#include "p10f200.inc"
	__CONFIG _WDT_OFF & _CP_OFF & _MCLRE_OFF
 
i   		 EQU 10   	 ;Delay register
rx_data 	 EQU 12   	 ;Received byte
count   	 EQU 13   	 ;Bit counter for UART communication
servo1   	 EQU 14   	 ;Servo1 pulse width
servo2   	 EQU 15   	 ;Servo2 pulse width
 
    ORG 0x0000   		 
INIT
    MOVLW ~((1<<T0CS)|(1<<PSA)|(1<<PS0))
    OPTION      		 ;Enable GP2, assign prescaler to Timer, set prescaler 128
    MOVLW ~((1 << GP0) | (1 << GP2))    
    TRIS GPIO   		 ;Set GP0 and GP2 as outputs
    CLRF servo1   		 ;Clear 'servo1' to stop servo 1
    CLRF servo2   		 ;Clear 'servo2' to stop servo 2
LOOP
    BTFSC servo1, 3   	              ;If servo 1 is not stopped
    CALL CONTROL_SERVO   ;then set the pulse width for the servos
WAIT_RX
    BTFSS GPIO, GP1               ;Check the GP1 level, if 1 then skip next line
    CALL RX_BYTE   	              ;Otherwise receive the byte
    GOTO LOOP   		 ;Return to the 'LOOP' label
;-----------------------------------------------------------------
CONTROL_SERVO   		 ;CONTROL_SERVO subroutine
    MOVF TMR0, W   	 ;Copy the TMR0 register into W
    BTFSS STATUS, Z   	 ;Check if it is 0 using Z bit of STATUS register
    GOTO SET_PULSE   	 ;If TMR0 is not 0 then move to SET_PULSE label
    BSF GPIO, GP0   	 ;Otherwise set GP0 high
    NOP
    BSF GPIO, GP2   	 ;and set GP2 high
SET_PULSE   	 
    MOVF servo1, W   	 ;Copy 'servo1' into W
    XORWF TMR0, W   	 ;Compare it with TMR0 value
    BTFSC STATUS, Z   	 ;If 'servo1' = TMR0
    BCF GPIO, GP0   	 ;Then set GP0 low
    MOVF servo2, W   	 ;Copy 'servo2' into W
    XORWF TMR0, W   	 ;Compare it with TMR0 value
    BTFSC STATUS, Z   	 ;If 'servo2' = TMR0
    BCF GPIO, GP2   	 ;Then set GP2 low
    RETLW 0
;-----------------------------------------------------------------
RX_BYTE   				 ;Beginning of the RX_BYTE subroutine
    MOVLW ~((1<<GP0)|(1<<GP2));Set servo outputs low
    MOVWF GPIO   		 ;to prevent the prolonged pulse
    CALL HALF_UART_DELAY;Delay to the middle of the bit interval
    BTFSC GPIO, GP1   	 ;If the GP1 bit is not 0
    RETLW 0   			 ;then error of the Start bit, and return
    CLRF count   		 ;Else clear 'count' register
    CLRF rx_data   	 ;and clear 'rx_data' register
SHIFT_RX_DATA   		 ;Start receiving the data byte
    CALL UART_DELAY     ;Call one bit delay
    RRF rx_data, F   	 ;Shift the 'rx_data' one bit to the right
    BTFSC GPIO,GP1   	 ;If GP1 bit is 1
    BSF rx_data, 7   	 ;then set the MSB of the 'rx_data' to 1
    INCF count, F   	 ;Increment the counter
    BTFSS count, 3   	 ;and check if it is 8
    GOTO SHIFT_RX_DATA    ;If it is not then return to the 'SHIFT_RX_DATA'
    CALL UART_DELAY     ;Otherwise call one bit delay
    BTFSS GPIO, GP1   	 ;And check the stop bit
    RETLW 0   			 ;if the GP1 is not 1 then return
CHECK_LEFT   			 ;Check Left button
    MOVLW '1'   		 ;Load the '1' into the W register
    XORWF rx_data, W    ;And perform the XOR between W and 'rx_data'
    BTFSS STATUS, Z   	 ;If result is not 0 (rx_data != W)
    GOTO CHECK_FWD   	 ;then check the next button
    MOVLW D'10'   		 ;Otherwise load value 10
    MOVWF servo1   	 ;into both 'servo1'
    MOVWF servo2   	 ;and 'servo2'
    RETLW 0
CHECK_FWD   			 ;Check Forward button
    MOVLW '2'   		 ;Load the '2' into the W register
    XORWF rx_data, W    ;And perform the XOR between W and 'rx_data'
    BTFSS STATUS, Z   	 ;If result is not 0 (rx_data != W)
    GOTO CHECK_RIGHT    ;then check the next button
    MOVLW D'10'   		 ;Otherwise load vakue 10
    MOVWF servo1   	 ;into 'servo1'
    MOVLW D'12'   		 ;and load value 12
    MOVWF servo2   	 ;into 'servo2'
    RETLW 0
CHECK_RIGHT   			 ;Check Right button
    MOVLW '3'   		 ;Load the '3' into the W register
    XORWF rx_data, W    ;And perform the XOR between W and 'rx_data'
    BTFSS STATUS, Z   	 ;If result is not 0 (rx_data != W)
    GOTO CHECK_BKWD   	 ;then check the next button
    MOVLW D'12'   		 ;Otherwise load value 12
    MOVWF servo1   	 ;into both 'servo1'
    MOVWF servo2   	 ;and 'servo2'
    RETLW 0
CHECK_BKWD   			 ;Check Backward button
    MOVLW '4'   		 ;Load the '4' into the W register
    XORWF rx_data, W    ;And perform the XOR between W and 'rx_data'
    BTFSS STATUS, Z   	 ;If result is not 0 (rx_data != W)
    GOTO CHECK_STOP   	 ;then check the next button
    MOVLW D'12'   		 ;Otherwise load value 12
    MOVWF servo1   	 ;into 'servo1'
    MOVLW D'10'   		 ;and load value 10
    MOVWF servo2   	 ;into 'servo2'
    RETLW 0
CHECK_STOP   			 ;Check Stop button
    MOVLW '9'   		 ;Load the '9' into the W register
    XORWF rx_data, W    ;And perform the XOR between W and 'rx_data'
    BTFSS STATUS, Z   	 ;If result is not 0 (rx_data != W)
    RETLW 0   			 ;then return from the subroutine
    CLRF servo1   		 ;Otherwise clear 'servo1'
    CLRF servo2   		 ;and clear 'servo2'
    RETLW 0
;--------------------------------------------------------------
UART_DELAY  	     	 ;Start UART_DELAY subroutine here
	MOVLW D'29'  		 ;Load initial value for the delay    
	MOVWF i  			 ;Copy the value to the register i
DELAY_LOOP_UART   	      ;Start delay loop
	DECFSZ i, F  		 ;Decrement i and check if it is not zero
	GOTO DELAY_LOOP_UART;If not, go to the DELAY_LOOP_UART label
	RETLW 0  			 ;Else return from the subroutine
 
HALF_UART_DELAY 		 ;Start HALF_UART_DELAY subroutine here
	MOVLW D'16'  		 ;Load initial value for the delay    
	MOVWF i  			 ;Copy the value to the register i
DELAY_LOOP_HALF   	      ;Start delay loop
	DECFSZ i, F  		 ;Decrement i and check if it is not zero
	GOTO DELAY_LOOP_HALF;If not, go to the DELAY_LOOP_HALF label
	RETLW 0  			 ;Else return from the subroutine
 
	END