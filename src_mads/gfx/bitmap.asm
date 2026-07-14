;ACME
; =====================================================================
; x16lib :: gfx/bitmap.asm -- 320x240x256 bitmap drawing
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; Requires X16_USE_VERA (uses vera_fill).
;
; The framebuffer is 8bpp at VRAM $00000, one byte per pixel, rows of
; 320. A pixel is at y*320 + x.
;
; gfx_pset clips. The line/rect/circle primitives do NOT: they assume
; their arguments are on screen. Clipping every span would cost more
; than it saves for a caller that already knows its geometry.
;
; Nothing here changes the screen mode. Call gfx_init once to switch the
; display to bitmap mode; the drawing routines only touch VRAM, so they
; also work on an off-screen buffer.
; =====================================================================


GFX_WIDTH  = 320
GFX_HEIGHT = 240

; ---------------------------------------------------------------------
; gfx_init  -- 320x240@256c bitmap on layer 0, 40x30 text on layer 1
; gfx_clear -- in: A = colour
; ---------------------------------------------------------------------
gfx_init
    lda #$80
    jmp screen_set_mode

; 320*240 = 76800 bytes does not fit vera_fill's 16-bit count (passing
; it naively truncates to $2C00 and clears only the top 35 rows), so
; clear in two halves; port 0 keeps auto-incrementing between calls.
gfx_clear
    pha
    vera_addr 0,VRAM_BITMAP,VERA_INC_1
    pla
    pha
    ldx #<(GFX_WIDTH * GFX_HEIGHT / 2)
    ldy #>(GFX_WIDTH * GFX_HEIGHT / 2)
    jsr vera_fill
    pla
    ldx #<(GFX_WIDTH * GFX_HEIGHT / 2)
    ldy #>(GFX_WIDTH * GFX_HEIGHT / 2)
    jmp vera_fill

; ---------------------------------------------------------------------
; gfx_setptr -- point data port 0 at pixel (x,y)
;   in:  A = increment index (VERA_INC_*)
;        X16_P0/P1 = x, X16_P2 = y
;
; y*320 = (y<<8) + (y<<6), so no multiply is needed. Result is 17-bit.
; Stepping by VERA_INC_320 then walks straight down a column.
; ---------------------------------------------------------------------
gfx_setptr
    asl
    asl
    asl
    asl
    sta X16_T5                  ; increment field, pre-shifted

    lda X16_P2                  ; y << 6
    stz X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    sta X16_T4                  ; T4/T3 = y*64

    clc                         ; + y<<8, whose low byte is zero
    lda X16_T4
    sta X16_T0
    lda X16_P2
    adc X16_T3
    sta X16_T1
    lda #0
    adc #0
    sta X16_T2                  ; T2:T1:T0 = y*320

    clc                         ; + x
    lda X16_T0
    adc X16_P0
    sta X16_T0
    lda X16_T1
    adc X16_P1
    sta X16_T1
    lda X16_T2
    adc #0
    sta X16_T2

    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda X16_T2
    and #VERA_ADDR_H_BANK
    ora X16_T5
    sta VERA_ADDR_H
    rts

; ---------------------------------------------------------------------
; gfx_pset -- set one pixel, clipped
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour
; ---------------------------------------------------------------------
gfx_pset
    lda X16_P2
    cmp #GFX_HEIGHT
    bcs gfx_pset__off                    ; y >= 240

    lda X16_P1                  ; x high byte
    beq gfx_pset__on                     ; x < 256, always on screen
    cmp #1
    bne gfx_pset__off                    ; x >= 512
    lda X16_P0
    cmp #<GFX_WIDTH             ; 320 = $140, so x low must be < $40
    bcs gfx_pset__off
gfx_pset__on
    lda #VERA_INC_0
    jsr gfx_setptr
    lda X16_P3
    sta VERA_DATA0
gfx_pset__off
    rts

; ---------------------------------------------------------------------
; gfx_hline -- in: X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;                  X16_P4/P5 = length
; ---------------------------------------------------------------------
gfx_hline
    lda #VERA_INC_1
    jsr gfx_setptr
    lda X16_P3
    ldx X16_P4
    ldy X16_P5
    jmp vera_fill

