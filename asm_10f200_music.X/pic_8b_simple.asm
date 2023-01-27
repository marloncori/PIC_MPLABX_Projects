;===============================================================================
; Description:
; 	Sample program to play music by connecint a buzzer
;	to gp2. If you have an electromagnetic buzzer, you
;       need to wire it to the microcontroller via a transistor
; Source:
;  https://www.circuitbread.com/tutorials/musical-microcontroller-part-8-microcontroller-basics-pic10f200
;	
;===============================================================================    	 
	#include "p10f200.inc"

;===============================================================================
; Config BITS 
;===============================================================================    	 
	
	__CONFIG _WDT_OFF & _CP_OFF & _MCLRE_ON

;===============================================================================
; User defined registers 
;===============================================================================    	 	
d1   	    EQU   	 10   	 ;define 0x10 register as lower delay byte
d2   	    EQU   	 11   	 ;define 0x11 register as upper delay byte
periods     EQU   	 12   	 ;define 0x12 register as number of periods to play

;===============================================================================
; Reset vector 
;===============================================================================    	 
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    INIT                   ; go to beginning of program

;===============================================================================
;  Start of program
;===============================================================================    
MAIN_PROG CODE             

 INIT
    MOVLW  ~(1<<T0CS)         ;enable GPIO2
    OPTION   			 
    MOVLW ~(1 << GP2)          ;set GP2 as an output
    TRIS GPIO
;===============================================================================
;  Main routine
;===============================================================================    
LOOP
    CALL E2   			 ;Play note E of the 2nd octave
    CALL D#2   		             ;Play note D# of the 2nd octave
    CALL E2                              ;and so on and so forth
    CALL D#2
    CALL E2
    CALL H1
    CALL D2
    CALL C2
    CALL A1
    CALL A1
    CALL A1
    CALL C1
    CALL E1
    CALL A1
    CALL H1
    CALL H1
    CALL H1
    CALL E1
    CALL G#1
    CALL H1
    CALL C2
    CALL C2
    CALL C2
    SLEEP   			 ;Enable sleep mode
    GOTO LOOP     		 ;loop forever
    
;===============================================================================
;  Subroutines
;===============================================================================   
E2  				 ;Note E of the 2nd octave
    MOVLW D'255'   	         ;Load the number of periods to play
    MOVWF periods
LOOP_E2   			 ;Toggle pin GP2 with the specified frequency
    MOVLW (1<<GP2)   	 
    XORWF GPIO, F		 ;Toggle GP2
    MOVLW D'251'   	 
    MOVWF d1			 ;Load lower delay byte
    MOVLW 1   		 
    MOVWF d2			 ;Load upper delay byte
    CALL DELAY   		 ;Perform delay
    DECFSZ periods, F            ;Decrease the number of periods and check if it is 0
    GOTO LOOP_E2   	         ;If no then keep toggling GP2
    RETLW 0   			 ;Otherwise return from the subroutine
;------------------------------------------------------------------------------- 
 
D#2
    MOVLW D'240'
    MOVWF periods
LOOP_D#2
    MOVLW (1<<GP2)
    XORWF GPIO, F      	
    MOVLW D'10'
    MOVWF d1
    MOVLW 2
    MOVWF d2
    CALL DELAY
    DECFSZ periods, F
    GOTO LOOP_D#2
    RETLW 0
;------------------------------------------------------------------------------- 
 
H1
    MOVLW D'191'
    MOVWF periods
LOOP_H1
    MOVLW (1<<GP2)
    XORWF GPIO, F      	
    MOVLW D'80'
    MOVWF d1
    MOVLW 2
    MOVWF d2
    CALL DELAY
    DECFSZ periods, F
    GOTO LOOP_H1
    RETLW 0
;------------------------------------------------------------------------------- 
 
D2
    MOVLW D'227'
    MOVWF periods
LOOP_D2
    MOVLW (1<<GP2)
    XORWF GPIO, F      	
    MOVLW D'26'
    MOVWF d1
    MOVLW 2
    MOVWF d2
    CALL DELAY
    DECFSZ periods, F
    GOTO LOOP_D2
    RETLW 0
;------------------------------------------------------------------------------- 
 
C2
    MOVLW D'202'
    MOVWF periods
LOOP_C2
    MOVLW (1<<GP2)
    XORWF GPIO, F      	
    MOVLW D'61'
    MOVWF d1
    MOVLW 2
    MOVWF d2
    CALL DELAY
    DECFSZ periods, F
    GOTO LOOP_C2
    RETLW 0
;------------------------------------------------------------------------------- 
 
A1
    MOVLW D'170'
    MOVWF periods
LOOP_A1
    MOVLW (1<<GP2)
    XORWF GPIO, F      	 
    MOVLW D'121'
    MOVWF d1
    MOVLW 2
    MOVWF d2
    CALL DELAY
    DECFSZ periods, F
    GOTO LOOP_A1
    RETLW 0
;------------------------------------------------------------------------------- 
 
C1
    MOVLW D'101'
    MOVWF periods
LOOP_C1
    MOVLW (1<<GP2)
    XORWF GPIO, F      	 
    MOVLW D'123'
    MOVWF d1
    MOVLW 3
    MOVWF d2
    CALL DELAY
    DECFSZ periods, F
    GOTO LOOP_C1
    RETLW 0
;------------------------------------------------------------------------------- 
 
E1
    MOVLW D'127'
    MOVWF periods
LOOP_E1
    MOVLW (1<<GP2)
    XORWF GPIO, F      	 
    MOVLW D'248'
    MOVWF d1
    MOVLW 2
    MOVWF d2
    CALL DELAY
    DECFSZ periods, F
    GOTO LOOP_E1
    RETLW 0
;------------------------------------------------------------------------------- 
 
G#1
    MOVLW D'160'
    MOVWF periods
LOOP_G#1
    MOVLW (1<<GP2)
    XORWF GPIO, F      	 
    MOVLW D'144'
    MOVWF d1
    MOVLW 2
    MOVWF d2
    CALL DELAY
    DECFSZ periods, F
    GOTO LOOP_G#1
    RETLW 0
;------------------------------------------------------------------------------- 
DELAY   			 ;Start DELAY subroutine here
    DECFSZ d1, F   	             ;Decrement the register 0x10 and check if not zero
    GOTO DELAY   		 ;If not then go to the DELAY_LOOP label
    DECFSZ d2, F   	             ;Else decrement the register 0x11, check if it is not 0
    GOTO DELAY   		 ;If not then go to the DELAY_LOOP label
    RETLW 0   			 ;Else return from the subroutine
;===============================================================================
;  end of program
;===============================================================================    
    END
;------------------------------------------------------------------------------- 
    