#include "common.h"
#include "display_small.h"
#include "display.h"
#include "network.h"
#include "tilt.h"
#include "timer.h"
#include "rtc.h"
	
top:
	## Set everything up
	ld sp,sp_loc

	## Set up interrupts
	ld bc,int_table
	ld a,b
	ld i,a
	out0 (0x33),c
	
	## Call all initialisers
	call init
	call disp_init
	call timer_init
	call network_init
	call rtc_init

	
	call disp_clear_text
	call disp_clear_graphics
	call disp_text_mode
	call clear_small

	## Write the menu out
	ld b,16
	ld hl,blank_line
	call disp_write_seq
	ld hl,tilt_game
	call disp_write_seq
	ld hl,blank_line
	call disp_write_seq
	ld hl,start
	call disp_write_seq
	ld hl,start_2
	call disp_write_seq

	ld hl,tilt_game
	call write_seq_small

	
in_loop:
	in0 a,(0xF4)
	and 0x88
	cp 0x00
	jp z,in_loop

	## Start the game!
	call disp_clear_text

	ld b,22
	ld hl,loading
	call disp_write_seq
	call network_recv_map

	call clear_small
	ld b,16
	ld hl,done
	call write_seq_small

	call disp_clear_text
	ld hl,0x0000
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

	## We should have the map, enter the main game loop
	## B = X axis
	## C = Y axis
	## TODO - fix this to probe for a blank space instead
	ld bc,0x0101
	ld de,0x30FF		#Counter so the timers dont go mad
	
	## The rest is handled by the PRTs
	call timer_0_enable

	## Set a custom RTC callback
	ld hl,main_rtc_callback
	call rtc_set_callback
	call rtc_start
	call clear_small
	
	ei
	
	## ZOMG INFINITE LOOP
loop:	nop
	jp loop

	## -------------------------------------------------------------------------------
	## Interrupts
	## -------------------------------------------------------------------------------
	## Initial interrupt vector table
	.align 5
int_table:
INT1:	 .int defh
INT2:	 .int defh
PRT0:	 .int defh
PRT1:	 .int defh
DMA0:	 .int defh
DMA1:	 .int defh
CSIO:	 .int defh
ASCI0:	 .int defh
ASCI1:	 .int defh

defh:	ei
	reti
	
stub:	halt

	
PRT_routine:
	dec de
	ld a,d
	and 0xFF
	jp z,PRT_start
	ei
	reti
	
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

main_rtc_callback:
	halt
	ret
	
	## -----------------------------------------------------------------------------
	## Messages
	## -----------------------------------------------------------------------------
blank_line:	"                " #Len: 16
tilt_game:	"   Tilt Game    " #Len: 16
start:	        "Press any button" #Len: 16
start_2:	"    to begin    " #Len: 16
loading:	"Please flip the switch" #Len:22
done:		"     Loaded     " #Len: 16

	## ----------------------------------------------------------------------------
	## Vars
	## ----------------------------------------------------------------------------
	## We dont appear to have any yet :)