; ---------------------------------------------------------------------
; gfx_vline -- in: X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;                  X16_P4 = length (1-255)
;
; VERA_INC_320 is one of the hardware's odd increments, so a vertical
; line is the same tight loop as a horizontal one.
; ---------------------------------------------------------------------
gfx_vline
    lda #VERA_INC_320
    jsr gfx_setptr
    lda X16_P3
    ldx X16_P4
    ldy #0
    jmp vera_fill

; ---------------------------------------------------------------------
; gfx_rect -- filled rectangle
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;        X16_P4/P5 = width, X16_P6 = height
; ---------------------------------------------------------------------
gfx_rect
gfx_rect__row
    lda X16_P6
    beq gfx_rect__done
    jsr gfx_hline               ; leaves P0..P5 alone
    inc X16_P2
    dec X16_P6
    bra gfx_rect__row
gfx_rect__done
    rts

; ---------------------------------------------------------------------
; gfx_frame -- rectangle outline
;   same arguments as gfx_rect
; ---------------------------------------------------------------------
gfx_frame
    ; Take a private copy of everything: gfx_vline reuses P4 as its
    ; length, which is where the caller's width lives.
    lda X16_P0
    sta gb_x
    lda X16_P1
    sta gb_x+1
    lda X16_P2
    sta gb_y
    lda X16_P3
    sta gb_c
    lda X16_P4
    sta gb_w
    lda X16_P5
    sta gb_w+1
    lda X16_P6
    sta gb_h

    jsr bitmap_restore_span           ; top edge
    jsr gfx_hline

    jsr bitmap_restore_span           ; bottom edge, y + h - 1
    clc
    lda gb_y
    adc gb_h
    sec
    sbc #1
    sta X16_P2
    jsr gfx_hline

    jsr bitmap_restore_col            ; left edge
    jsr gfx_vline

    jsr bitmap_restore_col            ; right edge, x + w - 1
    clc
    lda gb_x
    adc gb_w
    sta X16_P0
    lda gb_x+1
    adc gb_w+1
    sta X16_P1
    lda X16_P0
    bne gfx_frame__no_borrow
    dec X16_P1
gfx_frame__no_borrow
    dec X16_P0
    jsr gfx_vline

    rts

; x, y, colour, width -- arguments for gfx_hline
bitmap_restore_span
    lda gb_x
    sta X16_P0
    lda gb_x+1
    sta X16_P1
    lda gb_y
    sta X16_P2
    lda gb_c
    sta X16_P3
    lda gb_w
    sta X16_P4
    lda gb_w+1
    sta X16_P5
    rts

; x, y, colour, height -- arguments for gfx_vline
bitmap_restore_col
    lda gb_x
    sta X16_P0
    lda gb_x+1
    sta X16_P1
    lda gb_y
    sta X16_P2
    lda gb_c
    sta X16_P3
    lda gb_h
    sta X16_P4
    rts

; ---------------------------------------------------------------------
; gfx_line -- Bresenham, any direction
;   in:  X16_P0/P1 = x0, X16_P2 = y0
;        X16_P3/P4 = x1, X16_P5 = y1
;        X16_P6    = colour
;
; Works entirely from its own variables, because gfx_pset wants the
; colour in X16_P3 -- which is where x1 lives on entry.
; ---------------------------------------------------------------------
gfx_line
    lda X16_P0
    sta gl_x0
    lda X16_P1
    sta gl_x0+1
    lda X16_P2
    sta gl_y0
    lda X16_P3
    sta gl_x1
    lda X16_P4
    sta gl_x1+1
    lda X16_P5
    sta gl_y1
    lda X16_P6
    sta gl_color

    ; dx = |x1 - x0|, sx = sign
    sec
    lda gl_x1
    sbc gl_x0
    sta gl_dx
    lda gl_x1+1
    sbc gl_x0+1
    sta gl_dx+1
    bpl gfx_line__dx_pos
    sec
    lda #0
    sbc gl_dx
    sta gl_dx
    lda #0
    sbc gl_dx+1
    sta gl_dx+1
    lda #$FF
    sta gl_sx
    sta gl_sx+1                 ; -1, sign extended
    bra gfx_line__dx_done
gfx_line__dx_pos
    lda #$01
    sta gl_sx
    stz gl_sx+1
gfx_line__dx_done

    ; dy = -|y1 - y0|, sy = sign
    sec
    lda gl_y1
    sbc gl_y0
    bpl gfx_line__dy_pos
    eor #$FF
    clc
    adc #1                      ; absolute value
    sta gl_tmp
    lda #$FF
    sta gl_sy
    bra gfx_line__dy_done
