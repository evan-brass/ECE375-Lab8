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
	ldi		mpr, 0b01100000
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
	sbrs mpr, btnInc
	rcall inc_bright

	sbrs mpr, btnDec
	rcall dec_bright

	sbrs mpr, btnMin
	rcall min_bright

	sbrs mpr, btnMax
	rcall max_bright

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
send:

	ret
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************