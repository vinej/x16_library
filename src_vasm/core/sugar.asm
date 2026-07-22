;ACME
; =====================================================================
; x16lib :: core/sugar.asm -- optional friendly call macros (the "xm_" SDK)
; =====================================================================
; A thin, READ-ONLY convenience layer over the whole library: one macro
; per public routine, named xm_<routine>, that loads the argument block
; and calls it. So a program reads
;
;       +xm_shape_frrect 40, 40, 200, 110, 28, FILL
;       +xm_pal_set 1, $0F00
;       +xm_sprite_pos 0, 100, 50
;
; instead of a dozen lda/sta lines. This is the same idea as the CXRF
; asmsdk cxm_* layer, adapted to this repo's conventions and generated
; the same way as everything else here (written for ACME; the six ports
; are produced by tools/acme2*sugar_py -- it is NOT in their SKIP set).
;
; PURELY ADDITIVE and OPT-IN. Nothing sources this for you; add it
; yourself, once. Each module's macros are wrapped in that module's
; X16_USE_* gate, so SET YOUR GATES FIRST, then source this (before your
; own code, since the macros must be defined before you invoke them):
;
;       !source "x16.asm"
;       X16_USE_SHAPES_RRECT = 1     ; <- your gates first
;       X16_USE_BITMAP2      = 1
;       !source "core/sugar.asm"     ; <- then the (optional) macros
;       ... your program ...
;       !source "x16_code.asm"
;
; The gating matters: a macro that referenced a routine from a module you
; did not enable would be a dangling symbol under the stricter assemblers
; (KickAssembler), so xm_pal_set only exists when X16_USE_PALETTE is set,
; and so on. Set a gate to get its macros; the sub-gates (SHAPES_RRECT,
; PCM_STREAM, ...) each gate their own.
;
; A program that does not source this file, or does not invoke a macro,
; is byte-for-byte unchanged. Each macro expands to exactly the
; hand-written argument setup + jsr, so it costs nothing at run time, and
; you still pay only for the modules whose gates you enable -- a macro is
; only "real" when you invoke it and only then needs its routine linked.
;
; Conventions (mirroring the routine headers):
;   * A macro takes the routine's arguments in their natural order.
;     16-bit things (coordinates, sizes, addresses) are passed whole and
;     split here; bytes (colours, radii, angles, voice/sprite numbers)
;     pass through as-is.
;   * Angles are the sin8/cos8 byte convention: 0 = east, 64 = south.
;   * Arguments are loaded as IMMEDIATES (lda #arg), so pass constants or
;     assemble-time expressions. To call with a value held in a variable,
;     set the argument block by hand and jsr the routine directly -- the
;     macro is a convenience for the common constant case, not a wrapper
;     you can feed run-time values through.
;   * A "-> " note above a macro says what the routine returns (registers
;     / the P block / a carry flag); the macro does not capture it.
;   * Pure no-argument arithmetic (i16_add, f_neg, d_sqrt, ...) has no
;     macro -- a wrapper would add nothing, so call it directly. The
;     init/on/off/wait style calls are wrapped for a uniform call style.
;
; The routines these wrap live behind the X16_USE_* gates documented in
; x16_code.asm; enabling a macro's module is on you.
; =====================================================================

; =====================================================================
; video/vera
; =====================================================================
; point port 0 (compose the H byte -- bank | DECR | incr<<4 -- yourself)
    ifdef X16_USE_VERA
    macro xm_vera_set_addr0
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr vera_set_addr0
    endm
    endif
; point port 1
    ifdef X16_USE_VERA
    macro xm_vera_set_addr1
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr vera_set_addr1
    endm
    endif
; fill `count` bytes with `val` from the current port address
    ifdef X16_USE_VERA
    macro xm_vera_fill
    lda #(\1)
    ldx #<(\2)
    ldy #>(\2)
    jsr vera_fill
    endm
    endif
; copy `count` bytes port0 -> port1 (both pre-pointed)
    ifdef X16_USE_VERA
    macro xm_vera_copy
    ldx #<(\1)
    ldy #>(\1)
    jsr vera_copy
    endm
    endif

; =====================================================================
; video/screen
; =====================================================================
; -> carry set if the mode is unsupported
    ifdef X16_USE_SCREEN
    macro xm_screen_set_mode
    lda #(\1)
    jsr screen_set_mode
    endm
    endif
    ifdef X16_USE_SCREEN
    macro xm_screen_reset
    jsr screen_reset
    endm
    endif
    ifdef X16_USE_SCREEN
    macro xm_screen_cls
    jsr screen_cls
    endm
    endif
    ifdef X16_USE_SCREEN
    macro xm_screen_chrout
    lda #(\1)
    jsr screen_chrout
    endm
    endif
    ifdef X16_USE_SCREEN
    macro xm_screen_color
    lda #(\1)
    ldx #(\2)
    jsr screen_color
    endm
    endif
    ifdef X16_USE_SCREEN
    macro xm_screen_border
    lda #(\1)
    jsr screen_border
    endm
    endif
    ifdef X16_USE_SCREEN
    macro xm_screen_locate
    ldx #(\1)
    ldy #(\2)
    jsr screen_locate
    endm
    endif
    ifdef X16_USE_SCREEN
    macro xm_screen_charset
    lda #(\1)
    jsr screen_charset
    endm
    endif
; print a NUL-terminated string
    ifdef X16_USE_SCREEN
    macro xm_screen_puts
    lda #<(\1)
    ldx #>(\1)
    jsr screen_puts
    endm
    endif

; =====================================================================
; video/palette
; =====================================================================
; set one entry; rgb is a 12-bit $0RGB value
    ifdef X16_USE_PALETTE
    macro xm_pal_set
    ldx #(\1)
    lda #<(\2)
    ldy #>(\2)
    jsr pal_set
    endm
    endif
; bulk-load `count` entries from RAM (2 bytes each, low first)
    ifdef X16_USE_PALETTE
    macro xm_pal_load
    lda #<(\1)
    sta X16_PTR0
    lda #>(\1)
    sta X16_PTR0+1
    lda #(\2)
    ldx #(\3)
    jsr pal_load
    endm
    endif

; =====================================================================
; video/tile  (layer config + tilemap cells)
; =====================================================================
    ifdef X16_USE_TILE
    macro xm_layer_on
    lda #(\1)
    jsr layer_on
    endm
    endif
    ifdef X16_USE_TILE
    macro xm_layer_off
    lda #(\1)
    jsr layer_off
    endm
    endif
    ifdef X16_USE_TILE
    macro xm_layer_set_config
    ldx #(\1)
    lda #(\2)
    jsr layer_set_config
    endm
    endif
    ifdef X16_USE_TILE
    macro xm_layer_set_mapbase
    ldx #(\1)
    lda #(\2)
    jsr layer_set_mapbase
    endm
    endif
    ifdef X16_USE_TILE
    macro xm_layer_scroll_x
    ldx #(\1)
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    jsr layer_scroll_x
    endm
    endif
    ifdef X16_USE_TILE
    macro xm_layer_scroll_y
    ldx #(\1)
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    jsr layer_scroll_y
    endm
    endif
    ifdef X16_USE_TILE
    macro xm_tile_setptr
    ldx #(\1)
    ldy #(\2)
    jsr tile_setptr
    endm
    endif
    ifdef X16_USE_TILE
    macro xm_tile_put
    ldx #(\1)
    ldy #(\2)
    lda #(\3)
    sta X16_P0
    lda #(\4)
    sta X16_P1
    jsr tile_put
    endm
    endif
; -> A = screen code, X = attribute
    ifdef X16_USE_TILE
    macro xm_tile_get
    ldx #(\1)
    ldy #(\2)
    jsr tile_get
    endm
    endif

; =====================================================================
; sprite/sprite
; =====================================================================
    ifdef X16_USE_SPRITE
    macro xm_sprites_on
    jsr sprites_on
    endm
    endif
    ifdef X16_USE_SPRITE
    macro xm_sprites_off
    jsr sprites_off
    endm
    endif
    ifdef X16_USE_SPRITE
    macro xm_sprite_init_all
    jsr sprite_init_all
    endm
    endif
    ifdef X16_USE_SPRITE
    macro xm_sprite_pos
    ldx #(\1)
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\3)
    sta X16_P2
    lda #>(\3)
    sta X16_P3
    jsr sprite_pos
    endm
    endif
