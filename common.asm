	## File for all common (i.e. non-specific) procedures
	## Written by Y2841429

#include "common.h"
#include "display_small.h"

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

collide_item_check:
	push af
	push hl
	push ix
	
	ld l,0x00		#Simple counter
	ld a,(monsters_count)
	ld h,a
	ld ix,monsters
collide_monster_loop:
	ld a,l
	cp h			#Have we handled everything yet?
	jp z,collide_monster_end

	inc a
	ld l,a
	
	ld a,(ix)
	inc ix
	cp b

	## Load and increment again before testing the result of the last cp
	ld a,(ix)
	inc ix

	jp nz,collide_monster_loop
	cp c
	call z,death
	jp collide_monster_loop

	
collide_monster_end:
	ld l,0x00
	ld a,(ghosts_count)
	ld h,a
	ld ix,ghosts

collide_ghost_loop:
	ld a,l
	cp h			#Have we handled everything yet?
	jp z,collide_ghost_end
	inc a
	ld l,a
	ld a,(ix)
	inc ix
	cp b

	## Load and increment again before testing the result of the last cp
	ld a,(ix)
	inc ix

	jp nz,collide_ghost_loop
	cp c
	call z,death
	jp collide_ghost_loop
	
collide_ghost_end:		
	ld l,0x00
	ld a,(jewels_count)
	ld h,a
	ld ix,jewels

collide_jewel_loop:
	ld a,l
	cp h
	jp z,collide_jewel_end
	inc a
	ld l,a
	ld a,(ix)
	inc ix
	cp b

	ld a,(ix)
	inc ix

	jp nz,collide_jewel_loop
	cp 0xFF			#Ignore this jewel, it has been captured
	jp z,collide_jewel_loop
	cp c
	call z,grab_jewel
	jp collide_jewel_loop

collide_jewel_end:
	pop ix
	pop hl
	pop af
	ret

death:	
	push af

	ld a,game_dead
	ld (game_state),a
	
	pop af
	ret

grab_jewel:
	push af
	push bc
	push hl

	## IX should point to the memory location 2 past what the jewel
	## we just hit is
	## Dec it twice to point to the start again
	dec ix
	dec ix
	ld a,0xFF
	ld (ix),a
	inc ix
	ld (ix),a

	ld a,s_line_2_offset+8
	call set_adp_small
	
	ld a,(jewels_count)	#WHY CANT WE DO LD B,(FOO)?!
	ld b,a
	
	ld a,(jewels_collected)
	inc a
	ld (jewels_collected),a
	cp b
	jp nz,grab_jewel_writeout

	## OMG WE FINISHED
	ld a,game_complete
	ld (game_state),a
	
	jp grab_jewel_exit
	
	
grab_jewel_writeout:	
	## Now output the new jewels value to the screen
	add a,48
	call write_small

grab_jewel_exit:
	pop hl
	pop bc
	pop af
	ret
	
	
default_callback:
	nop
	ret
