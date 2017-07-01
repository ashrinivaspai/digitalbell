											ORG  0000H
  LJMP BEGIN

	SCL			EQU    0A0h	;IN THIS EXAMPLE I USED PORT 2.0
	SDA			EQU    0A1h	;AND PORT 2.1 FOR THE I2C LINES
					        ;YOU CAN CHANGE THEM TO WHATEVER ACCEPTABLE

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
	FLAG            EQU 65H
	COUNT5          EQU 64H
	COUNT7          EQU 6BH
	hours2			EQU	62H
	mins2           EQU 63H
	 days           EQU 69H
   COUNT6           EQU 6AH
   COUNT8           EQU 68H
   COUNT9           EQU 66H
   PA1              EQU 7CH
   MEM_VAL			EQU	00H
   MSG				EQU 6CH
	ORG    0100H

BEGIN:	    LCALL	INTI
		    CLR	SCL
		    CLR	SDA
            CLR	0a2h
			CLR P3.7
		    NOP
		    SETB	SCL
		    SETB	SDA
		    NOP
			;LCALL CREATE_PASSWORD
			CLR 	MEM_VAL	
			LCALL FIRST
			MOV DPTR,#INI_MSG
			LCALL DISPCH2
			LCALL   DELAY_3SEC
			
CHECK_9:LCALL KEYPD1
LCALL DISP
CJNE A,#39H,WELCOME
LCALL NEW_PASSWORD	
			
WELCOME:	LCALL CLEAR
            LCALL DISP_WELCOME			 
			LCALL DELAY_1SEC
			LCALL DISP_BELL_SYSTEM

MEM_ENTRY:	LCALL	READ_RTC
            LCALL 	DISP_SYSTEM_BELL_TIME
			LCALL MODE_DISP 
			
			
			LCALL   DISP_NXT_BELL_MSG
			LCALL   DAYDP1
			LCALL   DAYDP2
			SJMP 	MEM_ENTRY
LOAD_BELL_TIME:	 JB	MEM_VAL,LOAD_BELL
				 RET
LOAD_BELL:		LCALL	READ_MEM_STATUS
			   
			JB 	MEM_VAL , MEM_ENTRY
			LCALL 	NO_BELL_DISPLAY
			LCALL	DELAY_3SEC
			RET	
	

NO_BELL_DISPLAY: LCALL SECOND
			 MOV DPTR,#NO_BELL_DISP
			 LCALL DISPCH2
             LCALL DELAY_1SEC
			 RET

MODE_DISP:MOV DPTR,#7FFFH
		  MOV COUNT9, #01H
		  LCALL READ_DATA
		  
		  CJNE R0,#01H, DISP_MSG9
		  CJNE R0,#02H, DISP_MSG8
		    RET
//display bell time	
		
DAYDP1:     MOV 40H,hours2
     	    LCALL	UNPACK
     	    LCALL BELLH1        //LOAD HOURS
		    MOV	A,R3
	        LCALL  DISP
	        LCALL BELLH2
		    MOV	A,R2
	        LCALL  DISP
         	LCALL BELLC
	        MOV	A,#':'
	        LCALL  DISP
	    	RET

DAYDP2:	    MOV	40H,mins2
	        LCALL	UNPACK
	        LCALL BELLM1
	        MOV	A,R3          //LOAD MINUTES
	        LCALL  DISP
	        MOV A,#0CFH
		    LCALL CMD
		    MOV	A,R2
	        LCALL  DISP
		    RET

DISP_MSG8:LCALL FIRST 
 	MOV R1, #0DH 			;SHIFTING CURSOR 11 TIMES
	LOOP2: MOV A, #14H	
	LCALL CMD
	DJNZ R1, LOOP2
	MOV DPTR,#MSG8
	LCALL DISPCH2
	RET

 		
