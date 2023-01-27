;*******************************************************************************
;  Program to test interrupt om port RB0. A pushbutton is connected to port
;  RB0 and it toggles a LED on portB, ilne2. Another LED on portB, line 1, flashes 
;  on and off at 1/2 second intervals
;*******************************************************************************
#include "p16f887.inc"
    
; __config 0xE0D7
 __CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 cblock		H'200'
   I				; a counter register
   J				; a counter register
   K				; another counter register
   count1			; auxiliary counter
   count2			; ISR counter
   OLD_W			; varabiables for 
   OLD_STATUS			; context saving in ISR due to interrupt latency
 endc
 
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
;*******************************************************************************
    org		H'0004'
    goto    IntServ
    
; TODO INSERT ISR HERE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                     ; let linker place main program

START:
    ; set up interrupt on falling edge by
    ; clearing OPTION register bit 6
    ;-----------------------------------------------------------
    BSF	    STATUS,RP0		   ; select bank 1
    ; BSF STATUS,RP1 BCF   STATUS,RP0 -> goto bank 2
    MOVLW   H'BF'                  ; b'10111111
    MOVWF   OPTION_REG
    MOVLW   H'FF'                  ; b'11111111
    MOVWF   TRISA		   ; set port A for input
    MOVLW   H'01'                  ; b'00000001
    MOVWF   TRISB		   ; set port B bit 0 as input
    BSF	    IOCB, RB0		   ; enable state change in RB0
    ;-----------------------------------------------------------
    BCF	    STATUS,RP0		   ; select bank 0
    CLRF    PORTB		   ; all portB pins to 0
    BSF	    PORTB, RB0		   ; set line 0 bit to turn on led
    ;-----------------------------------------------------------
    BSF	    STATUS, RP1		   ;   
    BCF	    STATUS, RP0		   ; select bank 2
    BCF	    CM1CON0, C1ON	   ; turn off comparator 1
    BCF	    CM2CON0, C2ON	   ; turn off comparator 2
;-------------------------------------------------------------------------------    
    BSF	    STATUS,RP0		   ; select bank 3
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   ANSELH		   ; all ports as digital output

;*******************************************************************************
; INTERRUPT SETUP
;*******************************************************************************
    BCF	    INTCON, INTF	   ; clear the external interrupt flag
    BSF	    INTCON, GIE		   ; enable global interrupts
    BSF	    INTCON, RBIE	   ; enable rb0 interrupt
    
;*******************************************************************************
;   FLASH LED
;*******************************************************************************
LIGHTS:
    
    MOVLW   D'3'
    MOVWF   I			   ; prepare counter for the 3 time loop
    MOVLW   H'02'		   ; copy b'00000010 to W register
    XORWF   PORTB, F		   ; invert port state
L1: CALL    LongDelay		   ; call LongDelay subroutine 3 times
    DECFSZ  I, F
    GOTO    L1			   ; skip this line of code if i = 0
    GOTO    LIGHTS		   ; repeat main routine
    
;*******************************************************************************
; INTERRUPT SERVICE ROUTINE
;*******************************************************************************
IntServ:
    ; first, test if source is an RB0 interrupt
    BTFSS   INTCON, INTF
    GOTO    notRB0
    
    ; save context due to interrupt latency------------------------- 
    MOVWF   OLD_W		    ; save W register
    SWAPF   STATUS, W
    MOVWF   OLD_STATUS		    ; save status
    ;--------------------------------------------------------------
    
    ; make sure interrupt occured on the falling edge of the signal
    BSF	    STATUS, RP0		    ; go to bank 1
    BTFSC   PORTB, RB0		   ; is bit set? 
    GOTO    exitISR		   ; leave ISR if not set
    
    ; interrupt action -> debounce switch. 
    ; Logic: debounce algorithm consists in waiting until the
    ; same level is repeated on a number of samplings of the 
    ; button. At this point RB0 line is clear since the interrupt
    ; takes place on the falling edge. An initial short delay 
    ; makes sure that spikes for mechanical accomodation are ignored
    MOVLW   D'10'		   ; number of repetitions
    MOVWF   count2		   ; stored in counter
WAIT:
    ; check to see that portB bit 0 is still low, if not
    ; wait until its state chagnes
    BTFSC   PORTB, RB0
    GOTO    exitISR
    ; at this pint rb0 bit is clear, so
    DECFSZ  count2, F		  ; count this iteration
    GOTO    WAIT		  ; go there if bit not 0
    
    ; toggle bit 2 of PORTB to turn LED on and off
    MOVLW   H'02'		  ; Xoring with a 1-bit produces
    XORWF   PORTB, F		  ; complement bit 2, port B
    
exitISR:
    ; restore saved context ---------------------------------------
    SWAPF   OLD_STATUS, W	  ; save STATUS to W
    MOVFW   STATUS		  ; store in current STATUS regiser
    SWAPF   OLD_W, F		  ; swap file register in itself
    SWAPF   OLD_W, W		  ; reswap back to W
    ;--------------------------------------------------------------
notRB0:
    BCF	    INTCON, INTF         ; interrupt flag cleared
    RETFIE
;*******************************************************************************
; SUBROUTINES
;******************************************************************************* 
; procedure to delay 10 machine cycles
delay:
    MOVLW   D'4'		 ; repeat 12 machine cycles
    MOVWF   count1		 ; store value in counter
repeat:
    DECFSZ  count1, F
    GOTO    repeat
    RETURN
;*******************************************************************************
LongDelay:
    MOVLW   D'200'
    MOVWF   J
Jloop:
    MOVWF   K
Kloop:
    DECFSZ  K, F		 ; skip next opcode if K = 0
    GOTO    Kloop
    DECFSZ  J, F
    GOTO    Jloop
    RETURN
    
;*******************************************************************************    
    END