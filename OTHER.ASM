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
			CLR 	MEM_VAL
		    LCALL DISP_WELCOME
			LCALL DELAY_1SEC
			
			LCALL DISP_BELL_SYSTEM
			
			
			JB 	MEM_VAL , MEM_ENTRY
			
			LCALL	DELAY_3SEC
MEM_ENTRY:	LCALL	READ_RTC
            LCALL 	DISP_SYSTEM_BELL_TIME 
			
			LCALL	DISP_NXT_BELL_MSG
			SJMP 	MEM_ENTRY




			 

		    
		
			
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




	  	  
ONE:MOV A,#80H
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
							  


DELAY_1SEC:MOV R7,#10	
HERE4:  MOV R6,#0ffh                      ;delay routine for firing
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
			                            ;DISPLAY SINGLE CHAR
	MOV  80H, A
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

			MOV     ADD_LOWL,#02h
			LCALL   READ_BYTE
			MOV 	HOURS,DAVAVA
			LCALL	I2C_STOP

			 MOV     ADD_LOWL,#03h
			LCALL   READ_BYTE
			MOV 	DAY,DAVAVA
			LCALL	I2C_STOP

;==================================================READS HOURS
		
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

			;******************************************************
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


DISP_SYSTEM_BELL_TIME:
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
LCALL	DISPCH2
 RET


 MSG1:	DB 'SUN_DAY ',0FH
MSG2:	DB 'MON_DAY ',0FH
MSG3:	DB 'TUE_DAY ',0FH
MSG4:	DB 'WED_DAY ',0FH
MSG5:	DB 'THU_DAY ',0FH
MSG6:	DB 'FRI_DAY ',0FH
MSG7:	DB 'SAT_DAY ',0FH
	
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


welcome1:   db '    WELCOME!  ',0fh
welcome51:  db '  BELL SYSTEM  ',0fh
welcome52:  db 'NXT BELTME:     ',0fh
END

