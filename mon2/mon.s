/* include basic board definitions */#include "64180.h"
#include "sbc.h"

/*
****************************************************************
*                   8080/8085 system monitor                   *
*--------------------------------------------------------------*
*  commands:                                                   *
*    b .................... enter resident basic interpreter.  *
*    d .................... download from terminal port.       *
*    h .................... Command Help		       *
*    g <adr> .............. go (execute) at address.           *
*    l .................... load memory from tape.             *
*    m <adr>,<adr> ........ display memory in hexidecimal.     *
*    r .................... reenter resident basic.            *
*    s <adr> [nn]-<byt> ... substute into memory.              *
*    t 'h' or 'f' ......... terminal emulation mode.           *
*    w <addr>,<addr> ...... write memory to tape.              *
****************************************************************
	
*
* constants and equates...
*

*/
#include "memdefs.h"		/* basic memory definitions shared with basic */

origin	equ	00000h		; set the base of the monitor ron
defio	equ	005h		; default i/o configuration
keybrd	equ	0		; keyboard input port
PBASIC	equ	01000h		; pointer to the basic rom
PRENTRY	equ	010a1h		; soft restart of basic
	
/* set the origin of the code */
	org	origin
/*
* start of monitor, first initialize the hardware
*/
main:	jp	start		; get out of the way of the vector table
	org	origin+00038h	; restart 7 vector
restart7:			; where restart7 comes to
	push	hl		; save user hl
	ld	hl,(rest7)	; read vector
	ex	(sp),hl		; swap it to stack
	ret			; and goto interupt
/* JUMP table for the monitor routines */
	jp	bin		; input
	jp	bout		; output
	jp	ctrlc		; control c handler
	jp	prnt		; abort (exit) routine
	jp	getr		; routine to load intel hex
	jp	dump		; dump a file
	jp	stub		; ton
	jp	stub		; toff
	jp	stub		; curpos
	jp	bspace		; put a space out
	jp	nl		; put a crlf out
	jp	pmsg		; print
	org	origin+00066h	; NMI vecotor 
nmi_rot:			; 
	push	hl		; save user hl
	ld	hl,(nmi)	; read vector
	ex	(sp),hl		; swap it to stack
	ret			; and goto interupt
start:	ld	sp,stack	; initalize stack
	ld	hl,lcd_out	; set the base user device to lcd
	ld	(usrout),hl	; to indicate it hasnt been set 
	ld	hl,PBASIC	; set the basic/rentry to stub
	ld	(basic),hl	;
	ld	hl,PRENTRY	; reentery vector
	ld	(rentry),hl	;
	ld	hl,stub		; set the restart7 and NMI vectors up
	ld	(rest7),hl	;
	ld	(nmi),hl	;
	ld	a,defio		; default i/o configuration
	or	008		; set the bit for user I/O
	ld	(iocon),a	; set i/o configuration
	ld	hl,07a37h	; usart 7 bits, no parity, high-speed
	call	init		; setup the basic system
	ld	hl,opener	; tell user who we are
	call	pmsg		;
	ld	a,defio		; reset the  defio not to have lcd
	ld	(iocon),a	; save it
	jp	prnt		; prompt for command
opener:				; opener message
	ascii	'64180 monitor   ver 1.SLUG'
	byte	00dh		;
stub:				; command stub, for basic
	ret			; 
/* gets double value for hl, de */
dget:	call	aget		; get first address
	ex	de,hl		; swap
	ld	a,','		; get seperator character
	call	bout		; display
/* gets two byte value for h-l */
aget:	call	gethl		; get hex value
	ret	c		; return if ok
/* indicate error with '?' on console */
error:	ld	a,'?'		; error message
	call	bout		; display it
/* recover from error, reset stack, shut tape off */
abort:	ld	sp,stack	; fix up stack
	call	nl		; new line on terminal
/* wait for command */
prnt:	ld	a,'*'		; prompt message
	call	bout		; display
	call	cmd_wait	; see which serial line the command comes
				; in on, and set the iocon byte apropeatly
	call	bin		; get character from terminal
	call	bout		; echo
	ld	b,a		; save for comparison
	call	bspace		; display separater
	ld	hl,ctab		; point to command table
