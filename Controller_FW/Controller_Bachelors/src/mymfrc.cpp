#include "mymfrc.hpp"

void MFRC_WriteReg(MFRC_t *mfrc, MFRC_Reg reg, uint8_t val)
{
    SPI.beginTransaction(SPISettings(4000000u, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	digitalWrite(mfrc->CE, LOW);
    //gpio_write(&(mfrc->CE), 0);
	SPI.transfer(reg);						// MSB == 0 is for writing. LSB is not used in address. Datasheet section 8.1.2.3.
	SPI.transfer(val);
	digitalWrite(mfrc->CE, HIGH);
	//gpio_write(&(mfrc->CE), 1);
	SPI.endTransaction(); // Stop using the SPI bus

}

uint8_t MFRC_ReadReg(MFRC_t *mfrc, MFRC_Reg reg)
{
    uint8_t value;
	SPI.beginTransaction(SPISettings(4000000u, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	//gpio_write(&(mfrc->CE), 0);			// Select slave
	digitalWrite(mfrc->CE, LOW);
	SPI.transfer(0x80 | reg);					// MSB == 1 is for reading. LSB is not used in address. Datasheet section 8.1.2.3.
	value = SPI.transfer(0);					// Read the value back. Send 0 to stop reading.
	//gpio_write(&(mfrc->CE), 1);
	digitalWrite(mfrc->CE, HIGH);
	SPI.endTransaction(); // Stop using the SPI bus
	return value;
}

void MFRC_SetMask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask)
{
	uint8_t tmp = MFRC_ReadReg(mfrc, reg);
	MFRC_WriteReg(mfrc, reg, tmp | mask);	
}

void MFRC_ClearMask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask)
{
	uint8_t tmp = MFRC_ReadReg(mfrc, reg);
	MFRC_WriteReg(mfrc, reg, tmp & (~mask));	
}

void MFRC_AntennaOn(MFRC_t *mfrc)
{
    uint8_t value = MFRC_ReadReg(mfrc, TxControlReg);
	if ((value & 0x03) != 0x03) {
		MFRC_WriteReg(mfrc, TxControlReg, value | 0x03);
	}
}

void MFRC_Init(MFRC_t *mfrc)
{
    //gpio_set_mode(&(mfrc->CE), mode_enum::Output);
    //gpio_write(&(mfrc->CE), 1);	
	pinMode(mfrc->CE, OUTPUT);
	digitalWrite(mfrc->CE, HIGH);

    //gpio_set_mode(&(mfrc->RST), mode_enum::Input);
	pinMode(mfrc->RST, INPUT);

    //if (gpio_read(&(mfrc->RST)) == 0)
	if(digitalRead(mfrc->RST) == 0)
    {
        //gpio_set_mode(&(mfrc->RST), mode_enum::Output);
        //gpio_write(&(mfrc->RST), 0);
		pinMode(mfrc->RST, OUTPUT);
		digitalWrite(mfrc->RST, 0);
        delayMicroseconds(2);
		digitalWrite(mfrc->RST, 1);
        //gpio_write(&(mfrc->RST), 1);
        delay(50);
    }

	MFRC_Reset(mfrc);

    MFRC_WriteReg(mfrc, TxModeReg, 0x00);
	MFRC_WriteReg(mfrc, RxModeReg, 0x00);
	// Reset ModWidthReg
	MFRC_WriteReg(mfrc, ModWidthReg, 0x26);

	// When communicating with a PICC we need a timeout if something goes wrong.
	// f_timer = 13.56 MHz / (2*TPreScaler+1) where TPreScaler = [TPrescaler_Hi:TPrescaler_Lo].
	// TPrescaler_Hi are the four low bits in TModeReg. TPrescaler_Lo is TPrescalerReg.
	MFRC_WriteReg(mfrc, TModeReg, 0x80);			// TAuto=1; timer starts automatically at the end of the transmission in all communication modes at all speeds
	MFRC_WriteReg(mfrc, TPrescalerReg, 0xA9);		// TPreScaler = TModeReg[3..0]:TPrescalerReg, ie 0x0A9 = 169 => f_timer=40kHz, ie a timer period of 25μs.
	MFRC_WriteReg(mfrc, TReloadRegH, 0x03);		// Reload timer with 0x3E8 = 1000, ie 25ms before timeout.
	MFRC_WriteReg(mfrc, TReloadRegL, 0xE8);
	
	MFRC_WriteReg(mfrc, TxASKReg, 0x40);		// Default 0x00. Force a 100 % ASK modulation independent of the ModGsPReg register setting
	MFRC_WriteReg(mfrc, ModeReg, 0x3D);		// Default 0x3F. Set the preset value for the CRC coprocessor for the CalcCRC command to 0x6363 (ISO 14443-3 part 6.2.4)
	MFRC_AntennaOn(mfrc);						// Enable the antenna driver pins TX1 and TX2 (they were disabled by the reset)
}

void MFRC_Reset(MFRC_t *mfrc)
{
    MFRC_WriteReg(mfrc, CommandReg, SoftReset);	// Issue the SoftReset command.
	// The datasheet does not mention how long the SoftRest command takes to complete.
	// But the MFRC522 might have been in soft power-down mode (triggered by bit 4 of CommandReg) 
	// Section 8.8.2 in the datasheet says the oscillator start-up time is the start up time of the crystal + 37,74μs. Let us be generous: 50ms.
	uint8_t count = 0;
	do {
		// Wait for the PowerDown bit in CommandReg to be cleared (max 3x50ms)
		delay(50);
	} while ((MFRC_ReadReg(mfrc, CommandReg) & (1 << 4)) && (++count) < 3);
}

void MFRC_FSM_Comm(MFRC_t *mfrc, uint8_t command, uint8_t data)
{

	MFRC_ClearMask(mfrc, CollReg, 0x80);

	byte txLastBits = 7 ? 7 : 0;
	byte bitFraming = (0 << 4) + txLastBits;	

    MFRC_WriteReg(mfrc, CommandReg, Idle);			// Stop any active command.
    MFRC_WriteReg(mfrc, ComIrqReg, 0x7F);					// Clear all seven interrupt request bits
	MFRC_WriteReg(mfrc, FIFOLevelReg, 0x80);				// FlushBuffer = 1, FIFO initialization
	MFRC_WriteReg(mfrc, FIFODataReg, data);	// Write sendData to the FIFO
	MFRC_WriteReg(mfrc, BitFramingReg, bitFraming);
	MFRC_WriteReg(mfrc, CommandReg, command);				// Execute the command
    if (command == Transceive) {
		MFRC_SetMask(mfrc, BitFramingReg, 0x80);	// StartSend=1, transmission of data starts
	}

    const uint32_t deadline = millis() + 36;

    do {
		byte n = MFRC_ReadReg(mfrc, ComIrqReg);	// ComIrqReg[7..0] bits are: Set1 TxIRq RxIRq IdleIRq HiAlertIRq LoAlertIRq ErrIRq TimerIRq
		if (n & 0x30) {					// One of the interrupts that signal success has been set.
			break;
		}
		yield();
	}
	while (static_cast<uint32_t> (millis()) < deadline);
							// Number of bytes returned
    mfrc->data_buffer = MFRC_ReadReg(mfrc, FIFODataReg);	// Get received data from FIFO

}

void NewCard(MFRC_t *mfrc)
{
	MFRC_WriteReg(mfrc, TxModeReg, 0x00);
	MFRC_WriteReg(mfrc, RxModeReg, 0x00);
	// Reset ModWidthReg
	MFRC_WriteReg(mfrc, ModWidthReg, 0x26);

    MFRC_FSM_Comm(mfrc, Transceive, REQA);

	//MFRC_ClearMask(mfrc, CollReg, 0x80);

	//byte buffer[9];	
	//buffer[0] = CMD_SEL_Cascade1;
	//buffer[1] = 0x20;

	//MFRC_FSM_Comm(mfrc, Transceive, buffer);
}