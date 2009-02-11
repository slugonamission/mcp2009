#include "i2c.h"

i2c_init:
	push af
	## Set the control register so we can set S0'' next
	ld a,0x80
	out0 (i2c_cmd),a

	ld a,0x80
	out0 (i2c_data),a	#Load 0x80 into S0'' (i.e. own addr 0xAA, it is shifted)

	## Set the clock frequency
	ld a,0xA0
	out0 (i2c_cmd),a
	ld a,0x14		#6Mhz input clock, 90kHz operating freq
	out0 (i2c_data),a

	## We should be done and ready to send now
	
	pop af
	ret

	## Transmits data to the I2C bus
	## Params:
	## h - the address to send to
	## a - the data to send
i2c_xmit:
	push af
i2c_xmit_start:
	## First, check the bus isnt busy
	in0 a,(i2c_status)
	and 0x01
	cp 0x01
	jp nz,i2c_xmit_start

	## Ok, were ready to go
	## Transmit the address
	ld a,h
	out0 (i2c_data),a

	## Now we need to set up the control register
	ld a,0xC5
	out0 (i2c_cmd),a

i2c_xmit_stat_check:	
	## Now we can send the data bit
	## Check the status bits
	in0 a,(i2c_status)
	and 0x88
	cp 0x08
	jp nz,i2c_xmit_stat_check

	## WERE CLEAR TO SEND AT LAST!!!!!!!!11111oneone!!!
	pop af
	out0 (i2c_data),a

	## Now wait until we get the ACK bits back
i2c_xmit_outer_stat:
	in0 a,(i2c_status)
	and 0x88
	cp 0x08
	jp nz,i2c_xmit_outer_stat

	## Transmit the stop bit
	ld a,0xC3
	out0 (i2c_cmd),a

	## And now, I think were done!
	
	ret
