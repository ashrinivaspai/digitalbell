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
	TEMP_DAY		EQU	53H
	FLAG1           EQU 6FH
	BELL_HOUR		EQU	62H
	BELL_MIN     	EQU 63H
	BELL_DURATION 	EQU 64H
	CURRENT_DAY     EQU 65H
	DURATION        EQU 6AH
	COUNT9          EQU 66H
	SERIAL          EQU 7CH
	MEM_VAL			EQU	00H
	MODE 			EQU 7DH
	TEMP_SERIAL 	EQU 43H
	TEMP_HOUR 		EQU 41H
	TEMP_MIN	 	EQU 42H

	ORG    0100H

;**********************************************************************************************
;									CODE BEGINS
;**********************************************************************************************

BEGIN:
	LCALL INTI    		;CALL THE INITIALIZATION MODULE
	CLR SCL				;SCL: SERIAL CLOCK LINE ->MEANS THE CLOCK INPUT FOR I2C
	CLR	SDA 			;SDA: SERIAL DATA I/P & O/P ->MEANS THE INPUR AND OUTPUT LINE
    CLR	P2.2 			;
	CLR P3.7 			;SOME UNECESSARY STATEMENTS
    NOP 				;ANOTHER UNECESSARY STATEMENT
    SETB    SCL 		; 	""		""
    SETB	SDA
    NOP
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #INI_MSG
	LCALL DISPCH2
	LCALL DELAY_1SEC
	LCALL DELAY_1SEC
	LCALL KEYPD
	CJNE A, #39H, WELCOME
	LCALL NEW_PASSWORD
	WELCOME:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #WELCOME_MSG 	;DISPLAY NICE WELCOME MESSAGE
    LCALL DISPCH2
    LCALL DELAY_1SEC
    MOV CURRENT_DAY, #00H
    ;LCALL CREATE_DATA
    LOOP:				;BEGINNING OF ACTUAL 'MAIN' LOOP
    LCALL DETERMINE_MODE
    MOV MODE, #01H
	LCALL CHECK_KEY 	;CHECK FOR THE PRESS OF THE SET_TIME, SET_BELL, EMERGENCY_KEY
	LCALL CHECK_ALARM 	;CHECK WHETHER WE NEED TO RING THE BELL
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

CLEAR:
	MOV A,#01H
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
    CLR	0A7H			;read busy FLAG1
	MOV	80H,#0FFH
	CLR	0A5H
	SETB	0A6H
	WAIT:	
		CLR	0A7H
		SETB	0A7H
		JB	87H,WAIT
	RET

DETERMINE_MODE:
	MOV DPTR, #7FFFH
	MOV R1, #54H
	MOV COUNT9, #03H
	LCALL READ_DATA
	MOV MODE, 54H
	RET
;***********************************************************************************************
;										LOOK-UP TABLES
;***********************************************************************************************
WELCOME_MSG:   db '    WELCOME!',0fh
MESSAGE1: DB '     HH:MM', 0FH
MESSAGE2: DB '     __:__', 0FH
MESSAGE3: DB '    DAY[1-7]', 0FH
ERROR_MSG: DB 'INVALID NUMBER', 0FH
WEEKDAY: DB '000','MON','TUE','WED', 'THU', 'FRI', 'SAT', 'SUN' 
PASSWORD: DB '1234',0FH
KEYCODE:DB '1','2','3','4','5','6','7','8','9','*','0','#'
AUTH_MSG: DB '  ENTER THE PIN',0FH
MESSAGE5: DB '  TIME IS SET!', 0FH
AUTH_FAIL_MSG: DB ' INCORRECT  PIN', 0FH
EMERGENCY_MSG: DB '   EMERGENCY', 0FH
BELL_MESSAGE: DB ' SELECT OPTION',0FH
BELL_OPTIONS: DB '1)NEW  2)EDIT',0FH
BELL_NUMBER_MSG: DB 'BELL. NO.[01-',0FH
NO_BELL: DB '  NO BELLS SET',0FH
;TEMP: DB 12H,23H,01H
BELL_ACK_1: DB '  BELL IS SET!',0FH
SERIAL_NO_1: DB ' BELL NO. IS ', 0FH
NEW_BELL_MSG: DB ' NEW BELL TIME', 0FH
EDIT_DURATION: DB 'DURATION[IN SEC]', 0FH
DURATION_MSG: DB '[1-9]: ', 0FH
CONFIRM: DB '    CONFIRM!',0FH
SECONDS: DB 'SEC', 0FH
PASSMSG:db'PRESS 1:MODE',0fh
PASSMSG1:db '      2:PASSWORD',0fh
CONFIRM_MSG1:db'CONFIRM PASSWORD',0fh
CONFIRM_MSG2:db'NEW PASSWORD SET',0fh
MODE_MSG1:db'PRESS 1:MODE 1',0fh
MODE_MSG2:db'	   2:MODE 2',0fh
PASSMSG2:db'SET NEW PASSWORD',0fh

