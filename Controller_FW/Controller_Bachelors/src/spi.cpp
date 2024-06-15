#include "spi.hpp"

void spi_init(SPI_t *spi){

    // Set pin modes for SPI
    gpio_set_mode(&spi->clk, Output);
    gpio_set_mode(&spi->mosi, Output);
    gpio_set_mode(&spi->miso, Input);

    SPCR = (1 << SPE) | (1 << MSTR) | (1 << SPR0);  // SPI enable, Master mode, fclk/16 --> 1MHz

}

// SPI transfer + receive
uint8_t spi_transceive(uint8_t data){

    SPDR = data;

    // Wait for reception complete
    while(!(SPSR & (1 << SPIF)));
    asm volatile("nop");
    // return Data Register
    return SPDR;

}
