	## File for all common (i.e. non-specific) procedures
	## Written by Y2841429

#include "common.h"
#include "display_small.h"
#include "display.h"
#include "tilt_prt.h"
#include "network_callback.h"
	
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

	ld a,s_line_2_offset+2	#Where is the jewel count?
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

zoom_in:
	## Interrupts could cause some problems here
	di

	## This is going to take a lot of messing around to do properly
	push af
	push hl
	push bc
	
	## Switch to text mode
	call disp_text_mode

	ld hl,disp_text_home
	call disp_set_adp
	
	## We dont need to bother clearing, we will overwrite it all anyway
	## Set the pointer to the start of the map
	## Map start = 0xc000
	## Map end = 0xc400
	ld hl,0xc000

	## We might aswell turn on auto mode for this to make life easier
	call disp_enable_auto_write
	
	## Now we need to start reading bytes from the map. For each bit, we need to output the
	## respective bit to the screen.
zoom_in_inner:
	ld a,h
	cp 0xc4
	jp z,zoom_in_exit

	ld a,(hl)
	ld b,a
	inc hl
	
	## We now have one of the display bytes in A/B
	## A quick and dirty hack here. We shall just compare each bit and output respectively
	## LOOP UNROLLING!!! (and no nasty shift+compare stuff)
zoom_in_bit_loop:
	bit 7,b			#Bit C of byte B. Stupid instruction/operand ordering
	call z,zoom_in_dispatch_0
	call nz,zoom_in_dispatch_1
	bit 6,b			#Bit C of byte B. Stupid instruction/operand ordering
	call z,zoom_in_dispatch_0
	call nz,zoom_in_dispatch_1
	bit 5,b			#Bit C of byte B. Stupid instruction/operand ordering
	call z,zoom_in_dispatch_0
	call nz,zoom_in_dispatch_1
	bit 4,b			#Bit C of byte B. Stupid instruction/operand ordering
	call z,zoom_in_dispatch_0
	call nz,zoom_in_dispatch_1
	bit 3,b			#Bit C of byte B. Stupid instruction/operand ordering
	call z,zoom_in_dispatch_0
	call nz,zoom_in_dispatch_1
	bit 2,b			#Bit C of byte B. Stupid instruction/operand ordering
	call z,zoom_in_dispatch_0
	call nz,zoom_in_dispatch_1
	bit 1,b			#Bit C of byte B. Stupid instruction/operand ordering
	call z,zoom_in_dispatch_0
	call nz,zoom_in_dispatch_1
	bit 0,b			#Bit C of byte B. Stupid instruction/operand ordering
	call z,zoom_in_dispatch_0
	call nz,zoom_in_dispatch_1
	
	jp zoom_in_inner

zoom_in_exit:
	## Turn off auto mode again
	call disp_disable_auto_write	
	
	## Write the player pos out
	pop bc			#Restore BC
	push bc
	
	## Sod it, the monsters/ghosts/jewels will be written on
	## the next network packet
	## Get the offset for the row
	ld h,128
	ld l,c
	mlt hl

	## Add on for the column
	ld c,b
	ld b,0x00
	add hl,bc

	## And move to it
	call disp_set_adp

	## Now, fire off a P (for player)
	## Were still in auto mode, just fire it down the lines
	ld a,'P'
	call disp_write_char

	## We now need to change the text area
	ld a,128
	call clear_to_send
	out0 (disp_data),a

	ld a,0x00
	call clear_to_send
	out0 (disp_data),a

	ld a,0x41
	call clear_to_send
	out0 (disp_cmd),a

	## Update the PRT routine to use the new movement code
	call PRT_set_in	
	## And the network callback
	call network_callback_set_in
	pop bc
	pop hl
	pop af

	ei
	ret

zoom_in_dispatch_0:
	ld a,0x00
	call disp_send_byte
	ret

zoom_in_dispatch_1:
	ld a,0xFF
	call disp_send_byte	
	ret
	
zoom_out:
	push hl
	push bc
	
	ld hl,disp_gfx_home
	call disp_set_adp

	call disp_graphics_mode
	
	ld hl,0xc000
	ld b,0xff
	call disp_write_b_seq
	ld b,0xff
	call disp_write_b_seq
	ld b,0xff
	call disp_write_b_seq
	ld b,0xff
	call disp_write_b_seq
	ld b,0x10
	call disp_write_b_seq	

	## We also need to write the player position out
	pop bc			#Get the player pos back out again
	push bc

	ld a,b
	srl b;srl b;srl b
	ld h,0x10
	ld l,c
	mlt hl
	ld c,b
	ld b,0x00
	add hl,bc

	call disp_set_adp

	and 0x07
	cpl
	call clear_to_send
	or 0xF8
	out0 (disp_cmd),a	
	
	## Update the PRT routine to use the new movement code
	call PRT_set_out
	## And the network callback
	call network_callback_set_out

	pop bc
	pop hl

	ret

	
