;---------------------------------------------------
; max counts = 65536
; OVTime = 0.00256
; prescaler = 8
; delay = 2.0
; internal oscillator = 4 MHz
;---------------------------------------------------
; control variable counter = 781
; value for TMR1 = 64256, 0xFB00
;  TMR1H = FB and TMR1L = 00
;----------------------------------------------------
;
;*******************************************************************************
#include "p16f627a.inc"

; CONFIG
; __config 0xFF18
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
;------------------------------------------------------------------------------ 
#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0

; TODO PLACE VARIABLE DEFINITIONS GO HERE
CBLOCK	    H'20'
    timer	    ; GPR1 used as delay counter
    point	    ; GPR2 used as table pointer
    
    COUNTER1
    
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
        GOTO	TMR1_ISR
;*******************************************************************************
; START OF PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
    BANK1
    movlw	H'00'
    movwf	TRISB	    	    ; configures rb7 and rb6 as output
    bsf		PIE1, TMR1IE	    ; enables timer 1 interruption
    
    BANK0
    clrf	PORTB	    	    ; initialize portb
       
    movlw	H'C0'		    ; send value b1100 0000 to INTCON
    movwf	INTCON		    ; set GIE and PEIE bits for global
    movlw	H'31'		    ; and peripheral interrupt, 00110001
    movwf	T1CON		    ; enable timer 1 at T1CON reg, psa 1:8
    
    movlw	H'FB'		    ; timer1 will be initilized with 64256
    movwf	TMR1H		    ; initialize MSB of timer1
    movlw	H'00'		    ; timer1 will be initilized with 64256
    movwf	TMR1L		    ; initialize LSB of timer1
    
    movlw	D'255'
    movwf	COUNTER1
;*******************************************************************************
; START OF PROGRAM
;*******************************************************************************    
LOOP    
    goto	LOOP		    ; all the logic can be found in the ISR
    
;*******************************************************************************
; INTERRUPT SERVICE ROUTINE
;*******************************************************************************    
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
	movlw	    H'FB'	    ; timer1 will be initilized with 15536
	movwf	    TMR1H	    ; initialize MSB of timer1
	movlw	    H'00'	    ; timer1 will be initilized with 15536
	movwf	    TMR1L	    ; initialize LSB of timer1
	
	decfsz	    COUNTER1
	goto	    EXIT_ISR
	
	movlw	    D'255'
	movwf	    COUNTER1	    ; count 256*3 to obtain 768
newbar				    ; which is value near 781
	clrf	    point	    ; Reset pointer to start of table
	movlw	    006		    ; Check if all outputs done yet
	subwf	    point,W	    ; (note: destination W)
	btfsc	    3,2		    ; and start a new bar
	goto	    newbar	    ; if true...
	movf	    point,W	    ; Set pointer to
	call	    table	    ; access table...
	movwf	    PORTB	    ; and output to LED
	incf	    point	    ; Point to next table value
	
	GOTO	    EXIT_ISR
;------------------------------------------------------------------------------
; Defined table of Output Codes ..............................................
;------------------------------------------------------------------------------	
table	
	ADDWF	PCL	    ; Add pointer to PCL
	RETLW	0x00	    ; 0 LEDS on
	RETLW	0x01	    ; 1 LEDS on
	RETLW	0x03	    ; 2 LEDS on
	RETLW	0x07	    ; 3 LEDS on
	RETLW   0x0F	    ; 4 LEDS on
	RETLW	0x1F	    ; 5 LEDS on
	RETLW	0x3F	    ; 6 LEDS on
	RETLW	0x7F	    ; 7 LEDS on
	RETLW	0xFF	    ; 8 LEDS on	
;------------------------------------------------------------------------------	
EXIT_ISR		
	; Restore context
	swapf	    OLD_STATUS,W    ; saved status to W
	movfw	    STATUS	    ; to STATUS register
	swapf	    OLD_W,F	    ; swap File reg in itself
	swapf	    OLD_W,W	    ; re-swap back to W
	
	retfie
;*******************************************************************************
;  end of application
;*******************************************************************************    
	END
;-------------------------------------------------------------------------------	