/*
 * File:   main.c
 * Author: NUC
 *
 * Created on 2022. szeptember 21., 2:01
 */

// CONFIG
#pragma config FOSC = HS        // Oscillator Selection bits (HS oscillator)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled)
#pragma config PWRTE = ON      // Power-up Timer Enable bit (PWRT disabled)
#pragma config BOREN = ON       // Brown-out Reset Enable bit (BOR enabled)
#pragma config LVP = OFF         // Low-Voltage (Single-Supply) In-Circuit Serial Programming Enable bit (RB3/PGM pin has PGM function; low-voltage programming enabled)
#pragma config CPD = OFF        // Data EEPROM Memory Code Protection bit (Data EEPROM code protection off)
#pragma config WRT = OFF        // Flash Program Memory Write Enable bits (Write protection off; all program memory may be written to by EECON control)
#pragma config CP = OFF         // Flash Program Memory Code Protection bit (Code protection off)

#include <xc.h>
#define _XTAL_FREQ 16000000

void initialize();
void blink_next_led();
void interrupt_init(void);

unsigned int counter = 0;

void interrupt toggle_ISR(void){
    if(INTCONbits.TMR0IE && INTCONbits.TMR0IF){
        if(counter == 16){
            blink_next_led();
        }
        else {
          counter++;
        }
        INTCONbits.TMR0IF = 0x00;
    }
}

void main(void){

   initialize();
   interrupt_init();
   
   do {
     blink_next_led();
   } while(1);
}

void initialize(){
   CMCON  = 0x07;   // turn off comparators 
   TRISA  = 0x00;   // portc as output
   PORTA  = 0x00;  // bits cleared
}

void blink_next_led(){
   PORTC = (PORTC << 1);
   if(!PORTC){
       // begin cycle again
       PORTC = 1;
   }
}

void interrupt_init(void){
   OPTION_REG = 0x86;  /* disable pull-up, bit6 for external interruption
                        bit5, zero, for tmr to increment, bit 4 equals 0
                        bit 3 is zero, for the psa to be assigned to tmr0
                        bit 2-0 --> 110 (0x06) for a 1:128 prescaler
                       final setting: 1000 0110, in hex 0x86
                     */
  
  // config INTCON register bits 7, 6 and 5
   INTCONbits.GIE  = 0x01;    // global interruption
   INTCONbits.PEIE = 0x01;    // peripheral interruption
   INTCONbits.T0IE = 0x01;    // timer0 interruption
              TMR0 = 0x00;    // starts at 00
   /* calculate timing:
    16Mhz / 4 = 4Mhz
    1 / 4Mhz = 0.000004 = 4us 
    8bits max count = 256
    prescaler 128, overflow after 128 instuction cycles
    0.000004 * 256 * 128 = 131.072 ms per cycle
    * 0.131072 * 12 = 1.572864 (almost 1.5 seconds)
      0.131072 * 16 = 2.097152 (almost 2 seconds)
    */
}