; -> P0/1 = x, P2/3 = y
    ifdef X16_USE_SPRITE
    macro xm_sprite_get_pos
    ldx #(\1)
    jsr sprite_get_pos
    endm
    endif
; vaddr = 32-byte-aligned 17-bit VRAM address; mode = SPRITE_MODE_4BPP/8BPP
    ifdef X16_USE_SPRITE
    macro xm_sprite_image
    ldx #(\1)
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<((\2) >> 16)
    sta X16_P2
    lda #(\3)
    jsr sprite_image
    endm
    endif
    ifdef X16_USE_SPRITE
    macro xm_sprite_flags
    ldx #(\1)
    lda #(\2)
    jsr sprite_flags
    endm
    endif
    ifdef X16_USE_SPRITE
    macro xm_sprite_z
    ldx #(\1)
    lda #(\2)
    jsr sprite_z
    endm
    endif
; width/height are SPRITE_SIZE_8/16/32/64 codes
    ifdef X16_USE_SPRITE
    macro xm_sprite_size
    ldx #(\1)
    lda #(\4)
    sta X16_P0
    ldy #(\3)
    lda #(\2)
    jsr sprite_size
    endm
    endif

; =====================================================================
; gfx/bitmap  (320x240 @ 8bpp)
; =====================================================================
    ifdef X16_USE_BITMAP
    macro xm_gfx_init
    jsr gfx_init
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_clear
    lda #(\1)
    jsr gfx_clear
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_pset
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\3)
    sta X16_P3
    jsr gfx_pset
    endm
    endif
; -> A = colour
    ifdef X16_USE_BITMAP
    macro xm_gfx_read
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    jsr gfx_read
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_hline
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    jsr gfx_hline
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_vline
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    jsr gfx_vline
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_rect
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\5)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #(\4)
    sta X16_P6
    jsr gfx_rect
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_frame
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\5)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #(\4)
    sta X16_P6
    jsr gfx_frame
    endm
    endif
; A/X = the address of an 8x8 1bpp pattern
    ifdef X16_USE_BITMAP
    macro xm_gfx_pattern_set
    lda #<(\1)
    ldx #>(\1)
    jsr gfx_pattern_set
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_pattern_rect
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #(\4)
    sta X16_P6
    jsr gfx_pattern_rect
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_line
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\5)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #(\4)
    sta X16_P6
    jsr gfx_line
    endm
    endif
    ifdef X16_USE_BITMAP
    macro xm_gfx_char
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #(\3)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    lda #(\1)
    jsr gfx_char
    endm
    endif
; str = a NUL-terminated string
    ifdef X16_USE_BITMAP
    macro xm_gfx_text
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #(\3)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    lda #<(\1)
    ldx #>(\1)
    jsr gfx_text
    endm
    endif

; =====================================================================
; gfx/bitmap2  (640x480 @ 2bpp; colour in A)
; =====================================================================
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_init
    jsr gfx2_init
    endm
    endif
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_clear
    lda #(\1)
    jsr gfx2_clear
    endm
    endif
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_pset
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    jsr gfx2_pset
    endm
    endif
; -> A = colour, carry set if (x,y) is off screen
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_read
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr gfx2_read
    endm
    endif
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_hline
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #(\4)
    jsr gfx2_hline
    endm
    endif
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_vline
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #(\4)
    jsr gfx2_vline
    endm
    endif
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_rect
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #<(\4)
    sta X16_P6
    lda #>(\4)
    sta X16_P7
    lda #(\5)
    jsr gfx2_rect
    endm
    endif
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_frame
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #<(\4)
    sta X16_P6
    lda #>(\4)
    sta X16_P7
    lda #(\5)
    jsr gfx2_frame
    endm
    endif
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_line
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #<(\4)
    sta X16_P6
    lda #>(\4)
    sta X16_P7
    lda #(\5)
    jsr gfx2_line
    endm
    endif
