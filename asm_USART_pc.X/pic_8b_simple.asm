
;*******************************************************************************
;  USART communication, control leds from keyboard
;*******************************************************************************
#include "p16f887.inc"
    
; __config 0xE0D7
 __CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

;*******************************************************************************
; Variable definitions
;*******************************************************************************
 CBLOCK		H'20'
    rcv_data
    errFlag
    OLD_W
    OLD_STATUS
    OLD_PCLATH
    OLD_FSR
    COUNTER
 ENDC 
;*******************************************************************************
; Bank selection MACROS
;*******************************************************************************
Bank0	MACRO		    ; Select RAM bank 0
	bcf	STATUS,RP0
	bcf	STATUS,RP1
	ENDM
;----------------------------------------------
Bank1	MACRO		    ; Select RAM bank 1
	bsf	STATUS,RP0
	bcf	STATUS,RP1
	ENDM
;-----------------------------------------------
Bank2	MACRO		    ; Select RAM bank 2
	bcf	STATUS,RP0
	bsf	STATUS,RP1
	ENDM
;----------------------------------------------
Bank3	MACRO		    ; Select RAM bank 3
	bsf	STATUS,RP0
	bsf	STATUS,RP1
	ENDM 

;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
;*******************************************************************************
    org		H'0004'
    GOTO    USART_ISR
    
; TODO INSERT ISR HERE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                     ; let linker place main program
;---------------------------------------------------------------
; asynchronous reception setup
;---------------------------------------------------------------
START:
				
    Bank1			; select RAM Bank 1
				; transmit status and control register
				; high baud rate select bit
    BCF	    TXSTA, BRGH  	; async mode, low speed
    BCF	    TXSTA, SYNC  	; choose asynchronous operation
    MOVLW   H'85'		; configure timer 0         prescaler
    MOVWF   OPTION_REG		; pull-up disabled, Fosc/4, 1:64
    BSF	    PIE1, RCIE		; enable interrupt to detect incoming data
    MOVLW   H'80'		;
    MOVWF   INTCON		; enable global, peripheral, timer0 interrupts
    MOVLW   H'00'
    MOVWF   TRISD		; all portD as output
    MOVWF   TRISB		; all portB as output
    MOVLW   H'F0'
    MOVWF   TRISC		; bits 7 and 6 (5, 4) as inputs
;------------------------------------------------------------    
    Bank0			; select bank 0
				; receive status and control register
				; spen stands for serial port enable bit
    BSF	    RCSTA, SPEN		; enable the serial port
    BSF	    RCSTA, CREN		; enable data reception
				; continuous receive enable bit 
    BSF	    PORTD, RD0		; turn on led on RD0
    BCF	    PORTD, RD1	        ; turn off led on RD1
    BSF	    PORTB, RB2		; turn on led on RB2
    CLRF    TMR0		; initialize tmr0 counter (it counts up to 255)
;-------------------------------------------------------------
    Bank2			; select bank 2
    BCF	    CM1CON0, C1ON	; turn off comparator 1
    BCF	    CM2CON0, C2ON	; turn off comparator 2
;--------------------------------------------------------------
    Bank3			   ; select bank 3
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   ANSELH		   ; all ports as digital output
    MOVWF   ANSEL
    BCF	    BAUDCTL, BRG16	   ; set 8 bit baud rate generator bit
    MOVLW   D'25'		   ; 9600 baud rate, at 16 MHz, 8 bit, low speed
    MOVWF   SPBRG		   ; for high speed, BRG16 should be set, 
				   ; and this value would be 103
				  
;*******************************************************************************
    Bank0			   ; leave bank3 and go back to bank0
    MOVLW   D'245'
    MOVWF   COUNTER		   ; setup counter for LED blink delay
Main:
    GOTO    Main		   ; all the logic happends in the ISR
    
;*******************************************************************************
;  interrupt service routine
;*******************************************************************************    
USART_ISR:
	; save context
	MOVWF   OLD_W		; save W
    	BCF	STATUS, RP0     ; access BANK0
    	SWAPF   STATUS, W	; store status in W
    	MOVWF   OLD_STATUS	; save status
	MOVF	PCLATH, W	; store pclath in W
	MOVWF	OLD_PCLATH	; save pclath
	MOVF	FSR, W		; store fsr in W
	MOVWF	OLD_FSR		; save fsr
