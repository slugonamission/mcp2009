	## Were going to hack up the monitor program a bit here
	## Set the data rate to 19200 baud
	ld a,0x01
	out0 (0x03),a
	ret
