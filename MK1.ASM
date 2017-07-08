;**********************************************************************************************
;The following set of code is assembly level code for digital bell system
;Author: Sukesh Rao, Srinivas Pai, Sudesh Pai, Gayathri, Arpitha and 
;Version: 0.1
;Date: 
;**********************************************************************************************

;**********************************************************************************************
;------------------------------------EEPROM memory allocation----------------------------------
;
;0X0000H 	NOTHING- ACTUALLY TOTAL NUMBER OF BELLS -BUT THEN LEFT BLANK
;0X0001H 	BELL COUNT FOR MODE-1 MONDAY
;0X0002H	BELL COUNT FOR MODE-1 TUESDAY
;......
;0X0007H 	BELL COUNT FOR MODE-1 SUNDAY
;0X0008H 	BELL COUNT FOR MODE-2 MONDAY
;...... 	
;0X000EH 	BELL COUNT FOR MODE-2 SUNDAY
;......
;......
;0X0100H 
;......	
;0X0103H 	MODE-1 MONDAY BELL SERIAL NO.1 HOUR VALUE
;0X0104H 	MODE-1 MONDAY BELL SERIAL NO.1 MINUTES VALUE
;0X0105H 	MODE-1 MONDAY BELL SERIAL NO.1 DURATION VALUE
;0X0106H 	MODE-1 MONDAY BELL SERIAL NO.2 HOUR VALUE
;......
;......
;0X0200H
;...... 
;0X0203H	MODE-2 TUESDAY BELL SERIAL NO.1 HOUR VALUE
;......
;......
;......
;0X0E03H 	MODE-2 SUNDAY BELL SERIAL NO. 1 HOUR VALUE
;......
;......
;0X7001H 	PIN 1ST DIGIT
;......
;0X7004H 	PIN 4TH DIGIT
;......
;0X7FFFH	MODE BIT
;
;**********************************************************************************************


ORG 00H
LJMP BEGIN

SCL 				EQU 	0A0H	;IN THIS EXAMPLE I USED PORT 2.0
SDA					EQU 	0A1H	;AND PORT 2.1 FOR THE I2C LINES
				            		;YOU CAN CHANGE THEM TO WHATEVER ACCEPTABLE
TIME_KEY			EQU 	P3.3	;SET_TIME KEY
BELL_KEY			EQU		P3.4	;SET_BELL KEY
EMRG_KEY			EQU 	P3.5	;EMERGENCY KEY


;=====THE READ AND WRITE COMMANDS (0D0H AND 0D1H)

CONT_BYTE_W			EQU		11010000B
CONT_BYTE_R			EQU		11010001B

ORG    0060H

DAVAVA          	EQU 	61H
ADD_LOWL        	EQU 	60H
MEMORY_ADDRESS1 	EQU 	62H
MEMORY_ADDRESS2 	EQU 	63H
EEPROM_DATA     	EQU 	64H

PREVIOUS_SEC 		EQU 	4FH
SEC					EQU		50H
MIN 				EQU		51H
HOURS				EQU		52H
DAY 				EQU		67H
TEMP_DAY			EQU		53H
FLAG1 				EQU 	6FH
BELL_HOUR 			EQU		62H
BELL_MIN 			EQU 	63H
BELL_DURATION 		EQU 	64H
CURRENT_DAY 		EQU 	65H
DURATION 			EQU 	6AH
COUNT9          	EQU 	66H
SERIAL 				EQU 	7CH
MEM_VAL 			EQU		00H
MODE 				EQU 	7DH
TEMP_SERIAL 		EQU 	43H
TEMP_HOUR 			EQU 	41H
TEMP_MIN	 		EQU 	42H
IS_BELL_UPDATED 	EQU 	6EH
NO_BELL_FLAG 		EQU  	6FH
FLAG2 				EQU 	6DH


ORG    0100H


;***********************************************************************************************
;							LOOK-UP TABLES
;***********************************************************************************************
WELCOME_MSG: 	DB '    WELCOME!',0fh
MESSAGE1: 		DB '     HH:MM', 0FH
MESSAGE2: 		DB '     __:__', 0FH
MESSAGE3: 		DB '    DAY[1-7]', 0FH
ERROR_MSG: 		DB 'INVALID NUMBER', 0FH
WEEKDAY: 		DB '000','MON','TUE','WED', 'THU', 'FRI', 'SAT', 'SUN' 
PASSWORD: 		DB '1234',0FH
KEYCODE: 		DB '1','2','3','4','5','6','7','8','9','*','0','#'
AUTH_MSG: 		DB '  ENTER THE PIN',0FH
MESSAGE5: 		DB '  TIME IS SET!', 0FH
AUTH_FAIL_MSG: 	DB ' INCORRECT  PIN', 0FH
EMERGENCY_MSG: 	DB '   EMERGENCY', 0FH
BELL_MESSAGE: 	DB ' SELECT OPTION',0FH
BELL_OPTIONS: 	DB '1)NEW  2)EDIT',0FH
BELL_NUMBER_MSG:DB 'BELL. NO.[01-',0FH
NO_BELL: 		DB '  NO BELLS SET',0FH
;TEMP: 		DB 12H,23H,01H
BELL_ACK_1: 	DB '  BELL IS SET!',0FH
SERIAL_NO_1: 	DB ' BELL NO. IS ', 0FH
NEW_BELL_MSG: 	DB ' NEW BELL TIME', 0FH
EDIT_DURATION: 	DB 'DURATION[IN SEC]', 0FH
DURATION_MSG: 	DB '[1-9]: ', 0FH
CONFIRM: 		DB '    CONFIRM!',0FH
SECONDS: 		DB 'SEC', 0FH
BOOTMSG:		DB 'PRESS 1:MODE',0FH
BOOTMSG1: 		DB '      2:PASSWORD',0FH
CONFIRM_MSG1: 	DB 'CONFIRM PASSWORD',0FH
CONFIRM_MSG2: 	DB 'NEW PASSWORD SET',0FH
MODE_MSG1: 		DB 'PRESS 1:MODE 1',0FH
MODE_MSG2: 		DB '      2:MODE 2',0FH
PASSMSG2: 		DB 'SET NEW PASSWORD',0FH
DISP_BELL_SYS: 	DB '  BELL SYSTEM  ',0FH
NEXT_BELL_MSG: 	DB 'NEXT BELL: ',0fh
NO_BELL_DISP:	DB '    NO BELL!    ' ,0FH
INI_MSG: 		DB 'INITIALIZING',0FH
MODE_SET_MSG: 	DB 'MODE IS UPDATED!', 0FH
TEMP: 			DB 0H, 0H, 0H, 0H, 0H, 0H, 0H
BELL_RINGING: 	DB 'BELL IS RINGING',0FH
;*************************************************************************************************
;						    END of LOOK-UP TABLES
;*************************************************************************************************


;**********************************************************************************************
;							CODE BEGINS
;**********************************************************************************************

BEGIN:
	ACALL 	INTI    						;CALL THE INITIALIZATION MODULE
	CLR 	SCL							;SCL: SERIAL CLOCK LINE ->MEANS THE CLOCK INPUT FOR I2C
	CLR		SDA 							;SDA: SERIAL DATA I/P & O/P ->MEANS THE INPUR AND OUTPUT LINE
	CLR		P2.2 			
	CLR 	P3.7 						;SOME UNECESSARY STATEMENTS
	NOP 								;ANOTHER UNECESSARY STATEMENT
	SETB  	SCL 							; 	""		""
	SETB 	SDA
	NOP
	;LCALL CREATE_DATA
	LCALL 	CLEAR
	ACALL 	INTI 						;just trying to debug a LCD problem
	MOV 	DPTR, #INI_MSG
	LCALL 	DISPCH2

	MOV 	A, #'.' 					;display nice ... animation
	MOV  	R0, #04H
	ANIMATE:
	LCALL 	DELAY_500MSEC
	LCALL 	DISP
	DJNZ 	R0, ANIMATE
	LCALL 	DELAY_500MSEC
	LCALL 	KEYPD_NO_LOOP 
	CJNE 	A, #39H, WELCOME 			;if pressed 9 goto bootmenu
	LCALL 	BOOT_MENU
	
	WELCOME:
	LCALL 	CLEAR
	MOV 	DPTR, #WELCOME_MSG 			;DISPLAY NICE WELCOME MESSAGE
	LCALL 	DISP_MSG 					;disp_msg includes one sec delay
	LCALL 	CLEAR
	MOV 	DPTR, #DISP_BELL_SYS
	LCALL 	DISP_MSG
	MOV 	CURRENT_DAY, #00H 			;initialize the day
	MOV 	PREVIOUS_SEC, #0FFH
	MOV 	4EH, ':' 					;initializing the blinking cursor
	LOOP:								;BEGINNING OF ACTUAL 'MAIN' LOOP
	LCALL 	DETERMINE_MODE
	LCALL 	READ_RTC
	LCALL 	CHECK_KEY 					;CHECK FOR THE PRESS OF THE SET_TIME, SET_BELL, EMERGENCY_KEY
	LCALL 	CHECK_ALARM 				;CHECK WHETHER WE NEED TO RING THE BELL
	LCALL 	CLEAR 						
	LCALL 	DISP_TIME_BLINKING					
	MOV 	A, #14H
	LCALL 	CMD
	MOV 	A, DAY
	LCALL 	DISP_DAY
	MOV 	R1, #05H
	MOV 	A, #14H
	FIVE_SPACES: 						;give 5 spaces to display the mode at the right most corner
		LCALL 	CMD
		DJNZ 	R1, five_spaces
	MOV 	A, #'M'
	LCALL 	DISP
	MOV 	A, MODE
	ADD 	A, #30H 					;mode bit+30h= ascii value to be displayed
	LCALL 	DISP
	LCALL 	SECOND
	MOV 	A, IS_BELL_UPDATED 			;if the bell is not updated then that means no more next bell
	CJNE 	A, #0FFH,NO_BELLS
	LCALL 	DISP_NEXT_BELL
	SJMP 	LOOP
	NO_BELLS:
		MOV 	DPTR, #NO_BELL_DISP
		LCALL 	DISPCH2
	SJMP 	LOOP