;TEMP: DB 0H, 0H, 0H, 0H, 0H, 0H, 0H
;*************************************************************************************************
;									 END of LOOK-UP TABLES
;*************************************************************************************************

;*************************************************************************************************
;
;										DATA MANIPULATION
;												&
; 										DISPLAY FUNCTIONS
;
;*************************************************************************************************


;*************************************************************************************************
;This module will convert 8-bit hexadecimal number to corresponding BCD equivalent MSB of 3-dig
;BCD will be placed in R2 and other two will be in 40H.
;Parameters:hex number in Acc
;Return:msb in r2 and 2-dig lsb IN 40H(and Acc)
;DEPENDANCIES:None
;*************************************************************************************************
HEX_BCD:
	MOV B,#100
	DIV AB
	MOV R2, A
	MOV A, B
	MOV B, #10
	DIV AB
	SWAP A
	ADD A, B
	MOV 40H, A
	RET
;*************************************************************************************************
;This module is used to convert from BCD to HEX. 
;Parameters:data to be converted in the Acc
;Return: converted data in Acc
;DEPENDANCIES:None
;*************************************************************************************************
BCD_HEX:
	PUSH ACC
	ANL A, #0FH
	MOV R2, A
	POP ACC
	ANL A, #0F0H
	SWAP A
	MOV B, #0AH 
	MUL AB
	ADD A, R2
	RET

;*************************************************************************************************
;This module will prepare the BCD data to display on the LCD
;Parameters:40h
;Return:msb in R3 and lsb in R2
;DEPENDANCIES:None
;*************************************************************************************************
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
		CJNE A,#0FH,SKIP111 ;loop till 0xfh is encountered
		RET		
	SKIP111:	
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
	MOV B, #3H 				;IN THE LOOK-UP TABLE NAMED 'WEEKDAY' EACH WEEKDAY LENGTH IS 3
	MUL AB 					;HENCE TO GET ACTUAL OFFSET WE HAVE TO MULTIPLY BASE BY 3 AND ADD IT TO DPTR
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

;*************************************************************************************************
;This module outputs the 2-digit BCD number on the LCD
;Parameters:number to be displayed in 40H
;Return:None
;DEPENDANCIES:UNPACK, DISP
;*************************************************************************************************

DISP_2DIG_NO:
	LCALL UNPACK
	MOV A, R3
	LCALL DISP
	MOV A, R2
	LCALL DISP
	RET
;*************************************************************************************************
;This module will display the VALUES PRESENT IN HOURS AND MIN VARIABLE on LCD in format HH:mm DAY
;Parameters:HOURS, MIN
;Return:None
;DEPENDANCIES:DISP_DAY, DISP, UNPACK
;*************************************************************************************************
DISP_TIME:
	MOV 40h, HOURS
	LCALL DISP_2DIG_NO
	MOV A, #':'
	LCALL DISP
	MOV 40h, MIN
	LCALL DISP_2DIG_NO
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

DELAY_500MSEC:
	PUSH 07H 	;these push instruction will ensure that everything will work fine by saving the 			
				;... value of the register used by the function that called it
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
	;SJMP SETT_TIME
	CHECKING_BELL:
	JNB BELL_KEY, SETT_BELL
	CHECKING_EMERGENCY:
	JNB EMRG_KEY, EMMERGENCY
	END_CHECK_KEY:
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
SETT_BELL:
	LCALL SET_BELL

	SJMP CHECKING_EMERGENCY
EMMERGENCY:
	LCALL EMERGENCY
	SJMP END_CHECK_KEY


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