gfx_line__dy_pos
    sta gl_tmp
    lda #$01
    sta gl_sy
gfx_line__dy_done
    sec
    lda #0
    sbc gl_tmp
    sta gl_dy
    lda #0
    sbc #0
    sta gl_dy+1                 ; gl_dy = -|dy|, 16-bit signed

    clc                         ; err = dx + dy
    lda gl_dx
    adc gl_dy
    sta gl_err
    lda gl_dx+1
    adc gl_dy+1
    sta gl_err+1

gfx_line__loop
    jsr bitmap_plot

    lda gl_x0                   ; reached the end point?
    cmp gl_x1
    bne gfx_line__step
    lda gl_x0+1
    cmp gl_x1+1
    bne gfx_line__step
    lda gl_y0
    cmp gl_y1
    bne gfx_line__step
    rts

gfx_line__step
    lda gl_err                  ; e2 = err * 2
    asl
    sta gl_e2
    lda gl_err+1
    rol
    sta gl_e2+1

    ; if e2 >= dy  ->  err += dy, x0 += sx
    sec
    lda gl_e2
    sbc gl_dy
    lda gl_e2+1
    sbc gl_dy+1
    bvc gfx_line__nv1
    eor #$80                    ; signed compare: fold overflow into sign
gfx_line__nv1
    bmi gfx_line__skip_x
    clc
    lda gl_err
    adc gl_dy
    sta gl_err
    lda gl_err+1
    adc gl_dy+1
    sta gl_err+1
    clc
    lda gl_x0
    adc gl_sx
    sta gl_x0
    lda gl_x0+1
    adc gl_sx+1
    sta gl_x0+1
gfx_line__skip_x

    ; if e2 <= dx  ->  err += dx, y0 += sy
    sec
    lda gl_dx
    sbc gl_e2
    lda gl_dx+1
    sbc gl_e2+1
    bvc gfx_line__nv2
    eor #$80
gfx_line__nv2
    bmi gfx_line__skip_y
    clc
    lda gl_err
    adc gl_dx
    sta gl_err
    lda gl_err+1
    adc gl_dx+1
    sta gl_err+1
    clc
    lda gl_y0
    adc gl_sy
    sta gl_y0
gfx_line__skip_y
    jmp gfx_line__loop

; plot (gl_x0, gl_y0) in gl_color
bitmap_plot
    lda gl_x0
    sta X16_P0
    lda gl_x0+1
    sta X16_P1
    lda gl_y0
    sta X16_P2
    lda gl_color
    sta X16_P3
    jmp gfx_pset

; ---------------------------------------------------------------------
; gfx_circle -- midpoint circle outline
;   in:  X16_P0/P1 = centre x, X16_P2 = centre y, X16_P3 = colour,
;        X16_P4 = radius (0-120)
;
; Plots through gfx_pset, so the circle clips at every screen edge for
; free. Preserves X16_P0..P4.
; ---------------------------------------------------------------------
gfx_circle
    jsr bitmap_c_setup
    lda gc_r
    bne gfx_circle__go
    lda gc_cx                   ; radius 0: a single point
    sta X16_P0
    lda gc_cx+1
    sta X16_P1
    lda gc_cy
    sta X16_P2
    jsr gfx_pset
    jmp bitmap_c_restore
gfx_circle__go
    ; x = r, y = 0, err = 1 - r
    lda gc_r
    sta gc_x
    stz gc_y
    sec
    lda #1
    sbc gc_r
    sta gc_err
    lda #0
    sbc #0
    sta gc_err+1

gfx_circle__loop
    lda gc_x                    ; the 8 octant points
    ldy gc_y
    jsr bitmap_c_plot4
    lda gc_y
    ldy gc_x
    jsr bitmap_c_plot4

    inc gc_y
    lda gc_err+1                ; err < 0 ?
    bmi gfx_circle__err_neg
    dec gc_x                    ; no: also step x inward,
    sec                         ; err += 2*(y - x) + 1
    lda gc_y
    sbc gc_x
    sta X16_T0
    lda #0
    sbc #0
    sta X16_T1
    asl X16_T0
    rol X16_T1
    inc X16_T0
    bne gfx_circle__add_err
    inc X16_T1
