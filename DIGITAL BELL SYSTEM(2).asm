					 																	 						  						 									 				


    ORG 0000H
    ljmp BEGIN
;===================================================================================

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
   COUNT8           EQU  68H
   COUNT9           EQU  66H
   PA1              EQU 7CH
   MEM_VAL			EQU	00H
	ORG    0100H

;==================================================================================
;=====THIS PROCEDURE INITIATES THE DS1307, WITHOUT IT THE DS1307 WON'T START!!!!!!

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
		    
			LCALL	READ_MEM_STATUS
			JB 	MEM_VAL , MEM_ENTRY
			LCALL	NO_TIME_DISP
			LCALL	DELAY_3SEC
MEM_ENTRY:	LCALL	READ_RTC
			LCALL	LOAD_BELL_TIME
			JNB	MEM_VAL , NO_BELL
			LCALL	CHECK_BELL
NO_BELL	:	LCALL	CHECK_KEYS
			LCALL	DISP_TIME_BELL
			SJMP	MEM_ENTRY    


			
NORMALCONT: NOP
			;LCALL SETIME
            LCALL INTI
			
MAKEGAIN:  	
            LCALL FIRST               ; cursor to the first line
			LCALL INIT_PORT           ;read rtc
			LCALL DISPTIME            ;display rtc
			LCALL DAYDP
            LCALL DAYDP5
            LCALL DAYDP3
            LCALL DAYDP4
		    LCALL POLL_SWITCH
			LCALL DELAY
			LCALL COMP_DAY
			SJMP  MAKEGAIN
			
DISP_WELCOME:LCALL FIRST
			 MOV DPTR,#WELCOME1
			 LCALL DISPCH2
             LCALL DELAY_1SEC
			 
			 RET
			 
LOAD_BELL_TIME:	 JB	MEM_VAL,LOAD_BELL
				 RET
LOAD_BELL:		


			 
			 
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

DELAY_3SEC:     MOV R0,#03
MAKEDELAY:		LCALL	DELAY_1SEC
				DJNZ	R0,MAKEDELAY
				RET	

NO_TIME_DISP:	MOV DPTR,#NO_BELL
				LCALL	CLEAR
				LCALL	FIRST
				LCALL	DISPCH2
				RET


// display day 
DISPTIME:
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
LCALL FIRST
LCALL	DISPCH2
RET
	
//display syatem time
DAYDP5: 
MOV	40H,HOURS
     	    MOV A,40H
	        ANL	A,#1FH
	        MOV	40H,A
	        LCALL	UNPACK
     	    LCALL SECOND
	    	MOV	A,R3
	        LCALL  DISP
	        LCALL THIRD
		    MOV	A,R2
	        LCALL  DISP
            LCALL FOURTH
	        MOV	A,#':'
	        LCALL  DISP
			RET
  DAYDP3:          MOV	40H,MIN
	        LCALL UNPACK
	        LCALL FIFTH
	        MOV	A,R3
	        LCALL  DISP
			
			
	        MOV A,#0C4H
		    LCALL CMD
		    MOV	A,R2
	        LCALL  DISP
		    MOV A,#0C5H
		    LCALL CMD
	        MOV	A,#':'
	        LCALL  DISP
			RET
 DAYDP4:           MOV	40H,SEC
	        LCALL UNPACK
	        MOV A,#0C6H
		    LCALL CMD
	        MOV	A,R3
	        LCALL  DISP
	        MOV A,#0C7H
		    LCALL CMD
		    MOV	A,R2
	        LCALL  DISP
	        RET
			
//display bell time			
DAYDP1:     MOV 40H,hours2
     	    LCALL	UNPACK
     	    LCALL SECOND        //LOAD HOURS
		    MOV	A,R3
	        LCALL  DISP
	        LCALL THIRD
		    MOV	A,R2
	        LCALL  DISP
         	LCALL FOURTH
	        MOV	A,#':'
	        LCALL  DISP
	    	RET

