;ACME
; =====================================================================
; x16lib :: storage/bankalloc.asm -- whole-bank RAM allocator
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Banked RAM is 8 KB pages at $A000, selected by RAM_BANK. The natural
; allocation unit IS the bank: sample sets, level maps, decompression
; buffers. This is a bitmap allocator over banks 1-255 (bank 0 belongs
; to the KERNAL).
;
; The allocator hands out BANK NUMBERS; it never touches RAM_BANK
; itself. Combine with bank_peek/poke, mem_to_bank/bank_to_mem and
; bank_copy_far from storage/bank.asm.
;
;       lda #1                  ; manage banks 1..
;       ldx #63                 ; ..63 (a 512K machine's worth minus 0)
;       jsr bank_alloc_init
;       jsr bank_alloc          ; carry clear, A = a free bank
;       ...
;       jsr bank_free           ; give it back
; =====================================================================


ba_map
    :(32) dta 0  ; one bit per bank; set = FREE

bankalloc_bit
    .byte $01, $02, $04, $08, $10, $20, $40, $80

; ---------------------------------------------------------------------
; bank_alloc_init -- define the pool
;   in:  A = first bank, X = last bank (inclusive); A <= X
;
; Banks outside the range are never handed out. Call again to reset
; the pool (all banks become free; nothing is remembered).
; ---------------------------------------------------------------------
bank_alloc_init
    sta X16_T0                  ; first
    stx X16_T1                  ; last

    ldx #31                     ; everything starts out un-ownable
bank_alloc_init__clear
    stz ba_map,x
    dex
    bpl bank_alloc_init__clear

    lda X16_T0
bank_alloc_init__mark
    jsr bankalloc_set_bit                ; mark free
    lda X16_T0
    cmp X16_T1
    beq bank_alloc_init__done
    inc X16_T0
    lda X16_T0
    bra bank_alloc_init__mark
bank_alloc_init__done
    rts

; ---------------------------------------------------------------------
; bank_alloc -- take a free bank from the pool
;   out: carry clear, A = bank number -- or carry set: pool exhausted
;   Allocates the lowest free bank first.
; ---------------------------------------------------------------------
bank_alloc
    ldx #0
bank_alloc__scan
    lda ba_map,x
    bne bank_alloc__found
    inx
    cpx #32
    bne bank_alloc__scan
    sec                         ; nothing free
    rts
bank_alloc__found
    ldy #0
bank_alloc__bit
    lda ba_map,x
    and bankalloc_bit,y
    bne bank_alloc__take
    iny
    bra bank_alloc__bit                    ; must hit: the byte was nonzero
bank_alloc__take
    lda ba_map,x                ; clear the bit: bank is now in use
    eor bankalloc_bit,y
    sta ba_map,x
    txa                         ; bank = byte index * 8 + bit index
    asl
    asl
    asl
    sta X16_T0
    tya
    ora X16_T0
    clc
    rts

; ---------------------------------------------------------------------
; bank_free -- return a bank to the pool
;   in:  A = bank number (one that bank_alloc handed out)
;
; Freeing a bank that is already free, or that was never in the pool,
; quietly marks it allocatable -- there is no ownership record to
; check against, so don't do that.
; ---------------------------------------------------------------------
bank_free
    ; fall through to bankalloc_set_bit

; mark bank A's bit in the map. Clobbers A, X, Y; preserves T0/T1 not.
bankalloc_set_bit
    pha
    lsr
    lsr
    lsr
    tax                         ; byte index
    pla
    and #$07
    tay
    lda ba_map,x
    ora bankalloc_bit,y
    sta ba_map,x
    rts

; ---------------------------------------------------------------------
; bank_reserve -- claim a specific bank (mark it in use)
;   in:  A = bank number
;   out: carry clear if it was free and is now yours; carry set if it
;        was already taken (or outside the pool)
; ---------------------------------------------------------------------
bank_reserve
    pha
    lsr
    lsr
    lsr
    tax
    pla
    and #$07
    tay
    lda ba_map,x
    and bankalloc_bit,y
    beq bank_reserve__taken
    lda ba_map,x                ; it was free: clear the bit
    eor bankalloc_bit,y
    sta ba_map,x
    clc
    rts
bank_reserve__taken
    sec
    rts

