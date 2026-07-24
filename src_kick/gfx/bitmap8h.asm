//ACME
// =====================================================================
// x16lib :: gfx/bitmap8h.asm -- VERA_2 640x480x256 SDRAM bitmap drawing
// =====================================================================
// This file EMITS CODE. Source it exactly once (x16_code.asm does).
//
// Requires the MiSTer VERA_2 bitmap layer. The framebuffer is NOT VERA
// VRAM: it is the VERA_2 20-bit SDRAM byte address space behind $9F60-
// $9F6F. Feature-detect with gfx8h_has before relying on it.
//
// The framebuffer is 8bpp, one byte per pixel, rows of 640 bytes:
//   offset = y*640 + x, size = 307,200 bytes ($4B000).
//
// Calling convention follows the high-res engines:
//   X16_P0/P1 = x, X16_P2/P3 = y, colour in A.
// =====================================================================

// (zone: file scope in KickAssembler)

.label GFX8H_WIDTH = 640
.label GFX8H_HEIGHT = 480
.label GFX8H_STRIDE = 640
.label GFX8H_FRAME_PAGES = 1200       // 307200 / 256

// ---------------------------------------------------------------------
// gfx8h_has -- feature-detect the VERA_2 bitmap layer
//   out: carry set if present, carry clear otherwise
// ---------------------------------------------------------------------
gfx8h_has:
    lda VERA2_ID
    cmp #VERA2_ID_MAGIC
    beq gfx8h_has__yes
    clc
    rts
gfx8h_has__yes:
    sec
    rts

// ---------------------------------------------------------------------
// gfx8h_init -- select 640x480@8bpp and load a grayscale palette
// gfx8h_off  -- disable the VERA_2 bitmap layer
// ---------------------------------------------------------------------
gfx8h_init:
    jsr gfx8h_pal_gray
    lda #(VERA2_CTRL_ENABLE | VERA2_CTRL_MODE_8BPP)
    sta VERA2_CTRL
    rts

gfx8h_off:
    stz VERA2_CTRL
    rts

gfx8h_passthru_on:
    lda VERA2_CTRL
    ora #VERA2_CTRL_PASSTHRU
    sta VERA2_CTRL
    rts

gfx8h_passthru_off:
    lda #$FF - VERA2_CTRL_PASSTHRU
    and VERA2_CTRL
    sta VERA2_CTRL
    rts

// ---------------------------------------------------------------------
// gfx8h_pal_set -- set one VERA_2 palette entry
//   in: X = index, A = low byte (G<<4 | B), Y = high byte (R)
// gfx8h_pal_load -- load entries from RAM
//   in: X16_PTR0 = source, A = first index, X = count (0 loads nothing)
// ---------------------------------------------------------------------
gfx8h_pal_set:
    sta g8h_t
    sty g8h_t2
    stx VERA2_PAL_IDX
    lda g8h_t
    sta VERA2_PAL_LO
    lda g8h_t2
    sta VERA2_PAL_HI
    rts

gfx8h_pal_load:
    cpx #0
    beq gfx8h_pal_load__done
    sta VERA2_PAL_IDX
    stx g8h_n
    ldy #0
gfx8h_pal_load__loop:
    lda (X16_PTR0),y
    sta VERA2_PAL_LO
    iny
    lda (X16_PTR0),y
    sta VERA2_PAL_HI
    iny
    dec g8h_n
    bne gfx8h_pal_load__loop
gfx8h_pal_load__done:
    rts

gfx8h_pal_gray:
    stz VERA2_PAL_IDX
    ldx #0
gfx8h_pal_gray__loop:
    txa
    lsr
    lsr
    lsr
    lsr
    sta g8h_t                   // v = index >> 4
    asl
    asl
    asl
    asl
    ora g8h_t
    sta VERA2_PAL_LO            // G = B = v
    lda g8h_t
    sta VERA2_PAL_HI            // R = v
    inx
    bne gfx8h_pal_gray__loop
    rts

