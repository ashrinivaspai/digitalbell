org 00h
LJMP BEGIN
;===================================================================================

	SCL			EQU     0A0h	;IN THIS EXAMPLE I USED PORT 2.0
	SDA			EQU     0A1h	;AND PORT 2.1 FOR THE I2C LINES
					            ;YOU CAN CHANGE THEM TO WHATEVER ACCEPTABLE
	TIME_KEY	EQU	 	P3.3	;SET_TIME KEY
	BELL_KEY	EQU		P3.4	;SET_BELL KEY
	EMRG_KEY	EQU 	P3.5	;EMERGENCY KEY

;===================================================================================
;=====THE READ AND WRITE COMMANDS (0D0H AND 0D1H)

	CONT_BYTE_W		EQU	11010000B
	CONT_BYTE_R		EQU	11010001B

;===================================================================================

	ORG    0060H

;===================================================================================
;=====ADD_LOW IS THE DPL, THIS IS THE ADDRESS INISDE THE DS1307
;=====DAVAVA IS THE VARIABLE TO STORE DATA WHEN IT GETS BACK FROM THE DS1307
   
	DAVAVA          EQU 61H
	ADD_LOWL        EQU 60H
	memory_address1 EQU 62H
	memory_address2 EQU 63H
	eeprom_data     EQU 64H
;===================================================================================
;=====VARIABLES TO STORE THE TIME IN, COULD BE USED ALSO TO STORE DATA TO WRITE ON DS1307

	SEC			    EQU	50H
	MIN	            EQU	51H
	HOURS			EQU	52H
	DAY		    	EQU	67H
	COUNT			EQU	53H
	COUNT1			EQU 54H
	COUNT2          EQU 55H
	COUNT3          EQU 56H
	COUNT4          EQU 59H
	HOURS1			EQU 57H
	MIN1            EQU 58H
	COUNT5          EQU 64H
	COUNT7          EQU 6BH
	HOURS2			EQU	62H
	MINS2           EQU 63H
	DAYS            EQU 69H
	COUNT6          EQU 6AH
	COUNT8          EQU  68H
	COUNT9          EQU  66H
	PA1             EQU 7CH
	MEM_VAL			EQU	00H
	ORG    0100H

;============================================================================

BEGIN:
	LCALL INTI
	CLR SCL
	CLR	SDA
    CLR	P2.2
	CLR P3.7
    NOP
    SETB    SCL
    SETB	SDA
    NOP
	CLR 	MEM_VAL
	LCALL FIRST
	MOV DPTR, #WELCOME
    LCALL DISP_MSG
    LOOP:
	LCALL CHECK_KEY
	SJMP LOOP


INTI:	
	;******************************************
	;This module initializes the LD
	;DEPENDANCIES:CMD
	;******************************************
	MOV A,#3CH	;refer manual for the bit meaning
	LCALL CMD
	MOV A,#3CH
	LCALL CMD
	MOV A,#3CH
	LCALL CMD
	MOV A,#0CH
	LCALL  CMD
	MOV A,#06H
	LCALL  CMD
	MOV A,#01
	LCALL CMD
	RET


DISP_MSG:
	;*****************************************
	;This module is used to display the message
	;pointed by dptr on the dptr on the screen
	;DEPENDANCIES:DISPCH2, DELAY_1SEC
	;*****************************************
    LCALL DISPCH2
    LCALL DELAY_1SEC
	RET


FIRST:
	;*****************************************
	;This module moves the cursor back to first
	;line first position
	;******************************************
    MOV A,#80H
    LCALL CMD
    RET

SECOND:
	MOV A,#0C0H
	LCALL CMD
	RET



CMD:	
	;******************************************
	;This module gives cmd to LCD
	;cmd should be input through Acc
	;DEPENDANCIES: READY
	;******************************************
	LCALL READY
	MOV  80H,A
	CLR 0A5H	; low on RS
	CLR 0A6H
	SETB 0A7H	 ; high to low on En line
	CLR 0A7H
	RET


