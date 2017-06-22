;***********************************************************************************
;The following set of code is assembly level code for digital bell system
;Author: Sukesh Rao, Srinivas Pai, Gayathri, Sudesh Pai, Arpitha and 
;Version: 0.1
;Date: 
;***********************************************************************************

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
	MEMORY_ADDRESS1 EQU 62H
	MEMORY_ADDRESS2 EQU 63H
	EEPROM_DATA     EQU 64H
;===================================================================================
;=====VARIABLES TO STORE THE TIME IN, COULD BE USED ALSO TO STORE DATA TO WRITE ON DS1307

	SEC			    EQU	50H
	MIN	            EQU	51H
	HOURS			EQU	52H
	DAY		    	EQU	67H
	COUNT			EQU	53H
	;COUNT1			EQU 54H
	;COUNT2         EQU 55H
	;COUNT3         EQU 56H
	;COUNT4         EQU 57H
	HOURS1			EQU 59H
	MIN1            EQU 58H
	FLAG            EQU 64H
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

;*************************************************************************************
;									CODE BEGINS
;*************************************************************************************
BEGIN:
	LCALL INTI 			;CALL THE INITIALIZATION MODULE
	CLR SCL				;SCL: SERIAL CLOCK LINE ->MEANS THE CLOCK INPUT FOR I2C
	CLR	SDA 			;SDA: SERIAL DATA I/P & O/P ->MEANS THE INPUR AND OUTPUT LINE
    CLR	P2.2 			;
	CLR P3.7 			;SOME UNECESSARY STATEMENTS
    NOP 				;ANOTHER UNECESSARY STATEMENT
    SETB    SCL 		; 	""		""
    SETB	SDA
    NOP
	CLR 	MEM_VAL 	;
	LCALL FIRST 		;MOVE THE CURSOR TO THE BEGINNING OF FIRST LINE
	MOV DPTR, #WELCOME 	;DISPLAY NICE WELCOME MESSAGE
    LCALL DISP_MSG
    LOOP:				;BEGINNING OF ACTUAL 'MAIN' LOOP
	LCALL CHECK_KEY 	;CHECK FOR THE PRESS OF THE SET_TIME, SET_BELL, EMERGENCY_KEY
	SJMP LOOP

;**************************************************************************************
;This module initializes the LD
;DEPENDANCIES:CMD
;AUTHOR: SUKESH RAO
;**************************************************************************************
INTI:	
	MOV A,#3CH	;refer manual for the bit meaning
	LCALL CMD
	MOV A,#3CH 	;DONT KNOW WHY SAME COMMAND IS REPEATER FOR 3 TIMES
	LCALL CMD 	
	MOV A,#3CH	;MAY BE TO BE SUPER SURE ABOUT EXECUTION OF IT ;)
	LCALL CMD
	MOV A,#0CH
	LCALL  CMD
	MOV A,#06H
	LCALL  CMD
	MOV A,#01
	LCALL CMD
	RET

;****************************************************************************************
;This module is used to display the message pointed by DPTR on the DPTR on the screen
;DEPENDANCIES:DISPCH2, DELAY_1SEC
;****************************************************************************************
DISP_MSG:
    LCALL DISPCH2
    LCALL DELAY_1SEC
	RET

;*****************************************************************************************
;This module moves the cursor back to first line first position
;*****************************************************************************************
FIRST:
    MOV A,#80H			;look for the these codes in the LCD datasheet
    LCALL CMD
    RET
;SIMILARLY FOR SECOND LINE
SECOND:
	MOV A,#0C0H 	
	LCALL CMD
	RET

;******************************************************************************************
;This module gives cmd to LCD. Command to be passed to the LCD should be placed in Acc.
;DEPENDANCIES: READY
;******************************************************************************************
CMD:	
	LCALL READY
	MOV  80H,A
	CLR 0A5H	; low on RS
	CLR 0A6H
	SETB 0A7H	 ; high to low on En line
	CLR 0A7H
	RET

;******************************************************************************************
;This module checks the LCD status whether busy or not and returns from the module only if 
;the busy bit/pin/line is 0
;******************************************************************************************
READY:	
    CLR	0A7H		;read busy flag
	MOV	80H,#0FFH
	CLR	0A5H
	SETB	0A6H
	WAIT:	
		CLR	0A7H
		SETB	0A7H
		JB	87H,WAIT
	RET


