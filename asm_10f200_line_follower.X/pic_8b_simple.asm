;*******************************************************************************
; Line following robot, resource
;*******************************************************************************

#include "p10f200.inc"
	__CONFIG _WDT_OFF & _CP_OFF & _MCLRE_OFF
 
i   		 EQU 10   	 ;Delay register 1
j   		 EQU 11   	 ;Delay register 2
servo1   	 EQU 12   	 ;Servo1 pulse width
servo2   	 EQU 13   	 ;Servo2 pulse width
 
;*******************************************************************************
; Reset Vector
;*******************************************************************************
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; Start of program
;*******************************************************************************
MAIN_PROG CODE
	   		 
START
	MOVLW ~(1<<T0CS)
	OPTION   			 ;Enable GP2
	MOVLW ~((1 << GP0) | (1 << GP2))    
	TRIS GPIO   		 ;Set GP0 and GP2 as outputs
LOOP
    BTFSC GPIO, GP1   	 ;Check if GP1 is low (sensor is above the line)
    GOTO MOVE_RIGHT   	 ;If not then go to the MOVE_RIGHT label
MOVE_LEFT   			 ;Move the robot to the left
    MOVLW D'200'   	 ;Load the delay value for the servo 1
    MOVWF servo1   	 
    MOVLW D'215'   	 ;Load the delay value for the servo 2
    MOVWF servo2
    GOTO CONTROL_SERVO    ;Go to the CONTROL_SERVO label
MOVE_RIGHT   			 ;Move robot to the right
    MOVLW D'206'   	 ;Load the delay value for the servo 1
    MOVWF servo1
    MOVLW D'220'   	 ;Load the delay value for the servo 2
    MOVWF servo2
CONTROL_SERVO   		 ;Control the servo 1
    BSF GPIO, GP2   	 ;Set GP2 high
    MOVLW D'2'   		 ;Load 2 into the second delay register 'j'
    MOVWF j
    MOVF servo1, W   	 ;Copy the value of the servo1 into the W
    CALL DELAY   		 ;and call the delay
    BCF GPIO, GP2   	 ;Then seth GP2 low
    NOP   				;One cycle delay before the BSF instruction
SERVO_2   				 ;Control the servo 2
    BSF GPIO, GP0   	 ;Set GP0 high
    MOVLW D'2'   		 ;Load 2 into the second delay register 'j'
    MOVWF j    
    MOVF servo2, W   	 ;Copy the value of the servo2 into the W
    CALL DELAY   		 ;and call the delay
    BCF GPIO, GP0   	 ;Then seth GP0 low
PAUSE   				 ;Pause between the pulses
    MOVLW D'25'   		 ;Load 25 into the second delay register 'j'
    MOVWF j
    CALL DELAY   		 ;and call the delay
	GOTO LOOP   		 ;Return to the 'LOOP' label
 
DELAY   				 ;Start DELAY subroutine here
    MOVWF i   			 ;Load the W value into the 'i' register
DELAY_LOOP
    DECFSZ i, F   		 ;Decrement i and check if it is not zero
    GOTO DELAY_LOOP   	 ;If not, then go to the DELAY_LOOP label
    DECFSZ j, F   		 ;Decrement j and check if it is not zero
    GOTO DELAY_LOOP   	 ;If not, then go to the DELAY_LOOP label
    RETLW 0   			 ;Else return from the subroutine
 
	END