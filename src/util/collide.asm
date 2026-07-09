;ACME
; =====================================================================
; x16lib :: util/collide.asm -- axis-aligned bounding-box overlap
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; =====================================================================

!zone x16_collide {

; ---------------------------------------------------------------------
; collide8 -- do two boxes overlap?
;   in:  X16_P0 = ax, X16_P1 = ay, X16_P2 = aw, X16_P3 = ah
;        X16_P4 = bx, X16_P5 = by, X16_P6 = bw, X16_P7 = bh
;   out: carry set if the boxes overlap, clear otherwise
;
; Coordinates and sizes are unsigned bytes; the edge sums are computed
; in 9 bits so a box may legitimately run past x=255.
;
; Edges that merely touch do NOT overlap: a box at x=0 width 10 and one
; at x=10 are adjacent, not colliding. Overlap on an axis is
;       ax < bx+bw  AND  bx < ax+aw
; and both must hold on x and on y.
; ---------------------------------------------------------------------
collide8
    ; --- x axis ---
    lda X16_P4
    clc
    adc X16_P6                  ; bx + bw
    bcs @ax_lt                  ; past 255, so ax is certainly less
    cmp X16_P0                  ; carry set if (bx+bw) >= ax
    bcc @apart
    beq @apart                  ; equal means touching, not overlapping
@ax_lt
    lda X16_P0
    clc
    adc X16_P2                  ; ax + aw
    bcs @bx_lt
    cmp X16_P4
    bcc @apart
    beq @apart
@bx_lt

    ; --- y axis ---
    lda X16_P5
    clc
    adc X16_P7                  ; by + bh
    bcs @ay_lt
    cmp X16_P1
    bcc @apart
    beq @apart
@ay_lt
    lda X16_P1
    clc
    adc X16_P3                  ; ay + ah
    bcs @by_lt
    cmp X16_P5
    bcc @apart
    beq @apart
@by_lt

    sec
    rts
@apart
    clc
    rts

}   ; !zone x16_collide
