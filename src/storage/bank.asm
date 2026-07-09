;ACME
; =====================================================================
; x16lib :: storage/bank.asm -- banked RAM ($A000-$BFFF window)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; RAM_BANK ($00) selects which 8 KB bank appears at $A000-$BFFF.
; Bank 0 holds KERNAL variables; banks 1..255 are yours.
;
; Offsets are 0..8191 into the window. The bulk copies auto-advance
; across bank boundaries, so a run may start near the end of one bank
; and finish in the next.
;
; All routines here save and restore RAM_BANK, so they are safe to call
; without disturbing whatever bank the caller had mapped in.
; =====================================================================

!zone x16_bank {

BANK_WINDOW     = $A000
BANK_WINDOW_END = $C000
BANK_SIZE       = BANK_WINDOW_END - BANK_WINDOW    ; 8192

; ---------------------------------------------------------------------
; bank_set / bank_get -- the RAM bank mapped at $A000
; ---------------------------------------------------------------------
bank_set
    sta RAM_BANK
    rts

bank_get
    lda RAM_BANK
    rts

; ---------------------------------------------------------------------
; bank_peek
;   in:  A = bank, X16_P0/P1 = offset (0..8191)
;   out: A = byte
; bank_poke
;   in:  A = byte, X = bank, X16_P0/P1 = offset
; ---------------------------------------------------------------------
bank_peek
    ldx RAM_BANK
    phx
    sta RAM_BANK
    jsr .window_ptr
    ldy #0
    lda (X16_T0),y
    plx
    stx RAM_BANK
    rts

bank_poke
    pha                         ; [byte]
    lda RAM_BANK
    pha                         ; [byte][caller bank]
    stx RAM_BANK
    jsr .window_ptr
    ldy #0
    pla
    tax                         ; X = caller bank
    pla                         ; A = byte to store
    sta (X16_T0),y
    stx RAM_BANK
    rts

; Shared helpers are zone-local (a leading '.'), not cheap locals (a
; leading '@'): a cheap local only reaches from one global label to the
; next, so bank_peek could not see a helper defined after bank_poke.

; T0/T1 = BANK_WINDOW + offset. Preserves A.
.window_ptr
    pha
    lda X16_P0
    clc
    adc #<BANK_WINDOW
    sta X16_T0
    lda X16_P1
    adc #>BANK_WINDOW
    sta X16_T1
    pla
    rts

; ---------------------------------------------------------------------
; mem_to_bank -- copy low RAM into banked RAM
;   in:  X16_P0/P1 = source address
;        X16_P2    = destination bank
;        X16_P3/P4 = destination offset (0..8191)
;        X16_P5/P6 = byte count
;
; bank_to_mem -- the inverse
;   in:  X16_P0    = source bank
;        X16_P1/P2 = source offset
;        X16_P3/P4 = destination address
;        X16_P5/P6 = byte count
;
; Both auto-advance: when the window pointer reaches $C000 it snaps back
; to $A000 and RAM_BANK increments.
; ---------------------------------------------------------------------
mem_to_bank
    lda RAM_BANK
    pha
    lda X16_P2
    sta RAM_BANK

    lda X16_P0                  ; T2/T3 = source
    sta X16_T2
    lda X16_P1
    sta X16_T3
    lda X16_P3                  ; T0/T1 = window pointer
    clc
    adc #<BANK_WINDOW
    sta X16_T0
    lda X16_P4
    adc #>BANK_WINDOW
    sta X16_T1
    jsr .load_count

@copy_out
    lda X16_T4
    ora X16_T5
    beq @out_done
    ldy #0
    lda (X16_T2),y
    sta (X16_T0),y
    jsr .advance_src
    jsr .advance_window
    jsr .dec_count
    bra @copy_out
@out_done
    pla
    sta RAM_BANK
    rts

bank_to_mem
    lda RAM_BANK
    pha
    lda X16_P0
    sta RAM_BANK

    lda X16_P3                  ; T2/T3 = destination
    sta X16_T2
    lda X16_P4
    sta X16_T3
    lda X16_P1                  ; T0/T1 = window pointer
    clc
    adc #<BANK_WINDOW
    sta X16_T0
    lda X16_P2
    adc #>BANK_WINDOW
    sta X16_T1
    jsr .load_count

@copy_in
    lda X16_T4
    ora X16_T5
    beq @in_done
    ldy #0
    lda (X16_T0),y
    sta (X16_T2),y
    jsr .advance_src
    jsr .advance_window
    jsr .dec_count
    bra @copy_in
@in_done
    pla
    sta RAM_BANK
    rts

; --- shared helpers --------------------------------------------------
.load_count
    lda X16_P5
    sta X16_T4
    lda X16_P6
    sta X16_T5
    rts

; T2/T3 is whichever side lives in low RAM.
.advance_src
    inc X16_T2
    bne .as_done
    inc X16_T3
.as_done
    rts

; T0/T1 walks the $A000 window and rolls into the next bank at $C000.
.advance_window
    inc X16_T0
    bne .aw_done
    inc X16_T1
    lda X16_T1
    cmp #>BANK_WINDOW_END
    bne .aw_done
    lda #>BANK_WINDOW
    sta X16_T1
    inc RAM_BANK
.aw_done
    rts

.dec_count
    lda X16_T4
    bne .dc_low
    dec X16_T5
.dc_low
    dec X16_T4
    rts

}   ; !zone x16_bank
