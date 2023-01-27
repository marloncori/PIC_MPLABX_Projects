
;*******************************************************************************
#include "p16f887.inc"

; CONFIG1
; __config 0xE0D2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

 ; CONFIG2
; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
 
; TODO PLACE VARIABLE DEFINITIONS GO HERE
 #define BANK0	BCF STATUS,RP0
 #define BANK1	BSF STATUS,RP0
 
;******************************************************************************
  cblock	H'20'	; REGISTRADORES DE USO GERAL, 'VARIAVEIS
			; INICIO DO REGISTRADOR
     I			; variable to call tmr0_delay some times
    COUNT		; auxiliary counter
  endc
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************

; TODO INSERT ISR HERE
	ORG	    H'0004'
        RETFIE
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
	MOVLW	    H'00'
	MOVWF	    ANSEL	    ; configure all pins as digital
	CLRWDT
	BANK1
	MOVLW	    H'D7'	    ; B'11010111'
	MOVWF	    OPTION_REG	    
	; bit7 - rbpu (internal pull-ups), 0 enable, 1 disabled
	; bit6 - intedg, 0 falling edge, 1 raising edge
	; bit5 - tocs (tmr0 clock src), 0 - interal clock, 1 ra4/tockI bit src
	; bit4 - tose (tmr0 edge select), 0 inc low-to-high, 1 inc high-to-low
	; bit3 - psa (prescaler assing) 1 to WDT, 0 to timer0
	; bit2-0: value for timer0 prescaler --> 101 = 1:64, 111 = 1:256 (max)
	; 000 = 1:2, 010 = 1:8, 100 = 1:32, 110 = 1:128, 001 = 1:3, 011 = 1:16
	MOVLW	    H'00'           ; bit0 input for button
	MOVWF	    TRISB           ; 4 inputs + 4 outputs

	BANK0
	MOVLW	    H'00'	    ; set LEDs on line 0 and 1
	MOVWF	    PORTB

; ====================================
;  toggle all leds wired to portb
; ====================================
MAIN
	INCF	    PORTB,F	    ; INCREMENT bit values, one by one
	MOVLW	    D'10'
	MOVWF	    I
FOR
	CALL	    TMR0_DELAY
	DECFSZ	    I,F
	GOTO	    FOR
	GOTO	    MAIN

; ------------ SUBROUTINE 1 -----------------------------------------------------
; procedure meant to delay 10 machine cycles
DELAY
	MOVLW	    D'10'	    ; repeat 22 machine cycles
	MOVWF	    COUNT
REPEAT
	DECFSZ	    COUNT,F	    ; decrement counter
	GOTO	    REPEAT	    ; continue if not 0
	RETURN

; ------------ SUBROUTINE -----------------------------------------------------
; THIS IS USED TO SLOW DOWN LED BLINKING
TMR0_DELAY
	CLRF	    TMR0	    ; clear SFR for timer0
; routine tests the value in the TMR0 by subtracting 0xff from
; the value in TMR0. The zero flag is set if TMR = 0xff
; substraction is done for TMR0 overflow to be detect, since GOTO
; take two machine cycles, a detection would occur otherwise.
CYCLE
	MOVF	    TMR0,W	    ; read timer0 value, store it in W
	SUBLW	    H'FF'	    ; subtract max value
	
; now zero flag is set if value in tmr0 = 0xFF
	CALL	    DELAY
	BTFSS	    STATUS,Z	    ; test for zero value
	GOTO	    CYCLE
	RETURN

; -----------------------------------------------------------------------------
	END