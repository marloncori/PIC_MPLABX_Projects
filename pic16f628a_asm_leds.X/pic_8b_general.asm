
;*******************************************************************************

; Assembly source line config statements

#include "p16f628a.inc"

;*******************************************************************************
;
; TODO Step #2 - Configuration Word Setup
;
; The 'CONFIG' directive is used to embed the configuration word within the
; .asm file. MPLAB X requires users to embed their configuration words
; into source code.  See the device datasheet for additional information
; on configuration word settings.  Device configuration bits descriptions
; are in C:\Program Files\Microchip\MPLABX\mpasmx\P<device_name>.inc
; (may change depending on your MPLAB X installation directory).
;
; MPLAB X has a feature which generates configuration bits source code.  Go to
; Window > PIC Memory Views > Configuration Bits.  Configure each field as
; needed and select 'Generate Source Code to Output'.  The resulting code which
; appears in the 'Output Window' > 'Config Bits Source' tab may be copied
; below.
;
;*******************************************************************************

; TODO INSERT CONFIG HERE
; __config 0xFF19
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

;*******************************************************************************
;
; TODO Step #3 - Variable Definitions
;
; Refer to datasheet for available data memory (RAM) organization assuming
; relocatible code organization (which is an option in project
; properties > mpasm (Global Options)).  Absolute mode generally should
; be used sparingly.
;
; Example of using GPR Uninitialized Data
;
;   GPR_VAR        UDATA
;   MYVAR1         RES        1      ; User variable linker places
;   MYVAR2         RES        1      ; User variable linker places
;   MYVAR3         RES        1      ; User variable linker places
;
;   ; Example of using Access Uninitialized Data Section (when available)
;   ; The variables for the context saving in the device datasheet may need
;   ; memory reserved here.
;   INT_VAR        UDATA_ACS
;   W_TEMP         RES        1      ; w register for context saving (ACCESS)
;   STATUS_TEMP    RES        1      ; status used for context saving
;   BSR_TEMP       RES        1      ; bank select used for ISR context saving
;
;*******************************************************************************

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 #define BANK0	BCF STATUS,RP0
 #define BANK1	BSF STATUS,RP0

 CBLOCK     H'20'
    COUNT0
    COUNT1
    COUNT2
 ENDC
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
        RETFIE
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START

    ; TODO Step #5 - Insert Your Program Here
	BANK1
	MOVLW	    H'00'           ; your instructions
	MOVWF	    TRISB           ; output

TOGGLE
	BANK0
	MOVLW	    H'55'
	MOVWF	    PORTB	    ; b'00001010
	CALL	    DELAY500ms
	
	MOVLW	    H'AA'
	MOVWF	    PORTB	    ; b'00001010
	CALL	    DELAY500ms
	
	MOVLW	    H'0F'
	MOVWF	    PORTB	    ; b'00001010
	CALL	    DELAY500ms
	
	MOVLW	    H'F0'
	MOVWF	    PORTB	    ; b'00001010
	CALL	    DELAY500ms
	GOTO	    TOGGLE
; ====================================================================
;	SUBROUTINE
; ====================================================================

DELAY_AUX1
	MOVLW	    D'300'
	MOVWF	    COUNT0
CLOOP
	NOP
	NOP
	DECFSZ	    COUNT0,1
	GOTO	    CLOOP
	RETURN 
; --------------------------------------------------------------------

DELAY_AUX2
	MOVLW	    D'200'
	MOVWF	    COUNT1
DLOOP
	NOP
	NOP
	DECFSZ	    COUNT1,1
	GOTO	    DLOOP
	RETURN 
; --------------------------------------------------------------------
; -- NEARLY 500 ms DELAY
DELAY500ms
	MOVLW	    D'100'
	MOVWF	    COUNT2
DLOOP
	CALL	    DELAY_AUX1
	CALL	    DELAY_AUX2
	DECFSZ	    COUNT2,1
	GOTO	    DLOOP
	
	RETURN
; ====================================================================
	END