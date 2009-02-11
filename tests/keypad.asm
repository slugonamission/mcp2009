	keypad_data=0xB4
	disp_data=0xB9
	disp_control=0xB8

main:	ld sp,0xefff
	ld bc,int_table
	out0 (0x33),c	
	ld a,b
	ld i,a

	ld a,0x04
	out0 (0x34),a

	ld a,0x01
	out0 (disp_control),a
	ld l,0xFF
	call delay
	

loop:   ld l,0x50
	call delay

	
	nop
	ei
	nop
	di
	jp loop

delay:	push hl
	ld h,0
del1:	dec hl
	ld a,h
	or l
	jp nz,del1
	pop hl
	ret


	
	
.align 5
int_table:
	.int 0
INT2:	.int KBD_ISR
	.int 0
	.int 0
	.int 0
	.int 0
	.int 0
	.int 0
	.int 0

KBD_ISR:
	di
	push hl
	in0 a,(keypad_data)
	cpl
	and 0x0f
	ld hl,lookup
	ld b,0
	ld c,a
	add hl, bc
	ld a,(hl)
	out0 (disp_data),a
	ld l,0x01
	call delay
	ld hl,KBD_RLS
	ld (INT2),hl
	pop hl

	## Change the ISR

	
	reti

KBD_RLS:
	push hl
	ld a,(kbdcount)
	dec a
	ld (kbdcount),a
	jp nz,kbdrlsret
	ld hl,KBD_ISR
	ld (INT2),hl
	ld a, 0xFF
	ld (kbdcount),a
kbdrlsret:
	pop hl
	reti
	

lookup:	.byte '1','2','3','A','4','5','6','B','7','8','9','C','0','F','E','D'
kbdcount: .byte 0xFF
