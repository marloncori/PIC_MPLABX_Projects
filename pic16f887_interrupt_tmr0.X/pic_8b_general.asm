
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
CBLOCK	    H'20'
  AUX
  OLD_STATUS
  OLD_W
ENDC
  
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************

; TODO INSERT ISR HERE
	ORG	H'0004'		; WITH D'8' AND D'12' creates a 500ms delay

	; SAVE CONTEXT
	MOVWF	    OLD_W	    ; save context in W register
	SWAPF	    STATUS,W	    ; set STATUS to W
	BANK0			    ; select bank 0 (default for reset)
	MOVWF	    OLD_STATUS	    ; save STATUS

	MOVLW	D'16'
	MOVWF	AUX
	
 REPEAT	BCF	INTCON,T0IF
	MOVLW	D'24'
	MOVWF	TMR0
	
	BTFSS	INTCON,T0IF
	GOTO	$ -1
	DECFSZ	AUX
	GOTO	REPEAT
	COMF	PORTB

	; RESTORE CONTEXT
	SWAPF	    OLD_STATUS,W    ; saved status to W
	MOVFW	    STATUS	    ; to STATUS register
	SWAPF	    OLD_W,F	    ; swap File reg in itself
	SWAPF	    OLD_W,W	    ; re-swap back to W
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
	  
	    BCF		OPTION_REG,T0CS	    ; usado para incr o tmr0 por OSC
	    BCF		OPTION_REG,PSA	    ; abilita o prescaler
	    BSF		OPTION_REG,PS2	    ; 
	    BSF		OPTION_REG,PS1	    ; 
	    BSF		OPTION_REG,PS0	    ; 1:256
	    
	    BSF		OPTION_REG,GIE	    ; habilita interrupcao global
	    BSF		OPTION_REG,T0IE	    ; habilita interrupcao por tmr0
 
	    BANK0
	    MOVLW	H'F0'
	    MOVWF	PORTB		    ; B'0000 0000', outputs
	    CLRF	TMR0

; ------------ MAIN ROUTINE ---------------------------------------------------

	    GOTO	$		    ; wait untill timer0 overflows
					    ; so as to change PORTB state
; -----------------------------------------------------------------------------
	    END