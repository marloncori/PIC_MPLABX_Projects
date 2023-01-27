;*******************************************************************************
;  Program to use external interrupt on port RB0. It terminates the power-down
;    state cuased by the SLEEP instruction. A pushbutton is connected to port
;  RB0 and it generates the interrupt to wake the MCU up. A LED on portB, line 1, 
;    flashes on and off at 1/2 second intervals
;*******************************************************************************
#include "p16f887.inc"
    
; __config 0xE0D7
 __CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 cblock		H'200'
   I				; a counter register
   J				; a counter register
   K				; another counter register
   count1			; auxiliary counter
   count2			; ISR counter
 endc
 
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
;*******************************************************************************
    org		H'0004'
    goto    IntServ
    
; TODO INSERT ISR HERE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                     ; let linker place main program

START:
    ; set up interrupt on falling edge by
    ; clearing OPTION register bit 6
    ; BCF STATUS,RP1  (BCF   STATUS,RP0) -> goto bank 0
    ; BSF STATUS,RP1  goto bank 1
    ; BSF STATUS,RP1  +  BCF   STATUS,RP0 -> goto bank 2
    ; BSF STATUS,RP1  +  BSF   STATUS,RP0 -> goto bank 3
;------------------------------------------------------------------    
    BSF	    STATUS, RP0		   ; select bank 1  
    MOVLW   H'BF'                  ; b'10111111
    MOVWF   OPTION_REG
    MOVLW   H'FF'                  ; b'11111111
    MOVWF   TRISA		   ; set port A for input
    MOVLW   H'01'                  ; b'00000001
    MOVWF   TRISB		   ; set port B bit 0 as input
    MOVWF   IOCB		   ; enable RB0 state change
;------------------------------------------------------------------    
    BCF	    STATUS,RP0		   ; select bank 0
    CLRF    PORTB		   ; all portB pins to 0
    BSF	    PORTB, RB0		   ; set line 0 bit to turn on led 
;------------------------------------------------------------------
    BSF	    STATUS, RP1		   ; 
    BCF	    STATUS, RP0		   ; select bank 2
    BCF	    CM1CON0, C1ON	   ; turn off comparator 1
    BCF	    CM2CON0, C2ON	   ; turn off comparator 2
;------------------------------------------------------------------    
    BSF	    STATUS,RP0		   ; select bank 3
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   ANSELH		   ; all ports as digital output
    
;*******************************************************************************
; INTERRUPT SETUP
;*******************************************************************************
    BCF	    INTCON, INTF	   ; clear the external interrupt flag
    BSF	    INTCON, GIE		   ; enable global interrupts
    BSF	    INTCON, RBIE	   ; enable rb0 interrupt
    
;*******************************************************************************
;   FLASH LED 20 times
;*******************************************************************************
WAKE_UP:
    ; program flashes LED wired to portb, line 2
    ; 20 times before entering sleep mode
    MOVLW   D'3'
    MOVWF   I
    MOVLW   D'20'
    MOVWF   count2		   ; prepare counter for the 3 time loop
LIGHTS:
    MOVLW   H'02'		   ; copy b'00000010 to W register
    XORWF   PORTB, F		   ; invert port state
L1: CALL    LongDelay		   ; call LongDelay subroutine 3 times
    DECFSZ  I, F
    GOTO    L1			   ; skip this line of code if i = 0
    DECFSZ  count2, F
    GOTO    LIGHTS		   ; repeat main routine 20 times
    SLEEP
    NOP				   ; recommeded step
    GOTO    WAKE_UP		   ; resume execution
    
;*******************************************************************************
; INTERRUPT SERVICE ROUTINE
;*******************************************************************************
IntServ:
    ; first, test if source is an RB0 interrupt
    BTFSS   INTCON, INTF
    RETFIE
    
;*******************************************************************************
; SUBROUTINES
;******************************************************************************* 
LongDelay:
    MOVLW   D'200'
    MOVWF   J
Jloop:
    MOVWF   K
Kloop:
    DECFSZ  K, F		 ; skip next opcode if K = 0
    GOTO    Kloop
    DECFSZ  J, F
    GOTO    Jloop
    RETURN
    
;*******************************************************************************    
    END