DAYDP2:	    MOV	40H,mins2
	        LCALL	UNPACK
	        LCALL FIFTH
	        MOV	A,R3          //LOAD MINUTES
	        LCALL  DISP
	        MOV A,#0C4H
		    LCALL CMD
		    MOV	A,R2
	        LCALL  DISP
		    RET
			
			
SETPASS:LCALL CLEAR
     	LCALL FIRST
		MOV DPTR,#WELCOME12			 //ENTER PASSSWORD
		LCALL	DISPCH2
		MOV COUNT9,#04H
		MOV R0,#46H
		
		LCALL SECOND
		LCALL PASS	
		MOV DPTR,#2000H
		MOV R1,#6CH
		MOV COUNT9,#04H
	
        LCALL read_data
MOV COUNT9,#04H		
		MOV R0,#46H
		MOV R1,#6CH
		MOV DPTR,#2000H
		LCALL CLEAR
		LCALL FIRST
		MOV R1,#31H   
REPEAT3:MOV A,@R0
;LCALL DISP
;LCALL DELAY_1SEC
               //verification of password
		MOV PA1,R1
		
        CJNE A,PA1,NEXT6
		LCALL NEXT30
		RET
NEXT30:		INC R1
		INC R0
		DJNZ COUNT9,REPEAT3
		LCALL DELAY_1SEC
		RET		

NEXT6:LCALL FIRST
      MOV DPTR,#WELCOME41  //CORRECTNESS OF TIME
	  LCALL DISPCH2
	  LCALL DELAY_1SEC
	  LCALL CLEAR1
	 MOV A,#01H
	  RET

// set system time
SETTIME:LCALL CLEAR
        LCALL FIRST
		LCALL SETPASS
		CJNE A,#01H,NEXT31
		RET
NEXT31:		LCALL CLEAR
		LCALL FIRST
		MOV DPTR,#WELCOME11 
		LCALL	DISPCH2
            LCALL DELAY_1SEC
	    LCALL	DELAY_1SEC
		LCALL CLEAR
		LCALL FIRST
		MOV DPTR,#WELCOME50
		LCALL DISPCH2
		LCALL DELAY_1SEC
		LCALL CLEAR
           LCALL FIRST
		   MOV DPTR,#WELCOME16
		   LCALL	DISPCH2
	       LCALL SECOND
		   MOV 	DPTR,#WELCOME17		//SUNDAY 01,MONDAY 02.......
		   LCALL	DISPCH2
		   LCALL DELAY_1SEC
		   LCALL DELAY_1SEC
	    LCALL CLEAR
	    LCALL FIRST
		MOV DPTR,#WELCOME43
		LCALL DISPCH2
		LCALL DELAY_1SEC
		LCALL SECOND
		MOV DPTR,#WELCOME47	  //HH:MM:SS
		LCALL	DISPCH2
		LCALL DELAY_1SEC
		LCALL CLEAR1
		LCALL SYSTIME
		CJNE A,#01H,NEXT35
 RET
NEXT35:		LCALL CLEAR1
		RET
		
//enter bell time		
		 
ENTERPASS2:LCALL CLEAR
LCALL FIRST
LCALL SETPASS
LCALL CLEAR
		  LCALL NUMBER_BELL
		   
           RET


NUMBER_BELL:
             
            LCALL FIRST
	     	MOV DPTR,#WELCOME18	    //NUMBER OF BELLS AND CHANGE BELL TIMINGS
		    LCALL	DISPCH2
		    LCALL DELAY_1SEC
			LCALL DELAY_1SEC
		    LCALL OPT_1
		    RET


