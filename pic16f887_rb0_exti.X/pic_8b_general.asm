
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
 
 #define STANDBY PORTB,RB7
 #define ON_LED	 PORTB,RB6

 CBLOCK	    H'20'
    OLD_STATUS
    OLD_W
 ENDC
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************

; TODO INSERT ISR HERE
	ORG	H'0004'
        GOTO	RB0_ISR
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
	; TODO Step #5 - Insert Your Program Here
	    BANK1
	    MOVLW	H'3F'		    ; bit0 input for button
	    MOVWF	TRISB		    ; 7 outputs + 1 input
	    CLRF	INTCON
	    BCF	    	OPTION_REG,INTEDG   ; set edge to high-to-low mode
	    BCF		OPTION_REG,NOT_RBPU ; ENABLE internal pull-up
 
	    BANK0
	    MOVLW	H'00'
	    MOVWF	PORTB		    ; B'0000 0000', outputs
	    BSF		STANDBY		    ; init with standby led ON, bit7
	    BCF		ON_LED		    ; init with on state led OFF, bit6
	    BSF		INTCON,GIE	    ; ENABLE global interrupt
	    BSF		INTCON,INTE	    ; ENABLE RB0 external interrupt

; ------------ SUBROUTINE ------------------------------------------------------
	   SLEEP
	   GOTO $ -1			    ; SLEEP until an interrupt is detect
; -----------------------------------------------------------------------------
RB0_ISR

	   ; SAVE CONTEXT
	    MOVWF	    OLD_W	    ; save context in W register
	    SWAPF	    STATUS,W	    ; set STATUS to W
	    BANK0			    ; select bank 0 (default for reset)
	    MOVWF	    OLD_STATUS	    ; save STATUS
	    
; -----------------------------------------------------------------------------
	    COMF	 PORTB
	    BCF	         INTCON,INTF
; -----------------------------------------------------------------------------
	    ; RESTORE CONTEXT
	    SWAPF	    OLD_STATUS,W    ; saved status to W
	    MOVFW	    STATUS	    ; to STATUS register
	    SWAPF	    OLD_W,F	    ; swap File reg in itself
	    SWAPF	    OLD_W,W	    ; re-swap back to W
	

	    RETFIE
; -----------------------------------------------------------------------------
	    END