clook:	ld	a,(hl)		; get cmd from table
	inc	hl		; point to next
	and	a		; test for end if table
	jp	z,error		; if so, indicate so
	ld	e,(hl)		; get low address
	inc	hl		; point to high
	ld	d,(hl)		; get high address
	inc	hl		; point to next
	cp	b		; test for entered command
	jp	nz,clook	; keep looking till we find
	ld	hl,abort	; address to return to
	push	hl		; save return address
	ex	de,hl		; swap to h-l
	jp	(hl)		; execute user code
ctab:	byte	'B'		; basic command?
	word	Gbasic		; address of basic interpreter
	byte	'R'		; test for 'reenter'
	word	Grentry		; reenter basic
	byte	'H'		; test for 'help'
	word	help		; print help screen to user
	byte	'L'		; test for 'load'
	word	load		; load from host
	byte	'G'		; test for 'go'
	word	go		; go execute
	byte	'S'		; test for 'sub'
	word	subst		; subst. memory
	byte	'W'		; test for 'write'
	word	dump		; dump some out
	byte	'M'		; test for 'm'
	word	memry		; memory code
	byte	'T'		; terminal mode???
	word	tmode		; if so, enter terminal
	byte	0		; indicate end of table

/*
* wait to see where a coommand comes from, called at the top of the 
* main command loop, result will be commands comming in from both
* serial ports, 
*/
cmd_wait:			;
	ld	a,(iocon)	; patch iocon to console
	and	0feh		; mask first bit
	ld	(iocon),a	;
	in0a(stat1)
	and 	080h		; test for a char in buffer
	ret	nz		; if so act on it
	jr	cmd_wait	; loop
/*
* links to basic, via a vector in memory
*/
Gbasic:
	ld	hl,(basic)	; get the vector
	jp	(hl)		;
Grentry:			;
	ld	hl,(rentry)	; get vector
	jp	(hl)		;
/*
* print user some help info
*/
help:				;
	ld	hl,help_mes	; message pointer
	call	pmsg		; print it
	ret			;
help_mes:			; message
	ascii	'Commands '	;
	ascii	'g,m,l,w,b,r'	;
	byte	00dh		;
/*
* display memory command
*/
memry:	call	dget		; get addresses
	ex	de,hl		; swap back
mloop:	call	nl		; start a new line
	call	hlout		; display address
ml1:	call	bspace		; display space
	ld	a,(hl)		; get contents
	call	hout		; display hex
	call	chlde		; test for end
	ret	nc		; if so, stop
	inc	hl		; next byte
	ld	a,l		; get low address
	and	00fh		; test for end of line
	jp	nz,ml1		; if not, keep going
	call	ctrlc		; test for user abort
	jp	nz,mloop	; if not, keep displaying
	ret
/*
* go command
*/
go:	call	aget		; get address to 'go' at
	jp	(hl)		; set program counter
/*
* substutute command
*/
subst:	call	aget		; get address
sub0:	call	nl		; start on a new line
	call	hlout		; display address
	ld	d,8		; eight bytes/line
sub1:	call	bspace		; skip a space
	ld	a,(hl)		; get contents
	call	hout		; display
	ld	a,'-'		; prompt with '-'
	call	bout		; display
	call	getbyt		; get byte
	jp	c,sub3		; if ok, substute
	cp	00dh		; test for abort
	ret	z		; if so, back for command
	call	bspace		; otherwise, print.
	call	bspace		; two spaces (same space as hex digits)
	ld	a,(hl)		; get old byte back
sub3:	ld	(hl),a		; replace memory contents
snxt:	inc	hl		; next location in memory
	dec	d		; reduce count of bytes/line
	jp	nz,sub1		; if ok, stay on same line
	jp	sub0		; otherwise go to new line
/*
* dump command
*/
dump:	call	dget		; get addresses
/* de=start address, h-l=end address */
dump1:	inc	hl		; advance by one byte
	ld	a,h		; test for special case
	and	a		; if zero page
	jp	z,lbot		; if so, special case
	push	hl		; save ending value
	ld	bc,0ff01h	; get value to subtract
	add	hl,bc		; subtract from ending address
	ex	de,hl		; swap back
drecl:	call	chlde		; see if we have finished yet
	jp	nc,lrec		; if so, last record
	ld	a,0ffh		; otherwise, record length is 255
	call	dumpr		; dump out record
	jp	drecl		; keep going till last record
lrec:	pop	de		; get addres back
	ex	de,hl		; swap
