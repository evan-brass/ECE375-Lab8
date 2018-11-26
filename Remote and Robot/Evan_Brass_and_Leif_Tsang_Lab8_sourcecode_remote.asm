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

.equ	MovFwd = 0b10110000 ; Move Forward Action Code
.equ	MovBck = 0b10000000 ; Move Backward Action Code
.equ	TurnR = 0b10100000 ; Turn Right Action Code
.equ	TurnL = 0b10010000 ; Turn Left Action Code
.equ	Halt =  0b11001000 ; Halt Action Code

.equ	BotAddress = 0b01010101;(Enter your robot's address here (8 bits))

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org	$0002
		rjmp	Mov_Forward		;move forward func
		reti
.org	$0004
		rjmp	Mov_Backward	;move Backward func
		reti
.org	$0006
		rjmp	Turn_Right		;Turn right Func
		reti
.org	$0008
		rjmp	Turn_Left		;Turn left Func
		reti
.org	$000A
		rjmp	Halt			;Stop everything Func
		reti
.org	$000C
		rjmp	Freeze			;freeze for 5 second func
		reti

.org	$0046					; End of Interrupt Vectors

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
	ldi		mpr, 0b01100000   ;Lights on 6 and 7 are on
	out		PORTB, mpr

	;USART1
	;Set frame format: 8 data bits, 2 stop bits
	ldi		mpr, 0b00001110		;Data frame pin 2:1, 2 stop bit pin 3
	out		UCSR1C, mpr
	ldi		mpr, 0b00001000		;Enable transmitter pin 3, Data Frame pin 2
	out		UCSR1B, mpr
	ldi		mpr, 0b00000000	
	out		UCSR1A, mpr

	ldi		mpr, L(415)			;Set baudrate at 2400bps
	out		UBRR1L, mpr
	ldi		mpr, H(415)
	out		UBRR1H, mpr
	
		

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	in mpr, PIND
	cp mpr, prev
	breq MAIN
	; A button was pressed or released
	; (Order of operations if multiple buttons pressed)
	sbrs mpr, 0
	rcall Mov_Forward

	sbrs mpr, 1
	rcall Mov_Backward

	sbrs mpr, 2
	rcall Turn_Right

	sbrs mpr, 3
	rcall Turn_Left

	sbrs mpr, 4
	rcall Halt

	sbrs mpr, 5
	rcall Freeze

	; Set a new previous
	mov prev, mpr

	; debounce
	ldi waitcnt, 10
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

	; Restart
	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;Send signal to bot to move forward
Mov_Forward:
	sbis	UCSR1A, UDRE1
	rjump	Mov_Forward
	out		UDR1, BotAddress

Mov_Forward1:
	sbis	UCSR1A, UDRE1
	rjump	Mov_Forward1
	out		UDR1, 0b10110000
	ret



;Send signal to bot to move backwards
Mov_Backward:
	sbis	UCSR1A, UDRE1
	rjump	Mov_Backward
	out		UDR1, BotAddress

Mov_Backward1:
	sbis	UCSR1A, UDRE1
	rjump	Mov_Backward1
	out		UDR1, 0b10000000
	ret



;Send signal to bot to turn right
Turn_Right:
	sbis	UCSR1A, UDRE1
	rjump	Turn_Right
	out		UDR1, BotAddress

Turn_Right1:
	sbis	UCSR1A, UDRE1
	rjump	Turn_Right1
	out		UDR1, 0b10100000
	ret



;Send signal to bot to turn left
Turn_Left:
	sbis	UCSR1A, UDRE1
	rjump	Turn_Left
	out		UDR1, BotAddress

Turn_Left1:
	sbis	UCSR1A, UDRE1
	rjump	Turn_Left1
	out		UDR1, 0b10010000
	ret



;Send signal to bot to stop doing anything
Halt:
	sbis	UCSR1A, UDRE1
	rjump	Halt
	out		UDR1, BotAddress
Halt1:
	sbis	UCSR1A, UDRE1
	rjump	Halt1
	out		UDR1, 0b11001000
	ret



;Send signal to the bot to send out another signal to freeze all bots
Freeze:
	sbis	UCSR1A, UDRE1
	rjump	Freeze
	out		UDR1, BotAddress
Freeze1:
	sbis	UCSR1A, UDRE1
	rjump	Freeze1
	out		UDR1, 0b11111000
	ret


;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************