CHECK_ALARM:
	LCALL READ_RTC
	MOV A, DAY
	CJNE A, 65H ,  LOAD_NEXT_BELL
	PROCEED_TO_CMP_TIME:
		MOV CURRENT_DAY, DAY
		MOV A, HOURS
		CJNE A, 62H, END_OF_THIS_MODULE
		MOV A, MIN
		CJNE A, 63H, END_OF_THIS_MODULE
		LCALL RING_BELL
	END_OF_THIS_MODULE:
	RET
LOAD_NEXT_BELL:
	MOV CURRENT_DAY, DAY
	MOV BELL_HOUR, HOURS
	MOV BELL_MIN, MIN
	LCALL LOAD_NEXT_BELL_MODULE
	SJMP PROCEED_TO_CMP_TIME
	
RING_BELL:
	;MAKE HIGH ON SOME PIN
	LCALL LOAD_NEXT_BELL_MODULE

	RET

LOAD_NEXT_BELL_MODULE:
	MOV DPTR, #00H
	MOV A, CURRENT_DAY
	MOV R4, MODE
	CJNE R4, #02H, ADD_NOTHING__
	ADD A, #07H
	ADD_NOTHING__:
	MOV DPL, A
	MOV COUNT9, #01H
	MOV R1, #7CH 		;LOCATION OF SERIAL VARIABLE
	MOV R0, #00H
	LCALL READ_DATA  	;AFTER EXECUTION OF THIS INSTRUCTION SERIAL WILL HAVE MAX COUNT OF BELL FOR THAT DAY
	MOV DPTR, #00H
	MOV A, CURRENT_DAY
	CJNE R4, #02H, ADD_NOTHING__1
	ADD A, #07H
	ADD_NOTHING__1:
	MOV DPH, A
	NEXT_ITERATION:
	INC R0
	MOV A, #03H 	 	;VALUES START FROM 0X0*00H
	MOV B, R0
	MUL AB
	MOV DPL, A
	MOV COUNT9, #03H
	MOV R1, 41H 		;41H=TEMP_HOUR AND SO ON
	LCALL READ_DATA 	
	MOV A, 41H
	MOV B, BELL_HOUR
	CLR C
	SUBB A, B
	JC END_OF_ROUTINE
	JNZ POTENTIAL_CANDIDATE
	CLR C
	MOV A, 42H
	MOV B, BELL_MIN
	SUBB A, B
	JC END_OF_ROUTINE
	JZ END_OF_ROUTINE
	POTENTIAL_CANDIDATE:
		CJNE R0, #01H, CHECK_WITH_PREVIOUS_POTENTIAL_CANDIDATE
		SJMP UPDATE_POTENTIAL_CANDIDATE
		CHECK_WITH_PREVIOUS_POTENTIAL_CANDIDATE:
			MOV A, 44H 	;previous potential value of hour
			MOV B, 41H 	;current value of the hour copied from EEPROM
			CLR C
			SUBB A, B
			JNC UPDATE_POTENTIAL_CANDIDATE
			JNZ END_OF_ROUTINE
			CLR C
			MOV A, 45H
			MOV B, 42H
			SUBB A, B
			JC END_OF_ROUTINE
			JZ END_OF_ROUTINE
		UPDATE_POTENTIAL_CANDIDATE:
			MOV 44H, 41H
			MOV 45H, 42H
			MOV 46H, 43H
	END_OF_ROUTINE:
	MOV A, R0
	CJNE A, 7CH, NEXT_ITERATION
	MOV BELL_HOUR, 44H
	MOV BELL_MIN, 45H
	MOV BELL_DURATION, 46H
	RET 
;*************************************************************************************************
;This module returns the validity of the entered PIN in the Acc. 
;Parameters:None
;Return: Acc.
;DEPENDANCIES: FIRST, READ_PASSWORD, SECOND, DISPCH2, KEYPD, CMD, DISP
;*************************************************************************************************

VER_PASSWORD:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #AUTH_MSG
	LCALL DISPCH2
	LCALL SECOND
	MOV R0, #06H
	MOV A, #14H
	LOOP5:
	LCALL CMD
	DJNZ R0, LOOP5
	MOV A, #0EH
	LCALL CMD
	LCALL READ_PASSWORD
	MOV R0, #54H
	MOV FLAG1, #00H
	MOV R1, #4H
	LOOP4:
	MOV B, @R0
	LCALL KEYPD
	CJNE A, #'*', N103
	SJMP VER_PASSWORD
	N103:
	CJNE A, B, SET_FLAG
	N102:
	MOV A, #'*'
	LCALL DISP
	INC R0
	DJNZ R1,LOOP4
	MOV A, FLAG1
	MOV B, #00H
	CJNE A, B, AUTH_FAIL
	RET
	AUTH_FAIL:
		MOV A, #01H
		LCALL CMD
		MOV DPTR, #AUTH_FAIL_MSG
		LCALL DISP_MSG
		SJMP VER_PASSWORD
	SET_FLAG:
		MOV FLAG1, #0FFH
		SJMP N102		

