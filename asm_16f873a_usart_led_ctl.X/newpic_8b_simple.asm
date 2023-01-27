;==============================================================
; Description
;   Program to send/receive data through USART
;   A USB-USART fdti convert is wired to RC7/TX and R6/RX pins
;==============================================================
#include "p16f873a.inc"

; CONFIG
; __config 0xFF3A
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

#define	TRUE	1
#define FALSE   0 

;============================================================
; MACROS
;============================================================
; Macros to select the register banks
Bank0	MACRO		    ; Select RAM bank 0
	BCF	STATUS,RP0
	BCF	STATUS,RP1
	ENDM
;----------------------------------------------
Bank1	MACRO		    ; Select RAM bank 1
	BSF	STATUS,RP0
	BCF	STATUS,RP1
	ENDM
;-----------------------------------------------
Bank2	MACRO		    ; Select RAM bank 2
	BCF	STATUS,RP0
	BSF	STATUS,RP1
	ENDM
;----------------------------------------------
Bank3	MACRO		    ; Select RAM bank 3
	BSF	STATUS,RP0
	BSF	STATUS,RP1
	ENDM
;===============================================================================
; variables in PIC RAM
;===============================================================================
; Local variables
Aa   EQU   H'65'
Ss   EQU   H'83'
Dd   EQU   H'68'
Ff   EQU   H'70'
Gg   EQU   H'71'
Hh   EQU   H'72'
Jj   EQU   H'74'
Kk   EQU   H'75'
Ll   EQU   H'76'

Zz   EQU   H'90'
Xx   EQU   H'88'
Cc   EQU   H'67'
Vv   EQU   H'86'
Bb   EQU   H'66'
Nn   EQU   H'78'
Mm   EQU   H'77'

#define LED0_ON   Aa		
#define LED0_OFF  Ss
#define LED1_ON   Dd
#define LED1_OFF  Ff
#define LED2_ON   Gg
#define LED2_OFF  Hh
#define LED3_ON   Jj
#define LED3_OFF  Kk
#define LED4_ON   Ll
#define LED4_OFF  Zz
#define LED5_ON   Xx 
#define LED5_OFF  Cc
#define LED6_ON   Vv 
#define LED6_OFF  Bb
#define LED7_ON   Nn 
#define LED7_OFF  Mm
	
CBLOCK		 H'20'   ; Start of block
    rcvFree	
    rcvData
    errFlag
    W_TEMP
    STATUS_TEMP
    PCLATH_TEMP
ENDC
;===============================================================================
RES_VECT  CODE    H'0000'            ; processor reset vector
    GOTO    START                   ; go to beginning of program
;===============================================================================
; add interrupts here if used
    ORG	    H'0004'
    GOTO    USART_ISR
