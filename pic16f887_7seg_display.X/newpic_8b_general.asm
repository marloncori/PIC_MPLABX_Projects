;*******************************************************************************
;
; 7 segment display - common cathode ( - ), they're turned on by a HIGH signal.
;    
; wiring: a -> rb8, b -> rb9, c -> rb11, d -> rb12 
;          e -> rb13, f -> rb7, g -> rb6
;
; pic with a 16 MHz crystal
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
    timer
ENDC
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    goto    START                   ; go to beginning of program

;*******************************************************************************

;*******************************************************************************

; TODO INSERT ISR HERE
	org	    H'0004'
        retfie
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
    BANK0
    bcf	        PIR1,TMR1IF	    ; clear flag if it equals 1, it skips next line
    clrf	TMR1H		    ; high initialize MSB of timer1
    clrf	TMR1L		    ; and low tmr1 accoring to datasheet
    
    BANK1
    movlw	H'10'
    movwf	TRISB    	    ; configures rb as output, except for
    bsf		PIE1,TMR1IE	    ; enables timer 1 interruption
    
    BANK0
    bcf		PORTB,RB3	    ; RB3 led high
    movlw	H'C0'		    ; send value b1100 0000 to INTCON
    movwf	INTCON		    ; set GIE and PEIE bits for global
    movlw	H'01'		    ; and peripheral interrupt enabling
				    ; unimpl.: 00, PSA: 00, T1OSCEN: 1 (rc0 and rc1)
				    ; NOT_T1SYNC: 0 (async), TMR1CS: 1 (ext.clk)
				    ; TMR1ON is enabled, 1, 0b00001001
    movwf	T1CON		    ; enable timer 1 at T1CON reg, psa 1:1
   ; VALUES FOR a 32168 KHz crystal and a one second overflow time
    movlw	H'3C'		    ; timer1 will be initilized with 49152 for 0.5
    movwf	TMR1H		    ; initialize MSB of timer1
    movlw	H'B0'		    ; for a 0.002 sec overflow of timer1
    movwf	TMR1L		    ; initialize LSB of timer1
    clrf	counter
    clrf	timer		    ; prepare both variable for later use 

LOOP
    call	UPDATE_DISP	    ; subroutine will be called every 1 sec
    goto	LOOP
    
;------------------------------------------------------------------------------
; subroutine meant to update number showed on display
;------------------------------------------------------------------------------
CONVERT
    movf	timer,W		    ; copy timer contents to Work register
    andlw	H'0F'		    ; mask for counter value
    addwf	PCL,F		    ; PCL = PCL + W
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
    retlw	B'11000110'	    ; returns 'A'
    retlw	B'11101001'	    ; returns 'B'
    retlw	B'11000110'	    ; returns 'C'
    retlw	B'11101001'	    ; returns 'D'
    retlw	B'11000111'	    ; returns 'E'
    retlw	B'10000111'	    ; returns 'F'

    ; seven segment number right position: EDC.BAFG (for a common cathode one)
UPDATE_DISP
    call	CONVERT		    ; get a binary sequence for character
    movwf	PORTB		    ; send returned value to portb
    return
; -----------------------------------------------------------------------------
	END