; A/X = the address of an 8x8 1bpp pattern
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_pattern_set
    lda #<(\1)
    ldx #>(\1)
    jsr gfx2_pattern_set
    endm
    endif
    ifdef X16_USE_BITMAP2
    macro xm_gfx2_pattern_rect
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #<(\4)
    sta X16_P6
    lda #>(\4)
    sta X16_P7
    jsr gfx2_pattern_rect
    endm
    endif

; =====================================================================
; gfx/shapes  (engine-agnostic; bind SHP_* to pick the engine)
; =====================================================================
    ifdef X16_USE_SHAPES
    macro xm_shape_circle
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    lda #(\4)
    jsr shape_circle
    endm
    endif
    ifdef X16_USE_SHAPES
    macro xm_shape_disc
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    lda #(\4)
    jsr shape_disc
    endm
    endif
    ifdef X16_USE_SHAPES
    macro xm_shape_ellipse
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    lda #(\4)
    sta X16_P5
    lda #(\5)
    jsr shape_ellipse
    endm
    endif
    ifdef X16_USE_SHAPES
    macro xm_shape_fellipse
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    lda #(\4)
    sta X16_P5
    lda #(\5)
    jsr shape_fellipse
    endm
    endif
    ifdef X16_USE_SHAPES_RRECT
    macro xm_shape_rrect
    lda #<(\1)
    sta rr_x
    lda #>(\1)
    sta rr_x+1
    lda #<(\2)
    sta rr_y
    lda #>(\2)
    sta rr_y+1
    lda #<(\3)
    sta rr_w
    lda #>(\3)
    sta rr_w+1
    lda #<(\4)
    sta rr_h
    lda #>(\4)
    sta rr_h+1
    lda #(\5)
    sta rr_r
    lda #(\6)
    jsr shape_rrect
    endm
    endif
    ifdef X16_USE_SHAPES_RRECT
    macro xm_shape_frrect
    lda #<(\1)
    sta rr_x
    lda #>(\1)
    sta rr_x+1
    lda #<(\2)
    sta rr_y
    lda #>(\2)
    sta rr_y+1
    lda #<(\3)
    sta rr_w
    lda #>(\3)
    sta rr_w+1
    lda #<(\4)
    sta rr_h
    lda #>(\4)
    sta rr_h+1
    lda #(\5)
    sta rr_r
    lda #(\6)
    jsr shape_frrect
    endm
    endif
    ifdef X16_USE_SHAPES_POLY
    macro xm_shape_polygon
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    lda #(\4)
    sta X16_P5
    lda #(\5)
    sta X16_P6
    lda #(\6)
    jsr shape_polygon
    endm
    endif
    ifdef X16_USE_SHAPES_POLY
    macro xm_shape_fpolygon
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    lda #(\4)
    sta X16_P5
    lda #(\5)
    sta X16_P6
    lda #(\6)
    jsr shape_fpolygon
    endm
    endif
    ifdef X16_USE_SHAPES_ARC
    macro xm_shape_arc
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    lda #(\4)
    sta X16_P5
    lda #(\5)
    sta X16_P6
    lda #(\6)
    jsr shape_arc
    endm
    endif
    ifdef X16_USE_SHAPES_PIE
    macro xm_shape_pie
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    lda #(\4)
    sta X16_P5
    lda #(\5)
    sta X16_P6
    lda #(\6)
    jsr shape_pie
    endm
    endif
    ifdef X16_USE_SHAPES_BEZIER
    macro xm_shape_bezier
    lda #<(\1)
    sta bez_x0
    lda #>(\1)
    sta bez_x0+1
    lda #<(\2)
    sta bez_y0
    lda #>(\2)
    sta bez_y0+1
    lda #<(\3)
    sta bez_x1
    lda #>(\3)
    sta bez_x1+1
    lda #<(\4)
    sta bez_y1
    lda #>(\4)
    sta bez_y1+1
    lda #<(\5)
    sta bez_x2
    lda #>(\5)
    sta bez_x2+1
    lda #<(\6)
    sta bez_y2
    lda #>(\6)
    sta bez_y2+1
    lda #<(\7)
    sta bez_x3
    lda #>(\7)
    sta bez_x3+1
    lda #<(\8)
    sta bez_y3
    lda #>(\8)
    sta bez_y3+1
    lda #(\9)
    jsr shape_bezier
    endm
    endif
; -> carry set if the seed stack overflowed
    ifdef X16_USE_SHAPES
    macro xm_shape_flood
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    jsr shape_flood
    endm
    endif

; =====================================================================
; gfx/verafx  (VERA FX; check vera_has_fx first)
; =====================================================================
    ifdef X16_USE_VERAFX
    macro xm_fx_off
    jsr fx_off
    endm
    endif
; -> P4..P7 = signed 16x16 product
    ifdef X16_USE_VERAFX
    macro xm_fx_mult
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr fx_mult
    endm
    endif
; fill `count` bytes with `val` from the current port address
    ifdef X16_USE_VERAFX
    macro xm_fx_fill
    lda #(\1)
    ldx #<(\2)
    ldy #>(\2)
    jsr fx_fill
    endm
    endif
    ifdef X16_USE_VERAFX
    macro xm_fx_clear
    lda #(\1)
    sta X16_P0
    lda #(\2)
    sta X16_P1
    lda #(\3)
    sta X16_P2
    lda #<(\4)
    sta X16_P3
    lda #>(\4)
    sta X16_P4
    jsr fx_clear
    endm
    endif
    ifdef X16_USE_VERAFX
    macro xm_fx_transp_on
    jsr fx_transp_on
    endm
    endif
    ifdef X16_USE_VERAFX
    macro xm_fx_transp_off
    jsr fx_transp_off
    endm
    endif
    ifdef X16_USE_VERAFX
    macro xm_fx_line
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\5)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #(\4)
    sta X16_P6
    jsr fx_line
    endm
    endif

