;*******************************************************************************
;   Once I  have understood how timer0 works, it is easier to grasp the
;   timer1. To calculate its overflow time, use the following formula:
;
;   It is a 16 bit counter (two 8 bit registers work together, 
;	T1CONL and T1CONH). It counts up to 0-65535.
;	
; T1CON reg bit5-4 prescale value:  11 = 1:8
;				    10 = 1:4
;				    01 = 1:2
;				    00 = 1:1
; bit3 T1OSCEN	1: oscillator enable, 0: oscillator shut off
; bit2 NOT_T1SYNC   1 = do not synchronize external clock input
;		    0 =  do synchronize texternal clock input
; bit1 TMR1CS - timer2 clock source select bit
;	    1: external clock from pin rb6/T1OSO/T1CKi/PGC on rising edge
;	    0: internal clock (Fosc / 4)
; bit0 TMR1ON
;	    1: enable timer1, 0: stop timer1
;						current setting: 0000 0001
;
; ----------------------------------------------------------------------------
;  Calculation to find out TMR1 initial value:
;                                tmr1OVF
;  TMR1 = max_count - (   -------------------------- )
;                         prescaler * machine cycle
;
;  TMR1 = 65536 - (200e-3 / ( 4 * 1e-6) --> 65536 - 5000 = 15536 -> 0x3CB0
;  It is needed to load T1CONH and T1CONL                             H  L
;  TMR1H = 0x3C, TMR1L = 0xB0
;
;*******************************************************************************
#include "p16f628a.inc"
    
; __config 0xFF19
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
 
#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0

#define BTN1	PORTB,RB0
#define BTN2	PORTB,RB1
 
; TODO PLACE VARIABLE DEFINITIONS GO HERE
CBLOCK	    H'20'
    OLD_STATUS
    OLD_W
    COUNTER
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
        GOTO	TMR1_ISR
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
    BANK1
    bcf		TRISB, RB7	    ; configures rb7 as output
    bsf		PIE1, TMR1IE	    ; enables timer 1 interruption
    
    BANK0
    bsf		PORTB, RB7	    ; initialize rb7 as low
    movlw	H'C0'		    ; send value b1100 0000 to INTCON
    movwf	INTCON		    ; set GIE and PEIE bits for global
    movlw	H'21'		    ; and peripheral interrupt enabling
    movwf	T1CON		    ; enable timer 1 at T1CON reg, psa 1:4
    movlw	H'3C'		    ; timer1 will be initilized with 15536
    movwf	TMR1H		    ; initialize MSB of timer1
    movlw	H'B0'		    ; timer1 will be initilized with 15536
    movwf	TMR1L		    ; initialize LSB of timer1
    clrf	COUNTER		    ; init counter for a 1000 ms delay
    
    goto	$
; -----------------------------------------------------------------------------
TMR1_ISR
	; SAVE CONTEXT
	movwf	    OLD_W	    ; save context in W register
	swapf	    STATUS,W	    ; set STATUS to W
	BANK0			    ; select bank 0 (default for reset)
	movwf	    OLD_STATUS	    ; save STATUS
;------------------------------------------------------------------------------
	; check the timer 1 flag at PIR1 register
	btfss	    PIR1, TMR1IF    ; if it equals 1, it skips next line
	goto	    EXIT_ISR	    ; leave ISR since no overflow has happened
	bcf	    PIR1, TMR1IF    ; clears interrupt flag and
	movlw	    H'3C'	    ; timer1 will be initilized with 15536
	movwf	    TMR1H	    ; initialize MSB of timer1
	movlw	    H'B0'	    ; timer1 will be initilized with 15536
	movwf	    TMR1L	    ; initialize LSB of timer1
	
	; ---- 200 ms --
	incf	    COUNTER, F	    ; increment counter by 1
	movlw	    H'05'	    ;       5 xor 5
	xorwf	    COUNTER, W	    ; counter xor b0000 0101 = 0?
	btfss	    STATUS, Z	    ; is the result equal to zero?
	goto	    EXIT_ISR	    ; No, so leave ISR
	clrf	    COUNTER	    ; Yes, reload counter and toggle led
	; --- 1000 s -------
	; timing counting: 0.000001 sec * 65536 * 1 = 0.065536 s
	;                (machine cycle * max_count * psa) = 65.535 ms
	; but now prescaler is 4, not 1, and I want a 200 ms overflow time.
;------------------------------------------------------------------------------
	movlw	    H'80'	    ; create mask for bitwise operation
	xorwf	    PORTB	    ; change state of only RB7
EXIT_ISR		
	; Restore context
	swapf	    OLD_STATUS,W    ; saved status to W
	movfw	    STATUS	    ; to STATUS register
	swapf	    OLD_W,F	    ; swap File reg in itself
	swapf	    OLD_W,W	    ; re-swap back to W
	
	retfie
;------------------------------------------------------------------------------
	END