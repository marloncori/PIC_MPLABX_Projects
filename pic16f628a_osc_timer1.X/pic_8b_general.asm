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
;
;  FREQUENCY
;
;   for example, 1 KHz -> 1/1000 = 1e-3 s period
;        timer1 overflow -> 1 ms / 2 = 500e-6 s (500 us or 0.5 ms)
;    
;   for 50 Hz ->  1/50 -> 20e-3 s period
;       output inversion -> 20e-3 / 2 = 10e-3
;    
;   for 125 Hz -> 1/125 = 8e-3 s period
;        output inversion -> 8e-3 / 2 = 4e-3
;	    auxiliary counter - 4e-3 / 0.5e-3 (0.5 ms) -> 8
;
;  Calculation to find out TMR1 initial value:
;                                tmr1OVF
;  TMR1 = max_count - (   -------------------------- )
;                         prescaler * machine cycle
;
;  for an oscillator of 1 Khz --> 500e-6 s (500 us or 0.5e-3 ms)    
;    
;    
;  TMR1 = 65536 - (500e-6 / ( 1 * 1e-6) --> = 65036 -> 0xFE0C
;
;  It is needed to load TRM1H and TRM1L
;  TMR1H = 0xFE, TMR1L = 0x0C
;    
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
    movlw	H'00'
    movwf	TRISB	    	    ; configures rb7 and rb6 as output
    bsf		PIE1, TMR1IE	    ; enables timer 1 interruption
    
    BANK0
    bcf		PORTB, RB6	    ; initialize rb6 as low
    bsf		PORTB, RB7	    ; initialize rb7 as high
       
    movlw	H'C0'		    ; send value b1100 0000 to INTCON
    movwf	INTCON		    ; set GIE and PEIE bits for global
    movlw	H'01'		    ; and peripheral interrupt enabling
    movwf	T1CON		    ; enable timer 1 at T1CON reg, psa 1:1
    
    movlw	H'FE'		    ; timer1 will be initilized with 15536
    movwf	TMR1H		    ; initialize MSB of timer1
    movlw	H'0C'		    ; timer1 will be initilized with 15536
    movwf	TMR1L		    ; initialize LSB of timer1
    
    movlw	H'08'
    movwf	COUNTER
    
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
	movlw	    H'FE'	    ; timer1 will be initilized with 15536
	movwf	    TMR1H	    ; initialize MSB of timer1
	movlw	    H'0C'	    ; timer1 will be initilized with 15536
	movwf	    TMR1L	    ; initialize LSB of timer1
	
	; ---- 500 us --
	movlw	    H'40'	    ; portb RB6 will be set
	xorwf	    PORTB
	decfsz	    COUNTER
	goto	    EXIT_ISR	    ; No, so leave ISR
	; --- 1000 s -------
	; timing counting: 0.000001 sec * 65536 * 1 = 0.065536 s
	;                (machine cycle * max_count * psa) = 65.535 ms
	; but now prescaler is 4, not 1, and I want a 200 ms overflow time.
;------- 4 ms ------------------------------------------------------------------
	movlw	    H'80'	    ; create mask for bitwise operation
	xorwf	    PORTB	    ; change state of only RB6
	movlw	    H'08'
	movwf	    COUNTER
	
EXIT_ISR		
	; Restore context
	swapf	    OLD_STATUS,W    ; saved status to W
	movfw	    STATUS	    ; to STATUS register
	swapf	    OLD_W,F	    ; swap File reg in itself
	swapf	    OLD_W,W	    ; re-swap back to W
	
	retfie
;------------------------------------------------------------------------------
	END