lbot:	push	de		; get address back
	ld	a,d		; take.
	cpl			; twos.
	ld	d,a		; complement.
	ld	a,e		; so we can.
	cpl			; subtract.
	ld	e,a		; from the
	inc	de		; origional address
	add	hl,de		; subtract
	ld	a,l		; get length
	pop	hl		; get address back
	call	dumpr		; dump last record
	sub	a		; end of file indicator
/*
* dumps a record in intel hex format
*/
dumpr:	ld	b,a		; save length in b
	ld	a,4		; set for uart output
	ld	(iocon),a	; set i/o conf
	call	nl		; display lf cr to tape
	ld	a,':'		; start of record
	call	bout		; write to tabe
	ld	a,b		; get length
	ld	c,a		; start checksum
	call	hout		; write length to tape
	ld	a,b		; get length back
	and	a		; test for end of file
	jp	z,endmp		; if so, stop
	call	hlout		; write address to tape
	ld	a,c		; get checksum
	add	a,h		; add high address
	add	a,l		; add low address
	ld	c,a		; resave checksum
	sub	a		; data type zero
	call	hout		; write to tape
mhex:	ld	a,(hl)		; get byte of data to dump
	call	hout		; write to tape
	ld	a,(hl)		; get data back
	add	a,c		; add to checksum
	ld	c,a		; resave checksum
	inc	hl		; next memory location
	dec	b		; reduce length
	jp	nz,mhex		; if not end, keep dumping
	cpl			; invert to make.
	inc	a		; twos complement checksum
	call	hout		; write checksum to tape
endmp:	ld	a,defio		; get default i/o conf
	ld	(iocon),a	; reset i/o configuration
	ret
/*
* compares h-l with d-e
*/
chlde:	ld	a,h		; get high if hl
	cp	d		; test with high of de
	ret	nz		; if not same, problem solved
	ld	a,l		; get low hl
	cp	e		; set flags for compare with low de
	ret
/* displays a space on the terminal */
bspace:	ld	a,' '		; get a space
	jp	bout		; display
/*
* displays 16 bit value of h-l on the terminal
*/
hlout:	ld	a,h		; get h
	call	hout		; display h in hex
	ld	a,l		; get l
/* displys 8 bit value of acc in hex */
hout:	push	af		; save low digit
	rrca			; make high.
	rrca			; digit.
	rrca			; into.
	rrca			; low digit.
	call	hxout		; print high digit
	pop	af		; get low digit back
hxout:	and	00fh		; get rid of excess baggage
	add	a,030h		; convert to ascii number
	cp	03ah		; test for alpha character
	jp	c,bout		; if not, we are ok
	add	a,7		; convert to character
/*
* output routine, displays contents of acc on all enabled
* output devices
*/
bout:	push	bc		; save b-c pair
	push	de		; save d-e pair
	push	hl		; save h-l pair
	ld	b,a		; save character in b
	ld	a,(iocon)	; get i/o configuration
	ld	c,a		; save in c
	and	040h		; test for output disabled
	jp	nz,oexit	; if so, abort
	ld	a,c		; get configuration back
	and	2		; test for video display enabled
	jp	z,ourt		; no, try uart
				; char in b, going to console port
console_out:			; loop
	in0a(stat0)
	and	002h		; get status and test
	cp	002h		;
	jr	nz,console_out	; loop till ready
	ld	a,b		; get char from b
	out0a(tdr0)
/* test for uart output */
ourt:	ld	a,c		; get i/o configuration
	and	4		; test for uart enabled
	jp	z,ousr		; if not, try user supplied routine
ulp1:	in0a(stat1)
				; get uart status
	and	002h		; test for xmit ready
	cp	002h		;
	jr	nz,ulp1		; if not, keep trying
	ld	a,b		; get character
	out0a(tdr1)
/* user suplied output device */
ousr:	ld	a,c		; get i/o configuration
	and	008h		; test for user device enabled
	jp	z,oexit		; if not, exit
	ld	hl,oexit	; address to return to
	push	hl		; save on stack
	ld	hl,(usrout)	; address to jump to
	jp	(hl)		; call his routine
lcd_out:			; basic plug for user output device
	ld	a,b		; get char back
	out	(data_lcd),a	; send it
	call	delay;		; wait for the delay time
	ret			;
oexit:	pop	hl		; restore h-l
	pop	de		; restore d-e
	ld	a,b		; character is in a
	pop	bc		; restore b-c
	ret
