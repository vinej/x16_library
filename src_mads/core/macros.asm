; MADS
; =====================================================================
; x16lib :: core/macros.asm -- inlined plumbing (MADS edition)
; =====================================================================
; Pure macro file, hand-ported from src_acme/core/macros.asm. MADS names
; macro parameters (referenced as :name) rather than ACME's .name, and
; invokes a macro by writing its name with no leading '+'. Everything
; else -- the emitted bytes -- matches the reference exactly.
;
; Requires the 65C02 opcodes (opt c+, set by x16.asm): uses trb/tsb.
; =====================================================================

; ---------------------------------------------------------------------
; vera_addrsel port         select which data port the ADDR registers
;                           refer to. Clobbers A and flags.
; ---------------------------------------------------------------------
.macro vera_addrsel port
    lda #VERA_CTRL_ADDRSEL
    .if :port = 0
    trb VERA_CTRL           ; clear bit 0
    .else
    tsb VERA_CTRL           ; set bit 0
    .endif
.endm

; ---------------------------------------------------------------------
; vera_dcsel n              select the $9F29-$9F2C register bank (0-63).
;                           Clobbers A and flags. Preserves ADDRSEL.
; ---------------------------------------------------------------------
.macro vera_dcsel n
    .if (:n) > 63
    .error "DCSEL must be 0-63"
    .endif
    lda VERA_CTRL
    and #VERA_CTRL_ADDRSEL
    ora #((:n) << 1)
    sta VERA_CTRL
.endm

; ---------------------------------------------------------------------
; vera_addr port, adr, incr     point a data port at a 17-bit VRAM
;                               address. Clobbers A and flags.
;
; `incr` is an INDEX, not a byte count -- use the VERA_INC_* constants.
; ---------------------------------------------------------------------
.macro vera_addr port, adr, incr
    .if (:adr) > $1FFFF
    .error "VRAM address must be 17-bit"
    .endif
    .if (:incr) > 15
    .error "use a VERA_INC_* constant, not a byte count"
    .endif
    vera_addrsel :port
    lda #<(:adr)
    sta VERA_ADDR_L
    lda #>(:adr)
    sta VERA_ADDR_M
    lda #(((:adr) >> 16) & VERA_ADDR_H_BANK) | ((:incr) << 4)
    sta VERA_ADDR_H
.endm

; Same, but decrementing.
.macro vera_addr_decr port, adr, incr
    vera_addrsel :port
    lda #<(:adr)
    sta VERA_ADDR_L
    lda #>(:adr)
    sta VERA_ADDR_M
    lda #(((:adr) >> 16) & VERA_ADDR_H_BANK) | VERA_ADDR_H_DECR | ((:incr) << 4)
    sta VERA_ADDR_H
.endm

; ---------------------------------------------------------------------
; vpoke adr, value          one-off VRAM byte write. Clobbers A, flags.
; ---------------------------------------------------------------------
.macro vpoke adr, value
    vera_addr 0, :adr, VERA_INC_0
    lda #(:value)
    sta VERA_DATA0
.endm

; ---------------------------------------------------------------------
; Bank registers.
; ---------------------------------------------------------------------
.macro set_rambank n
    lda #(:n)
    sta RAM_BANK
.endm

.macro set_rombank n
    lda #(:n)
    sta ROM_BANK
.endm

; ---------------------------------------------------------------------
; jsrfar adr, bank          call a routine in another ROM/RAM bank via
;                           the KERNAL's own mechanism ($FF6E).
; ---------------------------------------------------------------------
.macro jsrfar adr, bank
    jsr JSRFAR
    .word :adr
    .byte :bank
.endm

; ---------------------------------------------------------------------
; rom_call_fast bank, entry     ~40 cycles cheaper than jsrfar, but it
;                               CLOBBERS A and leaves ROM_BANK set to
;                               `bank`. You must restore it yourself.
; ---------------------------------------------------------------------
.macro rom_call_fast bank, entry
    lda #(:bank)
    sta ROM_BANK
    jsr :entry
.endm

; ---------------------------------------------------------------------
; i16_const dest, value     load a 16-bit literal into a 2-byte
;                           little-endian buffer (see util/int16.asm).
; ---------------------------------------------------------------------
.macro i16_const dest, value
    lda #<(:value)
    sta :dest
    lda #>(:value)
    sta :dest + 1
.endm

; ---------------------------------------------------------------------
; i32_const dest, value     load a 32-bit literal into a 4-byte
;                           little-endian buffer (see util/int32.asm).
; ---------------------------------------------------------------------
.macro i32_const dest, value
    lda #<(:value)
    sta :dest
    lda #>(:value)
    sta :dest + 1
    lda #<((:value) >> 16)
    sta :dest + 2
    lda #<((:value) >> 24)
    sta :dest + 3
.endm

; ---------------------------------------------------------------------
; basic_stub                emit `10 SYS 2061` so the PRG autoruns.
;                           Must be the first thing at $0801; machine
;                           code then begins at $080D (= 2061).
; ---------------------------------------------------------------------
.macro basic_stub
    .if * != $0801
    .error "basic_stub must be emitted at $0801"
    .endif
    .word $080B             ; link to the end-of-program marker
    .word 10                ; line number
    .byte $9E               ; SYS token
    dta c'2061'             ; = $080D
    .byte $00               ; end of line
    .word $0000             ; end of program
    .if * != $080D
    .error "basic_stub emitted wrong length"
    .endif
.endm
