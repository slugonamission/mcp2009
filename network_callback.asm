#include "network_callback.h"
#include "common.h"
#include "display.h"
#include "display_small.h"
#include "rtc.h"
#include "network.h"
#include "tilt_prt.h"

main_network_end_callback_init:
	push af
	ld a,0x00
	ld (received_jewels),a
	ld (jewels_count),a
	pop af

	ret
	
	## -----------------------------------------------------------------------------
	## Network data handler code
	## -----------------------------------------------------------------------------
main_network_end_callback:
	push af
	push hl
	push de
	push bc

	ld b,0x00		#The number of items we have currently handled

	ld a,monsters
	ld (curr_monster_offset),a
	ld a,ghosts
	ld (curr_ghost_offset),a
	ld a,jewels
	ld (curr_jewel_offset),a
	
 	ld a,(network_item_count)
	ld (item_recv_count),a

	ld ix,monsters
	ld hl,monsters_count
	
main_network_end_monster_clear_loop:
	## Start clearing the old pixels
	ld a,b
	cp (hl)
	jp z,main_network_end_monster_clear_end
	inc a
	ld b,a
	
	ld d,(ix)
	inc ix
	ld e,(ix)
	inc ix

	push hl
	## Now do the transform to clear the right pixel
	ld h,0x10
	ld l,e
	mlt hl
	ld a,d
	srl d;srl d;srl d
	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp
	
	and 0x07
	cpl
	or 0xF0
	and 0xF7
	call clear_to_send
	out0 (disp_cmd),a

	pop hl
	
	jp main_network_end_monster_clear_loop
	
main_network_end_monster_clear_end:
	ld b,0x00

	ld ix,ghosts
	ld hl,ghosts_count
	
main_network_end_ghost_clear_loop:
	## Start clearing the old pixels
	ld a,b
	cp (hl)
	jp z,main_network_end_ghost_clear_end
	inc a
	ld b,a

	ld d,(ix)
	inc ix
	ld e,(ix)
	inc ix

	push hl
	## Now do the transform to clear the right pixel
	ld h,0x10
	ld l,e
	mlt hl
	ld a,d
	srl d;srl d;srl d
	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp
	
	and 0x07
	cpl
	or 0xF0
	and 0xF7
	call clear_to_send
	out0 (disp_cmd),a

	pop hl
	
	jp main_network_end_ghost_clear_loop
	
main_network_end_ghost_clear_end:
	ld ix,network_recv_buffer
	ld b,0x00

	ld a,0x00
	ld (monsters_count),a
	ld (ghosts_count),a
	
main_network_end_callback_loop:	
	## We now need to step through the recv buffer, looking for the data
	ld d,(ix)
	inc ix
	ld e,(ix)
	inc ix

	ld a,e
	and 0xC0		#Select just the ident bits

	## Figure out which store procedure to call
	cp 0x40
	call z,store_jewel
	jp z,network_jewel_display_callback
	
	cp 0x80
	call z,store_ghost
	jp z,network_callback_display

	cp 0xc0
	call z,store_monster
	jp z,network_callback_display


network_jewel_display_callback:
	ld h,a			#Store A somewhere convinent for now
	ld a,(received_jewels)
	cp 0xFF
	ld a,h
	jp z,network_callback_display_end
	
network_callback_display:	
	ld a,e
	and 0x3F		#Strip off the ident bits
	ld e,a

	## Standard display procedure
	ld h,0x10
	ld l,e
	mlt hl
	
	ld a,d
	srl d;srl d;srl d
	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp
	
	and 0x07
	cpl
	or 0xF8
	call clear_to_send
	out0 (disp_cmd),a

network_callback_display_end:	
	inc b
	ld a,(item_recv_count)
	cp b

	jp nz,main_network_end_callback_loop

	## Finally, display the jewels
	ld ix,jewels
	ld b,0x00
	ld hl,jewels_count

network_callback_display_jewels:
	ld a,b
	cp (hl)
	jp z,network_callback_display_jewels_end
	inc a
	ld b,a
	
	ld d,(ix)
	inc ix
	ld e,(ix)
	inc ix
	ld a,e
	cp 0xFF
	jp z,network_callback_display_jewels

	## Done the checks, display the jewel
	push hl
	
	ld h,0x10
	ld l,e
	mlt hl
	ld a,d
	srl d;srl d;srl d
	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp
	
	and 0x07
	cpl
	or 0xF8
	call clear_to_send
	out0 (disp_cmd),a

	pop hl
	jp network_callback_display_jewels
	
network_callback_display_jewels_end:		
	## We have all the items
	## Test collisions with enemies
	pop bc
	push bc			#Restore BC, and also push it back again for the POP BC later

	call collide_item_check

	
	ld a,0xFF
	ld (received_jewels),a	#Set the flag to say we have received the jewels

	pop bc
	pop de
	pop hl
	pop af
	ret

	## --------------------------------------------------------------------------
	## Storage routines
	## --------------------------------------------------------------------------
store_jewel:
	push af
	ld a,(received_jewels)
	cp 0x00
	jp nz,store_jewel_end

	ld a,d
	ld hl,(curr_jewel_offset)
	ld (hl),a
	inc hl

	ld a,e
	and 0x3F
	ld (hl),a
	inc hl
	ld (curr_jewel_offset),hl

	ld a,(jewels_count)
	inc a
	ld (jewels_count),a
	
store_jewel_end:
	pop af
	ret

store_ghost:
	push af
	
	ld a,d
	
	ld hl,(curr_ghost_offset)
	ld (hl),a
	inc hl

	ld a,e
	and 0x3F		#Strip the ident bits
	ld (hl),a
	inc hl
	ld (curr_ghost_offset),hl

	ld a,(ghosts_count)
	inc a
	ld (ghosts_count),a

	pop af
	ret

store_monster:
	push af
	ld a,d
	
	ld hl,(curr_monster_offset)
	ld (hl),a
	inc hl

	ld a,e
	and 0x3F		#Strip the ident bits
	ld (hl),a
	inc hl
	ld (curr_monster_offset),hl

	ld a,(monsters_count)
	inc a
	ld (monsters_count),a

	pop af
	ret
	

received_jewels:	.byte 0x00