;******************************************************************************************
;										LOOK-UP TABLES
;******************************************************************************************
WELCOME:   db '    WELCOME!   ',0fh
MESSAGE1: DB '     HH:MM      ', 0FH
MESSAGE2: DB '     __:__      ', 0FH
MESSAGE3: DB 'DAY[1-7]', 0FH
ERROR_MSG: DB 'INVALID NUMBER', 0FH
WEEKDAY: DB '000','MON','TUE','WED', 'THU', 'FRI', 'SAT', 'SUN' 
PASSWORD: DB '1234',0FH
KEYCODE:DB '1','2','3','4','5','6','7','8','9','*','0','#'
MESSAGE4: DB ' ENTER PASSWORD ',0FH
AUTH_MSG: DB ' INCORRECT  PIN ', 0FH
;*******************************************************************************************
;									 END of LOOK-UP TABLES
;*******************************************************************************************



;*******************************************************************************************
;This module takes the starting address of the string to be displayed in the DPTR and loops
;till it find the string terminator #0FH
;DEPENDANCIES:DISP
;*******************************************************************************************
DISPCH2:
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

;*******************************************************************************************
;This module is used to display the 3 lettered day in the LCD give the number of 
;corresponding day in Acc.
;DEPENDANCIES:DISP
;*******************************************************************************************
DISP_DAY:
	UP12:
		MOV B,A
		MOV R1, #04H
		MOV DPTR, #WEEKDAY
		UP13:
			MOV A,B
			MOVC A,@A+DPTR 	;use lookup table to get ascii character
			DJNZ R1,SKIP1
			RET		
	SKIP1:	
		INC DPTR
		LCALL  DISP
		SJMP UP13

;********************************************
;This module takes char. to be displayed in 
; the Acc. 
;*********************************************
DISP:
	LCALL	READY	                            ;DISPLAY SINGLE CHAR
	MOV  80H, A
	SETB	0A5H	 ; high RS
	CLR	0A6H	;; low RW
	SETB	0A7H	; high to low En 
	CLR	0A7H
	RET

;********************************************
; This module generates delay of 1sec
;********************************************
DELAY_1SEC:
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

SET_TIME: LCALL	
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

	RET

VER_PASSWD:
	LCALL FIRST 			;MOVING THE CURSOR TO FIRST POSITION OF FIRST LINE
	MOV DPTR, #MESSAGE4 	
	LCALL DISPCH2
	LCALL SECOND
	MOV A, #0FH 			;BLINKING CURSOR
	LCALL CMD
	LCALL READ_PASSWORD		;NOW 4 CHARACTER PIN WILL BE LOCATED FROM 54H
	MOV R0,#54H
	MOV B, @R0
	MOV FLAG,#00H
	MOV R1,#04H
	LOOP4:
	LCALL KEYPD
	CJNE A,B, SET_FLAG
	MOV A, '*'
	LCALL DISP
	DJNZ R1, LOOP4

	RET

SET_FLAG:
	MOV FLAG, #0FFH
	RET