gfx_circle__add_err
    clc
    lda gc_err
    adc X16_T0
    sta gc_err
    lda gc_err+1
    adc X16_T1
    sta gc_err+1
    bra gfx_circle__cont
gfx_circle__err_neg
    lda gc_y                    ; err += 2*y + 1
    stz X16_T1
    asl
    rol X16_T1
    inc
    bne gfx_circle__add2
    inc X16_T1
gfx_circle__add2
    clc
    adc gc_err
    sta gc_err
    lda gc_err+1
    adc X16_T1
    sta gc_err+1
gfx_circle__cont
    lda gc_y
    cmp gc_x
    bcc gfx_circle__loop
    beq gfx_circle__loop_last
    jmp bitmap_c_restore
gfx_circle__loop_last
    lda gc_x                    ; the final x == y diagonal points
    ldy gc_y
    jsr bitmap_c_plot4
    jmp bitmap_c_restore

; ---------------------------------------------------------------------
; gfx_disc -- filled circle
;   same arguments as gfx_circle. Draws horizontal spans clamped to
;   the screen, so it clips too. Preserves X16_P0..P4.
; ---------------------------------------------------------------------
gfx_disc
    jsr bitmap_c_setup
    lda gc_r
    sta gc_x
    stz gc_y
    sec
    lda #1
    sbc gc_r
    sta gc_err
    lda #0
    sbc #0
    sta gc_err+1

gfx_disc__dloop
    lda gc_x                    ; spans at cy+/-y, half-width x
    ldy gc_y
    jsr bitmap_c_span2
    lda gc_y                    ; spans at cy+/-x, half-width y
    ldy gc_x
    jsr bitmap_c_span2

    inc gc_y
    lda gc_err+1
    bmi gfx_disc__derr_neg
    dec gc_x
    sec
    lda gc_y
    sbc gc_x
    sta X16_T0
    lda #0
    sbc #0
    sta X16_T1
    asl X16_T0
    rol X16_T1
    inc X16_T0
    bne gfx_disc__dadd
    inc X16_T1
gfx_disc__dadd
    clc
    lda gc_err
    adc X16_T0
    sta gc_err
    lda gc_err+1
    adc X16_T1
    sta gc_err+1
    bra gfx_disc__dcont
gfx_disc__derr_neg
    lda gc_y
    stz X16_T1
    asl
    rol X16_T1
    inc
    bne gfx_disc__dadd2
    inc X16_T1
gfx_disc__dadd2
    clc
    adc gc_err
    sta gc_err
    lda gc_err+1
    adc X16_T1
    sta gc_err+1
gfx_disc__dcont
    lda gc_y
    cmp gc_x
    bcc gfx_disc__dloop
    beq gfx_disc__dloop_last
    jmp bitmap_c_restore
gfx_disc__dloop_last
    lda gc_x
    ldy gc_y
    jsr bitmap_c_span2
    jmp bitmap_c_restore

; --- circle plumbing --------------------------------------------------

bitmap_c_setup
    lda X16_P0
    sta gc_cx
    sta gc_sav
    lda X16_P1
    sta gc_cx+1
    sta gc_sav+1
    lda X16_P2
    sta gc_cy
    sta gc_sav+2
    lda X16_P4
    sta gc_r
    sta gc_sav+3
    rts

bitmap_c_restore
    lda gc_sav
    sta X16_P0
    lda gc_sav+1
    sta X16_P1
    lda gc_sav+2
    sta X16_P2
    lda gc_sav+3
    sta X16_P4
    rts

; plot (cx +/- A, cy +/- Y): the four reflections of one octant point
bitmap_c_plot4
    sta gc_ox
    sty gc_oy
    jsr bitmap_c_ypl
    bcs gfx_disc__p4_low
    jsr bitmap_c_xpl
    jsr gfx_pset
    jsr bitmap_c_xmi
    jsr gfx_pset
gfx_disc__p4_low
    jsr bitmap_c_ymi
    bcs gfx_disc__p4_done
    jsr bitmap_c_xpl
    jsr gfx_pset
    jsr bitmap_c_xmi
    jsr gfx_pset
gfx_disc__p4_done
    rts

; two clamped horizontal spans: rows cy +/- Y, half-width A
bitmap_c_span2
    sta gc_ox
    sty gc_oy
    jsr bitmap_c_ypl
    bcs gfx_disc__s2_lower
    jsr bitmap_c_hspan