// ---------------------------------------------------------------------
// gfx8h_setptr -- point VERA_2 DATA at pixel (x,y)
//   in: A = VERA2_INC_* stride index, X16_P0/P1 = x, X16_P2/P3 = y
// ---------------------------------------------------------------------
gfx8h_setptr:
    asl
    asl
    asl
    asl
    sta g8h_inc
    jsr bitmap8h_addr_calc
    lda g8h_a0
    sta VERA2_ADDR_L
    lda g8h_a1
    sta VERA2_ADDR_M
    lda g8h_a2
    and #$0F
    ora g8h_inc
    sta VERA2_ADDR_H
    rts

// ---------------------------------------------------------------------
// gfx8h_clear -- fill the whole framebuffer with one colour
//   in: A = colour
// ---------------------------------------------------------------------
gfx8h_clear:
    sta g8h_c
    stz VERA2_ADDR_L
    stz VERA2_ADDR_M
    stz VERA2_ADDR_H            // ptr 0, stride +1
    lda #<GFX8H_FRAME_PAGES
    sta g8h_n
    lda #>GFX8H_FRAME_PAGES
    sta g8h_n+1
    lda g8h_c
    jmp bitmap8h_fill_pages

// ---------------------------------------------------------------------
// gfx8h_pset / gfx8h_read -- clipped pixel access
//   pset in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y
//   read out: carry clear, A = colour; carry set if off screen
// ---------------------------------------------------------------------
gfx8h_pset:
    sta g8h_c
    jsr bitmap8h_onscreen
    bcs gfx8h_pset__off
    lda #VERA2_INC_1
    jsr gfx8h_setptr
    lda g8h_c
    sta VERA2_DATA
gfx8h_pset__off:
    rts

gfx8h_read:
    jsr bitmap8h_onscreen
    bcs gfx8h_read__off
    lda #VERA2_INC_0
    jsr gfx8h_setptr
    lda VERA2_DATA
    clc
gfx8h_read__off:
    rts

// ---------------------------------------------------------------------
// gfx8h_hline / gfx8h_vline -- spans, no clipping
//   in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = length
// ---------------------------------------------------------------------
gfx8h_hline:
    sta g8h_c
    lda X16_P4
    sta g8h_n
    lda X16_P5
    sta g8h_n+1
    ora g8h_n
    beq gfx8h_hline__done
    lda #VERA2_INC_1
    jsr gfx8h_setptr
    lda g8h_c
    jsr bitmap8h_fill_count
gfx8h_hline__done:
    rts

gfx8h_vline:
    sta g8h_c
    lda X16_P4
    sta g8h_n
    lda X16_P5
    sta g8h_n+1
    ora g8h_n
    beq gfx8h_vline__done
    lda #VERA2_INC_640
    jsr gfx8h_setptr
    lda g8h_c
    jsr bitmap8h_fill_count
gfx8h_vline__done:
    rts

// ---------------------------------------------------------------------
// gfx8h_rect / gfx8h_frame -- rectangles, no clipping
//   in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y,
//       X16_P4/P5 = width, X16_P6/P7 = height
// ---------------------------------------------------------------------
gfx8h_rect:
    sta g8h_rc
gfx8h_rect__row:
    lda X16_P6
    ora X16_P7
    beq gfx8h_rect__done
    lda g8h_rc
    jsr gfx8h_hline
    inc X16_P2
    bne bitmap8h_k1
    inc X16_P3
bitmap8h_k1:
	lda X16_P6
    bne bitmap8h_k2
    dec X16_P7
bitmap8h_k2:
	dec X16_P6
    bra gfx8h_rect__row
gfx8h_rect__done:
    rts

gfx8h_frame:
    sta g8h_rc
    ldx #7
gfx8h_frame__take:
    lda X16_P0,x
    sta g8h_fx,x
    dex
    bpl gfx8h_frame__take

    jsr bitmap8h_frame_span
    lda g8h_rc
    jsr gfx8h_hline

    jsr bitmap8h_frame_span
    clc
    lda g8h_fy
    adc g8h_rh
    sta X16_P2
    lda g8h_fy+1
    adc g8h_rh+1
    sta X16_P3
    lda X16_P2
    bne bitmap8h_k3
    dec X16_P3
