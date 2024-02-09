#ifndef MYMFRC_H
#define MYMFRC_H

#include <Arduino.h>
#include <stdint.h>
#include <SPI.h>
#include "gpio.hpp"

typedef enum{

    CommandReg				= 0x01 << 1,
    FIFODataReg				= 0x09 << 1,
    ComIrqReg				= 0x04 << 1,
    FIFOLevelReg			= 0x0A << 1,
    BitFramingReg			= 0x0D << 1,
    CollReg					= 0x0E << 1,

    ModeReg					= 0x11 << 1,	// defines general modes for transmitting and receiving 
    TxModeReg				= 0x12 << 1,	// defines transmission data rate and framing
    RxModeReg				= 0x13 << 1,	// defines reception data rate and framing
    TxControlReg			= 0x14 << 1,	// controls the logical behavior of the antenna driver pins TX1 and TX2
    TxASKReg				= 0x15 << 1,	// controls the setting of the transmission modulation
    TxSelReg				= 0x16 << 1,	// selects the internal sources for the antenna driver
    RxSelReg				= 0x17 << 1,	// selects internal receiver settings
    RxThresholdReg			= 0x18 << 1,	// selects thresholds for the bit decoder
    DemodReg				= 0x19 << 1,

    CRCResultRegH			= 0x21 << 1,	// shows the MSB and LSB values of the CRC calculation
    CRCResultRegL			= 0x22 << 1,

    ModWidthReg				= 0x24 << 1,

    RFCfgReg				= 0x26 << 1,	// configures the receiver gain
    GsNReg					= 0x27 << 1,	// selects the conductance of the antenna driver pins TX1 and TX2 for modulation 
    CWGsPReg				= 0x28 << 1,	// defines the conductance of the p-driver output during periods of no modulation
    ModGsPReg				= 0x29 << 1,	// defines the conductance of the p-driver output during periods of modulation
    TModeReg				= 0x2A << 1,	// defines settings for the internal timer
    TPrescalerReg			= 0x2B << 1,	// the lower 8 bits of the TPrescaler value. The 4 high bits are in TModeReg.
    TReloadRegH				= 0x2C << 1,	// defines the 16-bit timer reload value
    TReloadRegL				= 0x2D << 1,
    TCounterValueRegH		= 0x2E << 1,	// shows the 16-bit timer value
    TCounterValueRegL		= 0x2F << 1,

}MFRC_Reg;

typedef enum{

    Idle        = 0x00,
    CalcCRC     = 0x03,
    Transmit    = 0x04,
    Receive     = 0x08,
    Transceive  = 0x0C,
    SoftReset	= 0x0F,

}MFRC_Comm;

typedef enum{

    REQA                = 0x26,
    CMD_SEL_Cascade1	= 0x93,
    HALT			    = 0x50,	

}PICC_Comm;

typedef struct{

    const uint8_t CE;
    const uint8_t RST;

    uint8_t UidData[4];

    uint8_t data_buffer;
    uint8_t bufferATQA[2];

    uint8_t CRC_H;
    uint8_t CRC_L;


}MFRC_t;

void MFRC_WriteReg(MFRC_t *mfrc, MFRC_Reg reg, uint8_t val);
uint8_t MFRC_ReadReg(MFRC_t *mfrc, MFRC_Reg reg);

void MFRC_SetMask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask);
void MFRC_ClearMask(MFRC_t *mfrc, MFRC_Reg reg, uint8_t mask);
void MFRC_AntennaOn(MFRC_t *mfrc);

void MFRC_Init(MFRC_t *mfrc);
void MFRC_Reset(MFRC_t *mfrc);

void MFRC_FSM_Comm(MFRC_t *mfrc, uint8_t command, uint8_t data);

void NewCard(MFRC_t *mfrc);





#endif