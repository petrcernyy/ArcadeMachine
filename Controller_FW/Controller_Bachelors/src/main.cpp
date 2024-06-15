#include <string.h>
#include <stdio.h>
#include "mymfrc.hpp"
#include "gpio.hpp"
#include "adc.hpp"
#include "uart.hpp"
#include "spi.hpp"

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

  SPI_t spi = { .clk = { .pin = 5, .port = B},
                .mosi = { .pin = 3, .port = B},
                .miso = { .pin = 4, .port = B}};

  spi_init(&spi);

  MFRC_t mfrc = { .CE = { .pin = 2, .port = B},
                   .RST = { .pin = 5, .port = D}};

  mfrc_init(&mfrc);

  uint8_t nuidPICC[10];

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

  bool req;
  RFID_Status card;


  while(1){

    //if(rec_flag)
    //{
    //  rec_flag = 0;
    //}

    //uart_transmit_string("AHOJ");

    //JoyXVal = adc_read(&JoystickX);
    //JoyXVal = ((JoyXVal)/double(1023))*(double)100;
    //JoyYVal = adc_read(&JoystickY);
    //JoyYVal = ((JoyYVal)/double(1023))*(double)100;

    req = mfrc_request_A(&mfrc);
    

    if (req){
      card = mfrc_read_UID(&mfrc);
      if ((card==ok)){
        for (byte i = 0; i < 4; i++) {
          nuidPICC[i] = mfrc.Uid[i];
          index += sprintf(&nuidChar[index], "%d", nuidPICC[i]);
        }
        index = 0; 
        strcat(help, nuidChar);
        card_read = 1;
      }
    }

    mfrc_card_halt(&mfrc);

    if(card_read){
      card_read = 0;
      uart_transmit_string(help);
      for (byte i = 0; i < 10; i++) {
        nuidPICC[i] = 0;
      }
      nuidChar[0] = '\0';
      help[2] = '\0';
    }
    else{
      uart_transmit_string("AHOJ");
    }

    delay(50);
  }
}
