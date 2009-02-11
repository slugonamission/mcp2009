	## File for all common (i.e. non-specific) procedures
	## Written by Y2841429

#include "common.h"

	## Standard system initialisation
	## Destroys: probably everything. You shouldnt call this
	## and assume ANYTHING will be the same after.
init:
	di

	## Turn off more interrupts
##	ld a,0x00
##	out0 (0x34),a

	ld a,0x00
	out0 (0x30),a
	
	## Set other registers back to 0
	ld a,0x00
	ld bc,0x0000
	ld de,0x0000
	ld hl,0x0000
	ret
	
	## Delay procedure - delays for l milliseconds (ish)
	## Destroys - l
delay:	push af
	push hl
	ld h,0
del1:	dec hl
	ld a,h
	or l
	jp nz,del1
	pop hl
	pop af
	ret