DISP_MSG9:LCALL FIRST 
 	MOV R1, #0DH 			;SHIFTING CURSOR 11 TIMES
	LOOP3: MOV A, #14H	
	LCALL CMD
	DJNZ R1, LOOP3
	MOV DPTR,#MSG9
	LCALL DISPCH2
	RET

DISP_WELCOME:LCALL FIRST
			 MOV DPTR,#WELCOME1
			 LCALL DISPCH2
             LCALL DELAY_1SEC
			 RET
DISP_NXT_BELL_MSG:LCALL SECOND
			 MOV DPTR,#WELCOME52
			 LCALL DISPCH2
             LCALL DELAY_1SEC
			 RET

NEWBELL:LCALL FIRST
		MOV DPTR,#NEW_BELL
		LCALL DISPCH2
		RET
EDITBELL:LCALL SECOND
		MOV DPTR,#EDIT_BELL
		LCALL DISPCH2
		RET
					   			 
READ_MEM_STATUS: MOV DPTR,#0X0100   ; RETURNS BELL COUNT IN ACC AND STATUS IN MEM_VAL BIT
				 MOV COUNT9,#01
				 MOV R1,#79H
				 LCALL	READ_DATA
				 MOV A,79H
				 CJNE	A,#00H,SET_STATUS
				 CLR    MEM_VAL	
				 RET
SET_STATUS:	 SETB	MEM_VAL
				 RET
  
SET_NO:
        LCALL KEYPD				;READ A CHARACTER
		LCALL DISP
			  
		CJNE A, #23H, N10		;COMPARING THE VALUE OF KEY WITH #
		LJMP ERROR_DAY
		N10:
		CJNE A, #2AH, N11		;COMPARING THE VALUE OF KEY WITH *
		LJMP ERROR_DAY
		N11:
		CJNE A, #30H, N12		;COMPARING THE VALUE OF KEY WITH 0 AS VALID CHARACTERS ARE ONLY 1-7
		LJMP ERROR_DAY
		N12:
		MOV R1,A 				;SAVING THE VALUE OF A
		SUBB A, #33H 			;ERROR CHECKING BY CHECKING IF THE ANSWER COMES OUT NEGATIVE
		JNC ERROR_DAY 			;EX: INPUT IS 37H(VALID) SO 37H-38H=-1H HENCE C=1. HENCE VALID
		CLR C 					;EX: IF INPUT IS 39H(INVALID) SO ASNWER IS 1H AND C=0. HENCE INVALID
	
		MOV A,R1 				;RESTORING THE VALUE OF A
		SUBB A, #30H 			;GETTING ACTUAL VALUE FROM ASCII VALUE
		
		CJNE A,#01H,CHK_2
MODE_MSG:LCALL CLEAR  
LCALL FIRST
MOV DPTR,#MODE_MSG1
LCALL DISPCH2
LCALL SECOND
MOV DPTR,#MODE_MSG2
LCALL DISPCH2
SET_NO1:
        LCALL KEYPD				;READ A CHARACTER
		;LCALL DISP
			  
		CJNE A, #23H, N101		;COMPARING THE VALUE OF KEY WITH #
		LJMP ERROR_DAY1
		N101:
		CJNE A, #2AH, N111		;COMPARING THE VALUE OF KEY WITH *
		LJMP ERROR_DAY1
		N111:
		CJNE A, #30H, N121		;COMPARING THE VALUE OF KEY WITH 0 AS VALID CHARACTERS ARE ONLY 1-7
		LJMP ERROR_DAY1
		N121:
		MOV R1,A 				;SAVING THE VALUE OF A
		SUBB A, #33H 			;ERROR CHECKING BY CHECKING IF THE ANSWER COMES OUT NEGATIVE
		JNC ERROR_DAY1 			;EX: INPUT IS 37H(VALID) SO 37H-38H=-1H HENCE C=1. HENCE VALID
		CLR C 					;EX: IF INPUT IS 39H(INVALID) SO ASNWER IS 1H AND C=0. HENCE INVALID
	
		MOV A,R1 				;RESTORING THE VALUE OF A
		SUBB A, #30H 			;GETTING ACTUAL VALUE FROM ASCII VALUE
		
		CJNE A,#01H,CHK_2N
		MOV MSG,#01H
		LCALL SET_MODE
		LCALL WELCOME
