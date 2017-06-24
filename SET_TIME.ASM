;**********************************************************************************************
;The following set of code is assembly level code for digital bell system
;Author: Sukesh Rao, Srinivas Pai, Sudesh Pai, Gayathri, Arpitha and 
;Version: 0.1
;Date: 
;**********************************************************************************************

org 00h
LJMP BEGIN

	SCL			EQU     0A0h	;IN THIS EXAMPLE I USED PORT 2.0
	SDA			EQU     0A1h	;AND PORT 2.1 FOR THE I2C LINES
					            ;YOU CAN CHANGE THEM TO WHATEVER ACCEPTABLE
	TIME_KEY	EQU	 	P3.3	;SET_TIME KEY
	BELL_KEY	EQU		P3.4	;SET_BELL KEY
	EMRG_KEY	EQU 	P3.5	;EMERGENCY KEY


;=====THE READ AND WRITE COMMANDS (0D0H AND 0D1H)

	CONT_BYTE_W		EQU	11010000B
	CONT_BYTE_R		EQU	11010001B

	ORG    0060H

	DAVAVA          EQU 61H
	ADD_LOWL        EQU 60H
	MEMORY_ADDRESS1 EQU 62H
	MEMORY_ADDRESS2 EQU 63H
	EEPROM_DATA     EQU 64H

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
	COUNT8          EQU 68H
	COUNT9          EQU 66H
	PA1             EQU 7CH
	MEM_VAL			EQU	00H

	ORG    0100H

;**********************************************************************************************
;									CODE BEGINS
;**********************************************************************************************

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
    ;LCALL CREATE_PASSWORD
	CLR 	MEM_VAL 	;
	LCALL FIRST 		;MOVE THE CURSOR TO THE BEGINNING OF FIRST LINE
	MOV DPTR, #WELCOME 	;DISPLAY NICE WELCOME MESSAGE
    LCALL DISPCH2
    LOOP:				;BEGINNING OF ACTUAL 'MAIN' LOOP
	LCALL CHECK_KEY 	;CHECK FOR THE PRESS OF THE SET_TIME, SET_BELL, EMERGENCY_KEY
	SJMP LOOP

;**********************************************************************************************
;This module initializes the LD
;DEPENDANCIES:CMD
;**********************************************************************************************
INTI:	
	MOV A,#3CH			;refer manual for the bit meaning
	LCALL CMD
	MOV A,#3CH 			;DONT KNOW WHY SAME COMMAND IS REPEATER FOR 3 TIMES
	LCALL CMD 	
	MOV A,#3CH			;MAY BE TO BE SUPER SURE ABOUT EXECUTION OF IT ;)
	LCALL CMD
	MOV A,#0CH
	LCALL  CMD
	MOV A,#06H
	LCALL  CMD
	MOV A,#01
	LCALL CMD
	RET

;**********************************************************************************************
;This module is used to display the message pointed by DPTR on the DPTR on the screen
;DEPENDANCIES:DISPCH2, DELAY_1SEC
;**********************************************************************************************
DISP_MSG:
    LCALL DISPCH2
    LCALL DELAY_1SEC
	RET

;**********************************************************************************************
;This module moves the cursor back to first line first position
;**********************************************************************************************
FIRST:
    MOV A,#80H			;look for the these codes in the LCD datasheet
    LCALL CMD
    RET
;SIMILARLY FOR SECOND LINE
SECOND:
	MOV A,#0C0H 	
	LCALL CMD
	RET

;***********************************************************************************************
;This module gives cmd to LCD. Command to be passed to the LCD should be placed in Acc.
;To send a command a high to low signal is sent to the enable pin while the command to be
;sent is place on the data line and the register select(RS) pin is held low.
;DEPENDANCIES: READY
;***********************************************************************************************
CMD:	
	LCALL READY
	MOV  80H,A
	CLR 0A5H			; low on RS
	CLR 0A6H
	SETB 0A7H	 		; high to low on En line
	CLR 0A7H
	RET

