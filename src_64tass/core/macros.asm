; 64tass
; =====================================================================
; x16lib :: core/macros.asm -- inlined plumbing (64tass edition)
; =====================================================================
; The same macro layer the dist bindings carry
; (dist/templates/64tass-macros.inc). Invoke with '#'.
; =====================================================================

; ---------------------------------------------------------------------
; x16lib macro layer, hand-ported from src/core/macros.asm for 64tass.
;
; Requires the 65C02 instruction set (trb/tsb):
;       .cpu "65c02"
;
; IMPORTANT: assemble with case-sensitive symbols (64tass -C). The
; jsrfar MACRO wraps the KERNAL's JSRFAR entry point CONSTANT, and the
; two names differ only in case.
;
; Invoke macros with '#':   #vera_addr 0, VRAM_TEXT, VERA_INC_1
; ---------------------------------------------------------------------

; select which data port the ADDR registers refer to (clobbers A).
; ADDRSEL is bit 0 of CTRL; a read-modify-write via trb/tsb keeps DCSEL.
vera_addrsel .macro port
        lda #VERA_CTRL_ADDRSEL
        .if \port == 0
        trb VERA_CTRL
        .else
        tsb VERA_CTRL
        .endif
        .endm

; select the $9F29-$9F2C register bank (0-63). Preserves ADDRSEL.
; Never writes bit 7 (that resets VERA).
vera_dcsel .macro n
        .cerror \n > 63, "DCSEL must be 0-63"
        lda VERA_CTRL
        and #VERA_CTRL_ADDRSEL
        ora #(\n << 1)
        sta VERA_CTRL
        .endm

; point a data port at a 17-bit VRAM address. `inc` is an INDEX, not a
; byte count -- use the VERA_INC_* constants.
vera_addr .macro port, addr, inc
        .cerror \addr > $1FFFF, "VRAM address must be 17-bit"
        .cerror \inc > 15, "use a VERA_INC_* constant, not a byte count"
        #vera_addrsel \port
        lda #<(\addr)
        sta VERA_ADDR_L
        lda #>(\addr)
        sta VERA_ADDR_M
        lda #(((\addr >> 16) & $01) | (\inc << 4))
        sta VERA_ADDR_H
        .endm

; the same, but decrementing.
vera_addr_decr .macro port, addr, inc
        #vera_addrsel \port
        lda #<(\addr)
        sta VERA_ADDR_L
        lda #>(\addr)
        sta VERA_ADDR_M
        lda #(((\addr >> 16) & $01) | VERA_ADDR_H_DECR | (\inc << 4))
        sta VERA_ADDR_H
        .endm

; one-off VRAM byte write. Clobbers A, flags.
vpoke .macro addr, value
        #vera_addr 0, \addr, VERA_INC_0
        lda #\value
        sta VERA_DATA0
        .endm

set_rambank .macro n
        lda #\n
        sta RAM_BANK
        .endm

set_rombank .macro n
        lda #\n
        sta ROM_BANK
        .endm

; call a routine in another ROM/RAM bank via the KERNAL's own $FF6E
; mechanism. Preserves A/X/Y and flags, reentrant. Do NOT hand-roll
; the bank switch -- see src/core/macros.asm for why.
jsrfar .macro addr, bank
        jsr JSRFAR
        .word \addr
        .byte \bank
        .endm

; ~40 cycles cheaper than jsrfar, but CLOBBERS A and leaves ROM_BANK
; set to `bank`. Not IRQ-safe.
rom_call_fast .macro bank, entry
        lda #\bank
        sta ROM_BANK
        jsr \entry
        .endm

; load a 16-bit literal into a 2-byte little-endian buffer (i16_a etc.)
i16_const .macro dest, value
        lda #<(\value)
        sta \dest
        lda #>(\value)
        sta \dest+1
        .endm

; load a 32-bit literal into a 4-byte little-endian buffer (i32_a etc.)
i32_const .macro dest, value
        lda #<(\value)
        sta \dest
        lda #>(\value)
        sta \dest+1
        lda #((\value >> 16) & $FF)
        sta \dest+2
        lda #((\value >> 24) & $FF)
        sta \dest+3
        .endm

; emit `10 SYS 2061` so the PRG autoruns. Must land at exactly $0801;
; machine code then begins at $080D (= 2061).
basic_stub .macro
        .word $080B             ; link to the end-of-program marker
        .word 10                ; line number
        .byte $9E               ; SYS token
        .text "2061"            ; = $080D
        .byte $00               ; end of line
        .word $0000             ; end of program
        .endm
