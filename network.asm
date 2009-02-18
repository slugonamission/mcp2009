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
	ld hl,network_handler_start
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

	## The handlers for each seperate part of it all
network_handler_start:
	push af
	push hl
	in0 a,(asci_recv_0)
	cp 0x55
	jp nz,network_handler_start_end

	ld hl,network_handler_len
	ld (ASCI0),hl
	
network_handler_start_end:
	pop af
	pop hl
	reti

	## -----------------------------------------------------------------
network_handler_len:
	push af
	push hl
	
	in0 a,(asci_recv_0)
	sub 0x04
	ld (network_bytes_recv),a

	pop hl
	pop af
	reti

	## -----------------------------------------------------------------
network_handler_map:
	## Were not actually interested in this data, ignore it
	push af
	in0 a,(asci_recv_0)

	ld a,(network_bytes_recv)
	inc a
	ld (network_bytes_recv),a
	cp 16
	jp nz,network_handler_map_end

	push hl
	ld hl,network_handler_extra
	ld (ASCI0),hl
	pop hl

network_handler_map_end:
	pop af
	reti
	
	## -----------------------------------------------------------------
network_handler_extra:
	## Finally, we can check for jewels and ghosts!
	push af
	push hl
	in0 a,(asci_recv_0)
	push af

	ld a,(network_bytes_recv)
	inc a
	ld (network_bytes_recv),a

	ld h,a
	
	ld a,(network_bytes_total)
	cp h
	pop af
	jp z,network_handler_extra_change

	push af			#Were going to need it again!
	## Figure out what type of item we have
	and 0xC0		#Get the upper 2 bits

	cp 0x40
	jp z,network_handler_extra_jewel
	cp 0x80
	jp z,network_handler_extra_ghost
	cp 0xc0
	jp z,network_handler_extra_monster

network_handler_extra_jewel:
	pop af
	ld hl,network_handler_extra_end
	push hl
	ld hl,(network_jewel_callback)
	jp (hl)
	
network_handler_extra_ghost:
	pop af
	ld hl,network_handler_extra_end
	push hl
	ld hl,(network_ghost_callback)
	jp (hl)
	
network_handler_extra_monster:	
	pop af
	ld hl,network_handler_extra_end
	push hl
	ld hl,(network_monster_callback)
	jp (hl)
	
	## Change the handler to the next one
network_handler_extra_change:	
	ld hl,network_handler_checksum
	ld (ASCI0),hl

network_handler_extra_end:
	pop hl
	pop af
	reti
	
	## -------------------------------------------------------------
network_handler_checksum:
	## We dont care about the checksum right now
	push af
	push hl
	in0 a,(asci_recv_0)

	ld hl,network_handler_end
	ld (ASCI0),hl

	pop hl
	pop af
	reti
	
	## -------------------------------------------------------------
network_handler_end:
	push af
	push hl
	in0 a,(asci_recv_0)

	ld hl,network_handler_end_end
	push hl
	ld hl,(network_end_callback)
	jp (hl)
	
network_handler_end_end:
	pop hl
	pop af
	reti
	
	## -------------------------------------------------------
	## Vars
	## -------------------------------------------------------
network_monster_callback:	.int default_callback
network_ghost_callback:		.int default_callback
network_jewel_callback:		.int default_callback
network_end_callback:		.int default_callback
network_bytes_recv:		.byte 0x00
network_bytes_total:		.byte 0x00
