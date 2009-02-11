#include "common.h"
#include "display_small.h"
#include "display.h"
#include "network.h"
#include "tilt.h"

init:	ld sp,sp_loc
top:
	## Init the small display
	call clear_small
	## Init the big display
	call disp_init
	call disp_clear_graphics
	call disp_clear_text
	call disp_text_mode
	call network_init
	ld b,22
	ld hl,loading
	call disp_write_seq

	ld b,6
	ld hl,hi
	call write_seq_small
	call network_recv_map

	call clear_small
	ld b,6
	ld hl,done
	call write_seq_small

	call disp_clear_text
	ld bc,0x0000
	call disp_set_adp
	call disp_graphics_mode

	ld hl,0xc000
	ld b,0xff
	call disp_write_b_seq
	ld b,0xff
	call disp_write_b_seq
	ld b,0xff
	call disp_write_b_seq
	ld b,0xff
	call disp_write_b_seq
	ld b,0x10
	call disp_write_b_seq
	halt

	## Messages
loading:
	"Please flip the switch"

done:	"Loaded"

hi:	"O HAI!"