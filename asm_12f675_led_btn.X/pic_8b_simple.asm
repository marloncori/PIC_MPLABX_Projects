
;=================================================================
; Description
;       Program to blink pic12f675 as a test
;       PORTB. TMR0 is used to generata 1.5 sec delay
;=================================================================
#include "p12f675.inc"

; __config 0xF1B5
 __CONFIG _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _BOREN_OFF & _CP_OFF & _CPD_OFF

;=================================================================
; MACROS
;============================================================
; Macros to select the register banks
Bank0	MACRO		    ; Select RAM bank 0
	BCF	STATUS,RP0
	ENDM
;----------------------------------------------
Bank1	MACRO		    ; Select RAM bank 1
	BSF	STATUS,RP0
	ENDM
	
;===============================================================================
; variables in PIC RAM
;===============================================================================
; Local variables
CBLOCK		 H'20'   ; Start of block
    COUNT
    COUNT2
    COUNT3
    OLD_W
    OLD_STATUS
ENDC
;===============================================================================
RES_VECT  CODE    H'0000'            ; processor reset vector
    GOTO    START                   ; go to beginning of program
;===============================================================================
; add interrupts here if used
    ORG	    H'0004'
    GOTO    BTN_ISR
;===============================================================================    
; PROGRAM
;===============================================================================
MAIN_PROG CODE                      ; let linker place main program

START
    Bank0	    
    CLRF    GPIO		    ; clear gpio
    MOVLW   H'07'		    ; copy value to W reg
    MOVWF   CMCON		    ; turn off comparators
    ;---------------------------------------------------------------------------
    Bank1			    ; select bank 1  
    CLRF    ANSEL		    ; gpio as digital
    MOVLW   H'00'                   ; copy value to W reg 
    MOVWF   TRISIO		    ; to set up GPIO as output
    CALL    3FFh		    ; get CALL value to callibrate
    MOVWF   OSCCAL		    ; the 4 MHz internal oscillator
    MOVLW   H'D7'		    ; B'11010111'
    MOVWF   OPTION_REG	    
	; bit7 - rbpu (internal pull-ups), 0 enable, 1 disabled
	; bit6 - intedg, 0 falling edge, 1 raising edge
	; bit5 - tocs (tmr0 clock src), 0 - interal clock, 1 ra4/tockI bit src
	; bit4 - tose (tmr0 edge select), 0 inc low-to-high, 1 inc high-to-low
	; bit3 - psa (prescaler assing) 1 to WDT, 0 to timer0
	; bit2-0: value for timer0 prescaler --> 101 = 1:64, 111 = 1:256 (max)
	; 000 = 1:2, 010 = 1:8, 100 = 1:32, 110 = 1:128, 001 = 1:3, 011 = 1:16
	
;-------------------------------------------------------------------------------    
    Bank0			    ; go back bank 0
    MOVLW   (1<<GP0)	    
    IORWF   GPIO		    ; set gp0
    MOVLW   ~(1<<GP1) | ~(1<<GP4)
    ANDWF   GPIO		    ; clear gp1
    CLRWDT			    ; clear watchdog timer
    CLRF    TMR0
    MOVLW   (1<<GIE) | (1<<PEIE) | (1<<GPIE)    
				    ; enable global, peripheral and
    IORWF   INTCON		    ; gpio interrupts
    MOVLW   (1<<IOC5)		    ; enable gpio5 interrupt
    IORWF   IOC
				    
;*******************************************************************************
;   Main routine
;*******************************************************************************
MAIN
    MOVLW   H'03'		    ; load W with 0011 0111
    XORWF   GPIO		    ; to invert led states
    MOVLW   D'10'
    MOVWF   COUNT		    ; wait some time...
FOR
    CALL    TMR0_DELAY
    DECFSZ  COUNT,F
    GOTO    FOR
    GOTO    MAIN		    ; and then repeat it
;*******************************************************************************
;   Program subroutines 
;*******************************************************************************    
; procedure meant to delay 50 machine cycles
DELAY
    MOVLW      D'80'	    ; repeat 22 machine cycles
    MOVWF      COUNT2
REPEAT
    DECFSZ     COUNT2,F	    ; decrement counter
    GOTO       REPEAT	    ; continue if not 0
    RETURN

; ------------ SUBROUTINE -----------------------------------------------------
; THIS IS USED TO SLOW DOWN LED BLINKING
TMR0_DELAY
    CLRF       TMR0	    ; clear SFR for timer0
; routine tests the value in the TMR0 by subtracting 0xff from
; the value in TMR0. The zero flag is set if TMR = 0xff
; substraction is done for TMR0 overflow to be detect, since GOTO
; take two machine cycles, a detection would occur otherwise.
CYCLE
    MOVF       TMR0,W	    ; read timer0 value, store it in W
    SUBLW      H'FF'	    ; subtract max value
	
; now zero flag is set if value in tmr0 = 0xFF
    CALL       DELAY
    BTFSS      STATUS,Z	    ; test for zero value
    GOTO       CYCLE
    RETURN

;*******************************************************************************
;   Interrupt service routine
;*******************************************************************************    
BTN_ISR
    ; first, test if source is an RB0 interrupt
    BTFSS   INTCON, GPIF
    GOTO    notGP2
    
    ; save context due to interrupt latency------------------------- 
    MOVWF   OLD_W		    ; save W register
    SWAPF   STATUS, W
    MOVWF   OLD_STATUS		    ; save status
    ;--------------------------------------------------------------
    
    ; make sure interrupt occured on the rising edge of the signal
    BTFSS   GPIO, GP2		   ; is bit set? 
    GOTO    exitISR		   ; leave ISR if not set
    
    ; interrupt action -> debounce switch. 
    ; Logic: debounce algorithm consists in waiting until the
    ; same level is repeated on a number of samplings of the 
    ; button. At this point RB0 line is clear since the interrupt
    ; takes place on the falling edge. An initial short delay 
    ; makes sure that spikes for mechanical accomodation are ignored
    MOVLW   D'10'		   ; number of repetitions
    MOVWF   COUNT3		   ; stored in counter
WAIT:
    ; check to see that portB bit 0 is still low, if not
    ; wait until its state chagnes
    BTFSS   GPIO, GP2
    GOTO    exitISR
    ; at this pint rb0 bit is clear, so
    DECFSZ  COUNT3, F		  ; count this iteration
    GOTO    WAIT		  ; go there if bit not 0
    
    ; toggle bit 2 of PORTB to turn LED on and off
    MOVLW   (1<<GP4)		  ; Xoring with a 1-bit produces
    XORWF   GPIO, F		  ; complement bit 4 of gpio
    
exitISR:
    ; restore saved context ---------------------------------------
    SWAPF   OLD_STATUS, W	  ; save STATUS to W
    MOVFW   STATUS		  ; store in current STATUS regiser
    SWAPF   OLD_W, F		  ; swap file register in itself
    SWAPF   OLD_W, W		  ; reswap back to W
    ;--------------------------------------------------------------
notGP2:
    BCF	    INTCON, GPIF         ; interrupt flag cleared
    RETFIE
;*******************************************************************************
;   End of PIC program
;*******************************************************************************    
    END
;*******************************************************************************    
    