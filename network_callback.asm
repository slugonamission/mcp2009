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

	ld a,monsters
	ld (curr_monster_offset),a
	ld a,ghosts
	ld (curr_ghost_offset),a
	ld a,jewels
	ld (curr_jewel_offset),a
	
 	ld a,(network_item_count)
	ld (item_recv_count),a
	
	ld hl,main_network_callback_clear_end
	push hl
	ld hl,(network_callback_clear_items_jump)
	jp (hl)

main_network_callback_clear_end:
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

	## Jump to the relevant routine to display the items
	ld hl,(network_callback_display_items_jump)
	jp (hl)
	
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
	push hl
	ld hl,network_callback_display_jewels_end
	ex (sp),hl	#Push on the return address

	push hl
	ld hl,(network_callback_disp_j_jump)
	ex (sp),hl	#And also the address to jump to
	
	ret	#And jump to it!
	
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
	

	## Stores the jump location for the item display
network_callback_display_items_jump:	.int network_callback_display_items_out
	## Jump location for item clearing
network_callback_clear_items_jump:	.int network_callback_clear_items_out
	## And finally, for the jewel drawing
network_callback_disp_j_jump:		.int main_network_callback_disp_j_out

	## =======================================================================
	## Display code for items
	## =======================================================================
	## We really need to refactor all this
network_callback_display_items_out:
	ld a,e
 	and 0xC0		#Select just the ident bits

	## Figure out which store procedure to call
	cp 0x40
	call z,store_jewel
	jp z,network_callback_display_end
	
	cp 0x80
	call z,store_ghost
	jp z,network_callback_display_out

	cp 0xc0
	call z,store_monster
	jp z,network_callback_display_out
	
network_callback_display_out:	
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

	jp network_callback_display_end

	## --------------------------------------------------------------------------
	
network_callback_display_items_in:
	ld a,e
	and 0xC0		#Select the ident bits

	cp 0x40
	call z,store_jewel
	jp z,network_callback_display_end

	cp 0x80
	call z,store_ghost
	jp z,network_callback_display_ghost_in

	cp 0xc0
	call z,store_monster
	jp z,network_callback_display_monster_in

	## If we get here, something failed
	jp network_callback_display_end
	
network_callback_display_monster_in:
	ld a,e
	and 0x3F 		#Strip ident this time
	ld e,a

	ld h,128
	ld l,e
	mlt hl

	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp
	ld a,'M'
	call disp_write_char

	jp network_callback_display_end

network_callback_display_ghost_in:
	ld a,e
	and 0x3F 		#Strip ident this time
	ld e,a

	ld h,128
	ld l,e
	mlt hl

	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp
	
	ld a,'G'
	call disp_write_char

	jp network_callback_display_end
	
	## ====================================================================
	## Routines for clearing the old locations
	## ====================================================================

network_callback_clear_items_in:
	ld ix,monsters
	ld hl,monsters_count
	ld b,0x00		#The number of items we have currently handled
	
main_network_end_monster_clear_loop_in:
	## Start clearing the old pixels
	ld a,b
	cp (hl)
	jp z,main_network_end_monster_clear_end_in
	inc a
	ld b,a
	
	ld d,(ix)
	inc ix
	ld e,(ix)
	inc ix

	push hl
	## Now do the transform to clear the right pixel
	ld h,128
	ld l,e
	mlt hl

	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp

	ld a,' '
	call disp_write_char

	pop hl
	
	jp main_network_end_monster_clear_loop_in
	
main_network_end_monster_clear_end_in:
	ld b,0x00

	ld ix,ghosts
	ld hl,ghosts_count
	
main_network_end_ghost_clear_loop_in:
	## Start clearing the old pixels
	ld a,b
	cp (hl)
	jp z,main_network_end_ghost_clear_end_in
	inc a
	ld b,a

	ld d,(ix)
	inc ix
	ld e,(ix)
	inc ix

	push hl
	## Now do the transform to clear the right pixel
	ld h,128
	ld l,e
	mlt hl

	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp

	ld a,' '
	call disp_write_char

	pop hl
	
	jp main_network_end_ghost_clear_loop_in

main_network_end_ghost_clear_end_in:
	ret

	## ====================================================================

network_callback_clear_items_out:
	ld ix,monsters
	ld hl,monsters_count
	ld b,0x00		#The number of items we have currently handled
	
main_network_end_monster_clear_loop_out:
	## Start clearing the old pixels
	ld a,b
	cp (hl)
	jp z,main_network_end_monster_clear_end_out
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
	
	jp main_network_end_monster_clear_loop_out
	
main_network_end_monster_clear_end_out:
	ld b,0x00

	ld ix,ghosts
	ld hl,ghosts_count
	
main_network_end_ghost_clear_loop_out:
	## Start clearing the old pixels
	ld a,b
	cp (hl)
	jp z,main_network_end_ghost_clear_end_out
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
	
	jp main_network_end_ghost_clear_loop_out

main_network_end_ghost_clear_end_out:
	ret

	## =============================================================
	## Finally, routines to handle jewel drawing
	## =============================================================
main_network_callback_disp_j_out:	
	ld a,b
	cp (hl)
	jp z,main_network_callback_disp_h_end_out
	inc a
	ld b,a
	
	ld d,(ix)
	inc ix
	ld e,(ix)
	inc ix
	ld a,e
	cp 0xFF
	jp z,main_network_callback_disp_j_out

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
	jp main_network_callback_disp_j_out

main_network_callback_disp_h_end_out:
	ret

	## =============================================================

main_network_callback_disp_j_in:	
	ld a,b
	cp (hl)
	jp z,main_network_callback_disp_h_end_in
	inc a
	ld b,a
	
	ld d,(ix)
	inc ix
	ld e,(ix)
	inc ix
	ld a,e
	cp 0xFF
	jp z,main_network_callback_disp_j_in

	## Done the checks, display the jewel
	push hl
	
	ld h,128
	ld l,e
	mlt hl

	ld e,d
	ld d,0x00
	add hl,de
	call disp_set_adp
	
	ld a,'J'
	call disp_write_char

	pop hl
	jp main_network_callback_disp_j_in

main_network_callback_disp_h_end_in:
	ret

	## =============================================================
	## Routines to change the pointers to handle zooming
	## =============================================================

network_callback_set_in:
	push hl
	ld hl,network_callback_display_items_in
	ld (network_callback_display_items_jump),hl

	ld hl,network_callback_clear_items_in
	ld (network_callback_clear_items_jump),hl

	ld hl,main_network_callback_disp_j_in
	ld (network_callback_disp_j_jump),hl

	pop hl

	ret

network_callback_set_out:
	push hl
	ld hl,network_callback_display_items_out
	ld (network_callback_display_items_jump),hl
	
	ld hl,network_callback_clear_items_out
	ld (network_callback_clear_items_jump),hl

	ld hl,main_network_callback_disp_j_out
	ld (network_callback_disp_j_jump),hl

	pop hl

	ret
	
received_jewels:	.byte 0x00