;**********************************************************************************************
;This module initializes the LD
;DEPENDANCIES:CMD, CLEAR
;**********************************************************************************************
INTI:	
	MOV 	A,#3CH						;refer manual for the bit meaning
	LCALL 	CMD
	MOV 	A,#3CH 						;DONT KNOW WHY SAME COMMAND IS REPEATER FOR 3 TIMES
	LCALL 	CMD 	
	MOV 	A,#3CH						;MAY BE TO BE SUPER SURE ABOUT EXECUTION OF IT ;)
	LCALL 	CMD
	MOV 	A,#0CH
	LCALL 	CMD
	MOV 	A,#06H
	LCALL 	CMD
	LCALL 	CLEAR
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
	MOV 	A,#80H						;look for the these codes in the LCD datasheet
	LCALL 	CMD
	RET
;SIMILARLY FOR SECOND LINE
SECOND:
	MOV 	A,#0C0H 	
	LCALL 	CMD
	RET

;USED TO CLEAR THE CONTENT OF THE LCD
CLEAR:
	MOV 	A,#01H
	LCALL 	CMD
	RET
;***********************************************************************************************
;This module gives cmd to LCD. Command to be passed to the LCD should be placed in Acc.
;To send a command a high to low signal is sent to the enable pin while the command to be
;sent is place on the data line and the register select(RS) pin is held low.
;DEPENDANCIES: READY
;***********************************************************************************************
CMD:	
	LCALL 	READY
	MOV  	80H,A
	CLR 	0A5H						; low on RS
	CLR 	0A6H
	SETB 	0A7H	 					; high to low on En line
	CLR 	0A7H
	RET

;***********************************************************************************************
;This module checks the LCD status whether busy or not and returns from the module only if 
;the busy bit/pin/line is 0
;***********************************************************************************************
READY:	
	CLR		0A7H							;read busy FLAG1
	MOV		80H,#0FFH
	CLR		0A5H
	SETB	0A6H
	WAIT:	
		CLR		0A7H
		SETB	0A7H
		JB		87H,WAIT
	RET


;*************************************************************************************************
;This module returns the mode in variable named MODE
;Parameters:None
;Return:MODE
;DEPENDANCIES:READ_DATA
;*************************************************************************************************
DETERMINE_MODE:
	MOV 	DPTR, #07FFFH
	MOV 	R1, #54H
	MOV 	COUNT9, #01H
	LCALL 	READ_DATA
	MOV 	MODE, 54H
	RET


;*************************************************************************************************
;
;									DATA MANIPULATION
;				      						&
; 									DISPLAY FUNCTIONS
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
	MOV 	B,#100
	DIV 	AB
	MOV 	R2, A
	MOV 	A, B
	MOV 	B, #10
	DIV 	AB
	SWAP 	A
	ADD 	A, B
	MOV 	40H, A
	RET
;*************************************************************************************************
;This module is used to convert from BCD to HEX. 
;Parameters:data to be converted in the Acc
;Return: converted data in Acc
;DEPENDANCIES:None
;*************************************************************************************************
BCD_HEX:
	PUSH 	ACC
	ANL 	A, #0FH
	MOV 	R2, A
	POP 	ACC
	ANL 	A, #0F0H
	SWAP 	A
	MOV 	B, #0AH 
	MUL 	AB
	ADD 	A, R2
	RET

;*************************************************************************************************
;This module will prepare the BCD data to display on the LCD
;Parameters:40h
;Return:msb in R3 and lsb in R2
;DEPENDANCIES:None
;*************************************************************************************************
UNPACK:
	MOV 	A,40h
	ANL		A,#0FH
	ADD		A,#30h
	MOV		R2,A
	MOV 	A,40h	
	SWAP	A
	ANL		A,#0FH
	ADD		A,#30H
	MOV		R3,A
	RET

;*************************************************************************************************
;This module takes the starting address of the string to be displayed in the DPTR and loops
;till it find the string terminator #0FH and also turns the cursor OFF
;Parameters:DPTR holds the starting address of the string
;Return:
;DEPENDANCIES:DISP,CMD
;*************************************************************************************************
DISPCH2:
	nop
	MOV 	A, #0CH 			;TURNING OFF THE CURSOR
	LCALL 	CMD
	UP11:	
		CLR 	A
		MOVC 	A,@A+DPTR 		;use lookup table to get ascii character
		CJNE 	A,#0FH,SKIP111 ;loop till 0xfh is encountered
		RET		
	SKIP111:	
		INC 	DPTR
		LCALL  	DISP 		
		SJMP 	UP11

;*************************************************************************************************
;This module is used to display the 3 lettered day in the LCD give the number of 
;corresponding day in Acc.
;Parameters:Acc. holds the day number
;Return:None
;DEPENDANCIES:DISP
;*************************************************************************************************
DISP_DAY:
	PUSH 	01H
	MOV 	B, #3H 				;IN THE LOOK-UP TABLE NAMED 'WEEKDAY' EACH WEEKDAY LENGTH IS 3
	MUL 	AB 					;HENCE TO GET ACTUAL OFFSET WE HAVE TO MULTIPLY BASE BY 3 AND ADD IT TO DPTR
	UP12:
		MOV 	B,A 			;just saving the content of Acc.
		MOV 	R1, #04H  		;counter
		MOV 	DPTR, #WEEKDAY 	
		UP13:
			MOV 	A,B 		;you might assume that why to again load to Acc. but after first iteration...
			MOVC 	A,@A+DPTR 	;use lookup table to get ascii character
			DJNZ 	R1,SKIP1
			POP 	01H
			RET		
	SKIP1:	
		INC 	DPTR
		LCALL  	DISP
		SJMP 	UP13

;*************************************************************************************************
;This module takes character to be displayed in the Acc. and displys it on LCD(only one char)
;Parameters:Acc.  
;Return:None
;DEPENDANCIES: READY
;*************************************************************************************************
DISP:
	LCALL 	READY	
	MOV 	80H, A 				;80h is the address of the pin on 8051 which is connected to the 
	SETB 	0A5H	 			; high RS
	CLR		0A6H				; A6h is the R/WBAR
	SETB 	0A7H				; high to low En 
	CLR		0A7H
	RET

;*************************************************************************************************
;This module outputs the 2-digit BCD number on the LCD
;Parameters:number to be displayed in 40H
;Return:None
;DEPENDANCIES:UNPACK, DISP
;*************************************************************************************************

DISP_2DIG_NO:
	LCALL 	UNPACK
	MOV 	A, R3
	LCALL 	DISP
	MOV 	A, R2
	LCALL 	DISP
	RET

;*************************************************************************************************
;This module is used only in debugging mode to display the DPTR value on LCD
;*************************************************************************************************
DISP_2DIG_HEXA:
	MOV 5BH, A
	ANL A, #0F0H
	SWAP A
	LCALL HEXA_DISP
	MOV A, 5BH
	ANL A, #0FH
	LCALL HEXA_DISP
	RET

