/*
 * File:   main.c
 * Author: NUC
 *
 * Created on 2022. szeptember 21., 1:50
 */
// CONFIG
#pragma config FOSC = HS        // Oscillator Selection bits (HS oscillator)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config BOREN = ON       // Brown-out Reset Enable bit (BOR enabled)
#pragma config LVP = OFF         // Low-Voltage (Single-Supply) In-Circuit Serial Programming Enable bit (RB3/PGM pin has PGM function; low-voltage programming enabled)
#pragma config CPD = OFF        // Data EEPROM Memory Code Protection bit (Data EEPROM code protection off)
#pragma config WRT = OFF        // Flash Program Memory Write Enable bits (Write protection off; all program memory may be written to by EECON control)
#pragma config CP = OFF         // Flash Program Memory Code Protection bit (Code protection off)

#include <xc.h>
#define _XTAL_FREQ 16000000

void initialize(void);
void blink_led(void);

void main(void) {

   initialize();

   do {
     blink_led();
   } while(1);
}

void initialize(void){   
   ADCON1 = 0x0F // a/d module not use, all pin as digital outputs 
   TRISC  = 0x00;     // portc as output
   PORTC  = 0x01;  //bit zero high
}

void blink_led(void){
   PORTC |= 0x01;
   //or PORTCbits.RC7 = 1;
   __delay_ms(1000);
   PORTC &= ~0x01;
   //or PORTCbits.RC7 = 0;
   __delay_ms(1000);
}
