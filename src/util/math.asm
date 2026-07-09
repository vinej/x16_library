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

!zone x16_math {

; ---------------------------------------------------------------------
; rnd_seed -- in: A = low, X = high. Zero is nudged to 1 (xorshift's
;             one fixed point).
; rnd8  -- out: A = the next pseudo-random byte (X = high byte)
; rnd16 -- out: A = low, X = high
;
; John Metcalf's 16-bit xorshift (shifts 7, 9, 8): period 65535 and a
; handful of cycles -- cheap enough per frame per object.
; ---------------------------------------------------------------------
rnd_seed
    sta rnd_state
    stx rnd_state+1
    ora rnd_state+1
    bne @done
    inc rnd_state               ; zero stays zero forever
@done
    rts

rnd8                            ; same routine; read A, ignore X
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

rnd_state !word $2A56

; ---------------------------------------------------------------------
; sin8 / cos8   -- in: A = angle 0-255.  out: A = -127..127 signed
; sin8u / cos8u -- in: A = angle 0-255.  out: A = 1..255 unsigned
;                  (128 + the signed value: handy for volumes/scales)
; Preserve X; clobber Y.
; ---------------------------------------------------------------------
sin8
    tay
    lda .sintab,y
    rts

cos8
    clc
    adc #64                     ; cos(a) = sin(a + 90 degrees)
    tay
    lda .sintab,y
    rts

sin8u
    tay
    lda .sintab,y
    clc
    adc #128
    rts

cos8u
    clc
    adc #64
    tay
    lda .sintab,y
    clc
    adc #128
    rts

; round(sin(i * 2pi/256) * 127); int() truncates toward zero, so bias
; through +128.5 to get a floor, which rounds negatives correctly too.
.sintab
!for i, 0, 255 {
    !byte int(sin(float(i) * 3.14159265358979 / 128.0) * 127.0 + 128.5) - 128
}

; ---------------------------------------------------------------------
; atan2 -- the angle of a vector
;   in:  A = dx, X = dy  (signed bytes)
;   out: A = angle 0-255 (0 = +x/east, 64 = +y/down-screen)
;
; Octant reduction plus a 33-entry arctangent table; the only work is
; one 8-bit divide. atan2(0,0) answers 0.
; ---------------------------------------------------------------------
atan2
    stz at_negx
    tay                         ; |dx|, remembering the sign
    bpl @dx_pos
    inc at_negx
    eor #$FF
    clc
    adc #1
@dx_pos
    sta at_ax
    txa                         ; |dy|
    stz at_negy
    bpl @dy_pos
    inc at_negy
    eor #$FF
    clc
    adc #1
@dy_pos
    sta at_ay

    ; base angle 0..64 within the positive quadrant
    cmp at_ax
    beq @diag
    bcc @shallow
    lda at_ax                   ; steep: base = 64 - atan(ax/ay)
    ldx at_ay
    jsr .ratio32
    tay
    sec
    lda #64
    sbc .atantab,y
    bra @quad
@diag
    ora at_ax
    bne @is45
    lda #0                      ; atan2(0,0): call it east
    rts
@is45
    lda #32                     ; exactly 45 degrees
    bra @quad
@shallow
    lda at_ay                   ; shallow: base = atan(ay/ax)
    ldx at_ax
    jsr .ratio32
    tay
    lda .atantab,y

@quad
    ; fold the base angle into the right quadrant
    ldy at_negx
    beq @dx_ok
    eor #$FF                    ; dx < 0: angle = 128 - base
    clc
    adc #129
@dx_ok
    ldy at_negy
    beq @done
    eor #$FF                    ; dy < 0: angle = -angle
    clc
    adc #1
@done
    rts

; A = (A * 32) / X, for A <= X and X nonzero. Result 0..32.
.ratio32
    stx at_den
    sta at_num+1                ; num = A * 256...
    stz at_num
    ldx #3
@shift
    lsr at_num+1                ; ...then >> 3 = A * 32
    ror at_num
    dex
    bne @shift
    lda #0                      ; 16-bit / 8-bit restoring divide
    ldx #16
@div
    asl at_num
    rol at_num+1
    rol
    cmp at_den
    bcc @no
    sbc at_den
    inc at_num
@no
    dex
    bne @div
    lda at_num                  ; the quotient
    rts

at_ax   !byte 0
at_ay   !byte 0
at_negx !byte 0
at_negy !byte 0
at_num  !word 0
at_den  !byte 0

.atantab                        ; round(atan(t/32) * 256/2pi), t = 0..32
!for i, 0, 32 {
    !byte int(arctan(float(i) / 32.0) * 128.0 / 3.14159265358979 + 0.5)
}

; ---------------------------------------------------------------------
; lerp8 -- linear interpolation between two unsigned bytes
;   in:  X16_P0 = a, X16_P1 = b, A = t (0 = a ... 255 = b)
;   out: A = the interpolated value; t=0 is exactly a, t=255 exactly b
;
; Computes a +/- (|b-a| * (t+1)) / 256 -- at most one off from the
; ideal /255 midway, exact at both ends.
; ---------------------------------------------------------------------
lerp8
    sta lp_t
    lda X16_P1
    cmp X16_P0
    bcc @down
    sbc X16_P0                  ; carry set: a clean subtract
    jsr .scale_t
    clc
    adc X16_P0
    rts
@down
    lda X16_P0                  ; b < a: interpolate downwards
    sec
    sbc X16_P1
    jsr .scale_t
    sta lp_d
    sec
    lda X16_P0
    sbc lp_d
    rts

; A = (A * (lp_t + 1)) >> 8
.scale_t
    sta lp_d
    lda lp_t
    cmp #$FF
    beq @whole                  ; t+1 = 256: the answer is d itself
    inc                         ; n = t+1, fits a byte
    sta lp_n
    ; 8x8 multiply keeping only the high byte: per multiplier bit
    ; (LSB first), optionally add d, then rotate the result right.
    lda #0
    ldx #8
@mul
    lsr lp_n
    bcc @skip
    clc
    adc lp_d
@skip
    ror
    dex
    bne @mul
    rts
@whole
    lda lp_d
    rts

lp_t !byte 0
lp_n !byte 0
lp_d !byte 0

}   ; !zone x16_math