;***********************************************************************************************
;This module checks the LCD status whether busy or not and returns from the module only if 
;the busy bit/pin/line is 0
;***********************************************************************************************
READY:	
    CLR	0A7H			;read busy flag
	MOV	80H,#0FFH
	CLR	0A5H
	SETB	0A6H
	WAIT:	
		CLR	0A7H
		SETB	0A7H
		JB	87H,WAIT
	RET


;***********************************************************************************************
;										LOOK-UP TABLES
;***********************************************************************************************
WELCOME:   db '    WELCOME!',0fh
MESSAGE1: DB '     HH:MM', 0FH
MESSAGE2: DB '     __:__', 0FH
MESSAGE3: DB '    DAY[1-7]', 0FH
ERROR_MSG: DB 'INVALID NUMBER', 0FH
WEEKDAY: DB '000','MON','TUE','WED', 'THU', 'FRI', 'SAT', 'SUN' 
PASSWORD: DB '1234',0FH
KEYCODE:DB '1','2','3','4','5','6','7','8','9','*','0','#'
MESSAGE4: DB ' ENTER PASSWORD',0FH
MESSAGE5: DB '  SET TIME IS', 0FH
AUTH_MSG: DB ' INCORRECT  PIN', 0FH
EMERGENCY_MSG: DB '   EMERGENCY', 0FH
;***********************************************************************************************
;									 END of LOOK-UP TABLES
;***********************************************************************************************



;***********************************************************************************************
;This module takes the starting address of the string to be displayed in the DPTR and loops
;till it find the string terminator #0FH and also turns the cursor OFF
;Parameters:DPTR holds the starting address of the string
;Return:
;DEPENDANCIES:DISP,CMD
;***********************************************************************************************
DISPCH2:
	nop
	MOV A, #0CH 			;TURNING OFF THE CURSOR
	LCALL CMD
	UP11:	
		CLR A
		MOVC A,@A+DPTR 		;use lookup table to get ascii character
		CJNE A,#0FH,SKIP 	;loop till 0xfh is encountered
		RET		
	SKIP:	
		INC DPTR
		LCALL  DISP 		
		SJMP UP11

;***********************************************************************************************
;This module is used to display the 3 lettered day in the LCD give the number of 
;corresponding day in Acc.
;Parameters:Acc. holds the day number
;Return:None
;DEPENDANCIES:DISP
;***********************************************************************************************
DISP_DAY:
	PUSH 01H
	UP12:
		MOV B,A 			;just saving the content of Acc.
		MOV R1, #04H  		;counter
		MOV DPTR, #WEEKDAY 	
		UP13:
			MOV A,B 		;you might assume that why to again load to Acc. but after first iteration this mov operation is neccessary
			MOVC A,@A+DPTR 	;use lookup table to get ascii character
			DJNZ R1,SKIP1
			POP 01H
			RET		
	SKIP1:	
		INC DPTR
		LCALL  DISP
		SJMP UP13

;************************************************************************************************
;This module takes character to be displayed in the Acc. and displys it on LCD(only one char)
;Parameters:Acc.
;Return:None
;DEPENDANCIES: READY
;************************************************************************************************
DISP:
	LCALL READY	
	MOV 80H, A 				;80h is the address of the pin on 8051 which is connected to the 
	SETB 0A5H	 			; high RS
	CLR	0A6H				; A6h is the R/WBAR
	SETB 0A7H				; high to low En 
	CLR	0A7H
	RET

;************************************************************************************************
; This module generates delay of 1sec
;************************************************************************************************
DELAY_1SEC:
	MOV R7,#10	
	HERE4:
		MOV R6,#0ffh        ;delay routine for firing
		HERE31: 
				MOV     R5,#0ffH
				REPEAT1:
					DJNZ    R5,REPEAT1
				    DJNZ    R6,HERE31
				    DJNZ	R7,HERE4	
					RET

