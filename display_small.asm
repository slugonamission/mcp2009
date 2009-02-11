	## Routines for interacting with the onboard display

	## Global imports
#include "common.h"
#include "display_small.h"

	## Global exports
	.globl clear_small
	.globl write_small
	.globl write_seq_small
	
	## Clears the display and waits for the required time
	## Destroys: nothing
clear_small:
 	push af
	push hl		#Switch to shadow set so we dont break anything
	ld a,0x01
	ld l,0xB0
	
	out0 (s_disp_command),a
	call delay

	pop hl
	pop af			#Back to normal set
	ret

	## Writes a char to the cursor position on the display
	## Char code must be in the A register
	## Destroys: nothing
write_small:
	push hl			##Again, need it for the timer
	out0 (s_disp_data),a
				##Shadow registers
	ld l,0x01
	call delay
				##Back to normal
	pop hl
	ret

	## Writes a sequence of bytes to the screen
	## hl - start of sequence
	## b - number of bytes to write
	## Destroys: hl
write_seq_small:
	## We need A, switch to shadow register set
	push af
write_seq_small_start:	
	ld a,b
	cp 0
	jp z, write_seq_small_end
	dec a
	ld b,a
	ld a,(hl)
	call write_small
	inc hl
	jp write_seq_small_start
	
write_seq_small_end:
	pop af		#Switch A back in
	ret
