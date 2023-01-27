;*******************************************************************************
; TODO INSERT INCLUDE CODE HERE
#include "p10f200.inc"
#define  OFFSET	 H'0C'    
    
; __config 0xFFEB
 __CONFIG _WDTE_OFF & _CP_OFF & _MCLRE_OFF
;*******************************************************************************
; TODO PLACE VARIABLE DEFINITIONS GO HERE
CBLOCK	    H'10'
   i
   limit
   j
   dir
ENDC
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; TODO Step #4 - Interrupt
;*******************************************************************************
; TODO INSERT ISR HERE
     ISR       CODE    0x0004
       RETFIE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************
MAIN_PROG CODE                      ; let linker place main program

START				    
    MOVLW   ~(1<<GP1)		    ; set GP1 as an output
    TRIS    GPIO
    CLRF    limit		    ; prepare PWM limit register
    
;===============================================================================
;  Main program
;===============================================================================
LOOP
    MOVLW   H'FF'		    ; set initial value of i
    MOVWF   i			    ; as 255
    BSF	    GPIO, GP1		    ; set gp1 high
L1
    MOVF    limit, W		    ; copy PWM limit into W
    SUBWF   i, W		    ; subtract it from i
    BTFSS   STATUS, Z		    ; if result is not zero	
    GOTO    $ +2		    ; then go down 2 lines (DELAY)
    BCF	    GPIO, GP1		    ; set gp1 low
    CALL    DELAY		    ; wait some time
    DECFSZ  i, F		    ; decrement i variable
    GOTO    L1			    ; go to this label if not zero
    BTFSS   dir, 0
    GOTO    DEC_BRIGHTNESS
    DECFSZ  limit, F		    ; or else, decrement limit
    GOTO    LOOP                    ; and skipt this if it is zero
    GOTO    TOGGLE_DIR
;==============================================================================
DEC_BRIGHTNESS
    INCF    limit, F		    ; increment limit variable
    MOVLW   H'FF'		    ; load 255 into W
    SUBWF   limit, W		    ; subtract value from W
    BTFSS   STATUS, Z		    ; if zero flag is not set
    GOTO    LOOP		    ; go back to LOOP routine
    
;------------------------------------------------------------------------------    
TOGGLE_DIR
    BTFSS   dir, 0		    ; check whether variable is set
    GOTO    SET_DIR
    BCF	    dir, 0
    GOTO    LOOP


;------------------------------------------------------------------------------    
SET_DIR    
    BSF	    dir, 0
    GOTO    LOOP
    
;==============================================================================
;  Subroutines
;==============================================================================

DELAY
    MOVLW    H'10'		    ; movlw and movwf both take 1 cycle
    MOVWF    j                      ; goto and retlw take 2 cycles   
L2
    DECFSZ   j, F
    GOTO     L2
    
    RETLW   0
   
;*******************************************************************************
    END
;******************************************************************************* 