gfx_disc__s2_lower
    lda gc_oy
    beq gfx_disc__s2_done                ; same row twice: skip the mirror
    jsr bitmap_c_ymi
    bcs gfx_disc__s2_done
    jsr bitmap_c_hspan
gfx_disc__s2_done
    rts

; X16_P2 already holds the row: draw cx-gc_ox .. cx+gc_ox clamped
bitmap_c_hspan
    sec                         ; left = cx - ox, clamped to 0
    lda gc_cx
    sbc gc_ox
    sta X16_T0
    lda gc_cx+1
    sbc #0
    sta X16_T1
    bpl gfx_disc__left_ok
    stz X16_T0
    stz X16_T1
gfx_disc__left_ok
    clc                         ; right = cx + ox, clamped to 319
    lda gc_cx
    adc gc_ox
    sta X16_T2
    lda gc_cx+1
    adc #0
    sta X16_T3
    ; right >= 320 ?
    lda X16_T3
    cmp #>320
    bcc gfx_disc__right_ok
    bne gfx_disc__clamp_r
    lda X16_T2
    cmp #<320
    bcc gfx_disc__right_ok
gfx_disc__clamp_r
    lda #<319
    sta X16_T2
    lda #>319
    sta X16_T3
gfx_disc__right_ok
    ; entirely off screen?
    sec
    lda X16_T2
    sbc X16_T0
    sta X16_T4
    lda X16_T3
    sbc X16_T1
    sta X16_T5
    bmi gfx_disc__off
    inc X16_T4                  ; length = right - left + 1
    bne gfx_disc__len_ok
    inc X16_T5
gfx_disc__len_ok
    lda X16_T0
    sta X16_P0
    lda X16_T1
    sta X16_P1
    lda X16_T4
    sta X16_P4
    lda X16_T5
    sta X16_P5
    jmp gfx_hline
gfx_disc__off
    rts

; X16_P2 = cy + gc_oy; carry set if the row is off screen (>255).
; Rows 240-255 are left to gfx_pset/vera_fill? No -- reject them here.
bitmap_c_ypl
    clc
    lda gc_cy
    adc gc_oy
    bcs gfx_disc__ypl_bad                ; past 255
    cmp #GFX_HEIGHT
    bcs gfx_disc__ypl_bad                ; 240..255
    sta X16_P2
    clc
    rts
gfx_disc__ypl_bad
    sec
    rts

; X16_P2 = cy - gc_oy; carry set if above the screen.
bitmap_c_ymi
    sec
    lda gc_cy
    sbc gc_oy
    bcc gfx_disc__ymi_bad
    sta X16_P2
    clc
    rts
gfx_disc__ymi_bad
    sec
    rts

bitmap_c_xpl
    clc
    lda gc_cx
    adc gc_ox
    sta X16_P0
    lda gc_cx+1
    adc #0
    sta X16_P1
    rts

bitmap_c_xmi
    sec
    lda gc_cx
    sbc gc_ox
    sta X16_P0
    lda gc_cx+1
    sbc #0
    sta X16_P1
    rts

gc_cx  .word 0
gc_cy  .byte 0
gc_r   .byte 0
gc_x   .byte 0
gc_y   .byte 0
gc_ox  .byte 0
gc_oy  .byte 0
gc_err .word 0
gc_sav
    :(4) dta 0

; ---------------------------------------------------------------------
; gfx_char -- draw one glyph from the VRAM charset into the bitmap
;   in:  A = screen code (0-255)
;        X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour
;
; Reads the 8-byte 1bpp glyph from the charset the KERNAL keeps at
; VRAM $1F000; set bits become colour pixels through gfx_pset (so text
; clips), clear bits stay transparent. Preserves X16_P0..P3.
;
; gfx_text -- a NUL-terminated string, 8 pixels per character
;   in:  A = string low, X = string high; X16_P0..P3 as above.
;   ASCII letters are converted to screen codes ('A'-'Z' work as
;   expected); X16_P0/P1 are left one past the final character.
; ---------------------------------------------------------------------
gfx_char
    ; glyph address = VRAM_CHARSET + code * 8  (17-bit)
    sta gt_code
    stz gt_hi
    asl
    rol gt_hi
    asl
    rol gt_hi
    asl
    rol gt_hi                   ; gt_hi:A = code * 8
    pha
    vera_addrsel 1
    pla
    sta VERA_ADDR_L
    lda gt_hi
    clc
    adc #<(VRAM_CHARSET >> 8)
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))   ; $1F000 is in bank 1
    sta VERA_ADDR_H
    ldx #0