EMERGENCY:
	LCALL VER_PASSWORD
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #EMERGENCY_MSG
	LCALL DISPCH2
	;DO WHATEVER NEEDS TO BE DONE
	RET


SET_BELL:
	;LCALL VER_PASSWORD
	SET_BELL_VERIFIED:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #BELL_MESSAGE
	LCALL DISPCH2
	LCALL SECOND
	MOV DPTR, #BELL_OPTIONS
	LCALL DISPCH2
	MOV A, #0EH
	LCALL CMD
	LOOP8: 
		LCALL KEYPD
		MOV B, #31H
		CJNE A, B, N14
		JMP NEW_BELL
		N14:
		MOV B, #32H
	CJNE A, B, LOOP8

	EDIT_BELL:
	LCALL INPUT_DAY  	;now accumulator will contain the day value
	MOV TEMP_DAY, A
	;Load number of bells available for that day
	MOV DPTR, #00H
	MOV R4, MODE
	MOV R1, #50H
	MOV COUNT9, #01H
	MOV A, TEMP_DAY
	CJNE R4, #02H, ITS_MODE_1
	ADD A, #07H
	ITS_MODE_1:
	MOV DPL, A
	LCALL READ_DATA
	MOV R1, #50H
	MOV A, @R1
	
	MOV B, #00H
	CJNE A, B, HAS_BELL_ENTRY	;if its non zero then that means it has entry
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #NO_BELL
	LCALL DISPCH2
	LCALL DELAY_1SEC
	SJMP SET_BELL_VERIFIED  	;if its zero then give user chance to make an entry

	HAS_BELL_ENTRY:
		MOV A, TEMP_DAY
		MOV DPTR, #00H
		MOV R4, MODE
		CJNE R4, #02H, IT_IS_MODE_1
		ADD A, #07H
		IT_IS_MODE_1:
		MOV DPL, A
		MOV R1, #50H
		MOV COUNT9, #01H
		LCALL READ_DATA
		MOV R1, #50H
		MOV A, @R1
		PUSH ACC
		MOV A, #01H 				;clear screen
		LCALL CMD
		MOV DPTR, #BELL_NUMBER_MSG 	;display number of bells i.e., max count
		LCALL DISPCH2
		POP ACC 					;will contain max serial number
		LCALL HEX_BCD 				;converts to bcd and output will be in acc[lower two dig] and r2[only for 3 dig BCD]
		PUSH ACC 					;saving the bcd converted value	
		LCALL DISP_2DIG_NO 			
		MOV A, #']'
		LCALL DISP 					
		LCALL SECOND
		MOV A, #0FH
		LCALL CMD
		POP ACC 					;copy the value of max. serial number in ACC
		MOV 40H, ACC
		LCALL UNPACK 				;now r2 and r3 will contain ascii value of the bcd number
		MOV B, #04H
		MOV A, #14H
		LOOP9:
		LCALL CMD
		DJNZ B, LOOP9
		LCALL KEYPD
		LCALL DISP
		CJNE A, #'*', CONTINUE_1
		SJMP HAS_BELL_ENTRY
		CONTINUE_1:
		CJNE A, #'#', CONTINUE_2
		LCALL UNIVERSAL_ERROR_MODULE
		SJMP HAS_BELL_ENTRY
		CONTINUE_2:
		CLR C
		PUSH ACC 					;contains the 1st number in acsii mode 
		SUBB A, R3 					;r3= msb of the max serial number in ascii
		JC NEXT_ENTRY               
		JZ NEXT_ENTRY
		LCALL UNIVERSAL_ERROR_MODULE
		SJMP HAS_BELL_ENTRY
		NEXT_ENTRY:
		POP ACC 					;contains ascii value of first endtered key
		SUBB A, #30H 
		SWAP A 
		MOV R1, A  					;now r1 will contain msb of the entered number
		PUSH 01H 					;save this value
		LCALL KEYPD
		LCALL DISP
		CLR C
		CJNE A, #'*', CONTINUE_3
		JMP HAS_BELL_ENTRY
		CONTINUE_3:
		CJNE A, #'#', CONTINUE_4
		LCALL UNIVERSAL_ERROR_MODULE
		JMP HAS_BELL_ENTRY
		CONTINUE_4:
		CLR C 
		PUSH ACC
		SUBB A, R2
		JC DONE_ENTERING_SERIAL
		JZ DONE_ENTERING_SERIAL
		LCALL UNIVERSAL_ERROR_MODULE
		JMP HAS_BELL_ENTRY
		DONE_ENTERING_SERIAL:
		POP ACC 				;now A will contain the second digit in ascii format
		CLR C
		SUBB A, #30H
		POP 01H
		ADD A, R1 				;now acc will contain the user entered serial in bcd mode
		LCALL BCD_HEX
		MOV SERIAL, A 			;saving the value of serial safely in the RAM
		MOV DPH, TEMP_DAY
		MOV R4, MODE
		MOV A, DPH
		CJNE R4, #02H, IT_IS_MODE_1_
		ADD A, #07H
		IT_IS_MODE_1_:
		MOV DPH, A
		MOV B, #03H
		MUL AB
		MOV DPL,A
		MOV R1, #54H
		MOV COUNT9, #03H
		LCALL READ_DATA
		MOV HOURS, 54H
		MOV MIN, 55H
		MOV A, #' '
		LCALL DISP
		LCALL DISP_TIME
		WAIT_FOR_ENTER: 		;WAITING FOR USER TO CONFIRM THAT HE/SHE WANTS THIS BELL ITSELF
		LCALL KEYPD
		CJNE A, #2AH, N15
		JMP HAS_BELL_ENTRY 
		N15:
		CJNE A, #23H, WAIT_FOR_ENTER
		MOV B, #01H
		LCALL INPUT_HOUR_MINUTE	;READ THE TIME
		LCALL INPUT_DURATION
		LCALL CONFIRM_BELL
		WAIT_FOR_ENTER_KEY_1:
			LCALL KEYPD
			CJNE A, #2AH, N17
			JMP EDIT_BELL
			N17:
			CJNE A, #23H, WAIT_FOR_ENTER_KEY_1
		MOV A, #01H
		LCALL CMD
		MOV DPTR, #BELL_ACK_1
		LCALL DISPCH2
		MOV DPH, TEMP_DAY
		MOV A, DPH
		MOV R4, MODE
		CJNE R4, #02H, ITS_MODE_1__
		ADD A, #07H
		ITS_MODE_1__:
		MOV DPH, A
		MOV A, SERIAL
		MOV B, #03H
		MUL AB
		MOV DPL, A
		LCALL SAVE_BELL
		RET

	NEW_BELL:
		LCALL INPUT_DAY
		MOV TEMP_DAY, A
		MOV B, #01H
		LCALL INPUT_HOUR_MINUTE
		LCALL INPUT_DURATION
		MOV DPTR, #00H
		MOV R4, MODE
		MOV A, TEMP_DAY
		CJNE R4, #02H, ADD_NOTHING 	;THIS MEANS MODE 1
		ADD A, #7H
		ADD_NOTHING:
		MOV COUNT9, #01H
		MOV R1, #54H
		MOV DPL, A
		LCALL READ_DATA
		MOV SERIAL, 54H 		;if needed, add a comp. instruction to limit max count
		;MOV A, 54H
		;LCALL HEX_BCD
		LCALL CONFIRM_BELL
		WAIT_FOR_ENTER_KEY_2:
		LCALL KEYPD
		CJNE A, #2AH, N18
		SJMP NEW_BELL
		N18:
		CJNE A, #23H, WAIT_FOR_ENTER_KEY_2
		MOV R4, MODE
		MOV A, TEMP_DAY
		CJNE R4, #01H, ITS_MODE_2
		SJMP NOTHING_TO_ADD
		ITS_MODE_2:
		ADD A, #07H
		NOTHING_TO_ADD:
		MOV DPH, A
		MOV A, SERIAL
		INC A
		MOV B, #03H
		MUL AB
		MOV DPL, A
		LCALL SAVE_BELL
		MOV A, #01H
		LCALL CMD
		LCALL FIRST
		MOV DPTR, #BELL_ACK_1
		LCALL DISP_MSG
		LCALL SECOND
		MOV DPTR, #SERIAL_NO_1
		LCALL DISP_MSG
		MOV A, SERIAL
		INC A
		LCALL HEX_BCD
		LCALL DISP_2DIG_NO
		MOV A, SERIAL
		INC A
		MOV 54H, A
		MOV R0, #54H
		MOV COUNT9, #01H
		MOV DPTR, #00H
		MOV R4, MODE
		MOV A, TEMP_DAY
		CJNE R4, #01H, ADD_SOMETHING
		SJMP ADD_NOTHING_1
		ADD_SOMETHING:
		ADD A, #07H
		ADD_NOTHING_1:
		MOV DPL, A
		LCALL WRITE_DATA
		MOV DPTR, #0001H
		MOV COUNT9, #01H
		MOV R1, #54H
		LCALL READ_DATA
		MOV A, 54H
		INC A
		MOV 54H, A
		MOV R0, #54H
		MOV COUNT9, #01H
		MOV DPTR, #0001H
		LCALL WRITE_DATA
		LCALL DELAY_1SEC
		LCALL DELAY_1SEC
		RET


