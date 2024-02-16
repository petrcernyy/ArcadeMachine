#include "mymfrc.hpp"
#include <SPI.h>

// Address of register is bitshifted by one to the left, as stated in MFRC datasheet 8.1.2.3, MSB (1 = read, 0 = write), LSB = 0, bit 1-6 = address
// Write value to register of MFRC
void mfrc_write_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t value) {

	gpio_write(&mfrc->CE, 0);	// Choose Slave
	spi_transceive(reg);		// Transfer register address
	spi_transceive(value);		// Transfer value to register
	gpio_write(&mfrc->CE, 1);	// End Slave

}

// Write more bytes to register of MFRC, typically to FIFO buffer of MFRC
void mfrc_write_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t byteNum, uint8_t *values) {

	gpio_write(&mfrc->CE, 0);	// Choose Slave
	spi_transceive(reg);		// Transfer register address
	// Transfer all bytes to the register
	for (uint8_t index = 0; index < byteNum; index++) {
		spi_transceive(values[index]);
	}
	gpio_write(&mfrc->CE, 1);	// End Slave

}

// Read value from register of MFRC
uint8_t mfrc_read_register(MFRC_t *mfrc, MFRC_Reg reg) {

    uint8_t value;
	gpio_write(&mfrc->CE, 0);		// Choose Slave
	spi_transceive(0x80 | reg);		// Transfer register address, add MSB = 1 indicating read operation
	value = spi_transceive(0);		// Read value from register
	gpio_write(&mfrc->CE, 1);		// End Slave
	return value;

}

// Read more bytes from register of MFRC, typically FIFO buffer
void mfrc_read_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t count, uint8_t *values) {

	uint8_t index = 0;
	gpio_write(&mfrc->CE, 0);		// Choose Slave
	count--;						// First byte is not read
	spi_transceive(0x80 | reg);		// Transfer register address, add MSB = 1 indicating read operation
	while (index < count) {
		values[index] = spi_transceive(0x80 | reg);
		index++;
	}
	values[index] = spi_transceive(0);		// Read last value from register
	gpio_write(&mfrc->CE, 1);				// End Slave
}

// Set bitmask to register of MFRC
void mfrc_set_bitmask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask) {

	// Read register value and then add bitmask and write again
	uint8_t tmp;
	tmp = mfrc_read_register(mfrc, reg);
	mfrc_write_register(mfrc, reg, tmp | mask);

}

// Clear bitmask to register of MFRC
void mfrc_clear_bitmask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask) {

	// Read register value and then clear bitmask and write again
	uint8_t tmp;
	tmp = mfrc_read_register(mfrc, reg);
	mfrc_write_register(mfrc, reg, tmp & (~mask));

}

// MFRC calculates the CRC and send back
uint8_t mfrc_calculate_crc(MFRC_t *mfrc, uint8_t *data, uint8_t dataLen, uint8_t *response) {

	mfrc_write_register(mfrc, CommandReg, Idle);				// Stop any task
	mfrc_write_register(mfrc, DivIrqReg, 0x04);					// Set the CRC interrupt bit
	mfrc_write_register(mfrc, FIFOLevelReg, 0x80);				// Flush FIFO buffer of MFRC
	mfrc_write_register(mfrc, FIFODataReg, dataLen, data);		// Load data to FIFO
	mfrc_write_register(mfrc, CommandReg, CalcCRC);				// Send CRC command to MFRC

	// Set up deadline for CRC calculation
	const uint32_t deadline = millis() + 89;
	bool completed = false;

	while (!completed)
	{
		uint8_t n = mfrc_read_register(mfrc, DivIrqReg);				// Wait for CRC complete bit
		if (n & 0x04) {
			mfrc_write_register(mfrc, CommandReg, Idle);				// Stop any task
			response[0] = mfrc_read_register(mfrc, CRCResultRegL);		// Read lower byte of CRC result
			response[1] = mfrc_read_register(mfrc, CRCResultRegH);		// Read higher byte of CRC result
			return 1;
		}
		if (millis() > deadline) {
			// CRC calculation took too long
			return 0;
		}
	}

	return 0;
	
}

