;*******************************************************************************
;
;   Originally this code was for pic16f84a running at 4MHz. 
;   It comminucates with 74HC164 and 74HC165 shift registers. 
;
; DESCRIPTION:
;   The 74HC165 inputs 8 lines from a DIP switch and transmits settings to
;   PIC through a serial line. PIC sends data serially to an 74HC164 which
;   is wired to 8 LEDS that display the received data. A total of 6 PIC lines
;   are used in interfacing 8 input switches to 8 output LEDS.
;
; CIRCUIT: 
;   * RA0 is the serial transmission line which comes from the 74HC165
;   * RA1 is wired to the 74HC164 CLOCK pin
;   * RA2 is wired to the 74HC164 CLEAR pin
;   * 74HC164 output pins 0 to 7 are wired to LEDS
;   * RB0 is wired to the 74HC165 Hout line
;   * RB1 is wired to the 74HC165 CLK line
;   * RB2 is wired to the 74HC165 load line
;   * a pushbutton switch is in the pic16f84 RESET line
;     and serve to restart the program
;
; PROTOCOL:
;   Communicatin between PIC and the 74HC164 and 74HC165 is synchronous since
;   the shift registers clock lines serve to shift in and out the data bits.
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
#define clk74HC164   RA1
#define	clr74HC164   RA2
#define	data74HC164  RA0
;
#define clk74HC165   RB1
#define	load74HC165  RB2
	
;*******************************************************************************
; PIC register flag equates
;*******************************************************************************
MSB	    EQU	    7			; high order bit
	    
;*******************************************************************************
; Variables defined in PIC RAM
;*******************************************************************************
CBLOCK	    H'20'
   bitCount				; a counter for eight bits
   dataReg                              ; data to be sent through USART
   accuReg				; accumulator register for bit shifts
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
    MOVLW   H'00'		    ; portA as output
    MOVWF   TRISA		    ; 
    MOVLW   H'01'		    ; pin 0 is input
    MOVWF   TRISB		    ; the rest is output
    
    Bank0
    MOVLW   H'04'		    ; make sure PORTA line 2
    MOVWF   PORTA		    ; is set to high state (clear line)
    
;*****************************;
;  read input from 74HC165 IC ;
;*****************************;
    CALL    in_74HC165		    ; at this point dataReg contains input
    
;***********************************;
;   invoke serial output procedure  ; 
;***********************************;
    CALL    out_74HC164		    ; send data to second register shift
    
;***************;
;  wait forever ;
;***************;
endLoop
    GOTO    endLoop

;*******************************************************************************
;   74HC164 IC SUBROUTINE to send serial data
;*******************************************************************************
; ON ENTRY:
;	local variable dataReg holds 8-bit value to be transmitted through
;	port labeled serialLN
;
; OPERATION:
;     1. a local counter (bitCount) is initialized to eight bits.
;     2. first bit is assumed to be zero by setting the data line 
;	 low. Then the high-order bit in the data register (dataReg) is tested.
;	 If set, the data ilne is changed to HIGH
;     3. bits are shifted by pulsing the 74HC164 clock line (CLK).
;     4. data line are then shifted left and the bit counter is tested.
;        If all eight bits have been sent, the procedure returns.
; ------------------------------------------------------------------------------
out_74HC164
    BCF	    PORTA, clr74HC164	    ; clear shit register
    BSF	    PORTA, clr74HC164	    ; then set clear line to HIGH again
    
    MOVLW   H'08'
    MOVWF   bitCount		    ; initialize counter
;------------------------------------------------------------------------------
sendBit
    BCF	    PORTA, data74HC164	    ; set data line low (assume)
    ; using this assumption is possible because the bit is not
    ; shifted in untill the clock line is pulsed.
    BTFSC   dataReg, MSB	    ; test number bit 7
    BSF	    PORTA, data74HC164	    ; change assumption if set
    
;*******************;
;  pulse clock line ;
;*******************;-----------;
    ; bits will be shifted here ;
    ;---------------------------;
    BSF	    PORTA, data74HC164	    ; HIGH
    BCF	    PORTA, data74HC164	    ; CLK pin is LOW now
    
;************************;
;  rotate data bits left ;
;************************;
    RLF	    dataReg, F		    ; shift left data bits
    DECFSZ  bitCount, F		    ; decrement bit counter
    GOTO    sendBit		    ; repeat if not 8 bits
    
;***********************;    
;  end of transmission  ;
;***********************;    
    RETURN 
    
;******************************************;
;   74HC165 IC SUBROUTINE to read parallel ;
;	data and send serially to PIC      ;
;******************************************;------------------------------;
;									  ; 
; OPERATION:							          ;
;     1. eight DIP switches are connected to the input ports of an        ;
;        74HC165 IC. Its output line Hout and its control lines CLK       ;
;        and LOAD are connected to the PIC's portb lines 0, 1, and 2.     ;
;	 low. Then the high-order bit in the data register (dataReg)      ;
;     2. procedure sets a counter (bitCount) for eight iterations and     ;                 ;
;        clears a data holding register (dataReg)                         ;
;     3. PORTB bits are read into W and only the LSB of PORTB is relevant ;
;        This value is stored in a working register and the meaningful    ;
;        bit is rotated into the carry flag, then the carry flag bit is   ;
;	 then sifted into the data register.				  ;
;     4. the iteration counter is decremented. If this is the last        ;
;        iteration the routine ends. Otherwise the bitwise read-and-write ;
;	 operation is repeated.                                           ; 
; ------------------------------------------------------------------------;
in_74HC165
    CLRF    dataReg			; clear data register
    MOVLW   H'08'			; initialize counter
    MOVWF   bitCount			; 
    BCF	    PORTB, load74HC165		; reset shift register
    BSF	    PORTB, load74HC165

nextBit
    MOVF    PORTB, W			; read PORTB, only LSB are needed
    MOVWF   accuReg			; store value in local register
					
    RRF	    accuReg, F			; rotate LSB bit into carry flag
    RLF	    dataReg, F			; carry flag value into dataReg
    DECFSZ  bitCount, F			; decrement bit counter
    GOTO    shiftBits			; continue if not zero
    RETURN				; otherwise, end procedure
    
shiftBits
    BSF	    PORTB, clk74HC165		; pulse clock, line to HIGH
    BCF	    PORTB, clk74HC165		; line to LOW state
    GOTO    nextBit			; continue
    
;*******************************************************************************
    END
;*******************************************************************************