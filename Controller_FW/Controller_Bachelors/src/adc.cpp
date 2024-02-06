#include "adc.hpp"

void adc_init(void){

    ADMUX = 0x00;
    ADMUX |= (1<<REFS0); //reference AVCC with external cap at Aref pin

    ADCSRA = 0x00;
    ADCSRA |= (1<<ADEN); //Enable ADC
    ADCSRA |= (1<<ADPS0) | (1<<ADPS1) | (1<<ADPS2); //Prescaler of 128

}

uint16_t adc_read(const gpio_pin *pin){

    ADMUX &= 0b11110000;                //Clear channel
    ADMUX |= pin->pin;                  //Set channel

    ADCSRA |= (1 << ADSC);              //Start conversion  
    while(ADCSRA & (1 << ADSC)){};      //Wait for conversion to finish

    uint16_t val = ADCL | (ADCH << 8);  //Read value

    return val;

}