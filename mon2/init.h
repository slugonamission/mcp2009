				;
/*
********************************

basic Initalisation code for the 
64180 monitor/sbc card

********************************
*/

init:				; head of the init foutine, 
				; hl holds the data for the
				; console/host channel of the
				; duart
	call	init_serial	; so we do this first
	call	init_lcd	; then the LCD
	call	init_i2c	; then the i2c interface
				; now any basic system variables
				;
	ret			; return to base code
				;
init_serial:			; set thei internal serial devices
				; up
				; hl holds the basic data
	ld	a,072h		;
	out0a(cntla0)
	out0a(cntla1)
	ld	a,000h		;
	out0a(cntlb0)
	out0a(cntlb1)
	ld	a,000h		;
	out0a(stat0)
	ld	a,004h
	out0a(stat1)
				;
	in0a(rdr0)
	in0a(rdr1)
	ret			; serial lines now setup
				;
init_lcd:			; set the LCD display up
	ld	de,lcd_data	; init code for the LCD
lcd_il1:			; init loop
	ld	a,(de)		; get a byte
	cp	0		; if zero end of table
	ret	z		;
	out	(csr_lcd),a	; write it to the lcd
	call	delay		; wait for the LCD
	call	delay		; wait for the LCD
	call	delay		; wait for the LCD
	inc	de		; move pointer up one
	jr	lcd_il1		; loop
				;
lcd_data:			; LCD setup data
        byte    38h,38h,38h,04h,06h,40h,01h,0ch,00h
				;
				;
				;
init_i2c:			; setup the I2C chip as a master
	ret			;
				;
;*******************************;
;	END of INIT CODE	;
