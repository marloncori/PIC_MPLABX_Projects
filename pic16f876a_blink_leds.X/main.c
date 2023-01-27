/*
 * File:   main.c
 * Author: NUC
 *
 * Created on 2022. szeptember 21., 2:01
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
#define _XTAL_FREQ 8000000

void initialize();
void blink_next_led();

void main(void){

   initialize();

   do {
     blink_next_led();
   } while(1);
}

void initialize(){
   CMCON = 0x07; // a/d module not use, all pin as digital outputs 
   TRISB  = 0x00;     // portb as output
   PORTB  = 0x01;  //bit zero high
}

void blink_next_led(){
   __delay_ms(1000);
   PORTB = (PORTB << 1);
   if(!PORTB){
       // begin cycle again
       PORTB = 0x01;
   }
}