; =====================================================================
; system/irq
; =====================================================================
    ifdef X16_USE_IRQ
    macro xm_irq_install
    jsr irq_install
    endm
    endif
    ifdef X16_USE_IRQ
    macro xm_irq_remove
    jsr irq_remove
    endm
    endif
    ifdef X16_USE_IRQ
    macro xm_vsync_wait
    jsr vsync_wait
    endm
    endif
    ifdef X16_USE_IRQ
    macro xm_irq_line_install
    lda #<(\1)
    ldx #>(\1)
    jsr irq_line_install
    endm
    endif
; handler = 0 for polling (read with sprite_collisions)
    ifdef X16_USE_IRQ
    macro xm_irq_sprcol_install
    lda #<(\1)
    ldx #>(\1)
    jsr irq_sprcol_install
    endm
    endif
    ifdef X16_USE_IRQ
    macro xm_irq_sprcol_remove
    jsr irq_sprcol_remove
    endm
    endif

; =====================================================================
; audio/psg
; =====================================================================
    ifdef X16_USE_PSG
    macro xm_psg_init
    jsr psg_init
    endm
    endif
    ifdef X16_USE_PSG
    macro xm_psg_set_freq
    ldx #(\1)
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    jsr psg_set_freq
    endm
    endif
    ifdef X16_USE_PSG
    macro xm_psg_set_vol
    ldx #(\1)
    lda #(\2)
    ldy #(\3)
    jsr psg_set_vol
    endm
    endif
    ifdef X16_USE_PSG
    macro xm_psg_set_wave
    ldx #(\1)
    lda #(\2)
    ldy #(\3)
    jsr psg_set_wave
    endm
    endif
    ifdef X16_USE_PSG
    macro xm_psg_note_off
    ldx #(\1)
    jsr psg_note_off
    endm
    endif
    ifdef X16_USE_PSG
    macro xm_psg_env_start
    lda #(\1)
    jsr psg_env_start
    endm
    endif
    ifdef X16_USE_PSG
    macro xm_psg_env_release
    lda #(\1)
    jsr psg_env_release
    endm
    endif
    ifdef X16_USE_PSG
    macro xm_psg_env_stop
    lda #(\1)
    jsr psg_env_stop
    endm
    endif
    ifdef X16_USE_PSG
    macro xm_psg_env_tick
    jsr psg_env_tick
    endm
    endif

; =====================================================================
; audio/ym  (YM2151 FM)
; =====================================================================
    ifdef X16_USE_YM
    macro xm_ym_init
    jsr ym_init
    endm
    endif
    ifdef X16_USE_YM
    macro xm_ym_write
    lda #(\2)
    ldx #(\1)
    jsr ym_write
    endm
    endif
    ifdef X16_USE_YM
    macro xm_ym_poke
    lda #(\2)
    ldx #(\1)
    jsr ym_poke
    endm
    endif
; load a built-in ROM patch (0-162) into a channel
    ifdef X16_USE_YM
    macro xm_ym_patch_rom
    lda #(\1)
    ldx #(\2)
    sec
    jsr ym_patch
    endm
    endif
    ifdef X16_USE_YM
    macro xm_ym_note
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr ym_note
    endm
    endif
; note = (octave<<4)|1..12; note 0 releases
    ifdef X16_USE_YM
    macro xm_ym_note_bas
    lda #(\1)
    ldx #(\2)
    jsr ym_note_bas
    endm
    endif
    ifdef X16_USE_YM
    macro xm_ym_release_note
    lda #(\1)
    jsr ym_release_note
    endm
    endif
    ifdef X16_USE_YM
    macro xm_ym_vol
    lda #(\1)
    ldx #(\2)
    jsr ym_vol
    endm
    endif
    ifdef X16_USE_YM
    macro xm_ym_pan
    lda #(\1)
    ldx #(\2)
    jsr ym_pan
    endm
    endif
    ifdef X16_USE_YM
    macro xm_ym_drum
    lda #(\1)
    ldx #(\2)
    jsr ym_drum
    endm
    endif

; =====================================================================
; audio/pcm
; =====================================================================
    ifdef X16_USE_PCM
    macro xm_pcm_ctrl
    lda #(\1)
    jsr pcm_ctrl
    endm
    endif
    ifdef X16_USE_PCM
    macro xm_pcm_rate
    lda #(\1)
    jsr pcm_rate
    endm
    endif
    ifdef X16_USE_PCM
    macro xm_pcm_reset
    jsr pcm_reset
    endm
    endif
    ifdef X16_USE_PCM
    macro xm_pcm_put
    lda #(\1)
    jsr pcm_put
    endm
    endif
    ifdef X16_USE_PCM
    macro xm_pcm_write
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr pcm_write
    endm
    endif
    ifdef X16_USE_PCM_STREAM
    macro xm_pcm_stream_start
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    jsr pcm_stream_start
    endm
    endif
    ifdef X16_USE_PCM_STREAM
    macro xm_pcm_stream_stop
    jsr pcm_stream_stop
    endm
    endif

; =====================================================================
; audio/adpcm
; =====================================================================
    ifdef X16_USE_ADPCM
    macro xm_adpcm_init
    jsr adpcm_init
    endm
    endif
    ifdef X16_USE_ADPCM
    macro xm_adpcm_nibble
    lda #(\1)
    jsr adpcm_nibble
    endm
    endif
    ifdef X16_USE_ADPCM
    macro xm_adpcm_block
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    jsr adpcm_block
    endm
    endif

; =====================================================================
; input/input
; =====================================================================
    ifdef X16_USE_INPUT
    macro xm_joy_scan
    jsr joy_scan
    endm
    endif
; -> A/X/Y = button bytes
    ifdef X16_USE_INPUT
    macro xm_joy_get
    lda #(\1)
    jsr joy_get
    endm
    endif
    ifdef X16_USE_INPUT
    macro xm_mouse_show
    lda #(\1)
    jsr mouse_show
    endm
    endif
    ifdef X16_USE_INPUT
    macro xm_mouse_hide
    jsr mouse_hide
    endm
    endif
; -> P0/1 = x, P2/3 = y, A = buttons
    ifdef X16_USE_INPUT
    macro xm_mouse_get
    jsr mouse_get
    endm
    endif
