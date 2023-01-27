;*******************************************************************************
; TWO multiplexed
; 7 segment displays - common cathode ( - ), they're turned on by a HIGH signal.
;    
; wiring: a -> rb1, b -> rb2, c -> rb3, d -> rb4 
;          e -> rb5, f -> rb6, g -> rb7
;    
;	    btn2 -> ra5
;	    btn1 -> rb0  bc547(1) -> RA1, bc547(2) ->RA0 
;    
; pic with an internal 16 MHz crystal
;
;*******************************************************************************
    
#include "p16f628a.inc"

; CONFIG
; __config 0xFF19
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF


#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0

#define LED1	PORTA,RA3
#define BTN1	PORTB,RB0

#define LED2	PORTA,RA2
#define BTN2	PORTA,RA5

#define	digit1	PORTA,RA1	    ; MSB, transistor bc547
#define digit2  PORTA,RA0	    ; LSB, transistor bc547

; TODO PLACE VARIABLE DEFINITIONS GO HERE
CBLOCK	    H'20'
    OLD_STATUS
    OLD_W
    
    dez
    uni
    
    flags
    
    btn1_bounceA
    btn1_bounceB
    btn2_bounceA
    btn2_bounceB
ENDC
    
#define btn1_flag   flags,0	    ; btn1 state flag
#define	btn2_flag   flags,1	    ; btn2 state flag
    
; --- contants --- 
;  BOUNCE_BTN1A	    equ	    D'255'
;  BOUNCE_BTN1B	    equ	    D'8'
;  
;  BOUNCE_BTN2A	    equ	    D'255'
;  BOUNCE_BTN2B	    equ	    D'8'	
;    
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    goto    START                   ; go to beginning of program

;*******************************************************************************

;*******************************************************************************

; TODO INSERT ISR HERE
	org	    H'0004'
        goto	    TMR0_ISR
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
    
    BANK1
    movlw	H'F0'
    movwf	TRISA		    ; RA3, RA2, RA1, RA0 as outputs
    movlw	H'01'
    movwf	TRISB    	    ; configures rb as output, except for
    movlw	H'53'
    movwf	OPTION_REG	    ; enable pull up, icrement tmr0 every machine cycle
    
    BANK0
    movlw	H'07'		    ; send value b1100 0000 to INTCON
    movwf	CMCON		    ; turn off comparators
    movlw	H'A0'		    ; enable tmr0 interruption
    movwf	INTCON		    ; enable also GIE
    clrf	flags
    movlw	H'FF'
    movwf	btn1_bounceA
    movlw	H'08'
    movwf	btn1_bounceB
    clrf	dez		    ; prepare both variable for later use 
    clrf	uni

LOOP
    call	BTN1_PRESS
    call	BTN2_PRESS
    goto	LOOP

;------------------------------------------------------------------------------
; subroutine meant to update number showed on display
;------------------------------------------------------------------------------
BTN1_PRESS
    btfss	btn1_flag	    ; has flag been set?
    goto	CHECK_BTN1	    ; No, so jump to this label
    btfss	BTN1		    ; Yes, has btn been released?
    return			    ; No, so return
    bcf		btn1_flag	    ; Yes, set the state flag
;------------------------------------------------------------------------------    
CHECK_BTN1
    btfsc	BTN1		    ; has btn been pressed?
    goto	DEBOUNCE1	    ; No, jump to label
    decfsz	btn1_bounceA,F	    ; Yes, decrement variable, and is it zero?
    return			    ; No, so return
    movlw	H'FF'		    ; Yes, so copy this value to the W reg
    movwf	btn1_bounceA	    ; and reload the variable
    decfsz	btn1_bounceB,F	    ; decrement second variable
    return
    movlw	H'08'
    movwf	btn1_bounceB	    ; reload auxiliary register B
    bsf		btn1_flag	    ; set button state flag
    decf	uni,F
    movlw	H'0A'
    xorwf	uni,W
    btfss	STATUS,Z
    return
    clrf	uni
    incf	dez, F
    movlw	H'0A'
    xorwf	dez,W
    btfss	STATUS,Z
    return
    clrf	dez
    return
