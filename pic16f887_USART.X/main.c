/*
 * File:   main.c
 * Author: NUC
 *
 * Created on 2022. október 19., 1:04
 */

// 'C' source line config statements

// CONFIG1
#pragma config FOSC = EXTRC_CLKOUT// Oscillator Selection bits (RC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, RC on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = ON      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = ON       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = ON      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR21V   // Brown-out Reset Selection bit (Brown-out Reset set to 2.1V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)
// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.
#include <xc.h>
/*----------------------------------------
* USART RECEIVE
* ----------------------------------------*/
#define FREQ    16000000
#define LED1    PORTDbits.RD0
#define LED2    PORTDbits.RD1
#define LED3    PORTBbits.RB2

unsigned char command;
typedef void(*func_t)(void);

typedef struct {
  unsigned char cmd;
  func_t toggle;
} action;

void toggleGreenLed(void);
void toggleRedLed(void);

void delay(unsigned long time);

void configUSART(void);
void enableInterrupt(void);
void configPORTs(void);

void blinkLed(void);

action ledControl[] = {
  {'1', toggleGreenLed}, {'2', toggleRedLed}
};

void __interrupt USART_ISR(void){
    if(RCIF){
      command = RCREG;
      for(unsigned char i=0; i<2; i++){
        if(command == ledControl[i].cmd)
             ledControl[i].toggle();
      }
    }
}

void main(){
 
   configUSART();
   enableInterrupt();
   configPORTs();	
   
   LED1 = 1;
   LED2 = 1;
   LED3 = 1;
   
   do{
     blinkLed();
   } while(1);
   
}

void delay(unsigned long time){
    for(unsigned long j=time; j>0; j--){
      for(unsigned long k=time/4; k>0; k--){   
      // count down...
      }
    }
}

void configUSART(void){
   TXSTA = 0x20;    // enable serial communication, low baud rate
   SPBRG = 25;      // 9600 baud rate, 8 bit, low speed, XTAL = 16 MHz		
   RCSTA = 0x90;    // serial port enable, continuous receive mode set 
}

void enableInterrupt(void){
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;
    PIE1bits.RCIE = 1;
}

void configPORTs(void){
   ANSEL  = 0x00; 
   ANSELH = 0x00;
   TRISD = 0x00;    // PORTD as output
   TRISB = 0x00;    // PORTD as output
}

void toggleGreenLed(void){ LED1 = ~LED1; }
void toggleRedLed(void){ LED2 = ~LED2; }

void blinkLed(void){
   LED3 = ~LED3;
   delay(4000000);
}


