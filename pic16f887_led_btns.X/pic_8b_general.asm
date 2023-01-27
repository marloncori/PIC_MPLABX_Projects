
;*******************************************************************************
#include "p16f887.inc"

; CONFIG1
; __config 0xE0D2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
 
; TODO PLACE VARIABLE DEFINITIONS GO HERE
 #define BANK0	BCF STATUS,RP0
 #define BANK1	BSF STATUS,RP0
 #define BUTTON	PORTB,RB0
 
;******************************************************************************
  cblock	H'20'	; REGISTRADORES DE USO GERAL, 'VARIAVEIS
			; INICIO DO REGISTRADOR
    J			; counter used in delay routine
    K			; counter used in delay routine
    OLD_W		; context saving storage
    OLD_STATUS		; context saving storage
    COUNT1		; auxiliary counter
    COUNT2		; ISR counter
    BITS_B47		; storage for previous value in portB, bits 4-7
    READING		; temporary storage
  endc
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; TODO Step #4 - Interrupt Service Routines
;
; There are a few different ways to structure interrupt routines in the 8
; bit device families.  On PIC18's the high priority and low priority
; interrupts are located at 0x0008 and 0x0018, respectively.  On PIC16's and
; lower the interrupt is at 0x0004.  Between device families there is subtle
; variation in the both the hardware supporting the ISR (for restoring
; interrupt context) as well as the software used to restore the context
; (without corrupting the STATUS bits).
;
; General formats are shown below in relocatible format.
;
;------------------------------PIC16's and below--------------------------------
;
; ISR       CODE    0x0004           ; interrupt vector location
;
;     <Search the device datasheet for 'context' and copy interrupt
;     context saving code here.  Older devices need context saving code,
;     but newer devices like the 16F#### don't need context saving code.>
;
;     RETFIE
;
;----------------------------------PIC18's--------------------------------------
;
; ISRHV     CODE    0x0008
;     GOTO    HIGH_ISR
; ISRLV     CODE    0x0018
;     GOTO    LOW_ISR
;
; ISRH      CODE                     ; let linker place high ISR routine
; HIGH_ISR
;     <Insert High Priority ISR Here - no SW context saving>
;     RETFIE  FAST
;
; ISRL      CODE                     ; let linker place low ISR routine
; LOW_ISR
;       <Search the device datasheet for 'context' and copy interrupt
;       context saving code here>
;     RETFIE
;
;*******************************************************************************

; TODO INSERT ISR HERE
	ORG	    H'0004'
        GOTO	ISR
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START

	MOVLW	    H'00'
	MOVWF	    ANSEL	    ; configure all pins as digital
	
	BANK1
	MOVLW	    H'F0'           ; bit0 input for button
	MOVWF	    TRISB           ; 4 inputs + 4 outputs
	MOVLW	    H'00'	    ; set port-a for output
	MOVWF	    TRISA
	
	MOVLW	    H'BF'	    ; B'1011 1111'
	MOVWF	    OPTION_REG	    ; set up interrupT on falling edge

	BANK0
	MOVLW	    H'03'	    ; set LEDs on line 0 and 1
	MOVWF	    PORTA
	MOVLW	    H'00'
	MOVWF	    PORTB	    ; clear all port-B pins
	
; ===========================
;   setup interrupt routines
; ===========================
; CLEAR external interupt flag, int = bit 1
	BCF	    INTCON,RBIF
	
	BSF	    INTCON,GIE	   ; enable global interrupt, bit 7
	BSF	    INTCON,INTE	   ; enable RB0 pin interrupt, bit 4

; =================================
;  flash led wired to portb, line 2
; =================================
LIGHTS
	NOP	    ; main program does nothing, all action takes
		    ; place in the interrupt service routine
	GOTO	    LIGHTS
; ==========================================
;    interrupt service routine - ISR
; ==========================================
; this ISR receives control when there is action
; on pushbutton switch wired to portb, line 0
ISR
	BTFSS       INTCON,RBIF	    ; check if src is an RB0 interrupt
	GOTO	    NOT_PRESSED
	
	MOVWF	    OLD_W	    ; save context in W register
	SWAPF	    STATUS,W	    ; set STATUS to W
	MOVWF	    OLD_STATUS	    ; save STATUS
	
; ====================================
;  interrupt action
; ====================================
; HERE the interrupt occurs when any of port-b bits 4 to 7
; have changed their logical status
	MOVF	    PORTB,W	    ; read port-b bits
	MOVWF	    READING	    ; save read status
	XORWF	    BITS_B47,F	    ; XOR with old bits
				    ; store result in F register
	BTFSC	    BITS_B47,RB4    ; test bit 4
	GOTO	    RB4_CHNG
	
	BTFSC	    BITS_B47,RB7
	GOTO	    RB7_CHNG
	
	GOTO	    BTN_RELEASE	    ; invalid port line change. Exit
	
; ---------bit 4 change routine due button press ------------------------------
RB4_CHNG
	BTFSC	    PORTB,RB4	    ; is bit 4 high
				    ; has button been pressed?
	GOTO	    BTN_RELEASE	    ; bit is high, igore it
	
	MOVLW	    H'02'	    ; toggle bit 1 of port-a
	XORWF	    PORTA,F	    ; xoring will produce its complement
	GOTO	    BTN_RELEASE

; ---------bit 7 change routine due button press ------------------------------
RB7_CHNG
	BTFSC	    PORTB,RB7	    ; has button been pressed? is bit high?
	GOTO	    EXIT_ISR
	
	MOVLW	    H'01'	    ; toggle second led by xoring
	XORWF	    PORTA,F

BTN_RELEASE
	CALL	    DELAY	    ; debounce switch
	MOVF	    PORTB,W	    ; read port-b into W
	ANDLW	    H'90'	    ; B'1001000' - eliminate unused bits
	BTFSC	    STATUS,Z	    ; check for zero
	GOTO	    BTN_RELEASE	    ; wait a while
	
; at this point all port-b pushbuttons have been released

; ------------ SUBROUTINE ------------------------------------------------------
EXIT_ISR			    ; store new value of portB
	MOVF	    READING,W	    ; into W register
	MOVWF	    BITS_B47	    ; copy value into this register
; restore context
	SWAPF	    OLD_STATUS,W
	MOVFW	    STATUS
	SWAPF	    OLD_W,F
	SWAPF	    OLD_W,W

; ------------ SUBROUTINE 2 -----------------------------------------------------
; reset interrupt
NOT_PRESSED
	BCF	    INTCON,RBIF	    ; clear intcon bit 0
	RETFIE
; ------------ SUBROUTINE 3 -----------------------------------------------------
; procedure meant to delay 10 machine cycles
DELAY
	MOVLW	    D'6'	    ; repeat 18 machine cycles
	MOVWF	    COUNT1
REPEAT
	DECFSZ	    COUNT1,F	    ; decrement counter
	GOTO	    REPEAT	    ; continue if not 0
	RETURN
; ------------ SUBROUTINE 4 -----------------------------------------------------
; THIS IS USED FOR DEBUGGING
LONG_DELAY
	MOVLW	    D'200'
	MOVWF	    J		    ; endereco de onde se comeca a guardar variaveis
JLOOP
	MOVWF	    K
KLOOP
	DECFSZ	    K,F
	GOTO	    KLOOP
	
	DECFSZ	    J,F
	GOTO	    JLOOP
	RETURN
	
; -----------------------------------------------------------------------------
	END