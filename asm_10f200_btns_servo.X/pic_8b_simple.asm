;*******************************************************************************
; Control servo with a button. 
;    Three buttons are used to lock and unlock the system.
;    
; source:
;  https://www.circuitbread.com/tutorials/servo-motor-indirect-addressing-and-electronic-lock---part-10-microcontroller-basics-pic10f200    
;*******************************************************************************
    #include "p10f200.inc"
    __CONFIG _WDT_OFF & _CP_OFF & _MCLRE_OFF

;*******************************************************************************
; Constant and variables
;*******************************************************************************    
code_value     EQU    b'01011110'  ;code 2 3 1 1
                                   ; 01 01 11 10
                                   ;  1  1  3  2
;------------------------------------------------------------------------------ 
i            EQU    10     ;Delay register 1
j            EQU    11     ;Delay register 2
lock_state   EQU    12     ;Lock state: 3 - closed, 2 - opened
count        EQU    13     ;Counter of the pressed buttons
code_reg     EQU    14     ;Register for code
servo_steps  EQU    15     ;Number of pulses for servo to change position
num1         EQU    16     ;First number register
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
    MOVLW ~((1<<T0CS)|(1<<NOT_GPPU))
    OPTION                 ;Enable GPIO2 and pull-ups
    MOVLW ~(1 << GP2)    
    TRIS GPIO              ;Set GP2 as output
    MOVLW 3                
    MOVWF lock_state       ;Set lock state as "closed"
    GOTO LOCK_CLOSE        ;and close the lock
    
;*******************************************************************************
; Main routine
;*******************************************************************************    
LOOP
 
    CALL INIT_REGS         ;Initialize the registers values
;-------------------------------------------------------------------------------    
READ_BUTTONS               ;Here the "read buttons" part starts
    CALL CHECK_BUTTONS   ;Read the buttons state
    ANDLW 3                ;Clear all the bits of the result except two LSBs
    BTFSC STATUS, Z        ;If result is 0 (none of buttons were pressed)
    GOTO READ_BUTTONS   ;then return to the READ_BUTTONS label
    MOVLW D'40'            ;Otherwise load initial value for the delay
    CALL DELAY         ;and perform the debounce delay
    CALL CHECK_BUTTONS  ;Then check the buttons state again
    ANDLW 3
    BTFSC STATUS, Z
    GOTO READ_BUTTONS    ;If button is still pressed
    MOVWF INDF         ;Then save the button code in the INDF register
    CALL CHECK_BUTTONS   ;and keep checking the buttons state
    ANDLW 3
    BTFSS STATUS, Z
    GOTO $-3           ;until it becomes 0
    MOVLW D'40'            ;Perform the debounce delay again
    CALL DELAY         
    BTFSS lock_state, 0            ;If the last bit of the lock_state is 0(lock is opened)
    GOTO LOCK_CLOSE        ;then close the lock (with any button)
    INCF FSR, F            ;otherwise increment the indirect address,
    DECFSZ count, F        ;decrement the button press counter,check if it is 0
    GOTO READ_BUTTONS    ;If it is not, then return to the READ_BUTTONS
 
    CALL INIT_REGS     ;otherwise initialize registers again
;-------------------------------------------------------------------------------    
CHECK_CODE         ;and start checking the code
    MOVF code_reg, W             ;Copy the code value into the W
    ANDLW 3                ;and clear all the bits of W except of the two LSBs
    SUBWF INDF, W                  ;Subtract W from the indirectly addressed register
    BTFSS STATUS, Z        ;If result is not 0 (code is not correct)
    GOTO LOOP          ;then return to the LOOP label
    RRF code_reg, F                    ;otherwise shift the code register right
    RRF code_reg, F                    ;two times
    INCF FSR, F            ;Increment the the indirect address
    DECFSZ count, F        ;Decrement the counter and check if it is 0
    GOTO CHECK_CODE        ;If it is not, then check the next code value
;------------------------------------------------------------------------------- 
LOCK_OPEN          ;otherwise open the lock
    BCF lock_state, 0                ;Clear the LSB of the lock_state
    CALL MANIPULATE_SERVO;and manipulate the servo to open the lock
    GOTO LOOP          ;Then return to the LOOP label
;------------------------------------------------------------------------------- 
LOCK_CLOSE         ;Code part to close the lock
    BSF lock_state, 0                ;Set the LSB of the lock state
    CALL MANIPULATE_SERVO;and manipulate the servo to open the lock
    GOTO LOOP          ;Then return to the LOOP label
 
;----------------Subroutines----------------------------------------
INIT_REGS              ;Initialize the  registers
    MOVLW num1         ;Copy the num1 register address to the
    MOVWF FSR          ;indirect address pointer
    MOVLW 4                ;Set count as 4 wait for 4 buttons presses
    MOVWF count
    MOVLW code_value            ;Copy code_value
    MOVWF code_reg     ;into the code_reg register
    RETLW 0                ;Return from the subroutine
;------------------------------------------------------------------------------- 
CHECK_BUTTONS
    BTFSS GPIO, GP3        ;Check if GP3 is 0 (SW1 is pressed)    
    RETLW 1                ;and return 1 (b'01')
    BTFSS GPIO, GP0        ;Check if GP0 is 0 (SW2 is pressed)    
    RETLW 2                ;and return 2 (b'10')
    BTFSS GPIO, GP1        ;Check if GP1 is 0 (SW3 is pressed)    
    RETLW 3                ;and return 3 (b'11')
    RETLW 0                ;If none of the buttons are pressed then return 0
;------------------------------------------------------------------------------- 
DELAY              ;Start DELAY subroutine here    
    MOVWF i                ;Copy the W value to the register i
    MOVWF j                ;Copy the W value to the register j
DELAY_LOOP         ;Start delay loop
    DECFSZ i, F            ;Decrement i and check if it is not zero
    GOTO DELAY_LOOP        ;If not, then go to the DELAY_LOOP label
    DECFSZ j, F            ;Decrement j and check if it is not zero
    GOTO DELAY_LOOP        ;If not, then go to the DELAY_LOOP label
    RETLW 0                ;Else return from the subroutine
;------------------------------------------------------------------------------- 
MANIPULATE_SERVO       ;Manipulate servo subroutine
    MOVLW D'20'            ;Copy 20 to the servo_steps register
    MOVWF servo_steps          ;to repeat the servo move condition 20 times
SERVO_MOVE            ;Here servo move condition starts
    BSF GPIO, GP2                  ;Set the GP2 pin to apply voltage to the servo
    MOVF lock_state, W            ;Load initial value for the delay
    CALL DELAY         ;(2 to open the lock, 3 to close it)
    BCF GPIO, GP2                  ;Reset GP2 pin to remove voltage from the servo
    MOVLW D'25'            ;Load initial value for the delay
    CALL DELAY         ;(normal delay of about 20 ms)
    DECFSZ servo_steps, F     ;Decrease the servo steps counter, check if it is 0
    GOTO SERVO_MOVE        ;If not, keep moving servo
    RETLW 0                ;otherwise return from the subroutine
    
;*******************************************************************************
;  end of program
;******************************************************************************* 
    END
    