UNIVERSAL_ERROR_MODULE:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #ERROR_MSG
	LCALL DISP_MSG
	LCALL DELAY_1SEC
	LCALL DELAY_1SEC
	RET

SAVE_BELL:
	MOV COUNT9, #03H
	MOV 54H, HOURS
	MOV 55H, MIN
	MOV 56H, DURATION
	MOV R0, #54H
	LCALL WRITE_DATA
	RET

CONFIRM_BELL:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #CONFIRM
	LCALL DISPCH2
	LCALL SECOND
	LCALL DISP_TIME
	MOV A, #14H
	LCALL CMD
	MOV A, TEMP_DAY
	LCALL DISP_DAY
	MOV A, #14H
	LCALL CMD
	MOV A, DURATION
	ADD A, #30H
	LCALL DISP
	MOV DPTR, #SECONDS
	LCALL DISPCH2
	RET

;*************************************************************************************************
;This module is used to enter the duration Option
;Parameter:None
;Return: value of duration option in Acc
;DEPENDANCIES: CMD, KEYPD, SECOND, FIRST, DISPCH2
;*************************************************************************************************
INPUT_DURATION:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #EDIT_DURATION
	LCALL DISPCH2
	LCALL SECOND
	MOV DPTR, #DURATION_MSG
	LCALL DISPCH2
	MOV A, #0FH
	LCALL CMD
	LCALL KEYPD
	LCALL DISP
	CJNE A, #'0', CHECK_NEXT_OPTION_1
	LCALL ERROR_ENTRY
	SJMP INPUT_DURATION
	CHECK_NEXT_OPTION_1:
	CJNE A, #'*' , CHECK_NEXT_OPTION_2
	SJMP INPUT_DURATION
	CHECK_NEXT_OPTION_2:
	CJNE A, #'#', CORRECT_ENTRY
	LCALL ERROR_ENTRY
	SJMP INPUT_DURATION
	CORRECT_ENTRY:
	CLR C
	MOV B, #30H
	SUBB A, B
	PUSH ACC
	WAIT_FOR_ENTER_KEY:
		LCALL KEYPD
		CJNE A, #2AH, N16
		POP ACC 		;JUST TO FREE THE STACK MEM. WHILE LOOPING. IF NOT PRESENT STACK WILL OVERFLOW IF * IS PRESSED MANY TIMES
		JMP INPUT_DURATION
		N16:
		CJNE A, #23H, WAIT_FOR_ENTER_KEY
	POP ACC
	MOV DURATION, A
	RET

