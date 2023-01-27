
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
  AUX    EQU H'20'
  COUNT  EQU H'21'
  TIME	 EQU H'22'   
	
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************

; TODO INSERT ISR HERE
	ORG	H'0004'		; WITH D'8' AND D'12' creates a 500ms delay
	
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
	  
	    BSF		OPTION_REG,PSA	    ; abilita o prescaler para o WDT
	    
	    BSF		OPTION_REG,PS2	    ; WDT works every 18ms
	    BCF		OPTION_REG,PS1	    ; 1:32
	    BSF		OPTION_REG,PS0	    ; 32 * 18 = reset every 576 ms
	    
	    BANK0
	    MOVLW	H'00'
	    MOVWF	PORTB		    ; B'0000 0000', outputs

; ------------ MAIN ROUTINE ---------------------------------------------------
LED1
	    BSF		PORTB,RB7
	    BCF		PORTB,RB6
	    CALL	WAIT
	    CLRWDT
	    GOTO	LED2

LED2
	    BSF		PORTB,RB6
	    BCF		PORTB,RB7
	    CALL	WAIT
	    CLRWDT
	    GOTO	LED1

; -----------------------------------------------------------------------------
WAIT
	    MOVLW	H'FA'
	    MOVWF	AUX
LOOP
	    MOVLW	H'FA'
	    MOVWF	TIME
	    MOVLW	D'2'
	    MOVF	COUNT
REPEAT
	    DECFSZ	COUNT
	    GOTO	REPEAT
	    DECFSZ	TIME
	    GOTO	$ -5
	    
	    DECFSZ	AUX
	    GOTO	LOOP
	    
	    RETURN
; -----------------------------------------------------------------------------
	    
	    END