OPT_1:    LCALL FIRST
		   MOV DPTR,#WELCOME14
		   LCALL	DISPCH2
		   LCALL SECOND
		   MOV DPTR,#WELCOME15
		   LCALL DISPCH2		    //ENTER DAY NUMBER AND PRESS ENTER
		   LCALL	DELAY_1SEC
           LCALL FIRST
		   MOV DPTR,#WELCOME16
		   LCALL	DISPCH2
	       LCALL SECOND
		   MOV 	DPTR,#WELCOME17		//SUNDAY 01,MONDAY 02.......
		   LCALL	DISPCH2
           LCALL DELAY_1SEC
		   MOV R0,#70H
		   LCALL DAYNUM
		   RET
 
INCRE:	   INC R0
           LCALL DAYNUM
		   RET

DAYNUM:    LCALL KEYPD
		   MOV @R0,A                   //store days
		   CJNE @R0,#23H,INCRE 
		   MOV A,R0
		   SUBB A,#70H
		   MOV COUNT9,A
		   MOV COUNT1,COUNT9
		   MOV DPTR,#2010H
		   


		  MOV R0,#70H
		  lcall write_data 
          LCALL CLEAR
          LCALL FIRST
          MOV COUNT9,COUNT1
          MOV DPTR,#2010H
		  MOV R1,#70H
          LCALL read_data
	       MOV R0,#70H
		   MOV COUNT9,COUNT1
		   LCALL CLEAR
		   LCALL FIRST
REPEAT5:MOV A,@R0
INC R0
LCALL DISP
LCALL DELAY_1SEC
DJNZ COUNT9,REPEAT5	  
		  
          
	LCALL CLEAR
	LCALL FIRST
                                //PRESS '#' TO EXIT
        MOV DPTR,#WELCOME20
		LCALL	DISPCH2			  //ENTER NUMBER OF BELLS IN A DAY
		LCALL SECOND
		MOV 	DPTR,#WELCOME21
		LCALL	DISPCH2
		LCALL	DELAY_1SEC
		LCALL DELAY_1SEC
        LCALL CLEAR
	    LCALL FIRST
		MOV DPTR,#WELCOME49
		LCALL DISPCH2
		LCALL KEYPD
		ANL A,#0FH
	    SWAP A
     	MOV R1,A
	  	LCALL KEYPD
	    ANL A,#0FH
	    ADD A,R1
	    MOV R1,A 
		
				 
CNTNUE:	MOV COUNT2,R1
        MOV COUNT6,COUNT2
		MOV COUNT7,COUNT6           //CONTAINS NUMBER OF BELLS IN A DAY
		MOV	40H,R1
        LCALL	UNPACK
     	LCALL FIRST
		MOV	A,R3
	    ;LCALL  DISP
		MOV DPTR,#2030H
		MOV COUNT9,#01H
		MOV R0,#79H
		MOV @R0,A
		lcall write_data
		MOV DPTR,#2030H
		MOV COUNT9,#01H
		MOV R1,#79H
		lcall read_data
		MOV R1,#79H
		MOV A,@R1
		LCALL DISP
		MOV A,#81H
		LCALL CMD
		MOV	A,R2
	    ;LCALL  DISP
		MOV DPTR,#2031H
		MOV COUNT9,#01H
		MOV R0,#79H
		MOV @R0,A
		lcall write_data
		MOV DPTR,#2031H
		MOV COUNT9,#01H
		MOV R1,#79H
		lcall read_data
		MOV R1,#79H
		MOV A,@R1
		LCALL DISP
		LCALL	DELAY_1SEC

        LCALL FIRST
		MOV DPTR,#WELCOME23
		LCALL	DISPCH2		   //LOAD BELL TIME
	    LCALL	DELAY_1SEC
         
		 MOV R0,#11H
	     MOV R1,#20H
		 

LOAD_TIME: LCALL CLEAR
	      LCALL FIRST
          MOV DPTR,#WELCOME13	   //HH:MM
	      LCALL	DISPCH2
		  LCALL SECOND 
		  LCALL TIME
	CJNE A,#01H,NEXT38
