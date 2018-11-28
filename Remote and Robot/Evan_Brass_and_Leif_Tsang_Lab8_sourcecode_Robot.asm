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
.def	lives = r21
.def	command = r22

.equ	WTime = 100				; Time to wait in wait loop
.equ	BotAddress = 0b01100110;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ C_MovFwd = 0b10110000 ; Move Forward Action Code
.equ C_MovBck = 0b10000000 ; Move Backward Action Code
.equ C_TurnR = 0b10100000 ; Turn Right Action Code
.equ C_TurnL = 0b10010000 ; Turn Left Action Code
.equ C_Halt =  0b11001000 ; Halt Action Code
.equ C_Freeze = 0b11111000 ; Freeze Action Code

.equ Freeze = 0b01010101

.equ MovFwd = 0b11110000
.equ MovBck = 0b01100000
.equ TurnL = 0b01110000
.equ TurnR = 0b11100000
.equ Halt = 0b00000000

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

	; Initialize lives register
	ldi lives, 3

	ldi waitcnt, 100

	;I/O Ports
	;Initialize port B
	ldi		mpr, 0b11111111		;Configure LED's and set leds to output
	out		DDRB, mpr
	ldi		mpr, 0b11110000
	out		PORTB, mpr

	ldi command, 0b11110000

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

	rcall Disable_Receive

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

	out PORTB, command

	rcall Enable_Receive

	pop mpr				; Restore program state
	out SREG, mpr 
	pop waitcnt			; Restore wait register
	pop mpr				; Restore mpr

	ldi mpr, 0b11111111
	out EIFR, mpr
	reti

; Handle the left whisker
left_whisker:
	push mpr			; Save mpr register
	push waitcnt		; Save wait register
	in mpr, SREG		; Save program state
	push mpr

	rcall Disable_Receive

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

	out PORTB, command

	rcall Enable_Receive

	pop mpr				; Restore program state
	out SREG, mpr 
	pop waitcnt			; Restore wait register
	pop mpr				; Restore mpr
		
	ldi mpr, 0b11111111
	out EIFR, mpr
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

Disable_Receive:
	push mpr
	lds mpr, UCSR1B
	andi mpr, 0b11101111
	sts UCSR1B, mpr
	pop mpr
	ret

Enable_Receive:
	push mpr
	lds mpr, UCSR1B
	ori mpr, 0b00010000
	sts UCSR1B, mpr
	pop mpr
	ret
	
Enable_Transmit:
	push mpr
	; Enable Transmitter
	lds mpr, UCSR1B
	ori mpr, 0b00001000
	sts UCSR1B, mpr
	pop mpr
	ret
Disable_Transmit:
	push mpr
	; Enable Transmitter
	lds mpr, UCSR1B
	andi mpr, 0b11110111
	sts UCSR1B, mpr
	pop mpr
	ret

; Handle Data that's ready from the controller
rx_complete:
	; Check what command has been sent
	push mpr
	lds mpr, UDR1
	; - BEGIN DEBUG -
;	push lives
;	in lives, PINB
;	out PORTB, mpr
;	ldi waitcnt, 50
;	rcall Wait
;
;	ldi waitcnt, 100
;	out PORTB, lives
;	pop lives
	; - END DEBUG -
	; Check if this is an address or command frame
	sbrs mpr, 7
	rcall rx_address_frame

	sbrc mpr, 7
	rcall rx_command_frame

	out PORTB, command
	pop mpr
	reti

wait_5: ; This still is longer than 5 seconds and I don't know why
	rcall Wait
	rcall Wait
	rcall Wait
	rcall Wait
	rcall Wait
	ret

; Handle Address Frames
rx_address_frame:
	push mpr
	; Check for Freeze
	cpi mpr, Freeze
	brne rx_address_not_frozen
	; Handle freeze
	rcall Disable_Receive

	ldi mpr, Halt
	out PORTB, mpr
	rcall wait_5

	clr selected
	
	; Disable and Enable Receiver (This is just to clear the TXC flag)
	rcall Enable_Receive

	; Keep track of lives
	dec lives
;	out PORTB, lives
;	rcall Wait
;	cpi lives, 0
	breq trap

	rjmp rx_address_end
rx_address_not_frozen:
	cpi mpr, BotAddress
	breq rx_address_frame_match
	clr selected
	rjmp rx_address_end
rx_address_frame_match:
	ldi selected, 1

rx_address_end:
	pop mpr
	ret

trap: ; Infinite Loop
	rjmp trap

; Handle Command Frames
rx_command_frame:
	; Check if our robot is selected
	cpi selected, BotAddress
	breq rx_command_frame_done
	; Check what command was sent and handle it
	cpi mpr, C_MovFwd
	brne check_MovBck
	; Handle MovFwd
	ldi command, MovFwd
	ret
check_MovBck:
	cpi mpr, C_MovBck
	brne check_TurnR
	; Handle MovBck
	ldi command, MovBck
	ret
check_TurnR:
	cpi mpr, C_TurnR
	brne check_TurnL
	; Handle TurnR
	ldi command, TurnR
	ret
check_TurnL:
	cpi mpr, C_TurnL
	brne check_Halt
	; Handle TurnL
	ldi command, TurnL
	ret
check_Halt:
	cpi mpr, C_Halt
	brne check_Freeze
	; Handle Halt
	ldi command, Halt
	ret
check_Freeze:
	cpi mpr, C_Freeze
	brne rx_command_frame_done
	; Handle Freeze
	rcall HandleFreeze
rx_command_frame_done:
	ret

; Handle a Freeze Command from the remote
HandleFreeze:
	cli
	lds mpr, UCSR1B
	rcall Disable_Receive
	rcall Enable_Transmit

Wait_For_Empty:
	lds mpr, UCSR1A
	sbrs mpr, UDRE1
	rjmp Wait_For_Empty

	ldi mpr, Freeze
	sts UDR1, mpr
Wait_For_Sent:
	lds mpr, UCSR1A
	sbrs mpr, TXC1
	rjmp Wait_For_Sent

	rcall Disable_Transmit
	rcall Enable_Receive

	; Debounce receieve
	push waitcnt
	ldi waitcnt, 50
	rcall Wait
	pop waitcnt
	lds mpr, UDR1
	lds mpr, UDR1
;	rcall Disable_Receive
;	rcall Enable_Receive

	rcall Wait
	ret