HEXA_DISP:
	ADD A,#30h
	MOV B,A
	SUBB A,#39h
	JC MOVE
	MOV A, B
	ADD A,#07H
	MOVE:
	MOV A,B
	LCALL DISP
	RET

;*************************************************************************************************
;This module will display the VALUES PRESENT IN HOURS AND MIN VARIABLE on LCD in format HH:mm DAY
;Parameters:HOURS, MIN
;Return:None
;DEPENDANCIES:DISP_DAY, DISP, UNPACK
;*************************************************************************************************
DISP_TIME:
	MOV 	40h, HOURS
	LCALL 	DISP_2DIG_NO
	MOV 	A, #':'
	LCALL 	DISP
	MOV 	40h, MIN
	LCALL 	DISP_2DIG_NO
	RET

DISP_NEXT_BELL:
	MOV 	DPTR, #NEXT_BELL_MSG
	LCALL 	DISPCH2
	MOV 	HOURS, BELL_HOUR
	MOV 	MIN, BELL_MIN
	LCALL 	DISP_TIME
	RET

DISP_TIME_BLINKING:
	MOV 	A, SEC
	CJNE 	A, 4FH, CHNAGE_SYMBOL
	DISPLAY_BLINKING_CURSOR:
	MOV 	40h, HOURS
	LCALL 	DISP_2DIG_NO
	MOV 	A, 4EH
	LCALL 	DISP
	MOV 	40h, MIN
	LCALL 	DISP_2DIG_NO
	RET
	CHNAGE_SYMBOL:
		CJNE 4EH, ':', CHANGE_TO_COLON
		MOV 4EH, ' '
		SJMP DISPLAY_BLINKING_CURSOR
		CHANGE_TO_COLON:
		MOV 4EH, ' '
		SJMP DISPLAY_BLINKING_CURSOR

;*************************************************************************************************
;*************************************************************************************************

;*************************************************************************************************
; This module generates delay of 1sec
;*************************************************************************************************
DELAY_1SEC:
	MOV 	R7,#10	
	HERE4:
		MOV 	R6,#0ffh        ;delay routine for firing
		HERE31: 
				MOV 	R5,#0ffH
				REPEAT1:
					DJNZ 	R5,REPEAT1
				   	DJNZ  R6,HERE31
				   	DJNZ 	R7,HERE4	
					RET

DELAY_500MSEC:
	PUSH 	07H 	;these push instruction will ensure that everything will work fine by saving the 			
				;... value of the register used by the function that called it
	PUSH 	06H
	PUSH 	04H
	MOV 	R7,#4	
	HERE41:
		MOV 	R6,#0f0h        ;delay routine for firing
		HERE311: 
				MOV 	R4,#0ffH
				REPEAT11:
					DJNZ 	R4,REPEAT11
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
;									THIS MODULE CAN BE OPTIMIZED
;*************************************************************************************************
CHECK_KEY:
	JNB 	TIME_KEY, SETT_TIME	;PLEASE NOTICE THE DOUBLE 'T'
	;SJMP SETT_TIME
	CHECKING_BELL:
	JNB 	BELL_KEY, SETT_BELL
	CHECKING_EMERGENCY:
	JNB 	EMRG_KEY, EMMERGENCY
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


KEYPD_NO_LOOP:   
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
		LCALL DELAY_500MSEC
    	RET


;*************************************************************************************************
;*************************************************************************************************
;This module is called from the main loop. This module compares the RTC time with next bell time
;and if it matches calls the ring bell module and which inturn loads the next bell.
;Parameters: None passed explicitly. but needs the next bell timing loaded in the bell_* set of 
;		 variables
;
; 								PLEASE AVOID MODIFYING THIS MODULE
;*************************************************************************************************
;*************************************************************************************************

CHECK_ALARM:
	LCALL 	READ_RTC
	MOV 	A, DAY
	CJNE 	A, 65H , LOAD_NEXT_BELL 			;65h stands for CURRENT_DAY
	PROCEED_TO_CMP_TIME:
		MOV 	CURRENT_DAY, DAY 		
		MOV 	A, HOURS
		CJNE 	A, 62H, END_OF_THIS_MODULE 		;is hour equal to bell_hour?
		MOV 	A, MIN
		CJNE 	A, 63H, END_OF_THIS_MODULE 		;is min equal?
		MOV 	A, NO_BELL_FLAG
		CJNE 	A, #00H,END_OF_THIS_MODULE 
		LCALL 	RING_BELL 						;if equal ring bell else RET
	END_OF_THIS_MODULE:
	RET
LOAD_NEXT_BELL:
	MOV 	CURRENT_DAY, DAY 					;these three move instruction are 
	MOV 	BELL_HOUR, HOURS 					;needed for first time i.e., 
	MOV 	BELL_MIN, MIN 						;after reset
	LCALL 	LOAD_NEXT_BELL_MODULE 				;now load next bell
	SJMP 	PROCEED_TO_CMP_TIME					;again go back to cmd_time
	
RING_BELL:
	;MAKE HIGH ON SOME PIN
	LCALL 	CLEAR
	MOV 	DPTR, #BELL_RINGING
	LCALL	DISPCH2
	MOV 	R2, BELL_DURATION
	RING_BELL_DELAY:
		LCALL 	DELAY_1SEC
		DJNZ 	R2, RING_BELL_DELAY
	;MAKE SOME PIN LOW
	LCALL 	CLEAR
	LCALL 	LOAD_NEXT_BELL_MODULE 				;load next bell

	RET

LOAD_NEXT_BELL_MODULE:
	MOV 	IS_BELL_UPDATED, #00H 				;this is to know if next bell for day is available
	MOV 	NO_BELL_FLAG, #00H
	MOV 	DPH, #00H 							;load number of bells available for that day
	MOV 	A, CURRENT_DAY						;according to the mode
	MOV 	R4, MODE
	CJNE 	R4, #02H, ADD_NOTHING__
	ADD 	A, #07H
	ADD_NOTHING__:
	MOV 	DPL, A
	MOV 	COUNT9, #01H
	MOV 	R1, #7CH 	 						;location of serial variable
	LCALL 	READ_DATA 				  			;After execution of this instruction serial will have max count of bell for that day
	MOV 	R0, SERIAL
	CJNE 	R0, #00H, PROCEED
	lJMP 	NO_BELLS_PRESENT
	PROCEED:
	MOV 	R0, #00H 							;initializing the counter for linear search
	MOV 	A, CURRENT_DAY
	CJNE 	R4, #02H, ADD_NOTHING__1
	ADD 	A, #07H
	ADD_NOTHING__1:
	MOV 	DPH, A

	NEXT_ITERATION:
	MOV 	A, #03H 	 						;VALUES START FROM 0X0*00H
	INC 	R0									;AND ALSO SERIAL NUMBER STARTS FROM 01
	MOV 	B, R0
	MUL 	AB
	MOV 	DPL, A
	MOV 	COUNT9, #03H
	MOV 	R1, #41H 							;41H=TEMP_HOUR
	LCALL 	READ_DATA 	
	MOV 	A, 41H 								;NOW A= TEMP_HOUR=MAY BE THE NEXT BELL VALUE
	MOV 	B, BELL_HOUR
	CLR 	C
	SUBB 	A, B 						
	JC 		END_OF_ROUTINE 						;WE NEED HIGHER OR EQUAL HOUR VALUE AND NOT LESS
	JNZ 	POTENTIAL_CANDIDATE
	CLR 	C
	MOV 	A, 42H
	MOV 	B, BELL_MIN
	SUBB 	A, B
	JC 		END_OF_ROUTINE
	JZ 		END_OF_ROUTINE

	POTENTIAL_CANDIDATE:
		CJNE 	R0, #01H, CHECK_WITH_PREVIOUS_POTENTIAL_CANDIDATE
		SJMP 	UPDATE_POTENTIAL_CANDIDATE

		CHECK_WITH_PREVIOUS_POTENTIAL_CANDIDATE:

			MOV 	A, BELL_HOUR 					;these statements are needed otherwise it wont load next bell if the 
			MOV 	B,	44H 						;.. bells are in ascending order 
			CLR 	C 								;..because the 44h, and 45h will have lower entry than the 41h and 42H
			SUBB 	A, B  							;So, we check if the current bell time is equal to the value in 44h, and 
			JNZ 	CONTINUE_WITH_POTENTIAL_CANDIDATE 	;45h. If equals and R0 is not 1 then update 44h and 45H
			MOV 	A, BELL_MIN
			MOV 	B, 45H
			CLR 	C
			SUBB 	A, B  							;if not checked these condition updation wont happen and will stuck with no bell
			JZ 		UPDATE_POTENTIAL_CANDIDATE 		;for example current time 4:15 and potential candidate will be 4:15 and actual next 
													;bell must be at 4:20 so think.....what 4:20 is greater than 4:15 but is also more than
													;4:15 so if not for this condition the code would have skipped this value and any next 

			CONTINUE_WITH_POTENTIAL_CANDIDATE:
			MOV 	B, 44H 							;previous potential value of hour
			MOV 	A, 41H 							;current value of the hour copied from EEPROM
			CLR 	C
			SUBB 	A, B
			JC 		UPDATE_POTENTIAL_CANDIDATE
			JNZ 	END_OF_ROUTINE 		
			CLR 	C
			MOV 	A, 45H
			MOV 	B, 42H
			SUBB 	A, B
			JC 		END_OF_ROUTINE

		UPDATE_POTENTIAL_CANDIDATE:
			MOV 	IS_BELL_UPDATED, #0FFH 			;marking that the bell is updated
			MOV 	44H, 41H
			MOV 	45H, 42H
			MOV 	46H, 43H
	END_OF_ROUTINE:
		MOV 	A, R0
		CJNE 	A ,7CH,  NEXT_ITERATION 				;7ch is max bell available for that day

		MOV 	A, IS_BELL_UPDATED
		CJNE 	A, #0FFH, NO_BELLS_PRESENT
		MOV 	BELL_HOUR, 44H
		MOV 	BELL_MIN, 45H
		MOV 	BELL_DURATION, 46H
		RET 
		NO_BELLS_PRESENT:
			MOV 	NO_BELL_FLAG, #0FFH
			MOV 	BELL_DURATION, #00H
	RET