DELAY_500MSEC: 				;these push instruction will ensure that everything will work fine by saving the 
	PUSH 07H 				;... value of the register used by the function that called it
	PUSH 06H
	PUSH 04H
	MOV R7,#5	
	HERE41:
		MOV R6,#0ffh        ;delay routine for firing
		HERE311: 
				MOV     R4,#0ffH
				REPEAT11:
					DJNZ    R4,REPEAT11
				    DJNZ    R6,HERE311
				    DJNZ	R7,HERE41	
				    POP 04H
				    POP 06H
				    POP 07H
					RET

;*************************************************************************************************
;This module is used to recognize the hitting of the key. As the JNB performs the sjmp little
;technique is used to avoid the out of range jmp situation.
;Parameters:None
;Return:None
;DEPENDANCIES: SETT_TIME, SETT_BELL, EMMERGENCY
;*************************************************************************************************
CHECK_KEY:
	JNB TIME_KEY, SETT_TIME	;PLEASE NOTICE THE DOUBLE 'T'
	CHECKING_BELL:
	;JNB BELL_KEY, SET_BELL
	JNB EMRG_KEY, EMMERGENCY
	RET

;*************************************************************************************************
;Following three labels are just used to redirect the control to appropriate locations
;these are needed in order to avoid the below listed two reasons
;*************************************************************************************************

SETT_TIME:
	LCALL SET_TIME 			;WE REQUIRE THIS MANIPULATION BECAUSE
							;1)JNB INTERNALLY SJMPs AND SET_TIME IS OUT OF IT'S RANGE				
							;2)ITS JMP AND NOT CALL AND IN FUTURE WHILE ADDING NEW FEATURES IT MAY CAUSE BUG
	SJMP CHECKING_BELL 
;SETT_BELL:
	;LCALL SET_BELL
	;RET
EMMERGENCY:
	LCALL EMERGENCY
	RET

;*************************************************************************************************
;This module is used to read the key hit
;Parameters:None
;Return:Acc
;DEPENDANCIES:DELAY_1SEC
;*************************************************************************************************

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
		LCALL DELAY_500MSEC
		MOV 90H,#0F0H
		NOP
		NOP
		MOV	A,90H

		XRL	A,#0F0H
		JNZ	KEY
		MOV	A,R5
		MOV DPTR,#KEYCODE
		MOVC	A,@A+DPTR

	RET

;*************************************************************************************************
;This module returns the validity of the entered PIN in the Acc. 
;Parameters:None
;Return: Acc.
;DEPENDANCIES: FIRST, READ_PASSWORD, SECOND, DISPCH2, KEYPD, CMD, DISP
;*************************************************************************************************

VER_PASSWD:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #MESSAGE4 	
	LCALL DISPCH2			;CAN BE REPLACED WITH DISP_MSG(LATTER WILL ADD 1Sec DELAY)
	LCALL SECOND
	MOV R0, #06H
	MOV A, #14H
	LOOP5:
	LCALL CMD
	DJNZ R0, LOOP5
	MOV A, #0EH 			;BLINKING CURSOR
	LCALL CMD
	LCALL READ_PASSWORD		;NOW 4 CHARACTER PIN WILL BE LOCATED FROM 54H ONWARDS
	MOV R0,#54H				;POINTING THE BEGINNING OF THE PIN TO R0						
	MOV FLAG,#00H
	MOV R1,#04H				;COUNTER
	LOOP4:
	MOV B, @R0				
	LCALL KEYPD
	CJNE A, #2AH, N103 		;IF EQUAL THEN CLEAR EVERYTHING
	SJMP VER_PASSWD
	N103:
	CJNE A,B, SET_FLAG 		;IF NOT EQUAL THEN SET FLAG
	N102:
	MOV A, #2AH 				;WE HAVE TO DISPLAY * AND NOT THE DIGIT THAT WAS ENTERED
	LCALL DISP
	INC R0 					;POINT TO NEXT DIGIT ON RAM
	DJNZ R1, LOOP4
	MOV A, FLAG 			;AS PROMISED RETURN SHOULD BE IN Acc.
	MOV B, #00H
	CJNE A, B, AUTH_FAIL
	RET
	AUTH_FAIL:
		MOV A,#01H
		LCALL CMD
		MOV DPTR, #AUTH_MSG
		LCALL DISP_MSG
		SJMP VER_PASSWD 		;AGAIN GO BACK TO FIRST STEP

