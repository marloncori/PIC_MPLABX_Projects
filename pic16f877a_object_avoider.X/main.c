/*

Obstacle avoider using PIC16F877A

 * Code by: B.Aswinth Raj

 * Dated: 03-10-2017

 * More details at: www.CircuitDigest.com

 */


#include <xc.h>


#pragma config FOSC = HS        // Oscillator Selection bits (HS oscillator)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled)
#pragma config PWRTE = ON       // Power-up Timer Enable bit (PWRT enabled)
#pragma config BOREN = OFF       // Brown-out Reset Enable bit (BOR enabled)
#pragma config LVP = OFF        // Low-Voltage (Single-Supply) In-Circuit Serial Programming Enable bit (RB3 is digital I/O, HV on MCLR must be used for programming)
#pragma config CPD = OFF        // Data EEPROM Memory Code Protection bit (Data EEPROM code protection off)
#pragma config WRT = OFF        // Flash Program Memory Write Enable bits (Write protection off; all program memory may be written to by EECON control)
#pragma config CP = OFF         // Flash Program Memory Code Protection bit (Code protection off)

#define _XTAL_FREQ 16000000

#define Trigger RB1 //34 is Trigger
#define Echo RB2//35 is Echo 


int time_taken;
int distance;

     void back_off() //used to drive the robot backward
     {

      RC4=1; RC5=0; //Motor 1 reverse
      RC6=0; RC7=1; //Motor 2 reverse  

      __delay_ms(1000);   
     }

    
     void calculate_distance() //function to calculate distance of US
     {
         TMR1H =0; TMR1L =0; //clear the timer bits

        Trigger = 1; 
        __delay_us(10);           

        Trigger = 0;  

        while (!Echo);
            TMR1ON = 1;

        while (Echo);
            TMR1ON = 0;

        time_taken = (TMR1L | (TMR1H<<8)); 
         distance = (0.0272*time_taken)/2;        
     }

     

void main()
{

     TRISD = 0x00; //PORTD declared as output for interfacing LCD
     TRISB1 = 0; //Trigger pin of US sensor is sent as output pin
     TRISB2 = 1; //Echo pin of US sensor is set as input pin       
     TRISB3 = 0; //RB3 is output pin for LED

     TRISD2 = 1; TRISD3 = 1; //Both the IR sensor pins are declared as input
     TRISC4 = 0; TRISC5 = 0; //Motor 1 pins declared as output
     TRISC6 = 0; TRISC7 = 0; //Motor 2 pins declared as output

     T1CON=0x20;
     
     while(1){

         calculate_distance();        
        if (distance>5)
        {
          RC4=0; RC5=1; //Motor 1 forward
          RC6=1; RC7=0; //Motor 2 forward
        }

         calculate_distance();   
         if (RD2==0 && RD3==1 && distance<=5) //Left sensor is blocked
         {
           back_off();

           RC4=1; RC5=1; //Motor 1 stop
           RC6=1; RC7=0; //Motor 2 forward  
           __delay_ms(500);
         }

          calculate_distance();   

         if (RD2==1 && RD3==0 && distance<=5) //Right sensor is blocked
         {
           back_off();
           
           RC4=0; RC5=1; //Motor 1 forward
           RC6=1; RC7=1; //Motor 2 stop
           __delay_ms(500);
         } 

          calculate_distance();   
         if (RD2==0 && RD3==0 && distance<=5)//Both sensor is open
         {
           back_off();
           RC4=0; RC5=1; //Motor 1 forward
           RC6=1; RC7=1; //Motor 2 stop
           __delay_ms(500);
         }

          calculate_distance();       
         if (RD2==1 && RD3==1 && distance<=5)//Both sensor is blocked
         {
           back_off(); 
           RC4=1; RC5=0; //Motor 1 reverse
           RC6=1; RC7=1; //Motor 2 stop  
           __delay_ms(1000);
         }
           
    }
     
}

