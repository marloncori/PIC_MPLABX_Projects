
;*******************************************************************************
#include "p16f627a.inc"

; CONFIG
; __config 0xFF19
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

 ;*******************************************************************************

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 #define BANK0	BCF STATUS,RP0
 #define BANK1	BSF STATUS,RP0

 CBLOCK      H'20'
     MLREG
 ENDC
;******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT   CODE    0x0000            ; processor reset vector
           GOTO    START                   ; go to beginning of program

;*******************************************************************************
; TODO Step #4 - Interrupt Service Routines
;
; There are a few different ways to structure interrupt routines in the 8
; bit device families.  On PIC18's the high priority and low priority
; interrupts are located at 0x0008 and 0x0018, respectively.  On PIC16's and
; lower the interrupt is at 0x0004.  Between device families there is subtle
; variation in the both the hardware supporting the ISR (for restoring
; interrupt context) as well as the software used to restore the context
; (without corrupting the STATUS bits).
;
; General formats are shown below in relocatible format.
;
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
	MOVLW	    H'00'           ; your instructions
	MOVWF	    TRISB           ; output

	BANK0
	MOVLW	    H'0F'
	MOVWF	    PORTB	    ; b'00001010
	CLRF	    MLREG
	
LOOP
	MOVLW	    D'10'
	MOVWF	    MLREG

FOR	
	COMF	    PORTB,F	    ; not operation to invert state
	CALL	    DELAY_500ms
	DECFSZ	    MLREG,F
	GOTO	    FOR
	GOTO	    LOOP
	
; ------------ SUBROUTINE -----------------------------------------------------
DELAY_500ms
	
	MOVLW	    D'200'
	MOVWF	    H'20'	; endereco de onde se comeca a guardar variaveis
	
AUX1
	MOVLW	    D'250'
	MOVWF	    H'21'	; NEXT ADDRESS, see datasheet page 18
	
AUX2
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	
	DECFSZ	    H'20'
	GOTO	    AUX2
	
	DECFSZ	    H'21'
	GOTO	    AUX1
	
	RETURN
; -----------------------------------------------------------------------------
	END