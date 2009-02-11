asci_status_0=0x04
asci_ctrl_a_0=0x00
asci_tx_0=0x06
asci_rx_0=0x08

asci_status_1=0x05
asci_tx_1=0x07
asci_rx_1=0x09

maim:	ld sp,0xefff
top:	in0 a,(asci_status_1)
	and 0x80
	cp 0x80
	call z,echo
	jp top

echo:	in0 a,(asci_rx_1)
	call write
	ret
	
write:	ex af,af
write_1:
	in0 a,(asci_status_1)
	and 2
	cp 2
	jp nz, write_1
	ex af,af
	out0 (asci_tx_1), a
	ret
