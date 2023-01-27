;*******************************************************************************
; TODO INSERT INCLUDE CODE HERE
#include "p10f200.inc"
    
; __config 0xFFEB
 __CONFIG _WDTE_OFF & _CP_OFF & _MCLRE_OFF
;*******************************************************************************
; TODO PLACE VARIABLE DEFINITIONS GO HERE
CBLOCK	    H'10'
   count1
   count2
   count3
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
    MOVLW   ~(1<<T0CS)		    ; enable GPIO2
    OPTION
    MOVLW   ~(1<<GP2)		    ; set GPIO2 as an output
    TRIS    GPIO
;===============================================================================    
LOOP    
    BSF	    GPIO, GP2		    ; turn led on
    CALL    DELAY		    ; wait
    BCF	    GPIO, GP2		    ; turn led off
    CALL    DELAY		    ; wait
    GOTO    LOOP                    ; loop forever
;===============================================================================
;  Subroutines
;===============================================================================
DELAY
    MOVLW   D'255'
    MOVWF   count1
    NOP
iloop
    MOVLW   D'100'
    MOVWF   count2
    NOP
jloop
    MOVLW   D'50'
    MOVWF   count3
    NOP
kloop
    DECFSZ  count3
    GOTO    kloop
    DECFSZ  count2
    GOTO    jloop
    DECFSZ  count1
    GOTO    iloop
    RETURN
;*******************************************************************************
    END
;*******************************************************************************    