;*************************************************************************************************
;*************************************************************************************************


;*************************************************************************************************
;This module returns the validity of the entered PIN in the Acc. 
;Parameters:None
;Return: Acc.
;DEPENDANCIES: FIRST, READ_PASSWORD, SECOND, DISPCH2, KEYPD, CMD, DISP
; 									no more changes required
;*************************************************************************************************

VER_PASSWORD:
	LCALL 	CLEAR
	MOV 	DPTR, #AUTH_MSG
	LCALL 	DISPCH2
	LCALL 	SECOND
	MOV 	R0, #06H
	MOV 	A, #14H
	LOOP5:
	LCALL 	CMD
	DJNZ 	R0, LOOP5
	MOV 	A, #0EH
	LCALL 	CMD
	LCALL 	READ_PASSWORD
	MOV 	R0, #54H
	MOV 	FLAG1, #00H
	MOV 	R1, #4H
	LOOP4:
	MOV 	B, @R0
	LCALL 	KEYPD
	CJNE 	A, #'*', N103
	SJMP 	VER_PASSWORD
	N103:
	CJNE 	A, B, SET_FLAG
	N102:
	MOV 	A, #'*'
	LCALL 	DISP
	INC 	R0
	DJNZ 	R1,LOOP4
	MOV 	A, FLAG1
	MOV 	B, #00H
	CJNE 	A, B, AUTH_FAIL
	RET
	AUTH_FAIL:
		LCALL 	CLEAR
		MOV 	DPTR, #AUTH_FAIL_MSG
		LCALL 	DISP_MSG
		SJMP 	VER_PASSWORD
	SET_FLAG:
		MOV FLAG1, #0FFH
		SJMP N102		

EMERGENCY:
	LCALL 	VER_PASSWORD
	LCALL 	CLEAR
	LCALL 	DELAY_1SEC
	MOV 	DPTR, #EMERGENCY_MSG
	LCALL 	DISPCH2
	LCALL 	DELAY_1SEC 						;this will have blinking effect
	SJMP 	EMERGENCY 						;loop forever
	RET