bitmap8h_k3:
	dec X16_P2
    lda g8h_rc
    jsr gfx8h_hline

    jsr bitmap8h_frame_col
    lda g8h_rc
    jsr gfx8h_vline

    jsr bitmap8h_frame_col
    clc
    lda g8h_fx
    adc g8h_rw
    sta X16_P0
    lda g8h_fx+1
    adc g8h_rw+1
    sta X16_P1
    lda X16_P0
    bne bitmap8h_k4
    dec X16_P1
bitmap8h_k4:
	dec X16_P0
    lda g8h_rc
    jmp gfx8h_vline

bitmap8h_frame_span:
    ldx #5
gfx8h_frame__s:
    lda g8h_fx,x
    sta X16_P0,x
    dex
    bpl gfx8h_frame__s
    rts

bitmap8h_frame_col:
    ldx #3
gfx8h_frame__c:
    lda g8h_fx,x
    sta X16_P0,x
    dex
    bpl gfx8h_frame__c
    lda g8h_rh
    sta X16_P4
    lda g8h_rh+1
    sta X16_P5
    rts

// ---------------------------------------------------------------------
// gfx8h_line -- Bresenham line, clipped by gfx8h_pset
//   in: A = colour, P0/P1=x0, P2/P3=y0, P4/P5=x1, P6/P7=y1
// ---------------------------------------------------------------------
gfx8h_line:
    sta g8h_lc
    ldx #7
gfx8h_line__take:
    lda X16_P0,x
    sta g8h_lx0,x
    dex
    bpl gfx8h_line__take

    sec
    lda g8h_lx1
    sbc g8h_lx0
    sta g8h_ldx
    lda g8h_lx1+1
    sbc g8h_lx0+1
    sta g8h_ldx+1
    bpl gfx8h_line__dx_pos
    sec
    lda #0
    sbc g8h_ldx
    sta g8h_ldx
    lda #0
    sbc g8h_ldx+1
    sta g8h_ldx+1
    lda #$FF
    sta g8h_lsx
    sta g8h_lsx+1
    bra gfx8h_line__dx_done
gfx8h_line__dx_pos:
    lda #1
    sta g8h_lsx
    stz g8h_lsx+1
gfx8h_line__dx_done:

    sec
    lda g8h_ly1
    sbc g8h_ly0
    sta g8h_ldy
    lda g8h_ly1+1
    sbc g8h_ly0+1
    sta g8h_ldy+1
    bpl gfx8h_line__dy_pos
    sec
    lda #0
    sbc g8h_ldy
    sta g8h_ldy
    lda #0
    sbc g8h_ldy+1
    sta g8h_ldy+1
    lda #$FF
    sta g8h_lsy
    sta g8h_lsy+1
    bra gfx8h_line__dy_done
gfx8h_line__dy_pos:
    lda #1
    sta g8h_lsy
    stz g8h_lsy+1
gfx8h_line__dy_done:
    sec
    lda #0
    sbc g8h_ldy
    sta g8h_ldy
    lda #0
    sbc g8h_ldy+1
    sta g8h_ldy+1

    clc
    lda g8h_ldx
    adc g8h_ldy
    sta g8h_lerr
    lda g8h_ldx+1
    adc g8h_ldy+1
    sta g8h_lerr+1

gfx8h_line__loop:
    lda g8h_lc
    jsr bitmap8h_plot
    lda g8h_lx0
    cmp g8h_lx1
    bne gfx8h_line__step
    lda g8h_lx0+1
    cmp g8h_lx1+1
    bne gfx8h_line__step
    lda g8h_ly0
    cmp g8h_ly1
    bne gfx8h_line__step
    lda g8h_ly0+1
    cmp g8h_ly1+1
    bne gfx8h_line__step
    rts

gfx8h_line__step:
    lda g8h_lerr
    asl
    sta g8h_le2
    lda g8h_lerr+1
    rol
    sta g8h_le2+1

    sec
    lda g8h_le2
    sbc g8h_ldy
    lda g8h_le2+1
    sbc g8h_ldy+1
    bvc gfx8h_line__nv1
    eor #$80
