;=================================================================
#include "p12f675.inc"

; __config 0xF1B5
 __CONFIG _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _CP_OFF & _CPD_OFF

;=================================================================
; MACROS
;============================================================
; Macros to select the register banks
Bank0	MACRO		    ; Select RAM bank 0
	BCF	STATUS,RP0
	ENDM
;----------------------------------------------
Bank1	MACRO		    ; Select RAM bank 1
	BSF	STATUS,RP0
	ENDM	
;===============================================================================
; variables in PIC RAM
;===============================================================================	
; Constant value	
OFFSET	   EQU	    H'0C'	
;-------------------------------------------------------------------------------
	   
; Global variables
CBLOCK		 H'20'   ; Start of memory block
    count1
    count2
    count3
    count4
ENDC
;===============================================================================
RES_VECT  CODE    H'0000'           ; processor reset vector
    GOTO    START                   ; go to beginning of program
;===============================================================================
; add interrupts here if used
    ORG	    H'0004'
    REFTIE
;===============================================================================    
; PROGRAM
;===============================================================================
MAIN_PROG CODE                      ; let linker place main program

START
    Bank0	    
    CLRF    GPIO		    ; clear gpio
    MOVLW   H'07'		    ; copy value to W reg
    MOVWF   CMCON		    ; turn off comparators
    ;---------------------------------------------------------------------------
    Bank1			    ; select bank 1  
    CLRF    ANSEL		    ; gpio as digital
    CLRF    TRISIO                  ; clear port to set it as output 
				    ; this is done according to the datasheet --
    CALL    3FFh		    ; get CALL value to callibrate
    MOVWF   OSCCAL		    ; the 4 MHz internal oscillator ------------
    MOVLW   H'85'		    ; B'1000 0101', prescaler 1:256
    MOVWF   OPTION_REG	    
	; bit7 - rbpu (internal pull-ups), 0 enable, 1 disabled
	; bit6 - intedg, 0 falling edge, 1 raising edge
	; bit5 - tocs (tmr0 clock src), 0 - interal clock, 1 ra4/tockI bit src
	; bit4 - tose (tmr0 edge select), 0 inc low-to-high, 1 inc high-to-low
	; bit3 - psa (prescaler assing) 1 to WDT, 0 to timer0
	; bit2-0: value for timer0 prescaler --> *101* = 1:64, 111 = 1:256**
	; 000 = 1:2, 010 = 1:8, 100 = 1:32, 110 = 1:128, 001 = 1:3, 011 = 1:16
	
;-------------------------------------------------------------------------------    
    Bank0			    ; go back bank 0
    CLRF    GPIO		    ; set all gpio as output
    CLRWDT			    ; clear watchdog timer
    
;*******************************************************************************
;   Main routine
;*******************************************************************************
MAIN
    
    CALL    BLINK_LEDS
    GOTO    MAIN

;*******************************************************************************
;   subroutines
;*******************************************************************************
BLINK_LEDS
    
    CLRF    TMR0				    ; since the prescaler is 
    BCF	    INTCON, T0IF			    ; 1:64, so 0.016384 s is the
    MOVLW   D'31'				    ; overflow, wich should be
    MOVWF   count1				    ; counted 31 times.
    MOVLW   D'62'				    ; overflow, wich should be
    MOVWF   count2				    ; counted 31 times.
    MOVLW   D'124'				    ; overflow, wich should be
    MOVWF   count3				    ; counted 31 times.
    MOVLW   D'248'				    ; overflow, wich should be
    MOVWF   count4				    ; counted 31 times.
L1  BTFSS   INTCON, T0IF			    ; when TMR0 counts up to
    GOTO    L1					    ; 255, the flag is set
    CLRF    TMR0
    BCF	    INTCON, T0IF
TASK1  
    DECFSZ  count1				    ; a cycle of 31 overflows
    GOTO    L1					    ; is need to create a 0.5 s
    MOVLW   (1<<GP0) 				    ; delay, use 62 for 1 sec
    XORWF   GPIO
    MOVLW   D'31'
    MOVWF   count1
TASK2    
    DECFSZ  count2				    ; a cycle of 62 overflows
    GOTO    L1					    ; is needed to create a
    MOVLW   (1<<GP1) 				    ; one second-long delay
    XORWF   GPIO
    MOVLW   D'62'
    MOVWF   count2
TASK3  
    DECFSZ  count3				    ; a cycle of 62*2 overflows
    GOTO    L1					    ; is needed to create a
    MOVLW   (1<<GP2) 				    ; 2 second delay
    XORWF   GPIO
    MOVLW   D'124'
    MOVWF   count3
TASK4  
    DECFSZ  count4				    ; a cycle of 124*2 overflows
    GOTO    L1					    ; is needed to create a
    MOVLW   (1<<GP4) 				    ; 4 second delay
    XORWF   GPIO
    MOVLW   D'248'
    MOVWF   count4
  
    RETURN
;*******************************************************************************
;   end of program
;*******************************************************************************
    END