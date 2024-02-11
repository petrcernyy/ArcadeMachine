#include "mymfrc.hpp"
#include <SPI.h>

void mfrc_write_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t value)
{
	//SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	//digitalWrite(mfrc->CE, LOW);		// Select slave
	gpio_write(&mfrc->CE, 0);
	spi_transceive(reg);
	spi_transceive(value);
	//SPI.transfer(reg);						// MSB == 0 is for writing. LSB is not used in address. Datasheet section 8.1.2.3.
	//SPI.transfer(value);
	gpio_write(&mfrc->CE, 1);		// Release slave again
	//SPI.endTransaction(); // Stop using the SPI bus
} // End PCD_WriteRegister()

/**
 * Writes a number of bytes to the specified register in the MFRC522 chip.
 * The interface is described in the datasheet section 8.1.2.
 */
void mfrc_write_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t count, uint8_t *values)
{
	//SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	gpio_write(&mfrc->CE, 0);		// Select slave
	spi_transceive(reg);
	//SPI.transfer(reg);						// MSB == 0 is for writing. LSB is not used in address. Datasheet section 8.1.2.3.
	for (byte index = 0; index < count; index++) {
		spi_transceive(values[index]);
		//SPI.transfer(values[index]);
	}
	gpio_write(&mfrc->CE, 1);		// Release slave again
	//SPI.endTransaction(); // Stop using the SPI bus
} // End PCD_WriteRegister()

/**
 * Reads a byte from the specified register in the MFRC522 chip.
 * The interface is described in the datasheet section 8.1.2.
 */
uint8_t mfrc_read_register(MFRC_t *mfrc, MFRC_Reg reg)
{
    byte value;
	//SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	gpio_write(&mfrc->CE, 0);		// Select slave
	spi_transceive(0x80 | reg);
	//SPI.transfer(0x80 | reg);					// MSB == 1 is for reading. LSB is not used in address. Datasheet section 8.1.2.3.
	value = spi_transceive(0);
	//value = SPI.transfer(0);					// Read the value back. Send 0 to stop reading.
	gpio_write(&mfrc->CE, 1);			// Release slave again
	//SPI.endTransaction(); // Stop using the SPI bus
	return value;
} // End PCD_ReadRegister()

/**
 * Reads a number of bytes from the specified register in the MFRC522 chip.
 * The interface is described in the datasheet section 8.1.2.
 */
void mfrc_read_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t count, uint8_t *values, uint8_t rxAlign = 0)
{
    if (count == 0) {
		return;
	}
	byte address = 0x80 | reg;				// MSB == 1 is for reading. LSB is not used in address. Datasheet section 8.1.2.3.
	byte index = 0;							// Index in values array.
	//SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	gpio_write(&mfrc->CE, 0);		// Select slave
	count--;								// One read is performed outside of the loop
	spi_transceive(address);
	//SPI.transfer(address);					// Tell MFRC522 which address we want to read
	if (rxAlign) {		// Only update bit positions rxAlign..7 in values[0]
		// Create bit mask for bit positions rxAlign..7
		byte mask = (0xFF << rxAlign) & 0xFF;
		// Read value and tell that we want to read the same address again.
		//byte value = SPI.transfer(address);
		byte value = spi_transceive(address);
		// Apply mask to both current value of values[0] and the new data in value.
		values[0] = (values[0] & ~mask) | (value & mask);
		index++;
	}
	while (index < count) {
		//values[index] = SPI.transfer(address);
		values[index] = spi_transceive(address);	// Read value and tell that we want to read the same address again.
		index++;
	}
	//values[index] = SPI.transfer(0);
	values[index] = spi_transceive(0);			// Read the final byte. Send 0 to stop reading.
	gpio_write(&mfrc->CE, 1);			// Release slave again
	//SPI.endTransaction(); // Stop using the SPI bus
} // End PCD_ReadRegister()

/*
 * Sets the bits given in mask in register reg.
 */
void mfrc_set_bitmask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask)
{
	uint8_t tmp;
	tmp = mfrc_read_register(mfrc, reg);
	mfrc_write_register(mfrc, reg, tmp | mask);			// set bit mask
} // End PCD_SetRegisterBitMask()

/**
 * Clears the bits given in mask from register reg.
 */
void mfrc_clear_bitmask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask)
{
	uint8_t tmp;
	tmp = mfrc_read_register(mfrc, reg);
	mfrc_write_register(mfrc, reg, tmp & (~mask));		// clear bit mask
} // End PCD_ClearRegisterBitMask()

void mfrc_init(MFRC_t *mfrc)
{

	gpio_set_mode(&mfrc->CE, Output);
	//gpio_set_mode(&mfrc->RST, Output);

    mfrc_reset(mfrc);

    mfrc_write_register(mfrc, TxModeReg, 0x00);
	mfrc_write_register(mfrc, RxModeReg, 0x00);
	// Reset ModWidthReg
	mfrc_write_register(mfrc, ModWidthReg, 0x26);

	// When communicating with a PICC we need a timeout if something goes wrong.
	// f_timer = 13.56 MHz / (2*TPreScaler+1) where TPreScaler = [TPrescaler_Hi:TPrescaler_Lo].
	// TPrescaler_Hi are the four low bits in TModeReg. TPrescaler_Lo is TPrescalerReg.
	mfrc_write_register(mfrc, TModeReg, 0x80);			// TAuto=1; timer starts automatically at the end of the transmission in all communication modes at all speeds
	mfrc_write_register(mfrc, TPrescalerReg, 0xA9);		// TPreScaler = TModeReg[3..0]:TPrescalerReg, ie 0x0A9 = 169 => f_timer=40kHz, ie a timer period of 25μs.
	mfrc_write_register(mfrc, TReloadRegH, 0x03);		// Reload timer with 0x3E8 = 1000, ie 25ms before timeout.
	mfrc_write_register(mfrc, TReloadRegL, 0xE8);
	
	mfrc_write_register(mfrc, TxASKReg, 0x40);		// Default 0x00. Force a 100 % ASK modulation independent of the ModGsPReg register setting
	mfrc_write_register(mfrc, ModeReg, 0x3D);		// Default 0x3F. Set the preset value for the CRC coprocessor for the CalcCRC command to 0x6363 (ISO 14443-3 part 6.2.4)
	mfrc_antennaOn(mfrc);	
}

