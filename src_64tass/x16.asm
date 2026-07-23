; 64tass
; =====================================================================
; x16lib :: x16.asm -- constants and macros (64tass edition). No code.
; =====================================================================
; The 64tass port mirrors the ACME tree file for file; src_acme/ is
; the reference implementation and this tree must behave identically
; -- the same test suite proves it.
;
;       .include "x16.asm"
;       X16_USE_VERA = 1            ; pick modules or a section gate
;       * = $0801
;       ...your code...
;       .include "x16_code.asm"     ; library routines land here
;
; Assemble CASE-SENSITIVE, ASCII, CBM output:
;       64tass -C -a --cbm-prg -I src_64tass -o PROG.PRG prog.asm
;
; -C is not optional: the jsrfar macro and the KERNAL's JSRFAR entry
; differ only in case.
;
; Include each file once (the ACME tree's include guards have no
; 64tass equivalent and were dropped).
; =====================================================================

.cpu "65c02"

; 64tass's default "none" encoding converts ASCII to PETSCII ('H'
; becomes $C8). The library's strings are raw bytes -- define an
; identity encoding so .text and character literals emit the source
; bytes unchanged, exactly as ACME's !text does.
.enc "raw"
.cdef " ~", $20

.include "core/const_zp.asm"
.include "core/const_vera.asm"
.include "core/const_kernal.asm"
.include "core/const_rom.asm"
.include "core/macros.asm"