CHK_2N:	CJNE	A,#02H,ERROR_DAY1	
		MOV MSG,#02H
		LCALL SET_MODE
		LCALL WELCOME
		
		 
CHK_2:	CJNE	A,#02H,NEW_PASSWORD
        LCALL  CHANGE_PASSWORD
 NEW_PASSWORD:LCALL CLEAR
 			  LCALL 	FIRST
			  MOV DPTR,#PASSMSG


			 LCALL DISPCH2
			LCALL	SECOND
			MOV DPTR,#PASSMSG1
			LCALL DISPCH2
			LCALL SET_NO

 ERROR_DAY:
		LCALL FIRST 			;MOVING THE CURSOR TO FIRST LINE AS THE ERROR HAS TO BE PRINTED IN FIRST LINE
		MOV A, #0CH 			;TURNING OFF THE CURSOR
		LCALL CMD
		MOV DPTR, #ERROR_MSG
		LCALL CLEAR
		LCALL DISPCH2
		LCALL DELAY_1SEC
		
		JMP NEW_PASSWORD
			 

 ERROR_DAY1:
		LCALL FIRST 			;MOVING THE CURSOR TO FIRST LINE AS THE ERROR HAS TO BE PRINTED IN FIRST LINE
		MOV A, #0CH 			;TURNING OFF THE CURSOR
		LCALL CMD
		MOV DPTR, #ERROR_MSG
		LCALL CLEAR
		LCALL DISPCH2
		LCALL DELAY_1SEC
		 LJMP MODE_MSG
					
CHANGE_PASSWORD:  LCALL VER_PASSWD 		;ENTER PASSWORD VER MODULE
      			  MOV B, #00H 			
	              CJNE A, B, AUTH_FAIL 	
	              LCALL CLEAR
	              LCALL DISP_NEW_PWD 
	              RET
	AUTH_FAIL:
		MOV A,#01H
		LCALL CMD
		MOV DPTR, #AUTH_MSG
		LCALL DISPCH2
		LCALL DELAY_1SEC
		SJMP CHANGE_PASSWORD		;AGAIN GO BACK TO FIRST STEP

DISP_NEW_PWD: LCALL FIRST
			  MOV DPTR,#PASSMSG2
			  LCALL DISPCH2
			  LCALL BLINK2
			  LCALL CONFIRM_PWD
PASSWORD_SET: LCALL CLEAR
 	          LCALL FIRST
           	MOV DPTR,#CONFIRM_MSG2
        	LCALL DISPCH2
			LCALL CREATE_PASSWORD 
			  
			  LCALL DELAY_1SEC
			  MOV A,#0EH
			   MOV A,#0CH
			  LCALL  CMD
			  
			  LCALL  WELCOME
			  RET

CONFIRM_PWD:LCALL CONFIRM_MSG
			LCALL BLINK1
			RET
		BLINK1:	LCALL SECOND			;MOVING CURSOR TO SECOND LINE
	         MOV A, #0FH 			;TURNING ON THE CURSOR
           	 LCALL CMD
         	 MOV R1, #6H
			  		
				
	LOOP51: MOV A, #14H	  ;SHIFTING CURSOR 6 TIMES
	LCALL CMD
	DJNZ R1, LOOP51
		
		