/*
* input routine, inputs from selected device
*/
bin:	push	bc		; save b-c pair
ins1:	ld	a,(iocon)	; get input/output configuration
	ld	b,a		; save copy in b for fast reference
	rrca			; test for input from keyboard
	jp	c,in_console	; if so, get character from kbd
/* read from uart */
uin:				; get uart status
	in0a(stat1)
	and	080h		; test for received character
	jr	z,uin		; if not, wait for it
				; get data from uart
	in0a(rdr1)
	jp	inend		; process
/* read from keyboard */
kbd:	in	a,(kbdctrl)	; get keyboard data
	jr	inend		; got key press goto end
in_console:			; read char from console tty
	in0a(stat0)
	and	080h		; get status and test
	jr	z,in_console	; loop till char
	in0a(rdr0)
				; we have char in acc, drop through
/* process character just read, according to defaults */
inend:	ld	c,a		; save character
	cp	3		; test for control-c
	ld	a,b		; get io configuration
	jp	z,ctlc		; if ctrl-c, special case
	and	010h		; test for upper case conversin
	ld	a,c		; get character back
	pop	bc		; restore b-c pair
	ret	nz		; if upper case disabled, then dont change
	cp	061h		; test for < lower case a
	ret	c		; if so,  then dont change
	cp	07bh		; test for > lower case z
	ret	nc		; if so, dont change
	and	05fh		; convert to upper case
	ret
/* control-c, dont pass on if ctrl-c is disabled */
ctlc:	and	020h		; test for control-c disabled
	jp	nz,ins1		; if so, get next character
	ld	a,c		; get character back
	pop	bc		; restore b-c
	ret
/*
* test for ctrl-c from keyboard. also, if line-feed is pressed,
* then wait till it is released
*/
ctrlc:	 
	in0a(stat0)
	xor	080h		; see if there is a char in the input buffer
	ret	m		; ditch the zero strobe
	in0a(rdr0)
	and	07fh		; get char and test
	cp	3		; test for control-c
	ret	nz		; if not, dont process
	ld	a,(iocon)	; get i/o configuration
	and	020h		; test for control-c inhibit. (z=0 if not)
	ret

/* gets a 16 bit value for h-l, cy=1 if everything ok */
gethl:	call	getbyt		; get first byte
	ret	nc		; if bad, dont wait for second
	ld	h,a		; save in high byte of result
	call	getbyt		; get second byte
	ld	l,a		; save in low byte of result
	ret
/* gets a byte for acc from terminal, cy=0 if fails */
getbyt:	push	bc		; save b-c pair
	call	getnib		; geet first nibble
	jp	nc,retgb		; if bad, dont wait for more
	rlca			; shift into.
	rlca			; upper nibble.
	rlca			; of result.
	rlca			; so we can insert lower nibble
	ld	b,a		; keep high digit in b
	call	getnib		; get second digit
	jp	nc,retgb		; if bad, indicate so
	or	b		; insert high digit
	scf			; indicate sucess
retgb:	pop	bc		; restore b-c pair
	ret
/* gets a nibble from the terminal (in ascii hex) */
getnib:	call	bin		; get a character
	cp	' '		; test for blank (abort1)
	ret	z		; if so, return indicating bad (cy=0)
	cp	00dh		; test for <cr> (abort2)
	ret	z		; if so, return indicating bad
	cp	'0'		; test for invalid (below 0)
	jp	c,getnib		; if so, wait for more
	cp	'G'		; test for invalid (greater than f)
	jp	nc,getnib		; if so, ignore
	call	bout		; display character
	cp	03ah		; test for invalid
	jp	c,numh		; if ok, we are in
	cp	'A'		; test for invalid
	jp	c,getnib		; if bad, ignore
	sub	7		; convert to digit
numh:	sub	030h		; convert to binary
	scf			; indicate sucess
	ret
/* loads a record in intel hex format */
getr:	ld	a,042h		; inhibit output, enable uart
	ld	(iocon),a	; set i/o conf
	
get1:	call	bin		; get character from tape
	cp	':'		; test for start of record
	jp	nz,get1		; if not, ignore
	
	call	getbyt		; get length
	and	a		; test for end of file
	jp	z,rset		; if so, process
	ld	c,a		; start checksum
	ld	b,a		; remebmer length
	call	gethl		; get address
	ld	a,c		; get checksum
	add	a,h		; add high byte of address
	add	a,l		; add low byte of address
	ld	c,a		; resave checksum
	call	getbyt		; get type byte
	add	a,c		; add to checksum
	ld	c,a		; resave checksum
