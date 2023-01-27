
;*******************************************************************************
;  Program to use external interrupt on port RB0. It terminates the power-down
;    state cuased by the SLEEP instruction. A pushbutton is connected to port
;  RB0 and it generates the interrupt to wake the MCU up. A LED on portB, line 1, 
;    flashes on and off at 1/2 second intervals
;*******************************************************************************
#include "p16f887.inc"
    
; __config 0xE0D7
 __CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 cblock		H'200'
   J				; a counter register
   K				; another counter register
   count1			; auxiliary counter
   count2			; ISR counter
   OLD_W
   OLD_STATUS
   bitsB47		        ; store for previous value in port-B bits
   temp
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
    ; wiring
    ; PORTB -> RB4 = pushbutton for red led
    ;          RB7 = pushbutton for green led
    ;
    ; PORTA -> RA0 = red led
    ;          RA1 = green led
    ; set up interrupt on falling edge by
    ; clearing OPTION register bit 6
    ;
    ; BCF STATUS,RP1  (BCF   STATUS,RP0) -> goto bank 0
    ; BSF STATUS,RP1  goto bank 1
    ; BSF STATUS,RP1  +  BCF   STATUS,RP0 -> goto bank 2
    ; BSF STATUS,RP1  +  BSF   STATUS,RP0 -> goto bank 3
    BSF	    STATUS, RP0		   ; select bank 1  
    MOVLW   H'97'                  ; b'10010111, psa: tmr0, 1:256
    MOVWF   OPTION_REG
    MOVLW   H'00'                  ; b'11111111
    MOVWF   TRISA		   ; set port A for output
    MOVLW   H'F0'                  ; b'11110000, pins 4 and 7 as input
    MOVWF   TRISB		   ; set port B all other pins output
    MOVWF   IOCB		   ; enable state change for RB4-7
    ;-----------------------------------------------------------------
    BCF	    STATUS,RP0		   ; select bank 0
    CLRF    PORTB
    MOVLW   H'00'
    MOVWF   bitsB47
    BSF     PORTA, RA0		   ; set leds on line 0
    BSF	    PORTA, RA1		   ; and line 1 
   ;-----------------------------------------------------------------   
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
    BSF	    INTCON, GIE		   ; enable global interrupts (bit 7)
    BSF	    INTCON, RBIE	   ; enable rb0 interrupt (bit 3)
    
;*******************************************************************************
;   FLASH LED 20 times
;*******************************************************************************
MAIN:
    NOP		    		   ; program does nothing since all
    GOTO    MAIN		   ; the action takes place in the ISR
    
;*******************************************************************************
; INTERRUPT SERVICE ROUTINE
;*******************************************************************************
IntServ:
    ; first, test if source is an RB4-7 interrupt
    BTFSS   INTCON, RBIF
    GOTO    notRBIF
    
    ;save context
    MOVWF   OLD_W
    ;BCF    STATUS, RP0             ; access BANK1
    SWAPF   STATUS, W
    MOVWF   OLD_STATUS
    
    ; interrupt action - it is triggered when any PORTB bits 4 to 7
    ; detect a STATUS change
    ;BSF    STATUS, RP1             ; access BANK1
    MOVF    PORTB, W		    ; read PORTB bits
    MOVWF   temp		    ; save state value to temp
    XORWF   bitsB47, F		    ; xor it with old bits
				    ; store result in F
    BTFSC   bitsB47, 4		    ; check bit RB4 state
    GOTO    bit4Change		    ; jump to routine if it has changed
    
    BTFSC   bitsB47, 7		    ; if not, check bit RB7 state
    GOTO    bit7Change		    ; jump to routine if it has changed
    
    ; invalid port line change, exit
    GOTO    btnRelease

;******************** 
; bit4 state change ;
;********************
bit4Change:			    ; check for signal falling edge
    BTFSC   PORTB, RB4		    ; is bit 4 high?
    GOTO    btnRelease
    ; by toggling bit 1 of PORTA turns LED on and off
    MOVLW   H'02'
    XORWF   PORTA, F		    ; invert PORTA state
    GOTO    btnRelease
    
;******************** 
; bit7 state change ;
;********************
bit7Change:			    ; check for signal falling edge
    BTFSC   PORTB, RB7		    ; is bit 4 high?
    GOTO    exitISR
    ; by toggling bit 0 of PORTA turns LED on and off
    MOVLW   H'01'
    XORWF   PORTA, F		    ; invert PORTA state

;********************** 
; push button release ;
;**********************
btnRelease:
    CALL    Delay		    ; debounce switch
    MOVF    PORTB, W		    ; read portB into W
    ANDLW   H'90'		    ; eliminate unused bits
    BTFSC   STATUS, Z		    ; check for zero
    GOTO    btnRelease		    ; wait

;*********************************** 
; end of interrupt service routine ;
;***********************************
exitISR:
    MOVF    temp, W		    ; store new value of PORTB
    MOVWF   bitsB47		    ; load it
    ; restore context
    SWAPF   OLD_STATUS, W
    MOVFW   STATUS
    SWAPF   OLD_W, F
    SWAPF   OLD_W, W

notRBIF:
    BCF	    INTCON, RBIF	    ; clear intcon bit 0 (interrupt flag)
    RETFIE
    
;*******************************************************************************
; SUBROUTINES
;******************************************************************************* 
Delay:
    MOVLW   D'6'		    ; repeat it 18 machine cycles
    MOVWF   count1
D1: DECFSZ  count1, F
    GOTO    D1
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