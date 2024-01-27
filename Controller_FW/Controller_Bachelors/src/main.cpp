#include <Arduino.h>
#include <MFRC522.h>
#include <string.h>
#include <stdio.h>
#include "gpio.hpp"
#include "adc.hpp"
#include "uart.hpp"

void setup(void){}


void loop(void){

  gpio_pin ledka = { .pin = 5, .port = B };
  gpio_set_mode(&ledka, mode_enum::Output);

  gpio_pin button = { .pin = 6, .port = D };
  gpio_set_mode(&button, mode_enum::Input);

  gpio_pin JoystickX = { .pin = 1, .port = C};
  gpio_set_mode(&JoystickX, mode_enum::Input);

  gpio_pin JoystickY = { .pin = 0, .port = C};
  gpio_set_mode(&JoystickY, mode_enum::Input);

  adc_init();
  uart_init();

  uint16_t JoyXVal;
  uint16_t JoyYVal;

  char message[12];


  while(1){

    if (gpio_read(&button) == 1){
      gpio_write(&ledka, 1);
    }
    else{
      gpio_write(&ledka, 0);
    }

    JoyXVal = adc_read(&JoystickX);
    JoyYVal = adc_read(&JoystickY);

    sprintf(message, "%04d||%04d\n", JoyXVal, JoyYVal);

    uart_transmit_string(message);


    delay(100);
  }
}