// Set up MFRC
void mfrc_init(MFRC_t *mfrc) {

	gpio_set_mode(&mfrc->CE, Output);					// Set Chip enable pin as output
	gpio_write(&mfrc->CE, 1);
	
	gpio_set_mode(&mfrc->RST, Input);

	bool hardReset = false;
	if (gpio_read(&mfrc->RST) == 0) {	// The MFRC522 chip is in power down mode.
		gpio_set_mode(&mfrc->RST, Output);		// Now set the resetPowerDownPin as digital output.
		gpio_write(&mfrc->RST, 0);		// Make sure we have a clean LOW state.
		delayMicroseconds(2);				// 8.8.1 Reset timing requirements says about 100ns. Let us be generous: 2μsl
		gpio_write(&mfrc->RST, 1);		// Exit power down mode. This triggers a hard reset.
		// Section 8.8.2 in the datasheet says the oscillator start-up time is the start up time of the crystal + 37,74μs. Let us be generous: 50ms.
		delay(50);
		hardReset = true;
	}

	if (!hardReset) {
    	mfrc_reset(mfrc);									// SoftReset of MFRC
	}
	//mfrc_reset(mfrc);									// SoftReset of MFRC
    mfrc_write_register(mfrc, TxModeReg, 0x00);			// Defines the bit rate during data transmission --> 106 kBd
	mfrc_write_register(mfrc, RxModeReg, 0x00);			// Defines the bit rate during data reception --> 106 kBd

	mfrc_write_register(mfrc, ModWidthReg, 0x26);		// Set the modulation width

	// Setting for timer, indicating timeout 
	mfrc_write_register(mfrc, TModeReg, 0x80);			// Timer start automatically after the end of transmission
	mfrc_write_register(mfrc, TPrescalerReg, 0xA9);		// Defines the preslacer of timer, aprox. 25us
	mfrc_write_register(mfrc, TReloadRegH, 0x03);		// Reload timer with 0x3E8 = 1000, ie 25ms before timeout.
	mfrc_write_register(mfrc, TReloadRegL, 0xE8);	
	
	mfrc_write_register(mfrc, TxASKReg, 0x40);			// Forces a 100% ASK modulation
	mfrc_write_register(mfrc, ModeReg, 0x3D);			// Set the preset value for the CRC coprocessor
	mfrc_antennaOn(mfrc);								// Enable the antenna driver pins TX1 and TX2 (they were disabled by the reset)

}

// SoftReset MFRC, command of MFRC
void mfrc_reset(MFRC_t *mfrc) {

    mfrc_write_register(mfrc, CommandReg, SoftReset);				// Send reset command to MFRC
    //while ((mfrc_read_register(mfrc, CommandReg) & (1 << 4))){};	// Wait for MFRC to reset
	uint8_t count = 0;
	do {
		// Wait for the PowerDown bit in CommandReg to be cleared (max 3x50ms)
		delay(50);
	} while ((mfrc_read_register(mfrc, CommandReg) & (1 << 4)) && (++count) < 3);

}

// Antenna power on
void mfrc_antennaOn(MFRC_t *mfrc) {

    uint8_t value = mfrc_read_register(mfrc, TxControlReg);
    if ((value & 0x03) != 0x03) {
        mfrc_write_register(mfrc, TxControlReg, value | 0x03);
    }

}

