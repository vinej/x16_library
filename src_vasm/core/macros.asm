;vasm
; =====================================================================
; x16lib :: core/macros.asm -- inlined plumbing (vasm port)
; =====================================================================
; vasm oldstyle port of the ACME macro layer. vasm macros take
; positional parameters (\1, \2, ...) rather than ACME's named `.param`,
; and use macro/endm with if/else/endif. ACME's `^` bank-byte operator
; becomes `>> 16`; its `>>>` logical shift becomes `>>` (`<` then takes
; the low byte either way). ACME's compile-time !error asserts are
; dropped -- the callers here pass valid arguments.
;
; Requires 65C02 mode (-c02 on the command line: trb/tsb).
; =====================================================================

    ifndef X16_MACROS
X16_MACROS = 1

; ---------------------------------------------------------------------
; vera_addrsel port      select which data port the ADDR registers refer
;                        to (ADDRSEL is bit 0 of CTRL). trb/tsb preserve
;                        DCSEL (bits 6:1).
; ---------------------------------------------------------------------
    macro vera_addrsel
    lda #VERA_CTRL_ADDRSEL
    if \1 = 0
    trb VERA_CTRL               ; clear bit 0
    else
    tsb VERA_CTRL               ; set bit 0
    endif
    endm

; ---------------------------------------------------------------------
; vera_dcsel n           select the $9F29-$9F2C register bank (0-63).
;                        Preserves ADDRSEL. Never writes bit 7.
; ---------------------------------------------------------------------
    macro vera_dcsel
    lda VERA_CTRL
    and #VERA_CTRL_ADDRSEL
    ora #((\1) << 1)
    sta VERA_CTRL
    endm

; ---------------------------------------------------------------------
; vera_addr port, addr, inc     point a data port at a 17-bit VRAM
;                               address. `inc` is a VERA_INC_* index.
; ---------------------------------------------------------------------
    macro vera_addr
    vera_addrsel \1
    lda #<(\2)
    sta VERA_ADDR_L
    lda #>(\2)
    sta VERA_ADDR_M
    lda #((((\2) >> 16) & VERA_ADDR_H_BANK) | ((\3) << 4))
    sta VERA_ADDR_H
    endm

; Same, but decrementing.
    macro vera_addr_decr
    vera_addrsel \1
    lda #<(\2)
    sta VERA_ADDR_L
    lda #>(\2)
    sta VERA_ADDR_M
    lda #((((\2) >> 16) & VERA_ADDR_H_BANK) | VERA_ADDR_H_DECR | ((\3) << 4))
    sta VERA_ADDR_H
    endm

; ---------------------------------------------------------------------
; vpoke addr, value      one-off VRAM byte write. Clobbers A, flags.
; ---------------------------------------------------------------------
    macro vpoke
    vera_addr 0, \1, VERA_INC_0
    lda #(\2)
    sta VERA_DATA0
    endm

; ---------------------------------------------------------------------
; Bank registers.
; ---------------------------------------------------------------------
    macro set_rambank
    lda #(\1)
    sta RAM_BANK
    endm

    macro set_rombank
    lda #(\1)
    sta ROM_BANK
    endm

; ---------------------------------------------------------------------
; jsrfar addr, bank      call a routine in another ROM/RAM bank via the
;                        KERNAL's JSRFAR ($FF6E) mechanism.
; ---------------------------------------------------------------------
    macro jsrfar
    jsr JSRFAR
    word \1
    byte \2
    endm

; ---------------------------------------------------------------------
; rom_call_fast bank, entry     ~40 cycles cheaper than jsrfar, but it
;                               CLOBBERS A and leaves ROM_BANK = bank.
; ---------------------------------------------------------------------
    macro rom_call_fast
    lda #(\1)
    sta ROM_BANK
    jsr \2
    endm

; ---------------------------------------------------------------------
; i16_const dest, value     load a 16-bit literal into a 2-byte
;                           little-endian buffer.
; ---------------------------------------------------------------------
    macro i16_const
    lda #<(\2)
    sta \1
    lda #>(\2)
    sta \1+1
    endm

; ---------------------------------------------------------------------
; i32_const dest, value     load a 32-bit literal into a 4-byte
;                           little-endian buffer.
; ---------------------------------------------------------------------
    macro i32_const
    lda #<(\2)
    sta \1
    lda #>(\2)
    sta \1+1
    lda #<((\2) >> 16)
    sta \1+2
    lda #<((\2) >> 24)
    sta \1+3
    endm

; ---------------------------------------------------------------------
; basic_stub                emit `10 SYS 2061` so the PRG autoruns.
;                           Must be at $0801; code begins at $080D.
; ---------------------------------------------------------------------
    macro basic_stub
    word $080B                  ; link to the end-of-program marker
    word 10                     ; line number
    byte $9E                    ; SYS token
    byte "2061"                 ; = $080D
    byte $00                    ; end of line
    word $0000                  ; end of program
    endm

    endif                       ; X16_MACROS
