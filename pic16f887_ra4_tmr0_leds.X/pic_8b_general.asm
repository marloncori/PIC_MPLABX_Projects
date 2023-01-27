
;
;  Create a STATE CHANGE every 5 button presses
;*******************************************************************************
#include "p16f887.inc"

; CONFIG1
; __config 0xE0D2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
 
; TODO PLACE VARIABLE DEFINITIONS GO HERE
 #define BANK0	  BCF STATUS,RP0
 #define BANK1	  BSF STATUS,RP0
 
;*******************************************************************************

; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************

; TODO INSERT ISR HERE
	ORG	H'0004'
        RETFIE
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
	; TODO Step #5 - Insert Your Program Here
	    BANK1
	    MOVLW	H'00'		    ; 
	    MOVWF	TRISB		    ; 8 outputs
	    MOVLW	H'FF'		    ; 
	    MOVWF	TRISA		    ; 8 inputs
	    CLRF	INTCON
	  
	; SETUP TIMER0 BY USING OPTION_REG  ; define o "clock" do tmr0
	    BSF		OPTION_REG,T0CS	    ; usado para incr o tmr0 por RA4
	    BSF		OPTION_REG,T0SE     ; define a forma de deteccao high-low
	    BSF		OPTION_REG,PSA	    ; desabilita o prescaler, use o WDT
 
	    BANK0
	    MOVLW	H'AA'
	    MOVWF	PORTB		    ; B'0000 0000', outputs
	    CLRF	TMR0

; ------------ MAIN ROUTINE ---------------------------------------------------
LOOP
	    BSF		INTCON,T0IF	    ; clear tmr0 flag
	    MOVLW	D'251'		    ; 256 - 5: 251. BUTTON has to pressed
					    ; 5 times a state change at portb
	    MOVWF	TMR0
	    BTFSS	INTCON,T0IF
	    GOTO	$ -1
	    
	    COMF	PORTB		    ; PORTB GOES TO H'55'
	    GOTO	LOOP
	    
; -----------------------------------------------------------------------------
	    END