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
RFID_Status mfrc_calculate_crc(MFRC_t *mfrc, uint8_t *data, uint8_t dataLen, uint8_t *response) {

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
			return ok;
		}
		if (millis() > deadline) {
			// CRC calculation took too long
			return timeout;
		}
	}
	
	return error;
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
bool mfrc_request_A(MFRC_t *mfrc) {

	uint8_t ATQA[2];										// Buffer to store ATQA from card

	mfrc_write_register(mfrc, TxModeReg, 0x00);				// Defines the bit rate during data transmission --> 106 kBd
	mfrc_write_register(mfrc, RxModeReg, 0x00);				// Defines the bit rate during data reception --> 106 kBd

	mfrc_write_register(mfrc, ModWidthReg, 0x26);			// Set the modulation width
	mfrc_clear_bitmask(mfrc, CollReg, 0x80);				// All received bits will be cleared after collision

	uint8_t command = REQA;									
	RFID_Status status = mfrc_to_card(mfrc, &command, 1, ATQA, 1);		// Perform request command type A

	return ((status==ok) || (status==collision));

}

// Reads UID of card, and performs Select command
RFID_Status mfrc_read_UID(MFRC_t *mfrc) {

	bool uidComplete;
	bool selectDone;
	bool useCascadeTag;
	uint8_t cascadeLevel = 1;
	RFID_Status result;
	uint8_t count;
	uint8_t checkBit;
	uint8_t index;
	uint8_t uidIndex;					// The first index in uid->uidByte[] that is used in the current Cascade Level.
	int8_t currentLevelKnownBits;		// The number of known UID bits in the current Cascade Level.
	uint8_t buffer[9];					// The SELECT/ANTICOLLISION commands uses a 7 byte standard frame + 2 bytes CRC_A
	uint8_t bufferUsed;				// The number of bytes used in the buffer, ie the number of bytes to transfer to the FIFO.
	uint8_t rxAlign;					// Used in BitFramingReg. Defines the bit position for the first bit received.
	uint8_t txLastBits;				// Used in BitFramingReg. The number of valid bits in the last transmitted byte. 
	uint8_t *responseBuffer;
	uint8_t responseLength;
	int validBits = 0;
	
	// Description of buffer structure:
	//		Byte 0: SEL 				Indicates the Cascade Level: PICC_CMD_SEL_CL1, PICC_CMD_SEL_CL2 or PICC_CMD_SEL_CL3
	//		Byte 1: NVB					Number of Valid Bits (in complete command, not just the UID): High nibble: complete bytes, Low nibble: Extra bits. 
	//		Byte 2: UID-data or CT		See explanation below. CT means Cascade Tag.
	//		Byte 3: UID-data
	//		Byte 4: UID-data
	//		Byte 5: UID-data
	//		Byte 6: BCC					Block Check Character - XOR of bytes 2-5
	//		Byte 7: CRC_A
	//		Byte 8: CRC_A
	// The BCC and CRC_A are only transmitted if we know all the UID bits of the current Cascade Level.
	//
	// Description of bytes 2-5: (Section 6.5.4 of the ISO/IEC 14443-3 draft: UID contents and cascade levels)
	//		UID size	Cascade level	Byte2	Byte3	Byte4	Byte5
	//		========	=============	=====	=====	=====	=====
	//		 4 bytes		1			uid0	uid1	uid2	uid3
	//		 7 bytes		1			CT		uid0	uid1	uid2
	//						2			uid3	uid4	uid5	uid6
	//		10 bytes		1			CT		uid0	uid1	uid2
	//						2			CT		uid3	uid4	uid5
	//						3			uid6	uid7	uid8	uid9
	
	// Prepare MFRC522
	mfrc_clear_bitmask(mfrc, CollReg, 0x80);		// ValuesAfterColl=1 => Bits received after collision are cleared.
	
	// Repeat Cascade Level loop until we have a complete UID.
	uidComplete = false;
	while (!uidComplete) {
		// Set the Cascade Level in the SEL byte, find out if we need to use the Cascade Tag in byte 2.
		switch (cascadeLevel) {
			case 1:
				buffer[0] = SEL_CL1;
				uidIndex = 0;
				useCascadeTag = validBits && mfrc->size > 4;	// When we know that the UID has more than 4 bytes
				break;
			
			case 2:
				buffer[0] = SEL_CL2;
				uidIndex = 3;
				useCascadeTag = validBits && mfrc->size > 7;	// When we know that the UID has more than 7 bytes
				break;
			
			case 3:
				buffer[0] = SEL_CL3;
				uidIndex = 6;
				useCascadeTag = false;						// Never used in CL3.
				break;
			
			default:
				return error;
				break;
		}
		
		// How many UID bits are known in this Cascade Level?
		currentLevelKnownBits = validBits - (8 * uidIndex);
		if (currentLevelKnownBits < 0) {
			currentLevelKnownBits = 0;
		}
		// Copy the known bits from uid->uidByte[] to buffer[]
		index = 2; // destination index in buffer[]
		if (useCascadeTag) {
			buffer[index++] = CT;
		}
		uint8_t bytesToCopy = currentLevelKnownBits / 8 + (currentLevelKnownBits % 8 ? 1 : 0); // The number of bytes needed to represent the known bits for this level.
		if (bytesToCopy) {
			uint8_t maxBytes = useCascadeTag ? 3 : 4; // Max 4 bytes in each Cascade Level. Only 3 left if we use the Cascade Tag
			if (bytesToCopy > maxBytes) {
				bytesToCopy = maxBytes;
			}
			for (count = 0; count < bytesToCopy; count++) {
				buffer[index++] = mfrc->Uid[uidIndex + count];
			}
		}
		// Now that the data has been copied we need to include the 8 bits in CT in currentLevelKnownBits
		if (useCascadeTag) {
			currentLevelKnownBits += 8;
		}
		
		// Repeat anti collision loop until we can transmit all UID bits + BCC and receive a SAK - max 32 iterations.
		selectDone = false;
		while (!selectDone) {
			// Find out how many bits and bytes to send and receive.
			if (currentLevelKnownBits >= 32) { // All UID bits in this Cascade Level are known. This is a SELECT.
				buffer[1] = 0x70; // NVB - Number of Valid Bits: Seven whole bytes
				// Calculate BCC - Block Check Character
				buffer[6] = buffer[2] ^ buffer[3] ^ buffer[4] ^ buffer[5];
				// Calculate CRC_A
				result = mfrc_calculate_crc(mfrc, buffer, 7, &buffer[7]);
				if (result != ok) {
					return result;
				}
				txLastBits		= 0; // 0 => All 8 bits are valid.
				bufferUsed		= 9;
				// Store response in the last 3 bytes of buffer (BCC and CRC_A - not needed after tx)
				responseBuffer	= &buffer[6];
				responseLength	= 3;
			}
			else { // This is an ANTICOLLISION.
				txLastBits		= currentLevelKnownBits % 8;
				count			= currentLevelKnownBits / 8;	// Number of whole bytes in the UID part.
				index			= 2 + count;					// Number of whole bytes: SEL + NVB + UIDs
				buffer[1]		= (index << 4) + txLastBits;	// NVB - Number of Valid Bits
				bufferUsed		= index + (txLastBits ? 1 : 0);
				// Store response in the unused part of buffer
				responseBuffer	= &buffer[index];
				responseLength	= sizeof(buffer) - index;
			}
			
			// Set bit adjustments
			rxAlign = txLastBits;											// Having a separate variable is overkill. But it makes the next line easier to read.
			mfrc_write_register(mfrc, BitFramingReg, (rxAlign << 4) + txLastBits);	// RxAlign = BitFramingReg[6..4]. TxLastBits = BitFramingReg[2..0]
			
			// Transmit the buffer and receive the response.
			result = mfrc_to_card(mfrc, buffer, bufferUsed, responseBuffer, 0);
			if (result == collision) { // More than one PICC in the field => collision.
				uint8_t valueOfCollReg = mfrc_read_register(mfrc, CollReg); // CollReg[7..0] bits are: ValuesAfterColl reserved CollPosNotValid CollPos[4:0]
				if (valueOfCollReg & 0x20) { // CollPosNotValid
					return collision; // Without a valid collision position we cannot continue
				}
				uint8_t collisionPos = valueOfCollReg & 0x1F; // Values 0-31, 0 means bit 32.
				if (collisionPos == 0) {
					collisionPos = 32;
				}
				if (collisionPos <= currentLevelKnownBits) { // No progress - should not happen 
					return error;
				}
				// Choose the PICC with the bit set.
				currentLevelKnownBits	= collisionPos;
				count			= currentLevelKnownBits % 8; // The bit to modify
				checkBit		= (currentLevelKnownBits - 1) % 8;
				index			= 1 + (currentLevelKnownBits / 8) + (count ? 1 : 0); // First byte is index 0.
				buffer[index]	|= (1 << checkBit);
			}
			else if (result != ok) {
				return result;
			}
			else { // STATUS_OK
				if (currentLevelKnownBits >= 32) { // This was a SELECT.
					selectDone = true; // No more anticollision 
					// We continue below outside the while.
				}
				else { // This was an ANTICOLLISION.
					// We now have all 32 bits of the UID in this Cascade Level
					currentLevelKnownBits = 32;
					// Run loop again to do the SELECT.
				}
			}
		} // End of while (!selectDone)
		
		// We do not check the CBB - it was constructed by us above.
		
		// Copy the found UID bytes from buffer[] to uid->uidByte[]
		index			= (buffer[2] == CT) ? 3 : 2; // source index in buffer[]
		bytesToCopy		= (buffer[2] == CT) ? 3 : 4;
		for (count = 0; count < bytesToCopy; count++) {
			mfrc->Uid[uidIndex + count] = buffer[index++];
		}
		
		// Check response SAK (Select Acknowledge)
		if (responseLength != 3 || txLastBits != 0) { // SAK must be exactly 24 bits (1 byte + CRC_A).
			return error;
		}
		// Verify CRC_A - do our own calculation and store the control in buffer[2..3] - those bytes are not needed anymore.
		result = mfrc_calculate_crc(mfrc, responseBuffer, 1, &buffer[2]);
		if (result != ok) {
			return result;
		}
		if ((buffer[2] != responseBuffer[1]) || (buffer[3] != responseBuffer[2])) {
			return error;
		}
		if (responseBuffer[0] & 0x04) { // Cascade bit set - UID not complete yes
			cascadeLevel++;
		}
		else {
			uidComplete = true;
			mfrc->sak = responseBuffer[0];
		}
	} // End of while (!uidComplete)
	
	// Set correct uid->size
	mfrc->size = 3 * cascadeLevel + 1;

	return ok;

	/*uint8_t buffer[9];	
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
	RFID_Status status;

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

			status = mfrc_to_card(mfrc, buffer, 2, responseBuffer, 0);		// Transfer buffer to card

			if (status == collision)
			{
				valueOfCollReg = mfrc_read_register(mfrc, CollReg);
				collisionPos = valueOfCollReg & 0x1F;
				byteNum = (collisionPos/8);
				bitNum = (collisionPos%8);
				buffer[1] = 0x20 + (((byteNum)<<4)|(bitNum));
				idx = ((byteNum)<<4) + 2;
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

		uidcomplete = true;

		return status;
	}*/

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