SET_TIME:
	LCALL VER_PASSWD
	MOV B, #0FFH
	MOV A, FLAG
	CJNE A, B, AUTH_FAIL
	SJMP N101
	AUTH_FAIL:
		MOV DPTR, #AUTH_MSG
		LCALL DISP_MSG
		SJMP SET_TIME
	N101:
	LCALL FIRST
	MOV DPTR, #MESSAGE1
	LCALL DISP_MSG
	LCALL SECOND			;MOVING CURSOR TO SECOND LINE
	MOV DPTR, #MESSAGE2
	LCALL DISP_MSG
	LCALL SECOND
	MOV A, #0FH 			;TURNING ON THE CURSOR
	LCALL CMD
	MOV R1, #5H 			;SHIFTING CURSOR 5 TIMES
	LOOP1: MOV A, #14H	
	LCALL CMD
	DJNZ R1, LOOP1
	;STARTING TO READ THE VALUE OF HOUR
	LCALL KEYPD
	LCALL DISP
	CJNE A, #30H, N1
	SJMP N
	N1:CJNE A, #31H, N2
	SJMP N
	N2:CJNE A, #32H,ERROR
	N:
	CLR C
	SUBB A, #30H
	SWAP A 					;ADJUSTMENTS
	MOV R1, A 				;SAVING THE VALUE OF A
	LCALL KEYPD
	LCALL DISP
	CJNE A, #23H, N3		;COMPARING THE VALUE OF KEY WITH #
	JMP ERROR
	N3:
	CJNE A, #2AH, N4		;COMPARING THE VALUE OF KEY WITH *
	JMP ERROR
	N4:
	CLR C
	SUBB A, #30H			;ADJUSTMENTS
	ADD A,R1
	SUBB A,#25H				;CHECKING IF THE HOUR VALUE IS GRATER THAN 24
	JNC ERROR
	MOV A, #14H				;SHIFT CURSOR RIGHT ONCE TO AVOID THE COLON
	LCALL CMD

	SJMP N100
	
	;START OF ERROR HANDLING

	ERROR:
		LCALL FIRST
		MOV A, #0CH 		;TURNING OFF THE CURSOR
		LCALL CMD
		MOV DPTR, #ERROR_MSG
		LCALL DISP_MSG
		LCALL DELAY_1SEC
		LCALL DELAY_1SEC
	JMP SET_TIME

	;STARTING TO READ THE MINUTES 
	N100:
	LCALL KEYPD
	LCALL DISP
	CJNE A, #23H, N5		;COMPARING THE VALUE OF KEY WITH #
	SJMP ERROR
	N5:
	CJNE A, #2AH, N6		;COMPARING THE VALUE OF KEY WITH *
	SJMP ERROR
	N6:
	SUBB A, #36H
	JNC ERROR
	CLR C
	LCALL KEYPD
	LCALL DISP
	CJNE A, #23H, N7		;COMPARING THE VALUE OF KEY WITH #
	SJMP ERROR
	N7:
	CJNE A, #2AH, N8		;COMPARING THE VALUE OF KEY WITH *
	SJMP ERROR
	N8:
	MOV A, #0CH 			;TURNING OFF THE CURSOR
	LCALL CMD
	LOOP2:
	LCALL KEYPD
	CJNE A, #2AH, N9
	JMP SET_TIME
	N9:
	CJNE A, #23H, LOOP2

	;STARTING TO READ THE WEEK DAY
	SET_DAY:
		MOV A, #1H 				;CLEARING THE SCREEN TO BEGIN FRESH
		LCALL CMD
		MOV DPTR, #MESSAGE3
		LCALL DISP_MSG
		LCALL SECOND			;BRINGING THE CURSOR TO SECOND LINE FIRST POSITION
		LCALL CMD
		MOV A, #0FH 			;TURNING ON THE CURSOR
		LCALL CMD
		LCALL KEYPD				;READ A CHARACTER
		LCALL DISP
		CJNE A, #23H, N10		;COMPARING THE VALUE OF KEY WITH #
		SJMP ERROR_DAY
		N10:
		CJNE A, #2AH, N11		;COMPARING THE VALUE OF KEY WITH *
		SJMP ERROR_DAY
		N11:
		CJNE A, #30H, N12		;COMPARING THE VALUE OF KEY WITH 0 AS VALID CHARACTERS ARE ONLY 1-7
		SJMP ERROR_DAY
		N12:
		MOV R1,A 				;SAVING THE VALUE OF A
		SUBB A, #38H 			;ERROR CHECKING BY CHECKING IF THE ANSWER COMES OUT NEGATIVE
		JNC ERROR_DAY 			;EX: INPUT IS 37H(VALID) SO 37H-38H=-1H HENCE C=1. HENCE VALID
		CLR C 					;EX: IF INPUT IS 39H(INVALID) SO ASNWER IS 1H AND C=0. HENCE INVALID
		MOV A, #0CH 			;TURNING OFF THE CURSOR
		LCALL CMD
		MOV A, #14H				;SHIFTING RIGHT CURSOR TO GIVE SPACE
		LCALL CMD 
		MOV A,R1 				;RESTORING THE VALUE OF A
		SUBB A, #30H 			;GETTING ACTUAL VALUE FROM ASCII VALUE
		MOV B, #3H 				;IN THE LOOK-UP TABLE NAMED 'WEEKDAY' EACH WEEKDAY LENGTH IS 3
		MUL AB 					;HENCE TO GET ACTUAL OFFSET WE HAVE TO MULTIPLY BASE BY 3 AND ADD IT TO DPTR
		LCALL DISP_DAY			;DISPLAYING THE DAY AS SOON AS WE PRESS THE KEY

		LOOP3: 					;THIS LOOP IS FOR USER TO ENTER 'ENTER KEY'
		LCALL KEYPD				;INPUTTING THE ENTER KEY OR CLEAR KEY
		CJNE A, '*', N13 		;IF USER ENTERS * WHOLE SCREEN IS RESET
		JMP SET_DAY
		N13:
		CJNE A, '#', LOOP3 		;IF USER ENTERS # IT IS CONSIDERED AS 'ENTER KEY'
		SJMP END_SETTIME 		;JUMP TO END OF THIS ROUTINE
	;START OF ERROR HANDLING

	ERROR_DAY:
		LCALL first 			;MOVING THE CURSOR TO FIRST LINE AS THE ERROR HAS TO BE PRINTED IN FIRST LINE
		MOV A, #0CH 			;TURNING OFF THE CURSOR
		LCALL CMD
		MOV DPTR, #ERROR_MSG
		LCALL DISP_MSG
		LCALL DELAY_1SEC
		LCALL DELAY_1SEC
		JMP SET_DAY

	END_SETTIME:

	RET

