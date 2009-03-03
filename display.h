#ifndef __DISPLAY_H__
#define __DISPLAY_H__

##Constants
disp_data=0xF0
disp_cmd=0xF1

disp_gfx_home=0x0000
disp_text_home=0x0400

##Exports
.globl disp_init
.globl disp_set_adp
.globl disp_clear_text
.globl disp_clear_graphics
.globl disp_write_char
.globl disp_write_byte
.globl disp_write_seq
.globl disp_text_mode
.globl disp_graphics_mode
.globl disp_write_b_seq
.globl clear_to_send

#endif
