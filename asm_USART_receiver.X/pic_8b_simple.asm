;*******************************************************************************
;
; Originally this code was for pic16f84a running at 4MHz. 
; It sneds data through a single line. 
;
; Circuit:
;   portA RA0 is the serial transmission line
;   portA RA2  is an active-low push button switch that serves to initiate
;   communications.
;
;   portA RA3  is a Led that is ON when the program is ready to send data.
;   Once data starts being sent the LED is turned off.
;    
;   PORTB, B0-B7 is a 8 x toggle switch that provides the data byte to be
;   sent. A push button switch is in the 16f84 RESET line
;
;   A push button switch is in pic16f84a reset line and serves to restart app.
;    
;    Communication params:
;        Timer channel TMR0 is used for synchronizing data transmission.
;    The timer runs at the maximum rate of 256 cycles per iteration. In a
;    4 MHz system the rate is 1 MHz, thus the bit rate is 1 Mi/256
;    which is approximately 3,906 microseconds per bit
;    
;    Upon receiving the START bit, the program waits for one hald a clock cycle
;    (128 timer beats) to synchronize with the send.
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
   dataReg                               ; data to be sent through USART
   temp
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
    MOVLW   H'05'		    ; b'0101, RA0 and RA2 as input
    MOVWF   TRISA		    ; 
    MOVLW   H'00'
    MOVWF   TRISB		    ; PORTB as output
    
    Bank0
    CLRF    PORTB		    ; turn off all portb leds
    CLRF    dataReg		    ; prepare receiver register
    CLRF    TMR0
    CLRWDT
    
    ;----------------------------------------------------
    ; set up option_reg register for full timer speed
    ; NOT_RBPU: pullups -> 1, disabled
    ; INTEDG: 1, raising edge
    ; T0CS: timer zero clock source -> 0, internal clock
    ; T0SE: timer zero edge select -> 1, inc for hi-to-lo
    ; PSA: prescaler assign, 1: to WDT
    
    MOVLW   H'D8'		    ; 0  0  0 -> 1:2 prescaler 
    MOVWF   OPTION_REG		    ; value: b'11011000'
    
    BCF	    INTCON, T0IE	    ; timer0 overflow interrupt enable OFF
    BCF	    INTCON, GIE		    ; global interrup disabled
    
;*******************************************************************************
;  Wait for ready switch to be pressed
;*******************************************************************************
ready2Rcv
    BTFSC   PORTA, readySW	    ; test push button
    GOTO    ready2Rcv
    BSF	    PORTA, readyLED	    ; turn on the ready-to-rcv LED
    
;***********************;
;     receiving DATA    ; 
;***********************;
    CALL    rcvData		    ; invoke serial input procedure
    
;*****************;
;  DATA received  ;
;*****************;
    BCF	    PORTA, readyLED	    ; turn off the ready-to-rcv LED
    MOVF    dataReg, W		    ; display received data, copy byte to W
    MOVWF   PORTB		    ; display it in PORTB

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
;     4. the procedure tests the timer overflow flag to determine when the 
;         timer cycle has ended, that is when 256 clock beat have passed.
;	 
; ------------------------------------------------------------------------------
rcvData
    CLRF    TMR0		    ; reset timer zero
    MOVLW   H'08'		    ; setup bit counter
    MOVWF   bitCount

;**********************;
;  wait for start bit  ;
;**********************;
startWait    
    BTFSC   PORTA, serialLN	    ; is RA0 low?
    GOTO    startWait		    ; no, wait for mark
    
;*************************;
;  offset 128 clock beats ;
;*************************;--------------------------------------;
; at this point the receiver has found the falling edge of       ;
; the start bit. It must now wait 128 timer beats to synchronize ;
; in the middle of the sender's data rate, as follows:           ;
;         |<================= falling edge of START bit          ;
;         |                                                      ;
;         | --------|<============ 128 clock beats offset        ;
; ------- |                 .------------                        ;
;         |                 |  <== SIGNAL                        ;
;          -----------------                                     ;
;         |<--     256   -->|                                    ;
;                                                                ;
;----------------------------------------------------------------;
    MOVLW   H'80'		    ; 128 clock beats offset
    CLRF    TMR0		    ; reset timer counter
    BCF	    INTCON, tmr0_overf	    ; reset T0IF, timer0 overflow interrupt flag
    
offsetWait
    BTFSS   INTCON, tmr0_overf	    ; timer 0 overflow?
    GOTO    offsetWait		    ; wait until
    BTFSC   PORTA, serialLN	    ; test start bit for error
    GOTO    offsetWait		    ; recycle if it is a false start
    
;******************;
;  received  data  ;
;******************;
    CLRF    TMR0		    ; restart timer
    BCF	    INTCON, tmr0_overf	    ; clear overflow flag
    
;***************************************************;
; wait for 256 timer cycles for first/next data bit ;   
;***************************************************;
bitWait
    BTFSS   INTCON, tmr0_overf	    ; reset overflow flag
    MOVF    PORTA, W		    ; copy PORTA into W
    MOVWF   temp		    ; store read value
    RRF	    temp, F		    ; rotate bit 0 into carry flag
    RLF	    dataReg, F		    ; rotate carry into dataReg 0
    DECFSZ  bitCount, F		    ; eight bits received
    GOTO    bitWait		    ; next bit

;*******************************************;    
; wait for 1 time cycle at end of reception ;
;*******************************************;    
markWait
    BTFSS   INTCON, tmr0_overf	    ; timer 0 overflow flag
    GOTO    markWait		    ; keep waiting
    
;*********************;
;  end of tansmission ;
;*********************;    
    RETURN			    ; done.
    
;*******************************************************************************
    END
;*******************************************************************************