LOOP52:	MOV R0,#54H			;NOW 4 CHARACTER PIN WILL BE LOCATED FROM 54H ONWARDS
	                 ;POINTING THE BEGINNING OF THE PIN TO R0						
	MOV FLAG,#00H
	MOV R2,#04H				;COUNTER
	LOOP53:
	MOV B, @R0				
	LCALL KEYPD
	CJNE A,B, SET_FLAG1 		;IF NOT EQUAL THEN SET FLAG
	N150:
	MOV A, #2AH 				;WE HAVE TO DISPLAY * AND NOT THE DIGIT THAT WAS ENTERED
	LCALL DISP
	INC R0 					;POINT TO NEXT DIGIT ON RAM
	DJNZ R2, LOOP53

	LOOP54:
	LCALL KEYPD
	CJNE A, #2AH, N1444

	N1444:
	CJNE A, #23H, LOOP54
	 			;AS PROMISED RETURN SHOULD BE IN Acc.
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
	 		   
SET_FLAG1:
	MOV FLAG, #0FFH
		MOV A,#01H
		LCALL CMD
		MOV DPTR, #AUTH_MSG
		LCALL DISPCH2
		LCALL DELAY_1SEC
		LJMP DISP_NEW_PWD
	


	CONFIRM_MSG:LCALL CLEAR
	LCALL FIRST
	MOV DPTR,#CONFIRM_MSG1
	LCALL DISPCH2
			   RET


 KEYPD1:   
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

 DISP_BELL_SYSTEM:LCALL FIRST
			 MOV DPTR,#WELCOME51
			 LCALL DISPCH2
             LCALL DELAY_1SEC
			 RET

 CLEAR:MOV A,#01H
      LCALL CMD
	  RET

FIRST:MOV A,#80H
      LCALL CMD
	  RET
SECOND:MOV A,#0C0H
      LCALL CMD
	  RET
THIRD:MOV A,#0C1H
      LCALL CMD
      RET
FOURTH:MOV A,#0C2H
      LCALL CMD
      RET
FIFTH:MOV A,#0C3H
      LCALL CMD
      RET


TWO:MOV A,#081H
      LCALL CMD
	  RET
THREE:MOV A,#082H
      LCALL CMD
      RET
FOUR:MOV A,#083H
      LCALL CMD
      RET
FIVE:MOV A,#084H
      LCALL CMD
      RET
SIX :MOV A,#87H
      LCALL CMD
	  RET

BELLH1:  MOV A,#0CBH
      LCALL CMD
	  RET
BELLH2:  MOV A,#0CCH
      LCALL CMD
	  RET
BELLC:MOV A,#0CDH
      LCALL CMD
      RET
BELLM1: MOV A,#0CEH
      LCALL CMD
      RET
BELLM2: MOV A,#0CFH
      LCALL CMD
      RET

DELAY_1SEC:MOV R7,#10			;delay routine for firing
HERE4:  MOV R6,#0ffh                      
HERE31: MOV     R5,#0ffH
REPEAT1:DJNZ    R5,REPEAT1
        DJNZ    R6,HERE31
	    DJNZ	R7,HERE4	
        RET

DISPCH2:nop
UP11:	CLR A
	MOVC A,@A+DPTR 	;use lookup table to get ascii character
	CJNE A,#0FH,SKIP
	RET
	
		
CMD:	LCALL READY
	MOV  80H,A
	CLR 0A5H	; low on RS
	CLR 0A6H
	SETB 0A7H	 ; high to low on En line
	CLR 0A7H
	RET

READY:	CLR	0A7H  ;read busy flag
	MOV	80H,#0FFH
	CLR	0A5H
	SETB	0A6H
WAIT:	CLR	0A7H
	SETB	0A7H
	JB	87H,WAIT
	RET


SKIP:	INC DPTR
	LCALL  DISP
	SJMP UP11
UNPACK:MOV A,40h
	ANL	A,#0FH
	ADD	A,#30h
	MOV	R2,A
	MOV A,40h	
	SWAP	A
	ANL	A,#0FH
	ADD	A,#30H
	MOV	R3,A
	RET

DISP:LCALL	READY
	MOV  80H, A		                            ;DISPLAY SINGLE CHARACTER
	SETB	0A5H	 ; high RS
	CLR	0A6H	;; low RW
	SETB	0A7H	; high to low En 
	CLR	0A7H
    RET