// Transceive data to card, and receive response. ShortFrame is used to initiate communication (ISO 14443 6.1.5.1)
RFID_Status mfrc_to_card(MFRC_t *mfrc, uint8_t *sendData, uint8_t sendDataLen, uint8_t *responseData, uint8_t shortFrame) {

	mfrc_write_register(mfrc, CommandReg, Idle);						// Stop any task
	mfrc_write_register(mfrc, ComIrqReg, 0x7F);							// Set interrupt bits
	mfrc_write_register(mfrc, FIFOLevelReg, 0x80);						// Flush FIFO buffer
	mfrc_write_register(mfrc, FIFODataReg, sendDataLen, sendData);		// Load data to FIFO buffer

	// Transfer only 7 bits, first bit is used to start the communication
	if (shortFrame){
		mfrc_write_register(mfrc, BitFramingReg, 0x07);
	}
	else{
		mfrc_write_register(mfrc, BitFramingReg, 0x00);
	}
	mfrc_write_register(mfrc, CommandReg, Transceive);					// Transceive the data from FIFO to card
	mfrc_set_bitmask(mfrc, BitFramingReg, 0x80);						// Start the transmission

	// Defines deadline for transmission
	const uint32_t deadline = millis() + 36;
	bool completed = false;

	do {
		uint8_t n = mfrc_read_register(mfrc, ComIrqReg);	// ComIrqReg[7..0] bits are: Set1 TxIRq RxIRq IdleIRq HiAlertIRq LoAlertIRq ErrIRq TimerIRq
		if (n & 0x30) {					// One of the interrupts that signal success has been set.
			completed = true;
			break;
		}
		if (n & 0x01) {						// Timer interrupt - nothing received in 25ms
			return timeout;
		}
		yield();
	}
	while (static_cast<uint32_t> (millis()) < deadline);

	// 36ms and nothing happened. Communication with the MFRC522 might be down.
	if (!completed) {
		return timeout;
	}


	uint8_t errorRegValue = mfrc_read_register(mfrc, ErrorReg);

	if (errorRegValue & 0x08) {		// CollErr
		return collision;
	}

	uint8_t n = mfrc_read_register(mfrc, FIFOLevelReg);					// Number of bytes available to be read from FIFO
	mfrc_read_register(mfrc, FIFODataReg, n, responseData);				// Read bytes from FIFO
	return ok;

}

// Perform request command to card
RFID_Status mfrc_request_A(MFRC_t *mfrc) {

	uint8_t ATQA[2];										// Buffer to store ATQA from card

	mfrc_write_register(mfrc, TxModeReg, 0x00);				// Defines the bit rate during data transmission --> 106 kBd
	mfrc_write_register(mfrc, RxModeReg, 0x00);				// Defines the bit rate during data reception --> 106 kBd

	mfrc_write_register(mfrc, ModWidthReg, 0x26);			// Set the modulation width
	mfrc_clear_bitmask(mfrc, CollReg, 0x80);				// All received bits will be cleared after collision

	uint8_t command = REQA;									
	return mfrc_to_card(mfrc, &command, 1, ATQA, 1);		// Perform request command type A

}