gfx8h_line__nv1:
    bmi gfx8h_line__skip_x
    clc
    lda g8h_lerr
    adc g8h_ldy
    sta g8h_lerr
    lda g8h_lerr+1
    adc g8h_ldy+1
    sta g8h_lerr+1
    clc
    lda g8h_lx0
    adc g8h_lsx
    sta g8h_lx0
    lda g8h_lx0+1
    adc g8h_lsx+1
    sta g8h_lx0+1
gfx8h_line__skip_x:
    sec
    lda g8h_ldx
    sbc g8h_le2
    lda g8h_ldx+1
    sbc g8h_le2+1
    bvc gfx8h_line__nv2
    eor #$80
gfx8h_line__nv2:
    bmi gfx8h_line__skip_y
    clc
    lda g8h_lerr
    adc g8h_ldx
    sta g8h_lerr
    lda g8h_lerr+1
    adc g8h_ldx+1
    sta g8h_lerr+1
    clc
    lda g8h_ly0
    adc g8h_lsy
    sta g8h_ly0
    lda g8h_ly0+1
    adc g8h_lsy+1
    sta g8h_ly0+1
gfx8h_line__skip_y:
    jmp gfx8h_line__loop

bitmap8h_plot:
    sta g8h_c
    lda g8h_lx0
    sta X16_P0
    lda g8h_lx0+1
    sta X16_P1
    lda g8h_ly0
    sta X16_P2
    lda g8h_ly0+1
    sta X16_P3
    lda g8h_c
    jmp gfx8h_pset

// ---------------------------------------------------------------------
// gfx8h_pattern_set / gfx8h_pattern_rect
// ---------------------------------------------------------------------
gfx8h_pattern_set:
    sta X16_T0
    stx X16_T0+1
    ldy #7
gfx8h_pattern_set__copy:
    lda (X16_T0),y
    sta gp8h_pat,y
    dey
    bpl gfx8h_pattern_set__copy
    lda X16_P4
    sta gp8h_bg
    lda X16_P5
    sta gp8h_fg
    rts

gfx8h_pattern_rect:
    lda X16_P4
    ora X16_P5
    ora X16_P6
    ora X16_P7
    bne bitmap8h_k5
    jmp gfx8h_pattern_rect__done
+
    lda X16_P2
    sta gp8h_by
    lda X16_P3
    sta gp8h_by+1
    lda X16_P0
    sta gp8h_bx
    lda X16_P1
    sta gp8h_bx+1
gfx8h_pattern_rect__row:
    lda X16_P6
    ora X16_P7
    bne bitmap8h_k5
    jmp gfx8h_pattern_rect__done
+
    lda gp8h_bx
    sta gp8h_x
    lda gp8h_bx+1
    sta gp8h_x+1
    lda X16_P4
    sta gp8h_n
    lda X16_P5
    sta gp8h_n+1
    lda X16_P2
    and #7
    tay
    lda gp8h_pat,y
    sta gp8h_bits
gfx8h_pattern_rect__col:
    lda gp8h_n
    ora gp8h_n+1
    beq gfx8h_pattern_rect__next_row
    lda gp8h_bits
    bmi gfx8h_pattern_rect__fg
    lda gp8h_bg
    bra gfx8h_pattern_rect__plot
gfx8h_pattern_rect__fg:
    lda gp8h_fg
gfx8h_pattern_rect__plot:
    sta gp8h_c
    lda gp8h_x
    sta X16_P0
    lda gp8h_x+1
    sta X16_P1
    lda gp8h_by
    sta X16_P2
    lda gp8h_by+1
    sta X16_P3
    lda gp8h_c
    jsr gfx8h_pset
    lda gp8h_bits
    asl
    adc #0
    sta gp8h_bits
    inc gp8h_x
    bne bitmap8h_k5
    inc gp8h_x+1
bitmap8h_k5:
	lda gp8h_n
    bne bitmap8h_k6
    dec gp8h_n+1
bitmap8h_k6:
	dec gp8h_n
    jmp gfx8h_pattern_rect__col
gfx8h_pattern_rect__next_row:
    inc gp8h_by
    bne bitmap8h_k7
    inc gp8h_by+1
bitmap8h_k7:
	lda gp8h_by
    sta X16_P2
    lda gp8h_by+1
    sta X16_P3
    lda X16_P6
    bne bitmap8h_k8
    dec X16_P7
