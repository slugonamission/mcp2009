/* basic defines for the system monitor */
bin     EQU     0003eh          ; INPUT ROUTINE ADDRESS
bout    EQU     00041h          ; OUTPUT ROUTINE ADDRESS
ctrlc   EQU     00044h          ; CONTROL-C TEST ROUTINE ADDRESS
exit    EQU     00047h          ; TERMINATION RETURN ADDRESS
getr    EQU     0004ah          ; ROUTINE TO LOAD INTEL HEX FORMAT
tdump   EQU     0004dh          ; ROUTINE TO DUMP IN INTEL HEX FORMAT
hout	EQU	0022eh		; output a digit in hex
hlout	EQU	00229h		; output hl as a string to screen
ton     EQU     00050h          ; ROUTINE TO START TAPE
toff    EQU     00053h          ; ROUTINE TO STOP TAPE
curpos  EQU     00056h          ; ROUTINE TO POSITION CURSOR
bspace  EQU     00059h          ; DISPLAY SPACE ON CONSOLE
bnl     EQU     0005ch          ; ROUTINE TO PRINT A <LF>, <CR> ON TERMINAL
pmsg    EQU     0005fh          ; DISPLAYS MSG(HL) UP TO ZERO OR <CR>