INTI:	MOV A,#3CH	;refer manual for the bit meaning
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


READ_RTC:
				   //READING TIME
;==================================================READS MINUTES
			MOV     ADD_LOWL,#01h
			LCALL   READ_BYTE
			MOV 	MIN,DAVAVA
			LCALL	I2C_STOP
;==================================================READS HOURS
			MOV     ADD_LOWL,#02h
			LCALL   READ_BYTE
			MOV 	HOURS,DAVAVA
			LCALL	I2C_STOP
;==================================================READS DAYS
			 MOV     ADD_LOWL,#03h
			LCALL   READ_BYTE
			MOV 	DAY,DAVAVA
			LCALL	I2C_STOP
	        RET
			
I2C_Stop:
	CLR       SDA
	SETB      SCL
	NOP
	SETB      SDA
	RET
LOOP_BYTE:             PUSH    02H
                       MOV     R2,#08H
LOOP_SEND:             RLC     A
                       MOV     SDA,C
                       SETB    SCL
                       CLR     SCL
                       DJNZ    R2,LOOP_SEND
                       POP     02H
                       RET

;*****************************************************			
READ_BYTE:             CLR     SDA                   ;start bit
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
;*****************************************************
LOOP_READ:             PUSH   02H
                       MOV    R2,#08H
LOOP_READ1:            SETB   SCL
                       MOV    C,SDA
                       CLR    SCL
                       RLC    A
                       DJNZ   R2,LOOP_READ1
                       MOV    DAVAVA,A
                       POP    02H
                       RET


DISP_SYSTEM_BELL_TIME:LCALL CLEAR
                      LCALL DISP_TIME
					  LCALL	DAYDP5
					  LCALL	DAYDP3
					
// display day 
DISP_TIME:
MOV	A,DAY
	MOV	 DPTR,#MSG1
	CJNE	A,#01,NXT2
	SJMP	DAYDP
NXT2:	MOV	 DPTR,#MSG2
	CJNE	A,#02,NXT3
	SJMP	DAYDP
NXT3:	MOV	 DPTR,#MSG3
	CJNE	A,#03,NXT4
	SJMP	DAYDP
NXT4:	MOV	 DPTR,#MSG4
	CJNE	A,#04,NXT5
	SJMP	DAYDP
NXT5:	MOV	 DPTR,#MSG5
	CJNE	A,#05,NXT9
	SJMP	DAYDP

NXT9:	MOV	 DPTR,#MSG6
	CJNE	A,#06,NXT10
	SJMP	DAYDP
NXT10:	MOV	 DPTR,#MSG7
	CJNE	A,#07,DAYDP
DAYDP:
LCALL SIX
LCALL DISPCH2
 RET



MSG1:	DB 'MON ',0FH
MSG2:	DB 'TUE ',0FH
MSG3:	DB 'WED ',0FH
MSG4:	DB 'THU ',0FH
MSG5:	DB 'FRI ',0FH
MSG6:	DB 'SAT ',0FH
MSG7:	DB 'SUN ',0FH
MSG8:	DB  'M1',0FH
MSG9:	DB	'M2',0FH
INI_MSG: DB'INITIALISING...',0FH
	
//display system time
DAYDP5: 
MOV	40H,HOURS
     	    MOV A,40H
	        ANL	A,#1FH
	        MOV	40H,A
	        LCALL UNPACK
     	    LCALL TWO
	    	MOV	A,R3
	        LCALL  DISP
	        LCALL THREE
		    MOV	A,R2
	        LCALL  DISP
            LCALL FOUR
	        MOV	A,#':'
	        LCALL  DISP
			RET
  DAYDP3:          MOV	40H,MIN
	        LCALL UNPACK
	        LCALL FIVE
	        MOV	A,R3
	        LCALL  DISP
			
			
	        MOV A,#085H
		    LCALL CMD
		    MOV	A,R2
	        LCALL  DISP
		    MOV A,#086H
		    LCALL CMD
	        MOV	A,#' '
	        LCALL  DISP
			RET
