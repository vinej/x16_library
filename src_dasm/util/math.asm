;ACME
; =====================================================================
; x16lib :: util/math.asm -- game math: PRNG, sine tables, atan2, lerp
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Angles are bytes: a full circle is 256, so 64 = 90 degrees and
; wrap-around is free. With the X16's y axis pointing DOWN the screen,
; angle 0 points east (+x) and 64 points south (+y) -- atan2 and the
; sine tables agree on that, so
;       x += (cos8(a) * speed) >> 7 ; y += (sin8(a) * speed) >> 7
; moves along the heading atan2 returned.
;
; The sine and arctangent tables are computed by the assembler at
; build time.
; =====================================================================

; (zone: file scope in dasm)

; ---------------------------------------------------------------------
; rnd_seed -- in: A = low, X = high. Zero is nudged to 1 (xorshift's
;             one fixed point).
; rnd8  -- out: A = the next pseudo-random byte (X = high byte)
; rnd16 -- out: A = low, X = high
;
; John Metcalf's 16-bit xorshift (shifts 7, 9, 8): period 65535 and a
; handful of cycles -- cheap enough per frame per object.
; ---------------------------------------------------------------------
    SUBROUTINE
rnd_seed
    sta rnd_state
    stx rnd_state+1
    ora rnd_state+1
    bne .done
    inc rnd_state               ; zero stays zero forever
.done
    rts

    SUBROUTINE
rnd8                            ; same routine; read A, ignore X
    SUBROUTINE
rnd16
    lda rnd_state+1
    lsr
    lda rnd_state
    ror
    eor rnd_state+1
    sta rnd_state+1             ; x ^= x >> 9
    ror
    eor rnd_state
    sta rnd_state               ; x ^= x << 7
    eor rnd_state+1
    sta rnd_state+1             ; x ^= x << 8
    lda rnd_state
    ldx rnd_state+1
    rts

    SUBROUTINE
rnd_state dc.w $2A56

; ---------------------------------------------------------------------
; sin8 / cos8   -- in: A = angle 0-255.  out: A = -127..127 signed
; sin8u / cos8u -- in: A = angle 0-255.  out: A = 1..255 unsigned
;                  (128 + the signed value: handy for volumes/scales)
; Preserve X; clobber Y.
; ---------------------------------------------------------------------
    SUBROUTINE
sin8
    tay
    lda math_sintab,y
    rts

    SUBROUTINE
cos8
    clc
    adc #64                     ; cos(a) = sin(a + 90 degrees)
    tay
    lda math_sintab,y
    rts

    SUBROUTINE
sin8u
    tay
    lda math_sintab,y
    clc
    adc #128
    rts

    SUBROUTINE
cos8u
    clc
    adc #64
    tay
    lda math_sintab,y
    clc
    adc #128
    rts

; round(sin(i * 2pi/256) * 127); int() truncates toward zero, so bias
; through +128.5 to get a floor, which rounds negatives correctly too.
    SUBROUTINE
math_sintab
    dc.b $00, $03, $06, $09, $0C, $10, $13, $16, $19, $1C, $1F, $22, $25, $28, $2B, $2E
    dc.b $31, $33, $36, $39, $3C, $3F, $41, $44, $47, $49, $4C, $4E, $51, $53, $55, $58
    dc.b $5A, $5C, $5E, $60, $62, $64, $66, $68, $6A, $6B, $6D, $6F, $70, $71, $73, $74
    dc.b $75, $76, $78, $79, $7A, $7A, $7B, $7C, $7D, $7D, $7E, $7E, $7E, $7F, $7F, $7F
    dc.b $7F, $7F, $7F, $7F, $7E, $7E, $7E, $7D, $7D, $7C, $7B, $7A, $7A, $79, $78, $76
    dc.b $75, $74, $73, $71, $70, $6F, $6D, $6B, $6A, $68, $66, $64, $62, $60, $5E, $5C
    dc.b $5A, $58, $55, $53, $51, $4E, $4C, $49, $47, $44, $41, $3F, $3C, $39, $36, $33
    dc.b $31, $2E, $2B, $28, $25, $22, $1F, $1C, $19, $16, $13, $10, $0C, $09, $06, $03
    dc.b $00, $FD, $FA, $F7, $F4, $F0, $ED, $EA, $E7, $E4, $E1, $DE, $DB, $D8, $D5, $D2
    dc.b $CF, $CD, $CA, $C7, $C4, $C1, $BF, $BC, $B9, $B7, $B4, $B2, $AF, $AD, $AB, $A8
    dc.b $A6, $A4, $A2, $A0, $9E, $9C, $9A, $98, $96, $95, $93, $91, $90, $8F, $8D, $8C
    dc.b $8B, $8A, $88, $87, $86, $86, $85, $84, $83, $83, $82, $82, $82, $81, $81, $81
    dc.b $81, $81, $81, $81, $82, $82, $82, $83, $83, $84, $85, $86, $86, $87, $88, $8A
    dc.b $8B, $8C, $8D, $8F, $90, $91, $93, $95, $96, $98, $9A, $9C, $9E, $A0, $A2, $A4
    dc.b $A6, $A8, $AB, $AD, $AF, $B2, $B4, $B7, $B9, $BC, $BF, $C1, $C4, $C7, $CA, $CD
    dc.b $CF, $D2, $D5, $D8, $DB, $DE, $E1, $E4, $E7, $EA, $ED, $F0, $F4, $F7, $FA, $FD