;------------------------------------------------------------------------------        
DEBOUNCE1   
    movlw	H'FF'
    movwf	btn1_bounceA
    movlw	H'08'
    movwf	btn1_bounceB
    return
;------------------------------------------------------------------------------    
    
BTN2_PRESS    
    btfss	btn2_flag	    ; has flag been set?
    goto	CHECK_BTN2	    ; No, so jump to this label
    btfss	BTN2		    ; Yes, has btn been released?
    return			    ; No, so return
    bcf		btn2_flag	    ; Yes, set the state flag
;-------------------------------------------------------------------------------
CHECK_BTN2
    btfsc	BTN2		    ; has btn been pressed?
    goto	DEBOUNCE2	    ; No, jump to label
    decfsz	btn2_bounceA,F	    ; Yes, decrement variable, and is it zero?
    return			    ; No, so return
    movlw	H'FF'		    ; Yes, so copy this value to the W reg
    movwf	btn2_bounceA	    ; and reload the variable
    decfsz	btn2_bounceB,F	    ; decrement second variable
    return
    movlw	H'08'
    movwf	btn2_bounceB	    ; reload auxiliary register B
    bsf		btn2_flag	    ; set button state flag
    decf	uni,F
    movlw	H'FF'
    xorwf	uni,W
    btfss	STATUS,Z
    return
    movlw	H'09'
    movwf	uni
    decf	dez,F
    movlw	H'FF'
    xorwf	dez,W
    btfss	STATUS,Z
    return
    movlw	H'09'
    movwf	dez
    return
    
;----------------------------------------------
 DEBOUNCE2   
    movlw	H'FF'
    movwf	btn2_bounceA
    movlw	H'08'
    movwf	btn2_bounceB
    return
;------------------------------------------------------------------------------    
DISPLAY
    addwf	PCL,F		    ; PCL = PCL + W
		;  gfedcba
    retlw	B'11101110'	    ; returns '0'
    retlw	B'00101000'	    ; returns '1'
    retlw	B'11001101'	    ; returns '2'
    retlw	B'01101101'	    ; returns '3'
    retlw	B'00101011'	    ; returns '4'
    retlw	B'01100111'	    ; returns '4'
    retlw	B'11100111'	    ; returns '5'
    retlw	B'00101100'	    ; returns '6'
    retlw	B'11101111'	    ; returns '7'
    retlw	B'10101111'	    ; returns '8'
    retlw	B'11100011'	    ; returns '9'
    
; -----------------------------------------------------------------------------    
TMR0_ISR
    ; save context because of ISR latency --------------------------
    movwf	OLD_W
    swapf	STATUS,W
    bank0
    movwf	OLD_STATUS
    ; --------------------------------------------------------------
    
    btfss	INTCON, T0IF	    ; has a timer 1 overflow happened?
    goto	exit_ISR	    ; if not, just leave ISR
    bcf		INTCON, T0IF	    ; clear interrupt flag
    btfss	digit1
    goto	DIGIT2_OFF
    bcf		digit1
    clrf	PORTB
    bsf		digit2
    goto	COPY_UNIT
    
DIGIT2_OFF
    bcf		digit2
    clrf	PORTB
    bsf		digit1
    movf	dez,W
    call	DISPLAY
    movwf	PORTB
    goto	exit_ISR
    
COPY_UNIT
    movf	uni,W
    call	DISPLAY
    movwf	PORTB

; -------- recover saved context and exit --------------------
exit_ISR
    swapf	OLD_STATUS, W
    movwf	STATUS
    swapf	OLD_W, F
    swapf	OLD_W, W
    
    retfie   
;------------------------------------------------------------------------------
    END 