;*************************************************************************************************
;This module is used to write data to EEPROM. User has to pass the starting address of the data 
;through the R0 register, location on the EEPROM through the DPTR and the count of the data through
;COUNT9. Rest everything is handled by this module
;DEPENDANCIES:EEPROM_START, EEPROM_DELAY, SEND_DATA, EEPROM_STOP
;AUTHOR: SUKESH RAO
;*************************************************************************************************
WRITE_DATA:     
	CALL EEPROM_START
	MOV A,#0A0H          
	CALL SEND_DATA
	MOV A,DPL          		;LOCATION ADDRESS
	CALL SEND_DATA
	MOV A,DPH         		;LOCATION ADDRESS
	CALL SEND_DATA
	MOV EEPROM_DATA,@R0
	MOV A,EEPROM_DATA      	;DATA TO BE SEND
	CALL SEND_DATA
	CALL EEPROM_STOP
	LCALL EEPROM_DELAY
	LCALL EEPROM_DELAY
	CALL EEPROM_START
	MOV A,#0A0H          
	CALL SEND_DATA
	MOV A,DPL         		 ;LOCATION ADDRESS
	CALL SEND_DATA
	MOV A,DPH          		 ;LOCATION ADDRESS
	CALL SEND_DATA
	MOV EEPROM_DATA,@R0
	MOV A,EEPROM_DATA        ;DATA TO BE SEND
	CALL SEND_DATA
	CALL EEPROM_STOP
	LCALL	EEPROM_DELAY
	LCALL	EEPROM_DELAY
	INC DPTR
	INC R0
	DJNZ COUNT9,WRITE_DATA 
	RET   

;*************************************************************************************************
;This module is used to read the data from EEPROM. Location on the EEPROM is passed through the 
;DPTR and data is returned to the RAM in the location determined by the R1 and number of bytes read 
;is determined by the COUNT9
;DEPENDANCIES:EEPROM_START, EEPROM_DELAY,SEND_DATA, EEPROM_STOP
;AUTHOR: SUKESH RAO
;*************************************************************************************************
READ_DATA:      
	CALL EEPROM_START
	MOV A,#0A0H
	CALL SEND_DATA
	MOV A,DPL         		 ;LOCATION ADDRESS
	CALL SEND_DATA
	MOV A,DPH         		 ;LOCATION ADDRESS
	CALL SEND_DATA
	CALL EEPROM_START
	MOV A,#0A1H
	CALL SEND_DATA
	CALL GET_DATA
	CALL EEPROM_STOP
	LCALL	EEPROM_DELAY
	LCALL	EEPROM_DELAY
	INC DPTR
	MOV @R1,3CH				 ; STORE
	INC R1				
	DJNZ COUNT9,READ_DATA
	RET

;*************************************************************************************************
;This module is used to initialize the eeprom line
;start bit is high to low transition on the sda while the scl is high
;hence the flow of the module is 
;high sda -- high scl -- hold the scl high -- make sda low -- hold scl high --  make scl low
;author: sukesh rao
;**************************************************************************************************

EEPROM_START:  
	SETB SDA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	SETB SCL
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLR SDA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLR SCL
	RET


EEPROM_STOP:    
	CLR SDA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	SETB SCL
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	SETB SDA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLR SCL
	RET
	;=========================================================
SEND_DATA:     
	MOV R7,#00H
	SEND:      
		RLC A
		MOV SDA,C
		CALL CLOCK
		INC R7
		CJNE R7,#08,SEND
	SETB  SDA
	NOP
	NOP	
	NOP
	NOP
	NOP	
	NOP
	SETB SCL
	JB SDA,$
	CALL EEPROM_DELAY
	CLR SCL
	CALL EEPROM_DELAY
	RET
	;=========================================================
GET_DATA:
	SETB SDA   
	MOV R7,#00H
	CLR A
	GET:    
		SETB SCL
		NOP
		NOP	
		MOV C,SDA
		RLC A
		CLR SCL
		INC R7
		CJNE R7,#08,GET
	SETB SDA
	CALL CLOCK
	MOV 3CH,A
	RET
	;=========================================================
CLOCK:         
	SETB SCL
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLR SCL
	RET
EEPROM_DELAY:      
	MOV 33H,#11      ;DELAY OF 3 MSEC 
	EEPROM_DELAY_1:
		MOV 32H,#0FFH
		DJNZ 32H,$
		DJNZ 33H,EEPROM_DELAY_1
		RET

READ_PASSWORD:
	MOV R1, #54H
	MOV DPTR, #7001H
	MOV COUNT9, #4H
	LCALL READ_DATA
	RET

END

