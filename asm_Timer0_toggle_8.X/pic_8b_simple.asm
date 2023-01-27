
;*******************************************************************************
;  Program to demonstrate programming the TIMER0 module.
;    8 LEDS are flashed in sequence counting from 0 to 0xFF. TIMER0
;    is used to delay the count 
;*******************************************************************************
#include "p16f887.inc"
    
; __config 0xE0D7
 __CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
;*******************************************************************************
    org		H'0004'
    RETFIE
    
; TODO INSERT ISR HERE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                     ; let linker place main program

START:
    ; OPTION_REG
    ; 
    ; bt7: NOT_RBPU -> 0 = EN, 1 = DIS
    ; bt6: INTEDG -> 0 = falling edge
    ; bit5: T0CS (TMR0 clock source), 0 = internal, 1 = RA4/TOCKI bit src
    ; bit4: T0SE (TMR0 edge select), 0 = inc low-to-high, 1 = inc high-to-low
    ; bit3: PSA (prescaler assign) 1 = to WDT, 0 = to TMR0
    ; <bit2:0> presclaer bits, 000 1:2, 010 1:8, 100 1:32, 110 1:128, 
    ; 001 1:4, 011 1:16, 101 1:64 and 111 1:256, VALUE: b'11010111'
    BSF	    STATUS, RP0		   ; select bank 1  
    MOVLW   H'D7'                  ; set value: b'11010111'
    MOVWF   OPTION_REG
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   TRISB		   ;   set port B pins as output
;-------------------------------------------------------------------------------    
    BCF	    STATUS,RP0		   ; select bank 0
    CLRF    PORTB
;-------------------------------------------------------------------------------
    BSF	    STATUS, RP1		   ;   
    BCF	    STATUS, RP0		   ; select bank 2
    BCF	    CM1CON0, C1ON	   ; turn off comparator 1
    BCF	    CM2CON0, C2ON	   ; turn off comparator 2
;-------------------------------------------------------------------------------    
    BSF	    STATUS,RP0		   ; select bank 3
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   ANSELH		   ; all ports as digital output
    
;*******************************************************************************
;   Main routine
;*******************************************************************************

Loop: 
    INCF    PORTB, F		   ; turn on next LED
    CALL    TMR0_Delay		   ; invoke subroutine 
    GOTO    Loop		   ; repeat process
    
;*******************************************************************************
; Timer 0 routine 
;   it tests the vlaue in the TMR0 register
;   by sbustracting 0xFF from the value stored there. The zero flag
;   is then set if TMR0 = 0xFF
;*******************************************************************************
TMR0_Delay:
    CLRF    TMR0
Cycle:
    MOVF    TMR0, W		    ; store TMR0 in W register
    SUBLW   H'FF'
    BTFSS   STATUS, Z		    ; test for zero
    GOTO    Cycle		    ; repeat it
    RETURN  
    
;*******************************************************************************
;CONVERT
;    movf	timer,W		    ; copy timer contents to Work register
;    andlw	H'0F'		    ; mask for counter value
;    addwf	PCL,F		    ; PCL = PCL + W
;    retlw	B'11101110'	    ; returns '0'
;    retlw	B'00101000'	    ; returns '1'
;    retlw	B'11001101'	    ; returns '2'
;    retlw	B'01101101'	    ; returns '3'
;    retlw	B'00101011'	    ; returns '4'
;    retlw	B'01100111'	    ; returns '4'
;    retlw	B'11100111'	    ; returns '5'
;    retlw	B'00101100'	    ; returns '6'
;    retlw	B'11101111'	    ; returns '7'
;    retlw	B'10101111'	    ; returns '8'
;    retlw	B'11100011'	    ; returns '9'
;    retlw	B'11000110'	    ; returns 'A'
;    retlw	B'11101001'	    ; returns 'B'
;    retlw	B'11000110'	    ; returns 'C'
;    retlw	B'11101001'	    ; returns 'D'
;    retlw	B'11000111'	    ; returns 'E'
;    retlw	B'10000111'	    ; returns 'F'
; -----------------------------------------------------------------------------
;UPDATE
;    call	CONVERT		    ; get a binary sequence for character
;    movwf	PORTB
;    return

    END