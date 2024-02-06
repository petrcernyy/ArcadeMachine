#include <Arduino.h>
#include "gpio.hpp"

void gpio_set_mode(const gpio_pin *pin, mode_enum mode)
{
    switch(pin->port){
        case port_enum::B:
            DDRB |= (mode << pin->pin);
            break;
        case port_enum::C:
            DDRC |= (mode << pin->pin);
            break;
        case port_enum::D:
            DDRD |= (mode << pin->pin);
            break;
    }
}

void gpio_write(const gpio_pin *pin, int Value)
{ 
    switch(pin->port){
        case port_enum::B:
            if (Value){
                PORTB |= (1 << pin->pin);
            }
            else{
                PORTB &= ~(1 << pin->pin);
            }
            break;
        case port_enum::C:
            if (Value){
                PORTC |= (1 << pin->pin);
            }
            else{
                PORTC &= ~(1 << pin->pin);
            }
            break;
        case port_enum::D:
            if (Value){
                PORTD |= (1 << pin->pin);
            }
            else{
                PORTD &= ~(1 << pin->pin);
            }
            break;
    }
}

int gpio_read(const gpio_pin *pin){

    uint8_t val;

    switch(pin->port){
        case port_enum::B:
            val = PINB & (1 << pin->pin);
            break;
        case port_enum::C:
            val = PINC & (1 << pin->pin);
            break;
        case port_enum::D:
            val = PIND & (1 << pin->pin);
            break;
    }

    if (val){
        return 1;
    }
    else{
        return 0;
    }
}