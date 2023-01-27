;*******************************************************************************
;                                                                              *
;    Filename:                                                                 *
;    Date:                                                                     *
;    File Version:                                                             *
;    Author:                                                                   *
;    Company:                                                                  *
;    Description:                                                              *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Notes: In the MPLAB X Help, refer to the MPASM Assembler documentation    *
;    for information on assembly instructions.                                 *
;                                                                              *
;*******************************************************************************

; TODO INSERT CONFIG HERE
#include "p16f876a.inc"

; CONFIG
; __config 0xFF3a
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

;*******************************************************************************

; TODO PLACE VARIABLE DEFINITIONS GO HERE
  #define BANK0    BCF STATUS,RP0      ; FORMA DE ACESSAR O BANK0 DE MEMORIA
  #define BANK1    BSF STATUS,RP0      ; FORMA DE ACESSAR O BANK1 DE MEMORIA
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT   CODE    H'0000'            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; TODO INSERT ISR HERE
       ORG          H'0004'
       RETFIE
     
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program
 
 CBLOCK  0x0c			    ; user registers
	 D1
	 D2
	 D3
	 COUNT
   endc

START:

	; TODO Step #5 - Insert Your Program Here
	BANK1
	MOVLW	    H'FF'        ; W = B'11111111'
	MOVWF	    TRISA        ; send the value stored in W to TRISA
	MOVLW	    H'7F'	 ; W = B'01111111'
	MOVWF	    TRISB	 ; send the value stored in W to TRISB
	
	BANK0
	MOVLW	    H'00'	 ; W = B'00000000'
	MOVWF	    PORTB	 ; send the value stored in W to PORTB
	; GOTO	    $                   ; loop forever

LOOP:
    
	MOVLW	    H'AA'	 ; W = B'01010101'
	MOVWF	    PORTB	 ; send the value stored in W to PORTB
	CALL        DELAY_5SEC
	
	MOVLW	    H'55'	 ; W = B'01010101'
	MOVWF	    PORTB	 ; send the value stored in W to PORTB
	CALL        DELAY_5SEC
	
	GOTO        LOOP
; ---------------------------------------------------------------------------	
; SUBROUTINE CALLED DELAY

	;4999993 cycles
DELAY_5SEC
	MOVLW	    H'2C'
	MOVWF	    D1
	MOVLW 	    H'E7'
	MOVWF	    D2
	MOVLW	    H'0B'
	MOVWF	    D3
	
DELAY_0
	DECFSZ	    D1,F
	GOTO	    $+2
	DECFSZ	    D2,F
	GOTO	     $+2
	DECFSZ	    D3,F
	GOTO	    DELAY_0
	
	;3 cycles
	GOTO $+1
	NOP
	
	;4 cycles (including call)
	return						;  SPECIFIES THE END OF A SUBROUTINE
;---------------------------------------------------------------------------------------------------

	END
;-------------------------------------------------------------------------------------