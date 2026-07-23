;ACME
; =====================================================================
; x16lib :: util/tscrunch.asm -- TSCrunch decompression
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; TSCrunch (Antonio Savona) is a byte-aligned LZ+RLE built to maximise
; 6502 DECODE SPEED -- the other end of the trade from ZX0: unpacks
; markedly faster, packs a little looser. Crunch with:
;
;       tscrunch data.bin data.tsc        (plain memory crunch)
;
; This is a 65C02 port of the reference decrunch_small.asm: the
; original leans on the NMOS undocumented opcodes LAX and ALR, which
; the X16's 65C02 does not have -- they are replaced with legal pairs,
; everything else (including the load-bearing carry choreography) is
; kept move for move. Copyright for the original algorithm and
; decruncher: Antonio Savona.
;
;       lda #<data_tsc : sta X16_P0 : lda #>data_tsc : sta X16_P1
;       lda #<dest     : sta X16_P2 : lda #>dest     : sta X16_P3
;       jsr tsc_decompress          ; A/X = one past the last byte
;
; RAM to RAM, forward only, cannot decompress in place.
; =====================================================================


; ---------------------------------------------------------------------
; tsc_decompress
;   in:  X16_P0/P1 = compressed data, X16_P2/P3 = output address
;   out: A/X = one past the last output byte
;        (X16_P0..P3 consumed; X16_T5..T7 used as scratch)
; ---------------------------------------------------------------------
tsc_decompress
    ldy #0
    lda (X16_P0),y              ; the stream's first byte parameterises
    sta tscrunch_optlen+1               ; the one-token zero-run length
    inc X16_P0
    bne tsc_decompress__entry
    inc X16_P1

tsc_decompress__entry
    lda (X16_P0),y              ; (LAX) token
    tax
    bmi tsc_decompress__rleorlz

    cmp #$20
    bcs tsc_decompress__lz2

    ; --- literal: token = count, the bytes follow ---------------------
    tay
tsc_decompress__lit
    lda (X16_P0),y
    dey
    sta (X16_P2),y
    bne tsc_decompress__lit
    txa                         ; carry is clear (cmp #$20 fell through)
    inx
tsc_decompress__bump_zp
    adc X16_P2                  ; output += A (+ inherited carry)
    sta X16_P2
    bcs tsc_decompress__put_hi
tsc_decompress__put_ok
    txa
tsc_decompress__bump_get
    adc X16_P0                  ; input += X
    sta X16_P0
    bcc tsc_decompress__entry
    inc X16_P1
    bcs tsc_decompress__entry

tsc_decompress__put_hi
    inc X16_P3
    clc
    bcc tsc_decompress__put_ok

    ; --- RLE or LZ (token bit 7 set) -----------------------------------
tsc_decompress__rleorlz
    and #$7F                    ; (ALR #$7F)
    lsr
    bcc tsc_decompress__lz

    ; RLE: A = length field, carry is set for the +1 in tsc_decompress__bump_zp
    beq tsc_decompress__optrun
    ldx #2
    iny
    sta X16_T5                  ; run length
    lda (X16_P0),y              ; the byte to repeat
    ldy X16_T5
tsc_decompress__run_start
    sta (X16_P2),y
tsc_decompress__rle_loop
    dey
    sta (X16_P2),y
    bne tsc_decompress__rle_loop
    lda X16_T5
    bcs tsc_decompress__bump_zp                ; always (carry survived untouched)

tsc_decompress__done
    lda X16_P2                  ; the end of the output
    ldx X16_P3
    rts

    ; --- LZ2: a two-byte match with a one-byte token -------------------
tsc_decompress__lz2
    beq tsc_decompress__done                   ; $20 is the end-of-stream marker
    ora #$80                    ; carry is set: offset folds negative
    adc X16_P2
    sta X16_T6
    lda X16_P3
    sbc #$00
    sta X16_T7
    lda (X16_T6),y              ; y = 0
    sta (X16_P2),y
    iny
    lda (X16_T6),y
    sta (X16_P2),y
    tya                         ; A = 1
    tax                         ; X = 1
    dey                         ; Y = 0
    beq tsc_decompress__bump_zp                ; always; carry set: output += 2

    ; --- LZ match ------------------------------------------------------
tsc_decompress__lz
    lsr                         ; carry: short (1) or long (0) offset
    sta tsc_decompress__lzto+1                 ; length - 1
    iny
    lda X16_P2
    bcc tsc_decompress__long
    sbc (X16_P0),y              ; carry set: back = output - offset
    sta X16_T6
    lda X16_P3
    sbc #$00
    ldx #2
tsc_decompress__lz_put
    sta X16_T7
    ldy #0
    lda (X16_T6),y              ; matches MUST copy forward
    sta (X16_P2),y
tsc_decompress__lz_loop
    iny
    lda (X16_T6),y
    sta (X16_P2),y
tsc_decompress__lzto
    cpy #0                      ; operand = length - 1 (self-modified)
    bne tsc_decompress__lz_loop
    tya
    ldy #0
    bcs tsc_decompress__bump_zp                ; cpy equality left the carry set

    ; --- the one-token zero run ----------------------------------------
tsc_decompress__optrun
tscrunch_optlen
    ldy #255                    ; operand = the stream's header byte
    sty X16_T5
    ldx #1                      ; A = 0: a run of zeros
    bne tsc_decompress__run_start

    ; --- long LZ: 15-bit offset, one more length bit --------------------
tsc_decompress__long
    adc (X16_P0),y              ; carry clear, compensated by the encoder
    sta X16_T6
    iny
    lda (X16_P0),y              ; (LAX)
    tax
    ora #$80
    adc X16_P3                  ; the low add's carry ripples in here
    cpx #$80                    ; offset bit 15 doubles as a length bit
    rol tsc_decompress__lzto+1
    ldx #3
    bne tsc_decompress__lz_put                 ; always
