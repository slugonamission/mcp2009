
/* internal io definitions */
#define cntla0 00h
#define cntla1 01h
#define cntlb0 02h
#define cntlb1 03h
#define stat0 04h
#define stat1 05h
#define tdr0 06h
#define tdr1 07h
#define rdr0 08h
#define rdr1 09h
#define cntr 0ah
#define trdr 0bh
#define tmdr0l 0ch
#define tmdr0h 0dh
#define rldr0l 0eh
#define rldr0h 0fh
#define tcr 10h
#define tmdr1l 14h
#define tmdr1h 15h
#define rldr1l 16h
#define rldr1h 17h
#define frc 18h
#define sarol 20h
#define saroh 21h
#define sarob 22h
#define darol 23h
#define daroh 24h
#define darob 25h
#define bcrol 26h
#define bcroh 27h
#define mar1l 28h
#define mar1h 29h
#define mar1b 2ah
#define iar1l 2bh
#define iar1h 2ch
#define bcr1l 2eh
#define bcr1h 2fh
#define dstat 30h
#define dmode 31h
#define dcntl 32h
#define il 33h
#define itc 34h
#define rcr 36h
#define cbr 38h
#define bbr 39h
#define cbar 3ah
#define icr 3fh




/* opcode extensions for the 64180 */

#define out0a(a) BYTE 0edh,39h,a /* outo <----------- */
#define out0b(a) BYTE 0edh,1h,a /* outo b <----------- */
#define out0c(a) BYTE 0edh,9h,a /* outo c <----------- */
#define out0d(a) BYTE 0edh,11h,a /* outo d <----------- */
#define out0e(a) BYTE 0edh,19h,a /* outo e <----------- */
#define out0h(a) BYTE 0edh,21h,a /* outo h <----------- */
#define out0l(a) BYTE 0edh,29h,a /* outo l <----------- */
#define in0a(a) BYTE 0edh,38h,a /* ino <----------- */
#define in0b(a) BYTE 0edh,0h,a /* in0 b <----------- */
#define in0c(a) BYTE 0edh,8h,a /* in0 c <----------- */
#define in0d(a) BYTE 0edh,10h,a /* in0 d <----------- */
#define in0e(a) BYTE 0edh,18h,a /* in0 e <----------- */
#define in0h(a) BYTE 0edh,20h,a /* in0 h <----------- */
#define in0l(a) BYTE 0edh,28h,a /* in0 l <----------- */
#define multhl BYTE 0edh,6ch /* mult hl <----------- */
#define multde BYTE 0edh,5ch /* mult de <----------- */
#define multbc BYTE 0edh,4ch /* mult bc <----------- */
#define multsp BYTE 0edh,7ch /* mult sp <----------- */
