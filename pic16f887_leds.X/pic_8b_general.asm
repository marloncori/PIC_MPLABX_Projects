
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
    I			; counter to call long delay some times
    J			; counter used in delay routine
    K			; counter used in delay routine
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
	BANK1
	MOVLW	    H'00'           ; bit0 input for button
	MOVWF	    TRISB           ; 4 inputs + 4 outputs

	BANK0
	MOVLW	    H'55'	    ; set LEDs on line 0 and 1
	MOVWF	    PORTB

; ====================================
;  toggle all leds wired to portb
; ====================================
BLINK_8
	COMF	    PORTB	    ; INVERT STATE
	MOVLW	    D'14'
	MOVWF	    I
FOR
	CALL	    LONG_DELAY
	DECFSZ	    I,F
	GOTO	    FOR
	GOTO	    BLINK_8

; ------------ SUBROUTINE 1 -----------------------------------------------------
; procedure meant to delay 10 machine cycles
DELAY
	MOVLW	    D'100'	    ; repeat 22 machine cycles
	MOVWF	    COUNT
REPEAT
	DECFSZ	    COUNT,F	    ; decrement counter
	GOTO	    REPEAT	    ; continue if not 0
	RETURN

; ------------ SUBROUTINE 2 -----------------------------------------------------
; THIS IS USED TO SLOW DOWN LED BLINKING
LONG_DELAY
	MOVLW	    D'400'
	MOVWF	    J		    ; endereco de onde se comeca a guardar variaveis
JLOOP
	MOVWF	    K
KLOOP
	DECFSZ	    K,F
	GOTO	    KLOOP
	
	DECFSZ	    J,F
	GOTO	    JLOOP
	CALL	    DELAY
	RETURN

; -----------------------------------------------------------------------------
	END