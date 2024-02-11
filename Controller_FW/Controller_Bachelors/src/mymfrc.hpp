#ifndef MYMFRC_H
#define MYMFRC_H

#include <stdint.h>
#include "spi.hpp"

typedef enum{

        // Page 0: Command and status
		CommandReg				= 0x01 << 1,	// starts and stops command execution
		ComIrqReg				= 0x04 << 1,	// interrupt request bits 
		FIFODataReg				= 0x09 << 1,	// input and output of 64 byte FIFO buffer
		FIFOLevelReg			= 0x0A << 1,	// number of bytes stored in the FIFO buffer
		BitFramingReg			= 0x0D << 1,	// adjustments for bit-oriented frames
		CollReg					= 0x0E << 1,	// bit position of the first bit-collision detected on the RF interface
		
		// Page 1: Command
		ModeReg					= 0x11 << 1,	// defines general modes for transmitting and receiving 
		TxModeReg				= 0x12 << 1,	// defines transmission data rate and framing
		RxModeReg				= 0x13 << 1,	// defines reception data rate and framing
		TxControlReg			= 0x14 << 1,	// controls the logical behavior of the antenna driver pins TX1 and TX2
		TxASKReg				= 0x15 << 1,	// controls the setting of the transmission modulation
		
		// Page 2: Configuration
		CRCResultRegH			= 0x21 << 1,	// shows the MSB and LSB values of the CRC calculation
		CRCResultRegL			= 0x22 << 1,
		ModWidthReg				= 0x24 << 1,	// controls the ModWidth setting?
		TModeReg				= 0x2A << 1,	// defines settings for the internal timer
		TPrescalerReg			= 0x2B << 1,	// the lower 8 bits of the TPrescaler value. The 4 high bits are in TModeReg.
		TReloadRegH				= 0x2C << 1,	// defines the 16-bit timer reload value
		TReloadRegL				= 0x2D << 1,

}MFRC_Reg;

typedef enum{

    	Idle				= 0x00,		// no action, cancels current command execution
		CalcCRC				= 0x03,		// activates the CRC coprocessor or performs a self-test
		Transmit			= 0x04,		// transmits data from the FIFO buffer
		Receive				= 0x08,		// activates the receiver circuits
		Transceive 			= 0x0C,		// transmits data from FIFO buffer to antenna and automatically activates the receiver after transmission
		SoftReset			= 0x0F		// resets the MFRC522

}MFRC_Command;

typedef enum{
    	// The commands used by the PCD to manage communication with several PICCs (ISO 14443-3, Type A, section 6.4)
		REQA			= 0x26,		// REQuest command, Type A. Invites PICCs in state IDLE to go to READY and prepare for anticollision or selection. 7 bit frame.
		CT				= 0x88,		// Cascade Tag. Not really a command, but used during anti collision.
		SEL_CL1			= 0x93,		// Anti collision/Select, Cascade Level 1
		SEL_CL2			= 0x95,		// Anti collision/Select, Cascade Level 2
		SEL_CL3			= 0x97,		// Anti collision/Select, Cascade Level 3
		HLTA			= 0x50,		// HaLT command, Type A. Instructs an ACTIVE PICC to go to state HALT.

}RFID_Command;

typedef struct{

    const gpio_pin CE;
    const gpio_pin RST;

    uint8_t Uid[4];

}MFRC_t;

void mfrc_write_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t value);
void mfrc_write_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t count, uint8_t *values);
uint8_t mfrc_read_register(MFRC_t *mfrc, MFRC_Reg reg);
void mfrc_read_register(MFRC_t *mfrc, MFRC_Reg reg, uint8_t count, uint8_t *values, uint8_t rxAlign = 0);
void mfrc_set_bitmask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask);
void mfrc_clear_bitmask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask);

void mfrc_init(MFRC_t *mfrc);
void mfrc_reset(MFRC_t *mfrc);
void mfrc_antennaOn(MFRC_t *mfrc);

int mfrc_to_card(MFRC_t *mfrc, uint8_t *sendData, uint8_t sendDataLen, uint8_t *responseData, uint8_t shortFrame);
int mfrc_request_A(MFRC_t *mfrc);
int mfrc_read_UID(MFRC_t *mfrc);


#endif