SET_FLAG:
	MOV FLAG, #0FFH
	SJMP N102

EMERGENCY:
	LCALL VER_PASSWD
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #EMERGENCY_MSG
	LCALL DISPCH2
	;DO WHATEVER NEEDS TO BE DONE
	RET


;*************************************************************************************************
;This module sets the time and day. PIN is required to set the time. if incorrect password is 
;entered then user will again be asked to enter password and only reset breaks the loop
;Parameters:None
;Return:None(affects the RTC time)
;DEPENDANCIES: VER_PASSWD, FIRST, SECOND, DISP_MSG, DISP_DAY, CMD, KEYPD, DISP, ERROR, ERROR_DAY
;   			DELAY_1SEC
;*************************************************************************************************

SET_TIME:
	LCALL VER_PASSWD 		;ENTER PASSWORD VER MODULE
	N101:
	MOV A, #01H
	LCALL CMD
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
	CJNE A, #23H, N1		;COMPARING THE VALUE OF KEY WITH #
	SJMP ERROR
	N1:
	CJNE A, #2AH, N2 		;COMPARING THE VALUE OF KEY WITH *
	LJMP N101
	N2:
	MOV R1,A
	CLR C
	SUBB A, #33H 			;i.e., IF ENTERED NUMBER IS GREATER THAN 2(EXAMPLE IS 30 HOURS)
	JNC ERROR
	CLR C
	MOV A, R1
	SUBB A, #30H 			;ASCII ADJUSTMENTS
	SWAP A 					;EX: 31H-30H=01H AFTER SWAPPING IT WILL BE 10H
	MOV R1, A 				;SAVING THE VALUE OF A
	LCALL KEYPD
	LCALL DISP
	CJNE A, #23H, N3		;COMPARING THE VALUE OF KEY WITH #
	JMP ERROR
	N3:
	CJNE A, #2AH, N4		;COMPARING THE VALUE OF KEY WITH *
	JMP N101
	N4:
	CLR C
	SUBB A, #30H			;ADJUSTMENTS
	ADD A,R1 				;EXAMPLE CONTINUED: NOW PREVIOUS 10H IS ADDED WITH LETS SAY 2H GIVES 12H WHICH IS PASSED TO RTC IF ITS VALID
	MOV R1,A 				;AGAIN SAVING
	CLR C
	SUBB A,#25H				;CHECKING IF THE HOUR VALUE IS GRATER THAN 24
	JNC ERROR 
	MOV A, #14H				;SHIFT CURSOR RIGHT ONCE TO AVOID THE COLON
	LCALL CMD
	MOV ADD_LOWL, #02H
	MOV DAVAVA, R1
	LCALL WRITE_BYTE
	SJMP N100
	;START OF ERROR HANDLING

	ERROR:
		LCALL FIRST
		MOV DPTR, #ERROR_MSG
		LCALL DISP_MSG
		LCALL DELAY_1SEC
		LCALL DELAY_1SEC
	JMP N101

	;STARTING TO READ THE MINUTES 
	N100:
	LCALL KEYPD
	LCALL DISP
	CJNE A, #23H, N5		;COMPARING THE VALUE OF KEY WITH #
	SJMP ERROR
	N5:
	CJNE A, #2AH, N6		;COMPARING THE VALUE OF KEY WITH *
	LJMP N101
	N6:
	MOV R0,A
	CLR C
	SUBB A, #36H 			;i.e., IF ENTERED NUMBER IS GREATER THAN 5(EXAMPLE IS 60 MINUTES)
	JNC ERROR
	MOV A, R0
	CLR C 
	SUBB A, #30H 			;AGAIN SAME PROCEDURES AS DONE WITH HOURS
	SWAP A
	MOV R0, A 
	LCALL KEYPD
	LCALL DISP
	CJNE A, #23H, N7		;COMPARING THE VALUE OF KEY WITH #
	SJMP ERROR
	N7:
	CJNE A, #2AH, N8		;COMPARING THE VALUE OF KEY WITH *
	LJMP N101
	N8:
	CLR C 
	SUBB A, #30H
	ADD A, R0
	MOV R0,A
	MOV A, #0CH 			;TURNING OFF THE CURSOR
	LCALL CMD
	LOOP2:
	LCALL KEYPD
	CJNE A, #2AH, N9
	JMP N101
	N9:
	CJNE A, #23H, LOOP2
	;HERE ADD ROUTINE TO PASS CMD TO RTC TO SET TIME
	MOV ADD_LOWL, #01H
	MOV DAVAVA, R0
	LCALL WRITE_BYTE
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
		MOV R0, #5H 			;SHIFTING THE CURSOR TO THE MIDDLE
		MOV A, #14H 			
		LOOP6:
		LCALL CMD
		DJNZ R0, LOOP6
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
		PUSH 01H				;THE DISP_DAY FUNCTION WIHICH WE WILL USE LATER WILL USE R1 AS ONE OF ITS VARIABLES
		CLR C  					;... SO WE HAVE TO USE PUSH TO SAVE R1
		SUBB A, #38H 			;ERROR CHECKING BY CHECKING IF THE ANSWER COMES OUT NEGATIVE
		JNC ERROR_DAY 			;EX: INPUT IS 37H(VALID) SO 37H-38H=-1H HENCE C=1. HENCE VALID
		CLR C 					;EX: IF INPUT IS 39H(INVALID) SO ASNWER IS 1H AND C=0. HENCE INVALID
		MOV A, #14H				;SHIFTING RIGHT CURSOR TO GIVE SPACE
		LCALL CMD 
		MOV A,R1 				;RESTORING THE VALUE OF A
		SUBB A, #30H 			;GETTING ACTUAL VALUE FROM ASCII VALUE
		MOV B, #3H 				;IN THE LOOK-UP TABLE NAMED 'WEEKDAY' EACH WEEKDAY LENGTH IS 3
		MUL AB 					;HENCE TO GET ACTUAL OFFSET WE HAVE TO MULTIPLY BASE BY 3 AND ADD IT TO DPTR
		LCALL DISP_DAY			;DISPLAYING THE DAY AS SOON AS WE PRESS THE KEY
		MOV A, #0CH
		LCALL CMD
		LOOP3: 					;THIS LOOP IS FOR USER TO ENTER 'ENTER KEY'
		LCALL KEYPD				;INPUTTING THE ENTER KEY OR CLEAR KEY
		CJNE A, #2AH, N13 		;IF USER ENTERS * WHOLE SCREEN IS RESET
		JMP SET_DAY
		N13:
		CJNE A, #23H, LOOP3 	;IF USER ENTERS # IT IS CONSIDERED AS 'ENTER KEY'
		POP 01H 				;01H STANDS FOR R1
		MOV A, R1
		CLR C 
		SUBB A, #30H 			;MOV THIS ACC VALUE TO RTC
		;WRITE ROUTINE TO SEND DAY TO RTC
		MOV ADD_LOWL, #03H
		MOV DAVAVA, A
		LCALL WRITE_BYTE
		SJMP END_SETTIME 		;JUMP TO END OF THIS ROUTINE
	;START OF ERROR HANDLING

	ERROR_DAY:
		LCALL FIRST 			;MOVING THE CURSOR TO FIRST LINE AS THE ERROR HAS TO BE PRINTED IN FIRST LINE
		MOV A, #0CH 			;TURNING OFF THE CURSOR
		LCALL CMD
		MOV DPTR, #ERROR_MSG
		LCALL DISP_MSG
		LCALL DELAY_1SEC
		LCALL DELAY_1SEC
		JMP SET_DAY

	END_SETTIME:
		MOV A, #01H
		LCALL CMD
		MOV DPTR, #MESSAGE5
		LCALL DISP_MSG
		LCALL SECOND
		LCALL READ_RTC
		PUSH 01H
		MOV R1, #03H
		MOV A, #14H
		LOOP7:
		LCALL CMD
		DJNZ R1, LOOP7
		POP 01H
		LCALL DISP_TIME


	RET

