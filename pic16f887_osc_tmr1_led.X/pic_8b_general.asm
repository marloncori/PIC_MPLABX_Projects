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
;-----------------------------------------------------------------------------
;  desired overflow time: 1 second, xt_freq = 16 MHz (real Fosc: 4 MHz) (4 us)
;						machine cycle 0.0000004 s
;  ** built-in watch crystal: 32768 KHz **
;  ** between pins RC0 and RC1 **
;    
;  Calculation to find out TMR1 initial value:
;                                tmr1OVF
;  TMR1 = max_count - (   -------------------------- )
;                         prescaler_t1 * 1/xt_freq
;
;  For a 16 MHz crystal and 0.002 s overflow time, prescaler 1:2:
;    TMR1 = 65536 - ((0.002 / (2 * 1/16000000)) -> 49536 (0xC180)
;
;  For a 16 MHz crystal and 0.004 s overflow time, prescaler 1:1:
;    TMR1 = 65536 - ((0.004 / (1 * 1/16000000)) -> 1536 (0x0600)
; ------------------------------------------------------------------------------
; ** For a 32768 KHz crystal and 1.0 s overflow time, prescaler 1:1 **
;  **  TMR1 = 65536 - ((1.0 / (1 * 1/32768)) -> 32768 (0x8000) **
;  for a 2 sec overflow time TMR1 = 0
;*******************************************************************************
 #include "p16f887.inc"

; CONFIG1
; __config 0xE0D2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
 
#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0

; TODO PLACE VARIABLE DEFINITIONS GO HERE
CBLOCK	    H'20'
    OLD_STATUS
    OLD_W
    counter
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
    BANK0
    bcf	        PIR1, TMR1IF	    ; clear flag if it equals 1, it skips next line
    clrf	TMR1H		    ; high initialize MSB of timer1
    clrf	TMR1L		    ; and low tmr1 accoring to datasheet
    
    BANK1
    bcf		TRISB, RB3    	    ; configures rb3 as output
    movlw	H'03'
    movwf	TRISC		    ; portc high according to datasheet
    bsf		PIE1, TMR1IE	    ; enables timer 1 interruption
    
    BANK0
    bsf		PORTB, RB3	    ; RB3 led high
    movlw	H'FC'
    movwf	PORTC		    ; RC0 and RC1 low according to datasheet
    movlw	H'C0'		    ; send value b1100 0000 to INTCON
    movwf	INTCON		    ; set GIE and PEIE bits for global
    movlw	H'09'		    ; and peripheral interrupt enabling
				    ; unimpl.: 00, PSA: 00, T1OSCEN: 1 (rc0 and rc1)
				    ; NOT_T1SYNC: 0 (async), TMR1CS: 1 (ext.clk)
				    ; TMR1ON is enabled, 1, 0b00001001
    movwf	T1CON		    ; enable timer 1 at T1CON reg, psa 1:1
   ; VALUES FOR a 32168 KHz crystal and a one second overflow time
    movlw	H'C0'		    ; timer1 will be initilized with 49152 for 0.5
    movwf	TMR1H		    ; initialize MSB of timer1
    movlw	H'00'		    ; for a 0.002 sec overflow of timer1
    movwf	TMR1L		    ; initialize LSB of timer1
    movlw	D'1000'
    movwf	counter
DELAY
    decfsz	counter,F
    goto	DELAY
    
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
	movlw	    H'C0'	    ; 
	movwf	    TMR1H	    ; reload MSB of timer1
	
	movlw	    H'00'	    ; 
	movwf	    TMR1L	    ; reload MSB of timer1
	; ---- 1 s -----------------
	; portb RB3 will be reset
	comf	    PORTB
;--------------------------------------------------------------------------------	
EXIT_ISR		
	; Restore context
	swapf	    OLD_STATUS,W    ; saved status to W
	movfw	    STATUS	    ; to STATUS register
	swapf	    OLD_W,F	    ; swap File reg in itself
	swapf	    OLD_W,W	    ; re-swap back to W
	
	retfie
;------------------------------------------------------------------------------
	END