ERROR_ENTRY:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #ERROR_MSG
	LCALL DISP_MSG
	LCALL DELAY_1SEC
	RET
;*************************************************************************************************
;This module sets the time and day. PIN is required to set the time. If incorrect password is 
;entered then user will again be asked to enter password and only reset breaks the loop
;Parameters:None
;Return:None(affects the RTC time)
;DEPENDANCIES: VER_PASSWORD, FIRST, SECOND, DISP_MSG, DISP_DAY, CMD, KEYPD, DISP, ERROR, ERROR_DAY
;   			DELAY_1SEC, READ_RTC
;*************************************************************************************************

SET_TIME:
	LCALL VER_PASSWORD 		;ENTER PASSWORD MODULE
	MOV B, #00H
	LCALL INPUT_HOUR_MINUTE 	;THIS FUNCTION PLACES THE VALUE OF READ NUMBER IN HOURS AND MIN
	MOV ADD_LOWL, #01H
	MOV DAVAVA, MIN
	LCALL WRITE_BYTE
	MOV ADD_LOWL, #02H
	MOV DAVAVA, HOURS
	LCALL WRITE_BYTE		;AFTER EXECUTION OF THIS MODULE RTC WILL BE SET
	;STARTING TO READ THE WEEK DAY
	LCALL INPUT_DAY 		;day value will be present in acc.
	MOV ADD_LOWL, #03H 		;starting to send the data to RTC
	MOV DAVAVA, A
	LCALL WRITE_BYTE 		;write the data to RTC

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
	MOV A, #20H
	LCALL DISP
	MOV A, DAY
	LCALL DISP_DAY			;while calling the DISP_DAY module make sure that 

	RET