gfx_char__fetch
    lda VERA_DATA1
    sta gt_glyph,x
    inx
    cpx #8
    bne gfx_char__fetch
    vera_addrsel 0

    lda X16_P0                  ; park the caller's position
    sta gt_bx
    lda X16_P1
    sta gt_bx+1
    lda X16_P2
    sta gt_by

    stz gt_row
gfx_char__rows
    ldx gt_row
    lda gt_glyph,x
    sta gt_bits
    beq gfx_char__next_row               ; a blank row: nothing to plot
    stz gt_col
gfx_char__cols
    asl gt_bits                 ; leftmost pixel first
    bcc gfx_char__next_col
    clc
    lda gt_bx
    adc gt_col
    sta X16_P0
    lda gt_bx+1
    adc #0
    sta X16_P1
    clc
    lda gt_by
    adc gt_row
    bcs gfx_char__next_col               ; wrapped past 255: off screen
    sta X16_P2
    jsr gfx_pset
gfx_char__next_col
    inc gt_col
    lda gt_col
    cmp #8
    bne gfx_char__cols
gfx_char__next_row
    inc gt_row
    lda gt_row
    cmp #8
    bne gfx_char__rows

    lda gt_bx                   ; restore the caller's block
    sta X16_P0
    lda gt_bx+1
    sta X16_P1
    lda gt_by
    sta X16_P2
    rts

gfx_text
    sta bitmap_gt_lda+1               ; the string pointer lives in the lda's
    stx bitmap_gt_lda+2               ; own operand (no zero page needed)
gfx_text__tloop
bitmap_gt_lda
    lda $FFFF                   ; operand patched above and stepped below
    beq gfx_text__tdone
    ; ASCII -> screen code: bit 6 set means letters/at-sign block
    bit #%01000000
    beq gfx_text__code_ok
    and #$1F
gfx_text__code_ok
    jsr gfx_char
    clc                         ; advance the pen 8 pixels
    lda X16_P0
    adc #8
    sta X16_P0
    lda X16_P1
    adc #0
    sta X16_P1
    inc bitmap_gt_lda+1
    bne gfx_text__tloop
    inc bitmap_gt_lda+2
    bra gfx_text__tloop
gfx_text__tdone
    rts

gt_code  .byte 0
gt_hi    .byte 0
gt_glyph
    :(8) dta 0
gt_bx    .word 0
gt_by    .byte 0
gt_row   .byte 0
gt_col   .byte 0
gt_bits  .byte 0

; ---------------------------------------------------------------------
; gfx_flood -- scanline flood fill
;   in:  X16_P0/P1 = seed x, X16_P2 = seed y, X16_P3 = fill colour
;   out: carry clear = filled completely; carry set = the span stack
;        overflowed and the fill is INCOMPLETE (pathological shapes:
;        the stack holds 170 pending spans)
;
; Fills the 4-connected region of the seed's colour. Filling with the
; colour already under the seed is a no-op. Spans are painted with
; gfx_hline; both VERA ports get repointed freely.
; ---------------------------------------------------------------------
FF_DEPTH = 170

gfx_flood
    lda X16_P2                  ; a seed off screen fills nothing
    cmp #GFX_HEIGHT
    bcs gfx_flood__bail
    lda X16_P1
    beq gfx_flood__seed_ok
    cmp #1
    bne gfx_flood__bail
    lda X16_P0
    cmp #<GFX_WIDTH
    bcc gfx_flood__seed_ok
gfx_flood__bail
    clc
    rts
gfx_flood__seed_ok
    lda X16_P3
    sta ff_col
    lda X16_P0
    sta ff_x
    lda X16_P1
    sta ff_x+1
    lda X16_P2
    sta ff_y

    jsr bitmap_f_rd                   ; the colour being replaced
    sta ff_tgt
    cmp ff_col
    beq gfx_flood__bail                   ; already the fill colour: no-op

    stz ff_sp
    stz ff_ovf
    lda ff_x
    sta ff_px
    lda ff_x+1
    sta ff_px+1
    lda ff_y
    sta ff_ny
    jsr bitmap_f_push