RET		
NEXT38:		 
		  MOV @R0,hours2
		  MOV @R1,mins2
		  LCALL DELAY_1SEC     //LOAD BELLTIME
		  INC R0
		  INC R1
		  DJNZ COUNT2,LOAD_TIME
		                           //wrrit  to eeprom
		  MOV DPTR,#2035H
		  MOV R0,#11H
		  MOV COUNT9,COUNT6
		  
		  lcall write_data
		  
		   
		   
	MOV DPTR,#2050H
		  MOV R0,#20H
		  MOV COUNT9,COUNT6
		  
		  lcall write_data
		  
		  LCALL FIRST																  
		  MOV DPTR,#WELCOME37
		  LCALL DISPCH2
          LCALL DELAY_1SEC
		  
		  
          RET  
		  
// emergency bell

EMERGENCY:LCALL CLEAR
          LCALL FIRST
		  LCALL SETPASS
		  LCALL CLEAR
		  LCALL FIRST
		  MOV DPTR,#WELCOME48
		  LCALL DISPCH2
		  
		  SETB P3.7
		  LCALL DELAY_1SEC
		  LCALL DELAY_1SEC
		  LCALL DELAY_1SEC
		  CLR P3.7
		  LCALL CLEAR1
		  RET

COMP_DAY:MOV R0,#70H
         
        MOV COUNT1,#07H
	COMP2:  MOV A,@R0       //COMPARE DAYS
		 ANL A,#0FH
		 MOV @R0,A
	      MOV days,@R0
	      MOV A,DAY
		  CJNE A,days,NEXT15
		  LCALL COMP_TIME
		  ret
NEXT15:INC R0
       DJNZ COUNT1,COMP2
       RET
	
COMP_TIME: MOV R0,#11H
		   MOV R1,#20H
		   MOV COUNT6,#09H
		  
	COMP1:	  
		  MOV hours2,@R0
           MOV mins2,@R1

        MOV A,HOURS                 //COMPARE TIME
          CJNE A,hours2,NEXT
		  MOV A,MIN
		  CJNE A,mins2,NEXT
		 		 
		  LCALL FIRST
		  MOV DPTR,#WELCOME36
		  LCALL DISPCH2
          SETB P3.7
	      MOV COUNT3,#43
NEXT1:	  LCALL DELAY_1SEC
          DJNZ COUNT3,NEXT1
		  CLR P3.7
		  LCALL CLEAR
		  

	     
NEXT: 	INC R0
		INC R1
		DJNZ COUNT6,COMP1
		    RET

		ret 
DELAY:   MOV R6,#0ffh                      ;delay routine for firing
HERE3:   MOV     R5,#0ffH
REPEAT:  DJNZ    R5,REPEAT
         DJNZ    R6,HERE3
         RET


DELAY_5SEC:MOV R7,#2	
HERE41:  MOV R6,#0ffh                      ;delay routine for firing
HERE311: MOV     R5,#0ffH
REPEAT11:DJNZ    R5,REPEAT11
        DJNZ    R6,HERE311
	    DJNZ	R7,HERE41	
        RET

DELAY_1SEC:MOV R7,#10	
HERE4:  MOV R6,#0ffh                      ;delay routine for firing
HERE31: MOV     R5,#0ffH
REPEAT1:DJNZ    R5,REPEAT1
        DJNZ    R6,HERE31
	    DJNZ	R7,HERE4	
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



SETIME:	MOV	SEC,#00H
     	MOV	MIN,#05H
	    MOV	HOURS,#05H
	   MOV	DAY,#07;			01 FOR MONDAY , 02 TUESADY......

        MOV   DAVAVA,SEC;SET HOURS
		MOV   ADD_LOWL,#00H			 //ENTERING TIME
		LCALL WRITE_BYTE
		LCALL I2C_STOP

        MOV     DAVAVA,MIN;SET MINUTES 
        MOV     ADD_LOWL,#01H
		LCALL   WRITE_BYTE
		LCALL	I2C_STOP

		MOV     DAVAVA,HOURS;SET MINUTES 
        MOV     ADD_LOWL,#02H
		LCALL   WRITE_BYTE
		LCALL	I2C_STOP

		MOV     DAVAVA,DAY  ;SET MONTH 
		MOV     ADD_LOWL,#03H
		LCALL   WRITE_BYTE
			LCALL	I2C_STOP

        RET

