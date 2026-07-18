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
; gfx_pset clips. The line/rect primitives do NOT: they assume
; their arguments are on screen. Clipping every span would cost more
; than it saves for a caller that already knows its geometry.
;
; Nothing here changes the screen mode. Call gfx_init once to switch the
; display to bitmap mode; the drawing routines only touch VRAM, so they
; also work on an off-screen buffer.
; =====================================================================

; (zone: file scope in dasm)

GFX_WIDTH  = 320
GFX_HEIGHT = 240

; ---------------------------------------------------------------------
; gfx_init  -- 320x240@256c bitmap on layer 0, 40x30 text on layer 1
; gfx_clear -- in: A = colour
; ---------------------------------------------------------------------
    SUBROUTINE
gfx_init
    lda #$80
    jmp screen_set_mode

; 320*240 = 76800 bytes does not fit vera_fill's 16-bit count (passing
; it naively truncates to $2C00 and clears only the top 35 rows), so
; clear in two halves; port 0 keeps auto-incrementing between calls.
    SUBROUTINE
gfx_clear
    pha
    vera_addr 0, VRAM_BITMAP, VERA_INC_1
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
    SUBROUTINE
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
    SUBROUTINE
gfx_pset
    lda X16_P2
    cmp #GFX_HEIGHT
    bcs .off                    ; y >= 240

    lda X16_P1                  ; x high byte
    beq .on                     ; x < 256, always on screen
    cmp #1
    bne .off                    ; x >= 512
    lda X16_P0
    cmp #<GFX_WIDTH             ; 320 = $140, so x low must be < $40
    bcs .off
.on
    lda #VERA_INC_0
    jsr gfx_setptr
    lda X16_P3
    sta VERA_DATA0
.off
    rts

; ---------------------------------------------------------------------
; gfx_hline -- in: X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;                  X16_P4/P5 = length
; ---------------------------------------------------------------------
    SUBROUTINE
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
    SUBROUTINE
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
    SUBROUTINE
gfx_rect
.row
    lda X16_P6
    beq .done
    jsr gfx_hline               ; leaves P0..P5 alone
    inc X16_P2
    dec X16_P6
    bra .row
.done
    rts

; ---------------------------------------------------------------------
; gfx_frame -- rectangle outline
;   same arguments as gfx_rect
; ---------------------------------------------------------------------
    SUBROUTINE
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
    bne .no_borrow
    dec X16_P1
.no_borrow
    dec X16_P0
    jsr gfx_vline

    rts

; x, y, colour, width -- arguments for gfx_hline
    SUBROUTINE
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
    SUBROUTINE
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
    SUBROUTINE
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
    bpl .dx_pos
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
    bra .dx_done
.dx_pos
    lda #$01
    sta gl_sx
    stz gl_sx+1
.dx_done

    ; dy = -|y1 - y0|, sy = sign
    sec
    lda gl_y1
    sbc gl_y0
    bpl .dy_pos
    eor #$FF
    clc
    adc #1                      ; absolute value
    sta gl_tmp
    lda #$FF
    sta gl_sy
    bra .dy_done
.dy_pos
    sta gl_tmp
    lda #$01
    sta gl_sy
.dy_done
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

.loop
    jsr bitmap_plot

    lda gl_x0                   ; reached the end point?
    cmp gl_x1
    bne .step
    lda gl_x0+1
    cmp gl_x1+1
    bne .step
    lda gl_y0
    cmp gl_y1
    bne .step
    rts

.step
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
    bvc .nv1
    eor #$80                    ; signed compare: fold overflow into sign
.nv1
    bmi .skip_x
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
.skip_x

    ; if e2 <= dx  ->  err += dx, y0 += sy
    sec
    lda gl_dx
    sbc gl_e2
    lda gl_dx+1
    sbc gl_e2+1
    bvc .nv2
    eor #$80
.nv2
    bmi .skip_y
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
.skip_y
    jmp .loop

