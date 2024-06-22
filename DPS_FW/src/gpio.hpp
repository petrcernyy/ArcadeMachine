#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>
#include "uart.hpp"

typedef enum{
    B = 66,
    C = 67,
    D = 68
}port_enum;

typedef enum{
    Input = 0,
    Output = 1
}mode_enum;

typedef struct{
    int pin;
    port_enum port;
}gpio_pin;

void gpio_set_mode(const gpio_pin *pin, mode_enum mode);
void gpio_write(const gpio_pin *pin, int Value);
int gpio_read(const gpio_pin *pin);


#endif