SYSTIME:LCALL TIME1
	    MOV     DAVAVA,SEC;SET HOURS
		MOV     ADD_LOWL,#00H			 //ENTERING TIME
		LCALL   WRITE_BYTE
		LCALL	I2C_STOP

        MOV     DAVAVA,MIN;SET MINUTES 
        MOV     ADD_LOWL,#01H
		LCALL   WRITE_BYTE
		LCALL	I2C_STOP

		 MOV     DAVAVA,HOURS;SET MINUTES 
        MOV     ADD_LOWL,#02H
		LCALL   WRITE_BYTE
		LCALL	I2C_STOP
		
		MOV     DAVAVA,DAY  ;SET DAY 
		MOV     ADD_LOWL,#03H
		LCALL   WRITE_BYTE
			LCALL	I2C_STOP
	  RET

	  

         

;==================================================================================
;=====PAY ATTENTION, HERE IS WHERE YOU CHOOSE WHAT DATA YOU WANT, AND WHERE TO STORE IT!!

	READ_RTC:
;==================================================READS SECONDS
			MOV     ADD_LOWL,#00h
			LCALL   READ_BYTE
			MOV 	SEC,DAVAVA
			LCALL	I2C_STOP						   //READING TIME
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

;==================================================================================
;=====stop I2C communication
;=============READS HOURS

I2C_Stop:
	CLR       SDA
	SETB      SCL
	NOP
	SETB      SDA
	RET

;==================================================================================
;=====ANYTHING BELOW IS JUST PROCEDURES TO GET THE DATA, JUST COPY AND PASTE FROM
;=====HERE DOWN, IT'S EXPLAINED AS WELL, IF YOU INSIST. CHANGE THE PROCEDURE NAMES IF
;=====ANY CONFLICT HAPPENS WHEN YOU WRITE A LONGER PROGRAM
;=====
;*****************************************************
;*            WRITE DAVAVA TO DS1307 1 BYTE	*
;*	INPUT 	: ADD_LOW		*
;*		: DAVAVA			*
;*****************************************************
WRITE_BYTE:            CLR     SDA                   ;start bit
                       CLR     SCL
                       MOV     A,#CONT_BYTE_W        ;send control byte
                       LCALL   LOOP_BYTE
                       SETB    SDA
                       SETB    SCL
	                   cpl	0b0h
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

;******************************************************
;*            READ DAVAVA FROM DS1307 1 BYTE	*
;* INPUT  : ADD_HIGH			*
;*        : ADD_LOW				*
;* OUTPUT : DAVAVA			*
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

;****************************************************
;*                      WRITE                       *
;* INPUT: ACC                                       *
;****************************************************
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
;*                       READ                        *
;* OUTPUT: ACC                                       *
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

CMD:	LCALL READY
	MOV  80H,A
	
	
	
	CLR 0A5H	; low on RS
	CLR 0A6H
	SETB 0A7H	 ; high to low on En line
	CLR 0A7H
	RET

DISP:LCALL	READY
			                            ;DISPLAY SINGLE CHAR
	MOV  80H, A
	SETB	0A5H	 ; high RS
	CLR	0A6H	;; low RW
	SETB	0A7H	; high to low En 
	CLR	0A7H

	RET




READY:	CLR	0A7H		;read busy flag
	MOV	80H,#0FFH
	CLR	0A5H
	SETB	0A6H
WAIT:	CLR	0A7H
	SETB	0A7H
	JB	87H,WAIT
	RET

