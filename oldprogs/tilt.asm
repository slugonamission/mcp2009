#include "common.h"
#include "display_small.h"
#include "display.h"
#include "network.h"
#include "tilt.h"

init:	ld sp,sp_loc
top:
	## Init the small display
	call clear_small
	## Init the big display
	call disp_init
	call disp_clear_graphics
	call disp_clear_text
	call disp_graphics_mode

	## B = X axis
	## C = Y axis
	ld bc,0x0000
draw_loop:
	push bc
	ld a,b
	srl b;srl b;srl b;
	ld h,0x10
	ld l,c
	mlt hl
	ld c,b
	ld b,0x00
	add hl,bc
	ld b,h
	ld c,l
	
	call disp_set_adp	#Set where we're putting this
	
	pop bc

	and 0x07		#Get the last 3 bits
	cpl
	call clear_to_send
	or 0xf8
	out0 (disp_cmd),a
	
	## LOLTILT
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

	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay
	ld l,0xff
	call delay

	jp draw_loop

tilt_up:
	push af
	ld a,c
	sub 0x01
	ld c,a
	pop af
	ret
	
tilt_down:
	push af
	ld a,c
	add a,0x01
	ld c,a
	pop af
	ret
	
tilt_left:
	push af
	ld a,b
	sub 0x01
	ld b,a
	pop af
	ret
	
tilt_right:
	push af
	ld a,b
	add a,0x01
	ld b,a
	pop af
	ret

