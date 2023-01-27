
;
;  Create a 500 ms delay for a led to toggle its state regularly
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
; USER-DEFINED GENERAL PURPOSE REGISTER
  AUX  EQU  H'20'
 
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
	    CLRF	INTCON
	  
	; SETUP TIMER0 BY USING OPTION_REG
	    BCF		OPTION_REG,T0CS
	    BCF		OPTION_REG,PSA
	    BSF		OPTION_REG,PS2
	    BSF		OPTION_REG,PS1
	    BSF		OPTION_REG,PS0      ; PRESCALER 1:256
 
	    BANK0
	    MOVLW	H'00'
	    MOVWF	PORTB		    ; B'0000 0000', outputs
	    CLRF	TMR0

; ------------ MAIN ROUTINE ---------------------------------------------------
LOOP
	    COMF	PORTB
	    CALL	TIMING
	    
	    ADDWF	PORTB
	    CALL	TIMING
	    
	    SWAPF	PORTB
	    CALL	TIMING

   	    XORWF	PORTB
	    CALL	TIMING

	    GOTO	LOOP
	    
; ------------ SUBROUTINES ------------------------------------------------------
TIMING					    ; as timer0 counts till 255
	    MOVLW	D'8'		    ; it will be multipled by 256
	    MOVWF	AUX		    ; times 8 repetitions
					    ; that equals 522240 us
REPEAT	    BCF		INTCON,T0IF	    ; which represents 522 ms
	    MOVLW	D'12'		    ; or 1448 ms if AUX = 16
	    MOVWF	TMR0
	    
	    BTFSS	INTCON,T0IF	    ; ROUTINE will be caught here
	    GOTO	$ -1		    ; till timer0 overflows
	    DECFSZ	AUX
	    GOTO	REPEAT

	    RETURN
; -----------------------------------------------------------------------------
	    END