DISPCH2:nop
UP11:	CLR A
	MOVC A,@A+DPTR 	;use lookup table to get ascii character
	CJNE A,#0FH,SKIP
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
MSG1:	DB 'SUNDAY ',0FH
MSG2:	DB 'MONDAY ',0FH
MSG3:	DB 'TUESDAY ',0FH
MSG4:	DB 'WEDNESDAY ',0FH
MSG5:	DB 'THURSDAY ',0FH
MSG6:	DB 'FRIDAY ',0FH
MSG7:	DB 'SATURDAY ',0FH
welcome11:  db 'SET DAY AND TIME ',0fh

welcome12:	db 'ENTER PASSWORD',0fh
welcome13:  db 'HH:MM',0fh
welcome14:	db 'ENTER DAY NUMBER',0fh
welcome15:  db 'PRESS ENTER - # ',0fh
welcome16:	db 'SU-1 M-2 TU-3 W-',0fh	
welcome17:  db '4 TH-5 F-6 SA-7',0fh
welcome18:  db 'SET BELL TIMINGS',0fh
welcome19:  db '2.CHANGE TIMINGS ',0fh
welcome20:  db 'ENTER NUMBER OF',0fh
welcome21:  db 'BELLS IN A DAY',0fh
welcome23:  db 'LOAD BELL TIME',0fh
welcome30:  db 'ENTER THE BELL',0fh
welcome31:  db '     NUMBER     ',0fh
welcome33:  db 'ENTER BELL TIME',0fh
welcome1:   db '    WELCOME!   ',0fh
welcome36:  db 'TRIN!!TRIN!!',0fh
welcome37:  db 'BELL TIME IS SET',0fh
welcome38:  db 'ENTER DAY NUMBER',0fh
welcome39:  db 'SU-1 M-2 TU-3 W-',0fh	
welcome40:  db '4 TH-5 F-6 SA-7',0fh 
welcome41:  db 'INVALID ENTRY',0fh
welcome42:	db '                ',0fh
welcome43:  db '*',0fh

welcome44:  db 'INVALID DAYNUMBER',0fh
welcome45:  db 'SECOND PERIOD',0fh
welcome46:  db 'BREAK!!! ',0fh
welcome47:  db 'HH:MM:SS',0fh
welcome48:  db 'EMERGENCY!!!',0fh
welcome49:  db '**',0fh
welcome50:  db 'DAY NUMBER LIST',0fh
NO_BELL		:	DB 'No Bell Entry !' ,0fh
CLEAR1:LCALL FIRST
       MOV DPTR,#WELCOME42    //clear a single line
	   LCALL DISPCH2
	   RET


CLEAR2:LCALL CLEAR
       LCALL FIRST
	   MOV DPTR,#WELCOME41
	   LCALL DISPCH2
	   LCALL DELAY_1SEC
	   LCALL CLEAR1
	   RET
PASS:	
		lcall KEYPD
		MOV @R0,A             //SETTING PASSWORD
		LCALL	DISP
		
		
		INC R0
		
		DJNZ COUNT9,PASS
		;LCALL DELAY_1SEC
		;MOV DPTR,#2000H
		;MOV R0,#46H
		;MOV COUNT9,#04H
		;lcall write_data
		RET	

PART1:
      MOV A,#30H
	  ANL A,#0FH
	  SWAP A
	  MOV DAY,A
	  					//ENTERING SYSTIME
	LCALL KEYPD
	ANL A,#0FH
	ADD A,DAY
	MOV DAY,A
	MOV R1,A
	MOV A,#07H
	CLR C
	  SUBB A,DAY
      JC NEXT20
	   MOV A,DAY
	LCALL DISPTIME
	
      LCALL SECOND 
      LCALL KEYPD
	  ANL A,#0FH
	  SWAP A
	  MOV HOURS,A
	  					//ENTERING SYSTIME
	LCALL KEYPD
	ANL A,#0FH
	ADD A,HOURS
	MOV HOURS,A
	MOV A,#24H
	CLR C
	  SUBB A,HOURS
      JC NEXT20
	LCALL DAYDP5
	RET
 TIME1:LCALL PART1
    LCALL KEYPD
	ANL A,#0FH
	SWAP A
	MOV MIN,A
	 
	LCALL KEYPD
	ANL A,#0FH
	ADD A,MIN
	MOV MIN,A
	MOV A,#60H
	CLR C
	 SUBB A,MIN
     JC NEXT20

 
	;MOV MIN,R4

 NEXT34:   LCALL DAYDP3

    LCALL KEYPD
	ANL A,#0FH
	SWAP A
	MOV SEC,A
	 
    LCALL KEYPD
	ANL A,#0FH
    ADD A,SEC
	MOV SEC,A
	MOV A,#60H
	CLR C
	SUBB A,SEC
    JC NEXT20
	MOV SEC,SEC
   	LCALL DAYDP4
      
    RET
