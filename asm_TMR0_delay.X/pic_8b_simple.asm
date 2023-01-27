
;*******************************************************************************
;  Using timer0 to produce a variable lapse delay.
;    The delay is calculated based on the number of machine
;     cycles necessary for the desired wait period. For
;     example, a machine running at a 4 MHz clock rate
;     execute 1 million instructions per second. In this
;     case a 1/2 second delay requires 500,000 instructions.
;     The wait period is passed to the delay routine in three program
;     registers which hold the high-, middle- and low-order bytes of the counter
;     But in the case of a 16 MHz, it is 250 thousand instructions per second
;*******************************************************************************
#include "p16f887.inc"
    
; __config 0xE0D7
 __CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 CBLOCK		H'200'
    countH
    countM
    countL
 ENDC
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
    ; 001 1:4, 011 1:16, 101 1:64 and 111 1:256, VALUE: b'11110000'
    BSF	    STATUS, RP0		   ; select bank 1  
    MOVLW   H'F0'                  ; set value: b'11110000 (PSA 1:2)'
    MOVWF   OPTION_REG
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   TRISB		   ;   set port B pins as output
;---------------------------------------------------------------    
    BCF	    STATUS,RP0		   ; select bank 0
    CLRF    PORTB
;---------------------------------------------------------------
    BSF	    STATUS, RP1
    BCF	    STATUS, RP0		   ; select bank 2
    BCF	    CM1CON0, C1ON	   ; turn off comparator 1
    BCF	    CM2CON0, C2ON	   ; turn off comparator 2
;---------------------------------------------------------------    
    BSF	    STATUS,RP0		   ; select bank 3
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   ANSELH		   ; all ports as digital output
    CLRF    TMR0		   ; clear timer zero value
    CLRWDT			   ; reset watch dog timer

;*******************************************************************************
;   Main routine
;*******************************************************************************
Loop: 
    BSF     PORTB, RB0		   ; turn led on
    CALL    OneHalfSec
    CALL    TMR0_Delay		   ; invoke subroutine 
    BCF	    PORTB, RB0
    CALL    OneHalfSec
    CALL    TMR0_Delay		   ; invoke subroutine 
    GOTO    Loop		   ; repeat process
    
;*******************************************************************************
;   The prescaler is assigned to timer0 and set up so that the timer runs 
;   at 1:2 rate. This means, that every time the counter reaches 128 (0x80)
;   a total of 256 machine cycles have elapsed. The value 0x80 is detected by
;   testing bit 7 of the counter register.
;
;   Timer0 register provides low-order level of the count. Since the counter
;    counts up to from zero, in order to ensure that the initial low-level delay
;    count is correc the value 128 - (xx/2) must be calculated where xx is the value
;    in the original countL register. First calculate xx/2 by bit shifting
;*******************************************************************************
TMR0_Delay:
    BCF     STATUS, C		    ; clear carry flag
    RRF	    countL, F		    ; divide by 2
    MOVF    countL, W		    ; substract 128-(xx/2)
    SUBLW   D'128'
    MOVWF   TMR0
    
Cycle:
    BTFSS   TMR0,7		    ; is bit 7 set?
    GOTO    Cycle		    ; wait if not set 
    BCF     TMR0,7		    ; All other bits are preserved
    
    ; substract 256 from beat counter by decrementing the mid-order byte
    DECFSZ  countM, F
    GOTO    Cycle		    ; continue if mid-byte not zero
    
    ; at this point the mid-order byte has overflowed
    ; high-order byte must be decremented
    DECFSZ  countH, F
    GOTO    Cycle
    
    ; at this point the time cycle has elapsed
    RETURN  
    
;*******************************************************************************    
; SET REGISTER VARIABLES FOR ONE-HALF SECOND DELAY
;  (P16F84 at 4 MHz)
;   
;  Timer is set up for 500000 clock beats as follows:
;  500,000 = 0x07 0xA1 0x20 (countH: H'07', countM: H'A1', countL: H'20'
;
;  But for a 16 MHz crystal 2 Mi clock beats are needed to create a half sec delay
;  2,000,000 = 0x1E 0x84 0x80 (but the prescaler is 1:2, so 16 Mi/2 = 1/4 Mi = 0.25 us
;			(countH: H'1E', countM: H'84', countL: H'80')
; For 1 second, it take 4,000,000 instructions:
; 4,000,000 = 0x3D 0x09 0x00    
;*******************************************************************************    
OneHalfSec:
    MOVLW   H'1E'
    ;MOVLW   H'3D'
    MOVWF   countH
    ;--------------
    MOVLW   H'84'
    ;MOVLW   H'09'
    MOVWF   countM
    ;--------------
    MOVLW   H'80'
    ;MOVLW   H'00'
    MOVWF   countL
    ;--------------
    RETURN
    
;*******************************************************************************        
    END
;*******************************************************************************