SET_BELL:
	LCALL VER_PASSWORD
	SET_BELL_VERIFIED:
	LCALL 	CLEAR
	MOV 	DPTR, #BELL_MESSAGE
	LCALL 	DISPCH2
	LCALL 	SECOND
	MOV 	DPTR, #BELL_OPTIONS
	LCALL 	DISPCH2
	MOV 	A, #0EH
	LCALL 	CMD
	LOOP8: 
		LCALL 	KEYPD
		MOV 	B, #31H
		CJNE 	A, B, N14
		JMP 	NEW_BELL
		N14:
		MOV 	B, #32H
	CJNE 	A, B, LOOP8

	EDIT_BELL:
	LCALL 	INPUT_DAY  					;now accumulator will contain the day value
	MOV 	TEMP_DAY, A
	;Load number of bells available for that day
	MOV 	DPTR, #00H
	MOV 	R4, MODE
	MOV 	R1, #50H
	MOV 	COUNT9, #01H
	MOV 	A, TEMP_DAY
	CJNE 	R4, #02H, ITS_MODE_1
	ADD 	A, #07H
	ITS_MODE_1:
	MOV 	DPL, A
	LCALL 	READ_DATA
	MOV 	R1, #50H
	MOV 	A, @R1
	
	MOV 	B, #00H
	CJNE 	A, B, HAS_BELL_ENTRY		;if its non zero then that means it has entry
	LCALL 	CLEAR
	MOV 	DPTR, #NO_BELL
	LCALL 	DISPCH2
	LCALL 	DELAY_1SEC
	SJMP 	SET_BELL_VERIFIED  			;if its zero then give user chance to make an entry

	HAS_BELL_ENTRY:
		MOV 	A, TEMP_DAY
		MOV 	DPTR, #00H
		MOV 	R4, MODE
		CJNE 	R4, #02H, IT_IS_MODE_1
		CLR 	C
		ADD 	A, #07H
		IT_IS_MODE_1:
		MOV 	DPL, A
		MOV 	R1, #50H
		MOV 	COUNT9, #01H
		LCALL 	READ_DATA
		MOV 	R1, #50H
		MOV 	A, @R1
		PUSH 	ACC
		LCALL 	CLEAR
		MOV 	DPTR, #BELL_NUMBER_MSG 	;display number of bells i.e., max count
		LCALL 	DISPCH2
		POP 	ACC 					;will contain max serial number
		LCALL 	HEX_BCD 				;converts to bcd and output will be in acc[lower two dig] and r2[only for 3 dig BCD]
		PUSH 	ACC 					;saving the bcd converted value	
		LCALL 	DISP_2DIG_NO 			;display the serial number
		MOV 	A, #']'
		LCALL 	DISP 					
		LCALL 	SECOND
		MOV 	A, #0FH
		LCALL 	CMD
		LCALL 	KEYPD
		LCALL 	DISP 					;read and display the entered number
		CJNE 	A, #'*', CONTINUE_1 	
		POP 	ACC
		SJMP 	HAS_BELL_ENTRY
		CONTINUE_1:
		CJNE 	A, #'#', CONTINUE_2
		LCALL 	UNIVERSAL_ERROR_MODULE
		POP 	ACC
		SJMP 	HAS_BELL_ENTRY
		CONTINUE_2:
		CLR 	C
		SUBB 	A, #30H
		SWAP 	A 						;move the entered number to 10's place
		MOV 	B, A 					;and save it in B
		LCALL 	KEYPD
		LCALL 	DISP
		CJNE 	A, #'*', CONTINUE_3
		POP 	ACC
		SJMP 	HAS_BELL_ENTRY
		CONTINUE_3:
		CJNE 	A, #'#', CONTINUE_4
		LCALL 	UNIVERSAL_ERROR_MODULE
		POP 	ACC
		SJMP 	HAS_BELL_ENTRY
		CONTINUE_4:
		CLR 	C
		SUBB 	A, #30H
		ADD 	A, B 						;now acc. contains the actual entered serial in packed BCD
		MOV 	B,A 						;save this value
		POP 	ACC 						;restore max. bells available
		CLR 	C
		SUBB 	A, B 						
		JNC 	OKAY
		LCALL 	UNIVERSAL_ERROR_MODULE
		LJMP 	HAS_BELL_ENTRY
		OKAY:
		MOV 	A, B
		CJNE 	A, #00H, OKAY_1 			;checking if entered number is 0
		LCALL 	UNIVERSAL_ERROR_MODULE
		LJMP 	HAS_BELL_ENTRY
		OKAY_1:
		MOV 	A, B
		LCALL 	BCD_HEX 					;converted value will be in acc
		MOV 	SERIAL, A 					;saving the value of serial safely in the RAM
		MOV 	DPH, TEMP_DAY 				;location of the bells start from 0*03
		MOV 	R4, MODE
		MOV 	A, DPH
		CJNE 	R4, #02H, IT_IS_MODE_1_
		CLR 	C
		ADD 	A, #07H 					;location of bells for mode 2 is 0700+0*03
		IT_IS_MODE_1_:
		MOV 	DPH, A
		MOV 	B, #03H
		MOV 	A, SERIAL
		MUL 	AB
		MOV 	DPL,A
		MOV 	R1, #54H
		MOV 	COUNT9, #03H
		LCALL 	READ_DATA
		MOV 	HOURS, 54H
		MOV 	MIN, 55H
		MOV 	A, #' '
		LCALL 	DISP
		LCALL 	DISP_TIME
		WAIT_FOR_ENTER: 					;WAITING FOR USER TO CONFIRM THAT HE/SHE WANTS THIS BELL ITSELF
		MOV 	A, #0CH 						;turn off cursor
		LCALL 	CMD
		LCALL 	KEYPD
		CJNE 	A, #2AH, N15
		LJMP 	HAS_BELL_ENTRY 
		N15:
		CJNE 	A, #23H, WAIT_FOR_ENTER
		MOV 	B, #01H
		LCALL 	INPUT_HOUR_MINUTE			;READ THE TIME
		LCALL 	INPUT_DURATION
		LCALL 	CONFIRM_BELL 				;displays confirmation message along with info.
		WAIT_FOR_ENTER_KEY_1:
			LCALL 	KEYPD
			CJNE 	A, #2AH, N17
			LJMP 	EDIT_BELL
			N17:
			CJNE 	A, #23H, WAIT_FOR_ENTER_KEY_1
		LCALL 	CLEAR
		MOV 	DPTR, #BELL_ACK_1
		LCALL 	DISPCH2
		MOV 	A, TEMP_DAY 				;start to save the bell.
		MOV 	R4, MODE
		CJNE 	R4, #02H, ITS_MODE_1__
		ADD 	A, #07H 					;to understand the logic see the memory allocation at the beginnig the code
		ITS_MODE_1__:
		MOV 	DPH, A
		MOV 	A, SERIAL
		MOV		B, #03H
		MUL 	AB
		MOV 	DPL, A 						;after this ins. the DPTR will contain the address to which the bell has to be saved
		LCALL 	SAVE_BELL
		RET

	NEW_BELL:
		LCALL 	INPUT_DAY 					;day value is returned in Acc
		MOV 	TEMP_DAY, A
		MOV 	B, #01H
		LCALL 	INPUT_HOUR_MINUTE
		LCALL 	INPUT_DURATION 				;returned in DURATION variable
		MOV 	DPH, #00H
		MOV 	R4, MODE
		MOV 	A, TEMP_DAY
		CJNE 	R4, #02H, ADD_NOTHING 		;THIS MEANS MODE 1
		CLR  	C
		ADD 	A, #07H
		ADD_NOTHING:
		MOV 	COUNT9, #01H
		MOV 	R1, #54H
		MOV 	DPL, A
		LCALL 	READ_DATA
		MOV 	SERIAL, 54H 				;if needed, add a comp. instruction to limit max count
		LCALL 	CONFIRM_BELL
		WAIT_FOR_ENTER_KEY_2:
		LCALL 	KEYPD
		CJNE 	A, #'*', N18
		SJMP 	NEW_BELL
		N18:
		CJNE 	A, #'#', WAIT_FOR_ENTER_KEY_2
		MOV 	R4, MODE
		MOV 	A, TEMP_DAY
		CJNE 	R4, #01H, ITS_MODE_2
		SJMP 	NOTHING_TO_ADD
		ITS_MODE_2:
		ADD 	A, #07H
		NOTHING_TO_ADD:
		MOV 	DPH, A
		MOV 	A, SERIAL
		INC 	A  							;this is because we start serial from 1 and not 0
		MOV 	B, #03H
		MUL 	AB
		MOV 	DPL, A
		LCALL 	SAVE_BELL 					;after execution of this ins. the bell will be saved
		LCALL 	CLEAR
		LCALL 	FIRST
		MOV 	DPTR, #BELL_ACK_1 
		LCALL 	DISPCH2
		LCALL 	SECOND
		MOV 	DPTR, #SERIAL_NO_1			;we have to display the serial number for users ref.
		LCALL 	DISPCH2
		MOV 	A, SERIAL
		INC 	A
		LCALL 	HEX_BCD
		LCALL 	DISP_2DIG_NO 
		MOV 	A, SERIAL
		INC 	A
		MOV 	54H, A
		MOV 	R0, #54H
		MOV 	COUNT9, #01H
		MOV 	DPH, #00H
		MOV 	R4, MODE
		MOV 	A, TEMP_DAY
		CJNE 	R4, #01H, ADD_SOMETHING
		SJMP 	ADD_NOTHING_1
		ADD_SOMETHING:
		CLR 	C
		ADD 	A, #07H
		ADD_NOTHING_1:
		MOV 	DPL, A
		LCALL 	WRITE_DATA
		LCALL 	DELAY_1SEC
		LCALL 	DELAY_1SEC
		RET


UNIVERSAL_ERROR_MODULE:
	LCALL 	CLEAR
	MOV 	DPTR, #ERROR_MSG
	LCALL 	DISPCH2
	LCALL 	DELAY_1SEC
	RET

SAVE_BELL:
	LCALL 	CLEAR
	MOV 	COUNT9, #03H
	MOV 	54H, HOURS
	MOV 	55H, MIN
	MOV 	56H, DURATION
	MOV 	R0, #54H
	LCALL 	CLEAR
	LCALL 	WRITE_DATA
	RET

CONFIRM_BELL:
	LCALL 	CLEAR
	MOV 	DPTR, #CONFIRM
	LCALL 	DISPCH2
	LCALL 	SECOND
	LCALL 	DISP_TIME
	MOV 	A, #14H
	LCALL 	CMD
	MOV 	A, TEMP_DAY
	LCALL 	DISP_DAY
	MOV 	A, #14H
	LCALL 	CMD
	MOV 	A, DURATION
	ADD 	A, #30H
	LCALL 	DISP
	MOV 	DPTR, #SECONDS
	LCALL 	DISPCH2
	RET

;*************************************************************************************************
;This module is used to enter the duration Option
;Parameter:None
;Return: value of duration option in Acc
;DEPENDANCIES: CMD, KEYPD, SECOND, FIRST, DISPCH2
; 									no more changes required
;*************************************************************************************************
INPUT_DURATION:
	LCALL 	CLEAR
	MOV 	DPTR, #EDIT_DURATION
	LCALL 	DISPCH2
	LCALL 	SECOND
	MOV 	DPTR, #DURATION_MSG
	LCALL 	DISPCH2
	MOV 	A, #0FH
	LCALL 	CMD
	LCALL 	KEYPD
	LCALL 	DISP
	CJNE 	A, #'0', CHECK_NEXT_OPTION_1
	LCALL 	UNIVERSAL_ERROR_MODULE
	SJMP 	INPUT_DURATION
	CHECK_NEXT_OPTION_1:
	CJNE 	A, #'*' , CHECK_NEXT_OPTION_2
	SJMP 	INPUT_DURATION
	CHECK_NEXT_OPTION_2:
	CJNE 	A, #'#', CORRECT_ENTRY
	LCALL 	UNIVERSAL_ERROR_MODULE
	SJMP 	INPUT_DURATION
	CORRECT_ENTRY:
	CLR 	C
	MOV 	B, #30H
	SUBB 	A, B
	PUSH 	ACC
	WAIT_FOR_ENTER_KEY:
		LCALL 	KEYPD
		CJNE 	A, #2AH, N16
		POP 	ACC 		;just to free the stack mem. while looping. 
		JMP 	INPUT_DURATION
		N16:
		CJNE 	A, #23H, WAIT_FOR_ENTER_KEY
	POP 	ACC
	MOV 	DURATION, A
	RET

;*************************************************************************************************
;This module sets the time and day. PIN is required to set the time. If incorrect password is 
;entered then user will again be asked to enter password and only reset breaks the loop
;Parameters:None
;Return:None(affects the RTC time)
;DEPENDANCIES: VER_PASSWORD, FIRST, SECOND, DISP_MSG, DISP_DAY, CMD, KEYPD, DISP, ERROR, ERROR_DAY
;   			DELAY_1SEC, READ_RTC
; 									no more changes required
;*************************************************************************************************

