#ifndef __DISPLAY_SMALL_ASM__
#define __DISPLAY_SMALL_ASM__

s_disp_data=0xb9
s_disp_command=0xb8
s_line_2_offset=0x40

	## Global operations
	.globl clear_small
        .globl set_adp_small
	.globl write_small
	.globl write_seq_small

#endif
