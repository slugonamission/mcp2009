	## TODO - DOCUMENT THIS MODULE

#include "display.h"

disp_init:
	## We use a a lot, swap it out for now
	push af
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
	ld a,0x00		
	out0 (disp_data),a
	call clear_to_send
	ld a,0x04
	out0 (disp_data),a
	call clear_to_send
	ld a,0x40
	out0 (disp_cmd),a

	## Set graphics area
	call clear_to_send	
	ld a,0x10
	out0 (disp_data),a
	call clear_to_send
	ld a,0x00
	out0 (disp_data),a
	call clear_to_send
	ld a,0x43
	out0 (disp_cmd),a

	## Set text area
	call clear_to_send	
	ld a,0x10
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

	
	## OR mode
	call clear_to_send
	ld a,0x80
	out0 (disp_cmd),a
	
	## Text on, no graphics, no cursor
	call clear_to_send
	ld a,0x94
	out0 (disp_cmd),a

	## Cursor size
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
	ld a,0x00
	out0 (disp_data),a
	call clear_to_send
	ld a,0x14
	out0 (disp_data),a

	call clear_to_send
	ld a,0x24
	out0 (disp_cmd),a
	## OMG WERE DONE!!!!!!!!!!!
	pop af
	ret

	## Sets the address pointer
	## Params: HL - address pointer value
disp_set_adp:
	push af
	call clear_to_send
	ld a,l
	out0 (disp_data),a
	call clear_to_send
	ld a,h
	out0 (disp_data),a

	call clear_to_send
	ld a,0x24
	out0 (disp_cmd),a
	pop af

	ret
	
	## Instructs the display to enter text mode
disp_text_mode:
	push af
	call clear_to_send
	ld a,0x94
	out0 (disp_cmd),a
	pop af
	ret

	## Instructs the display to enter graphics mode
disp_graphics_mode:
	push af
	call clear_to_send
	ld a,0x98
	out0 (disp_cmd),a
	pop af
	ret

	## Clears the whole of text-RAM
disp_clear_text:
	push af
	push hl
	ld hl,disp_text_home
	call disp_set_adp
disp_clear_text_inner:	
	ld a,h
	cp 0x18
	jp z,disp_clear_text_out
	## Else, write out a blank char to the screen
	ld a,0x20		#32 = ASCII space
	call disp_write_char
	inc hl
	jp disp_clear_text_inner
	
disp_clear_text_out:
	## Were done!
	## Set the ADP back to text start
	ld hl,disp_text_home
	call disp_set_adp

	## Exit the procedure
	pop hl
	pop af
	ret

disp_clear_graphics:
	push af
	push hl
	ld hl,disp_gfx_home
	call disp_set_adp
disp_clear_graphics_inner:
	ld a,h
	cp 0x04
	jp z,disp_clear_graphics_end
	ld a,0x00
	call disp_write_byte
	inc hl
	jp disp_clear_graphics_inner
disp_clear_graphics_end:
	ld bc,disp_gfx_home
	call disp_set_adp
	pop hl
	pop af
	ret
	
	## Writes a character to the screen
	## Params: A - the ASCII code to write
	## Destroys: A
disp_write_char:
	## Display chars = ASCII - 0x20
	sub 0x20		
	call clear_to_send
	out0 (disp_data),a
	call clear_to_send
	ld a,0xc0
	out0 (disp_cmd),a

	ret

	## Writes a byte to (ADP)
	## Params: A - the code to write
	## Destroys: A
disp_write_byte:
	push af
	call clear_to_send
	out0 (disp_data),a
	call clear_to_send
	ld a,0xc0
	out0 (disp_cmd),a
	pop af
	
	ret

	## Writes a sequence of chars to the screen
	## hl - start of sequence
	## b - number of bytes
	## Kills - hl,b
disp_write_seq:
	push af
	push bc
disp_write_seq_start:
	ld a,b
	cp 0
	jp z,disp_write_seq_end
	dec a
	ld b,a
	ld a,(hl)
	call disp_write_char
	inc hl
	jp disp_write_seq_start
	
disp_write_seq_end:
	pop bc
	pop af
	ret

	## Writes a sequence of bytes to the screen
	## hl - start of sequence
	## b - number of bytes
	## Kills - hl,b
disp_write_b_seq:
	push af
disp_write_b_seq_start:
	ld a,b
	cp 0
	jp z,disp_write_b_seq_end
	dec a
	ld b,a
	ld a,(hl)
	call disp_write_byte
	inc hl
	jp disp_write_b_seq_start
	
disp_write_b_seq_end:	
	pop af
	ret	

	## Checks the LCD status registers to check we can send data OK
clear_to_send:
	push af
clear_to_send_inner:
	in0 a,(disp_cmd)
	and 0x03
	cp 0x03
	jp nz,clear_to_send_inner
	pop af
	ret
