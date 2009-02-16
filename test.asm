#include "common.h"
#include "display_small.h"
#include "display.h"
#include "network.h"
#include "tilt.h"
#include "timer.h"
#include "rtc.h"
#include "tilt_prt.h"
	
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

	ld a,'0'
	ld (time_min_1),a
	ld (time_min_2),a
	ld (time_sec_1),a
	ld (time_sec_2),a

	
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

	## Show the time on the screen
	call clear_small
	ld hl,timer
	ld b,11
	call write_seq_small
	
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
PRT0:	 .int PRT_routine
PRT1:	 .int defh
DMA0:	 .int defh
DMA1:	 .int defh
CSIO:	 .int defh
ASCI0:	 .int defh
ASCI1:	 .int defh
	
defh:	ei
	reti
	
stub:	halt

main_rtc_callback:
	push af
	push bc
	ld a,(time_sec_2)
	inc a
	cp 0x3A			#0x3A corresponds to '9'+1
	ld (time_sec_2),a
	jp nz,main_rtc_callback_end

	## We need to increment time_sec_2 now
	ld a,'0'		#Zero time_sec_2
	ld (time_sec_2),a

	ld a,(time_sec_1)
	inc a
	cp 0x36 		#>5?
	ld (time_sec_1),a
	jp nz,main_rtc_callback_end

	## Now increment the minutes
	ld a,'0'
	ld (time_sec_1),a
	ld a,(time_min_2)
	inc a
	cp 0x3A
	ld (time_min_2),a
	jp nz,main_rtc_callback_end

	## Increment the other minutes digit
	ld a,'0'
	ld (time_min_2),a
	ld a,(time_min_1)
	inc a
	ld (time_min_1),a	
	
main_rtc_callback_end:
	## Now, write the value out
	ld a,0x06
	call set_adp_small
	
	ld hl,time_min_1
	ld b,5
	call write_seq_small
	
	pop bc
	pop af
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
timer:          "Time: "	   #Len: 11 (inc digits (below))
	
	## ----------------------------------------------------------------------------
	## Vars
	## ----------------------------------------------------------------------------
	## Were going to cheat for the time values and just store the ASCII values instead :)
time_min_1:	.byte '0'
time_min_2:	.byte '0'
time_sep:	.byte ':' 	
time_sec_1:	.byte '0'
time_sec_2:	.byte '0'	#Now, to write the time, we can just tell the display to write from time_min_1

	## Monster and ghost storage
monsters:	.space monster_count
ghosts:		.space ghost_count
jewels:		.space jewel_count