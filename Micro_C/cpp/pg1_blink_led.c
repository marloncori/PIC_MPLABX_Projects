// project 2, led blink
#include <pic.h>
//#define _XTAL_FREQ 8000000
#define _XTAL_FREQ 16000000

void initialize();
void blink_led();

void main(void){

   initialize();

   do {
     blink_led();
   } while(1):
}

void initialize(){
   ANSEL  = 0;     // all pins as digital output
   ANSELH = 0;
   TRISC  = 0;     // portc as output
   PORTC  = 0x01;  //bit zero high
}

void blink_led(){
   PORTC |= 0x01;
   __delay_ms(1000);
   PORTC &= ~0x01;
   __delay_ms(1000);
}