;*************************************************************************************************
;This module is used to write data to EEPROM. User has to pass the starting address of the data 
;through the R0 register, location on the EEPROM through the DPTR and the count of the data through
;COUNT9. Rest everything is handled by this module
;DEPENDANCIES:EEPROM_START, EEPROM_DELAY, SEND_DATA, EEPROM_STOP
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
;Parameters:COUNT9, DPTR, R1
;Return:data on RAM location pointed by R1
;DEPENDANCIES:EEPROM_START, EEPROM_DELAY,SEND_DATA, EEPROM_STOP
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
;Parameters:None
;Return:None
;DEPENDANCIES:None
;*************************************************************************************************

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

;*************************************************************************************************
;This module is used to mark stop of EEPROM data flow
;stop bit is low to high transition on SDA while SCL is maintained high
;Parameters:None
;Return:None
;DEPENDANCIES:None
;*************************************************************************************************
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

;*************************************************************************************************
;This module sends the data to the EEPROM through Acc.
;this module rotates left the data through carry and puts the carry to the SDA pin
;Parameters:Acc
;Return:None(writes data onto EEPROM)
;DEPENDANCIES:EEPROM_DELAY, CLOCK
;*************************************************************************************************
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

;*************************************************************************************************
;This module reads the data from the EEPROM into the RAM location 3CH
;Parameters: None
;Return: data in 3CH
;DEPENDANCIES:CLOCK
;*************************************************************************************************
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

