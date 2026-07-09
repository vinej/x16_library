;ACME
; =====================================================================
; x16lib :: gfx/verafx.asm -- VERA FX: hardware multiply, fast fills
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Requires VERA firmware v0.3.1+ (emulator R44+). Probe with vera_has_fx
; before calling anything here; on older VERA these routines write to
; registers that do not exist and quietly do the wrong thing.
;
; The FX registers are $9F29-$9F2C banked behind DCSEL 2..6. Always
; select the bank with +vera_dcsel, which preserves ADDRSEL -- writing
; VERA_CTRL directly (as the reference manual's examples do) would
; deselect whatever data port the caller had chosen.
;
; Every routine here leaves FX disabled (FX_CTRL = 0, Addr1 Mode 0) and
; DCSEL back at 0. Leaving Addr1 Mode set would silently change how
; ordinary VRAM addressing behaves for everyone downstream.
; =====================================================================

!zone x16_verafx {

; ---------------------------------------------------------------------
; fx_off -- disable FX and return DCSEL to 0.
; Safe to call whether or not FX was ever enabled.
; ---------------------------------------------------------------------
fx_off
    +vera_dcsel 2
    stz VERA_FX_CTRL            ; cache off, transparency off, Addr1 mode 0
    stz VERA_FX_MULT            ; multiplier off
    +vera_dcsel 0
    rts

; ---------------------------------------------------------------------
; fx_mult -- signed 16 x 16 -> 32 in hardware
;   in:  X16_P0/P1 = a, X16_P2/P3 = b
;   out: X16_P4..P7 = product, low byte first
;
; The two operands go into the halves of the 32-bit cache. The result
; is not readable from a register: triggering the multiply writes four
; bytes to VRAM, so we park them at VRAM_FX_SCRATCH and read them back.
;
; Only ADDR0/DATA0 is used. VERA pre-fetches whenever an address pointer
; changes or increments -- even with increment 0 -- so touching the same
; VRAM through the other port here would risk reading a stale latch.
; ---------------------------------------------------------------------
fx_mult
    +vera_dcsel 2
    stz VERA_FX_CTRL            ; Addr1 Mode 0
    lda #VERA_FX_MULT_ENABLE
    sta VERA_FX_MULT

    +vera_dcsel 6
    lda VERA_FX_ACCUM_RESET     ; a *read* clears the accumulator
    lda X16_P0
    sta VERA_FX_CACHE_L
    lda X16_P1
    sta VERA_FX_CACHE_M         ; cache 15:0  = a
    lda X16_P2
    sta VERA_FX_CACHE_H
    lda X16_P3
    sta VERA_FX_CACHE_U         ; cache 31:16 = b

    +vera_dcsel 2
    lda #VERA_FX_CACHE_WRITE
    sta VERA_FX_CTRL            ; with multiplier on, writes the product

    ; Trigger: any store to DATA0 emits the 32-bit result. The stored
    ; value itself is ignored.
    +vera_addr 0, VRAM_FX_SCRATCH, VERA_INC_0
    stz VERA_DATA0

    ; Read it back, now advancing one byte at a time.
    +vera_addr 0, VRAM_FX_SCRATCH, VERA_INC_1
    lda VERA_DATA0
    sta X16_P4
    lda VERA_DATA0
    sta X16_P5
    lda VERA_DATA0
    sta X16_P6
    lda VERA_DATA0
    sta X16_P7

    jmp fx_off

; ---------------------------------------------------------------------
; fx_fill -- fill VRAM through the 32-bit write cache (~4x a byte loop)
;   in:  A = byte value
;        X16_P0/P1/P2 = destination VRAM address (17-bit)
;        X16_P3/P4    = byte count
;
; With Cache Write Enable set, one store to DATA0 writes all four cache
; bytes. Stepping the port by 4 covers the region a quad at a time; any
; remaining 1-3 bytes are written normally with FX switched back off.
; ---------------------------------------------------------------------
fx_fill
    sta X16_T0                  ; fill value

    +vera_dcsel 2
    stz VERA_FX_MULT            ; multiplier off: write the cache itself
    lda #VERA_FX_CACHE_WRITE
    sta VERA_FX_CTRL

    +vera_dcsel 6
    lda X16_T0
    sta VERA_FX_CACHE_L
    sta VERA_FX_CACHE_M
    sta VERA_FX_CACHE_H
    sta VERA_FX_CACHE_U
    +vera_dcsel 0

    ; Point port 0 at the destination, stepping 4 bytes per write.
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    lda X16_P0
    sta VERA_ADDR_L
    lda X16_P1
    sta VERA_ADDR_M
    lda X16_P2
    and #VERA_ADDR_H_BANK
    ora #(VERA_INC_4 << 4)
    sta VERA_ADDR_H

    ; quads = count >> 2, remainder = count & 3
    lda X16_P3
    and #$03
    sta X16_T3
    lda X16_P4
    sta X16_T2
    lda X16_P3
    sta X16_T1
    lsr X16_T2
    ror X16_T1
    lsr X16_T2
    ror X16_T1

    lda X16_T1
    ora X16_T2
    beq @tail                   ; fewer than four bytes

    ldx X16_T1
    ldy X16_T2
    txa
    beq @full
    iny
@full
@loop
    stz VERA_DATA0              ; writes the four cache bytes
    dex
    bne @loop
    dey
    bne @loop

@tail
    ; FX off first: the leftover bytes must be written singly.
    +vera_dcsel 2
    stz VERA_FX_CTRL
    +vera_dcsel 0

    lda X16_T3
    beq @done

    ; Port 0 already sits just past the quads. Keep its bank and DECR
    ; bits, switch the increment back to 1.
    lda VERA_ADDR_H
    and #$0F
    ora #(VERA_INC_1 << 4)
    sta VERA_ADDR_H

    ldx X16_T3
    lda X16_T0
@rest
    sta VERA_DATA0
    dex
    bne @rest
@done
    rts

; ---------------------------------------------------------------------
; fx_clear -- zero a VRAM region
;   in:  X16_P0/P1/P2 = address, X16_P3/P4 = byte count
; ---------------------------------------------------------------------
fx_clear
    lda #0
    jmp fx_fill

}   ; !zone x16_verafx
