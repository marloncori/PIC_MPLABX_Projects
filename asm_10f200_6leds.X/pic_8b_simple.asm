;===============================================================================
; INCLUDE and CONFIG CODE 
;===============================================================================    
#include "p10f200.inc"
    
; __config 0xFFEB
 __CONFIG _WDTE_OFF & _CP_OFF & _MCLRE_OFF

;===============================================================================
; Variable definition 
;===============================================================================    
i   	 EQU   	 H'10' 	 	;define 0x10 register as the delay variable
j   	 EQU   	 H'11' 	 	;define 0x11 register as the delay variable
k   	 EQU   	 H'12' 	 	;define 0x12 register as the delay variable
led   	 EQU   	 H'13' 	 	;define 0x13 register as the LED number

;===============================================================================
; Reset vector 
;===============================================================================    	 
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    INIT                   ; go to beginning of program

;===============================================================================
;  Start of program
;===============================================================================    
MAIN_PROG CODE                      ; let linker place main program

INIT
    MOVLW  ~(1<<T0CS) 	 	;Enable GPIO2
    OPTION    
    MOVLW ((1 << GP0)|(1 << GP1)|(1 << GP2));set GP0, GP1, GP2 as inputs
    TRIS GPIO
    
;===============================================================================
;  Main routine
;===============================================================================    
LOOP
    MOVLW 1   			 ;Light up LED1
    CALL LIGHT_LED
    MOVLW 2   			 ;Light up LED2
    CALL LIGHT_LED
    MOVLW 3   			 ;Light up LED3
    CALL LIGHT_LED
    MOVLW 4   			 ;Light up LED4
    CALL LIGHT_LED
    MOVLW 5   			 ;Light up LED5
    CALL LIGHT_LED
    MOVLW 6   			 ;Light up LED6
    CALL LIGHT_LED
    MOVLW 5   			 ;Light up LED5
    CALL LIGHT_LED
    MOVLW 4   			 ;Light up LED4
    CALL LIGHT_LED
    MOVLW 3   			 ;Light up LED3
    CALL LIGHT_LED
    MOVLW 2   			 ;Light up LED2
    CALL LIGHT_LED
    GOTO LOOP     		 ;loop forever
    
;===============================================================================
;  Subroutines
;===============================================================================    
DELAY   			 ;Start DELAY subroutine here
    MOVLW 2   			 ;Load initial value for the delay    
    MOVWF i   			 ;Copy the value to the register 0x10
    MOVWF j   			 ;Copy the value to the register 0x11
    MOVWF k   			 ;Copy the value to the register 0x12
;------------------------------------------------------------------------------    
DELAY_LOOP   		         ;Start delay loop
    DECFSZ i, F   		 ;Decrement the register i and check if not zero
    GOTO DELAY_LOOP   	         ;If not then go to the DELAY_LOOP label
    DECFSZ j, F   		 ;Else decrement the register j, check if it is not 0
    GOTO DELAY_LOOP       	 ;If not then go to the DELAY_LOOP label
    DECFSZ k, F   		 ;Else decrement the register k, check if it is not 0
    GOTO DELAY_LOOP   	         ;If not then go to the DELAY_LOOP label
    RETLW 0   			 ;Else return from the subroutine
;------------------------------------------------------------------------------ 
SELECT_LED   		         ;Turn on LED1
    DECFSZ led, F   	         ;Decrement the register 'led' and check if not zero
    GOTO LED2   		 ;If not then go to the LED2 label    
    MOVLW ~((1 << GP0)|(1 << GP1))
    TRIS GPIO   		 ;Otherwise set GP0 and GP1 as outputs
    MOVLW 1 << GP0   	         ;Set GP0 pin as output high
    MOVWF GPIO
    RETLW 0   			 ;and return from the subroutine
;------------------------------------------------------------------------------    
LED2
    DECFSZ led, F   	             ;Decrement the register 'led' and check if not zero
    GOTO LED3   		 ;If not then go to the LED3 label    
    MOVLW ~((1 << GP0)|(1 << GP1))
    TRIS GPIO   		 ;Otherwise set GP0 and GP1 as outputs
    MOVLW 1 << GP1   	         ;Set GP1 pin as output high    
    MOVWF GPIO
    RETLW 0   			 ;and return from the subroutine
;------------------------------------------------------------------------------    
LED3
    DECFSZ led, F   	             ;Decrement the register 'led' and check if not zero
    GOTO LED4   		 ;If not then go to the LED4 label    
    MOVLW ~((1 << GP1)|(1 << GP2))
    TRIS GPIO   		 ;Otherwise set GP1 and GP2 as outputs
    MOVLW 1 << GP1   	 	 ;Set GP1 pin as output high
    MOVWF GPIO
    RETLW 0   			 ;and return from the subroutine
;------------------------------------------------------------------------------    
LED4
    DECFSZ led, F   	             ;Decrement the register 'led' and check if not zero
    GOTO LED5   		 ;If not then go to the LED5 label    
    MOVLW ~((1 << GP1)|(1 << GP2))
    TRIS GPIO   		 ;Otherwise set GP1 and GP2 as outputs
    MOVLW 1 << GP2   	 	 ;Set GP2 pin as output high
    MOVWF GPIO
    RETLW 0   			 ;and return from the subroutine
;------------------------------------------------------------------------------    
LED5
    DECFSZ led, F   	             ;Decrement the register 'led' and check if not zero
    GOTO LED6   		 ;If not then go to the LED6 label    
    MOVLW ~((1 << GP0)|(1 << GP2))
    TRIS GPIO   		 ;Otherwise set GP0 and GP2 as outputs
    MOVLW 1 << GP0   	 	;Set GP0 pin as output high
    MOVWF GPIO
    RETLW 0   			 ;and return from the subroutine
;------------------------------------------------------------------------------    
LED6
    DECFSZ led, F   	             ;Decrement the register 'led' and check if not zero
    RETLW 0   			 ;If not return from the subroutine    
    MOVLW ~((1 << GP0)|(1 << GP2))
    TRIS GPIO   		 ;Otherwise set GP0 and GP2 as outputs
    MOVLW 1 << GP2   	 	;Set GP2 pin as output high
    MOVWF GPIO
    RETLW 0   			 ;and return from the subroutine
 ;------------------------------------------------------------------------------
LIGHT_LED   			 ;Light one LED and perform delay
    MOVWF led   		 ;Copy the content of the W into 'led' register
    CALL SELECT_LED   	 	;Call SELECT_LED subroutine
    CALL DELAY   		 ;Call DELAY subroutine
    RETLW 0   			 ;Return from the subroutine
;===============================================================================
;   end of application
;===============================================================================    
    END   
;-------------------------------------------------------------------------------    