; -> A = PETSCII, 0 if none waiting
    ifdef X16_USE_INPUT
    macro xm_key_get
    jsr key_get
    endm
    endif
; -> A = PETSCII (blocks)
    ifdef X16_USE_INPUT
    macro xm_key_wait
    jsr key_wait
    endm
    endif
; -> A = next key without consuming it
    ifdef X16_USE_INPUT
    macro xm_key_peek
    jsr key_peek
    endm
    endif

; =====================================================================
; storage/bank  (banked RAM)
; =====================================================================
    ifdef X16_USE_BANK
    macro xm_bank_set
    lda #(\1)
    jsr bank_set
    endm
    endif
; -> A = byte
    ifdef X16_USE_BANK
    macro xm_bank_peek
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #(\1)
    jsr bank_peek
    endm
    endif
    ifdef X16_USE_BANK
    macro xm_bank_poke
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #(\3)
    ldx #(\1)
    jsr bank_poke
    endm
    endif
    ifdef X16_USE_BANK
    macro xm_mem_to_bank
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #<(\3)
    sta X16_P3
    lda #>(\3)
    sta X16_P4
    lda #<(\4)
    sta X16_P5
    lda #>(\4)
    sta X16_P6
    jsr mem_to_bank
    endm
    endif

; =====================================================================
; storage/bankalloc
; =====================================================================
    ifdef X16_USE_BANKALLOC
    macro xm_bank_alloc_init
    lda #(\1)
    ldx #(\2)
    jsr bank_alloc_init
    endm
    endif
; -> carry clear, A = the bank number
    ifdef X16_USE_BANKALLOC
    macro xm_bank_alloc
    jsr bank_alloc
    endm
    endif
    ifdef X16_USE_BANKALLOC
    macro xm_bank_free
    lda #(\1)
    jsr bank_free
    endm
    endif
    ifdef X16_USE_BANKALLOC
    macro xm_bank_reserve
    lda #(\1)
    jsr bank_reserve
    endm
    endif

; =====================================================================
; storage/mem  (KERNAL block ops; stream to/from VERA_DATA0 too)
; =====================================================================
    ifdef X16_USE_MEM
    macro xm_mem_fill
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    jsr mem_fill
    endm
    endif
    ifdef X16_USE_MEM
    macro xm_mem_copy
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    jsr mem_copy
    endm
    endif
; -> A = CRC low, X = CRC high
    ifdef X16_USE_MEM
    macro xm_mem_crc
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr mem_crc
    endm
    endif
; -> A/X = one past the last output byte
    ifdef X16_USE_MEM
    macro xm_mem_decompress
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr mem_decompress
    endm
    endif

; =====================================================================
; storage/load
; =====================================================================
    ifdef X16_USE_LOAD
    macro xm_fs_setname
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    jsr fs_setname
    endm
    endif
; -> carry set = error, A = KERNAL error code
    ifdef X16_USE_LOAD
    macro xm_fs_load
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\3)
    sta X16_P3
    lda #(\4)
    sta X16_P4
    lda #<(\5)
    sta X16_P5
    lda #>(\5)
    sta X16_P6
    jsr fs_load
    endm
    endif
    ifdef X16_USE_LOAD
    macro xm_fs_vload
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\3)
    sta X16_P3
    lda #(\4)
    sta X16_P4
    lda #<(\5)
    sta X16_P5
    lda #>(\5)
    sta X16_P6
    jsr fs_vload
    endm
    endif

; =====================================================================
; storage/dos
; =====================================================================
; -> A = status code
    ifdef X16_USE_DOS
    macro xm_dos_cmd
    lda #<(\1)
    ldx #>(\1)
    ldy #(\2)
    jsr dos_cmd
    endm
    endif
    ifdef X16_USE_DOS
    macro xm_dos_status
    jsr dos_status
    endm
    endif
    ifdef X16_USE_DOS
    macro xm_dos_delete
    lda #<(\1)
    ldx #>(\1)
    ldy #(\2)
    jsr dos_delete
    endm
    endif

; =====================================================================
; storage/bmx
; =====================================================================
    ifdef X16_USE_BMX
    macro xm_bmx_load
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\3)
    sta X16_P3
    lda #(\4)
    sta X16_P4
    lda #<(\5)
    sta X16_P5
    lda #>(\5)
    sta X16_P6
    jsr bmx_load
    endm
    endif

; =====================================================================
; util/math
; =====================================================================
    ifdef X16_USE_MATH
    macro xm_rnd_seed
    lda #<(\1)
    ldx #>(\1)
    jsr rnd_seed
    endm
    endif
; -> A = -127..127
    ifdef X16_USE_MATH
    macro xm_sin8
    lda #(\1)
    jsr sin8
    endm
    endif
    ifdef X16_USE_MATH
    macro xm_cos8
    lda #(\1)
    jsr cos8
    endm
    endif
; -> A = 1..255
    ifdef X16_USE_MATH
    macro xm_sin8u
    lda #(\1)
    jsr sin8u
    endm
    endif
    ifdef X16_USE_MATH
    macro xm_cos8u
    lda #(\1)
    jsr cos8u
    endm
    endif
; -> A = angle 0-255
    ifdef X16_USE_MATH
    macro xm_atan2
    lda #(\1)
    ldx #(\2)
    jsr atan2
    endm
    endif
; -> A = interpolated value
    ifdef X16_USE_MATH
    macro xm_lerp8
    lda #(\1)
    sta X16_P0
    lda #(\2)
    sta X16_P1
    lda #(\3)
    jsr lerp8
    endm
    endif

; =====================================================================
; util/collide
; =====================================================================
; -> carry set if the two boxes overlap (8-bit coordinates and sizes)
    ifdef X16_USE_COLLIDE
    macro xm_collide8
    lda #(\1)
    sta X16_P0
    lda #(\2)
    sta X16_P1
    lda #(\3)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    lda #(\5)
    sta X16_P4
    lda #(\6)
    sta X16_P5
    lda #(\7)
    sta X16_P6
    lda #(\8)
    sta X16_P7
    jsr collide8
    endm
    endif
