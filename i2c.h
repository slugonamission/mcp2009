#ifndef __I2C_H__
#define __I2C_H__

i2c_data=0xBC
i2c_cmd=0xBD
i2c_status=0xBD    ##Same address, this is just for semantic meaning

.globl i2c_init
.globl i2c_start_xmit
.globl i2c_start_recv
.globl i2c_write_byte
.globl i2c_recv_byte
.globl i2c_xmit_end
.globl i2c_recv_end

#endif
