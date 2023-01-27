;***********************************************************
; INT1.ASM M. Bates 12/6/66 Ver 2.1
; ***********************************************************
; Minimal program to demonstrate interrupts.
;
; An output binary count to LEDs on PortB, bits 1-7
; is interrupted by an active low input at RB0/INT.
; The Interrupt Service Routine sets all outputs high,
; and waits for RA4 to go low before returning to
; the main program.
; Connect push button inputs to RB0 and RA4
;
;
; Processor: PIC 16F84
; Hardware: PIC Modular Demo System
; (reset switch connected to RB0)
    
; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
#include "p16f627a.inc"

; CONFIG
; __config 0xFF18
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

; ****************************************************************  
; Register Label Equates........................................
; ****************************************************************  
timer	EQU	H'0C'		    ; GPR1 = delay counter
tempb	EQU	H'0D'		    ; GPR2 = Output temp. store

; **************************************************************** 	
; Input Bit Label Equates .......................................
; **************************************************************** 
intin	EQU	RB0		    ; Interrupt input = RB0
resin	EQU	RA4		    ; Restart input = RA4
;
; ****************************************************************
;  reset vector	
; ****************************************************************	
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
; ****************************************************************
; interrupt vectors address
; ****************************************************************    
    ORG	    H'0004'
    GOTO    RB0_ISR

; ****************************************************************
;  start of program	    
; **************************************************************** 	    
MAIN_PROG CODE              ; let linker place main program

START
    BSF	    STATUS,RP0	    ; access bank 1
    MOVLW   B'00000001'	    ; Set data direction bits
    MOVWF   TRISB	    ; and load TRISB
    MOVLW   H'07'
    MOVWF   CMCON	    ; turn off comparators
    
    ;-----------------------------------------------------
    BCF	    STATUS,RP0	    ; access bank 0
    CLRF    PORTB
    MOVLW   B'10010000'	    ; Enable RB0 interrupt in
    MOVWF   INTCON	    ; Interrupt Control Register
    
; **************************************************************** 	    
; Main output loop .............................................
; **************************************************************** 	    
COUNT
    INCF    PORTB	     ; Increment LED display
    CALL    Delay	     ; Execute delay subroutine
    GOTO    COUNT	     ; Repeat main loop always
    
; **************************************************************** 
; Interrupt Service Routine at address 004........................
; ****************************************************************     
RB0_ISR
    
    BTFSS   INTCON,INTF		; check interrupt flag state
    GOTO    exitISR		; leave interrupt if flag is not set
    
    MOVF    PORTB,W		; Save current output value
    MOVWF   tempb		; in temporary register
    MOVLW   B'11111111'		; Switch LEDs 1-7 on
    MOVWF   PORTB
Wait 
    BTFSC   PORTA,  resin	; Wait for restart input
    GOTO    Wait		; to go low
    MOVF    tempb,w		; Restore previous output
    MOVWF   PORTB		; at the LEDs
    BCF	    INTCON,INTF		; Clear RB0 interrupt flag
exitISR    
    RETFIE			; Return from interrupt
	    
; ***************************************************************
; DELAY subroutine.............................................
; ***************************************************************
Delay 
    MOVLW   H'FF'	    ; Delay count literal is
    MOVWF   timer	    ; loaded into spare register
Again
    DECFSZ  timer	    ; Decrement timer register
    GOTO    Again	    ; and repeat until zero then
    RETURN		    ; return to main program
	     
; ************************************************************
    END ; Terminate source code
; ************************************************************
 