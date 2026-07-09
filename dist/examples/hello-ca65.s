; =====================================================================
; x16lib :: dist/examples/hello-ca65.s -- using the library from ca65
; =====================================================================
; Assemble and link (x16lib.inc and x16lib.bin come from dist.ps1):
;
;   ca65 --cpu 65C02 -I dist\ca65 --bin-include-dir dist ^
;        -o hello-ca65.o dist\examples\hello-ca65.s
;   ld65 -C dist\ca65\x16lib.cfg -o HELLO.PRG hello-ca65.o
;
; The library blob sits at $6800 (see X16LIB_ORG in x16lib.inc, and
; keep x16lib.cfg's LIB area in step); your program owns $0801-$67FF.
; The library claims zero page $22-$31 (X16_P0..X16_T7).
; =====================================================================

.setcpu "65C02"
.include "x16lib.inc"

.segment "LOADADDR"
        .word $0801             ; PRG load address

.segment "CODE"
        basic_stub              ; 10 SYS 2061

main:
        lda #<msg
        ldx #>msg
        jsr screen_puts         ; library routine, inside the blob

        lda #<1234              ; and some arithmetic: print 1234
        sta X16_P0
        lda #>1234
        sta X16_P1
        jsr u16_to_dec          ; A/X -> "1234", NUL-terminated
        jsr screen_puts

        lda #$0D
        jsr screen_chrout

        vpoke VRAM_TEXT + (4 * 128 * 2), $2A    ; a '*' on text row 4
        rts

msg:    .byte "HELLO FROM CA65! ", 0

.segment "X16LIB"
        .incbin "x16lib.bin"    ; found via --bin-include-dir dist
