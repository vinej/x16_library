;ACME
; =====================================================================
; x16lib :: util/zx0.asm -- ZX0 decompression (Einar Saukas's format)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The ROM's LZSA2 (mem_decompress) is free and fast; ZX0 packs
; tighter. This decodes the MODERN ZX0 v2 stream -- what `zx0` and
; `salvador` emit by default (not their -classic mode).
;
;       salvador data.bin data.zx0
;
;       lda #<data_zx0 : sta X16_P0 : lda #>data_zx0 : sta X16_P1
;       lda #<dest     : sta X16_P2 : lda #>dest     : sta X16_P3
;       jsr zx0_decompress          ; A/X = one past the last byte
;
; RAM to RAM only (the match copier reads the output back). Cannot
; decompress in place. Ported from the reference dzx0.c: three states
; (literals / repeat last offset / new offset), interlaced Elias gamma
; lengths, and the offset byte's low bit seeding the next length.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; zx0_decompress
;   in:  X16_P0/P1 = compressed data, X16_P2/P3 = output address
;   out: A/X = one past the last output byte
;        (X16_P0..P3 are consumed; X16_T6/T7 used as the copy pointer)
; ---------------------------------------------------------------------
zx0_decompress
    stz zx_bits                 ; empty bit buffer: first use refills
    stz zx_bt
    lda #1                      ; the initial offset is 1
    sta zx_off
    stz zx_off+1

_literals
    jsr zx0_gamma_n                ; literal run length
_lit_byte
    jsr zx0_getbyte
    sta (X16_P2)
    inc X16_P2
    bne _lit_dec
    inc X16_P3
_lit_dec
    jsr zx0_dec_len
    bne _lit_byte

    jsr zx0_getbit
    bcs _new_offset

_last_offset
    jsr zx0_gamma_n                ; match length, offset unchanged
    jsr zx0_copy
    jsr zx0_getbit
    bcc _literals

_new_offset
    jsr zx0_gamma_i                ; the offset MSB, inverted gamma (v2)
    lda zx_val+1                ; 256 is the end-of-stream marker
    beq _not_end
    lda zx_val
    bne _not_end
    lda X16_P2                  ; done: hand back the output end
    ldx X16_P3
    rts
_not_end
    lda zx_val                  ; offset = MSB*128 - (next byte >> 1)
    lsr
    sta zx_off+1
    lda #0
    ror
    sta zx_off
    jsr zx0_getbyte                ; ...which also latches zx_last
    lsr
    sta zx_t
    sec
    lda zx_off
    sbc zx_t
    sta zx_off
    lda zx_off+1
    sbc #0
    sta zx_off+1
    lda #1                      ; that byte's low bit is the FIRST bit
    sta zx_bt                   ; of the coming length gamma
    jsr zx0_gamma_n
    inc zx_val                  ; new-offset match lengths are +1
    bne _len_ok
    inc zx_val+1
_len_ok
    jsr zx0_copy
    jsr zx0_getbit
    bcs _new_offset
    bra _literals

; --- plumbing ---------------------------------------------------------

; copy zx_val bytes from (output - zx_off) to the output
zx0_copy
    sec
    lda X16_P2
    sbc zx_off
    sta X16_T6
    lda X16_P3
    sbc zx_off+1
    sta X16_T7
_byte
    lda (X16_T6)
    sta (X16_P2)
    inc X16_T6
    bne _dst
    inc X16_T7
_dst
    inc X16_P2
    bne _count
    inc X16_P3
_count
    jsr zx0_dec_len
    bne _byte
    rts

; zx_val -= 1; Z set when it reaches zero (val >= 1 on entry)
zx0_dec_len
    lda zx_val
    bne _lo
    dec zx_val+1
_lo
    dec zx_val
    lda zx_val
    ora zx_val+1
    rts

; interlaced Elias gamma into zx_val: normal and inverted data bits
zx0_gamma_i
    lda #1
    bra zx0_gamma
zx0_gamma_n
    lda #0
zx0_gamma
    sta zx_inv
    lda #1
    sta zx_val
    stz zx_val+1
_more
    jsr zx0_getbit
    bcs _done                   ; a 1 control bit ends the number
    jsr zx0_getbit
    lda #0
    rol                         ; A = the data bit
    eor zx_inv
    lsr                         ; ...back into the carry
    rol zx_val
    rol zx_val+1
    bra _more
_done
    rts

; next bit into the carry. The buffer keeps a sentinel 1 in bit 0, so
; a zero buffer after the shift means "that carry was the sentinel":
; refill and take bit 7 of the fresh byte instead.
zx0_getbit
    lda zx_bt
    beq _stream
    stz zx_bt                   ; backtrack: the offset byte's low bit
    lda zx_last
    lsr
    rts
_stream
    asl zx_bits
    beq _refill
    rts
_refill
    jsr zx0_getbyte
    sec
    rol                         ; carry = bit 7, sentinel into bit 0
    sta zx_bits
    rts

zx0_getbyte
    lda (X16_P0)
    sta zx_last
    inc X16_P0
    bne _gb_ok
    inc X16_P1
_gb_ok
    lda zx_last
    rts

zx_bits .byte 0
zx_last .byte 0
zx_bt   .byte 0
zx_inv  .byte 0
zx_val  .word 0
zx_off  .word 0
zx_t    .byte 0

; (end zone)
