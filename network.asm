#include "network.h"
#include "common.h"
	
network_init:
	## Were using port 0
	## Set up ctrl a
	## MPE off, RE on, TE off, RTS on, EFR off, 1 stop bit, 8 data, no parity
	ld a,0x4C
	out0 (asci_ctrl_a_0),a
	## Set up ctrlB
	## MPBT=0,MP=0,PS=0,PEO=X,DR=0,SS1/2=0,SS0=1 (19200 baud)
	ld a,0x01
	out0 (asci_ctrl_b_0),a

	## Set the needed flags in the status register
	in0 a,(asci_stat_0)
	and 0xf6
	out0 (asci_stat_0),a

	## Patch ourself into the main interrupt handler
	ld hl,network_int_handler
	ld (ASCI0),hl
	
	ret
	
	## Recieves map data from the network
	## hl - where to store the map
	## Destroys:
	## hl - yeah, its probably going to fuck it up a bit
network_recv_map:
	push af			#Were going to need it a lot
	push bc
	push de
	ld b,0x00
network_recv_map_start:
	call network_recv_byte
	cp 0x55		#Check for the start byte
	jp nz,network_recv_map_start #If not, jump back to top

	## Get the packet number
	call network_recv_byte	#Get the packet length
	call network_recv_byte	#Get the row number
	ld e,a			     #Put the row number in C
	## Figure out the offset for HL
	ld d,0x10
	mlt de
	ld hl,mcp_map_loc
	add hl,de

	## Ok, receive the rest of this row
	ld c,0x00
network_recv_map_row_loop:	
	call network_recv_byte
	cpl
	ld (hl),a		#Store the byte in (hl)
	inc hl			#inc HL
	ld a,c			
	inc a			#Increment the recv byte counter
	
	cp 0x10			#C=16?
	ld c,a
	jp nz,network_recv_map_row_loop

	## Ok, we finished this iteration, scan for the end byte
network_recv_map_row_loop_end:
	call network_recv_byte
	cp 0x0d
	jp nz,network_recv_map_row_loop_end

	## Got the end bit and all that
	## Do we need to receive more rows?
	ld a,b
	inc a
	cp mcp_map_rows
	ld b,a
	jp nz,network_recv_map_start
	## Else, were done!
	pop de
	pop bc
	pop af

	ret
	
	## Loads a byte from the network into A
	## Destroys: Anything currently in A. Duh.
network_recv_byte:
	in0 a,(asci_stat_0)
	and 0x80		#1000000 i.e. check for RDRF
	cp 0x80
	jp nz, network_recv_byte

	## Ok, we have data, load it into a
	in0 a,(asci_recv_0)
	ret

	## Enables the interrupt on data recv
network_enable_recv_int:
	push af
	
	in0 a,(asci_stat_0)
	or 0x08
	out0 (asci_stat_0),a

	pop af	
	ret

	## Disables interrupt on data recv
network_disable_recv_int:
	push af

	in0 a,(asci_stat_0)
	and 0xF7
	out0 (asci_stat_0),a

	pop af
	ret
	
network_set_monster_callback:
	ld (network_monster_callback),hl
	ret

network_set_ghost_callback:
	ld (network_ghost_callback),hl
	ret

network_set_jewel_callback:
	ld (network_jewel_callback),hl
	ret

network_set_end_callback:
	ld (network_end_callback),hl
	ret
	
	## -------------------------------------------------------
	## Interrupt handler
	## -------------------------------------------------------
network_int_handler:
	push af

	in0 a,(asci_recv_0)

network_int_handler_end:	
	pop af
	reti

	## The handlers for each seperate part of it all
network_handler_start:
	jp network_int_handler_end

network_handler_len:
	jp network_int_handler_end

network_handler_map:
	jp network_int_handler_end

network_handler_extra:
	jp network_int_handler_end

network_handler_checksum:
	jp network_int_handler_end

network_handler_end:
	jp network_int_handler_end
	
	## -------------------------------------------------------
	## Vars
	## -------------------------------------------------------
network_monster_callback:	.int default_callback
network_ghost_callback:		.int default_callback
network_jewel_callback:		.int default_callback
network_end_callback:		.int default_callback
network_bytes_recv:		.byte 0x00
network_bytes_total:		.byte 0x00

	
network_int_jump_table:
	.byte 0x00