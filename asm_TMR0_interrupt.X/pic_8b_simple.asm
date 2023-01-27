
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
    OLD_W
    OLD_STATUS
 ENDC
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
;*******************************************************************************
    org		H'0004'
    GOTO    TMR0_ISR
    
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
    ; bit3: PSA (prescaler assign) *1 = to WDT, 0 = to TMR0
    ; <bit2:0> presclaer bits, 000 1:2, 010 1:8, 100 1:32, 110 1:128, 
    ; 001 1:4, 011 1:16, 101 1:64 and 111 1:256, VALUE: b'11010111'
    BSF	    STATUS, RP0		   ; select bank 1  
    MOVLW   H'D7'                  ; set value: b'11010111' (PSA 1:256)'
    MOVWF   OPTION_REG
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   TRISB		   ;   set port B pins as output
;------------------------------------------------------------    
    BCF	    STATUS,RP0		   ; select bank 0
    CLRF    PORTB
;-------------------------------------------------------------
    BSF	    STATUS, RP1
    BCF	    STATUS, RP0		   ; select bank 2
    BCF	    CM1CON0, C1ON	   ; turn off comparator 1
    BCF	    CM2CON0, C2ON	   ; turn off comparator 2
;--------------------------------------------------------------
    BSF	    STATUS,RP0		   ; select bank 3
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   ANSELH		   ; all ports as digital output
    CLRF    TMR0		   ; clear timer zero value
    CLRWDT			   ; reset watch dog timer
    
;*******************************************************************************
;   set up interrupts
;*******************************************************************************
    BCF	    INTCON, INTF	   ; clear interrupt flag
    BSF	    INTCON, GIE		   ; enable global interrupt
    BSF	    INTCON, T0IE	   ; enable timer0 interrupt

InitCount:
    CALL    OneHalfSec
;*******************************************************************************
;   Main routine
;*******************************************************************************
Loop: 
    ; all action takes place in the interrupt service routine
    GOTO    Loop		   ; repeat process
     
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
;  timer0 interrupt service routine
;*******************************************************************************        
TMR0_ISR:
    ; TMR0 overflow occurs when 256 timer beats have elapsed
    ;----------------------------------------------------------------------
    BTFSS   INTCON, T0IF	     ; test if source is a tmr0 interrupt
    GOTO    notT0IF                  ; if not, leave ISR
    BCF	    INTCON, T0IF             ; if so, clear interrupt flag
    
    ;save context
    MOVWF   OLD_W
    ;BCF    STATUS, RP0             ; access BANK1
    SWAPF   STATUS, W
    MOVWF   OLD_STATUS
    ;----------------------------------------------------------------------
    
    ;DECFSZ  countL, F
    ;GOTO    exitISR		    ; continue if low-byte equals zero
    
    ; substract 256 from beat counter by decrementing the mid-order byte
    DECFSZ  countM, F
    GOTO    exitISR		    ; continue if mid-byte not
    
    DECFSZ  countH, F		    ; after mid-order overflow,
    GOTO    exitISR		    ; decrement high-order bit
    
    ; at this point count has expired so the programmed time has
    ; elapsed. The ISR toggles the LED on line 0, PORTB.
    ; This is done by xoring a mask with a one-bit at PORTB,RB0
    MOVLW   H'01'
    XORWF   PORTB, F
    
    ; reset the one-half-second timer
    CALL    OneHalfSec
    ;----------------------------------------------------------------------
exitISR:
    ; restore context
    SWAPF   OLD_STATUS, W
    MOVFW   STATUS
    SWAPF   OLD_W, F
    SWAPF   OLD_W, W
    
notT0IF:
    RETFIE
;*******************************************************************************        
    END
;*******************************************************************************