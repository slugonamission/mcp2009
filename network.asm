#include "network.h"

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
