#ifndef __NETWORK_H__
#define __NETWORK_H__

##Global definitions
asci_ctrl_a_0=0x00
asci_ctrl_b_0=0x02
asci_stat_0=0x04
asci_xmit_0=0x06
asci_recv_0=0x08

asci_ctrl_a_1=0x01
asci_ctrl_b_1=0x03
asci_stat_1=0x05
asci_xmit_1=0x07
asci_recv_1=0x09

mcp_packet_start=0x55
mcp_packet_end=0x0D
mcp_map_loc=0xBFF0 ##Row 0 is a test row - ignore it
mcp_map_rows=65

item_space=256

##Global exports
.globl network_init
.globl network_recv_map
.globl network_recv_byte
.globl network_enable_recv_int
.globl network_disable_recv_int
.globl network_set_end_callback
.globl network_recv_buffer
.globl network_item_count
.globl network_bytes_total
#endif
