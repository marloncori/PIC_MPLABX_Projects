;
;  LCD CONNECTIONS: rs:rb2, rw:vss, en:rb3, d4:rb4, d5:rb5, d6:rb6, d7:rb7
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
 #define RS_PIN	  PORTB,RB2 ; CHOOSE COMMAND OR WRITING MODE
 #define EN_PIN   PORTB,RB1 ; ENABLE INFORMATION
 
;*******************************************************************************
  TIME1   EQU H'20'
  TIME2   EQU H'21'
  COUNT	  EQU H'22'   
	
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
	    MOVLW	H'03'		    ; b'0000 0011'
	    MOVWF	TRISB		    ; 8 outputs
	  
	    BANK0
	    BTFSC	PORTB,RB0	    ; button is wired to this pin
	    GOTO	$ -1
	    GOTO	INIT_LCD	    ; when btn is pressed, init LCD

; ------------ MAIN ROUTINE ---------------------------------------------------
INIT_LCD
	    MOVLW	B'0011000'	    ; SET D4 and D5 to HIGH level
	    MOVWF	PORTB
	
	    MOVLW	D'3'
	    MOVWF	COUNT
	    
REPEAT_3    BSF		EN_PIN		; set and clear ENABLE three times
	    BCF		EN_PIN
	    CALL	WAIT
	    DECFSZ	COUNT
	    GOTO	REPEAT_3 
	    
	    MOVLW	B'00100000'
	    MOVWF	PORTB
	    
	    MOVLW	D'2'
	    MOVWF	COUNT
	    
REPEAT_2    BSF		EN_PIN		; set and clear ENABLE twice
	    BCF		EN_PIN
	    CALL	WAIT
	    DECFSZ	COUNT
	    GOTO	REPEAT_2 
	    
	    MOVLW	B'10000000'
	    MOVWF	PORTB
	    
	    BSF		EN_PIN		; set and clear ENABLE once
	    BCF		EN_PIN
	    CALL	WAIT
	    
	    CLRF	PORTB
	    
	    BSF		EN_PIN		; set and clear ENABLE ONCE
	    BCF		EN_PIN
	    CALL	WAIT
	    
	    MOVLW	H'F0'		; D7, D6, D5, D4 at high level
	    MOVWF	PORTB

	    BSF		EN_PIN		; set and clear ENABLE ONCE
	    BCF		EN_PIN
	    CALL	WAIT
; ---------------------------- ROUTINE ----------------------------------------
	    
	    BTFSC	PORTB,RB1
	    GOTO	$ -1
	    GOTO	LCD_WRITE

; -----------------------------------------------------------------------------
LCD_WRITE
; == LETTER 'C' ====================
	    MOVLW	B'01000100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
	    MOVLW	B'00110100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
; == LETTER 'A' ====================
	    MOVLW	B'01000100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
	    MOVLW	B'00010100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
; == LETTER 'N' ======================
	    MOVLW	B'01000100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
	    MOVLW	B'11100100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
; == LETTER 'A' =====================
	    MOVLW	B'01000100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
	    MOVLW	B'00010100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
; == LETTER 'L' =====================
	    MOVLW	B'01000100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT
	    
	    MOVLW	B'11000100'
	    MOVWF	PORTB
	    BSF		EN_PIN
	    BCF		EN_PIN
	    CALL	WAIT

; ========================= DELAY SUBROUTINE ===================================
WAIT
	    MOVLW	D'100'
	    MOVWF	TIME1
	    
FOR	    MOVLW	D'255'
	    MOVWF	TIME2
	    DECFSZ	TIME2
	    GOTO	$ -1
	    DECFSZ	TIME1
	    GOTO	FOR
	    
	    RETURN
; -----------------------------------------------------------------------------
	    
	    END