gfx_flood__main
    lda ff_sp
    bne gfx_flood__have_work
    jmp gfx_flood__finish
gfx_flood__have_work
    jsr bitmap_f_pop                  ; -> ff_x / ff_y
    jsr bitmap_f_rd
    cmp ff_tgt
    bne gfx_flood__main                   ; painted over since it was queued

    ; grow the span left: xl = leftmost target pixel
    lda ff_x
    sta ff_xl
    lda ff_x+1
    sta ff_xl+1
    lda ff_xl
    ora ff_xl+1
    beq gfx_flood__left_done
    sec                         ; walk from xl-1 downwards
    lda ff_xl
    sbc #1
    sta ff_ax
    lda ff_xl+1
    sbc #0
    sta ff_ax+1
    lda ff_y
    sta ff_ay
    lda #VERA_ADDR_H_DECR
    jsr bitmap_f_addr1
gfx_flood__left_scan
    lda VERA_DATA1
    cmp ff_tgt
    bne gfx_flood__left_done
    lda ff_xl
    bne gfx_flood__left_dec
    dec ff_xl+1
gfx_flood__left_dec
    dec ff_xl
    lda ff_xl
    ora ff_xl+1
    bne gfx_flood__left_scan
gfx_flood__left_done

    ; grow the span right: xr = rightmost target pixel
    lda ff_x
    sta ff_xr
    lda ff_x+1
    sta ff_xr+1
    jsr bitmap_f_at_right
    bcs gfx_flood__right_done
    clc                         ; walk from xr+1 upwards
    lda ff_xr
    adc #1
    sta ff_ax
    lda ff_xr+1
    adc #0
    sta ff_ax+1
    lda ff_y
    sta ff_ay
    lda #0
    jsr bitmap_f_addr1
gfx_flood__right_scan
    lda VERA_DATA1
    cmp ff_tgt
    bne gfx_flood__right_done
    inc ff_xr
    bne gfx_flood__right_chk
    inc ff_xr+1
gfx_flood__right_chk
    jsr bitmap_f_at_right
    bcc gfx_flood__right_scan
gfx_flood__right_done

    ; paint it
    lda ff_xl
    sta X16_P0
    lda ff_xl+1
    sta X16_P1
    lda ff_y
    sta X16_P2
    lda ff_col
    sta X16_P3
    sec                         ; length = xr - xl + 1
    lda ff_xr
    sbc ff_xl
    sta X16_P4
    lda ff_xr+1
    sbc ff_xl+1
    sta X16_P5
    inc X16_P4
    bne gfx_flood__len_ok
    inc X16_P5
gfx_flood__len_ok
    jsr gfx_hline

    ; queue fresh spans in the rows above and below
    lda ff_y
    beq gfx_flood__no_up
    dec
    sta ff_ny
    jsr bitmap_f_scanrow
gfx_flood__no_up
    lda ff_y
    cmp #(GFX_HEIGHT - 1)
    bcs gfx_flood__no_down
    inc
    sta ff_ny
    jsr bitmap_f_scanrow
gfx_flood__no_down
    jmp gfx_flood__main

gfx_flood__finish
    vera_addrsel 0
    lda ff_ovf                  ; carry = "the fill may be incomplete"
    lsr
    rts

ff_x   .word 0
ff_y   .byte 0
ff_xl  .word 0
ff_xr  .word 0
ff_px  .word 0
ff_ny  .byte 0
ff_ax  .word 0
ff_ay  .byte 0
ff_h   .byte 0
ff_tgt .byte 0
ff_col .byte 0
ff_seg .byte 0
ff_cnt .word 0
ff_sp  .byte 0
ff_ovf .byte 0

; carry set when ff_xr is the last column (319)
bitmap_f_at_right
    lda ff_xr+1
    cmp #>(GFX_WIDTH - 1)
    bne ff_ovf__below
    lda ff_xr
    cmp #<(GFX_WIDTH - 1)
    bcs ff_ovf__at
ff_ovf__below
    clc
    rts
ff_ovf__at
    sec
    rts

; scan row ff_ny across columns ff_xl..ff_xr, pushing the start of
; every run of target-coloured pixels
bitmap_f_scanrow
    lda ff_xl
    sta ff_ax
    sta ff_px
    lda ff_xl+1
    sta ff_ax+1
    sta ff_px+1
    lda ff_ny
    sta ff_ay
    lda #0
    jsr bitmap_f_addr1
    sec                         ; count = xr - xl + 1
    lda ff_xr
    sbc ff_xl
    sta ff_cnt
    lda ff_xr+1
    sbc ff_xl+1
    sta ff_cnt+1
    inc ff_cnt
    bne ff_ovf__counted
    inc ff_cnt+1
