#include "network.h"
#include "common.h"
#include "display_small.h"

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

network_clear_errors:
	push af
	in0 a,(asci_ctrl_a_0)
	and 0xF7
	out0 (asci_ctrl_a_0),a
	pop af
	ret

	## Loads a byte from the network into A
	## Destroys: Anything currently in A. Duh.
network_recv_byte:
	call network_clear_errors
	in0 a,(asci_stat_0)
	and 0x80		#1000000 i.e. check for RDRF+DCD0
	cp 0x80
	jp nz,network_recv_byte
	
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
	
network_set_end_callback:
	ld (network_end_callback),hl
	ret
	
	## -------------------------------------------------------
	## Interrupt handler
	## -------------------------------------------------------
network_handler_start:
	push af
	push bc

	ld c,0x00		#Checksum
	
	
	call network_recv_byte
	cp 0x55
	jp nz,network_handler_real_end

	## Checksumming
	add a,c
	and 0x7f
	ld c,a
	
	## Ok, we have just had the start byte, now receive the length
	call network_recv_byte
	## Subtract the start(1), len(1), row(1), map data(16), checksum(1) and end(1) bytes = 21
	sub 21
	ld (network_bytes_total),a

	## Checksumming
	add a,21
	add a,c
	and 0x7f
	ld c,a
	
	## Get the row number. We dont actually need this though
	call network_recv_byte

	add a,c
	and 0x7f
	ld c,a
	## Now we can start receiving the map row
	ld b,0x00
network_handler_recv_map:	
	call network_recv_byte

	## Do the checksum here
	add a,c
	and 0x7f
	ld c,a
	
	inc b
	ld a,16
	cp b
	jp nz,network_handler_recv_map

	## Ok, now we can start receiving the monsters etc
	ld iy,network_recv_buffer
	ld b,0x00		#Reset B to use as a counter again
	
network_handler_recv_item:
	ld a,(network_bytes_total)
	cp b
	jp z,network_handler_recv_item_end
	
	call network_recv_byte
	ld (iy),a
	inc iy
	inc b

	## Checksum again
	add a,c
	and 0x7f
	ld c,a
	
	jp network_handler_recv_item
	
network_handler_recv_item_end:	
	## Receive the checksum
	call network_recv_byte

	## Check the checksum
	cp c
	jp nz,network_handler_error #Checksums dont match, break out
	
	## And finally, get the last byte
	call network_recv_byte
	cp 0x0d
	jp nz,network_handler_error
	
network_handler_end:	
	## Calculate how many monsters we actually have (bytes/2)
	ld a,(network_bytes_total)
	srl a
	ld (network_item_count),a
	jp z,network_handler_real_end
	
	## Now call the custom callback
	push hl
	ld hl,network_handler_callback_end
	push hl
	ld hl,(network_end_callback)
	jp (hl)	

network_handler_callback_end:
	pop hl
	
network_handler_real_end:
	pop bc
	pop af
	ei
	reti

network_handler_error:
	## OH TEH NOES - WE BROKE
	## We should be safe enough to just jump back in to the return function
	jp network_handler_real_end
	
	## -------------------------------------------------------
	## Vars
	## -------------------------------------------------------
network_end_callback:		.int default_callback
network_bytes_recv:		.byte 0x00
network_bytes_total:		.byte 0x00
network_item_count:		.byte 0x00
network_recv_buffer:		.space item_space