SET_TIME:
	LCALL 	VER_PASSWORD 				;ENTER PASSWORD MODULE
	MOV 	B, #00H
	LCALL 	INPUT_HOUR_MINUTE 			;THIS FUNCTION PLACES THE VALUE OF READ NUMBER IN HOURS AND MIN
	MOV 	ADD_LOWL, #01H
	MOV 	DAVAVA, MIN
	LCALL 	WRITE_BYTE
	MOV 	ADD_LOWL, #02H
	MOV 	DAVAVA, HOURS
	LCALL 	WRITE_BYTE					;AFTER EXECUTION OF THIS MODULE RTC WILL BE SET
	;STARTING TO READ THE WEEK DAY
	LCALL 	INPUT_DAY 					;day value will be present in acc.
	MOV 	ADD_LOWL, #03H 				;starting to send the data to RTC
	MOV 	DAVAVA, A
	LCALL 	WRITE_BYTE 					;write the data to RTC

	LCALL	CLEAR
	MOV 	DPTR, #MESSAGE5
	LCALL 	DISP_MSG
	LCALL 	SECOND
	LCALL 	READ_RTC
	PUSH 	01H
	MOV 	R1, #03H
	MOV 	A, #14H
	LOOP7:
	LCALL 	CMD
	DJNZ 	R1, LOOP7
	POP 	01H
	LCALL 	DISP_TIME
	MOV 	A, #20H
	LCALL 	DISP
	MOV 	A, DAY
	LCALL 	DISP_DAY					;while calling the DISP_DAY module make sure that 

	RET

;*************************************************************************************************
;This module takes input from user to enter the day in number from 1-7 and also displays the 3
;lettered corresponding day beside it
;Parameter:None
;Return:day value in Acc
;DEPENDANCIES:DISP_MSG, SECOND, CMD, ERROR_DAY, KEYPD, DISP_DAY
; 									no more changes required
;*************************************************************************************************
INPUT_DAY:
	MOV 	A, #1H 						;CLEARING THE SCREEN TO BEGIN FRESH
	LCALL 	CMD
	MOV 	DPTR, #MESSAGE3
	LCALL 	DISPCH2
	LCALL 	SECOND						;BRINGING THE CURSOR TO SECOND LINE FIRST POSITION
	LCALL 	CMD
	MOV 	A, #0FH 					;TURNING ON THE CURSOR
	LCALL 	CMD
	MOV 	R0, #5H 					;SHIFTING THE CURSOR TO THE MIDDLE
	MOV 	A, #14H 			
	LOOP6:
	LCALL 	CMD
	DJNZ 	R0, LOOP6
	LCALL 	KEYPD						;READ A CHARACTER
	LCALL 	DISP
	CJNE 	A, #23H, N10				;COMPARING THE VALUE OF KEY WITH #
	SJMP 	ERROR_DAY
	N10:
	CJNE 	A, #2AH, N11				;COMPARING THE VALUE OF KEY WITH *
	SJMP 	ERROR_DAY
	N11:
	CJNE 	A, #30H, N12				;COMPARING THE VALUE OF KEY WITH 0 AS VALID CHARACTERS ARE ONLY 1-7
	SJMP 	ERROR_DAY
	N12:
	MOV 	R1,A 						;SAVING THE VALUE OF A
	PUSH 	01H							;THE DISP_DAY FUNCTION WIHICH WE WILL USE LATER WILL USE R1 AS ONE OF ITS VARIABLES
	CLR 	C  							;... SO WE HAVE TO USE PUSH TO SAVE R1
	SUBB 	A, #38H 					;ERROR CHECKING BY CHECKING IF THE ANSWER COMES OUT NEGATIVE
	JNC 	ERROR_DAY 					;EX: INPUT IS 37H(VALID) SO 37H-38H=-1H HENCE C=1. HENCE VALID
	CLR 	C 							;EX: IF INPUT IS 39H(INVALID) SO ASNWER IS 1H AND C=0. HENCE INVALID
	MOV 	A, #14H						;SHIFTING RIGHT CURSOR TO GIVE SPACE
	LCALL 	CMD 
	MOV 	A,R1 						;RESTORING THE VALUE OF A
	SUBB 	A, #30H 					;GETTING ACTUAL VALUE FROM ASCII VALUE
	LCALL 	DISP_DAY					;DISPLAYING THE DAY AS SOON AS WE PRESS THE KEY
	MOV 	A, #0CH
	LCALL 	CMD
	LOOP3: 								;THIS LOOP IS FOR USER TO ENTER 'ENTER KEY'
	LCALL 	KEYPD						;INPUTTING THE ENTER KEY OR CLEAR KEY
	CJNE 	A, #2AH, N13 				;IF USER ENTERS * WHOLE SCREEN IS RESET
	JMP 	INPUT_DAY
	N13:
	CJNE 	A, #23H, LOOP3 				;IF USER ENTERS # IT IS CONSIDERED AS 'ENTER KEY'
	POP 	01H 						;01H STANDS FOR R1
	MOV 	A, R1
	CLR 	C 
	SUBB 	A, #30H 					;USE THIS VALUE OF DAY
	RET

;This module is error handler for the INPUT_DAY module
ERROR_DAY:
	LCALL 	FIRST 						;MOVING THE CURSOR TO FIRST LINE AS THE ERROR HAS TO BE PRINTED IN FIRST LINE
	MOV 	A, #0CH 					;TURNING OFF THE CURSOR
	LCALL 	CMD
	MOV 	DPTR, #ERROR_MSG
	LCALL 	DISP_MSG
	LCALL 	DELAY_1SEC
	JMP 	INPUT_DAY

;*************************************************************************************************
;This module is used to read hour and minute from the keypad. calling function must specify whether 
;it is set_time or set_bell by passing value on register B.
;Parameter:B -> 0H if SET_TIME B->01h if SET_BELL
;Return: value will be placed in HOURS AND MIN
;DEPENDANCIES:DISP, DISPCH2, DISP_MSG, CMD, FIRST, SECOND, KEYPD
; 									no more changes required
;*************************************************************************************************
INPUT_HOUR_MINUTE:
	LCALL	CLEAR
	MOV 	A, #01H 
	CLR 	C
	SUBB 	A, B
	JZ 		ITS_BELL
	MOV 	DPTR, #MESSAGE1
	SJMP 	NEXT
	ITS_BELL:
	MOV 	DPTR, #NEW_BELL_MSG
	NEXT:
	LCALL 	DISPCH2
	LCALL 	SECOND						;MOVING CURSOR TO SECOND LINE
	MOV 	DPTR, #MESSAGE2
	LCALL 	DISPCH2
	LCALL 	SECOND
	MOV 	A, #0FH 					;TURNING ON THE CURSOR
	LCALL 	CMD
	MOV 	R1, #5H  					;SHIFTING CURSOR 5 TIMES
	LOOP1: 
		MOV 	A, #14H	
		LCALL 	CMD
	DJNZ 	R1, LOOP1
	;STARTING TO READ THE VALUE OF HOUR
	LCALL 	KEYPD
	LCALL 	DISP
	CJNE 	A, #23H, N1					;COMPARING THE VALUE OF KEY WITH #
	SJMP 	ERROR
	N1:
	CJNE 	A, #2AH, N2 				;COMPARING THE VALUE OF KEY WITH *
	LJMP 	INPUT_HOUR_MINUTE
	N2:
	MOV 	R1,A
	CLR 	C
	SUBB 	A, #33H 					;i.e., IF ENTERED NUMBER IS GREATER THAN 2(EXAMPLE IS 30 HOURS)
	JNC 	ERROR
	CLR 	C
	MOV 	A, R1
	SUBB 	A, #30H 					;ASCII ADJUSTMENTS
	SWAP 	A 							;EX: 31H-30H=01H AFTER SWAPPING IT WILL BE 10H
	MOV 	R1, A 						;SAVING THE VALUE OF A
	LCALL 	KEYPD
	LCALL 	DISP
	CJNE 	A, #23H, N3					;COMPARING THE VALUE OF KEY WITH #
	JMP 	ERROR
	N3:
	CJNE 	A, #2AH, N4					;COMPARING THE VALUE OF KEY WITH *
	JMP 	INPUT_HOUR_MINUTE
	N4:
	CLR 	C
	SUBB 	A, #30H						;ADJUSTMENTS
	ADD 	A,R1 						;EXAMPLE CONTINUED: NOW PREVIOUS #10H IS ADDED WITH LETS SAY 2H GIVES 12H and then passed to RTC
	MOV 	R1,A 						;AGAIN SAVING
	CLR 	C
	SUBB 	A,#25H						;CHECKING IF THE HOUR VALUE IS GRATER THAN 24
	JNC 	ERROR 
	MOV 	A, #14H						;SHIFT CURSOR RIGHT ONCE TO AVOID THE COLON
	LCALL 	CMD
	MOV 	HOURS, R1
	SJMP 	READ_MINUTES

	;START OF ERROR HANDLING
	ERROR:
		LCALL 	FIRST
		MOV 	DPTR, #ERROR_MSG
		LCALL 	DISP_MSG
		LCALL 	DELAY_1SEC
		LJMP 	INPUT_HOUR_MINUTE

	;STARTING TO READ THE MINUTES 
	READ_MINUTES:
	LCALL 	KEYPD
	LCALL 	DISP
	CJNE 	A, #23H, N5					;COMPARING THE VALUE OF KEY WITH #
	SJMP 	ERROR
	N5:
	CJNE 	A, #2AH, N6					;COMPARING THE VALUE OF KEY WITH *
	LJMP 	INPUT_HOUR_MINUTE
	N6:
	MOV 	R0,A
	CLR 	C
	SUBB 	A, #36H 					;i.e., IF ENTERED NUMBER IS GREATER THAN 5(EXAMPLE IS 60 MINUTES)
	JNC 	ERROR
	MOV 	A, R0
	CLR 	C 
	SUBB 	A, #30H 					;AGAIN SAME PROCEDURES AS DONE WITH HOURS
	SWAP 	A
	MOV 	R0, A 
	LCALL 	KEYPD
	LCALL 	DISP
	CJNE 	A, #23H, N7					;COMPARING THE VALUE OF KEY WITH #
	SJMP 	ERROR
	N7:
	CJNE 	A, #2AH, N8					;COMPARING THE VALUE OF KEY WITH *
	LJMP 	INPUT_HOUR_MINUTE
	N8:
	CLR 	C 
	SUBB 	A, #30H
	ADD 	A, R0
	MOV 	R0,A
	MOV 	A, #0CH 					;TURNING OFF THE CURSOR
	LCALL 	CMD
	LOOP2:
		LCALL 	KEYPD
		CJNE 	A, #2AH, N9
		LJMP 	INPUT_HOUR_MINUTE
		N9:
		CJNE 	A, #23H, LOOP2
	MOV 	MIN, R0
	RET

