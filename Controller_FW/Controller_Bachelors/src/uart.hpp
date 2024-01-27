#ifndef UART_H
#define UART_H

#include <Arduino.h>

void uart_init(void);
void uart_transmit_char(unsigned char data);
void uart_transmit_string(char* data);


#endif