DELAY_3SEC:     MOV R0,#03
MAKEDELAY:		LCALL	DELAY_1SEC
				DJNZ	R0,MAKEDELAY
				RET	
SET_FLAG:
	MOV FLAG, #0FFH
		LCALL AUTH_FAIL
		
	

READ_PASSWORD:
	MOV R1, #54H
	MOV DPTR, #7001H
	MOV COUNT9, #4H
	LCALL READ_DATA
	RET

VER_PASSWD:
	MOV A, #01H
	LCALL CMD
	MOV DPTR, #MESSAGE4 	
	LCALL DISPCH2			;CAN BE REPLACED WITH DISP_MSG(LATTER WILL ADD 1Sec DELAY)
	BLINK:LCALL SECOND

	MOV A, #0FH 			;BLINKING CURSOR
	LCALL CMD
	MOV R1, #6H 			;SHIFTING CURSOR 6 TIMES
	LOOP1: MOV A, #14H	
	LCALL CMD
	DJNZ R1, LOOP1
	MOV R0,#54H
	LCALL READ_PASSWORD		;NOW 4 CHARACTER PIN WILL BE LOCATED FROM 54H ONWARDS
					        ;POINTING THE BEGINNING OF THE PIN TO R0			
	MOV FLAG,#00H
	MOV R1,#04H				;COUNTER
	LOOP4:
	MOV B, @R0				
	LCALL KEYPD
	CJNE A,B, SET_FLAG 		;IF NOT EQUAL THEN SET FLAG
	N102:
	MOV A, #2AH 				;WE HAVE TO DISPLAY * AND NOT THE DIGIT THAT WAS ENTERED
	LCALL DISP
	INC R0 					;POINT TO NEXT DIGIT ON RAM
	DJNZ R1, LOOP4
	LOOP5:
	LCALL KEYPD
	CJNE A, #2AH, N14
	JMP VER_PASSWD
	N14:
	CJNE A, #23H, LOOP5
	MOV A, FLAG 			;AS PROMISED RETURN SHOULD BE IN Acc.
	RET

KEYCODE:DB '1','2','3','4','5','6','7','8','9','*','0','#'
welcome1:   db '    WELCOME!  ',0fh
welcome51:  db '  BELL SYSTEM  ',0fh
welcome52:  db 'NXT BELTME:',0fh
NO_BELL_DISP:	db '    No Bell!    ' ,0fh
NEW_BELL:db 'PRESS 1:NEW BELL'  ,0fh
EDIT_BELL: db '     2:EDIT BELL' ,0fh
PASSMSG:db'PRESS 1:MODE',0fh
PASSMSG1:db '      2:PASSWORD',0fh
ERROR_MSG: db ' INVALID NUMBER ', 0fh
MESSAGE4: db 'ENTR OLD PASSWRD',0fh
AUTH_MSG: db ' INCORRECT  PIN ', 0fh
PASSMSG2:db'SET NEW PASSWORD',0fh
CONFIRM_MSG1:db'CONFIRM PASSWORD',0fh
CONFIRM_MSG2:db'NEW PASSWORD SET',0fh
MODE_MSG1:db'PRESS 1:MODE 1',0fh
MODE_MSG2:db'	   2:MODE 2',0fh
PASSWORD: db '1234', 0fh

//EEPROM
	write_data:     call eeprom_start
                mov a,#0a0h          
                call send_data
				
                mov a,DPL          ;location address
                call send_data
				
                mov a,DPH          ;location address
                call send_data
				mov eeprom_data,@R0
                mov a,eeprom_data              ;data to be send
                call send_data
				
                call eeprom_stop
				lcall eeprom_delay
				;lcall eeprom_delay
				
				
				INC DPTR
				INC R0
				DJNZ COUNT9,write_data 
                ret   
