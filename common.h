#ifndef __COMMON_H__
#define __COMMON_H__

	## Constants

nmi_callback=0xF24C
sp_loc=0xEFFF

item_count=30

monster_space=10
ghost_space=10
jewel_space=10

##Game states
game_running=0x00
game_dead=0x01
game_complete=0x02

	## Global exports
	.globl delay
  	.globl init
	.globl default_callback
	.globl collide_item_check

	.globl monsters
	.globl monsters_count
	.globl curr_monster_offset

	.globl ghosts
	.globl ghosts_count
	.globl curr_ghost_offset

	.globl jewels
	.globl jewels_count
	.globl jewels_collected
	.globl curr_jewel_offset

	.globl game_state

	.globl item_recv_count

	.globl int_table
	.globl INT1
	.globl INT2
	.globl PRT0
	.globl PRT1
 	.globl DMA0
	.globl DMA1
	.globl CSIO
	.globl ASCI0
	.globl ASCI1
#endif