; -> carry set if the two boxes overlap (16-bit; writes cl_* directly)
    ifdef X16_USE_COLLIDE
    macro xm_collide16
    lda #<(\1)
    sta cl_ax
    lda #>(\1)
    sta cl_ax+1
    lda #<(\2)
    sta cl_ay
    lda #>(\2)
    sta cl_ay+1
    lda #<(\3)
    sta cl_aw
    lda #>(\3)
    sta cl_aw+1
    lda #<(\4)
    sta cl_ah
    lda #>(\4)
    sta cl_ah+1
    lda #<(\5)
    sta cl_bx
    lda #>(\5)
    sta cl_bx+1
    lda #<(\6)
    sta cl_by
    lda #>(\6)
    sta cl_by+1
    lda #<(\7)
    sta cl_bw
    lda #>(\7)
    sta cl_bw+1
    lda #<(\8)
    sta cl_bh
    lda #>(\8)
    sta cl_bh+1
    jsr collide16
    endm
    endif

; =====================================================================
; util/bits
; =====================================================================
    ifdef X16_USE_BITS
    macro xm_catnib
    lda #(\1)
    ldx #(\2)
    jsr catnib
    endm
    endif
    ifdef X16_USE_BITS
    macro xm_hinib
    lda #(\1)
    jsr hinib
    endm
    endif
    ifdef X16_USE_BITS
    macro xm_lonib
    lda #(\1)
    jsr lonib
    endm
    endif
    ifdef X16_USE_BITS
    macro xm_bit_set
    lda #<(\1)
    sta X16_PTR0
    lda #>(\1)
    sta X16_PTR0+1
    lda #(\2)
    jsr bit_set
    endm
    endif
    ifdef X16_USE_BITS
    macro xm_bit_clr
    lda #<(\1)
    sta X16_PTR0
    lda #>(\1)
    sta X16_PTR0+1
    lda #(\2)
    jsr bit_clr
    endm
    endif
; -> Z clear if any masked bit was set
    ifdef X16_USE_BITS
    macro xm_bit_test
    lda #<(\1)
    sta X16_PTR0
    lda #>(\1)
    sta X16_PTR0+1
    lda #(\2)
    jsr bit_test
    endm
    endif

; =====================================================================
; util/number
; =====================================================================
; -> A/X = buffer, Y = length
    ifdef X16_USE_NUMBER
    macro xm_u16_to_dec
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    jsr u16_to_dec
    endm
    endif
; -> A/X = buffer, Y = 4
    ifdef X16_USE_NUMBER
    macro xm_u16_to_hex
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    jsr u16_to_hex
    endm
    endif
; -> P4/5 = value, carry set on a bad digit
    ifdef X16_USE_NUMBER
    macro xm_dec_to_u16
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    jsr dec_to_u16
    endm
    endif

; =====================================================================
; util/fixed
; =====================================================================
; -> P4..P7 = product
    ifdef X16_USE_FIXED
    macro xm_umul16
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr umul16
    endm
    endif
; signed 8.8; -> P0/1 = result
    ifdef X16_USE_FIXED
    macro xm_mul88
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr mul88
    endm
    endif

; =====================================================================
; util/int16  (load i16_a / i16_b with +i16_const; ops are argument-free)
; =====================================================================
    ifdef X16_USE_INT16
    macro xm_i16_from_u8
    lda #(\1)
    jsr i16_from_u8
    endm
    endif
    ifdef X16_USE_INT16
    macro xm_i16_from_s8
    lda #(\1)
    jsr i16_from_s8
    endm
    endif

; =====================================================================
; util/int32  (load i32_a / i32_b with +i32_const)
; =====================================================================
    ifdef X16_USE_INT32
    macro xm_i32_from_u16
    lda #<(\1)
    ldx #>(\1)
    jsr i32_from_u16
    endm
    endif
    ifdef X16_USE_INT32
    macro xm_i32_from_s16
    lda #<(\1)
    ldx #>(\1)
    jsr i32_from_s16
    endm
    endif

; =====================================================================
; util/float  (FAC is the accumulator; addr = a 5-byte float in memory)
; =====================================================================
    ifdef X16_USE_FLOAT
    macro xm_f_from_u8
    lda #(\1)
    jsr f_from_u8
    endm
    endif
    ifdef X16_USE_FLOAT
    macro xm_f_from_s16
    lda #<(\1)
    ldx #>(\1)
    jsr f_from_s16
    endm
    endif
    ifdef X16_USE_FLOAT
    macro xm_f_load
    lda #<(\1)
    ldy #>(\1)
    jsr f_load
    endm
    endif
    ifdef X16_USE_FLOAT
    macro xm_f_store
    lda #<(\1)
    ldy #>(\1)
    jsr f_store
    endm
    endif
    ifdef X16_USE_FLOAT
    macro xm_f_add
    lda #<(\1)
    ldy #>(\1)
    jsr f_add
    endm
    endif
    ifdef X16_USE_FLOAT
    macro xm_f_sub
    lda #<(\1)
    ldy #>(\1)
    jsr f_sub
    endm
    endif
    ifdef X16_USE_FLOAT
    macro xm_f_mul
    lda #<(\1)
    ldy #>(\1)
    jsr f_mul
    endm
    endif
    ifdef X16_USE_FLOAT
    macro xm_f_div
    lda #<(\1)
    ldy #>(\1)
    jsr f_div
    endm
    endif
    ifdef X16_USE_FLOAT
    macro xm_f_cmp
    lda #<(\1)
    ldy #>(\1)
    jsr f_cmp
    endm
    endif
; FAC = mem - FAC
    ifdef X16_USE_FLOAT
    macro xm_f_rsub
    lda #<(\1)
    ldy #>(\1)
    jsr f_rsub
    endm
    endif
; FAC = mem / FAC
    ifdef X16_USE_FLOAT
    macro xm_f_rdiv
    lda #<(\1)
    ldy #>(\1)
    jsr f_rdiv
    endm
    endif
; FAC = FAC ^ mem
    ifdef X16_USE_FLOAT
    macro xm_f_pow
    lda #<(\1)
    ldy #>(\1)
    jsr f_pow
    endm
    endif