ff_ovf__counted
    stz ff_seg
ff_ovf__cell
    lda VERA_DATA1
    cmp ff_tgt
    bne ff_ovf__break
    lda ff_seg
    bne ff_ovf__step                   ; already inside a run
    jsr bitmap_f_push                 ; a run begins here: remember its start
    lda #1
    sta ff_seg
    bra ff_ovf__step
ff_ovf__break
    stz ff_seg
ff_ovf__step
    inc ff_px
    bne ff_ovf__count
    inc ff_px+1
ff_ovf__count
    lda ff_cnt
    bne ff_ovf__declo
    dec ff_cnt+1
ff_ovf__declo
    dec ff_cnt
    lda ff_cnt
    ora ff_cnt+1
    bne ff_ovf__cell
    rts

ff_stk
    :(FF_DEPTH * 3) dta 0

; push (ff_px, ff_ny); a full stack sets ff_ovf instead
bitmap_f_push
    lda ff_sp
    cmp #FF_DEPTH
    bcc ff_stk__room
    lda #1
    sta ff_ovf
    rts
ff_stk__room
    jsr bitmap_f_slot
    ldy #0
    lda ff_px
    sta (X16_T6),y
    iny
    lda ff_px+1
    sta (X16_T6),y
    iny
    lda ff_ny
    sta (X16_T6),y
    inc ff_sp
    rts

; pop -> ff_x, ff_y
bitmap_f_pop
    dec ff_sp
    jsr bitmap_f_slot
    ldy #0
    lda (X16_T6),y
    sta ff_x
    iny
    lda (X16_T6),y
    sta ff_x+1
    iny
    lda (X16_T6),y
    sta ff_y
    rts

; X16_T6/T7 = &ff_stk[ff_sp * 3]
bitmap_f_slot
    lda ff_sp
    sta X16_T6
    stz X16_T7
    asl X16_T6
    rol X16_T7
    clc
    lda X16_T6
    adc ff_sp
    sta X16_T6
    lda X16_T7
    adc #0
    sta X16_T7
    clc
    lda X16_T6
    adc #<ff_stk
    sta X16_T6
    lda X16_T7
    adc #>ff_stk
    sta X16_T7
    rts

; A = the pixel at (ff_x, ff_y)
bitmap_f_rd
    lda ff_x
    sta ff_ax
    lda ff_x+1
    sta ff_ax+1
    lda ff_y
    sta ff_ay
    lda #0
    jsr bitmap_f_addr1
    lda VERA_DATA1
    rts

; point port 1 at (ff_ax, ff_ay), INC_1, with A's DECR flag
bitmap_f_addr1
    ora #(VERA_INC_1 << 4)
    sta ff_h
    lda ff_ay                   ; ay*320 = ay*64 + ay*256
    stz X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    sta X16_T0
    clc
    lda ff_ay
    adc X16_T1
    sta X16_T1
    lda #0
    adc #0
    sta X16_T2
    clc                         ; + ax
    lda X16_T0
    adc ff_ax
    sta X16_T0
    lda X16_T1
    adc ff_ax+1
    sta X16_T1
    lda X16_T2
    adc #0
    sta X16_T2
    lda #VERA_CTRL_ADDRSEL
    tsb VERA_CTRL
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda X16_T2
    and #VERA_ADDR_H_BANK
    ora ff_h
    sta VERA_ADDR_H
    rts

; ---------------------------------------------------------------------
; Module variables. Kept out of zero page: these are only touched by
; the routine that owns them, never across a call boundary.
; ---------------------------------------------------------------------
gb_x    .word 0
gb_y    .byte 0
gb_w    .word 0
gb_h    .byte 0
gb_c    .byte 0

gl_x0    .word 0
gl_y0    .byte 0
gl_x1    .word 0
gl_y1    .byte 0
gl_color .byte 0
gl_dx    .word 0
gl_dy    .word 0
gl_err   .word 0
gl_e2    .word 0
gl_sx    .word 0
gl_sy    .byte 0
gl_tmp   .byte 0

