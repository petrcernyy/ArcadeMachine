#include <string.h>
#include <stdio.h>
#include "mfrc.hpp"
#include "gpio.hpp"
#include "adc.hpp"
#include "uart.hpp"

void setup(void){}

#define RISINGEDGE 0b00000111

void led_control(char* index);

typedef struct{
  int ButtonEnterRead;
  int ButtonEnterState;
  int ButtonExitRead;
  int ButtonExitState;
}Buttons_t;

volatile Buttons_t buttons = {0};

const gpio_pin buttonEnt = { .pin = 0, .port = B };
const gpio_pin buttonExit = { .pin = 1, .port = B };

const gpio_pin red_led = { .pin = 4, .port = D };
const gpio_pin blue_led = { .pin = 7, .port = D };

char receive[10];
char nuidChar[16];
char buttonMess[6];
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

ISR(TIMER2_COMPA_vect){

    buttons.ButtonEnterRead<<=1;
    buttons.ButtonEnterRead |= gpio_read(&buttonEnt);

    if (buttons.ButtonEnterRead == RISINGEDGE){
      buttons.ButtonEnterState = 1;
    }

    buttons.ButtonExitRead<<=1;
    buttons.ButtonExitRead |= gpio_read(&buttonExit);

    if (buttons.ButtonExitRead == RISINGEDGE){
      buttons.ButtonExitState = 1;
    }

}

void loop(void){

  MFRC522 rfid(10, 5);

  //SPI.begin(); // Init SPI bus
  //rfid.PCD_Init(); // Init MFRC522 

  uint8_t nuidPICC[4];

  i = 0;
  rec_flag = 0;
  int index = 0;
  char card_read = 0;
  char help[] = "9|";

  gpio_set_mode(&buttonEnt, mode_enum::Input);
  gpio_set_mode(&buttonExit, mode_enum::Output);

  const gpio_pin JoystickX = { .pin = 2, .port = C};
  gpio_set_mode(&JoystickX, mode_enum::Input);

  const gpio_pin JoystickY = { .pin = 3, .port = C};
  gpio_set_mode(&JoystickY, mode_enum::Input);

  gpio_set_mode(&red_led, mode_enum::Output);

  gpio_set_mode(&blue_led, mode_enum::Output);

  SREG = (0 << 7);

  adc_init();
  uart_init();

  TCCR2A = 0; 
  TCCR2B = 0;
  OCR2A = 100;
  TCCR2A |= (1 << WGM21);     // CTC mode on
  TCCR2B |= (1 << CS21);
  TIMSK2 |= (1 << OCIE2A);    // timer compare intrupt

  SREG = (1 << 7);

  uint16_t JoyXVal;
  uint16_t JoyYVal;

  char Values[18];


  while(1){

    if(rec_flag)
    {
      rec_flag = 0;
      led_control(receive);
    }

    JoyXVal = adc_read(&JoystickX);
    JoyXVal = ((JoyXVal)/double(1023))*(double)100;
    JoyYVal = adc_read(&JoystickY);
    JoyYVal = ((JoyYVal)/double(1023))*(double)100;

    /*if ((rfid.PICC_IsNewCardPresent()) && (rfid.PICC_ReadCardSerial())){

        for (byte i = 0; i < 4; i++) {
          nuidPICC[i] = rfid.uid.uidByte[i];
          index += sprintf(&nuidChar[index], "%d", nuidPICC[i]);
        }
        index = 0; 
        strcat(help, nuidChar);
        card_read = 1;
    }

    rfid.PICC_HaltA();*/

    if(card_read){
      card_read = 0;
      uart_transmit_string(help);
      for (byte i = 0; i < 4; i++) {
        nuidPICC[i] = 0;
      }
      nuidChar[0] = '\0';
      help[2] = '\0';
    }
    else{
      sprintf(Values, "8|%03d||%03d||%01d||%01d", JoyXVal, JoyYVal, buttons.ButtonEnterState, buttons.ButtonExitState);
      buttons.ButtonEnterState = 0;
      buttons.ButtonExitState = 0;
      uart_transmit_string(Values);
    }

    delay(50);
  }
}

void led_control(char* index)
{
  switch(*index)
  {
    case('0'):
      if(gpio_read(&red_led))
      {
        gpio_write(&red_led, 0);
      }
      else
      {
        gpio_write(&red_led, 1);
      }
      break;
    case('1'):
      gpio_write(&red_led, 1);
      break;
    case('2'):
      gpio_write(&red_led, 0);
      break;
    case('3'):
      if(gpio_read(&blue_led))
      {
        gpio_write(&blue_led, 0);
      }
      else
      {
        gpio_write(&blue_led, 1);
      }
      break;
    case('4'):
      gpio_write(&blue_led, 1);
      break;
    case('5'):
      gpio_write(&blue_led, 0);
      break;
  }
}