neor:	call	getbyt		; get data byte
	ld	(hl),a		; save in memory
	inc	hl		; point to next location
	add	a,c		; add to checksum
	ld	c,a		; resave checksum
	dec	b		; reduce count of remaining data bytes
	jp	nz,neor		; if more, keep loading
	call	getbyt		; get checksum. (from tape)
	add	a,c		; add to computed checksum
	jp	z,eipl		; if ok, end this record
	call	rset		; clear flags
	ld	hl,errmsg	; address of ?i/o error message
	call	pmsg		; print message
	and	a		; indicate end of load
	ret
/* indicate end of record, more data to follow (cy=1) */
eipl:	call	rset		; reset default i/0
	scf			; indicate more data
	ret
/* reset i/o configuration */
rset:	ld	a,defio		; set to default i/o
	ld	(iocon),a	; save in i/o conf
	and	a		; indicate done
	ret
errmsg:	ascii	'?i/o error'	; error message
	byte	00dh
/* displays message on display up to a carriage-return. or zero */
pmsg:	ld	a,(hl)		; get character from message
	and	a		; end of message?
	ret	z		; if so, return
	call	bout		; display it
	inc	hl		; point to next char. in message
	cp	00dh		; test for carriage return
	jp	nz,pmsg		; if not, keep displaying
/* displays a line-feed, carriage-return pair on the video display */
nl:	ld	a,00ah		; get line-feed
	call	bout		; display
	ld	a,00dh		; get carriage return
	jp	bout		; display and return
/* load command */
load:				;
	ld	d,0ffh		; set number of records dumped to 255
	call	nl		; advance to a new line
lodlp:	inc	d		; advance number of records dumped
	ld	a,d		; get number of records dumped
	call	hout		; display on terminal
	call	getr		; get next record
	ret	nc		; if end, get next command
	ld	a,00dh		; get carriage return
	call	bout		; back up to start of line
	jp	lodlp		; get next record
/* delay, waits a finite time interval */
delay:	push	hl		; save h-l
	ld	h,0		; start counting from zero
del1:	dec	hl		; reduce count
	ld	a,h		; get high value
	or	l		; test for zero with low value
	jp	nz,del1		; if not, keep counting
	pop	hl		; restore h-l
	ret

/*
* terminal mode.... pass-through, console port to host port
* 		    ignore the iocon byte, as it dosn't matter
*/
tmode:
	ld	hl,host_mes	; tell user what we are doing
	call	pmsg		; print it
	ld	b,00dh		; wake host up
	call	con_hL		; send it
	ccf			; clear the carry flag
tmode_loop:			; loop point
	in0a(stat0)
	and	080h		; see if thete is a char in the console
				; receive buffer
	call	nz,con_host	; get char and send to host
	ret	c		; return to system loop
	in0a(stat1)
	and	080h		; now test the host buffer
	call	nz,host_con	;
	ret	c		; return to system loop
	jr	tmode_loop	; loop till done
				;
con_host:			; char in console buffer, to goto host	
	in0a(rdr0)
	push	af
	pop	af
	cp	01ch		;
	jr	z,host_end	; get out
	ld	b,a		; get char, and test for exit
con_hL:				; loop point
	in0a(stat1)
	and	002h		; test for clear tx buffer
	cp	002h		;
	jr	nz,con_hL	; loop till clear
	ld	a,b		; get char back from b
	out0a(tdr1)
	ret			;
host_con:			; char in host buffer, to goto console
	in0a(rdr1)
	cp	01ch		;
	jr	z,host_end	; get out
	ld	b,a		; get char, and test for exit
host_cL:			; loop point
	in0a(stat0)
	and	002h		; test for clear tx buffer
	cp	002h		;
	jr	nz,host_cL	; loop till clear
	ld	a,b		; get char back from b
	out0a(tdr0)
	ret			; ret
host_end:			; get out of here
	scf			; set the carry flag
	ret			;
host_mes:			; tell user what is happning
	ascii	'Transparant Mode, ctrl-\ to exit'
	byte	00dh		;
#include "init.h"		/* include the basic system init code */
