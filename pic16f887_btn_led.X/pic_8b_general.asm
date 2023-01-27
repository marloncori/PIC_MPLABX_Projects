
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
    COUNT
    COUNT2
    TIME1
    TIME2
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
	    BANK1
	    MOVLW	H'01'           ; bit0 input for button
	    MOVWF	TRISB           ; 7 outputs + 1 input
	
	    BANK0
	    MOVLW	H'00'
	    MOVWF	PORTB	    ; B'0000 0001'

PRESS_DETECT
	    BTFSC	BUTTON
	    
	    GOTO	TURN_OFF
	    CALL	TURN_ON
	    
	    GOTO	PRESS_DETECT
	
; ------------ SUBROUTINE 1 -----------------------------------------------------
; procedure meant to delay 10 machine cycles
DELAY
	MOVLW	    D'4'	    ; repeat 12 machine cycles
	MOVWF	    TIME1
REPEAT
	DECFSZ	    TIME1,F	    ; decrement counter
	GOTO	    REPEAT	    ; continue if not 0
	RETURN
; ------------ SUBROUTINE 2 -----------------------------------------------------
DEBOUNCE
	MOVLW	    H'FF'
	MOVWF	    COUNT2	; endereco de onde se comeca a guardar variaveis
JLOOP
	MOVWF	    TIME2
KLOOP
	DECFSZ	    TIME2,F
	GOTO	    KLOOP
	
	DECFSZ	    COUNT2,F
	GOTO	    JLOOP
	CALL	    DELAY
	GOTO	    PRESS_DETECT
; -----------------------------------------------------------------------------
TURN_OFF
	BCF	LED
	GOTO	DEBOUNCE
; -----------------------------------------------------------------------------
TURN_ON
	BSF	LED
	GOTO	DEBOUNCE
; -----------------------------------------------------------------------------
	END