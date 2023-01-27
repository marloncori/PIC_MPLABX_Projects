/*
 * File:   main.c
 * Author: NUC
 *
 * Created on 2022. szeptember 21., 1:50
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

void initialize(void);
void blink_leds(void);
void interrupt_init(void);

unsigned int counter = 0;

void interrupt toggle_ISR(void){
    if(INTCONbits.TMR0IE && INTCONbits.TMR0IF){
        if(counter == 16){
           blink_leds();
           counter = 0;
        }
        else {
           counter++;
        }
        INTCONbits.TMR0IF = 0x00;
                     TMR0 = 0x00;
    }
}

void main(void) {

   initialize();
   interrupt_init();
   
   do {
    // 
    // ISR
   } while(1);
}

void initialize(void){   
   CMCON  = 0x07;    // turn off comparators 
   TRISB  = 0x00;    // portb as output
   PORTB  = 0x02;    //  bit 1 high
}

void blink_leds(void){
   PORTBbits.RB0 = ~PORTBbits.RB0;
   PORTBbits.RB1 = ~PORTBbits.RB1;
   PORTBbits.RB2 = ~PORTBbits.RB2;
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