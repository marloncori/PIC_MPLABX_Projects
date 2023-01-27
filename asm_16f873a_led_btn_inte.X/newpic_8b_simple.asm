;==============================================================
; Description
;   Program to send/receive data through USART
;   A USB-USART fdti convert is wired to RC7/TX and R6/RX pins
;==============================================================
#include "p16f873a.inc"

; CONFIG
; __config 0xFF3A
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

;============================================================
; MACROS
;============================================================
; Macros to select the register banks
Bank0	MACRO		    ; Select RAM bank 0
	BCF	STATUS,RP0
	BCF	STATUS,RP1
	ENDM
;----------------------------------------------
Bank1	MACRO		    ; Select RAM bank 1
	BSF	STATUS,RP0
	BCF	STATUS,RP1
	ENDM
;-----------------------------------------------
Bank2	MACRO		    ; Select RAM bank 2
	BCF	STATUS,RP0
	BSF	STATUS,RP1
	ENDM
;----------------------------------------------
Bank3	MACRO		    ; Select RAM bank 3
	BSF	STATUS,RP0
	BSF	STATUS,RP1
	ENDM
;===============================================================================
; variables in PIC RAM
;===============================================================================
; Local variables
CBLOCK		 H'20'   ; Start of block
    count1
    count2
    count3
    count4
    W_TEMP
    STATUS_TEMP
    PCLATH_TEMP
ENDC
;===============================================================================
RES_VECT  CODE    H'0000'            ; processor reset vector
    GOTO    START                   ; go to beginning of program
;===============================================================================
; add interrupts here if used
    ORG	    H'0004'
    GOTO    RB0_ISR
;===============================================================================    
; PROGRAM
;===============================================================================
MAIN_PROG CODE                      ; let linker place main program

;------------------------------------------------------------------------------;
START    

    Bank1			   ; select bank 1  
    MOVLW   (1<<RB0)		   ; set RB0 as input for  
    IORWF   TRISB		   ; push button and external interrupt
    MOVLW   ~(1<<INTEDG)	   ; clear bit 6, for a falling edge interrupt
    ANDWF   OPTION_REG		   ; since push button is pullup
    
    Bank0			   ; select bank 0
    CLRF    PORTB		   ; clear portB
    MOVLW   ~(1<<INTF)		   ; make sure interrupt flag is cleared
    ANDWF   INTCON		   ; 
    MOVLW   (1<<GIE) | (1<<INTE)   ; enable global and external interrupts
    IORWF   INTCON		   ;
    MOVLW   D'2'
    MOVWF   count1
    BCF	    STATUS, C		   ; clear carry bit
;-------------------------------------------------------------------------------
Loop:
    COMF    PORTB, RB1		   ; invert PORTB state
L1: CALL    Delay_100ms		   ; wait some time
    DECFSZ  count1
    GOTO    L1
    GOTO    Loop
    
;===============================================================================    
;   Subroutines
;===============================================================================    
Btn1_debounce
    BSF	    PORTB, RB2
    CALL    Delay_100ms
    RETURN
;-------------------------------------------------------------------------------    
Btn2_debounce
    BSF	    PORTB, RB3
    CALL    Delay_100ms
    RETURN
;-------------------------------------------------------------------------------    
Delay_100ms
    MOVLW   D'255'
    MOVWF   count2
Outer_a
    CALL    Inner_b
    DECFSZ  count2
    GOTO    Outer_a
    RETURN
Inner_b
    MOVLW   D'122'
    MOVWF   count3
Outer_b    
    CALL    Inner_c
    DECFSZ  count3
    GOTO    Outer_b
    return
Inner_c
    MOVLW   D'100'
    MOVWF   count4
Outer_c
    DECFSZ  count4
    GOTO    Outer_c
    RETURN
;===============================================================================    
;    Interrupt service routine
;===============================================================================    
RB0_ISR
    BTFSC   INTCON, INTF	   ; if flag is not set
    CALL    led_IRQn		   ; go to this label
    RETFIE
;------------------------------------------------------------------------------
led_IRQn
    ; save context
    MOVWF   W_TEMP		    ; Copy W to TEMP register
    SWAPF   STATUS,W		    ; Swap status to be saved into W 
    CLRF    STATUS		    ; bank 0, regardless of current bank, 
				    ;it clears IRP,RP1,RP0
    MOVWF   STATUS_TEMP		    ;Save status to bank zero STATUS_TEMP reg
;------------------------------------------------------------------------------
    BTFSC  PORTB, RB4		   ; check for led state
    GOTO   ledOFF		   ; go here if it is on
;------------------------------------------------------------------------------				   
ledON
    BSF	    PORTB, RB4		   ; execute this code (turn led on)
    GOTO    exitISR
;------------------------------------------------------------------------------    
ledOFF
    BSF	    PORTB, RB4		   ; execute this code (turn led off)
;------------------------------------------------------------------------------    
exitISR    
    ; restore context
    SWAPF   STATUS_TEMP,W	    ;Swap STATUS_TEMP register into W 
				    ;(sets bank to original state)
    MOVWF   STATUS		    ;Move W into STATUS register
    SWAPF   W_TEMP,F		    ;Swap W_TEMP
    SWAPF   W_TEMP,W		    ;Swap W_TEMP into W reg
    BCF	    INTCON, INTF	   ; clear interrupt flag
    RETURN			   
;===============================================================================    
    END
;===============================================================================    