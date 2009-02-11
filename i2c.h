#ifndef __I2C_H__
#define __I2C_H__

	i2c_data=0xBC
	## Well define 0xBD twice so it has some
	## semantic meaning in the program
	i2c_cmd=0xBD
	i2c_status=0xBD
	
	.globl i2c_init

#endif