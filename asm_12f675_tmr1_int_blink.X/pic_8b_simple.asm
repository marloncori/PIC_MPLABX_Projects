
;=================================================================
; Description
;    
;           Program to blink led using a precisely calculated
;       one second delay. Internal 4MHz oscillator is used,
;       with a prescaler 1, max count will be 65536, the cycle
;       counter will be 400 for a 0.00250 sec overflow time and
;       the TMR1 value is 55536 (0xD8F0). 
;    
;          If the overflow time is 0.00125 with the prescaler 1
;       the control variable counter will be 800 and the value
;       to be load in TMR1 is 60536 (0xEC78).      
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
; Global variables
CBLOCK		 H'20'   ; Start of memory block
    intCycl		            ; total cycles of interrupt to
                                    ; achieve desired delay time
    intCycl2				    
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
    BSF	    PIE1, TMR1IE	    ; enables timer 1 interruption
    	
;-------------------------------------------------------------------------------    
    Bank0			    ; go back bank 0
    MOVLW   (1<<GP1) | (1<<GP4)
    IORWF   GPIO		    ; set gp1 and gp4
    MOVLW   ~(1<<GP0) | ~(1<<GP2) ~(1<<GP5)
    ANDWF   GPIO		    ; clear gp0, gp1 and gp5
    CLRWDT			    ; clear watchdog timer
    MOVLW   H'C0'		    ; send value b1100 0000 to INTCON
    MOVWF   INTCON		    ; set GIE and PEIE bits for global
    MOVLW   H'01'		    ; and peripheral interrupt enabling
    MOVWF   T1CON		    ; enable timer 1 at T1CON reg, psa 1:1
    
    MOVLW   H'D8'		    ; timer1 will be initilized with 55536
    MOVWF   TMR1H		    ; initialize MSB of timer1
    MOVLW   H'F0'		    ; timer1 will be initilized with 55536
    MOVWF   TMR1L		    ; initialize LSB of timer1
   
    MOVLW   D'400'		    ; total interrupt cycles for a 1 sec delay
    MOVWF   intCycl		    ; prepare register for decrementing in ISR
    
    MOVLW   D'800'		    ; total interrupt cycles for a 2 sec delay
    MOVWF   intCycl2		    ; prepare register for decrementing in ISR
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
    BTFSS   PIR1, TMR1IF	    ; if it equals 1, it skips next line
    GOTO    exitISR		    ; if not, just leave ISR
    
    BCF	    PIR1, TMR1IF	    ; else, clear timer 0 flag
    MOVLW   H'D8'		    ; timer1 will be initilized with 55536
    MOVWF   TMR1H		    ; initialize MSB of timer1
    MOVLW   H'F0'		    ; timer1 will be initilized with 15536
    MOVWF   TMR1L		    ; initialize LSB of timer1

    DECFSZ  intCycl, F		    ; decrement variable till it is zero
    GOTO    L1			    ; and then skip this line to toggle leds
    MOVLW   H'30'		    ; b'00110000' -> gp4, gp5
    XORWF   GPIO		    ; toggle GPIO state
    MOVLW   D'400'		    ; reload total interrupt cycles value 1
    MOVWF   intCycl		    ; 
    
L1: DECFSZ  intCycl2, F		    ; decrement variable till it is zero
    GOTO    exitISR		    ; and then skip this line to toggle leds
    MOVLW   H'07'		    ; b'0000 0111' -> gp0, gp1, gp2
    XORWF   GPIO		    ; toggle GPIO state
    MOVLW   D'800'		    ; reload total interrupt cycles value 2
    MOVWF   intCycl2		    ; 
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
