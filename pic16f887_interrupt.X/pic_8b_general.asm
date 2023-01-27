
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
    COUNT
    COUNT2
    OLD_W
    OLD_STATUS
    TIME1
    TIME2
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

    ; TODO Step #5 - Insert Your Program Here
	BANK1
	MOVLW	    H'01'           ; bit0 input for button
	MOVWF	    TRISB           ; 7 outputs + 1 input
	
	MOVLW	    H'BF'	    ; B'1011 1111'
	MOVWF	    OPTION_REG	    ; set up interrupT on falling edge

	BANK0
	MOVLW	    H'00'
	MOVWF	    PORTB	    ; B'0000 0000'
	BSF	    BUTTON
; ===========================
;   setup interrupt routines
; ===========================
	BCF	    INTCON,INTF	   ; clear external interrupt flag
	BSF	    INTCON,GIE	   ; enable global interrupt, bit 7
	BSF	    INTCON,INTE	   ; enable RB0 pin interrupt, bit 4

; =================================
;  flash led wired to portb, line 2
; =================================
LIGHTS
	MOVLW	    H'02'
	XORWF	    PORTB,F	   ; complement bit 1, COMF?
	MOVLW	    D'3'
	MOVWF	    COUNT
FOR	CALL	    LONG_DELAY
	DECFSZ      COUNT,F
	GOTO	    FOR
	GOTO	    LIGHTS
; ==========================================
;    interrupt service routine - ISR
; ==========================================
; this ISR receives control when there is action
; on pushbutton switch wired to portb, line 0
ISR
	BTFSS       INTCON,INTF	    ; check if src is an RB0 interrupt
	GOTO	    NOT_PRESSED
	MOVWF	    OLD_W	    ; save context in W register
	SWAPF	    STATUS,W	    ; set STATUS to W
	BANK0			    ; select bank 0 (default for reset)
	MOVWF	    OLD_STATUS	    ; save STATUS
; make sure that interrupt occured on the falling edge
; of the signal. If not, abort ISR handler
	BTFSC	    BUTTON	    ; is button set to high?
	GOTO	    EXIT_ISR
	
; ====================================
;  interrupt action
; ====================================
; debounce switch - this algorithm consists in waiting until
; the same leel is repeated on a number of samplings of the
; button. At this pint the RB0 line is clear since the interrupt
; takes place on thje falling edge. The routine waits until the low 
; value is read several times.
	MOVLW	    D'10'	    ; NUMBER OF REPETITIONS
	MOVWF	    COUNT2	    ; save it into counter
WAIT
	BTFSC	    BUTTON	    ; check to see that BUTTON is still low
				    ; if not, wait until it changes
	GOTO	    EXIT_ISR
	DECFSZ	    COUNT2,F
	GOTO	    WAIT
; INTERRUPT action consists of toggling bit 2 of portb to toggle LED
	MOVLW	    H'04'	    ;xor-ing with a 1-bit produces the complement
	XORWF	    PORTB,F

; ------------ SUBROUTINE 1 -----------------------------------------------------
EXIT_ISR			    ; restore context
	SWAPF	    OLD_STATUS,W    ; saved status to W
	MOVFW	    STATUS	    ; to STATUS register
	SWAPF	    OLD_W,F	    ; swap File reg in itself
	SWAPF	    OLD_W,W	    ; re-swap back to W
; ------------ SUBROUTINE 2 -----------------------------------------------------

NOT_PRESSED
	BCF	    INTCON,INTF	    ; clear intcon bit 1 to reset interrupt
	RETFIE
; ------------ SUBROUTINE 3 -----------------------------------------------------
; procedure meant to delay 10 machine cycles
DELAY
	MOVLW	    D'4'	    ; repeat 12 machine cycles
	MOVWF	    TIME1
REPEAT
	DECFSZ	    COUNT,F	    ; decrement counter
	GOTO	    REPEAT	    ; continue if not 0
	RETURN
; ------------ SUBROUTINE 4 -----------------------------------------------------
LONG_DELAY
	MOVLW	    D'200'
	MOVWF	    COUNT2	; endereco de onde se comeca a guardar variaveis
JLOOP
	MOVWF	    TIME2
KLOOP
	DECFSZ	    TIME2,F
	GOTO	    KLOOP
	
	DECFSZ	    COUNT2,F
	GOTO	    JLOOP
	CALL	    DELAY
	RETURN
	
; -----------------------------------------------------------------------------
	END