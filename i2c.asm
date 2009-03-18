#include "i2c.h"
	
i2c_init:
	push af
	
	ld a,0x80
	out0 (i2c_cmd),a 	#Write to own address

	ld a,0x55		#Our address
	out0 (i2c_data),a

	ld a,0x20		#Want to write the clock data
	out0 (i2c_cmd),a

	ld a,0x15		#6Mhz clock, 1.5kHz SCL
	out0 (i2c_data),a

	## Now turn ourselves on properly
	ld a,0x41
	out0 (i2c_cmd),a

	## We should be done now
	pop af
	ret

	## Checks the BB flag on the bus.
	## Effectively a CTS? routine 
i2c_check_bb:
	push af
i2c_check_bb_loop:	
	in0 a,(i2c_status)
	and 0x01
	jp z,i2c_check_bb_loop	#/BB = 0?

	## We should now be clear to send
	pop af
	ret

	## Checks the PIN flag on the bus.
	## Effectively a CTS? routine 
i2c_check_pin:
	push af
i2c_check_pin_loop:	
	in0 a,(i2c_status)
	and 0x80
	jp nz,i2c_check_pin_loop	#PIN = 0?

	## We should now be clear to send
	pop af
	ret
	
	## Initialises a transmit on the I2C lines
	## H - contains the device address to write to
i2c_start_xmit:
	push af

	ld a,h
	and 0xfe		#Mask off the lowest bit
	out0 (i2c_data),a
	
	call i2c_check_bb

	## Now tell the control to send a start packet
	ld a,0xC5
	out0 (i2c_cmd),a

	## The bus should now be running, were ok to exit
	pop af
	ret

	## Initialises a receive on the I2C lines
	## H - contains the recv address
i2c_start_recv:
	push af

	ld a,h
	or 0x01			#Make sure the R bit is set
	out0 (i2c_data),a	#Write the recv loc into S0

	call i2c_check_bb	#Wait for the bus to become clear

	## And send the start packet
	ld a,0xC5
	out0 (i2c_cmd),a

	## Bus running, exit routine
	pop af
	ret

	## Writes a byte onto the I2C bus.
	## A - contains the byte to write
i2c_write_byte:
	push af

	push af
i2c_w_loop:
	pop af
	in0 a,(i2c_status)
	push af

	and 0x80
	jp nz,i2c_w_loop

	pop af
	
	and 0x08
	jp nz,i2c_error #Error, break out

	pop af
	out0 (i2c_data),a
	
	ret
	
i2c_recv_byte:	
	ret

	## Marks the end of a transmission
i2c_xmit_end:
	push af

	ld a,0xC3
	out0 (i2c_cmd),a

	pop af	
	ret
	
i2c_recv_end:
	ret

i2c_error:
	di
	halt