NEXT20:LCALL FIRST
      MOV DPTR,#WELCOME41  //CORRECTNESS OF TIME
	  LCALL DISPCH2
	  LCALL DELAY_1SEC
	  LCALL CLEAR1
	  LCALL MAKEGAIN
	  RET		

TIME: 
      LCALL KEYPD
	  ANL A,#0FH
	  SWAP A
	  MOV hours2,A
	  					//ENTERING TIME
	  LCALL KEYPD
	  ANL A,#0FH
	  ADD A,hours2
	  MOV R4,A
	  
	  MOV A,#24H
	  SUBB A,R4
      JC NEXT7

	  MOV hours2,R4
	  LCALL DAYDP1
	  
      LCALL KEYPD
   	  ANL A,#0FH
	  SWAP A
	  MOV mins2,A
	 
	  LCALL KEYPD
	  ANL A,#0FH
	  ADD A,mins2
	  LCALL DISP
	  MOV R4,A
	  MOV A,#60H
	  SUBB A,R4
	  JC NEXT7
	  MOV mins2,R4
      LCALL DAYDP2
      RET

NEXT7:LCALL FIRST
      MOV DPTR,#WELCOME41
	  LCALL DISPCH2
	  LCALL DELAY_1SEC
	  LCALL CLEAR1
	  MOV A,#01H
	  RET
POLL_SWITCH: 
        JB P3.3,NEXT21
		 LCALL SETTIME
   	NEXT21:JB P3.4,NEXT25
	       LCALL ENTERPASS2
	NEXT25:JB P3.5,NEXT26
	       LCALL EMERGENCY
	NEXT26:RET

//keypad routine

KEYPD:   MOV R5,#00           
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
     
   ROW:  MOV A,90H
         ANL A,#0F0H


           SWAP A
    REDO:  RRC A
           JNC KEY
           INC R5
           SJMP REDO
        KEY:MOV 90H,#0F0H
				NOP
				NOP
				MOV	A,90H
			
		XRL	A,#0F0H
		JNZ	KEY
		MOV	A,R5
		MOV DPTR,#KEYCODE
		MOVC	A,@A+DPTR
		LCALL DELAY_5SEC
		
    RET
       
    KEYCODE:DB '1','2','3','4','5','6','7','8','9','*','0','#'
	
	
	//EEPROM
	write_data:     call eeprom_start
                mov a,#0a0h          
                call send_data
				
                mov a,DPL          ;location address
                call send_data
				
                mov a,DPH          ;location address
                call send_data
				MOV eeprom_data,@R0
                mov a,eeprom_data              ;data to be send
                call send_data
				
                call eeprom_stop
				lcall eeprom_delay
				lcall eeprom_delay
				
				 call eeprom_start
                mov a,#0a0h          
                call send_data
				
                mov a,DPL          ;location address
                call send_data
				
                mov a,DPH          ;location address
                call send_data
				MOV eeprom_data,@R0
                mov a,eeprom_data              ;data to be send
                call send_data
				
                call eeprom_stop
				lcall	eeprom_delay
				lcall	eeprom_delay
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
				lcall	eeprom_delay
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


   END