bitmap8h_k8:
	dec X16_P6
    jmp gfx8h_pattern_rect__row
gfx8h_pattern_rect__done:
    rts

// ---------------------------------------------------------------------
// gfx8h_blit / gfx8h_blitm -- RAM to framebuffer, row-major source
//   blit in: A = op (0 copy, 1 OR, 2 AND, 3 XOR)
//   common: P0/P1=x, P2/P3=y, P4=width (1-255), P5=height, P6/P7=source
// ---------------------------------------------------------------------
gfx8h_blit:
    and #3
    sta g8h_op
    bra bitmap8h_blit_common

gfx8h_blitm:
    lda #$80
    sta g8h_op
bitmap8h_blit_common:
    lda X16_P6
    sta X16_PTR3
    lda X16_P7
    sta X16_PTR3+1
gfx8h_blitm__row:
    lda X16_P5
    beq gfx8h_blitm__done
    ldy #0
gfx8h_blitm__col:
    cpy X16_P4
    beq gfx8h_blitm__next_row
    lda (X16_PTR3),y
    sta g8h_ink
    lda g8h_op
    bmi gfx8h_blitm__masked
    beq gfx8h_blitm__copy
    lda #VERA2_INC_0
    jsr gfx8h_setptr
    lda VERA2_DATA
    sta g8h_t
    lda g8h_op
    cmp #1
    beq gfx8h_blitm__or
    cmp #2
    beq gfx8h_blitm__and
    lda g8h_ink
    eor g8h_t
    bra gfx8h_blitm__store
gfx8h_blitm__and:
    lda g8h_ink
    and g8h_t
    bra gfx8h_blitm__store
gfx8h_blitm__or:
    lda g8h_ink
    ora g8h_t
    bra gfx8h_blitm__store
gfx8h_blitm__masked:
    lda g8h_ink
    beq gfx8h_blitm__advance
gfx8h_blitm__copy:
    lda g8h_ink
gfx8h_blitm__store:
    jsr gfx8h_pset
gfx8h_blitm__advance:
    inc X16_P0
    bne bitmap8h_k9
    inc X16_P1
bitmap8h_k9:
	iny
    jmp gfx8h_blitm__col
gfx8h_blitm__next_row:
    sec
    lda X16_P0
    sbc X16_P4
    sta X16_P0
    bcs bitmap8h_k10
    dec X16_P1
bitmap8h_k10:
	clc
    lda X16_PTR3
    adc X16_P4
    sta X16_PTR3
    bcc bitmap8h_k11
    inc X16_PTR3+1
bitmap8h_k11:
	inc X16_P2
    bne bitmap8h_k12
    inc X16_P3
bitmap8h_k12:
	dec X16_P5
    jmp gfx8h_blitm__row
gfx8h_blitm__done:
    rts

// ---------------------------------------------------------------------
// gfx8h_copy -- VERA_2 SDRAM-to-SDRAM hardware copy, then wait
//   in: P0/P1/P2 = source, P3/P4/P5 = destination, A/X/Y = length
// ---------------------------------------------------------------------
gfx8h_copy:
    sta VERA2_BLIT_LEN_L
    stx VERA2_BLIT_LEN_M
    sty VERA2_BLIT_LEN_H
    lda X16_P0
    sta VERA2_ADDR_L
    lda X16_P1
    sta VERA2_ADDR_M
    lda X16_P2
    and #$0F
    sta VERA2_ADDR_H            // source pointer, stride +1
    lda X16_P3
    sta VERA2_BLIT_DST_L
    lda X16_P4
    sta VERA2_BLIT_DST_M
    lda X16_P5
    and #$0F
    sta VERA2_BLIT_DST_H
    lda #1
    sta VERA2_BLIT_CTRL
gfx8h_copy_wait:
    lda VERA2_BLIT_CTRL
    and #1
    bne gfx8h_copy_wait
    rts

// ---------------------------------------------------------------------
// private helpers
// ---------------------------------------------------------------------
bitmap8h_onscreen:
    lda X16_P1
    cmp #>GFX8H_WIDTH
    bcc gfx8h_copy_wait__xok
    bne gfx8h_copy_wait__bad
    lda X16_P0
    cmp #<GFX8H_WIDTH
    bcs gfx8h_copy_wait__bad
