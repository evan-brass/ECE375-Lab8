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
.def	selected = r17			; Non zero if the last received address byte was the same as our bot address
.def	waitcnt = r18			; Wait Loop Counter
.def	ilcnt = r19
.def	olcnt = r20

.equ	WTime = 100				; Time to wait in wait loop
.equ	BotAddress = 0b01100110;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ MovFwd = 0b10110000 ; Move Forward Action Code
.equ MovBck = 0b10000000 ; Move Backward Action Code
.equ TurnR = 0b10100000 ; Turn Right Action Code
.equ TurnL = 0b10010000 ; Turn Left Action Code
.equ Halt =  0b11001000 ; Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org $0000					; Beginning of IVs
	rjmp INIT

.org $0002 ; Left Whisker Interrupt
	cli
	rjmp left_whisker

.org $0004 ; Right Whisker Interrupt
	cli
	rjmp right_whisker

.org $003C ; USART 1 Rx Complete Interrupt
	rjmp rx_complete

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
	sts		UCSR1C, mpr
	ldi		mpr, 0b10010000		;Enable receiver pin 5 and enable receive interrupts pin 7, pin 2 data frame
	sts		UCSR1B, mpr
	ldi		mpr, 0b00000000
	sts		UCSR1A, mpr

	ldi		mpr, low(415)		;Set baudrate at 2400bps
	sts		UBRR1L, mpr
	ldi		mpr, high(415)
	sts		UBRR1H, mpr

	;External Interrupts
	;Set the External Interrupt Mask
	ldi		mpr, 0b00000011
	out		EIMSK, mpr

	;Set the Interrupt Sense Control to falling edge detection
	ldi		mpr, 0b00001010  ;0b10 for falling edge for interrupt
	sts		EICRA, mpr

	sei ; Enable global interrupts

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	rjmp MAIN

; Handle the right whisker
right_whisker:

	push mpr			; Save mpr register
	push waitcnt		; Save wait register
	in mpr, SREG		; Save program state
	push mpr 

	; Move Backwards for a second
	ldi mpr, MovBck		; Load Move Backwards command
	out PORTB, mpr		; Send command to port
	ldi waitcnt, Wtime	; Wait for 1 second
	rcall Wait			; Call wait function

	; Turn left for a second
	ldi mpr, TurnL		; Load Turn Left Command
	out PORTB, mpr		; Send command to port
	ldi waitcnt, Wtime	; Wait for 1 second
	rcall Wait			; Call wait function

	pop mpr				; Restore program state
	out SREG, mpr 
	pop waitcnt			; Restore wait register
	pop mpr				; Restore mpr

	ldi mpr, 0b11111111
	out EIFR, mpr
	sei

	reti

; Handle the left whisker
left_whisker:
	push mpr			; Save mpr register
	push waitcnt		; Save wait register
	in mpr, SREG		; Save program state
	push mpr 

	; Move Backwards for a second
	ldi mpr, MovBck		; Load Move Backwards command
	out PORTB, mpr		; Send command to port
	ldi waitcnt, Wtime	; Wait for 1 second
	rcall Wait			; Call wait function

	; Turn right for a second
	ldi mpr, TurnR		; Load Turn Left Command
	out PORTB, mpr		; Send command to port
	ldi waitcnt, Wtime	; Wait for 1 second
	rcall Wait			; Call wait function

	pop mpr				; Restore program state
	out SREG, mpr 
	pop waitcnt			; Restore wait register
	pop mpr				; Restore mpr
		
	ldi mpr, 0b11111111
	out EIFR, mpr
	sei

	reti

Wait:
	push	waitcnt			; Save wait register
	push	ilcnt			; Save ilcnt register
	push	olcnt			; Save olcnt register

Loop:	
	ldi		olcnt, 224		; load olcnt register
OLoop:	
	ldi		ilcnt, 237		; load ilcnt register
ILoop:	
	dec		ilcnt			; decrement ilcnt
	brne	ILoop			; Continue Inner Loop
	dec		olcnt			; decrement olcnt
	brne	OLoop			; Continue Outer Loop
	dec		waitcnt			; Decrement wait 
	brne	Loop			; Continue Wait loop	

	pop		olcnt			; Restore olcnt register
	pop		ilcnt			; Restore ilcnt register
	pop		waitcnt			; Restore wait register

	ret


; Handle Data that's ready from the controller
rx_complete:
	; Check if our robot is selected
	cpi selected, BotAddress
	breq rx_command_frame_done
	; Check what command has been sent
	push mpr
	lds mpr, UDR1
	; - BEGIN DEBUG -
;	out PORTB, mpr
;	pop mpr
;	reti
	; - END DEBUG -
	; Check if this is an address or command frame
	sbrs mpr, 7
	rcall rx_address_frame

	sbrc mpr, 7
	rcall rx_command_frame

	pop mpr
	reti

; Handle Address Frames
rx_address_frame:
	cpi mpr, BotAddress
	breq rx_address_frame_match
	clr selected
	ret
rx_address_frame_match:
	ldi selected, 1
	ret

; Handle Command Frames
rx_command_frame:
	cpi mpr, MovFwd
	brne check_MovBck
	; Handle MovFwd
check_MovBck:
	cpi mpr, MovBck
	brne check_TurnR
	; Handle MovBck
check_TurnR:
	cpi mpr, TurnR
	brne check_TurnL
	; Handle TurnR
check_TurnL:
	cpi mpr, TurnL
	brne check_Halt
	; Handle TurnL
check_Halt:
	cpi mpr, Halt
	brne rx_command_frame_done
	; Handle Halt
rx_command_frame_done:
	ret