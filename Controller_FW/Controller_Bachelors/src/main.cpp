#include <Arduino.h>
#include "gpio.hpp"

void setup(void){}


void loop(void){

  gpio_pin ledka = { .pin = 5, .port = B };
  gpio_set_mode(&ledka, mode_enum::Output);

  gpio_pin button = { .pin = 6, .port = D };
  gpio_set_mode(&button, mode_enum::Input);

  while(1){

    if (gpio_read(&button) == 1){
      gpio_write(&ledka, 1);
    }
    else{
      gpio_write(&ledka, 0);
    }

    delay(100);
  }
}