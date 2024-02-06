#ifndef ADC_H
#define ADC_H

#include <Arduino.h>
#include "gpio.hpp"

void adc_init(void);
uint16_t adc_read(const gpio_pin *pin);


#endif