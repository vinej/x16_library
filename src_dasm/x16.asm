;dasm
; =====================================================================
; x16lib :: x16.asm -- constants and macros (dasm port). Emits no code.
; =====================================================================
; Source this near the top of your program, BEFORE any code, because
; dasm macros must be defined before they are called.
;
;       processor 65c02
;       include "x16.asm"
;
;       org $0801
;       basic_stub
;   main
;       vera_addr 0, VRAM_TEXT, VERA_INC_1
;       rts
;
;       include "x16_code.asm"      ; library routines land here
;
; Assemble with src_dasm/ on the include path:
;       dasm myprog.asm -I src_dasm -f1 -o OUT.PRG
; =====================================================================

    include "core/const_zp.asm"
    include "core/const_vera.asm"
    include "core/const_kernal.asm"
    include "core/const_rom.asm"
    include "core/macros.asm"