;*************************************************************************************************
;This module takes input from user to enter the day in number from 1-7 and also displays the 3
;lettered corresponding day beside it
;Parameter:None
;Return:day value in Acc
;DEPENDANCIES:DISP_MSG, SECOND, CMD, ERROR_DAY, KEYPD, DISP_DAY
;*************************************************************************************************
INPUT_DAY:
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
	LCALL DISP_DAY			;DISPLAYING THE DAY AS SOON AS WE PRESS THE KEY
	MOV A, #0CH
	LCALL CMD
	LOOP3: 					;THIS LOOP IS FOR USER TO ENTER 'ENTER KEY'
	LCALL KEYPD				;INPUTTING THE ENTER KEY OR CLEAR KEY
	CJNE A, #2AH, N13 		;IF USER ENTERS * WHOLE SCREEN IS RESET
	JMP INPUT_DAY
	N13:
	CJNE A, #23H, LOOP3 	;IF USER ENTERS # IT IS CONSIDERED AS 'ENTER KEY'
	POP 01H 				;01H STANDS FOR R1
	MOV A, R1
	CLR C 
	SUBB A, #30H 			;USE THIS VALUE OF DAY
	RET

ERROR_DAY:
	LCALL FIRST 			;MOVING THE CURSOR TO FIRST LINE AS THE ERROR HAS TO BE PRINTED IN FIRST LINE
	MOV A, #0CH 			;TURNING OFF THE CURSOR
	LCALL CMD
	MOV DPTR, #ERROR_MSG
	LCALL DISP_MSG
	LCALL DELAY_1SEC
	LCALL DELAY_1SEC
	JMP INPUT_DAY

;*************************************************************************************************
;This module is used to read hour and minute from the keypad. calling function must specify whether 
;it is set_time or set_bell by passing value on register B.
;Parameter:B -> 0H if SET_TIME B->01h if SET_BELL
;Return: value will be placed in HOURS AND MIN
;DEPENDANCIES:DISP, DISPCH2, DISP_MSG, CMD, FIRST, SECOND, KEYPD
;*************************************************************************************************
INPUT_HOUR_MINUTE:
	MOV A, #01H
	LCALL CMD
	MOV A, #01H 
	CLR C
	SUBB A, B
	JZ ITS_BELL
	MOV DPTR, #MESSAGE1
	SJMP NEXT
	ITS_BELL:
	MOV DPTR, #NEW_BELL_MSG
	NEXT:
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
	LJMP INPUT_HOUR_MINUTE
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
	JMP INPUT_HOUR_MINUTE
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
	MOV HOURS, R1
	SJMP READ_MINUTES

	;START OF ERROR HANDLING
	ERROR:
		LCALL FIRST
		MOV DPTR, #ERROR_MSG
		LCALL DISP_MSG
		LCALL DELAY_1SEC
		LCALL DELAY_1SEC
		LJMP INPUT_HOUR_MINUTE

	;STARTING TO READ THE MINUTES 
	READ_MINUTES:
	LCALL KEYPD
	LCALL DISP
	CJNE A, #23H, N5		;COMPARING THE VALUE OF KEY WITH #
	SJMP ERROR
	N5:
	CJNE A, #2AH, N6		;COMPARING THE VALUE OF KEY WITH *
	LJMP INPUT_HOUR_MINUTE
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
	LJMP INPUT_HOUR_MINUTE
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
		LJMP INPUT_HOUR_MINUTE
		N9:
		CJNE A, #23H, LOOP2
	MOV MIN, R0
	RET



