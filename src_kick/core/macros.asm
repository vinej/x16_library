// KickAssembler
#importonce
// --------------------------------------------------------------------
// x16lib macro layer, hand-ported from src/core/macros.asm for
// KickAssembler (5.x).
//
// Requires the 65C02 instruction set (trb/tsb):
//      .cpu _65c02
//
// PETSCII note: put `.encoding "ascii"` at the top of your program if
// you print .text strings through CHROUT, so 'H' emits $48.
//
// Invoke like functions:   vera_addr(0, VRAM_TEXT, VERA_INC_1)
// --------------------------------------------------------------------

// select which data port the ADDR registers refer to (clobbers A).
// ADDRSEL is bit 0 of CTRL; a read-modify-write via trb/tsb keeps DCSEL.
.macro vera_addrsel(port) {
        lda #VERA_CTRL_ADDRSEL
        .if (port == 0) {
        trb VERA_CTRL
        } else {
        tsb VERA_CTRL
        }
}

// select the $9F29-$9F2C register bank (0-63). Preserves ADDRSEL.
// Never writes bit 7 (that resets VERA).
.macro vera_dcsel(n) {
        .errorif (n > 63), "DCSEL must be 0-63"
        lda VERA_CTRL
        and #VERA_CTRL_ADDRSEL
        ora #(n << 1)
        sta VERA_CTRL
}

// point a data port at a 17-bit VRAM address. `inc` is an INDEX, not a
// byte count -- use the VERA_INC_* constants.
.macro vera_addr(port, addr, inc) {
        .errorif (addr > $1FFFF), "VRAM address must be 17-bit"
        .errorif (inc > 15), "use a VERA_INC_* constant, not a byte count"
        vera_addrsel(port)
        lda #<addr
        sta VERA_ADDR_L
        lda #>addr
        sta VERA_ADDR_M
        lda #(((addr >> 16) & $01) | (inc << 4))
        sta VERA_ADDR_H
}

// the same, but decrementing.
.macro vera_addr_decr(port, addr, inc) {
        vera_addrsel(port)
        lda #<addr
        sta VERA_ADDR_L
        lda #>addr
        sta VERA_ADDR_M
        lda #(((addr >> 16) & $01) | VERA_ADDR_H_DECR | (inc << 4))
        sta VERA_ADDR_H
}

// one-off VRAM byte write. Clobbers A, flags.
.macro vpoke(addr, value) {
        vera_addr(0, addr, VERA_INC_0)
        lda #value
        sta VERA_DATA0
}

.macro set_rambank(n) {
        lda #n
        sta RAM_BANK
}

.macro set_rombank(n) {
        lda #n
        sta ROM_BANK
}

// call a routine in another ROM/RAM bank via the KERNAL's own $FF6E
// mechanism. Preserves A/X/Y and flags, reentrant. Do NOT hand-roll
// the bank switch -- see src/core/macros.asm for why.
.macro jsrfar(addr, bank) {
        jsr JSRFAR
        .word addr
        .byte bank
}

// ~40 cycles cheaper than jsrfar, but CLOBBERS A and leaves ROM_BANK
// set to `bank`. Not IRQ-safe.
.macro rom_call_fast(bank, entry) {
        lda #bank
        sta ROM_BANK
        jsr entry
}

// load a 16-bit literal into a 2-byte little-endian buffer (i16_a etc.)
.macro i16_const(dest, value) {
        lda #<value
        sta dest
        lda #>value
        sta dest+1
}

// load a 32-bit literal into a 4-byte little-endian buffer (i32_a etc.)
.macro i32_const(dest, value) {
        lda #<value
        sta dest
        lda #>value
        sta dest+1
        lda #((value >> 16) & $FF)
        sta dest+2
        lda #((value >> 24) & $FF)
        sta dest+3
}

// emit `10 SYS 2061` so the PRG autoruns. Must land at exactly $0801;
// machine code then begins at $080D (= 2061).
.macro basic_stub() {
        .word $080B             // link to the end-of-program marker
        .word 10                // line number
        .byte $9E               // SYS token
        .text "2061"            // = $080D
        .byte $00               // end of line
        .word $0000             // end of program
}

