	disp_data=0xF0
	disp_cmd=0xF1

	## Get the status, then send the command when we can
main:	ld sp,0xefff
	call clear_to_send

	## Set graphics home address
	ld a,0x00		
	out0 (disp_data),a
	call clear_to_send
	ld a,0x00
	out0 (disp_data),a
	call clear_to_send
	ld a,0x42
	out0 (disp_cmd),a

	## Set text home address
	ld a,0x14		
	out0 (disp_data),a
	call clear_to_send
	ld a,0x00
	out0 (disp_data),a
	call clear_to_send
	ld a,0x40
	out0 (disp_cmd),a

	## Set graphics area
	call clear_to_send	
	ld a,0x1E
	out0 (disp_data),a
	call clear_to_send
	ld a,0x00
	out0 (disp_data),a
	call clear_to_send
	ld a,0x43
	out0 (disp_cmd),a

	## Set text area
	call clear_to_send	
	ld a,0x1E
	out0 (disp_data),a
	call clear_to_send
	ld a,0x00
	out0 (disp_data),a
	call clear_to_send
	ld a,0x41
	out0 (disp_cmd),a

	## Set the offset pointer properly
	call clear_to_send
	ld a,0x00
	out0 (disp_data),a
	call clear_to_send
	ld a,0x03
	out0 (disp_data),a

	call clear_to_send
	ld a,0x22
	out0 (disp_cmd),a

	
	## OR mode (I think)
	call clear_to_send
	ld a,0x80
	out0 (disp_cmd),a
	
	## Turn the cursor on
	call clear_to_send
	ld a,0x97
	out0 (disp_cmd),a

	## BIG CURSOR
	call clear_to_send
	ld a,0xa0
	out0 (disp_cmd),a

	## Move the cursor back
	call clear_to_send
	ld a,0x00
	out0 (disp_data),a
	call clear_to_send
	out0 (disp_data),a

	call clear_to_send
	ld a,0x21
	out0 (disp_cmd),a

	## Move the address pointer back
	call clear_to_send
	ld a,0x14
	out0 (disp_data),a
	call clear_to_send
	ld a,0x00
	out0 (disp_data),a

	call clear_to_send
	ld a,0x24
	out0 (disp_cmd),a
	
	## Do some data output
	call clear_to_send
	ld a,0x2D
	out0 (disp_data),a
	call clear_to_send
	ld a,0xc0
	out0 (disp_cmd),a

	call clear_to_send
	ld a,0x23
	out0 (disp_data),a
	call clear_to_send
	ld a,0xc0
	out0 (disp_cmd),a

	call clear_to_send
	ld a,0x30
	out0 (disp_data),a
	call clear_to_send
	ld a,0xc0
	out0 (disp_cmd),a
	
loop:	halt
	
clear_to_send:
	in0 a,(disp_cmd)
	and 0x03
	cp 0x03
	jp nz,clear_to_send
	ret
