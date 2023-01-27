
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

;*******************************************************************************
 CBLOCK	    H'20'
    OLD_STATUS
    OLD_W
    TIME1
    TIME2   ; these registers are needed for the delay subroutine
    COUNT   ; this counter is needed to call the 500ms delay twice 
    COUNT2  ; this counter is needed to decrement TIME2 twice
    COUNT3  ; this counter is used in the ISR, for a 2 second delay
 ENDC
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
	    MOVLW	H'1F'		    ; bit7,6,5 AS OUTPUT
	    MOVWF	TRISB		    ; 7 outputs + 1 input
	    CLRF	INTCON
	    BCF	    	OPTION_REG,INTEDG   ; set edge to high-to-low mode
	    BCF		OPTION_REG,NOT_RBPU ; ENABLE internal pull-up
 
	    BANK0
	    MOVLW	H'00'
	    MOVWF	PORTB		    ; B'0000 0000', outputs
	    BSF		INTCON,GIE	    ; ENABLE global interrupt
	    BSF		INTCON,INTE	    ; ENABLE RB0 external interrupt

; ------------ MAIN ROUTINES ---------------------------------------------------
BLINK_LED1
	    BCF		PORTB,RB7
	    BCF		PORTB,RB6
	    BSF		PORTB,RB5
	    MOVLW	D'2'
	    MOVWF	COUNT
    LED1_FOR    CALL	DELAY_500ms
	        DECFSZ	COUNT
	        GOTO	LED1_FOR
	    GOTO	BLINK_LED2
	    
BLINK_LED2
	    BCF		PORTB,RB7
	    BCF		PORTB,RB5
	    BSF		PORTB,RB6
	    MOVLW	D'2'		    ; this routine is needed to 
	    MOVWF	COUNT		    ; call the delay twice
    LED2_FOR    CALL	DELAY_500ms	    ; in order to create a 1 sec. delay
	        DECFSZ	COUNT
	        GOTO	LED2_FOR
	    GOTO	BLINK_LED1
	    
; ------------ SUBROUTINES ------------------------------------------------------
DELAY_500ms
	    MOVLW	H'FA'		    ; D'250'
	    MOVWF	TIME1
	    MOVLW	H'FA'
D_LOOP
	    MOVLW	H'FA'
	    MOVWF   	TIME2	    
	    MOVLW	D'2'
	    MOVWF	COUNT2
FOR	    
	    DECFSZ	COUNT2
	    GOTO	FOR
	    
	    DECFSZ	TIME2
	    GOTO	$ -5
	    
	    DECFSZ	TIME1
	    GOTO	D_LOOP		   ; DELAY ends when TIME1 equals 0
	    RETURN
;--------------- RB0 INTERRUPT SERVICE ROUTINE --------------------------------- 
RB0_ISR
	    ; SAVE_CONTEXT  
	    MOVWF	    OLD_W	    ; save context in W register
	    SWAPF	    STATUS,W	    ; set STATUS to W
	    BANK0			    ; select bank 0 (default for reset)
	    MOVWF	    OLD_STATUS	    ; save STATUS
;-------------------------------------------------------------------------------
	    BCF		PORTB,RB6
	    BCF		PORTB,RB5
	    BSF		PORTB,RB7
	    MOVLW	D'4'
	    MOVWF	COUNT3
REPEAT	    
	    CALL	DELAY_500ms	    ; this loop is need to generate
	    DECFSZ	COUNT3		    ; a nearly 2 second delay
	    GOTO	REPEAT
	    BCF		INTCON,INTF
;-------------------------------------------------------------------------------	    
	    ; restore context
	    SWAPF	    OLD_STATUS,W    ; saved status to W
	    MOVFW	    STATUS	    ; to STATUS register
	    SWAPF	    OLD_W,F	    ; swap File reg in itself
	    SWAPF	    OLD_W,W	    ; re-swap back to W
	    
	    RETFIE
; -----------------------------------------------------------------------------
	    END