#include "common.h"
#include "display_small.h"
#include "display.h"
#include "network.h"
#include "tilt.h"
#include "timer.h"
#include "rtc.h"
#include "tilt_prt.h"
#include "network_callback.h"
#include "graphics.h"
	
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
	call main_network_end_callback_init

	ld a,game_running
	ld (game_state),a
	
	ld a,'0'
	ld (time_min_1),a
	ld (time_min_2),a
	ld (time_sec_1),a
	ld (time_sec_2),a

	ld a,0			#Reset the menu item selected to 0
	ld (menu_sel),a
	ld (jewels_collected),a
	
	call disp_clear_graphics
	call disp_clear_text
	call disp_text_mode
	call clear_small

	## Write the menu out
	ld b,16
	ld hl,blank_line
	call disp_write_seq
	ld hl,tilt_game
	call disp_write_seq
	ld hl,sep
	call disp_write_seq
	ld hl,play_sel
	call disp_write_seq
	ld hl,view_scores
	call disp_write_seq
	ld hl,exit
	call disp_write_seq

	ld hl,tilt_game
	call write_seq_small

in_loop:
	in0 a,(0xF4)		#Get the state of the systems buttons
	and 0x0E
	cp 0x0E			#Clicked in
	jp z,menu_click

	cp 0x04
	jp z,menu_up

	cp 0x02
	jp z,menu_down

	jp in_loop
	
menu_up:
	ld a,(menu_sel)
	cp 0x00
	jp z,in_loop
	dec a
	ld (menu_sel),a

	ld h,0x10
	ld l,a
	mlt hl			#The line offset we need to change
	push hl
	push hl
	
	ld bc,disp_text_home+0x0030
	add hl,bc
	call disp_set_adp	#Set the address pointer to the new line

	pop hl
	ld bc,play_sel
	add hl,bc		#Add on the offset into the messages
	ld b,16
	call disp_write_seq

	## Now set the prev line back again
	pop hl
	ld bc,0x0010
	add hl,bc
	## Conviently, the ADP will already be on the next line ;)
	ld bc,play
	add hl,bc
	ld b,16
	call disp_write_seq

	halt			#We really shouldnt exploit the RTC like this, but oh well
	
	jp in_loop
	
menu_click:
	ld a,(menu_sel)
	cp 0x00
	jp z,game_start
	cp 0x02
	jp z,game_reset

	jp in_loop
	
menu_down:
	ld a,(menu_sel)
	cp 0x02
	jp z,in_loop
	
	ld h,0x10
	ld l,a
	mlt hl			#The line offset (prev line) we need to change
	push hl
	push hl
	
	inc a
	ld (menu_sel),a		#And now increment the menu item selected number thingy
	
	ld bc,disp_text_home+0x0030
	add hl,bc
	call disp_set_adp	#Set the address pointer to the line

	pop hl
	ld bc,play
	add hl,bc		#Add on the offset into the messages
	ld b,16
	call disp_write_seq

	## Now set the next line to what is needed
	pop hl
	ld bc,0x0010
	add hl,bc
	## Conviently, the ADP will already be on the next line ;)
	ld bc,play_sel
	add hl,bc
	ld b,16
	call disp_write_seq

	halt 			#We really shouldnt exploit the RTC like this, but oh well
	
	jp in_loop


	## ----------------------------------------------------------------------
	## Start of the game
	## ----------------------------------------------------------------------
game_start:	
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

	## Show the time on the screen
	call clear_small
	ld hl,timer
	ld b,11
	call write_seq_small

	## Show the number of jewels collected on the screen
	ld a,s_line_2_offset
	call set_adp_small
	ld hl,jewel_msg
	ld b,9
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

	## Set the end of network callback
	ld hl,main_network_end_callback
	call network_set_end_callback
	call network_enable_recv_int
	
	ei

	## Quick test - zoom in
	call zoom_in

	
	## Main game state checking loop
loop:	ld a,(game_state)
	cp game_dead
	jp z,loop_dead
	cp game_complete
	jp z,loop_complete
	jp loop

	## Were safe enough to make these calls blocking, after all
	## we dont want anything to actually be happening while were dead...
loop_dead:
	di

	call rtc_stop
	call clear_small
	ld hl,dead
	ld b,16
	call write_seq_small

	ld a,s_line_2_offset
	call set_adp_small
	
	ld hl,btn_cont
	ld b,16
	call write_seq_small

loop_dead_inner:
	in0 a,(0xf4)
	and 0x88
	jp nz,top
	jp loop_dead_inner

loop_complete:
	di

	call rtc_stop
	call clear_small
	ld hl,complete
	ld b,16
	call write_seq_small

	ld a,s_line_2_offset
	call set_adp_small
	ld hl,your_time
	ld b,16
	call write_seq_small
	
	call disp_clear_graphics
	ld hl,disp_gfx_home
	call disp_set_adp
	
	ld hl,cake
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
	
loop_complete_inner:
	nop
	jp loop_complete_inner

	## ------------------------------------------------------------------------
	## Highscore display routine
	## ------------------------------------------------------------------------

	## ------------------------------------------------------------------------
	## Reset back to monitor
	## ------------------------------------------------------------------------
game_reset:
	nop
	rst 0x0000
	
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
	
stub:	nop
	ei
	ret

	## --------------------------------------------------------------------------
	## RTC handler code
	## --------------------------------------------------------------------------
main_rtc_callback:
	push af
	push bc
	push hl

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

	pop hl
	pop bc
	pop af
	ret
	
	## -----------------------------------------------------------------------------
	## Messages
	## -----------------------------------------------------------------------------
blank_line:	"                " #Len: 16
tilt_game:	"    MCP 2009    " #Len: 16
sep:	        "----------------" #Len: 16
	## Menu items
play:		"      Play      " #Len: 16
view_scores:	" Display Scores " #Len: 16
exit:		"      Exit      " #Len: 16
	## Menu items (selected)
play_sel:	"     >Play<     " #Len: 16
view_scores_sel:">Display Scores<" #Len: 16
exit_sel:	"     >Exit<     " #Len: 16

	## Loading stuffs
loading:	"Please flip the switch" #Len:22
done:		"     Loaded     " #Len: 16
	## Game progress stuffs
jewel_msg:	"Jewels: 0"        #Len:9

dead:		"  You are dead  " #Len:16
complete:	"    You won!    " #Len:16

btn_cont:	" Press any btn  " #Len: 16

your_time:	"Your " #Len:16 (inc time below)
	
timer:          "Time: "	   #Len: 11 (inc digits (below)) - THIS MUST BE THE LAST MESSAGE
	
	## ----------------------------------------------------------------------------
	## Vars
	## ----------------------------------------------------------------------------
	## Were going to cheat for the time values and just store the ASCII values instead :)
time_min_1:	.byte '0'
time_min_2:	.byte '0'
time_sep:	.byte ':' 	
time_sec_1:	.byte '0'
time_sec_2:	.byte '0'	#Now, to write the time, we can just tell the display to write from time_min_1

	## Which menu item have we selected?
menu_sel:		.byte 0x00

	## Monster and ghost storage
monsters:		.space monster_space
monsters_count:		.byte 0x00
curr_monster_offset:	.int monsters
	
ghosts:			.space ghost_space
ghosts_count:		.byte 0x00
curr_ghost_offset:	.int ghosts
	
jewels:			.space jewel_space
jewels_count:		.byte 0x00
jewels_collected:	.byte 0x00
curr_jewel_offset:	.int jewels
	
item_recv_count:	.byte 0x00
curr_ix_val:		.int 0x0000

game_state:		.byte game_running
