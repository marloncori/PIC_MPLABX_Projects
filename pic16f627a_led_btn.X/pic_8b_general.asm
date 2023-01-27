;*******************************************************************************
; TODO INSERT CONFIG HERE
#include "p16f627a.inc"

; CONFIG
; __config 0xFF19
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 #define BANK0	BCF STATUS,RP0
 #define BANK1	BSF STATUS,RP0
 
 #define LED	PORTB,RB0
 #define BTN	PORTB,RA1
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************

;*******************************************************************************
; TODO INSERT ISR HERE
	ORG	    H'0004'
        RETFIE
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
	BANK1
	MOVLW	    H'00'           ; your instructions
	MOVWF	    TRISB           ; output
	
	MOVLW	    H'02'           ; your instructions
	MOVWF	    TRISA           ; output

	BANK0
	MOVLW	    H'00'
	MOVWF	    PORTB	    ; b'00000000
	
	MOVLW	    H'02'
	MOVWF	    PORTA	    ; b'00000010

CONTROL
	BTFSS	    BTN		    ; test, skip next line
				    ; if bit is set
	GOTO	    TURN_OFF
				    ; at this portA bit 0 is not set
	; switch is pressed, active low action
	BSF	    LED		    ; RB0 is high
	GOTO	    CONTROL

TURN_OFF
	BCF	    LED
	GOTO	    CONTROL 
	
;*******************************************************************************
    END