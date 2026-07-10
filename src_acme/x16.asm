;ACME
; =====================================================================
; x16lib :: x16.asm -- constants and macros. Emits no code.
; =====================================================================
; Source this near the top of your program, BEFORE any code, because
; ACME macros must be defined before they are called (unlike labels,
; which resolve on a later pass).
;
;       !cpu 65c02
;       !source "x16.asm"
;
;       *= $0801
;       +basic_stub
;       main
;           +vera_addr 0, VRAM_TEXT, VERA_INC_1
;           rts
;
;       !source "x16_code.asm"      ; library routines land here
;
; Assemble with the src/ directory on the include path:
;       acme -I src -f cbm -o OUT.PRG myprog.asm
; =====================================================================

!cpu 65c02

!source "core/const_zp.asm"
!source "core/const_vera.asm"
!source "core/const_kernal.asm"
!source "core/const_rom.asm"
!source "core/macros.asm"