;*************************************************************************************************
;This module generates clock for EEPROM communication
;Parameters:None
;Return:None
;DEPENDANCIES:None
;*************************************************************************************************
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

;*************************************************************************************************
;This module generates a delay of 3ms
;Parameters:None
;Return:None
;DEPENDANCIES:None
;*************************************************************************************************
EEPROM_DELAY:      
	MOV 33H,#11      ;DELAY OF 3 MSEC 
	EEPROM_DELAY_1:
		MOV 32H,#0FFH
		DJNZ 32H,$
		DJNZ 33H,EEPROM_DELAY_1
		RET

;*************************************************************************************************
;This module reads the stored PIN from EEPROM and loads it to RAM location 54H
;Parameters:None
;Return:PIN on RAM location 0x54
;DEPENDANCIES:READ_DATA
;*************************************************************************************************
READ_PASSWORD:
	PUSH 01H
	MOV R1, #54H
	MOV DPTR, #7001H
	MOV COUNT9, #4H
	LCALL READ_DATA
	POP 01H
	RET

CREATE_PASSWORD:

	MOV COUNT9, #04H
	MOV DPTR,#PASSWORD
	MOV R0,#50H
	UP2:
	CLR A
	MOVC A, @A+DPTR
	MOV @R0, A
	INC R0
	INC DPTR
	DJNZ COUNT9, UP2
	MOV DPTR, #7001H
	MOV R0, #50H
	MOV COUNT9, #04H
	LCALL WRITE_DATA
	RET

;*************************************************************************************************
;This module writes the values to RTC
;Parameters: data to be loaded in DAVAVA, address of register in ADD_LOWL
;Return:None
;DEPENDANCIES:LOOP_BYTE
;*************************************************************************************************
WRITE_BYTE:            
	CLR     SDA                   ;start bit
	CLR     SCL
	MOV     A,#CONT_BYTE_W        ;send control byte
	LCALL   LOOP_BYTE
	SETB    SDA
	SETB    SCL
	CPL		0B0H
	JB      SDA,WRITE_BYTE        ;loop until busy
	CLR     SCL
	MOV     A,ADD_LOWL             ;send address low
	LCALL   LOOP_BYTE
	SETB    SDA
	SETB    SCL
	JB      SDA,WRITE_BYTE        ;loop until busy
	CLR     SCL
	MOV     A,DAVAVA                ;send DAVAVA
	LCALL   LOOP_BYTE
	SETB    SDA
	SETB    SCL
	JB      SDA,WRITE_BYTE        ;loop until busy
	CLR     SDA
	CLR     SCL
	SETB    SCL                   ;stop bit
	SETB    SDA
	RET