// Reads UID of card, and performs Select command
RFID_Status mfrc_read_UID(MFRC_t *mfrc) {

	uint8_t buffer[9];	
	uint8_t level = 1;
	bool uidcomplete = false;
	bool anticollision_complete = false;
	uint8_t *responseBuffer;
	uint8_t bitNum = 0;
	uint8_t idx = 2;
	uint8_t valueOfCollReg;
	uint8_t collisionPos;
	uint8_t byteNum;
	uint8_t followbit;

	while(!uidcomplete)
	{
		if(level == 1){
			buffer[0] = SEL_CL1;
		}
		else if(level == 2){
			buffer[0] = SEL_CL2;
		}
		else if(level == 3){
			buffer[0] = SEL_CL3;
		}
		buffer[1] = 0x20;

		while(!anticollision_complete)
		{
			responseBuffer	= &buffer[idx];
			mfrc_write_register(mfrc, BitFramingReg, (bitNum << 4) + bitNum);		// All bits of the last byte will be transmitted

			RFID_Status status = mfrc_to_card(mfrc, buffer, 2, responseBuffer, 0);		// Transfer buffer to card

			if (status == collision)
			{
				valueOfCollReg = mfrc_read_register(mfrc, CollReg);
				collisionPos = valueOfCollReg & 0x1F;
				byteNum = (collisionPos/8);
				bitNum = (collisionPos%8);
				buffer[1] = 0x20 + (((byteNum)<<4)|(bitNum));
				idx = (byteNum)<<4 + 2;
				followbit = (collisionPos-1)%8;
				buffer[idx] |= (1 << followbit);
			}
			else if (status == ok)
			{
				anticollision_complete = true;
			}
		}

		buffer[1] = 0x70;
		buffer[6] = buffer[2] ^ buffer[3] ^ buffer[4] ^ buffer[5];
		mfrc_calculate_crc(mfrc, buffer, 7, &buffer[7]);							// Calculate CRC
		responseBuffer = &buffer[6];
		mfrc_to_card(mfrc, buffer, 9, responseBuffer, 0);

		// Fill UID from buffer
		mfrc->Uid[0] = buffer[2];
		mfrc->Uid[1] = buffer[3];
		mfrc->Uid[2] = buffer[4];
		mfrc->Uid[3] = buffer[5];
	}

	// Buffer for communication between MFRC and card
	// 	byte[0]	byte[1]	byte[2]	byte[3]	byte[4]	byte[5]	byte[6] byte[7] byte[8]
	//	SEL		NVB		UID0	UID1	UID2	UID3	BCC/SAK	CRCA	CRCA	
	/*uint8_t buffer[9];									

	mfrc_clear_bitmask(mfrc, CollReg, 0x80);			// All received bits will be cleared after collision
	buffer[0] = SEL_CL1;								// Select firs cascade level

	uint8_t index = 2;			
	buffer[1] = 0x20;									// NVB = 0x20, indicates 2 bytes and 0 bits send
	uint8_t bufferUsed = index;

	uint8_t *responseBuffer;							// Fill response to buffer
	responseBuffer	= &buffer[index];
	mfrc_write_register(mfrc, BitFramingReg, 0x00);		// All bits of the last byte will be transmitted
	
	RFID_Status status = mfrc_to_card(mfrc, buffer, bufferUsed, responseBuffer, 0);		// Transfer buffer to card

	if (status == 2)
	{
		uint8_t valueOfCollReg = mfrc_read_register(mfrc, CollReg);
		uint8_t collisionPos = valueOfCollReg & 0x1F;
		buffer[1] = 0x20 + (((collisionPos/8)<<4)|(collisionPos%8));
	}

	buffer[1] = 0x70;															// NVB = 0x70, transmit 2 bytes of SEL, NVB + 4 bytes of UID
	buffer[6] = buffer[2] ^ buffer[3] ^ buffer[4] ^ buffer[5];					// Calculate BCC
	mfrc_calculate_crc(mfrc, buffer, 7, &buffer[7]);							// Calculate CRC
	responseBuffer = &buffer[6];
	mfrc_to_card(mfrc, buffer, 9, responseBuffer, 0);							// Send Select command to MFRC, receieve SAK

	// Fill UID from buffer
	mfrc->Uid[0] = buffer[2];
	mfrc->Uid[1] = buffer[3];
	mfrc->Uid[2] = buffer[4];
	mfrc->Uid[3] = buffer[5];

	return status;*/

}

// Put card in HALT state, so that we wont read the same UID more than once
void mfrc_card_halt(MFRC_t *mfrc) {

	uint8_t buffer[4];

	// Fill buffer with Halt command
	// 	byte[0]	byte[1] byte[2] byte[3]
	//	0x50	0x00	CRC		CRC	
	buffer[0] = HALT;
	buffer[1] = 0;

	mfrc_calculate_crc(mfrc, buffer, 2, &buffer[2]);
	
	mfrc_to_card(mfrc, buffer, sizeof(buffer), nullptr, 0);		// Transmit buffer to card

}