;***********************************************************
;*
;*	Evan_Brass_and_Leif_Tsang_Lab8_sourcecode_remote.asm
;*
;*	Lab8 Transmitter
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Evan Brass
;*	   Date: 11/14/2018
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def prev = r17
.def waitcnt = r18
.def ilcnt = r19
.def olcnt = r20
.def data = r21

.equ	C_MovFwd = 0b10110000 ; Move Forward Action Code
.equ	C_MovBck = 0b10000000 ; Move Backward Action Code
.equ	C_TurnR = 0b10100000 ; Turn Right Action Code
.equ	C_TurnL = 0b10010000 ; Turn Left Action Code
.equ	C_Halt =  0b11001000 ; Halt Action Code
.equ	C_Freeze = 0b11111000 ; Freeze Action Code

.equ	BotAddress = 0b01100110;(Enter your robot's address here (8 bits))

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org $0000					; Beginning of IVs
		rjmp 	INIT		; Reset interrupt

.org $0046					; End of Interrupt Vectors

trap:
	rjmp trap

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi		mpr, low(RAMEND)
	out		SPL, mpr		; Load SPL(PORT) with low byte of RAMEND
	ldi		mpr, high(RAMEND)
	out		SPH, mpr		; Load SPH with high byte of RAMEND

	;I/O Ports
	ldi		mpr, 0b11111111   ;Configure LED's and set leds to output
	out		DDRB, mpr

	ldi mpr, 0b00001000
	out DDRD, mpr
	ldi mpr, 0b11111111
	out PORTD, mpr 

	;USART1
	;Set frame format: 8 data bits, 2 stop bits
	ldi		mpr, 0b00001110		;Data frame pin 2:1, 2 stop bit pin 3
	sts		UCSR1C, mpr
	ldi		mpr, 0b00001000		;Enable transmitter pin 3, Data Frame pin 2
	sts		UCSR1B, mpr
	ldi		mpr, 0b00000000	
	sts		UCSR1A, mpr

	ldi		mpr, low(415)			;Set baudrate at 2400bps
	sts		UBRR1L, mpr
	ldi		mpr, high(415)
	sts		UBRR1H, mpr
	
		

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	in mpr, PIND
	cp mpr, prev
	breq MAIN
	; A button was pressed or released
;	out PORTB, mpr
;	rjmp Main_End
	; Debugging - send freeze command from remote
	cpi mpr, 0b11111100
	brne Rest_Checks
	
	push mpr
	ldi data, 0b01010101
	sts UDR1, data
DEBUG_Send_Freeze:
	lds mpr, UCSR1A
	sbrs mpr, UDRE1
	rjmp DEBUG_Send_Freeze
	; Done
	out PORTB, data
	pop mpr
	rjmp Main_End

Rest_Checks:
	sbrs mpr, 0
	rjmp Mov_Forward

	sbrs mpr, 1
	rjmp Mov_Backward

	sbrs mpr, 4
	rjmp Turn_Right

	sbrs mpr, 5
	rjmp Turn_Left

	sbrs mpr, 6
	rjmp Halt

	sbrs mpr, 7
	rjmp Freeze


Main_End:
	; Set a new previous
	mov prev, mpr

	; debounce
	ldi waitcnt, 10
	rcall Wait

	; Restart
	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
Wait:
Loop:	
	ldi	olcnt, 224
OLoop:	
	ldi	ilcnt, 237
ILoop:	
	dec	ilcnt
	brne ILoop
	dec	olcnt
	brne OLoop
	dec	waitcnt
	brne Loop
	ret

; Not quite a subroutine
Send_Command:
	push mpr
	; Send Bot address
	ldi mpr, BotAddress
	sts UDR1, mpr
Wait_On_Address:
	lds mpr, UCSR1A
	sbrs mpr, UDRE1
	rjmp Wait_On_Address
	; Send Command
	sts UDR1, data
Wait_On_Command:
	lds mpr, UCSR1A
	sbrs mpr, UDRE1
	rjmp Wait_On_Command
	; Done
	out PORTB, data
	pop mpr
	rjmp Main_End

;Send signal to bot to move forward
Mov_Forward:
	ldi data, C_MovFwd
	rjmp Send_Command

;Send signal to bot to move backwards
Mov_Backward:
	ldi data, C_MovBck
	rjmp Send_Command

;Send signal to bot to turn right
Turn_Right:
	ldi data, C_TurnR
	rjmp Send_Command

;Send signal to bot to turn left
Turn_Left:
	ldi data, C_TurnL
	rjmp Send_Command

;Send signal to bot to stop doing anything
Halt:
	ldi data, C_Halt
	rjmp Send_Command

;Send signal to the bot to send out another signal to freeze all bots
Freeze:
	ldi data, C_Freeze
	rjmp Send_Command

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************