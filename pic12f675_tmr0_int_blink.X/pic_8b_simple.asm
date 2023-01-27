
;=================================================================
; Description
;    
;       Program to blink led using a precisely calculated
;       one second delay. Internal 4MHz oscillator is used,
;       with a 256 prescaler, max count will be 244, the offset
;       from 256-244 is the TMR0 initial value. 
;    
;       Furthermore, a variable called 'intCycl' has been 
;       created to check if the needed 16 interrupt cycles 
;       have been reached so GPIO state can be toggled.
;
;       In case a 2 sec delay is desired, intCycl = 31 and TMR0
;       starting point will be 4 , with a max count per cycle of
;       252. Machine cycle equals 0.000256 seconds
;    
;       For a half second delay, intCycl wil be 8 and TMR0
;       value equals 12, with a max count per cycle of 244      
;    
;=================================================================
#include "p12f675.inc"

; __config 0xF1B5
 __CONFIG _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _CP_OFF & _CPD_OFF

;=================================================================
; MACROS
;============================================================
; Macros to select the register banks
Bank0	MACRO		    ; Select RAM bank 0
	BCF	STATUS,RP0
	ENDM
;----------------------------------------------
Bank1	MACRO		    ; Select RAM bank 1
	BSF	STATUS,RP0
	ENDM	
;===============================================================================
; variables in PIC RAM
;===============================================================================	
; Constant value	
OFFSET	   EQU	    H'0C'	
;-------------------------------------------------------------------------------
	   
; Global variables
CBLOCK		 H'20'   ; Start of memory block
    intCycl		            ; total cycles of interrupt to
                                    ; achieve desired delay time
    W_TEMP			    ; registers needed for context 
    STATUS_TEMP                     ; savigin in ISR
ENDC
;===============================================================================
RES_VECT  CODE    H'0000'           ; processor reset vector
    GOTO    START                   ; go to beginning of program
;===============================================================================
; add interrupts here if used
    ORG	    H'0004'
    GOTO    LED_ISR
;===============================================================================    
; PROGRAM
;===============================================================================
MAIN_PROG CODE                      ; let linker place main program

START
    Bank0	    
    CLRF    GPIO		    ; clear gpio
    MOVLW   H'07'		    ; copy value to W reg
    MOVWF   CMCON		    ; turn off comparators
    ;---------------------------------------------------------------------------
    Bank1			    ; select bank 1  
    CLRF    ANSEL		    ; gpio as digital
    CLRF    TRISIO                  ; clear port to set it as output 
				    ; this is done according to the datasheet --
    CALL    3FFh		    ; get CALL value to callibrate
    MOVWF   OSCCAL		    ; the 4 MHz internal oscillator ------------
    MOVLW   H'87'		    ; B'0000 0111', prescaler 1:256
    MOVWF   OPTION_REG	    
	; bit7 - rbpu (internal pull-ups), 0 enable, 1 disabled
	; bit6 - intedg, 0 falling edge, 1 raising edge
	; bit5 - tocs (tmr0 clock src), 0 - interal clock, 1 ra4/tockI bit src
	; bit4 - tose (tmr0 edge select), 0 inc low-to-high, 1 inc high-to-low
	; bit3 - psa (prescaler assing) 1 to WDT, 0 to timer0
	; bit2-0: value for timer0 prescaler --> 101 = 1:64,  **111 = 1:256**
	; 000 = 1:2, 010 = 1:8, 100 = 1:32, 110 = 1:128, 001 = 1:3, 011 = 1:16
	
;-------------------------------------------------------------------------------    
    Bank0			    ; go back bank 0
    MOVLW   (1<<GP0) | (1<<GP2)
    IORWF   GPIO		    ; set gp0 and gp2
    MOVLW   ~(1<<GP1) | ~(1<<GP4)
    ANDWF   GPIO		    ; clear gp1 and gp4
    CLRWDT			    ; clear watchdog timer
    MOVLW   OFFSET		    ; save offset value of 12
				    ; into TMR0, since 256-244=12
    MOVWF   TMR0		    ; clear timer0
    MOVLW   (1<<GIE) | (1<<T0IE)    ; enable bits 7 and 5
    MOVWF   INTCON		    ; same as sending H'A0' (B'1010 0000)
    MOVLW   D'16'		    ; total interrupt cycles for a 1 sec delay
    MOVWF   intCycl		    ; prepare register for decrementing in ISR
;*******************************************************************************
;   Main routine
;*******************************************************************************
MAIN
   
    GOTO    MAIN		    ; all the logic is in the ISR
;*******************************************************************************
;   Interrupt service routine 
;*******************************************************************************    
LED_ISR
    MOVWF   W_TEMP		    ; Copy W to TEMP register
    SWAPF   STATUS,W		    ; Swap status to be saved into W 
    CLRF    STATUS		    ; bank 0, regardless of current bank, 
				    ;it clears IRP,RP1,RP0
    MOVWF   STATUS_TEMP		    ;Save status to bank zero STATUS_TEMP reg
;------------------------------------------------------------------------------
    BTFSS   INTCON, T0IF	    ; check if flag has been set
    GOTO    exitISR		    ; if not, just leave ISR
    BCF	    INTCON, T0IF	    ; else, clear timer 0 flag
    MOVLW   OFFSET		    ; reload timer0 withe the offset of 12
    MOVWF   TMR0		    ; total interrupt cycles needed = 16
    DECFSZ  intCycl, F		    ; decrement variable till it is zero
    GOTO    exitISR		    ; and then skip this line to toggle leds
    MOVLW   H'17'		    ; b'00010111' -> gp0, gp1, gp2, gp4
    XORWF   GPIO		    ; toggle GPIO state
    MOVLW   D'16'		    ; reload total interrupt cycles value
    MOVWF   intCycl		    ; 
;------------------------------------------------------------------------------
exitISR    
    ; restore context
    SWAPF   STATUS_TEMP,W	    ;Swap STATUS_TEMP register into W 
				    ;(sets bank to original state)
    MOVWF   STATUS		    ;Move W into STATUS register
    SWAPF   W_TEMP,F		    ;Swap W_TEMP
    SWAPF   W_TEMP,W		    ;Swap W_TEMP into W reg
    
    RETFIE			   
;*******************************************************************************
;   End of PIC program
;*******************************************************************************    
    END
;*******************************************************************************    