;*************************************************************************************************
;*************************************************************************************************
;*																								**
;*											EEPROM MODULES  									**
;*																								**
;*************************************************************************************************
;*************************************************************************************************

;*************************************************************************************************
;This module is used to write data to EEPROM. User has to pass the starting address of the data 
;through the R0 register, location on the EEPROM through the DPTR and the count of the data through
;COUNT9. Rest everything is handled by this module
;Parameters: DPTR, R0, COUNT9
;DEPENDANCIES:EEPROM_START, EEPROM_DELAY, SEND_DATA, EEPROM_STOP
;*************************************************************************************************
WRITE_DATA:   
	LCALL 	EEPROM_START
	MOV 	A,#0A0H          
	LCALL 	SEND_DATA
	MOV 	A,DPL          		;LOCATION ADDRESS
	LCALL 	SEND_DATA
	MOV 	A,DPH         		;LOCATION ADDRESS
	LCALL 	SEND_DATA
	MOV 	EEPROM_DATA,@R0
	MOV 	A,EEPROM_DATA      	;DATA TO BE SEND
	LCALL 	SEND_DATA
	LCALL 	EEPROM_STOP
	LCALL 	EEPROM_DELAY
	LCALL 	EEPROM_DELAY
	LCALL 	EEPROM_START
	MOV 	A,#0A0H          
	LCALL 	SEND_DATA
	MOV 	A,DPL         		 ;LOCATION ADDRESS
	LCALL 	SEND_DATA
	MOV 	A,DPH          		 ;LOCATION ADDRESS
	LCALL 	SEND_DATA
	MOV 	EEPROM_DATA,@R0
	MOV 	A,EEPROM_DATA        ;DATA TO BE SEND
	LCALL 	SEND_DATA
	LCALL 	EEPROM_STOP
	LCALL	EEPROM_DELAY
	LCALL	EEPROM_DELAY
	INC 	DPTR
	INC 	R0
	DJNZ 	COUNT9,WRITE_DATA 
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
	CALL 	EEPROM_START
	MOV 	A,#0A0H
	CALL 	SEND_DATA
	MOV 	A,DPL         		 ;LOCATION ADDRESS
	CALL 	SEND_DATA
	MOV 	A,DPH         		 ;LOCATION ADDRESS
	CALL 	SEND_DATA
	CALL 	EEPROM_START
	MOV 	A,#0A1H
	CALL 	SEND_DATA
	CALL 	GET_DATA
	CALL 	EEPROM_STOP
	LCALL	EEPROM_DELAY
	LCALL	EEPROM_DELAY
	INC 	DPTR
	MOV 	@R1,3CH				 ; STORE
	INC 	R1				
	DJNZ 	COUNT9,READ_DATA
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
	SETB 	SDA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	SETB 	SCL
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLR 	SDA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLR 	SCL
	RET

;*************************************************************************************************
;This module is used to mark stop of EEPROM data flow
;stop bit is low to high transition on SDA while SCL is maintained high
;Parameters:None
;Return:None
;DEPENDANCIES:None
;*************************************************************************************************
EEPROM_STOP:    
	CLR 	SDA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	SETB 	SCL
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	SETB 	SDA
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLR 	SCL
	RET

;*************************************************************************************************
;This module sends the data to the EEPROM through Acc.
;this module rotates left the data through carry and puts the carry to the SDA pin
;Parameters:Acc
;Return:None(writes data onto EEPROM)
;DEPENDANCIES:EEPROM_DELAY, CLOCK
;*************************************************************************************************
SEND_DATA:     
	MOV 	R7,#00H
	SEND:      
		RLC 	A
		MOV 	SDA,C
		CALL 	CLOCK
		INC 	R7
		CJNE 	R7,#08,SEND
	SETB  	SDA
	NOP
	NOP	
	NOP
	NOP
	NOP	
	NOP
	SETB 	SCL
	JB 		SDA,$
	CALL 	EEPROM_DELAY
	CLR 	SCL
	CALL 	EEPROM_DELAY
	RET

;*************************************************************************************************
;This module reads the data from the EEPROM into the RAM location 3CH
;Parameters: None
;Return: data in 3CH
;DEPENDANCIES:CLOCK
;*************************************************************************************************
GET_DATA:
	SETB 	SDA   
	MOV 	R7,#00H
	CLR 	A
	GET:    
		SETB 	SCL
		NOP
		NOP	
		MOV 	C,SDA
		RLC 	A
		CLR 	SCL
		INC 	R7
		CJNE 	R7,#08,GET
	SETB 	SDA
	CALL 	CLOCK
	MOV 	3CH,A
	RET


;*************************************************************************************************
;This module generates clock for EEPROM communication
;Parameters:None
;Return:None
;DEPENDANCIES:None
;*************************************************************************************************
CLOCK:         
	SETB 	SCL
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CLR 	SCL
	RET

;*************************************************************************************************
;This module generates a delay of 3ms
;Parameters:None
;Return:None
;DEPENDANCIES:None
;*************************************************************************************************
EEPROM_DELAY:      
	MOV 	33H,#11      ;DELAY OF 3 MSEC 
	EEPROM_DELAY_1:
		MOV 	32H,#0FFH
		DJNZ 	32H,$
		DJNZ 	33H,EEPROM_DELAY_1
		RET

;*************************************************************************************************
;This module reads the stored PIN from EEPROM and loads it to RAM location 54H
;Parameters:None
;Return:PIN on RAM location 0x54
;DEPENDANCIES:READ_DATA
;*************************************************************************************************
READ_PASSWORD:
	MOV 	R1, #54H
	MOV 	DPTR, #07001H
	MOV 	COUNT9, #4H
	LCALL 	READ_DATA
	RET

;*************************************************************************************************
;*************************************************************************************************