; plot (gl_x0, gl_y0) in gl_color
    SUBROUTINE
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
;   ASCII letters are converted to screen codes ('A-'Z work as
;   expected); X16_P0/P1 are left one past the final character.
; ---------------------------------------------------------------------
    SUBROUTINE
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
.fetch
    lda VERA_DATA1
    sta gt_glyph,x
    inx
    cpx #8
    bne .fetch
    vera_addrsel 0

    lda X16_P0                  ; park the caller's position
    sta gt_bx
    lda X16_P1
    sta gt_bx+1
    lda X16_P2
    sta gt_by

    stz gt_row
.rows
    ldx gt_row
    lda gt_glyph,x
    sta gt_bits
    beq .next_row               ; a blank row: nothing to plot
    stz gt_col
.cols
    asl gt_bits                 ; leftmost pixel first
    bcc .next_col
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
    bcs .next_col               ; wrapped past 255: off screen
    sta X16_P2
    jsr gfx_pset
.next_col
    inc gt_col
    lda gt_col
    cmp #8
    bne .cols
.next_row
    inc gt_row
    lda gt_row
    cmp #8
    bne .rows

    lda gt_bx                   ; restore the caller's block
    sta X16_P0
    lda gt_bx+1
    sta X16_P1
    lda gt_by
    sta X16_P2
    rts

    SUBROUTINE
gfx_text
    sta bitmap_gt_lda+1               ; the string pointer lives in the lda's
    stx bitmap_gt_lda+2               ; own operand (no zero page needed)
    SUBROUTINE
gtx_tloop
    SUBROUTINE
bitmap_gt_lda
    lda $FFFF                   ; operand patched above and stepped below
    beq gtx_tdone
    ; ASCII -> screen code: bit 6 set means letters/at-sign block
    bit #%01000000
    beq gtx_code_ok
    and #$1F
    SUBROUTINE
gtx_code_ok
    jsr gfx_char
    clc                         ; advance the pen 8 pixels
    lda X16_P0
    adc #8
    sta X16_P0
    lda X16_P1
    adc #0
    sta X16_P1
    inc bitmap_gt_lda+1
    bne gtx_tloop
    inc bitmap_gt_lda+2
    bra gtx_tloop
    SUBROUTINE
gtx_tdone
    rts

    SUBROUTINE
gt_code  dc.b 0
    SUBROUTINE
gt_hi    dc.b 0
    SUBROUTINE
gt_glyph ds 8, 0
    SUBROUTINE
gt_bx    dc.w 0
    SUBROUTINE
gt_by    dc.b 0
    SUBROUTINE
gt_row   dc.b 0
    SUBROUTINE
gt_col   dc.b 0
    SUBROUTINE
gt_bits  dc.b 0

; ---------------------------------------------------------------------
; Module variables. Kept out of zero page: these are only touched by
; the routine that owns them, never across a call boundary.
; ---------------------------------------------------------------------
    SUBROUTINE
gb_x    dc.w 0
    SUBROUTINE
gb_y    dc.b 0
    SUBROUTINE
gb_w    dc.w 0
    SUBROUTINE
gb_h    dc.b 0
    SUBROUTINE
gb_c    dc.b 0

    SUBROUTINE
gl_x0    dc.w 0
    SUBROUTINE
gl_y0    dc.b 0
    SUBROUTINE
gl_x1    dc.w 0
    SUBROUTINE
gl_y1    dc.b 0
    SUBROUTINE
gl_color dc.b 0
    SUBROUTINE
gl_dx    dc.w 0
    SUBROUTINE
gl_dy    dc.w 0
    SUBROUTINE
gl_err   dc.w 0
    SUBROUTINE
gl_e2    dc.w 0
    SUBROUTINE
gl_sx    dc.w 0
    SUBROUTINE
gl_sy    dc.b 0
    SUBROUTINE
gl_tmp   dc.b 0

; (end zone)
