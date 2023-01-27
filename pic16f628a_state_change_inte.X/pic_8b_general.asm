;*******************************************************************************
;   In the case of an external interrupt, I have to set a falling or rising
;   edge for interruption triggering sensitivity (high to low, or low to high)
;
;   In the case of a state change triggered interruption, any state change
;   in any detection is detected and triggers off the interrupt service routine
;
;   Only INTCON has to be set for this kind of interrupt, BIT 7 and BIT 3 (RBIE)
;*******************************************************************************
    
#include "p16f628a.inc"
    
; __config 0xFF19
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0
 
; TODO PLACE VARIABLE DEFINITIONS GO HERE
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

;*******************************************************************************

; TODO INSERT ISR HERE
	ORG	    H'0004'
        GOTO	  SCH_ISR
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START

    ; TODO Step #5 - Insert Your Program Here
    BANK1
    MOVLW	H'FD'		     ;
    MOVWF	TRISB                ; RB1 AS output, other pins - input
    BSF	    	OPTION_REG, NOT_RBPU ; bit7 is set, enable pull-up resistors
    
    BANK0
    MOVLW	H'88'		     ; load Work register with hexa value
    MOVWF	INTCON		     ; enable global and RB interrupts
    BCF		PORTB, RB1	     ; RB1 AS ZERO

LOOP
    
    BSF		PORTB, RB1
    GOTO	LOOP
; -----------------------------------------------------------------------------
SCH_ISR
	; SAVE CONTEXT
	MOVWF	    OLD_W	    ; save context in W register
	SWAPF	    STATUS,W	    ; set STATUS to W
	BANK0			    ; select bank 0 (default for reset)
	MOVWF	    OLD_STATUS	    ; save STATUS

;------------------------------------------------------------------------------
	BTFSS	    INTCON, RBIF    ; Has any interruption happened?
	GOTO	    EXIT_ISR	    ; NO, jump to ISR end
	BCF	    INTCON, RBIF    ; Yes, clear flag by software
	COMF	    PORTB	    ; invert portb state
;------------------------------------------------------------------------------
EXIT_ISR		
	; Restore context
	SWAPF	    OLD_STATUS,W    ; saved status to W
	MOVFW	    STATUS	    ; to STATUS register
	SWAPF	    OLD_W,F	    ; swap File reg in itself
	SWAPF	    OLD_W,W	    ; re-swap back to W
	
	RETFIE
;------------------------------------------------------------------------------
    END