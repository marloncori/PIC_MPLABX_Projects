
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
 
 #define BUTTON	PORTB,RB0
 #define LED	PORTB,RB7
;******************************************************************************
  cblock	H'20'	; REGISTRADORES DE USO GERAL, 'VARIAVEIS
			; INICIO DO REGISTRADOR
    COUNT1
    COUNT2
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
	; TODO Step #5 - Insert Your Program Here
	    BANK1			; B'0111 1111'
	    MOVLW	H'7F'           ; bit7 as output for button
	    MOVWF	TRISB           ; 7 outputs + 1 input
	
	    BANK0
	    MOVLW	H'00'
	    MOVWF	PORTB	    ; B'0000 0000'

PRESS_DETECT
	    BTFSS	BUTTON	    ; button wired to Vcc through a 5k Ohm resistor
	    GOTO	$ -1	    ; go back to previous line
	    CALL	TOGGLE
	    GOTO	PRESS_DETECT
	
; ------------ SUBROUTINES -----------------------------------------------------
DEBOUNCE
	MOVLW	    H'FF'
	MOVWF	    COUNT1	; endereco de onde se comeca a guardar variaveis
REPEAT
	MOVWF	    COUNT2
CLOOP
	NOP
	DECFSZ	    COUNT2
	GOTO	    CLOOP
	
	DECFSZ	    COUNT1
	GOTO	    REPEAT
	GOTO	    PRESS_DETECT

; -----------------------------------------------------------------------------
TOGGLE
	COMF 	LED
	GOTO	DEBOUNCE

; -----------------------------------------------------------------------------
	END