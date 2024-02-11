#ifndef SPI_H
#define SPI_H

#include <Arduino.h>
#include "gpio.hpp"

typedef struct{

    const gpio_pin clk;
    const gpio_pin mosi;
    const gpio_pin miso;

}SPI_t;

void spi_init(SPI_t *spi);
uint8_t spi_transceive(uint8_t data);


#endif