; ---------------------------------------------------------------------
; atan2 -- the angle of a vector
;   in:  A = dx, X = dy  (signed bytes)
;   out: A = angle 0-255 (0 = +x/east, 64 = +y/down-screen)
;
; Octant reduction plus a 33-entry arctangent table; the only work is
; one 8-bit divide. atan2(0,0) answers 0.
; ---------------------------------------------------------------------
    SUBROUTINE
atan2
    stz at_negx
    tay                         ; |dx|, remembering the sign
    bpl .dx_pos
    inc at_negx
    eor #$FF
    clc
    adc #1
.dx_pos
    sta at_ax
    txa                         ; |dy|
    stz at_negy
    bpl .dy_pos
    inc at_negy
    eor #$FF
    clc
    adc #1
.dy_pos
    sta at_ay

    ; base angle 0..64 within the positive quadrant
    cmp at_ax
    beq .diag
    bcc .shallow
    lda at_ax                   ; steep: base = 64 - atan(ax/ay)
    ldx at_ay
    jsr math_ratio32
    tay
    sec
    lda #64
    sbc math_atantab,y
    bra .quad
.diag
    ora at_ax
    bne .is45
    lda #0                      ; atan2(0,0): call it east
    rts
.is45
    lda #32                     ; exactly 45 degrees
    bra .quad
.shallow
    lda at_ay                   ; shallow: base = atan(ay/ax)
    ldx at_ax
    jsr math_ratio32
    tay
    lda math_atantab,y

.quad
    ; fold the base angle into the right quadrant
    ldy at_negx
    beq .dx_ok
    eor #$FF                    ; dx < 0: angle = 128 - base
    clc
    adc #129
.dx_ok
    ldy at_negy
    beq .done
    eor #$FF                    ; dy < 0: angle = -angle
    clc
    adc #1
.done
    rts

; A = (A * 32) / X, for A <= X and X nonzero. Result 0..32.
    SUBROUTINE
math_ratio32
    stx at_den
    sta at_num+1                ; num = A * 256...
    stz at_num
    ldx #3
.shift
    lsr at_num+1                ; ...then >> 3 = A * 32
    ror at_num
    dex
    bne .shift
    lda #0                      ; 16-bit / 8-bit restoring divide
    ldx #16
.div
    asl at_num
    rol at_num+1
    rol
    cmp at_den
    bcc .no
    sbc at_den
    inc at_num
.no
    dex
    bne .div
    lda at_num                  ; the quotient
    rts

    SUBROUTINE
at_ax   dc.b 0
    SUBROUTINE
at_ay   dc.b 0
    SUBROUTINE
at_negx dc.b 0
    SUBROUTINE
at_negy dc.b 0
    SUBROUTINE
at_num  dc.w 0
    SUBROUTINE
at_den  dc.b 0

    SUBROUTINE
math_atantab
    dc.b $00, $01, $03, $04, $05, $06, $08, $09, $0A, $0B, $0C, $0D, $0F, $10, $11, $12
    dc.b $13, $14, $15, $16, $17, $18, $19, $19, $1A, $1B, $1C, $1D, $1D, $1E, $1F, $1F
    dc.b $20

; ---------------------------------------------------------------------
; lerp8 -- linear interpolation between two unsigned bytes
;   in:  X16_P0 = a, X16_P1 = b, A = t (0 = a ... 255 = b)
;   out: A = the interpolated value; t=0 is exactly a, t=255 exactly b
;
; Computes a +/- (|b-a| * (t+1)) / 256 -- at most one off from the
; ideal /255 midway, exact at both ends.
; ---------------------------------------------------------------------
    SUBROUTINE
lerp8
    sta lp_t
    lda X16_P1
    cmp X16_P0
    bcc .down
    sbc X16_P0                  ; carry set: a clean subtract
    jsr math_scale_t
    clc
    adc X16_P0
    rts
.down
    lda X16_P0                  ; b < a: interpolate downwards
    sec
    sbc X16_P1
    jsr math_scale_t
    sta lp_d
    sec
    lda X16_P0
    sbc lp_d
    rts

; A = (A * (lp_t + 1)) >> 8
    SUBROUTINE
math_scale_t
    sta lp_d
    lda lp_t
    cmp #$FF
    beq .whole                  ; t+1 = 256: the answer is d itself
    ina  ; n = t+1, fits a byte
    sta lp_n
    ; 8x8 multiply keeping only the high byte: per multiplier bit
    ; (LSB first), optionally add d, then rotate the result right.
    lda #0
    ldx #8
.mul
    lsr lp_n
    bcc .skip
    clc
    adc lp_d
.skip
    ror
    dex
    bne .mul
    rts
.whole
    lda lp_d
    rts

    SUBROUTINE
lp_t dc.b 0
    SUBROUTINE
lp_n dc.b 0
    SUBROUTINE
lp_d dc.b 0

; (end zone)
