#ifndef __COMMON_H__
#define __COMMON_H__

	## Constants

nmi_callback=0xF24C
sp_loc=0xEFFF

item_count=30

	## Global exports
	.globl delay
  	.globl init
	.globl default_callback

	.globl int_table
	.globl INT1
	.globl INT2
	.globl PRT0
	.globl PRT1
 	.globl DMA0
	.globl DMA1
	.globl CSIO
	.globl ASCI0
	.globl ASCI1
#endif
