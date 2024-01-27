#include "uart.hpp"

#define FOSC 16000000
#define BAUD 9600
#define MYUBRR FOSC/16/BAUD-1

void uart_init(void){

    UBRR0H = (unsigned char)(MYUBRR >> 8);
    UBRR0L = (unsigned char)(MYUBRR);

    UCSR0A = (1 << RXC0);
    UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
    UCSR0C = (3 << UCSZ00);

}

void uart_transmit_char(unsigned char data){

    while (!(UCSR0A & (1 << UDRE0))){};
    UDR0 = data;

}

void uart_transmit_string(char* data){

    int i;
    for(i = 0; i < strlen(data); i++){
        uart_transmit_char(data[i]);
    }
}

unsigned char uart_receive_char(void){

    while (!(UCSR0A & (1<<RXC0))){};

    return UDR0;
    
}