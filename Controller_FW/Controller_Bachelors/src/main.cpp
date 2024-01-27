#include <string.h>
#include <stdio.h>
#include <MFRC522.h>
#include "gpio.hpp"
#include "adc.hpp"
#include "uart.hpp"

void setup(void){}

char receive[10];
int i;
char rec_flag;

ISR (USART_RX_vect){

  unsigned char rec = uart_receive_char();
  if (rec == '\n'){
    i = 0;
    rec_flag = 1;
  }
  else{
    receive[i++] = rec;
  }

}

void loop(void){

  MFRC522 rfid(10, 5);

  SPI.begin(); // Init SPI bus
  rfid.PCD_Init(); // Init MFRC522 

  uint8_t nuidPICC[4];
  char nuidChar[16];

  i = 0;
  rec_flag = 0;
  int index = 0;

  gpio_pin button = { .pin = 6, .port = D };
  gpio_set_mode(&button, mode_enum::Input);

  gpio_pin JoystickX = { .pin = 1, .port = C};
  gpio_set_mode(&JoystickX, mode_enum::Input);

  gpio_pin JoystickY = { .pin = 0, .port = C};
  gpio_set_mode(&JoystickY, mode_enum::Input);

  SREG = (0 << 7);

  adc_init();
  uart_init();

  SREG = (1 << 7);

  uint16_t JoyXVal;
  uint16_t JoyYVal;

  char message[12];
  char card_mess1[50] = "A new card has been detected";
  char card_mess2[50] = "Card read previously";


  while(1){

    if (gpio_read(&button) == 1){
      uart_transmit_string(nuidChar);
    }
    else{
      
    }

    JoyXVal = adc_read(&JoystickX);
    JoyYVal = adc_read(&JoystickY);

    sprintf(message, "%04d||%04d", JoyXVal, JoyYVal);

    if (rec_flag){
      rec_flag = 0;
      uart_transmit_string(message);
    }

    if ((rfid.PICC_IsNewCardPresent()) && (rfid.PICC_ReadCardSerial())){

      if (rfid.uid.uidByte[0] != nuidPICC[0] || 
        rfid.uid.uidByte[1] != nuidPICC[1] || 
        rfid.uid.uidByte[2] != nuidPICC[2] || 
        rfid.uid.uidByte[3] != nuidPICC[3] ) {
        uart_transmit_string(card_mess1);

        for (byte i = 0; i < 4; i++) {
          nuidPICC[i] = rfid.uid.uidByte[i];
          index += sprintf(&nuidChar[index], "%d", nuidPICC[i]);
        }
        index = 0;


      }
      else uart_transmit_string(card_mess2);
    }

    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();

    delay(100);
  }
}