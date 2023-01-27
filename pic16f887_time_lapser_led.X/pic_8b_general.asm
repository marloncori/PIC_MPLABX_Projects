
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
 
;******************************************************************************
  cblock	H'20'	; REGISTRADORES DE USO GERAL, 'VARIAVEIS
			; INICIO DO REGISTRADOR
    COUNT_H		; high order byte
    COUNT_M		; medium order byte
    COUNT_L		; low order byte
  endc
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************

; TODO INSERT ISR HERE
	ORG	    H'0004'
        RETFIE
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
	CLRF	    TMR0
	CLRWDT
	
	BANK1
	MOVLW	    H'D0'	    ; B'1101 0000'
	MOVWF	    OPTION_REG	    
	; bit7 - rbpu (internal pull-ups), 0 enable, 1 disabled
	; bit6 - intedg, 0 falling edge, 1 raising edge
	; bit5 - tocs (tmr0 clock src), 0 - interal clock, 1 ra4/tockI bit src
	; bit4 - tose (tmr0 edge select), 0 inc low-to-high, 1 inc high-to-low
	; bit3 - psa (prescaler assing) 1 to WDT, 0 to timer0
	; bit2-0: value for timer0 prescaler --> 101 = 1:64, 111 = 1:256 (max)
	; *000 = 1:2, 010 = 1:8, 100 = 1:32, 110 = 1:128, 001 = 1:3, 011 = 1:16
	MOVLW	    H'00'           ; bit0 input for button
	MOVWF	    TRISB           ; 4 inputs + 4 outputs

	BANK0
	MOVLW	    H'00'	    ; set LEDs on line 0 and 1
	MOVWF	    PORTB

; ====================================
;  toggle all leds wired to portb
; ====================================
MAIN
	COMF 	    PORTB,RB0	    ; turn led on AND off
	CALL	    ONE_HALF_SEC    ; initiliaze counters and delay
	CALL	    TMR0_DELAY
	
	GOTO	    MAIN

; ------------ SUBROUTINE 1 -----------------------------------------------------
; variables count_l, count_m, count_h hold the low, middle and high-order
; bytes of the delay period in timer units. The prescaler is assigned to timer0
; and set up so that timer runs at 1:2 rate. This means that every time the
; counter reaches 128 (0x80) a total of 256 machine cycles have elapsed. The 
; value 0x80 is detected by testing bit 7 of the counter register.
; Note:
;  The timer0 register provides the low-order level of the count. since the counter
; counts up from zero, in order to ensure that the initial low-level delay count
; is correct, the value 128 - (xx/2) must be calculated where xx is the value in
; the original count_l register. First calculate xx/2 by bit shifting
TMR0_DELAY
	BCF	    STATUS,C	    ; clear Carry flag
	RRF	    COUNT_L,F	    ; divide by witha right shift
	MOVF	    COUNT_L,W	    ; now substract 128 - (xx/2)
	SUBLW	    D'128'
	MOVWF	    TMR0	    ; now store the adjusted value in tmr0

; this routine tests timer overflow by testing bit 7 of the tmr0 register
CYCLE
	BTFSS	    TMR0,7	    ; is bit 7 set?
	GOTO	    CYCLE
; at this point tmr0 bit 7 is set
	BCF	    TMR0,7	    ; all other bits are preserved
; subtract 256 from beat countre by decrementing the mid-order byte
	DECFSZ	    COUNT_M,F
	GOTO	    CYCLE
; at this point the mid-order byte has overflowed
; high-order byte must be decremented
	DECFSZ	    COUNT_H,F
	GOTO	    CYCLE
; at this point time cycle has elapsed
	RETURN
; =============================================================================
; Set register variables for a one-half second delay
; =============================================================================
; This was originally designed for a PIC16F84 at 4 MHz, it is older than PIC16F628
; Timer is set up for 500000 clock beats as follows: 
;      500,000 = 0x07      0xA1     0x20
;	         count_h  count_m   count_;
ONE_HALF_SEC
	
	    MOVLW	    H'07'
	    MOVWF	    COUNT_H
	    MOVLW	    H'01'
	    MOVWF	    COUNT_M
	    MOVLW	    H'20'
	    MOVWF	    COUNT_L
	    RETURN
; -----------------------------------------------------------------------------
	END