#include "timer.h"

timer_init:
	push af
	## Init the data and reload registers to FFFF
	## First, we need to disable the PRTs
	ld a,0x00
	out0 (tcr),a		#Turn EVERYTHING off

	## Set the timer values and reload values
	ld a,0xFF
	out0 (tmdr_0_low),a
	out0 (tmdr_0_high),a
	out0 (tmdr_1_low),a
	out0 (tmdr_1_high),a

	out0 (rldr_0_low),a
	out0 (rldr_0_high),a
	out0 (rldr_1_low),a
	out0 (rldr_1_high),a

	## Should be done now
	pop af
	ret

	## SET THE ISR PROPERLY BEFORE CALLING ANY OF THESE!!!
timer_0_enable:
	push af
	in0 a,(tcr)
	or 0x11
	out0 (tcr),a
	pop af
	ret

timer_0_disable:
	push af
	in0 a,(tcr)
	and 0xEE
	out0 (tcr),a
	pop af
	ret

timer_1_enable:
	push af
	in0 a,(tcr)
	or 0x22
	out0 (tcr),a
	pop af
	ret

timer_1_disable:
	push af
	in0 a,(tcr)
	and 0xDD
	out0 (tcr),a
	pop af
	ret
