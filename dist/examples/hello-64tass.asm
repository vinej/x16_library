; =====================================================================
; x16lib :: dist/examples/hello-64tass.asm -- using the library from
; 64tass
; =====================================================================
; Assemble (x16lib.inc and x16lib.bin come from dist.ps1):
;
;   64tass -C -a --cbm-prg -I dist -o HELLO.PRG dist\examples\hello-64tass.asm
;
; -C (case-sensitive symbols) is REQUIRED: the jsrfar macro and the
; KERNAL's JSRFAR constant differ only in case.
;
; The library blob sits at $8000; your program owns $0801-$7FFF.
; The library claims zero page $22-$31 (X16_P0..X16_T7).
; =====================================================================

        .cpu "65c02"

        ; 64tass's default "none" encoding converts ASCII to PETSCII,
        ; turning 'H' into $C8. Define an identity encoding so .text
        ; emits the bytes as written ($48), which is what CHROUT's
        ; upper/graphics mode expects.
        .enc "raw"
        .cdef " ~", $20

        .include "64tass/x16lib.inc"

* = $0801
        #basic_stub             ; 10 SYS 2061

main
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

        #vpoke VRAM_TEXT + (4 * 128 * 2), $2A   ; a '*' on text row 4
        rts

msg     .text "HELLO FROM 64TASS! ", 0

* = $8000
        .binary "x16lib.bin"
