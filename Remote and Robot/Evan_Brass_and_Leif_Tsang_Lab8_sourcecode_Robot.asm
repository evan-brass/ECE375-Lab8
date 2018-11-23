;***********************************************************
;*
;*	Evan_Brass_and_Leif_Tsang_Lab8_sourcecode_robot.asm
;*
;*	Lab8 Receiver / Freeze Transmitter
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
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

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = ;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;Should have Interrupt vectors for:
;- Left whisker
;- Right whisker
;- USART receive

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
	;Initialize port B
	ldi		mpr, 0b11111111		;Configure LED's and set leds to output
	out		DDRB, mpr
	ldi		mpr, 0b00000000
	out		PORTB, mpr

	;USART1
	; Set frame format: 8 data bits, 2 stop bits
	ldi		mpr, 0b00001110		;pin 6:0 Transmission Mode, pin 2:1 Data frame, pin 3 2 stop bits
	out		UCSR1C, mpr
	ldi		mpr, 0b10010000		;Enable receiver pin 5 and enable receive interrupts pin 7, pin 2 data frame
	out		UCSR1B, mpr
	ldi		mpr, 0b00000000
	out		UCSR1A, mpr

	ldi		mpr, L(415)			;Set baudrate at 2400bps
	out		UBRR1L, mpr
	ldi		mpr, H(415)
	out		UBRR1H, mpr
		

		

	;External Interrupts
	;Set the External Interrupt Mask
	ldi		mpr, 0b00000001
	out		EIMSK, mpr

	;Set the Interrupt Sense Control to falling edge detection
	ldi		mpr, 0b00000010  ;0b10 for falling edge for interrupt
	sts		EICRA, mpr
		

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