;===============================================================================    
; PROGRAM
;===============================================================================
MAIN_PROG CODE                      ; let linker place main program

    ;------------------------ TXSTA and RCSTA REG ------------------------------;
    ; TXSTA 
    ;
    ; bt7: CSRC - clock source select bit, Asynchronous mode -> don't care      ;                                  ;
    ; bt6: TX9, 9-bit transmit enable bit				        ;
    ; bit5: TXEN - transmit enable bit, 0: off, 1: on                           ;
    ;                                    
    ; bit4: SYNC, USART mode select bit, 1: synchronous, 0: async               ;
    ; bit3: (unimplemented)                                                     ;
    ; bit2: BRGH - 1: high speed, 0:low speed                                  ;
    ;   --------> SPBRG value is 25 for 9600 baudrate, 8 bit                    ;
    ;	              low speed, 16 MHz or 103 for high speed			; 		;
    ; bit1: transmit shift register status bit TRMT, 1: TSR empty, 0: TSR full  ;
    ; bit0: 9th bit of transmit data, can be parity bit
    ;---------------------------------------------------------------------------;
    ; RCSTA - received status and control register
    ;
    ; bt7: SPEN serial port enable, 1: on (RC7/RX/DT and RC6/TX/CK set)                                  ;
    ; bt6: RX9 9-bit receive enable bit, 1: on, 0: 8-bit receive enabled				        ;
    ; bit5: SREN single receive enable bit (async - don't care)
    ; bit4: CREN continuous receive enable bit, 1: ON, 0: off
    ; bit3: ADDEN address detect enable bit 
    ;      1: enables it, enables interrupt and load of the receive buffer when
    ;      RSR<8> is set
    ;      0: disables, all bytes are received, 9th bit can be parity bit
    ; bit2: FERR, 1: framing error, can be updated by reading RCREG and
    ;                  receive next valid bit.                      		;
    ; bit1: OERR, 1: overrun error, can be cleared by clearing bit CREN
    ; bit0: RX9D, 9th bit of received data
    ;---------------------------------------------------------------------------;
START    

    CALL    USART_Init
    Bank1			   ; select bank 1  
    CLRF    TRISB		   ; set port B pins as output
    MOVLW   H'FF'
    MOVWF   TRISA		   ; input
;-------------------------------------------------------------------------------    
    Bank0			   ; select bank 0
    CLRF    PORTB
    MOVLW   (1 << GIE)
    IORWF   INTCON		   ; enable global interrupt
    BCF	    STATUS, C		   ; clear carry bit
    
;*******************************************************************************
;   Main routine
;*******************************************************************************
Loop
    BTFSC   rcvFree, FALSE	    ; check rx buffer flag status
    CALL    RX_Echo		    ; if it is TRUE, invoke this subroutine
    GOTO    Loop

;*******************************************************************************
;   Subroutines
;*******************************************************************************
; PIE1 = peripheral interrupt enable registre
;     bit7 - reserved
;     bit6 - ADIE: A/D converter interrupt enable	
;     bit5 RCIE: USART receive interrupt enable
;     bit4 TXIE: USART transmit interrupt enable
;     bit3 SSPIE synchronous serial port interrupt enable
;     bit2 CCP1IE capture control register one interrupt enable
;     bit1 TMR2IE timer two interrupt enable bit
;     bit0 TMR1IE timer one interrupt enable bit
;-------------------------------------------------------------------------------    
; PIR1 = peripheral interrupt flags register
;     bit7 - reserved
;     bit6 ADIF: A/D converter interrupt flag	
;     bit5 RCIF: USART receive interrupt flag
;     bit4 TXIF: USART transmit interrupt flag
;     bit3 SSPIF synchronous serial port interrupt flag
;     bit2 CCP1IE capture control register one interrupt flag
;     bit1 TMR2IE timer two interrupt flag
;     bit0 TMR1IE timer one interrupt flag
;-------------------------------------------------------------------------------    

USART_Init
    Bank1			    ; select bank 1
    MOVLW   D'25'		    ; set 9600 baud rate, 8-bit transmit
    MOVWF   SPBRG		    ; low speed, at HS 16 MHz
    MOVLW   (1<<RC7) | (1<<RC6)	    ; set pins 7 and 6 as input
    IORWF   TRISC		    ; since they are RX and TX lines.
    MOVLW   (1 << TXEN)
    IORWF   TXSTA		    ; set bit 5(transmit enable bit
    MOVLW   (1<<RCIE)		    ; bit five will be set
    IORWF   PIE1		    ; enable USART receive interrupt
    
    Bank0
    MOVLW   (1<<SPEN) | (1<<CREN)   ; set continous receive mode (bit4)
    IORWF   RCSTA		    ; set serial port enable bit (bit7)
    MOVLW   (1<<PEIE)
    IORWF   INTCON		    ; set peripheral interrupt enable pin
    RETURN
;-------------------------------------------------------------------------------
TX_Done
    Bank1
    BTFSC   TXSTA, TRMT		    ; check for the transmit status register
    GOTO    TX_Done		    ; bit, if it is full it equal zero
    Bank0			            ; if empty, jump to label, else skip it
    RETURN			    ; and go back to main routine
;-------------------------------------------------------------------------------
turnOnGreen
    BSF   PORTB, RB0
    GOTO    endEcho
turnOffGreen
    BCF   PORTB, RB0
    GOTO    endEcho
turnOnRed
    BSF   PORTB, RB1
    GOTO    endEcho
turnOffRed
    BCF   PORTB, RB1
    GOTO    endEcho
turnOnYel
    BSF   PORTB, RB2
    GOTO    endEcho
turnOffYel
    BCF   PORTB, RB2
    GOTO    endEcho
;=======================    
turnOnGreen2
    BSF     PORTB, RB3
    GOTO    endEcho
turnOffGreen2
    BCF    PORTB, RB3
    GOTO    endEcho
turnOnRed2
    BSF    PORTB, RB4
    GOTO    endEcho
turnOffRed2
    BCF   PORTB, RB4
    GOTO    endEcho
turnOnYel2
    BSF     PORTB, RB5
    GOTO    endEcho
turnOffYel2
    BCF     PORTB, RB5
    GOTO    endEcho
;======================
turnOnGreen3
    BSF     PORTB,RB6
    GOTO    endEcho
turnOffGreen3
    BCF     PORTB, RB6
    GOTO    endEcho
turnOnRed3
    BSF     PORTB, RB7
    GOTO    endEcho
turnOffRed3
    BCF     PORTB, RB7
    GOTO    endEcho
;-------------------------------------------------------------------------------    
RX_Echo
    BCF	    rcvFree, FALSE	    ; clear buffer flag
    MOVF    rcvData, W		    ; move received data back to W reg
    MOVWF   TXREG		    ; and copy into the receive register
    CALL    TX_Done		    ; invoke transmit soubroutine
    
    SUBLW   LED0_ON		    ; check if data is 'A'
    BTFSC   STATUS, Z		    ; is Z set? (L-W = 0)?
    CALL    turnOnGreen
    SUBLW   LED0_OFF		    ; check if data is 'S'
    BTFSC   STATUS, Z
    CALL    turnOffGreen
    
    SUBLW   LED1_ON		    ; check is data is 'D'
    BTFSC   STATUS, Z
    CALL    turnOnRed
    SUBLW   LED1_OFF		    ; check is data is 'F'
    BTFSC   STATUS, Z
    CALL    turnOffRed
    
    SUBLW   LED2_ON		    ; check is data is 'G'
    BTFSC   STATUS, Z
    CALL    turnOnYel
    SUBLW   LED2_OFF		    ; check is data is 'H'
    BTFSC   STATUS, Z
    CALL    turnOffYel
    
    SUBLW   LED3_ON		    ; check is data is 'J'
    BTFSC   STATUS, Z
    CALL    turnOnGreen2
    SUBLW   LED3_OFF		    ; check is data is 'K'
    BTFSC   STATUS, Z
    CALL    turnOffGreen2
    
    SUBLW   LED4_ON		    ; check is data is 'L'
    BTFSC   STATUS, Z
    CALL    turnOnRed2
    SUBLW   LED4_OFF		    ; check is data is 'Z'
    BTFSC   STATUS, Z
    CALL    turnOffRed2
    
    SUBLW   LED5_ON		    ; check is data is 'X'
    BTFSC   STATUS, Z
    CALL    turnOnYel2
    SUBLW   LED5_OFF		    ; check is data is 'C'
    BTFSC   STATUS, Z
    CALL    turnOffYel2
    
    SUBLW   LED6_ON		    ; check is data is 'V'
    BTFSC   STATUS, Z
    CALL    turnOnGreen3
    SUBLW   LED6_OFF		    ; check is data is 'B'
    BTFSC   STATUS, Z
    CALL    turnOffGreen3
    
    SUBLW   LED7_ON		    ; check is data is 'N'
    BTFSC   STATUS, Z
    CALL    turnOnRed3
    SUBLW   LED7_OFF		    ; check is data is 'M'
    BTFSC   STATUS, Z
    CALL    turnOffRed3
endEcho    
    RETURN
;*******************************************************************************
;   interrupt service routine
;*******************************************************************************    
USART_ISR 
    ; save context--------------------------------------------------------------
    MOVWF   W_TEMP		    ; Copy W to TEMP register
    SWAPF   STATUS,W		    ; Swap status to be saved into W 
    CLRF    STATUS		    ; bank 0, regardless of current bank, 
				    ; Clears IRP,RP1,RP0
    MOVWF   STATUS_TEMP		    ;Save status to bank zero STATUS_TEMP reg
    MOVF    PCLATH, W		    ;Only required if using pages 1, 2 and/or 3
    MOVWF   PCLATH_TEMP		    ;Save PCLATH into W
    CLRF    PCLATH		    ;Page zero, regardless of current page
;-------------------------------------------------------------------------------
    BTFSS   PIR1, RCIF		    ; check if receive interrupt enable
    GOTO    ExitISR		    ; is set, if not leave ISR
    BCF	    PIR1, RCIF		    ; else, continue from here
    BTFSC   RCSTA, OERR		    ; Test for overrun error
    GOTO    OverErr		    ; Error handler
    BTFSC   RCSTA,FERR		    ; Test for framing error
    GOTO    FrameErr		    ; Error handler
				    ; At this point no error was detected
				    ; Received data is in the USART 
				    ; RCREG register
    MOVF    RCREG,W		    ; get received data
    MOVWF   rcvData		    ; and copy to local variable
    BSF	    rcvFree,FALSE	    ; buffer is full, not available for new data
    CLRF    errFlag
    GOTO    ExitISR
;==========================
; error handlers
;==========================
OverErr
    bsf	    errFlag,0		    ; Bit 0 is overrun error
				    ; Reset system
    bcf	    RCSTA, CREN		    ; Clear continuous receive bit
    bsf	    RCSTA, CREN		    ; Set to re-enable reception
    return

; error because FERR framing error bit is set
; can do special error handling here 
; this code simply clears and continues
FrameErr
    bsf	    errFlag,1               ; Bit 1 is framing error
    movf    RCREG, W               ; Read and throw away bad data
    return
;-------------------------------------------------------------------------------    
ExitISR    
    ; restore context
    MOVF    PCLATH_TEMP, W	    ;Restore PCLATH
    MOVWF   PCLATH		    ;Move W into PCLATH
    SWAPF   STATUS_TEMP,W	    ;Swap STATUS_TEMP register into W 
				    ;(sets bank to original state)
    MOVWF   STATUS		    ;Move W into STATUS register
    SWAPF   W_TEMP,F		    ;Swap W_TEMP
    SWAPF   W_TEMP,W		    ;Swap W_TEMP into 
    
    RETFIE				    
;*******************************************************************************
;   end of program
;*******************************************************************************
    END
;*******************************************************************************