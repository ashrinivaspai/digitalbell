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

TEMP: 			DB 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H
PASSWORD: 		DB '1234',0FH

ORG    0100H

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
	;LCALL DISP
	MOV 	A, #01H
	LCALL 	CMD
	LCALL 	DELAY_1SEC
	MOV 	DPTR, #07fffH
	MOV 	COUNT9, #01H
	MOV 	54H, #31H
	MOV 	R0, #54H
	lcall write_data
	MOV 	DPTR, #07fffH
	MOV 	COUNT9, #1H
	MOV 	R1, #54H
	LCALL 	read_DATA
	mov a, 54h
	lcall disp
	;MOV 	DPTR, #INI_MSG
	;LCALL 	DISPCH2
	;LCALL 	DELAY_1SEC
	;LCALL 	DELAY_1SEC
	;LCALL 	KEYPD_NO_LOOP 
	;CJNE 	A, #39H, WELCOME
	;LCALL 	BOOT_MENU
	
	;WELCOME:
	;MOV 	A, #01H
	;LCALL 	CMD
	;MOV 	DPTR, #WELCOME_MSG 			;DISPLAY NICE WELCOME MESSAGE
	;LCALL 	DISPCH2
	;LCALL 	DELAY_1SEC
	;LCALL 	CLEAR
	;MOV 	DPTR, #WELCOME51
	;LCALL 	DISPCH2
	;MOV 	CURRENT_DAY, #00H
	LOOP:								;BEGINNING OF ACTUAL 'MAIN' LOOP
	LCALL 	DETERMINE_MODE
	SJMP 	LOOP



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
	MOV 	A,#01
	LCALL 	CMD
	RET


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
	MOV 	DPTR, #7001H
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

HEXA_DISP:
ADD A,#30h
MOV B,A
SUBB A,#39h
JC MOVE
MOV A, B
ADD A,#07H
MOVE:MOV A,B
LCALL DISP
RET

DISP_2DIG_HEXA:
MOV 5BH, A
ANL A, #0F0H
SWAP A
LCALL HEXA_DISP
MOV A, 5BH
ANL A, #0FH
LCALL HEXA_DISP
RET


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
	MOV 	R7,#5	
	HERE41:
		MOV 	R6,#0ffh        ;delay routine for firing
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
	MOV 	DPTR, #0701H
	MOV 	COUNT9, #4H
	LCALL 	READ_DATA
	RET

;*************************************************************************************************
;*************************************************************************************************

CREATE_DATA:
	MOV 	COUNT9, #0eh
	MOV 	DPTR,#temp
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
	MOV 	COUNT9, #0eH
	LCALL 	WRITE_DATA
	RET


END