gfx8h_copy_wait__xok:
    lda X16_P3
    cmp #>GFX8H_HEIGHT
    bcc gfx8h_copy_wait__ok
    bne gfx8h_copy_wait__bad
    lda X16_P2
    cmp #<GFX8H_HEIGHT
    bcs gfx8h_copy_wait__bad
gfx8h_copy_wait__ok:
    clc
    rts
gfx8h_copy_wait__bad:
    sec
    rts

bitmap8h_addr_calc:
    lda X16_P2                  // a = y << 7
    sta g8h_a0
    lda X16_P3
    sta g8h_a1
    stz g8h_a2
    ldx #7
gfx8h_copy_wait__s7:
    asl g8h_a0
    rol g8h_a1
    rol g8h_a2
    dex
    bne gfx8h_copy_wait__s7

    lda g8h_a0                  // T = y << 9
    sta X16_T0
    lda g8h_a1
    sta X16_T1
    lda g8h_a2
    sta X16_T2
    asl X16_T0
    rol X16_T1
    rol X16_T2
    asl X16_T0
    rol X16_T1
    rol X16_T2

    clc                         // y*640 = (y<<7) + (y<<9)
    lda g8h_a0
    adc X16_T0
    sta g8h_a0
    lda g8h_a1
    adc X16_T1
    sta g8h_a1
    lda g8h_a2
    adc X16_T2
    sta g8h_a2

    clc                         // + x
    lda g8h_a0
    adc X16_P0
    sta g8h_a0
    lda g8h_a1
    adc X16_P1
    sta g8h_a1
    lda g8h_a2
    adc #0
    sta g8h_a2
    rts

bitmap8h_fill_count:
    ldy g8h_n+1                 // high byte first, so beq tests the LOW byte:
    ldx g8h_n                  // a partial low byte needs one extra dey pass,
    beq gfx8h_copy_wait__full                  // a zero low byte does not (testing the high
    iny                        // byte made every width < 256 write 64K)
gfx8h_copy_wait__full:
gfx8h_copy_wait__loop:
    sta VERA2_DATA
    dex
    bne gfx8h_copy_wait__loop
    dey
    bne gfx8h_copy_wait__loop
    rts

bitmap8h_fill_pages:
    ldy g8h_n+1
gfx8h_copy_wait__outer:
    ldx #0
gfx8h_copy_wait__inner:
    sta VERA2_DATA
    dex
    bne gfx8h_copy_wait__inner
    lda g8h_n
    bne bitmap8h_k13
    dec g8h_n+1
bitmap8h_k13:
	dec g8h_n
    lda g8h_n
    ora g8h_n+1
    beq gfx8h_copy_wait__done
    lda g8h_c
    bra gfx8h_copy_wait__outer
gfx8h_copy_wait__done:
    rts

// ---------------------------------------------------------------------
// data
// ---------------------------------------------------------------------
g8h_a0: .byte 0
g8h_a1: .byte 0
g8h_a2: .byte 0
g8h_inc: .byte 0
g8h_c: .byte 0
g8h_t: .byte 0
g8h_t2: .byte 0
g8h_n: .word 0
g8h_op: .byte 0
g8h_ink: .byte 0

g8h_fx: .word 0
g8h_fy: .word 0
g8h_rw: .word 0
g8h_rh: .word 0
g8h_rc: .byte 0

gp8h_pat: .fill 8, 0
gp8h_bg: .byte 0
gp8h_fg: .byte 0
gp8h_bits: .byte 0
gp8h_bx: .word 0
gp8h_x: .word 0
gp8h_by: .word 0
gp8h_n: .word 0
gp8h_c: .byte 0

g8h_lc: .byte 0
g8h_lx0: .word 0
g8h_ly0: .word 0
g8h_lx1: .word 0
g8h_ly1: .word 0
g8h_ldx: .word 0
g8h_ldy: .word 0
g8h_lerr: .word 0
g8h_le2: .word 0
g8h_lsx: .word 0
g8h_lsy: .word 0

// (end zone)
