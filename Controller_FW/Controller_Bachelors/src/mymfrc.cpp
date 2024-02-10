#include "mymfrc.hpp"

void mfrc_write_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t value)
{
	SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	digitalWrite(mfrc->CE, LOW);		// Select slave
	SPI.transfer(reg);						// MSB == 0 is for writing. LSB is not used in address. Datasheet section 8.1.2.3.
	SPI.transfer(value);
	digitalWrite(mfrc->CE, HIGH);		// Release slave again
	SPI.endTransaction(); // Stop using the SPI bus
} // End PCD_WriteRegister()

/**
 * Writes a number of bytes to the specified register in the MFRC522 chip.
 * The interface is described in the datasheet section 8.1.2.
 */
void mfrc_write_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t count, uint8_t *values)
{
	SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	digitalWrite(mfrc->CE, LOW);		// Select slave
	SPI.transfer(reg);						// MSB == 0 is for writing. LSB is not used in address. Datasheet section 8.1.2.3.
	for (byte index = 0; index < count; index++) {
		SPI.transfer(values[index]);
	}
	digitalWrite(mfrc->CE, HIGH);		// Release slave again
	SPI.endTransaction(); // Stop using the SPI bus
} // End PCD_WriteRegister()

/**
 * Reads a byte from the specified register in the MFRC522 chip.
 * The interface is described in the datasheet section 8.1.2.
 */
uint8_t mfrc_read_register(MFRC_t *mfrc, MFRC_Reg reg)
{
    byte value;
	SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	digitalWrite(mfrc->CE, LOW);			// Select slave
	SPI.transfer(0x80 | reg);					// MSB == 1 is for reading. LSB is not used in address. Datasheet section 8.1.2.3.
	value = SPI.transfer(0);					// Read the value back. Send 0 to stop reading.
	digitalWrite(mfrc->CE, HIGH);			// Release slave again
	SPI.endTransaction(); // Stop using the SPI bus
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
	SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));	// Set the settings to work with SPI bus
	digitalWrite(mfrc->CE, LOW);		// Select slave
	count--;								// One read is performed outside of the loop
	SPI.transfer(address);					// Tell MFRC522 which address we want to read
	if (rxAlign) {		// Only update bit positions rxAlign..7 in values[0]
		// Create bit mask for bit positions rxAlign..7
		byte mask = (0xFF << rxAlign) & 0xFF;
		// Read value and tell that we want to read the same address again.
		byte value = SPI.transfer(address);
		// Apply mask to both current value of values[0] and the new data in value.
		values[0] = (values[0] & ~mask) | (value & mask);
		index++;
	}
	while (index < count) {
		values[index] = SPI.transfer(address);	// Read value and tell that we want to read the same address again.
		index++;
	}
	values[index] = SPI.transfer(0);			// Read the final byte. Send 0 to stop reading.
	digitalWrite(mfrc->CE, HIGH);			// Release slave again
	SPI.endTransaction(); // Stop using the SPI bus
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
	mfrc_antennaOn();	
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