;*************************************************************************************************
;
;*************************************************************************************************
LOOP_BYTE:             
	PUSH    02H
	MOV     R2,#08H
	LOOP_SEND:            
		RLC     A
		MOV     SDA,C
		SETB    SCL
		CLR     SCL
		DJNZ    R2,LOOP_SEND
	POP     02H
	RET

;*************************************************************************************************
;
;*************************************************************************************************
READ_BYTE:             
	CLR     SDA                   ;start bit
	CLR     SCL
	MOV     A,#CONT_BYTE_W        ;send control byte
	LCALL   LOOP_BYTE
	SETB    SDA
	SETB    SCL
	JB      SDA,READ_BYTE         ;loop until busy
	CLR     SCL
	MOV     A,ADD_LOWL             ;send address low
	LCALL   LOOP_BYTE
	SETB    SDA
	SETB    SCL
	JB      SDA,READ_BYTE         ;loop until busy
	CLR     SCL

	SETB    SCL
	SETB    SDA
	CLR     SDA                   ;start bit
	CLR     SCL
	MOV     A,#CONT_BYTE_R        ;send control byte
	LCALL   LOOP_BYTE
	SETB    SDA
	SETB    SCL
	JB      SDA,READ_BYTE         ;loop until busy
	CLR     SCL
	LCALL   LOOP_READ
	SETB    SDA
	SETB    SCL
	CLR     SCL

	SETB    SCL                   ;stop bit
	SETB    SDA
	RET

;*************************************************************************************************
;This module reads the 
;*************************************************************************************************

LOOP_READ:             
	PUSH   02H
    MOV    R2,#08H
	LOOP_READ1:            
		SETB   SCL
		MOV    C,SDA
		CLR    SCL
		RLC    A
		DJNZ   R2,LOOP_READ1
	MOV    DAVAVA,A
	POP    02H
	RET

;***************************************
READ_RTC:
	MOV     ADD_LOWL,#00h
	LCALL   READ_BYTE
	MOV 	SEC,DAVAVA
	LCALL	I2C_STOP						   
	MOV     ADD_LOWL,#01h
	LCALL   READ_BYTE
	MOV 	MIN,DAVAVA
	LCALL	I2C_STOP
	MOV     ADD_LOWL,#02h
	LCALL   READ_BYTE
	MOV 	HOURS,DAVAVA
	LCALL	I2C_STOP
	 MOV     ADD_LOWL,#03h
	LCALL   READ_BYTE
	MOV 	DAY,DAVAVA
	LCALL	I2C_STOP
    RET

UNPACK:
	MOV A,40h
	ANL	A,#0FH
	ADD	A,#30h
	MOV	R2,A
	MOV A,40h	
	SWAP	A
	ANL	A,#0FH
	ADD	A,#30H
	MOV	R3,A
	RET

;****************************************************************

DISP_TIME:
	PUSH 40h
	MOV 40h, HOURS
	LCALL UNPACK
	MOV A, R3
	LCALL DISP
	MOV A, R2
	LCALL DISP
	MOV A, #3AH
	LCALL DISP
	MOV 40h, MIN
	LCALL UNPACK
	MOV A, R3
	LCALL DISP
	MOV A, R2
	LCALL DISP
	MOV A, #20H
	LCALL DISP
	MOV A, DAY
	MOV B, #3H 				;IN THE LOOK-UP TABLE NAMED 'WEEKDAY' EACH WEEKDAY LENGTH IS 3
	MUL AB 					;HENCE TO GET ACTUAL OFFSET WE HAVE TO MULTIPLY BASE BY 3 AND ADD IT TO DPTR
	LCALL DISP_DAY	
	POP 40h
	RET

I2C_Stop:
	CLR       SDA
	SETB      SCL
	NOP
	SETB      SDA
	RET
END

