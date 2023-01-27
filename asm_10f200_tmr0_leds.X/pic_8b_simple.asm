;*******************************************************************************
; TODO INSERT INCLUDE CODE HERE
#include "p10f200.inc"
#define  OFFSET	 H'0C'    
    
; __config 0xFFEB
 __CONFIG _WDTE_OFF & _CP_OFF & _MCLRE_OFF
;*******************************************************************************
; TODO PLACE VARIABLE DEFINITIONS
countCycl   EQU   H'10'
maxCount    EQU   H'11'

;*******************************************************************************
; Reset Vector
;*******************************************************************************
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************
MAIN_PROG CODE                      ; let linker place main program

START				    ; set TMR0 as timer, rising edge
    MOVLW   ~((1<<T0CS) | (1<<T0SE) | (1<<PSA))
    OPTION			    ; assign prescaler to timer0	
    ;----------------------------------------------------------------    
    MOVLW   (1<<PS2) | (1<<PS1) | (1<<PS0)   
    OPTION			    ; prescaler 1:256
    ;----------------------------------------------------------------    
    MOVLW   ~((1<<GP0) | (1<<GP1)|(1<<GP2))   ; set GP0 and GP2 also as output
    TRIS    GPIO
    ;----------------------------------------------------------------    
    MOVLW   ~(1<<GP1) ; clear GP1 and GP3 pins
    ANDWF    GPIO
    ;----------------------------------------------------------------    
    MOVLW   (1<<GP0) | (1<<GP2)     ; set GP0 and GP2 pins
    IORWF   GPIO
    ;----------------------------------------------------------------        
    MOVLW   H'F4'		    ; save 244
    MOVWF   maxCount		    ; into temporary register
    ;----------------------------------------------------------------    
    CLRWDT			    ; clear watchdog timer
    
;===============================================================================
;  Main program
;===============================================================================
LOOP
    CALL    TOGGLE
    CALL    TMR0_DELAY		    ; wait for one second
    CALL    TOGGLE
    CALL    TMR0_DELAY_2sec	    ; wait for one second
    GOTO    LOOP                    ; repeat procedure

;==============================================================================
;  Subroutines
;==============================================================================
TOGGLE
    MOVLW   H'0F'		    ; mask 0000 1111
    XORWF   GPIO		    ; toggle led state on GPIO
    RETURN
    
;==============================================================================
;  TMR0 Subroutine
;==============================================================================
TMR0_DELAY
    MOVLW   OFFSET		    ; Yes, so copy offset value of 12
				    ; again into TMR0, since 256-244=12
    MOVWF   TMR0		    ; tmr0 is ready for new couting cycle
    MOVLW    D'16'		    ; total interrupt cycles for a 1 sec delay
    MOVWF   countCycl		    ; prepare register for decrementing in ISR
WAIT
    MOVF    TMR0,W		    ; read timer0 value, store it in W
    SUBWF   maxCount		    ; subtract W from 244	
    BTFSS   STATUS,Z		    ; Is zero set? 
    GOTO    WAIT		    ; No, because W - 244 != 0
   
    MOVLW   OFFSET		    ; Yes, so copy offset value of 12
				    ; again into TMR0, since 256-244=12
    MOVWF   TMR0		    ; tmr0 is ready for new couting cycle
    DECFSZ  countCycl,F		    ; the variable has the value 16
    GOTO    WAIT		    ; for the number of cycles till the
    MOVLW    D'16'		    ; total interrupt cycles for a 1 sec delay
    MOVWF   countCycl		    ; prepare register for decrementing in ISR

    RETURN			    ; delay function reaches 1 second
;-------------------------------------------------------------------------------
TMR0_DELAY_2sec
    MOVLW   OFFSET		    ; Yes, so copy offset value of 12
				    ; again into TMR0, since 256-244=12
    MOVWF   TMR0		    ; tmr0 is ready for new couting cycle
    MOVLW    D'32'		    ; total interrupt cycles for a 1 sec delay
    MOVWF   countCycl		    ; prepare register for decrementing in ISR
WAIT2
    MOVF    TMR0,W		    ; read timer0 value, store it in W
    SUBWF   maxCount		    ; subtract W from 244	
    BTFSS   STATUS,Z		    ; Is zero set? 
    GOTO    WAIT2		    ; No, because W - 244 != 0
   
    MOVLW   OFFSET		    ; Yes, so copy offset value of 12
				    ; again into TMR0, since 256-244=12
    MOVWF   TMR0		    ; tmr0 is ready for new couting cycle
    DECFSZ  countCycl,F		    ; the variable has the value 16
    GOTO    WAIT2		    ; for the number of cycles till the
    MOVLW    D'32'		    ; total interrupt cycles for a 1 sec delay
    MOVWF   countCycl		    ; prepare register for decrementing in ISR

    RETURN			    ; delay function reaches 1 second
    
;*******************************************************************************
    END
;*******************************************************************************    