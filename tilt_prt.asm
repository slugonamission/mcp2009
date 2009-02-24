#include "common.h"
#include "tilt_prt.h"
#include "display.h"
#include "display_small.h"
#include "tilt.h"
#include "timer.h"
#include "rtc.h"
	
	## --------------------------------------------------------------------------------
	## Reload timer routine
	## Use: Gets the value from the tilt sensors. If the display is tilted, check we
	## 	can move into the space, and move the pixel into the space accordingly
	## --------------------------------------------------------------------------------
PRT_routine:
##	dec de
##	ld a,d
##	and 0xFF
##	jp z,PRT_start
##	ei
##	reti
	
PRT_start:
	ld de,0x30FF
	push de
	push af
	push hl			#Yeah, we use nearly every regiter
	
	ld d,b
	ld e,c			#So we can use DE later to clear the bit if we need to
	ld h,0x00		#We can use H as a hacky flag register
	
	## Do the tilt
	call tilt_get

	push af
	and 0xF0
	srl a;srl a;srl a;srl a
	cp 0x06
	call z,tilt_left
	cp 0x09
	call z,tilt_right

	pop af
	and 0x0F
	cp 0x06
	call z,tilt_up
	cp 0x09
	call z,tilt_down

	ld a,h
	and 0xFF
	jp z,PRT_end
	
	## Ok then, we need to update the display
	## DE holds the old location, BC holds the new one
	## Check we can actually move into this location
	push bc
	push bc
	## Simply check if the pixel is already set
	ld h,0x10 
	ld l,c
	mlt hl			#HL will now contain the offset to the start of the row
	
	ld a,h
	add a,0xc0		#Add on the offset into the display RAM
	ld h,a
	
	ld a,b
	## Now add on the X offset
	srl b;srl b;srl b
	ld c,b
	ld b,0x00
	add hl,bc

	pop bc			#Get BC back
	## Now, this is a nasty hack to compare the right bit. There's probably a better way, but I don't know it
	## A already contains the value of B from above
	and 0x07		#The bottom 3 bits of A contain which bit we need to check in the byte
	ld c,0x80		#Were going to be shifting this left until it contains the correct bit

shift_loop_start:	
	cp 0x00
	jp z,shift_loop_end	#See if were at the end of the loop
	srl c			#Shift c right
	dec a
	jp shift_loop_start
	
shift_loop_end:
	## Ok, we have the bit mask we want in c
	ld a,(hl)
	and c	       		#See if the required bit is set
	
	pop bc			#Just incase the next jump actually happens
	jp nz,PRT_restore_bc		#If it isnt 0, we cant move into it, jump out
	
	## Right then, we now need to update the pixels
	## Turn the new pixel on
	## Put HL to be 0 based again (i.e. dont account for the 0xc0 offset)
	ld a,h
	sub 0xc0
	ld h,a
	call disp_set_adp

	## Now, we need to check if were going to collide with an enemy
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
	ld a,b			#Load it with the new X value
	and 0x07
	cpl
	or 0xF8
	call clear_to_send
	out0 (disp_cmd),a
	## We should now have set the correct bit

	## Clear the previous bit
	ld a,d
	srl d;srl d;srl d
	ld h,0x10
	ld l,e
	mlt hl
	ld e,d
	ld d,0x00
	add hl,de

	call disp_set_adp

	and 0x07
	cpl
	call clear_to_send
	and 0xF7
	out0 (disp_cmd),a

	## We dont need to restore BC, jump over it
	jp PRT_end
PRT_restore_bc:
	ld b,d
	ld c,e
PRT_end:
	call timer_0_reset
	
	pop hl
	pop af			#Reinstate all the registers
	pop de
	ei
	reti

tilt_up:
	push af
	ld a,c
	sub 0x01
	ld c,a
	pop af
	ld h,0xFF		#Signal we need to move stuffs
	ret

tilt_down:
	push af
	ld a,c
	add a,0x01
	ld c,a
	pop af
	ld h,0xFF
	ret

tilt_left:
	push af
	ld a,b
	sub 0x01
	ld b,a
	pop af
	ld h,0xFF
	ret

tilt_right:
	push af
	ld a,b
	add a,0x01
	ld b,a
	pop af
	ld h,0xFF
	ret

death:
	push bc
	push hl
	call rtc_stop
	ld b,13
	ld hl,dead
	call clear_small
	call write_seq_small

	pop bc
	pop hl
	
	ret

dead:	"You have died"		#Len:13
