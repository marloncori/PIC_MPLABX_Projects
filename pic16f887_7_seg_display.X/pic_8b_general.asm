;
;  SEVEN SEGMENT DISPLAY, COMMON CATHODE ( - ), RB1 - RB7
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
 
 ; LCD wiring to pic
 #define ZERO	 B'01111110'
 #define ONE	 B'00001100'
 #define TWO	 B'10110110'
 #define THREE	 B'10011110'
 #define FOUR    B'11001100'
 #define FIVE	 B'11011010'
 #define SIX	 B'11111010'
 #define SEVEN   B'00001110'
 #define EIGHT   B'11111110'
 #define NINE    B'11011110'
 
;*******************************************************************************
  TIME1   EQU H'20'
  TIME2   EQU H'21'
  TIME3	  EQU H'22'   
	
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
	    MOVLW	H'01'		    ; b'0000 0001'
	    MOVWF	TRISB		    ; 7 outputs
	  
	    BANK0
	    CLRF	PORTB
	    BTFSC	PORTB,RB0	    ; button is wired to this pin
	    GOTO	$ -1
	    GOTO	DISPLAY		    ; when btn is pressed, init DISPLAY
	    
; ------------ MAIN ROUTINE ---------------------------------------------------
DISPLAY
	    MOVLW	ZERO
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    MOVLW	ONE
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    MOVLW	TWO
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    MOVLW	THREE
	    MOVWF	PORTB
	    CALL	WAIT

	    MOVLW	FOUR
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    MOVLW	FIVE
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    MOVLW	SIX
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    MOVLW	SEVEN
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    MOVLW	EIGHT
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    MOVLW	NINE
	    MOVWF	PORTB
	    CALL	WAIT
	    
	    GOTO	DISPLAY
	    
; ========================= DELAY SUBROUTINE ===================================
WAIT
	    MOVLW	D'10'
	    MOVWF	TIME1
	    
FOR_1	    MOVLW	D'100'
	    MOVWF	TIME2
	    
FOR_2	    MOVLW	D'250'
	    MOVWF	TIME3
	    
FOR_3	    DECFSZ	TIME3
	    GOTO	FOR_3
	    
	    DECFSZ	TIME2
	    GOTO	FOR_2
	    
	    DECFSZ	TIME1
	    GOTO	FOR_1
	    RETURN
; -----------------------------------------------------------------------------
	    
	    END