;============================================================
; Description
;   Program uses a table to show 8 blinking patterns on
;   PORTB. TMR0 is used to generate a 1 second delay.
;============================================================
#include "p16f887.inc"

; __config 0xE0E5
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
 
; __CONFIG directive is used to embed configuration data
; within the source file. The labels following the directive
; are located in the corresponding .inc file.
#define save_rp1 INTCON,PEIE ; or PEIE, TMR0IE, INTE, RBIE
#define save_rp0 INTCON,RBIE 
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
CBLOCK		 H'20'   ; Start of block
    counter
    pointer
    lastIndex
    OLD_W
    OLD_STATUS
    ;OLD_FSR
    OLD_PCLATH
ENDC
;===============================================================================
RES_VECT  CODE    H'0000'            ; processor reset vector
    GOTO    START                   ; go to beginning of program
;===============================================================================
; add interrupts here if used
    ORG	    H'0004'
    GOTO    TMR0_ISR
;===============================================================================    
; PROGRAM
;===============================================================================
MAIN_PROG CODE                      ; let linker place main program

START
    ;------------------------ OPTION_REG setting--------------------------------;
    ; bt7: NOT_RBPU -> 0 = EN, *1* = DIS                                        ;
    ; bt6: INTEDG -> 0 = falling edge, *1* =rising edge                         ;
    ; bit5: T0CS (TMR0 clock source), *0* = internal instruction cycle clock    ;
    ;                                    (Fosc/4), 1 = transition on TOCKI pin  ;
    ; bit4: T0SE (TMR0 edge select), 0 = inc low-to-high, *1* = inc high-to-low ;
    ; bit3: PSA (prescaler assign) 1 = to WDT, *0* = to TMR0                    ;
    ; <bit2:0> presclaer bits, 000 1:2, 010 1:8, 100 1:32, 110 1:128,           ;
    ; 001 1:4, 011 1:16, *101* 1:64 and 111 1:256, --> VALUE: b'11010101'       ;
    ;---------------------------------------------------------------------------;
    Bank0	    
    CLRF    PORTB
    ;---------------------------------------------------------------------------
    Bank1			   ; select bank 1  
    MOVLW   H'85'                  ; set value: b'10000101'
    MOVWF   OPTION_REG		   ; XTAL 16 MHz, psa TMR0, 1:64
    MOVLW   H'A0'		   ; set GIE, T0IE (b'1010 000')
    MOVWF   INTCON		   ;
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   TRISB		   ; set port B pins as output
;-------------------------------------------------------------------------------    
    Bank0			   ; select bank 0
    MOVLW   H'55'
    MOVWF   PORTB
    CLRF    pointer		   ; prepare pointer for table index control
    MOVLW   H'00'		   ; this counter is used to generate a
    MOVWF   counter                ; 1 second delay by decrementing 
    MOVLW   H'07'		   ; the value 0000 0111 is used to check
    MOVWF   lastIndex		   ; if the table last index has been reached
    CLRWDT
    MOVLW   H'06'		   ;
    MOVWF   TMR0		   ; load tmr0 with initial counting value
    
;*******************************************************************************
;   Main routine
;*******************************************************************************
Loop:
    MOVLW   D'20'
    SUBLW   counter
    BTFSS   STATUS, Z
    GOTO    Loop
    GOTO    LedPatterns
    CLRF    counter
    GOTO    Loop		   ; repeat procedure forever
;*******************************************************************************
;   Program subroutines 
;*******************************************************************************    
Table
    ADDWF   PCL
    RETLW   H'A2'
    RETLW   H'1F'
    RETLW   H'03'
    RETLW   H'67'
    RETLW   H'23'
    RETLW   H'3F'
    RETLW   H'47'
    RETLW   H'7F'
;---------------------------------------------------------------------------    
LedPatterns    
    MOVF    pointer, W		    ; copy 0 into W register
    CALL    Table		    ; call table with hex values
    MOVWF   PORTB	            ; send returned value to W into PORTB
    INCF    pointer, W		    ; increment pointer and save in W reg
    ANDLW   lastIndex		    ; AND value with 0000 0111 to reset pointer
    MOVWF   pointer		    ; copy result of ANDing in pointer register
    RETURN
;*******************************************************************************
;   Interrupt service routine
;*******************************************************************************
TMR0_ISR
	BCF save_rp1 ; *** can eliminate two instructions here ***
        BCF save_rp0 ;
        BTFSC STATUS,RP1 ; save banking bits
        BSF save_rp1 ;
        BTFSC STATUS,RP0 ;
        BSF save_rp0 ;
  
        BCF STATUS,RP1 ; select bank0
        BCF STATUS,RP0 ;
        MOVWF OLD_W ; save wreg
        MOVF STATUS,W ; save status with bank0 bits
        MOVWF OLD_STATUS ;
        MOVF PCLATH,W ; save pclath
        MOVWF OLD_PCLATH ;
  
        PAGESEL IRQ_Handler ; select page
        GOTO IRQ_Handler ; branch to interrupt handler
  
IRQn	MOVF OLD_PCLATH,W ; restore pclath
        MOVWF PCLATH ;
        MOVF OLD_STATUS,W ; restore status with bank0 bits
        MOVWF STATUS ;
        SWAPF OLD_W,F ; restore wreg
        SWAPF OLD_W,W ;
  
        BTFSC save_rp1 ; restore banking bits
        BSF STATUS,RP1 ;
        BTFSC save_rp0 ;
        BSF STATUS,RP0 ;
  
        BCF save_rp1 ; restore interrupt enable bits
        BCF save_rp0 ;
        RETFIE ; return from interrupt
 
IRQ_Handler
        ; (ISR) ; insert isr code here -----------------------------------------
        BTFSS	INTCON, T0IF	    ; check if an overflow ocurred
	GOTO	exitISR		    ; if flag is not set, exit ISR.
	BCF	INTCON, T0IF	    ; else, clear flag
	MOVLW   H'06'
	MOVWF   TMR0		    ; reload tmr0 with initial counting value
	INCF    counter		    ; increment counter
;-------------------------------------------------------------------------------
exitISR 
	CLRF	PCLATH		    ; select page0
        GOTO	IRQn		    ; branch to
;*******************************************************************************
;   End of PIC program
;*******************************************************************************    
    END
;*******************************************************************************    
    