READY:	
	;******************************************
	;This module checks the LCD status
	;whether busy or not and returns from the 
	;module only if the busy flag is 0
	;******************************************
    CLR	0A7H		;read busy flag
	MOV	80H,#0FFH
	CLR	0A5H
	SETB	0A6H
	WAIT:	
		CLR	0A7H
		SETB	0A7H
		JB	87H,WAIT
	RET

WELCOME:   db '    WELCOME!   ',0fh
MESSAGE1: DB 'HH:MM DAY[0-7]', 0FH
MESSAGE2: DB '__:__ _', 0FH


DISPCH2:

	;******************************************
	;This module takes the starting add. of the 
	;string to be displayed in the DPTR and loops
	;till it find the string terminator #0FH
	;DEPENDANCIES:DISP
	;******************************************
	nop
	UP11:	
		CLR A
		MOVC A,@A+DPTR 	;use lookup table to get ascii character
		CJNE A,#0FH,SKIP
		RET		
	SKIP:	
		INC DPTR
		LCALL  DISP
		SJMP UP11



DISP:
	;********************************************
	;This module takes char. to be displayed in 
	; the Acc. 
	;*********************************************
	LCALL	READY	                            ;DISPLAY SINGLE CHAR
	MOV  80H, A
	SETB	0A5H	 ; high RS
	CLR	0A6H	;; low RW
	SETB	0A7H	; high to low En 
	CLR	0A7H
	RET


DELAY_1SEC:
	;********************************************
	; This module generates delay of 1sec
	;********************************************
	MOV R7,#10	
	HERE4:
		MOV R6,#0ffh                      ;delay routine for firing
		HERE31: 
				MOV     R5,#0ffH
				REPEAT1:
					DJNZ    R5,REPEAT1
				    DJNZ    R6,HERE31
				    DJNZ	R7,HERE4	
					RET

CHECK_KEY:
	JNB TIME_KEY, SET_TIME
	;JNB BELL_KEY, SET_BELL
	;JNB EMRG_KEY, EMERGENCY
	RET

KEYPD:   
	MOV R5,#00           
	MOV 90H,#0FEH   ;scan 1st row
	MOV A,90H
	XRL A,#0FEH
	JNZ ROW
	        
	MOV A,R5
	ADD A,#03H
	MOV R5,A
	      
	MOV 90H,#0FDH   ;scan 2nd row
	MOV A,90H
	XRL A,#0FDH
	JNZ ROW
	MOV A,R5
	ADD A,#03H
	MOV R5,A
	     
	MOV 90H,#0FBH   ;scan 3rd row
	MOV A,90H
	XRL A,#0FBH
	JNZ ROW
	MOV A,R5
	ADD A,#03H
	MOV R5,A

	MOV 90H,#0F7H   ;scan 4th row
	MOV A,90H
	XRL A,#0F7H
	JNZ ROW
	LJMP KEYPD
 
 	ROW:  
		MOV A,90H
     	ANL A,#0F0H
        SWAP A
	REDO:  
		RRC A
		JNC KEY
		INC R5
		SJMP REDO
	KEY:
		MOV 90H,#0F0H
		NOP
		NOP
		MOV	A,90H

		XRL	A,#0F0H
		JNZ	KEY
		MOV	A,R5
		MOV DPTR,#KEYCODE
		MOVC	A,@A+DPTR
		LCALL DELAY_1SEC
		;LCALL DELAY_1SEC

	RET
   
KEYCODE:DB '1','2','3','4','5','6','7','8','9','*','0','#'

SET_TIME:
	LCALL FIRST
	MOV DPTR, #MESSAGE1
	LCALL DISP_MSG
	LCALL SECOND			;MOVING CURSOR TO SECOND LINE
	MOV DPTR, #MESSAGE2
	LCALL DISP_MSG
	LCALL SECOND
	MOV A, #0FH
	LCALL CMD
	LCALL KEYPD
	LCALL DISP
	LCALL KEYPD
	LCALL DISP
	MOV A, #14H
	LCALL CMD
	LCALL KEYPD
	LCALL DISP
	LCALL KEYPD
	LCALL DISP
	MOV A, #14H
	LCALL CMD
	LCALL KEYPD
	LCALL DISP
	MOV A, #0CH
	LCALL CMD
	RET




END