; FAC = the value parsed from a string of `len` chars
    ifdef X16_USE_FLOAT
    macro xm_f_from_str
    lda #<(\1)
    ldy #>(\1)
    ldx #(\2)
    jsr f_from_str
    endm
    endif

; =====================================================================
; util/double  (d_ac is the accumulator; addr = an 8-byte double in memory)
; =====================================================================
    ifdef X16_USE_DOUBLE
    macro xm_d_load
    lda #<(\1)
    ldy #>(\1)
    jsr d_load
    endm
    endif
    ifdef X16_USE_DOUBLE
    macro xm_d_store
    lda #<(\1)
    ldy #>(\1)
    jsr d_store
    endm
    endif
    ifdef X16_USE_DOUBLE
    macro xm_d_add
    lda #<(\1)
    ldy #>(\1)
    jsr d_add
    endm
    endif
    ifdef X16_USE_DOUBLE
    macro xm_d_sub
    lda #<(\1)
    ldy #>(\1)
    jsr d_sub
    endm
    endif
    ifdef X16_USE_DOUBLE
    macro xm_d_mul
    lda #<(\1)
    ldy #>(\1)
    jsr d_mul
    endm
    endif
    ifdef X16_USE_DOUBLE
    macro xm_d_div
    lda #<(\1)
    ldy #>(\1)
    jsr d_div
    endm
    endif
    ifdef X16_USE_DOUBLE
    macro xm_d_cmp
    lda #<(\1)
    ldy #>(\1)
    jsr d_cmp
    endm
    endif
; d_ac = d_ac ^ mem  (base ^ exponent)
    ifdef X16_USE_DOUBLE
    macro xm_d_pow
    lda #<(\1)
    ldy #>(\1)
    jsr d_pow
    endm
    endif
; d_ac = the value parsed from a string of `len` chars
    ifdef X16_USE_DOUBLE
    macro xm_d_from_str
    lda #<(\1)
    ldy #>(\1)
    ldx #(\2)
    jsr d_from_str
    endm
    endif
    ifdef X16_USE_DOUBLE
    macro xm_d_from_s16
    lda #<(\1)
    ldx #>(\1)
    jsr d_from_s16
    endm
    endif

; =====================================================================
; util/clip
; =====================================================================
    ifdef X16_USE_CLIP
    macro xm_clip_set
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #<(\3)
    sta X16_P4
    lda #>(\3)
    sta X16_P5
    lda #<(\4)
    sta X16_P6
    lda #>(\4)
    sta X16_P7
    jsr clip_set
    endm
    endif

; =====================================================================
; util/buffers  (ring buffer + byte stack)
; =====================================================================
    ifdef X16_USE_BUFFERS
    macro xm_rb_init
    jsr rb_init
    endm
    endif
; -> carry set if the buffer was full
    ifdef X16_USE_BUFFERS
    macro xm_rb_put
    lda #(\1)
    jsr rb_put
    endm
    endif
; -> A = byte, carry set if empty
    ifdef X16_USE_BUFFERS
    macro xm_rb_get
    jsr rb_get
    endm
    endif
    ifdef X16_USE_BUFFERS
    macro xm_rb_count
    jsr rb_count
    endm
    endif
    ifdef X16_USE_BUFFERS
    macro xm_stk_init
    jsr stk_init
    endm
    endif
; -> carry set if the stack was full
    ifdef X16_USE_BUFFERS
    macro xm_stk_push
    lda #(\1)
    jsr stk_push
    endm
    endif
; -> A = byte, carry set if empty
    ifdef X16_USE_BUFFERS
    macro xm_stk_pop
    jsr stk_pop
    endm
    endif
    ifdef X16_USE_BUFFERS
    macro xm_stk_depth
    jsr stk_depth
    endm
    endif

; =====================================================================
; util/zx0 and util/tscrunch
; =====================================================================
; -> A/X = one past the last output byte
    ifdef X16_USE_ZX0
    macro xm_zx0_decompress
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr zx0_decompress
    endm
    endif
    ifdef X16_USE_TSC
    macro xm_tsc_decompress
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr tsc_decompress
    endm
    endif

; =====================================================================
; comms/serial
; =====================================================================
; -> A = count (0-2), carry clear if any found, ser_u0/ser_u1 = bases
    ifdef X16_USE_SERIAL
    macro xm_ser_detect
    jsr ser_detect
    endm
    endif
    ifdef X16_USE_SERIAL
    macro xm_ser_init
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\1)
    ldx #>(\1)
    jsr ser_init
    endm
    endif
; -> carry set if a received byte is waiting
    ifdef X16_USE_SERIAL
    macro xm_ser_avail
    jsr ser_avail
    endm
    endif
; -> carry clear + A = byte, or carry set if the RX FIFO was empty
    ifdef X16_USE_SERIAL
    macro xm_ser_get
    jsr ser_get
    endm
    endif
; -> A = byte (blocks until one arrives)
    ifdef X16_USE_SERIAL
    macro xm_ser_get_wait
    jsr ser_get_wait
    endm
    endif
    ifdef X16_USE_SERIAL
    macro xm_ser_put
    lda #(\1)
    jsr ser_put
    endm
    endif
    ifdef X16_USE_SERIAL
    macro xm_ser_puts
    lda #<(\1)
    ldx #>(\1)
    jsr ser_puts
    endm
    endif
    ifdef X16_USE_SERIAL
    macro xm_ser_write
    ldy #(\2)
    lda #<(\1)
    ldx #>(\1)
    jsr ser_write
    endm
    endif
; -> X16_P4/P5 = bytes stored
    ifdef X16_USE_SERIAL
    macro xm_ser_read_until
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\3)
    sta X16_P2
    lda #>(\3)
    sta X16_P3
    lda #<(\1)
    ldx #>(\1)
    jsr ser_read_until
    endm
    endif
    ifdef X16_USE_SERIAL
    macro xm_ser_discard_until
    lda #<(\1)
    ldx #>(\1)
    jsr ser_discard_until
    endm
    endif

