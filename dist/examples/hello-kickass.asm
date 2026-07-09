// ====================================================================
// x16lib :: dist/examples/hello-kickass.asm -- using the library from
// KickAssembler
// ====================================================================
// Assemble (x16lib.inc and x16lib.bin come from dist.ps1):
//
//   java -jar KickAss.jar dist\examples\hello-kickass.asm -o HELLO.PRG
//
// The library blob sits at $8000; your program owns $0801-$7FFF.
// The library claims zero page $22-$31 (X16_P0..X16_T7).
// ====================================================================

.cpu _65c02
.encoding "ascii"               // CHROUT wants raw PETSCII/ASCII bytes
#import "../kickass/x16lib.inc"

.pc = $0801 "basic stub"
        basic_stub()            // 10 SYS 2061

main:
        lda #<msg
        ldx #>msg
        jsr screen_puts         // library routine, inside the blob

        lda #<1234              // and some arithmetic: print 1234
        sta X16_P0
        lda #>1234
        sta X16_P1
        jsr u16_to_dec          // A/X -> "1234", NUL-terminated
        jsr screen_puts

        lda #$0D
        jsr screen_chrout

        vpoke(VRAM_TEXT + (4 * 128 * 2), $2A)   // a '*' on text row 4
        rts

msg:    .byte 'H','E','L','L','O',' ','F','R','O','M',' ','K','I','C','K','A','S','S','!',' ',0

.pc = $8000 "x16lib blob"
.var x16libData = LoadBinary("../x16lib.bin")
.fill x16libData.getSize(), x16libData.get(i)