;-----------------------------------------------

	Bank0    
	BTFSS   INTCON, T0IF      ; is it a timer0 interrupt?
	GOTO	exitISR		  ; it not (T0IF = 0), leave ISR
	BCF	INTCON, T0IF      ; if it is, clear flag.
	CLRF	TMR0		  ; restart timer0 counting  
	DECFSZ	COUNTER		  ; decrement counter and skip
	GOTO	usart		  ; this line, when it reaches 0
	CALL	blinkLed
	; is an USART RX interrupt?
usart:	BTFSC   PIR1, RCIF      ; Test bit 5 
        BSF     STATUS, RP0     ; Bank 1 if RCIF set

	Bank1
	BTFSS	PIE1, RCIE	; test if interrupt is enabled
	GOTO	exitISR
	
	Bank0
	; Test for overrun and framing errors.
	; Bit 1 (OERR) of the RCSTA register detects overrun
	; Bit 2 (FERR) of the RCSTA register detects framing error
	BTFSC	RCSTA, OERR	; Test for overrun error   
	GOTO	overflowErr	; Error handler
	BTFSC	RCSTA, FERR	; Test for framing error
	GOTO	frameErr	; Error handler
	
	; read the RCSTA register to get the error flags
	MOVF	RCREG, W	; get the 8 least significant data bits
	MOVWF	rcv_data	; copy value into variable
	;-----------------------
	MOVLW	H'49'
	SUBWF   rcv_data	; check whether it is a '1' (ASCII: 0x49)
	BTFSC	STATUS, Z	; if Z flag not set?
	GOTO    toggleGreen	; No, it is 1 (0x49-0x49 = 0, Z = 1)
				; so, toggle green led
	GOTO	secondCmd				
;-----------------------------------------------	
blinkLed:
        MOVLW   H'04'
	XORWF   PORTB
	MOVLW   D'245'
	MOVWF   COUNTER		; reload counter with 245
	RETURN
;-----------------------------------------------		
toggleGreen:
	MOVLW	H'01'
	XORWF	PORTD		; change LED state
	GOTO	exitISR
;-------------------------------	
secondCmd:			; Yes, it is zero, so come to this label	
	MOVLW	H'50'
	SUBWF   rcv_data	; check whether it is a '2' (ASCII: 0x50)
	BTFSC	STATUS, Z	; Is Z flag not set?
	GOTO	toggleRed	; No, it is set, since 0x50-0x50 = 0, Z = 1
				; so, toggle red led
	GOTO    exitISR  	; Z flag is zero, so leave ISR
;-------------------------------
toggleRed:
	MOVLW	H'02'
	XORWF	PORTD		; change LED state
	GOTO	exitISR
	
;==========================;
;     error handlers       ;
;==========================;
overflowErr:
        BSF	errFlag, 0	    ; Bit 0 is overrun error
	; Reset system, because if an overrun occurred, clear the OERR flag
	BCF	RCSTA,CREN	    ; Clear continuous receive bit
	BSF     RCSTA,CREN	    ; Set to re-enable reception
	GOTO    exitISR

frameErr:
	BSF	errFlag, 1	    ; Bit 1 is framing error
	MOVF	RCREG, W	    ; Read and throw away bad data
	
;======================================;
;   end of interrupt service routine   ;
;======================================;
exitISR:
	; restore context
	Bank0
	MOVF	OLD_FSR, W	    ; Recover FSR value
	MOVWF	FSR		    ; Restore in register
	MOVF	OLD_PCLATH, w	    ; Recover PCLATH value
	MOVWF	PCLATH		    ; Restore in register

	SWAPF   OLD_STATUS, W
	MOVFW   STATUS
	SWAPF   OLD_W, F
	SWAPF   OLD_W, W
   
	RETFIE
;*******************************************************************************    	
	END
;*******************************************************************************    
           