;=========================================================
read_data:      call eeprom_start
                mov a,#0a0h
                call send_data
                mov a,DPL          ;location address
                call send_data
                mov a,DPH          ;location address
                call send_data
                call eeprom_start
                mov a,#0a1h
                call send_data
                call get_data
                call eeprom_stop
				;lcall	eeprom_delay
				lcall	eeprom_delay
				INC DPTR
				MOV @R1,3ch; STORE
                 INC R1				
				DJNZ COUNT9,read_data
                ret
;=========================================================
eeprom_start:   setb SDA
                nop
				nop
                nop
				nop
                nop
				nop
                nop
                setb SCL
                nop
                nop
				nop
                nop
				nop
                nop
				nop
                nop
                clr SDA
                nop
				nop
                nop
				nop
                nop
				nop
                nop
                clr SCL
                ret
;=========================================================
eeprom_stop:    clr SDA
                nop
				nop
                nop
				 nop
                nop
				nop
                nop
                setb SCL
                nop
                nop
				nop
                nop
				 nop
                nop
				nop
                nop
                setb SDA
                nop
				nop
                nop
				 nop
                nop
				nop
                nop
                clr SCL
                ret
;=========================================================
send_data:     mov r7,#00h
	send:      rlc a
               mov SDA,c
               call clock
               inc r7
               cjne r7,#08,send
		       ;clr	0b7h
			   setb  SDA
			    nop
               nop	
               nop
			    nop
               nop	
               nop
			   setb SCL
				
				
		      jb SDA,$
			  call eeprom_delay
			  clr SCL
              call eeprom_delay
		      ;clr SCL
		
		      ;setb	0b7h
              ;call eeprom_delay
              
               ret
;=========================================================
get_data: setb SDA   
          mov r7,#00h
          CLR A
get:    setb SCL
               nop
               nop	
             
           
               mov c,SDA
		       rlc a
		       clr SCL
				
               inc r7

               
               cjne r7,#08,get
               setb SDA
               call clock
               mov 3ch,a
               ret
;=========================================================
clock:         setb SCL
               nop
               nop
			   nop
               nop
			   nop
               nop
			   nop
               nop
               clr SCL
               ret
;=========================================================
eeprom_delay:      mov 33h,#11      ;delay of 3 msec 
eeprom_delay_1:    mov 32h,#0ffh
                   djnz 32h,$
                   djnz 33h,eeprom_delay_1
                   ret
BLINK2:LCALL SECOND

	MOV A, #0FH 			;BLINKING CURSOR
	LCALL CMD
	MOV R1, #6H 			;SHIFTING CURSOR 6 TIMES
	LOOP11: MOV A, #14H	
	LCALL CMD
	DJNZ R1, LOOP11
	MOV R0,#54H			

	MOV R1,#04H				;COUNTER
	LOOP44:
	LCALL KEYPD
	MOV @R0,A
	CJNE A,#2AH,N1022
	MOV A,#10H
	LCALL CMD		
	N1022:
	MOV A, #2AH 				;WE HAVE TO DISPLAY * AND NOT THE DIGIT THAT WAS ENTERED
	LCALL DISP
	INC R0 					;POINT TO NEXT DIGIT ON RAM
	DJNZ R1, LOOP44
LOOP55:
    LCALL KEYPD	
	
   
	N144:
	CJNE A, #23H,LOOP55 
	 			;AS PROMISED RETURN SHOULD BE IN Acc.
	RET

SET_MODE:
	CLR A
	MOVC A, @A+DPTR
	MOV DPTR, #7FFFH
	MOV R0, #6CH
	LCALL WRITE_DATA
	RET


CREATE_PASSWORD:

	MOV COUNT9, #04H
	MOV DPTR,#7001H
	MOV R0,#54H
	
	LCALL WRITE_DATA
	

	RET

END