void mfrc_reset(MFRC_t *mfrc)
{
    mfrc_write_register(mfrc, CommandReg, SoftReset);
    while ((mfrc_read_register(mfrc, CommandReg) & (1 << 4))){};
}

void mfrc_antennaOn(MFRC_t *mfrc)
{
    uint8_t value = mfrc_read_register(mfrc, TxControlReg);
    if ((value & 0x03) != 0x03) {
        mfrc_write_register(mfrc, TxControlReg, value | 0x03);
    }
}

int mfrc_to_card(MFRC_t *mfrc, uint8_t *sendData, uint8_t sendDataLen, uint8_t *responseData, uint8_t shortFrame)
{

	mfrc_write_register(mfrc, CommandReg, Idle);			// Stop any active command.
	mfrc_write_register(mfrc, ComIrqReg, 0x7F);					// Clear all seven interrupt request bits
	mfrc_write_register(mfrc, FIFOLevelReg, 0x80);				// FlushBuffer = 1, FIFO initialization
	mfrc_write_register(mfrc, FIFODataReg, sendDataLen, sendData);	// Write sendData to the FIFO
	if (shortFrame){
		mfrc_write_register(mfrc, BitFramingReg, 0x07);
	}
	else{
		mfrc_write_register(mfrc, BitFramingReg, 0x00);
	}
	mfrc_write_register(mfrc, CommandReg, Transceive);				// Execute the command
	mfrc_set_bitmask(mfrc, BitFramingReg, 0x80);

	const uint32_t deadline = millis() + 36;
	bool completed = false;

	while (!completed)
	{
		byte n = mfrc_read_register(mfrc, ComIrqReg);	// ComIrqReg[7..0] bits are: Set1 TxIRq RxIRq IdleIRq HiAlertIRq LoAlertIRq ErrIRq TimerIRq
		if (n & 0x30) {					// One of the interrupts that signal success has been set.
			completed = true;
		}
		if (n & 0x01) {						// Timer interrupt - nothing received in 25ms
			return 0;
		}
		if (millis() > deadline) {
			return 0;
		}
	}
/*
	do {
		byte n = mfrc_read_register(mfrc, ComIrqReg);	// ComIrqReg[7..0] bits are: Set1 TxIRq RxIRq IdleIRq HiAlertIRq LoAlertIRq ErrIRq TimerIRq
		if (n & 0x30) {					// One of the interrupts that signal success has been set.
			completed = true;
			break;
		}
		if (n & 0x01) {						// Timer interrupt - nothing received in 25ms
			return;
		}
		yield();
	}
	while (static_cast<uint32_t> (millis()) < deadline);
*/
	uint8_t n = mfrc_read_register(mfrc, FIFOLevelReg);	
	mfrc_read_register(mfrc, FIFODataReg, n, responseData, 0);	// Get received data from FIFO
	return 1;

}

int mfrc_request_A(MFRC_t *mfrc)
{
	uint8_t ATQA[2];

	// Reset baud rates
	mfrc_write_register(mfrc, TxModeReg, 0x00);
	mfrc_write_register(mfrc, RxModeReg, 0x00);
	// Reset ModWidthReg
	mfrc_write_register(mfrc, ModWidthReg, 0x26);
	mfrc_clear_bitmask(mfrc, CollReg, 0x80);		// ValuesAfterColl=1 => Bits received after collision are cleared.

	uint8_t command = REQA;
	return mfrc_to_card(mfrc, &command, 1, ATQA, 1);

}

int mfrc_read_UID(MFRC_t *mfrc)
{

	uint8_t buffer[9];

	mfrc_clear_bitmask(mfrc, CollReg, 0x80);
	buffer[0] = SEL_CL1;

	uint8_t index			= 2;					// Number of whole bytes: SEL + NVB + UIDs
	buffer[1]		= 0x20;	// NVB - Number of Valid Bits
	uint8_t bufferUsed		= index;
	// Store response in the unused part of buffer
	uint8_t *responseBuffer;
	responseBuffer	= &buffer[index];
	mfrc_write_register(mfrc, BitFramingReg, 0x00);	// RxAlign = BitFramingReg[6..4]. TxLastBits = BitFramingReg[2..0]
	
	// Transmit the buffer and receive the response.
	int status = mfrc_to_card(mfrc, buffer, bufferUsed, responseBuffer, 0);

	mfrc->Uid[0] = buffer[2];
	mfrc->Uid[1] = buffer[3];
	mfrc->Uid[2] = buffer[4];
	mfrc->Uid[3] = buffer[5];

	return status;
}