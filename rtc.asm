#include "rtc.h"
#include "common.h"
	
rtc_init:
	## Basically, we just need to init the vector table and initialise the variable
	push af
	push hl

	## We need to patch into NMI. The monitor automatically jumps to (0xF24C) for us
	ld hl,rtc_isr
	ld (nmi_callback),hl

	call rtc_stop
	call rtc_reset
	
	pop hl
	pop af
	
	ret
	
	## Sets a callback for when the clock ticks
	## Vars: HL - the callback procedure address
rtc_set_callback:
	ld (rtc_callback),hl
	ret

	## Set the RTC to the running state
rtc_start:
	push hl
	## Big hack. Load the first 2 bytes with nop so it doesnt return
	ld hl,0x0000
	ld (rtc_isr),hl
	pop hl
	ret
	
rtc_stop:
	push hl
	## Big hack, load the first 2 bytes with retn to jump back out of the NMI routine
	ld hl,0x45ED
	ld (rtc_isr),hl
	pop hl
	ret
	
rtc_reset:
	push hl
	ld hl,0x0000
	ld (rtc_count),hl
	pop hl
	ret
	
	## ----------------------------------------------------------------------------
	## VARS
	## ----------------------------------------------------------------------------
rtc_count:
	.int 0x0000

	## The callback that can be overridden from the actual program
	## HL will contain the current counter value!
rtc_callback:
	.int default_callback
	
	## ---------------------------------------------------------------------------
	## RTC ISR
	## ---------------------------------------------------------------------------

rtc_isr:
	retn
	push af
	push hl
		
	## Ok, were running, carry on
	## Increment the actual counter
	ld hl,(rtc_count)
	inc hl
	ld (rtc_count),hl

	## Play with the stack pointer a bit to get the correct return
	## address for the callback
	ld hl,rtc_isr_end
	push hl
	ld hl,(rtc_callback)
	## Call the callback
	jp (hl)
	
rtc_isr_end:
	pop hl
	pop af

	retn