;*************************************************************************************************
;This module is used to write data to EEPROM. User has to pass the starting address of the data 
;through the R0 register, location on the EEPROM through the DPTR and the count of the data through
;COUNT9. Rest everything is handled by this module
;Parameters: DPTR, R0, COUNT9
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
	MOV R1, #54H
	MOV DPTR, #7001H
	MOV COUNT9, #4H
	LCALL READ_DATA
	RET


NEW_PASSWORD:
	LCALL CLEAR
	LCALL 	FIRST
	MOV DPTR,#PASSMSG
	LCALL DISPCH2
	LCALL	SECOND
	MOV DPTR,#PASSMSG1
	LCALL DISPCH2
	LCALL KEYPD
	LCALL DISP
	CJNE A, #23H, N19
	LCALL UNIVERSAL_ERROR_MODULE
	SJMP NEW_PASSWORD
	N19:
	CJNE A, #2AH, N20
	SJMP NEW_PASSWORD
	N20:
	CJNE A, #'0', N21
	LCALL UNIVERSAL_ERROR_MODULE
	SJMP NEW_PASSWORD
	N21:
	MOV R1, A
	CLR C
	SUBB A, #33H
	JNC ERROR_HANDLER_NEW_PASSWORD
	MOV A, R1
	CLR C
	SUBB A, #30H
	CJNE A, #01H, CHK_2
	MODE_MSG:
		LCALL CLEAR  
		LCALL FIRST
		MOV DPTR,#MODE_MSG1
		LCALL DISPCH2
		LCALL SECOND
		MOV DPTR,#MODE_MSG2
		LCALL DISPCH2
		LCALL KEYPD
		CJNE A, #23H, N22
		LCALL UNIVERSAL_ERROR_MODULE
		SJMP MODE_MSG
		N22:
		CJNE A, #2AH, N23
		SJMP MODE_MSG
		N23:
		CJNE A, #30H, N24
		LCALL UNIVERSAL_ERROR_MODULE
		SJMP MODE_MSG
		N24:
		MOV R1, A
		CLR C
		SUBB A, #33H
		JNC ERROR_HANDLER_MODE_MSG
		SJMP MODE_MSG
		MOV A, R1
		CLR C
		SUBB A, #30H
		CJNE A, #01H, CHK_2N 
		MOV MODE, #01H
		SJMP SET_MODE_
		CHK_2N:	
		MOV MODE, #02H
		SET_MODE_:
		LCALL SET_MODE
		RET
	CHK_2:
		LCALL CHANGE_PASSWORD
		RET

		

ERROR_HANDLER_NEW_PASSWORD:
LCALL UNIVERSAL_ERROR_MODULE
SJMP NEW_PASSWORD
ERROR_HANDLER_MODE_MSG:
LCALL UNIVERSAL_ERROR_MODULE
SJMP MODE_MSG


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
;This module will read a single Parameter from the RTC.
;Parameters: ADD_LOWL must contain the address of required register
;OUTPUT:DAVAVA will contain the data
;DEPENDANCIES:LOOP_BYTE, LOOP_READ
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
;This module reads all the Parameters of the RTC by calling other functions
;Parameters:None
;Return:MIN, HOURS, DAY
;DEPENDANCIES:READ_BYTE, I2C_STOP
;*************************************************************************************************
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

;*************************************************************************************************
;This module writes the content of DAVAVA to the RTC one bit at a time
;Parameters:DAVAVA
;Return:None but RTC will br set
;DEPENDANCIES:None
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
;This module reads the value passed by the RTC via SDA and places it in DAVAVA
;Parameters:None passed but output depends on the value passed through the SDA before calling this
;OUTPUT: value on DAVAVA
;DEPENDANCIES:None
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


I2C_Stop:
	CLR       SDA
	SETB      SCL
	NOP
	SETB      SDA
	RET




CREATE_DATA:
	MOV COUNT9, #04H
	MOV DPTR,#PASSWORD
	MOV R0,#54H
	UP2:
	CLR A
	MOVC A, @A+DPTR
	MOV @R0, A
	INC R0
	INC DPTR
	DJNZ COUNT9, UP2
	MOV DPTR, #07001H
	MOV R0, #54H
	MOV COUNT9, #04H
	LCALL WRITE_DATA
	RET


END

