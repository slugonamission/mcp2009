asci_status_0=0x04
asci_ctrl_a_0=0x00
asci_tx_0=0x06
asci_rx_0=0x08

asci_status_1=0x05
asci_tx_1=0x07
asci_rx_1=0x09

main:	ld sp,0xefff
	ld hl,hello
	ld b,12
	call write_seq
	jp loop

write:	ex af,af
write_1:
	in0 a,(asci_status_1)
	and 2
	cp 2
	jp nz, write_1
	ex af,af
	out0 (asci_tx_1), a
	ret
	
write_seq:
	ex af,af
write_seq_loop:
	ld a,b
	cp 0
	jp z, write_seq_end
	dec a
	ld b,a
	ld a,(hl)
	call write
	inc hl
	jp write_seq_loop

write_seq_end:
	ex af,af
	ret
	
loop:	halt

hello:
	.byte 'H','e','l','l','o',' ','W','o','r','l','d','!'
