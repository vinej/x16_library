;vasm
; =====================================================================
; x16lib :: x16.asm -- constants and macros (vasm port). Emits no code.
; =====================================================================
; Source this near the top of your program, BEFORE any code, because
; vasm macros must be defined before they are called.
;
;       include "x16.asm"
;
;           org $0801
;           basic_stub
;       main
;           vera_addr 0, VRAM_TEXT, VERA_INC_1
;           rts
;
;       include "x16_code.asm"      ; library routines land here
;
; Assemble with vasm6502_oldstyle, 65C02 mode, src_vasm/ on the include
; path; -Fbin -cbm-prg writes the .prg (load address + image) directly:
;       vasm6502_oldstyle -c02 -Fbin -cbm-prg -I src_vasm -o OUT.PRG myprog.asm
; =====================================================================

    include "core/const_zp.asm"
    include "core/const_vera.asm"
    include "core/const_kernal.asm"
    include "core/const_rom.asm"
    include "core/macros.asm"
