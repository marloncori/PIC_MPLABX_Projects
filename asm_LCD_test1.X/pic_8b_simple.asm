;===============================================================================
; Program to exercise 4-bit PIC-to-LCD interface (a display driven by
; Hitachi HDD44780 controller is assumed.
;
; Code also assumes a 4 MHz clock. Delay routines must editted for faster 
; clock.
;
;    
;===============================================================================
; config bits 
#include "p16f887.inc"

; __config 0xE0D5
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF

; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF    
;===============================================================================    
; reserve 16 bytes for string buffer 
CBLOCK	    H'20'
    strData      ; addr from H'21' till H'30'
ENDC

CBLOCK	    H'31'
    count1
    count2
    count3
    pic_addr	; storage for start of text area
		; labeled strData in PIC RAM
    index	; index into text table also used for 
    store1      ; auxiliary store, local temp store
    store2	; temp store # 2
ENDC
    
; LCD related constants     
EN   EQU    RA1
RS   EQU    RA2   
RW   EQU    RA3
LN_1 EQU    H'80'
LN_2 EQU    H'C0' 
 
;===============================================================================
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
;===============================================================================
; add interrupts here if used
    ORG	    H'0004'
    RETFIE
;===============================================================================    
MAIN_PROG CODE                      ; let linker place main program

START
    BSF	    STATUS, RP0		   ; select bank 1  
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   TRISA		   ;   set port A pins as output
    MOVWF   TRISB		   ;   set port B pins as output
;------------------------------------------------------------    
    BCF	    STATUS, RP0		   ; select bank 0  
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   PORTA		   ;  clear port A
    MOVWF   PORTB		   ;  clear port B
;------------------------------------------------------------        
    BSF	    STATUS, RP1		   ; 
    BCF	    STATUS, RP0		   ; select bank 2
    BCF	    CM1CON0, C1ON	   ; turn off comparator 1
    BCF	    CM2CON0, C2ON	   ; turn off comparator 2
;--------------------------------------------------------------
    BSF	    STATUS,RP0		   ; select bank 3
    MOVLW   H'00'                  ; load W with zero to 
    MOVWF   ANSELH		   ; all ports as digital output
;--------------------------------------------------------------
				    ; wait and initiliaze HD447801
    CALL    Delay_5		   ; allow LCD time to start
    CALL    Delay_5
    CALL    LCD_Init
    CALL    Delay_5		   ; wait again
 ;--------------------------------------------------------------
    MOVLW   H'20'		   ; start address for buffer
    MOVWF   pic_addr		   ; to local variable

;===============================================================================
; FIRST LCD LINE
;===============================================================================    
; Store 16 blanks in PIC RAM, starting at address stored in pic_addr
    CALL    Blank_16
				; call procedure to store ASCII chars 
				; for message in text buffer
    MOVLW   D'3'		; offset into buffer
    CALL    MSU_Store
				; set DDRAM address to start of first ilne
    CALL    Line_1
				; call procedure to display 16 characters in LCD    
    CALL    Display_16

;===============================================================================
; SECOND LCD LINE
;===============================================================================
    CALL    Delay_5		; wait for termination
    CALL    Blank_16		; blank buffer
				; call procedure to store ASCII chars 
				; for message in text buffer
    MOVLW   D'1'		; offset into buffer
    CALL    Univ_Store
    CALL    Line_2		; DDRAM addres of LCD line 2
    CALL    Display_16
    
;===============================================================================    
; Done~!    
;===============================================================================
Loop:
    goto    Loop
    
;===============================================================================
; Subroutines    
;===============================================================================
LCD_Init:
    BCF	    PORTA, EN		; enable line low
    BCF	    PORTA, RS		; RS line low
    BCF	    PORTA, RW		; write mode
    CALL    Delay_125		; wait 125 us
;-------------------------------------------------------------------------------
    ; function set - 0 0 1 0 1 0 0 0 -> bit5: function set command 
    ;					bit4: interface width, 0: 4 bits, 1: 8 b
    ;					bit3: duty cycle select, 0: 1/8 or 1/11
    ;						1: 1/16
    ;					bit2: font select, 1 = 5x10 in 1/8 1/11
    ;							    0 = 1/16 dc
    CALL    Send_8		; four bit send routine
    ; set 4-bit mode command must be repeated
    MOVLW   H'28'
    CALL    Send_8
    ; display, cursor on -> 0 0 0 0 1 1 1 0 -> bit0: blink char 
    ;					bit1: cursor on/off
    ;					bit2: display on/off
    ;						1: 1/16
    ;					bit2: command bit
    MOVLW   H'0E'
    CALL    Send_8
    ; set entry mode -> 0 0 0 0 0 1 1 0 -> bit0: display shift 
    ;					bit1: increment mode, 1= L-to-R
    ;					bit2: command bit
    MOVLW   H'06'
    CALL    Send_8
    ; cursor display shift -> 0 0 0 1 0 1 0 0 ->  
    ;				    bit2, bit3: 00 - cursor shift left
    ;					    01 - cursor shift right
    ;					    10 - cursor, display shifted left
    ;					    11 - cursor, display shifted right					    
    MOVLW   H'14'
    CALL    Send_8
    ; clear display > 0 0 0 0 0 0 0 1 ->  
    ;				    bit0: command bit
    MOVLW   H'01'
    CALL    Send_8
    
    CALL    Delay_5		    ; test for busy
    RETURN
;-------------------------------------------------------------------------------    
Delay_125:
    ; procedure to delay 42 us
    MOVLW   D'42'		    ; repeat 42 machine cycles
    MOVWF   count1
D1: DECFSZ  count1, F
    GOTO    D1
    RETURN
;-------------------------------------------------------------------------------
Delay_5:        
    ; procedure to delay 5 ms
    MOVLW   D'41'		    ; repeat 42 machine cycles
    MOVWF   count2
D2: CALL    Delay_125		    ; wait
    DECFSZ  count2, F		    ; 40 times = 5 milliseconds
    GOTO    D2
    RETURN

;-------------------------------------------------------------------------------    
Pulse_EN:
    BSF	    PORTA, EN
    NOP
    BCF	    PORTA, EN
    RETURN
;-------------------------------------------------------------------------------
Display_16:
    CALL    Delay_5		; make sure it is not busy
    BCF	    PORTA, EN		; set up for data
    MOVLW   D'16'		; counter for 16 characters
    MOVWF   count3
    ; get display address from local variable pic_ad
    MOVF    pic_addr, W		; first display RAM address to W
    MOVWF   FSR			; W value to File Sekect Register
    
GetChar:
    MOVF    INDF, W		; get character from display RAM
				; locaotion pointed to by file select reg
    CALL    Send_8		; 4-bit interface routine
    ; test for sixteen characters displayed
    DECFSZ  count3, F		; decrement counter
    GOTO    NextChar	        ; skip this line when done
    RETURN
    
NextChar:    
    INCF    FSR, F		; bump pointer
    GOTO    GetChar
;-------------------------------------------------------------------------------
Send_8:
    ; send two nibbles in 4 bit mode
    ; 7, 6, 5, and 4 (high-order nibble) is sent frist 
    MOVWF   store1		; save original value
    CALL    Merge_4		; merge with port B
    MOVWF   PORTB		; W to port B
    CALL    Pulse_EN		; send data to LCD
    ; high nibble has been set at this point
    MOVF    store1, W		; recover byte into W
    SWAPF   store1, W		; swap nibbles in W
    CALL    Merge_4
    MOVWF   PORTB
    CALL    Pulse_EN		; send data to LCD
    CALL    Delay_125
    RETURN
;-------------------------------------------------------------------------------
    ; merge bits - the 4 high order bits of the value to be sent
    ; with the contents of portB so as to preserve the 4 low-bits in PORTB
    ; Logic: AND value with 1111 0000 mask
    ; Now low nibble in value and high nibble in portB are all 0 bits
    ;    value = vvvv 0000
    ;	 portB = 0000 bbbb
    ; OR value and portB resulting in:
    ;    value OR portB = vvvv bbbb
Merge_4:			; ANDing with 1 preserves the original value
    ANDLW	H'F0'		; ANDing with 0 clears the bit
    MOVWF	store2		; save result in variable
    MOVF	PORTB, W	; copy portB value into W reg
    ANDLW	H'0F'		; now clear high nibble in portb
				; and preserve low nibble in it
    IORWF	store2, W	; OR two operands and store result in W reg
    RETURN
	
;-------------------------------------------------------------------------------        
Blank_16:	
    MOVLW	D'16'
    MOVWF	count1		; set up counter
    MOVF	pic_addr, W	; first PIC RAM address
    MOVWF	FSR		; indexed addressing
    MOVLW	H'20'		; ASCII space character
StoreIt:
    MOVWF	INDF		; store blank char in PIC RAM
				; buffer using File Select Register
    DECFSZ	count1, F       ; Done?
    GOTO	incFSR          ; no
    RETURN			; yes
incFSR:
    INCF	FSR, F		; bump FSR to next buffer space
    GOTO	StoreIt
;-----------------------------------;-------------------------------------------    
; Set address register to LCD line2 |
;-----------------------------------;
Line_1:
    BCF		PORTA, EN	; enable line low
    BCF		PORTA, RS	; RS line low, set up for control
    CALL	Delay_5		; is it busy?
    ; set to second display line
    MOVLW	LN_1		; address and command bit
    CALL	Send_8		; 4-bit routine call
   
    BSF		PORTA, RS	; set up RS line for data
    CALL	Delay_5		; busy?
    RETURN
    
;-----------------------------------;
; Set address register to LCD line2 |
;-----------------------------------;
Line_2:
    BCF		PORTA, EN	; enable line low
    BCF		PORTA, RS	; RS line low, set up for control
    CALL	Delay_5		; is it busy?
    ; set to second display line
    MOVLW	LN_2		; address and command bit
    CALL	Send_8		; 4-bit routine call
  
    BSF		PORTA, RS	; set up RS line for data
    CALL	Delay_5		; busy?
    RETURN
  
;-------------------------------------------------------------------------------
; first text string procedure ;
;-----------------------------;    
MSU_Store:
    ; it stores in PIC RAM buffer the message contained in the
    ; code area labeled msg1
    ;
    ; ON ENTRY:
    ;	pic_addr holds address of text buffer
    ;	W register holds offset into storage area
    ;	msg1 is routine that returns the string characters
    ;   andiy a zero terminator
    ;   index is local variable that holds offset into text table
    ;   This var is also for temporary storage of offset into buffer
    ;
    ; ON EXIT:
    ;   text message stored in buffer
    MOVWF   index
    MOVF    pic_addr, W	    ; first display RAM address to W
    ADDWF   index, W	    ; add offset to address
    MOVWF   FSR		    ; copy W value to File Select Register
    ; initialize index for text string access
    MOVLW   0		    ; start at 0
    MOVWF   index	    ; store index in variable of the same name
    
GetMsgChar:
    CALL    msg1	    ; get a character from table
    ANDLW   0	    	    ; TEST for zero terminator
    BTFSC   STATUS, Z
    GOTO    endStr1	    ; end of string reached
    ; ASSERT: valid string character in W
    ;         store character in text buffer by FSR
    MOVWF   INDF	    ; store in buffer by FSR
    INCF    FSR, F	    ; increment buffer pointer
    ; restore table character counter forom variable
    MOVF    index, W	    ; copy value to W reg
    ADDLW   1		    ; bump to next character
    MOVWF   index	    ; store table index in varabiel
    GOTO    GetMsgChar	    ; continue
    
endStr1:
    RETURN
;-------------------------------------------------------------------------------
;  Routine for returning message stored in program area
;-------------------------------------------------------------------------------
msg1:
    ADDWF   PCL, F	    ; access table
    RETLW   'M'
    RETLW   'i'
    RETLW   'n'
    RETLW   'e'
    RETLW   's'
    RETLW   'o'
    RETLW   't'
    RETLW   'a'
    RETLW   0
    
;-------------------------;-----------------------------------------------------
; second string procedure ;
;-------------------------;
Univ_Store:
    ; process identical to procedure MSU_Store
    MOVWF   index	    ; store W value in index variable
    ; store base address of text buffer in FSR
    MOVF    pic_addr, 0	    ; first display RAM address to W
    ADDWF   index, 0	    ; add offset to address
    MOVWF   FSR		    ; copy W value to File Select Register
    
    ; initialize index for text string access
    MOVLW   0	    	    ; start at 0
    MOVWF   index
    
GetMsgChar2:
    CALL    msg2	    ; get a character from table
    ANDLW   H'0FF'    	    ; TEST for zero terminator
    BTFSC   STATUS, Z	    ; Test for zero flag
    GOTO    endStr2	    ; end of string reached
    ; ASSERT: valid string character in W
    ;         store character in text buffer by FSR
    MOVWF   INDF	    ; store in buffer by FSR
    INCF    FSR, F	    ; increment buffer pointer
    ; restore table character counter forom variable
    MOVF    index, W	    ; copy value to W reg
    ADDLW   1		    ; bump to next character
    MOVWF   index	    ; store table index in varabiel
    GOTO    GetMsgChar2	    ; continue
    
endStr2:
    RETURN
    
;-------------------------------------------------------------------------------
;  Routine for returning message stored in program area
;-------------------------------------------------------------------------------
msg2:
    ADDWF   PCL, F	    ; access table
    RETLW   'S'
    RETLW   't'
    RETLW   'a'
    RETLW   't'
    RETLW   'e'
    RETLW   H'20'	    ; ASCII for space
    RETLW   'M'
    RETLW   'a'
    RETLW   'n'
    RETLW   'k'
    RETLW   'a'
    RETLW   't'
    RETLW   'o'
    RETLW   0    
;===============================================================================    
    END
;===============================================================================    