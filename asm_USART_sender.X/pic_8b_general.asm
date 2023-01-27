;*******************************************************************************
;
; Originally this code was for pic16f84a running at 4MHz. 
; It sneds data through a single line. 
;
; Circuit:
;   portA RA1 is the serial transmission line
;   portA RA2  is an active-low push button switch that serves to initiate
;   communications.
;
;   portA RA3  is a Led that is ON when the program is ready to send data.
;   Once data starts being sent the LED is turned off.
;    
;   PORTB, B0-B7 is a 8 x toggle switch that provides the data byte to be
;   sent. A push button switch is in the 16f84 RESET line
;
;   A push button switch is the 16f84a reset line and serves to restart program.
;    
;    Communication params:
;        Timer channel TMR0 is used for synchronizing data transmission.
;    The timer runs at the maximum rate of 256 cycles per iteration. In a
;    4 MHz system the rate is 1 MHz, thus the bit rate is 1 Mi/256
;    which is approximately 3,906 microseconds per bit
;    
;*******************************************************************************
#include "p16f628a.inc"

;*******************************************************************************
; __config 0xFF19
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

;*******************************************************************************
Bank0	MACRO				; select RAM bank 0
	bcf	STATUS, RP0
	ENDM
;------------------------------------------------------------
Bank1	MACRO				; select RAM bank 1
	bsf	STATUS, RP0
	ENDM	
;*******************************************************************************
; Constant definitions for pin wiring
;*******************************************************************************
#define readySW	    2
#define	readyLED    3
#define	serialLN    1	
	
;*******************************************************************************
; PIC register flag equates
;*******************************************************************************
c_flag	    EQU	    0			; Carry flag ("vai um")
tmr0_overf  EQU	    T0IF		; timer overflow bit
	    
;*******************************************************************************
; Variables defined in PIC RAM
;*******************************************************************************
CBLOCK	    H'20'
   bitCount				; a counter for eight bits
   dataReg                             ; data to be sent through USART
ENDC	    
;*******************************************************************************
; Reset Vector
;*******************************************************************************
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; INSERT ISR HERE
     ISR     CODE    0x0004           ; interrupt vector location
     RETFIE   
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START

    Bank1
    MOVLW   H'04'
    MOVWF   TRISA		    ; PORTA, RA2 is input, rest is output
    MOVLW   H'04'
    MOVWF   TRISB		    ; PORTB as input
    
    Bank0
    BSF	    PORTA, 1		    ; marking bit
    CLRF    TMR0		    ; prepare to set prescale
    CLRWDT
    
    ;----------------------------------------------------
    ; set up option_reg register for full timer speed
    ; NOT_RBPU: pullups -> 1, disabled
    ; INTEDG: 1, raising edge
    ; T0CS: timer zero clock source -> 0, internal clock
    ; T0SE: timer zero edge select -> 1, inc for hi-to-lo
    ; PSA: prescaler assign, 1: to WDT
    ; 0  0  0 -> 1:2 prescaler, value: b'11011000'
    MOVLW   H'D8'
    MOVWF   OPTION_REG
    
    BCF	    INTCON, T0IE	    ; timer0 overflow interrupt enable OFF
    BCF	    INTCON, GIE		    ; global interrup disabled
    BSF	    PORTA, RA3		    ; LED is on
    
;*******************************************************************************
;  Wait for ready switch to be pressed
;*******************************************************************************
Ready2Send
    BTFSC   PORTA, readySW
    GOTO    Ready2Send
    
;***********************;
;    send serial DATA   ; 
;***********************;
turnOffLed			; at this point program proceeds to send
    BCF	    PORTA, readyLED	; data through the serial port line
    
readSwitches
    MOVF    PORTB, W
    MOVWF   dataReg
    
;*****************************;
; call serial output procdure ;
;*****************************;
    CALL    sendData

;***************;
;  wait forever ;
;***************;
EndLoop
    GOTO    EndLoop

;*******************************************************************************
;  SUBROUTINES to deal with serial data
;*******************************************************************************
; ON ENTRY:
;	local variable dataReg holds 8-bit value to be transmitted through
;	port labeled serialLN
;
; OPERATION:
;     1. the timer at register TMR0 is set to run at max clock speed, that is
;	  to say: 256 clock beats. The timer overflow flag in the INTCON register
;`	  is set when the timer cycles from 0xFF to 0x00
;     2. each bit (start, data and stop bits) is sent at a rate of 256 timer
;	  beats. That is, each bit is held high or low one full timer cycle 
;   	 (256 clock beats)
;     3. the procdure tests the timer overflow flag (tmr_ovf) to determine when
;	 the timer cycle has ended, that is when 256 clock beats have passed
; ------------------------------------------------------------------------------
sendData
    MOVLW   H'08'		    ; setup shift countre
    MOVWF   bitCount

;******************;
;  send start bit  ;
;******************;
    BCF	    PORTA, serialLN	    ; set line low then hold for 256
				    ; timer clock beats
    CLRF    TMR0		    ; reset timer counter
    BCF	    INTCON, tmr0_overf	    ; reset T0IF, timer0 overflow interrupt flag
    
startBit
    BTFSS   INTCON, tmr0_overf	    ; timer 0 overflow?
    GOTO    startBit		    ; wait until it is set
				    ; at this point timer has cycled
    BCF	    INTCON, tmr0_overf	    ; Start bit has ended.
    
;*********************;
;  send 8 data bits   ;
;*********************;----------------------------------------------------;
;  The bits are rotated left to the carry flag. Code assumes the bit       ; 
;   is zero and sets the serial line low. Then the carry flag is tested.   ;
;  If the carry is set the serial line is changed to high. The line is kept;
;   low or high for 256 timer beats                                        ; 
;--------------------------------------------------------------------------;
sendEight
    RLF	    dataReg, F		    ; bit stored into carry flag
    BCF	    PORTA, serialLN	    ; send 0 to serial line

;*********************;----------------------------------------------------;
;  It is assumed the bit is a zero and set the line low since, if low is   ; 
;   the wrong state, it will only remainf for two timer beats. The receiver;
;   will not check the line for data until 128 timer beats have elapsed, so;
;   the error will be harmless. In any case, there is no assurance that the;
;   previous line state is the correct one, so leaving the line in its     ;
;   previous state could also be wrong.                                    ; 
;--------------------------------------------------------------------------;
    BTFSC   STATUS, c_flag	    ; test carry flag
    BSF	    PORTA, serialLN	    ; bit is set, fix error.
    
bitWait
    BTFSS   INTCON, tmr0_overf	    ; timer cycled?
    GOTO    bitWait		    ; not yet
    
    BCF	    INTCON, tmr0_overf	    ; timer has cycled
    DECFSZ  bitCount, F		    ; test for end of byte, if not
				    ; so send next bit
    GOTO    sendEight		    ; repeat it if last bit not reached
    
;*********************;
;  hold marking state ;
;*********************;------------------------------------------------;    
; all 8 data bits have been set, the serial line must now be held high ;
; (MARKING) for one clock cycle                                        ;      
;----------------------------------------------------------------------;
markWait
    BTFSS   INTCON, tmr0_overf	    ; Done?
    GOTO    markWait		    ; not yet
    
;*********************;
;  end of tansmission ;
;*********************;    
    RETURN			    ; done.
    
;*******************************************************************************
    END
;*******************************************************************************