; =====================================================================
; comms/zimodem
; =====================================================================
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_init
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\1)
    ldx #>(\1)
    jsr zi_init
    endm
    endif
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_cmd
    lda #<(\1)
    ldx #>(\1)
    jsr zi_cmd
    endm
    endif
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_wait_ok
    jsr zi_wait_ok
    endm
    endif
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_reset
    jsr zi_reset
    endm
    endif
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_get_ip
    lda #<(\1)
    ldx #>(\1)
    jsr zi_get_ip
    endm
    endif
; -> carry clear if the transfer started, carry set if not found
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_hex_open
    lda #<(\1)
    ldx #>(\1)
    jsr zi_hex_open
    endm
    endif
; -> A = bytes decoded into the buffer, 0 when the file is done
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_hex_chunk
    lda #<(\1)
    ldx #>(\1)
    jsr zi_hex_chunk
    endm
    endif
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_hex_close
    jsr zi_hex_close
    endm
    endif
; -> A = bytes written (sugar_digits / 2)
    ifdef X16_USE_SERIAL_ZIMODEM
    macro xm_zi_hexdecode
    lda #<(\3)
    sta X16_P0
    lda #>(\3)
    sta X16_P1
    ldy #(\2)
    lda #<(\1)
    ldx #>(\1)
    jsr zi_hexdecode
    endm
    endif

; =====================================================================
; string/string
; =====================================================================
; -> Y = length
    ifdef X16_USE_STRING
    macro xm_str_length
    lda #<(\1)
    ldx #>(\1)
    jsr str_length
    endm
    endif
; -> Y = length copied
    ifdef X16_USE_STRING
    macro xm_str_copy
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\1)
    ldx #>(\1)
    jsr str_copy
    endm
    endif
    ifdef X16_USE_STRING
    macro xm_str_ncopy
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    ldy #(\3)
    lda #<(\1)
    ldx #>(\1)
    jsr str_ncopy
    endm
    endif
; -> A = resulting length
    ifdef X16_USE_STRING
    macro xm_str_append
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\1)
    ldx #>(\1)
    jsr str_append
    endm
    endif
    ifdef X16_USE_STRING
    macro xm_str_nappend
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    ldy #(\3)
    lda #<(\1)
    ldx #>(\1)
    jsr str_nappend
    endm
    endif
; -> A = -1 / 0 / 1
    ifdef X16_USE_STRING
    macro xm_str_compare
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\1)
    ldx #>(\1)
    jsr str_compare
    endm
    endif
; -> A = hash
    ifdef X16_USE_STRING
    macro xm_str_hash
    lda #<(\1)
    ldx #>(\1)
    jsr str_hash
    endm
    endif

; =====================================================================
; string/case
; =====================================================================
    ifdef X16_USE_STRING_CASE
    macro xm_str_lower
    lda #<(\1)
    ldx #>(\1)
    jsr str_lower
    endm
    endif
    ifdef X16_USE_STRING_CASE
    macro xm_str_lower_iso
    lda #<(\1)
    ldx #>(\1)
    jsr str_lower_iso
    endm
    endif
    ifdef X16_USE_STRING_CASE
    macro xm_str_upper
    lda #<(\1)
    ldx #>(\1)
    jsr str_upper
    endm
    endif
    ifdef X16_USE_STRING_CASE
    macro xm_str_upper_iso
    lda #<(\1)
    ldx #>(\1)
    jsr str_upper_iso
    endm
    endif
; -> A = -1 / 0 / 1
    ifdef X16_USE_STRING_CASE
    macro xm_str_compare_nocase
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\1)
    ldx #>(\1)
    jsr str_compare_nocase
    endm
    endif
    ifdef X16_USE_STRING_CASE
    macro xm_str_compare_nocase_iso
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\1)
    ldx #>(\1)
    jsr str_compare_nocase_iso
    endm
    endif

; =====================================================================
; string/find
; =====================================================================
; -> carry set + A = index if found
    ifdef X16_USE_STRING_FIND
    macro xm_str_find
    ldy #(\2)
    lda #<(\1)
    ldx #>(\1)
    jsr str_find
    endm
    endif
    ifdef X16_USE_STRING_FIND
    macro xm_str_rfind
    ldy #(\2)
    lda #<(\1)
    ldx #>(\1)
    jsr str_rfind
    endm
    endif
    ifdef X16_USE_STRING_FIND
    macro xm_str_find_eol
    lda #<(\1)
    ldx #>(\1)
    jsr str_find_eol
    endm
    endif
; -> carry set if the character occurs
    ifdef X16_USE_STRING_FIND
    macro xm_str_contains
    ldy #(\2)
    lda #<(\1)
    ldx #>(\1)
    jsr str_contains
    endm
    endif
; -> carry set (A = 1) if it matches
    ifdef X16_USE_STRING_FIND
    macro xm_str_pattern_match
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #<(\1)
    ldx #>(\1)
    jsr str_pattern_match
    endm
    endif

; =====================================================================
; string/slice
; =====================================================================
    ifdef X16_USE_STRING_SLICE
    macro xm_str_left
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    ldy #(\3)
    lda #<(\1)
    ldx #>(\1)
    jsr str_left
    endm
    endif
    ifdef X16_USE_STRING_SLICE
    macro xm_str_right
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    ldy #(\3)
    lda #<(\1)
    ldx #>(\1)
    jsr str_right
    endm
    endif
    ifdef X16_USE_STRING_SLICE
    macro xm_str_slice
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #(\3)
    sta X16_P2
    ldy #(\4)
    lda #<(\1)
    ldx #>(\1)
    jsr str_slice
    endm
    endif
; -> Y = new length
    ifdef X16_USE_STRING_SLICE
    macro xm_str_ltrim
    lda #<(\1)
    ldx #>(\1)
    jsr str_ltrim
    endm
    endif
    ifdef X16_USE_STRING_SLICE
    macro xm_str_rtrim
    lda #<(\1)
    ldx #>(\1)
    jsr str_rtrim
    endm
    endif
    ifdef X16_USE_STRING_SLICE
    macro xm_str_trim
    lda #<(\1)
    ldx #>(\1)
    jsr str_trim
    endm
    endif