;*************************************************************************************************
;This module is used to create new password. This module is called when button 9 is pressed during
;boot process. This module will inturn call the set mode and change password modules based on input 
;in this module.
;*************************************************************************************************
BOOT_MENU:
	LCALL 	CLEAR
	MOV 	DPTR,#BOOTMSG
	LCALL 	DISPCH2
	LCALL	SECOND
	MOV 	DPTR,#BOOTMSG1
	LCALL 	DISPCH2
	LCALL 	KEYPD 				;read the option(wait for option and read)
	;LCALL DISP
	CJNE 	A, #'#', N19
	LCALL 	UNIVERSAL_ERROR_MODULE
	SJMP 	BOOT_MENU  	
	N19:
	CJNE 	A, #'*', N20
	SJMP 	BOOT_MENU
	N20:
	CJNE 	A, #'0', N21 		;0 is INVALID
	LCALL 	UNIVERSAL_ERROR_MODULE
	SJMP 	BOOT_MENU
	N21:
	MOV 	R1, A
	CLR 	C
	SUBB 	A, #33H 			;start validating the input (valid are 0 and 1)
	JNC 	ERROR_HANDLER_BOOT_MENU
	MOV 	A, R1 
	CLR 	C
	SUBB 	A, #30H
	CJNE 	A, #01H, CHK_2 		;if not 1 then it must be 2(change password)
	MODE_MSG:
		LCALL 	CLEAR  
		MOV 	DPTR,#MODE_MSG1
		LCALL 	DISPCH2
		LCALL 	SECOND
		MOV 	DPTR,#MODE_MSG2
		LCALL 	DISPCH2 	
		LCALL 	KEYPD
		CJNE 	A, #'#', N22
		LCALL 	UNIVERSAL_ERROR_MODULE
		SJMP 	MODE_MSG
		N22:
		CJNE 	A, #'*', N23
		SJMP 	MODE_MSG
		N23:
		CJNE 	A, #'0', N24
		LCALL 	UNIVERSAL_ERROR_MODULE
		SJMP 	MODE_MSG
		N24:
		MOV 	R1, A
		CLR 	C
		SUBB 	A, #33H
		JNC 	ERROR_HANDLER_MODE_MSG
		MOV 	A, R1
		CLR 	C
		SUBB 	A, #30H
		MOV 	MODE, A
		LCALL 	SET_MODE
		MOV 	DPTR, #MODE_SET_MSG
		LCALL 	DISPCH2
		LCALL 	DELAY_1SEC
		LCALL 	CLEAR
		RET
	CHK_2:
		LCALL 	CHANGE_PASSWORD
		RET

;*************************************************************************************************
; These are needed because JNC is jump ins. and not call ins.
;*************************************************************************************************
ERROR_HANDLER_BOOT_MENU:
	LCALL 	UNIVERSAL_ERROR_MODULE
	LJMP 	BOOT_MENU
ERROR_HANDLER_MODE_MSG:
	LCALL 	UNIVERSAL_ERROR_MODULE
	LJMP 	MODE_MSG


CHANGE_PASSWORD:
	LCALL 	VER_PASSWORD
	CHANGE_PASSWORD_VERIFIED:
		LCALL 	CLEAR
		LCALL 	SET_NEW_PASSWORD
	RET

SET_NEW_PASSWORD:
	MOV 	DPTR, #PASSMSG2
	LCALL 	DISPCH2
	LCALL 	ENTER_PASSWORD_FIRST_TIME
	LCALL 	CONFIRM_PWD
	LCALL 	CREATE_PASSWORD
	LCALL 	CLEAR
	MOV 	DPTR,#CONFIRM_MSG2
	LCALL 	DISPCH2
	RET

CREATE_PASSWORD:
	MOV 	COUNT9,#04H
	MOV 	DPTR,#07001H
	MOV 	R0,#54H
	LCALL 	WRITE_DATA
	RET

ENTER_PASSWORD_FIRST_TIME: 
	LCALL 	SECOND
	MOV 	A,#0FH
	LCALL 	CMD
	MOV 	R1,#6H 
	LOOP11:
		MOV 	A,#14H 
		LCALL 	CMD
		DJNZ 	R1,LOOP11
		MOV 	R0,#54H 
		MOV 	R1,#04H
		LOOP44:
			LCALL 	KEYPD
			MOV 	@R0,A 
			CJNE 	A,#'*',N1022
			LCALL 	CLEAR
			MOV 	DPTR, #PASSMSG2
			LCALL 	DISPCH2
			SJMP 	ENTER_PASSWORD_FIRST_TIME
			N1022:
				MOV 	A,#2AH
				LCALL 	DISP 
				INC 	R0
				DJNZ 	R1,LOOP44 
		LOOP55:
			LCALL 	KEYPD
			N144:
				CJNE 	A, #'*', CHECK_FOR_ENTER_KEY
				SJMP 	ENTER_PASSWORD_FIRST_TIME
				CHECK_FOR_ENTER_KEY: 
				CJNE 	A,#'#',LOOP55
	RET


CONFIRM_PWD:
	LCALL 	CLEAR
	MOV 	DPTR,#CONFIRM_MSG1
	LCALL 	DISPCH2
	LCALL 	ENTER_PASSWORD_SECOND_TIME
	RET

ENTER_PASSWORD_SECOND_TIME:
	MOV 	FLAG2,#00H
	LCALL 	SECOND
	MOV 	A,#0FH 
	LCALL 	CMD
	MOV 	R1,#6H 
	LOOP51:
		MOV 	A,#14H
		LCALL 	CMD
		DJNZ 	R1,LOOP51
		LOOP52:
			MOV 	R0,#54H
			MOV 	R2,#04H 
			LOOP53:
				MOV 	B,@R0
				LCALL 	KEYPD
				CJNE 	A,B,CONFIRM_FAILED
				N150:
					MOV 	A,#'*'
					LCALL 	DISP
					INC 	R0
					DJNZ 	R2,LOOP53
					LOOP54:
						LCALL 	KEYPD
						CJNE 	A,#'*',N1444
						SJMP 	ENTER_PASSWORD_SECOND_TIME
						N1444:
							CJNE 	A,#'#',LOOP54
							MOV 	A,FLAG2
							CJNE 	A,#00H,AUTH_FAIL_SET_PASSWORD
							RET

CONFIRM_FAILED:
	MOV 	FLAG2,#0FFH
	SJMP 	N150

AUTH_FAIL_SET_PASSWORD:
	LCALL	CLEAR
	MOV 	DPTR, #AUTH_FAIL_MSG
	LCALL 	DISPCH2
	LCALL 	DELAY_1SEC
	LJMP 	CHANGE_PASSWORD_VERIFIED


;*************************************************************************************************
;This module writes mode bit in MEMORY
;Parameters: mode data in 6CH
;Return:None
;DEPENDANCIES: WRITE_DATA
;*************************************************************************************************
SET_MODE:
	LCALL 	CLEAR
	MOV 	R0, #7DH
	MOV 	COUNT9, #01H
	MOV 	DPTR, #07FFFH
	LCALL	WRITE_DATA
	RET


;*************************************************************************************************
;*************************************************************************************************
;*																								**
;*											RTC MODULES 										**
;*																								**
;*************************************************************************************************
;*************************************************************************************************


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
	MOV 	ADD_LOWL,#00h
	LCALL 	READ_BYTE
	MOV 	SEC,DAVAVA
	LCALL	I2C_STOP						   
	MOV   	ADD_LOWL,#01h
	LCALL 	READ_BYTE
	MOV 	MIN,DAVAVA
	LCALL	I2C_STOP
	MOV   	ADD_LOWL,#02h
	LCALL 	READ_BYTE
	MOV 	HOURS,DAVAVA
	LCALL	I2C_STOP
	MOV   	ADD_LOWL,#03h
	LCALL 	READ_BYTE
	MOV 	DAY,DAVAVA
	LCALL	I2C_STOP
    RET

;*************************************************************************************************
;This module writes the content of DAVAVA to the RTC one bit at a time
;Parameters:DAVAVA
;Return:None but RTC will br set
;DEPENDANCIES:None
;**************************************************************************************************
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
;**************************************************************************************************
;This module reads the value passed by the RTC via SDA and places it in DAVAVA
;Parameters:None passed but output depends on the value passed through the SDA before calling this
;OUTPUT: value on DAVAVA
;DEPENDANCIES:None
;**************************************************************************************************

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

;**************************************************************************************************
;**************************************************************************************************


;**************************************************************************************************
;This module is used while debugging to write some data to EEPROM
;**************************************************************************************************

CREATE_DATA:
	MOV 	COUNT9, #07H
	MOV 	DPTR,#TEMP
	MOV 	R0,#54H
	UP2:
	CLR 	A
	MOVC 	A, @A+DPTR
	MOV 	@R0, A
	INC 	R0
	INC 	DPTR
	DJNZ 	COUNT9, UP2
	MOV 	DPTR, #0001H
	MOV 	R0, #54H
	MOV 	COUNT9, #07H
	LCALL 	WRITE_DATA
	MOV 	DPTR, #0008H
	MOV 	R0, #54H
	MOV 	COUNT9, #07H
	LCALL 	WRITE_DATA
	RET


END

;**************************************************************************************************
; -------------------------------PRAY GOD THAT NO MORE BUGS WILL ARISE-----------------------------
;**************************************************************************************************