;*******************************************************************************
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
AUX	   EQU  H'20'
counter    EQU	H'21'   
pointer    EQU  H'22'
lastIndex  EQU  H'23'
  
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
	    BANK1
	    MOVLW	H'00'		    ; 
	    MOVWF	TRISB		    ; 8 outputs
	    CLRF	INTCON		    ; not interrupt enabled
	    BCF		OPTION_REG,T0CS	    ; external clock
	    BCF		OPTION_REG,PSA	    ; assigned to TMR0
	    BSF		OPTION_REG,PS2	    ; 1
	    BSF		OPTION_REG,PS1	    ; 1, 1
	    BSF		OPTION_REG,PS0      ; PRESCALER 1:256
 
	    BANK0
	    MOVLW	H'00'
	    MOVWF	PORTB		    ; B'0000 0000', outputs
	    CLRF	TMR0		    ; start timer0 counting
	    CLRF	counter
	    CLRF	pointer
	    MOVLW	H'47'
	    MOVWF	lastIndex
; ------------ MAIN ROUTINE ---------------------------------------------------
LOOP
	    CALL	PATTERNS
	    CALL	TIMING
	    GOTO	LOOP
	    
; ------------ SUBROUTINES ------------------------------------------------------
TABLE
        ADDWF   PCL
pattern0
	RETLW   H'23'
	RETLW   H'3F'
	RETLW   H'47'
	RETLW   H'7F'
	RETLW   H'A2'
	RETLW   H'1F'
	RETLW   H'03'
	RETLW   H'67'
pattern1
	RETLW	H'FF'
	RETLW	H'7E'
	RETLW	H'BD'
	RETLW	H'DB'
	RETLW	H'E7'
	RETLW	H'DB'
	RETLW   H'BD'
	RETLW   H'07E'

pattern2
	RETLW H'FF'
	RETLW H'3C'
	RETLW H'18'
	RETLW H'24'
	RETLW H'42'
	RETLW H'81'
	RETLW H'C3'
	RETLW H'00'

pattern3
	RETLW H'01'
	RETLW H'02'
	RETLW H'04'
	RETLW H'08'
	RETLW H'10' 
	RETLW H'20'
	RETLW H'40'
	RETLW H'80'

pattern4
	RETLW H'FF'
	RETLW H'81'
	RETLW H'83'
	RETLW H'87'
	RETLW H'8F'
	RETLW H'9F'
	RETLW H'BF'
	RETLW H'FF'

pattern5
	RETLW H'7F'
	RETLW H'3F'
	RETLW H'1F'
	RETLW H'0F'
	RETLW H'07'
	RETLW H'03'
	RETLW H'01'
	RETLW H'FF'
;-------------------------------------------------------------------------------    
PATTERNS    
	MOVF    pointer, W	   ; copy 0 into W register
	CALL    TABLE		   ; call table with hex values
	MOVWF   PORTB	           ; send returned value to W into PORTB
	INCF    pointer, W	   ; increment pointer and save in W reg
	ANDLW   lastIndex	   ; AND value with 0000 0111 to reset pointer
	MOVWF   pointer		   ; copy result of ANDing in pointer register    
	RETURN     
;-------------------------------------------------------------------------------        
TIMING				    ; as timer0 counts till 255
	MOVLW	D'26'		    ; it will be multipled by 256
	MOVWF	AUX		    ; times 8 repetitions
				    ; that equals 522240 us
REPEAT	BCF	INTCON,T0IF	    ; which represents 522 ms
	CLRF	TMR0		    ; or 1448 ms if AUX = 16
	    
	BTFSS	INTCON,T0IF	    ; ROUTINE will be caught here
	GOTO	$ -1		    ; till timer0 overflows
	DECFSZ	AUX
	GOTO	REPEAT
	RETURN
; -----------------------------------------------------------------------------
	    END