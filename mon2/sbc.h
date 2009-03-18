/* definitions for the SBC built for Don Goodeve 1998 */
/* code started 13/2/98				      */

/* basic defines for the 8255 on SBC */
pa_8255		equ	0b0h	/* Port A on 8255 */
pb_8255		equ	0b1h	/* Port B on 8255 */
pc_8255		equ	0b2h	/* Port C on 8255 */
csr_8255	equ	0b3h	/* CSR on 8255    */

/* basic defines for the keyboard decoder on SBC */
kbdctrl		equ	0b4h	/* Port */

/* basic defines for the LCD on the SBC */
csr_lcd		equ	0b8h	/* CSR on LCD */
data_lcd	equ	0b9h	/* DATA register on LCD */

/* basic defines for the I2C interface on the SBC */
data_i2c	equ	0bch	/* DATA register on I2c chip */
csr_i2c		equ	0bdh	/* CSR on I2C */
