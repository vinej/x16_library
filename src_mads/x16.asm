; MADS
; =====================================================================
; x16lib :: x16.asm -- constants and macros (MADS edition). No code.
; =====================================================================
; The MADS port of the library mirrors the ACME tree file for file;
; src_acme/ is the reference implementation and this tree must behave
; identically -- the same test suite proves it, assembling to a
; byte-identical PRG.
;
;       icl "x16.asm"
;       X16_USE_VERA = 1            ; pick modules or a section gate
;       org $0801
;       ...your code...
;       icl "x16_code.asm"         ; library routines land here
;
; Assemble (MADS has no linker -- like ACME it writes bytes directly;
; build_mads.ps1 prepends the CBM load address to the raw output):
;       mads prog.asm -c -i:src_mads -o:PROG.PRG
;
; opt c+ turns on the 65C02 opcodes the VERA macros use (trb/tsb/stz/
; bra/phx/...). opt h- drops the Atari segment header so the output is
; a flat image; the build script adds the two-byte $0801 load address.
; =====================================================================

    opt h-
    opt c+

    icl "core/const_zp.asm"
    icl "core/const_vera.asm"
    icl "core/const_kernal.asm"
    icl "core/const_rom.asm"
    icl "core/macros.asm"
