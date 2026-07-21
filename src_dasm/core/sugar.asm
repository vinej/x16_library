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
; instead of a dozen lda/sta lines. This is the same idea as the CXGEOS
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
    IFCONST X16_USE_VERA
    MAC xm_vera_set_addr0
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr vera_set_addr0
    ENDM
    ENDIF
; point port 1
    IFCONST X16_USE_VERA
    MAC xm_vera_set_addr1
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr vera_set_addr1
    ENDM
    ENDIF
; fill `count` bytes with `val` from the current port address
    IFCONST X16_USE_VERA
    MAC xm_vera_fill
    lda #({1})
    ldx #<({2})
    ldy #>({2})
    jsr vera_fill
    ENDM
    ENDIF
; copy `count` bytes port0 -> port1 (both pre-pointed)
    IFCONST X16_USE_VERA
    MAC xm_vera_copy
    ldx #<({1})
    ldy #>({1})
    jsr vera_copy
    ENDM
    ENDIF

; =====================================================================
; video/screen
; =====================================================================
; -> carry set if the mode is unsupported
    IFCONST X16_USE_SCREEN
    MAC xm_screen_set_mode
    lda #({1})
    jsr screen_set_mode
    ENDM
    ENDIF
    IFCONST X16_USE_SCREEN
    MAC xm_screen_reset
    jsr screen_reset
    ENDM
    ENDIF
    IFCONST X16_USE_SCREEN
    MAC xm_screen_cls
    jsr screen_cls
    ENDM
    ENDIF
    IFCONST X16_USE_SCREEN
    MAC xm_screen_chrout
    lda #({1})
    jsr screen_chrout
    ENDM
    ENDIF
    IFCONST X16_USE_SCREEN
    MAC xm_screen_color
    lda #({1})
    ldx #({2})
    jsr screen_color
    ENDM
    ENDIF
    IFCONST X16_USE_SCREEN
    MAC xm_screen_border
    lda #({1})
    jsr screen_border
    ENDM
    ENDIF
    IFCONST X16_USE_SCREEN
    MAC xm_screen_locate
    ldx #({1})
    ldy #({2})
    jsr screen_locate
    ENDM
    ENDIF
    IFCONST X16_USE_SCREEN
    MAC xm_screen_charset
    lda #({1})
    jsr screen_charset
    ENDM
    ENDIF
; print a NUL-terminated string
    IFCONST X16_USE_SCREEN
    MAC xm_screen_puts
    lda #<({1})
    ldx #>({1})
    jsr screen_puts
    ENDM
    ENDIF

; =====================================================================
; video/palette
; =====================================================================
; set one entry; rgb is a 12-bit $0RGB value
    IFCONST X16_USE_PALETTE
    MAC xm_pal_set
    ldx #({1})
    lda #<({2})
    ldy #>({2})
    jsr pal_set
    ENDM
    ENDIF
; bulk-load `count` entries from RAM (2 bytes each, low first)
    IFCONST X16_USE_PALETTE
    MAC xm_pal_load
    lda #<({1})
    sta X16_PTR0
    lda #>({1})
    sta X16_PTR0+1
    lda #({2})
    ldx #({3})
    jsr pal_load
    ENDM
    ENDIF

; =====================================================================
; video/tile  (layer config + tilemap cells)
; =====================================================================
    IFCONST X16_USE_TILE
    MAC xm_layer_on
    lda #({1})
    jsr layer_on
    ENDM
    ENDIF
    IFCONST X16_USE_TILE
    MAC xm_layer_off
    lda #({1})
    jsr layer_off
    ENDM
    ENDIF
    IFCONST X16_USE_TILE
    MAC xm_layer_set_config
    ldx #({1})
    lda #({2})
    jsr layer_set_config
    ENDM
    ENDIF
    IFCONST X16_USE_TILE
    MAC xm_layer_set_mapbase
    ldx #({1})
    lda #({2})
    jsr layer_set_mapbase
    ENDM
    ENDIF
    IFCONST X16_USE_TILE
    MAC xm_layer_scroll_x
    ldx #({1})
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    jsr layer_scroll_x
    ENDM
    ENDIF
    IFCONST X16_USE_TILE
    MAC xm_layer_scroll_y
    ldx #({1})
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    jsr layer_scroll_y
    ENDM
    ENDIF
    IFCONST X16_USE_TILE
    MAC xm_tile_setptr
    ldx #({1})
    ldy #({2})
    jsr tile_setptr
    ENDM
    ENDIF
    IFCONST X16_USE_TILE
    MAC xm_tile_put
    ldx #({1})
    ldy #({2})
    lda #({3})
    sta X16_P0
    lda #({4})
    sta X16_P1
    jsr tile_put
    ENDM
    ENDIF
; -> A = screen code, X = attribute
    IFCONST X16_USE_TILE
    MAC xm_tile_get
    ldx #({1})
    ldy #({2})
    jsr tile_get
    ENDM
    ENDIF

; =====================================================================
; sprite/sprite
; =====================================================================
    IFCONST X16_USE_SPRITE
    MAC xm_sprites_on
    jsr sprites_on
    ENDM
    ENDIF
    IFCONST X16_USE_SPRITE
    MAC xm_sprites_off
    jsr sprites_off
    ENDM
    ENDIF
    IFCONST X16_USE_SPRITE
    MAC xm_sprite_init_all
    jsr sprite_init_all
    ENDM
    ENDIF
    IFCONST X16_USE_SPRITE
    MAC xm_sprite_pos
    ldx #({1})
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({3})
    sta X16_P2
    lda #>({3})
    sta X16_P3
    jsr sprite_pos
    ENDM
    ENDIF
; -> P0/1 = x, P2/3 = y
    IFCONST X16_USE_SPRITE
    MAC xm_sprite_get_pos
    ldx #({1})
    jsr sprite_get_pos
    ENDM
    ENDIF
; vaddr = 32-byte-aligned 17-bit VRAM address; mode = SPRITE_MODE_4BPP/8BPP
    IFCONST X16_USE_SPRITE
    MAC xm_sprite_image
    ldx #({1})
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<(({2}) >> 16)
    sta X16_P2
    lda #({3})
    jsr sprite_image
    ENDM
    ENDIF
    IFCONST X16_USE_SPRITE
    MAC xm_sprite_flags
    ldx #({1})
    lda #({2})
    jsr sprite_flags
    ENDM
    ENDIF
    IFCONST X16_USE_SPRITE
    MAC xm_sprite_z
    ldx #({1})
    lda #({2})
    jsr sprite_z
    ENDM
    ENDIF
; width/height are SPRITE_SIZE_8/16/32/64 codes
    IFCONST X16_USE_SPRITE
    MAC xm_sprite_size
    ldx #({1})
    lda #({4})
    sta X16_P0
    ldy #({3})
    lda #({2})
    jsr sprite_size
    ENDM
    ENDIF

; =====================================================================
; gfx/bitmap  (320x240 @ 8bpp)
; =====================================================================
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_init
    jsr gfx_init
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_clear
    lda #({1})
    jsr gfx_clear
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_pset
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    jsr gfx_pset
    ENDM
    ENDIF
; -> A = colour
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_read
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    jsr gfx_read
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_hline
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({4})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    jsr gfx_hline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_vline
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({4})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    jsr gfx_vline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_rect
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({5})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #({4})
    sta X16_P6
    jsr gfx_rect
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_frame
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({5})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #({4})
    sta X16_P6
    jsr gfx_frame
    ENDM
    ENDIF
; A/X = the address of an 8x8 1bpp pattern
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_pattern_set
    lda #<({1})
    ldx #>({1})
    jsr gfx_pattern_set
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_pattern_rect
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #({4})
    sta X16_P6
    jsr gfx_pattern_rect
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_line
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({5})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #({4})
    sta X16_P6
    jsr gfx_line
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_char
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    lda #({4})
    sta X16_P3
    lda #({1})
    jsr gfx_char
    ENDM
    ENDIF
; str = a NUL-terminated string
    IFCONST X16_USE_BITMAP
    MAC xm_gfx_text
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    lda #({4})
    sta X16_P3
    lda #<({1})
    ldx #>({1})
    jsr gfx_text
    ENDM
    ENDIF

; =====================================================================
; gfx/bitmap2  (640x480 @ 2bpp; colour in A)
; =====================================================================
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_init
    jsr gfx2_init
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_clear
    lda #({1})
    jsr gfx2_clear
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_pset
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    jsr gfx2_pset
    ENDM
    ENDIF
; -> A = colour, carry set if (x,y) is off screen
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_read
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr gfx2_read
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_hline
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #({4})
    jsr gfx2_hline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_vline
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #({4})
    jsr gfx2_vline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_rect
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #<({4})
    sta X16_P6
    lda #>({4})
    sta X16_P7
    lda #({5})
    jsr gfx2_rect
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_frame
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #<({4})
    sta X16_P6
    lda #>({4})
    sta X16_P7
    lda #({5})
    jsr gfx2_frame
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_line
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #<({4})
    sta X16_P6
    lda #>({4})
    sta X16_P7
    lda #({5})
    jsr gfx2_line
    ENDM
    ENDIF
; A/X = the address of an 8x8 1bpp pattern
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_pattern_set
    lda #<({1})
    ldx #>({1})
    jsr gfx2_pattern_set
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2
    MAC xm_gfx2_pattern_rect
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #<({4})
    sta X16_P6
    lda #>({4})
    sta X16_P7
    jsr gfx2_pattern_rect
    ENDM
    ENDIF

; =====================================================================
; gfx/shapes  (engine-agnostic; bind SHP_* to pick the engine)
; =====================================================================
    IFCONST X16_USE_SHAPES
    MAC xm_shape_circle
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    lda #({4})
    jsr shape_circle
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES
    MAC xm_shape_disc
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    lda #({4})
    jsr shape_disc
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES
    MAC xm_shape_ellipse
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    lda #({4})
    sta X16_P5
    lda #({5})
    jsr shape_ellipse
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES
    MAC xm_shape_fellipse
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    lda #({4})
    sta X16_P5
    lda #({5})
    jsr shape_fellipse
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES_RRECT
    MAC xm_shape_rrect
    lda #<({1})
    sta rr_x
    lda #>({1})
    sta rr_x+1
    lda #<({2})
    sta rr_y
    lda #>({2})
    sta rr_y+1
    lda #<({3})
    sta rr_w
    lda #>({3})
    sta rr_w+1
    lda #<({4})
    sta rr_h
    lda #>({4})
    sta rr_h+1
    lda #({5})
    sta rr_r
    lda #({6})
    jsr shape_rrect
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES_RRECT
    MAC xm_shape_frrect
    lda #<({1})
    sta rr_x
    lda #>({1})
    sta rr_x+1
    lda #<({2})
    sta rr_y
    lda #>({2})
    sta rr_y+1
    lda #<({3})
    sta rr_w
    lda #>({3})
    sta rr_w+1
    lda #<({4})
    sta rr_h
    lda #>({4})
    sta rr_h+1
    lda #({5})
    sta rr_r
    lda #({6})
    jsr shape_frrect
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES_POLY
    MAC xm_shape_polygon
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    lda #({4})
    sta X16_P5
    lda #({5})
    sta X16_P6
    lda #({6})
    jsr shape_polygon
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES_POLY
    MAC xm_shape_fpolygon
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    lda #({4})
    sta X16_P5
    lda #({5})
    sta X16_P6
    lda #({6})
    jsr shape_fpolygon
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES_ARC
    MAC xm_shape_arc
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    lda #({4})
    sta X16_P5
    lda #({5})
    sta X16_P6
    lda #({6})
    jsr shape_arc
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES_PIE
    MAC xm_shape_pie
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    lda #({4})
    sta X16_P5
    lda #({5})
    sta X16_P6
    lda #({6})
    jsr shape_pie
    ENDM
    ENDIF
    IFCONST X16_USE_SHAPES_BEZIER
    MAC xm_shape_bezier
    lda #<({1})
    sta bez_x0
    lda #>({1})
    sta bez_x0+1
    lda #<({2})
    sta bez_y0
    lda #>({2})
    sta bez_y0+1
    lda #<({3})
    sta bez_x1
    lda #>({3})
    sta bez_x1+1
    lda #<({4})
    sta bez_y1
    lda #>({4})
    sta bez_y1+1
    lda #<({5})
    sta bez_x2
    lda #>({5})
    sta bez_x2+1
    lda #<({6})
    sta bez_y2
    lda #>({6})
    sta bez_y2+1
    lda #<({7})
    sta bez_x3
    lda #>({7})
    sta bez_x3+1
    lda #<({8})
    sta bez_y3
    lda #>({8})
    sta bez_y3+1
    lda #({9})
    jsr shape_bezier
    ENDM
    ENDIF
; -> carry set if the seed stack overflowed
    IFCONST X16_USE_SHAPES
    MAC xm_shape_flood
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    jsr shape_flood
    ENDM
    ENDIF

; =====================================================================
; gfx/verafx  (VERA FX; check vera_has_fx first)
; =====================================================================
    IFCONST X16_USE_VERAFX
    MAC xm_fx_off
    jsr fx_off
    ENDM
    ENDIF
; -> P4..P7 = signed 16x16 product
    IFCONST X16_USE_VERAFX
    MAC xm_fx_mult
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr fx_mult
    ENDM
    ENDIF
; fill `count` bytes with `val` from the current port address
    IFCONST X16_USE_VERAFX
    MAC xm_fx_fill
    lda #({1})
    ldx #<({2})
    ldy #>({2})
    jsr fx_fill
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX
    MAC xm_fx_clear
    lda #({1})
    sta X16_P0
    lda #({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    lda #<({4})
    sta X16_P3
    lda #>({4})
    sta X16_P4
    jsr fx_clear
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX
    MAC xm_fx_transp_on
    jsr fx_transp_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX
    MAC xm_fx_transp_off
    jsr fx_transp_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX
    MAC xm_fx_line
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({5})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #({4})
    sta X16_P6
    jsr fx_line
    ENDM
    ENDIF

; =====================================================================
; system/irq
; =====================================================================
    IFCONST X16_USE_IRQ
    MAC xm_irq_install
    jsr irq_install
    ENDM
    ENDIF
    IFCONST X16_USE_IRQ
    MAC xm_irq_remove
    jsr irq_remove
    ENDM
    ENDIF
    IFCONST X16_USE_IRQ
    MAC xm_vsync_wait
    jsr vsync_wait
    ENDM
    ENDIF
    IFCONST X16_USE_IRQ
    MAC xm_irq_line_install
    lda #<({1})
    ldx #>({1})
    jsr irq_line_install
    ENDM
    ENDIF
; handler = 0 for polling (read with sprite_collisions)
    IFCONST X16_USE_IRQ
    MAC xm_irq_sprcol_install
    lda #<({1})
    ldx #>({1})
    jsr irq_sprcol_install
    ENDM
    ENDIF
    IFCONST X16_USE_IRQ
    MAC xm_irq_sprcol_remove
    jsr irq_sprcol_remove
    ENDM
    ENDIF

; =====================================================================
; audio/psg
; =====================================================================
    IFCONST X16_USE_PSG
    MAC xm_psg_init
    jsr psg_init
    ENDM
    ENDIF
    IFCONST X16_USE_PSG
    MAC xm_psg_set_freq
    ldx #({1})
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    jsr psg_set_freq
    ENDM
    ENDIF
    IFCONST X16_USE_PSG
    MAC xm_psg_set_vol
    ldx #({1})
    lda #({2})
    ldy #({3})
    jsr psg_set_vol
    ENDM
    ENDIF
    IFCONST X16_USE_PSG
    MAC xm_psg_set_wave
    ldx #({1})
    lda #({2})
    ldy #({3})
    jsr psg_set_wave
    ENDM
    ENDIF
    IFCONST X16_USE_PSG
    MAC xm_psg_note_off
    ldx #({1})
    jsr psg_note_off
    ENDM
    ENDIF
    IFCONST X16_USE_PSG
    MAC xm_psg_env_start
    lda #({1})
    jsr psg_env_start
    ENDM
    ENDIF
    IFCONST X16_USE_PSG
    MAC xm_psg_env_release
    lda #({1})
    jsr psg_env_release
    ENDM
    ENDIF
    IFCONST X16_USE_PSG
    MAC xm_psg_env_stop
    lda #({1})
    jsr psg_env_stop
    ENDM
    ENDIF
    IFCONST X16_USE_PSG
    MAC xm_psg_env_tick
    jsr psg_env_tick
    ENDM
    ENDIF

; =====================================================================
; audio/ym  (YM2151 FM)
; =====================================================================
    IFCONST X16_USE_YM
    MAC xm_ym_init
    jsr ym_init
    ENDM
    ENDIF
    IFCONST X16_USE_YM
    MAC xm_ym_write
    lda #({2})
    ldx #({1})
    jsr ym_write
    ENDM
    ENDIF
    IFCONST X16_USE_YM
    MAC xm_ym_poke
    lda #({2})
    ldx #({1})
    jsr ym_poke
    ENDM
    ENDIF
; load a built-in ROM patch (0-162) into a channel
    IFCONST X16_USE_YM
    MAC xm_ym_patch_rom
    lda #({1})
    ldx #({2})
    sec
    jsr ym_patch
    ENDM
    ENDIF
    IFCONST X16_USE_YM
    MAC xm_ym_note
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr ym_note
    ENDM
    ENDIF
; note = (octave<<4)|1..12; note 0 releases
    IFCONST X16_USE_YM
    MAC xm_ym_note_bas
    lda #({1})
    ldx #({2})
    jsr ym_note_bas
    ENDM
    ENDIF
    IFCONST X16_USE_YM
    MAC xm_ym_release_note
    lda #({1})
    jsr ym_release_note
    ENDM
    ENDIF
    IFCONST X16_USE_YM
    MAC xm_ym_vol
    lda #({1})
    ldx #({2})
    jsr ym_vol
    ENDM
    ENDIF
    IFCONST X16_USE_YM
    MAC xm_ym_pan
    lda #({1})
    ldx #({2})
    jsr ym_pan
    ENDM
    ENDIF
    IFCONST X16_USE_YM
    MAC xm_ym_drum
    lda #({1})
    ldx #({2})
    jsr ym_drum
    ENDM
    ENDIF

; =====================================================================
; audio/pcm
; =====================================================================
    IFCONST X16_USE_PCM
    MAC xm_pcm_ctrl
    lda #({1})
    jsr pcm_ctrl
    ENDM
    ENDIF
    IFCONST X16_USE_PCM
    MAC xm_pcm_rate
    lda #({1})
    jsr pcm_rate
    ENDM
    ENDIF
    IFCONST X16_USE_PCM
    MAC xm_pcm_reset
    jsr pcm_reset
    ENDM
    ENDIF
    IFCONST X16_USE_PCM
    MAC xm_pcm_put
    lda #({1})
    jsr pcm_put
    ENDM
    ENDIF
    IFCONST X16_USE_PCM
    MAC xm_pcm_write
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr pcm_write
    ENDM
    ENDIF
    IFCONST X16_USE_PCM_STREAM
    MAC xm_pcm_stream_start
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    sta X16_P4
    jsr pcm_stream_start
    ENDM
    ENDIF
    IFCONST X16_USE_PCM_STREAM
    MAC xm_pcm_stream_stop
    jsr pcm_stream_stop
    ENDM
    ENDIF

; =====================================================================
; audio/adpcm
; =====================================================================
    IFCONST X16_USE_ADPCM
    MAC xm_adpcm_init
    jsr adpcm_init
    ENDM
    ENDIF
    IFCONST X16_USE_ADPCM
    MAC xm_adpcm_nibble
    lda #({1})
    jsr adpcm_nibble
    ENDM
    ENDIF
    IFCONST X16_USE_ADPCM
    MAC xm_adpcm_block
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    jsr adpcm_block
    ENDM
    ENDIF

; =====================================================================
; input/input
; =====================================================================
    IFCONST X16_USE_INPUT
    MAC xm_joy_scan
    jsr joy_scan
    ENDM
    ENDIF
; -> A/X/Y = button bytes
    IFCONST X16_USE_INPUT
    MAC xm_joy_get
    lda #({1})
    jsr joy_get
    ENDM
    ENDIF
    IFCONST X16_USE_INPUT
    MAC xm_mouse_show
    lda #({1})
    jsr mouse_show
    ENDM
    ENDIF
    IFCONST X16_USE_INPUT
    MAC xm_mouse_hide
    jsr mouse_hide
    ENDM
    ENDIF
; -> P0/1 = x, P2/3 = y, A = buttons
    IFCONST X16_USE_INPUT
    MAC xm_mouse_get
    jsr mouse_get
    ENDM
    ENDIF
; -> A = PETSCII, 0 if none waiting
    IFCONST X16_USE_INPUT
    MAC xm_key_get
    jsr key_get
    ENDM
    ENDIF
; -> A = PETSCII (blocks)
    IFCONST X16_USE_INPUT
    MAC xm_key_wait
    jsr key_wait
    ENDM
    ENDIF
; -> A = next key without consuming it
    IFCONST X16_USE_INPUT
    MAC xm_key_peek
    jsr key_peek
    ENDM
    ENDIF

; =====================================================================
; storage/bank  (banked RAM)
; =====================================================================
    IFCONST X16_USE_BANK
    MAC xm_bank_set
    lda #({1})
    jsr bank_set
    ENDM
    ENDIF
; -> A = byte
    IFCONST X16_USE_BANK
    MAC xm_bank_peek
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #({1})
    jsr bank_peek
    ENDM
    ENDIF
    IFCONST X16_USE_BANK
    MAC xm_bank_poke
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #({3})
    ldx #({1})
    jsr bank_poke
    ENDM
    ENDIF
    IFCONST X16_USE_BANK
    MAC xm_mem_to_bank
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #<({3})
    sta X16_P3
    lda #>({3})
    sta X16_P4
    lda #<({4})
    sta X16_P5
    lda #>({4})
    sta X16_P6
    jsr mem_to_bank
    ENDM
    ENDIF

; =====================================================================
; storage/bankalloc
; =====================================================================
    IFCONST X16_USE_BANKALLOC
    MAC xm_bank_alloc_init
    lda #({1})
    ldx #({2})
    jsr bank_alloc_init
    ENDM
    ENDIF
; -> carry clear, A = the bank number
    IFCONST X16_USE_BANKALLOC
    MAC xm_bank_alloc
    jsr bank_alloc
    ENDM
    ENDIF
    IFCONST X16_USE_BANKALLOC
    MAC xm_bank_free
    lda #({1})
    jsr bank_free
    ENDM
    ENDIF
    IFCONST X16_USE_BANKALLOC
    MAC xm_bank_reserve
    lda #({1})
    jsr bank_reserve
    ENDM
    ENDIF

; =====================================================================
; storage/mem  (KERNAL block ops; stream to/from VERA_DATA0 too)
; =====================================================================
    IFCONST X16_USE_MEM
    MAC xm_mem_fill
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    jsr mem_fill
    ENDM
    ENDIF
    IFCONST X16_USE_MEM
    MAC xm_mem_copy
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    jsr mem_copy
    ENDM
    ENDIF
; -> A = CRC low, X = CRC high
    IFCONST X16_USE_MEM
    MAC xm_mem_crc
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr mem_crc
    ENDM
    ENDIF
; -> A/X = one past the last output byte
    IFCONST X16_USE_MEM
    MAC xm_mem_decompress
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr mem_decompress
    ENDM
    ENDIF

; =====================================================================
; storage/load
; =====================================================================
    IFCONST X16_USE_LOAD
    MAC xm_fs_setname
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    jsr fs_setname
    ENDM
    ENDIF
; -> carry set = error, A = KERNAL error code
    IFCONST X16_USE_LOAD
    MAC xm_fs_load
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    lda #({4})
    sta X16_P4
    lda #<({5})
    sta X16_P5
    lda #>({5})
    sta X16_P6
    jsr fs_load
    ENDM
    ENDIF
    IFCONST X16_USE_LOAD
    MAC xm_fs_vload
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    lda #({4})
    sta X16_P4
    lda #<({5})
    sta X16_P5
    lda #>({5})
    sta X16_P6
    jsr fs_vload
    ENDM
    ENDIF

; =====================================================================
; storage/dos
; =====================================================================
; -> A = status code
    IFCONST X16_USE_DOS
    MAC xm_dos_cmd
    lda #<({1})
    ldx #>({1})
    ldy #({2})
    jsr dos_cmd
    ENDM
    ENDIF
    IFCONST X16_USE_DOS
    MAC xm_dos_status
    jsr dos_status
    ENDM
    ENDIF
    IFCONST X16_USE_DOS
    MAC xm_dos_delete
    lda #<({1})
    ldx #>({1})
    ldy #({2})
    jsr dos_delete
    ENDM
    ENDIF

; =====================================================================
; storage/bmx
; =====================================================================
    IFCONST X16_USE_BMX
    MAC xm_bmx_load
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    lda #({4})
    sta X16_P4
    lda #<({5})
    sta X16_P5
    lda #>({5})
    sta X16_P6
    jsr bmx_load
    ENDM
    ENDIF

; =====================================================================
; util/math
; =====================================================================
    IFCONST X16_USE_MATH
    MAC xm_rnd_seed
    lda #<({1})
    ldx #>({1})
    jsr rnd_seed
    ENDM
    ENDIF
; -> A = -127..127
    IFCONST X16_USE_MATH
    MAC xm_sin8
    lda #({1})
    jsr sin8
    ENDM
    ENDIF
    IFCONST X16_USE_MATH
    MAC xm_cos8
    lda #({1})
    jsr cos8
    ENDM
    ENDIF
; -> A = 1..255
    IFCONST X16_USE_MATH
    MAC xm_sin8u
    lda #({1})
    jsr sin8u
    ENDM
    ENDIF
    IFCONST X16_USE_MATH
    MAC xm_cos8u
    lda #({1})
    jsr cos8u
    ENDM
    ENDIF
; -> A = angle 0-255
    IFCONST X16_USE_MATH
    MAC xm_atan2
    lda #({1})
    ldx #({2})
    jsr atan2
    ENDM
    ENDIF
; -> A = interpolated value
    IFCONST X16_USE_MATH
    MAC xm_lerp8
    lda #({1})
    sta X16_P0
    lda #({2})
    sta X16_P1
    lda #({3})
    jsr lerp8
    ENDM
    ENDIF

; =====================================================================
; util/collide
; =====================================================================
; -> carry set if the two boxes overlap (8-bit coordinates and sizes)
    IFCONST X16_USE_COLLIDE
    MAC xm_collide8
    lda #({1})
    sta X16_P0
    lda #({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    lda #({4})
    sta X16_P3
    lda #({5})
    sta X16_P4
    lda #({6})
    sta X16_P5
    lda #({7})
    sta X16_P6
    lda #({8})
    sta X16_P7
    jsr collide8
    ENDM
    ENDIF
; -> carry set if the two boxes overlap (16-bit; writes cl_* directly)
    IFCONST X16_USE_COLLIDE
    MAC xm_collide16
    lda #<({1})
    sta cl_ax
    lda #>({1})
    sta cl_ax+1
    lda #<({2})
    sta cl_ay
    lda #>({2})
    sta cl_ay+1
    lda #<({3})
    sta cl_aw
    lda #>({3})
    sta cl_aw+1
    lda #<({4})
    sta cl_ah
    lda #>({4})
    sta cl_ah+1
    lda #<({5})
    sta cl_bx
    lda #>({5})
    sta cl_bx+1
    lda #<({6})
    sta cl_by
    lda #>({6})
    sta cl_by+1
    lda #<({7})
    sta cl_bw
    lda #>({7})
    sta cl_bw+1
    lda #<({8})
    sta cl_bh
    lda #>({8})
    sta cl_bh+1
    jsr collide16
    ENDM
    ENDIF

; =====================================================================
; util/bits
; =====================================================================
    IFCONST X16_USE_BITS
    MAC xm_catnib
    lda #({1})
    ldx #({2})
    jsr catnib
    ENDM
    ENDIF
    IFCONST X16_USE_BITS
    MAC xm_hinib
    lda #({1})
    jsr hinib
    ENDM
    ENDIF
    IFCONST X16_USE_BITS
    MAC xm_lonib
    lda #({1})
    jsr lonib
    ENDM
    ENDIF
    IFCONST X16_USE_BITS
    MAC xm_bit_set
    lda #<({1})
    sta X16_PTR0
    lda #>({1})
    sta X16_PTR0+1
    lda #({2})
    jsr bit_set
    ENDM
    ENDIF
    IFCONST X16_USE_BITS
    MAC xm_bit_clr
    lda #<({1})
    sta X16_PTR0
    lda #>({1})
    sta X16_PTR0+1
    lda #({2})
    jsr bit_clr
    ENDM
    ENDIF
; -> Z clear if any masked bit was set
    IFCONST X16_USE_BITS
    MAC xm_bit_test
    lda #<({1})
    sta X16_PTR0
    lda #>({1})
    sta X16_PTR0+1
    lda #({2})
    jsr bit_test
    ENDM
    ENDIF

; =====================================================================
; util/number
; =====================================================================
; -> A/X = buffer, Y = length
    IFCONST X16_USE_NUMBER
    MAC xm_u16_to_dec
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr u16_to_dec
    ENDM
    ENDIF
; -> A/X = buffer, Y = 4
    IFCONST X16_USE_NUMBER
    MAC xm_u16_to_hex
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr u16_to_hex
    ENDM
    ENDIF
; -> P4/5 = value, carry set on a bad digit
    IFCONST X16_USE_NUMBER
    MAC xm_dec_to_u16
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    jsr dec_to_u16
    ENDM
    ENDIF

; =====================================================================
; util/fixed
; =====================================================================
; -> P4..P7 = product
    IFCONST X16_USE_FIXED
    MAC xm_umul16
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr umul16
    ENDM
    ENDIF
; signed 8.8; -> P0/1 = result
    IFCONST X16_USE_FIXED
    MAC xm_mul88
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr mul88
    ENDM
    ENDIF

; =====================================================================
; util/int16  (load i16_a / i16_b with +i16_const; ops are argument-free)
; =====================================================================
    IFCONST X16_USE_INT16
    MAC xm_i16_from_u8
    lda #({1})
    jsr i16_from_u8
    ENDM
    ENDIF
    IFCONST X16_USE_INT16
    MAC xm_i16_from_s8
    lda #({1})
    jsr i16_from_s8
    ENDM
    ENDIF

; =====================================================================
; util/int32  (load i32_a / i32_b with +i32_const)
; =====================================================================
    IFCONST X16_USE_INT32
    MAC xm_i32_from_u16
    lda #<({1})
    ldx #>({1})
    jsr i32_from_u16
    ENDM
    ENDIF
    IFCONST X16_USE_INT32
    MAC xm_i32_from_s16
    lda #<({1})
    ldx #>({1})
    jsr i32_from_s16
    ENDM
    ENDIF

; =====================================================================
; util/float  (FAC is the accumulator; addr = a 5-byte float in memory)
; =====================================================================
    IFCONST X16_USE_FLOAT
    MAC xm_f_from_u8
    lda #({1})
    jsr f_from_u8
    ENDM
    ENDIF
    IFCONST X16_USE_FLOAT
    MAC xm_f_from_s16
    lda #<({1})
    ldx #>({1})
    jsr f_from_s16
    ENDM
    ENDIF
    IFCONST X16_USE_FLOAT
    MAC xm_f_load
    lda #<({1})
    ldy #>({1})
    jsr f_load
    ENDM
    ENDIF
    IFCONST X16_USE_FLOAT
    MAC xm_f_store
    lda #<({1})
    ldy #>({1})
    jsr f_store
    ENDM
    ENDIF
    IFCONST X16_USE_FLOAT
    MAC xm_f_add
    lda #<({1})
    ldy #>({1})
    jsr f_add
    ENDM
    ENDIF
    IFCONST X16_USE_FLOAT
    MAC xm_f_sub
    lda #<({1})
    ldy #>({1})
    jsr f_sub
    ENDM
    ENDIF
    IFCONST X16_USE_FLOAT
    MAC xm_f_mul
    lda #<({1})
    ldy #>({1})
    jsr f_mul
    ENDM
    ENDIF
    IFCONST X16_USE_FLOAT
    MAC xm_f_div
    lda #<({1})
    ldy #>({1})
    jsr f_div
    ENDM
    ENDIF
    IFCONST X16_USE_FLOAT
    MAC xm_f_cmp
    lda #<({1})
    ldy #>({1})
    jsr f_cmp
    ENDM
    ENDIF
; FAC = mem - FAC
    IFCONST X16_USE_FLOAT
    MAC xm_f_rsub
    lda #<({1})
    ldy #>({1})
    jsr f_rsub
    ENDM
    ENDIF
; FAC = mem / FAC
    IFCONST X16_USE_FLOAT
    MAC xm_f_rdiv
    lda #<({1})
    ldy #>({1})
    jsr f_rdiv
    ENDM
    ENDIF
; FAC = FAC ^ mem
    IFCONST X16_USE_FLOAT
    MAC xm_f_pow
    lda #<({1})
    ldy #>({1})
    jsr f_pow
    ENDM
    ENDIF
; FAC = the value parsed from a string of `len` chars
    IFCONST X16_USE_FLOAT
    MAC xm_f_from_str
    lda #<({1})
    ldy #>({1})
    ldx #({2})
    jsr f_from_str
    ENDM
    ENDIF

; =====================================================================
; util/double  (d_ac is the accumulator; addr = an 8-byte double in memory)
; =====================================================================
    IFCONST X16_USE_DOUBLE
    MAC xm_d_load
    lda #<({1})
    ldy #>({1})
    jsr d_load
    ENDM
    ENDIF
    IFCONST X16_USE_DOUBLE
    MAC xm_d_store
    lda #<({1})
    ldy #>({1})
    jsr d_store
    ENDM
    ENDIF
    IFCONST X16_USE_DOUBLE
    MAC xm_d_add
    lda #<({1})
    ldy #>({1})
    jsr d_add
    ENDM
    ENDIF
    IFCONST X16_USE_DOUBLE
    MAC xm_d_sub
    lda #<({1})
    ldy #>({1})
    jsr d_sub
    ENDM
    ENDIF
    IFCONST X16_USE_DOUBLE
    MAC xm_d_mul
    lda #<({1})
    ldy #>({1})
    jsr d_mul
    ENDM
    ENDIF
    IFCONST X16_USE_DOUBLE
    MAC xm_d_div
    lda #<({1})
    ldy #>({1})
    jsr d_div
    ENDM
    ENDIF
    IFCONST X16_USE_DOUBLE
    MAC xm_d_cmp
    lda #<({1})
    ldy #>({1})
    jsr d_cmp
    ENDM
    ENDIF
; d_ac = d_ac ^ mem  (base ^ exponent)
    IFCONST X16_USE_DOUBLE
    MAC xm_d_pow
    lda #<({1})
    ldy #>({1})
    jsr d_pow
    ENDM
    ENDIF
; d_ac = the value parsed from a string of `len` chars
    IFCONST X16_USE_DOUBLE
    MAC xm_d_from_str
    lda #<({1})
    ldy #>({1})
    ldx #({2})
    jsr d_from_str
    ENDM
    ENDIF
    IFCONST X16_USE_DOUBLE
    MAC xm_d_from_s16
    lda #<({1})
    ldx #>({1})
    jsr d_from_s16
    ENDM
    ENDIF

; =====================================================================
; util/clip
; =====================================================================
    IFCONST X16_USE_CLIP
    MAC xm_clip_set
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #<({3})
    sta X16_P4
    lda #>({3})
    sta X16_P5
    lda #<({4})
    sta X16_P6
    lda #>({4})
    sta X16_P7
    jsr clip_set
    ENDM
    ENDIF

; =====================================================================
; util/buffers  (ring buffer + byte stack)
; =====================================================================
    IFCONST X16_USE_BUFFERS
    MAC xm_rb_init
    jsr rb_init
    ENDM
    ENDIF
; -> carry set if the buffer was full
    IFCONST X16_USE_BUFFERS
    MAC xm_rb_put
    lda #({1})
    jsr rb_put
    ENDM
    ENDIF
; -> A = byte, carry set if empty
    IFCONST X16_USE_BUFFERS
    MAC xm_rb_get
    jsr rb_get
    ENDM
    ENDIF
    IFCONST X16_USE_BUFFERS
    MAC xm_rb_count
    jsr rb_count
    ENDM
    ENDIF
    IFCONST X16_USE_BUFFERS
    MAC xm_stk_init
    jsr stk_init
    ENDM
    ENDIF
; -> carry set if the stack was full
    IFCONST X16_USE_BUFFERS
    MAC xm_stk_push
    lda #({1})
    jsr stk_push
    ENDM
    ENDIF
; -> A = byte, carry set if empty
    IFCONST X16_USE_BUFFERS
    MAC xm_stk_pop
    jsr stk_pop
    ENDM
    ENDIF
    IFCONST X16_USE_BUFFERS
    MAC xm_stk_depth
    jsr stk_depth
    ENDM
    ENDIF

; =====================================================================
; util/zx0 and util/tscrunch
; =====================================================================
; -> A/X = one past the last output byte
    IFCONST X16_USE_ZX0
    MAC xm_zx0_decompress
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr zx0_decompress
    ENDM
    ENDIF
    IFCONST X16_USE_TSC
    MAC xm_tsc_decompress
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr tsc_decompress
    ENDM
    ENDIF

; =====================================================================
; comms/serial
; =====================================================================
; -> A = count (0-2), carry clear if any found, ser_u0/ser_u1 = bases
    IFCONST X16_USE_SERIAL
    MAC xm_ser_detect
    jsr ser_detect
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL
    MAC xm_ser_init
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({1})
    ldx #>({1})
    jsr ser_init
    ENDM
    ENDIF
; -> carry set if a received byte is waiting
    IFCONST X16_USE_SERIAL
    MAC xm_ser_avail
    jsr ser_avail
    ENDM
    ENDIF
; -> carry clear + A = byte, or carry set if the RX FIFO was empty
    IFCONST X16_USE_SERIAL
    MAC xm_ser_get
    jsr ser_get
    ENDM
    ENDIF
; -> A = byte (blocks until one arrives)
    IFCONST X16_USE_SERIAL
    MAC xm_ser_get_wait
    jsr ser_get_wait
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL
    MAC xm_ser_put
    lda #({1})
    jsr ser_put
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL
    MAC xm_ser_puts
    lda #<({1})
    ldx #>({1})
    jsr ser_puts
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL
    MAC xm_ser_write
    ldy #({2})
    lda #<({1})
    ldx #>({1})
    jsr ser_write
    ENDM
    ENDIF
; -> X16_P4/P5 = bytes stored
    IFCONST X16_USE_SERIAL
    MAC xm_ser_read_until
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({3})
    sta X16_P2
    lda #>({3})
    sta X16_P3
    lda #<({1})
    ldx #>({1})
    jsr ser_read_until
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL
    MAC xm_ser_discard_until
    lda #<({1})
    ldx #>({1})
    jsr ser_discard_until
    ENDM
    ENDIF

; =====================================================================
; comms/zimodem
; =====================================================================
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_init
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({1})
    ldx #>({1})
    jsr zi_init
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_cmd
    lda #<({1})
    ldx #>({1})
    jsr zi_cmd
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_wait_ok
    jsr zi_wait_ok
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_reset
    jsr zi_reset
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_get_ip
    lda #<({1})
    ldx #>({1})
    jsr zi_get_ip
    ENDM
    ENDIF
; -> carry clear if the transfer started, carry set if not found
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_hex_open
    lda #<({1})
    ldx #>({1})
    jsr zi_hex_open
    ENDM
    ENDIF
; -> A = bytes decoded into the buffer, 0 when the file is done
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_hex_chunk
    lda #<({1})
    ldx #>({1})
    jsr zi_hex_chunk
    ENDM
    ENDIF
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_hex_close
    jsr zi_hex_close
    ENDM
    ENDIF
; -> A = bytes written (sugar_digits / 2)
    IFCONST X16_USE_SERIAL_ZIMODEM
    MAC xm_zi_hexdecode
    lda #<({3})
    sta X16_P0
    lda #>({3})
    sta X16_P1
    ldy #({2})
    lda #<({1})
    ldx #>({1})
    jsr zi_hexdecode
    ENDM
    ENDIF

; =====================================================================
; string/string
; =====================================================================
; -> Y = length
    IFCONST X16_USE_STRING
    MAC xm_str_length
    lda #<({1})
    ldx #>({1})
    jsr str_length
    ENDM
    ENDIF
; -> Y = length copied
    IFCONST X16_USE_STRING
    MAC xm_str_copy
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({1})
    ldx #>({1})
    jsr str_copy
    ENDM
    ENDIF
    IFCONST X16_USE_STRING
    MAC xm_str_ncopy
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    ldy #({3})
    lda #<({1})
    ldx #>({1})
    jsr str_ncopy
    ENDM
    ENDIF
; -> A = resulting length
    IFCONST X16_USE_STRING
    MAC xm_str_append
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({1})
    ldx #>({1})
    jsr str_append
    ENDM
    ENDIF
    IFCONST X16_USE_STRING
    MAC xm_str_nappend
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    ldy #({3})
    lda #<({1})
    ldx #>({1})
    jsr str_nappend
    ENDM
    ENDIF
; -> A = -1 / 0 / 1
    IFCONST X16_USE_STRING
    MAC xm_str_compare
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({1})
    ldx #>({1})
    jsr str_compare
    ENDM
    ENDIF
; -> A = hash
    IFCONST X16_USE_STRING
    MAC xm_str_hash
    lda #<({1})
    ldx #>({1})
    jsr str_hash
    ENDM
    ENDIF

; =====================================================================
; string/case
; =====================================================================
    IFCONST X16_USE_STRING_CASE
    MAC xm_str_lower
    lda #<({1})
    ldx #>({1})
    jsr str_lower
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_CASE
    MAC xm_str_lower_iso
    lda #<({1})
    ldx #>({1})
    jsr str_lower_iso
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_CASE
    MAC xm_str_upper
    lda #<({1})
    ldx #>({1})
    jsr str_upper
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_CASE
    MAC xm_str_upper_iso
    lda #<({1})
    ldx #>({1})
    jsr str_upper_iso
    ENDM
    ENDIF
; -> A = -1 / 0 / 1
    IFCONST X16_USE_STRING_CASE
    MAC xm_str_compare_nocase
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({1})
    ldx #>({1})
    jsr str_compare_nocase
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_CASE
    MAC xm_str_compare_nocase_iso
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({1})
    ldx #>({1})
    jsr str_compare_nocase_iso
    ENDM
    ENDIF

; =====================================================================
; string/find
; =====================================================================
; -> carry set + A = index if found
    IFCONST X16_USE_STRING_FIND
    MAC xm_str_find
    ldy #({2})
    lda #<({1})
    ldx #>({1})
    jsr str_find
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_FIND
    MAC xm_str_rfind
    ldy #({2})
    lda #<({1})
    ldx #>({1})
    jsr str_rfind
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_FIND
    MAC xm_str_find_eol
    lda #<({1})
    ldx #>({1})
    jsr str_find_eol
    ENDM
    ENDIF
; -> carry set if the character occurs
    IFCONST X16_USE_STRING_FIND
    MAC xm_str_contains
    ldy #({2})
    lda #<({1})
    ldx #>({1})
    jsr str_contains
    ENDM
    ENDIF
; -> carry set (A = 1) if it matches
    IFCONST X16_USE_STRING_FIND
    MAC xm_str_pattern_match
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #<({1})
    ldx #>({1})
    jsr str_pattern_match
    ENDM
    ENDIF

; =====================================================================
; string/slice
; =====================================================================
    IFCONST X16_USE_STRING_SLICE
    MAC xm_str_left
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    ldy #({3})
    lda #<({1})
    ldx #>({1})
    jsr str_left
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_SLICE
    MAC xm_str_right
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    ldy #({3})
    lda #<({1})
    ldx #>({1})
    jsr str_right
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_SLICE
    MAC xm_str_slice
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    ldy #({4})
    lda #<({1})
    ldx #>({1})
    jsr str_slice
    ENDM
    ENDIF
; -> Y = new length
    IFCONST X16_USE_STRING_SLICE
    MAC xm_str_ltrim
    lda #<({1})
    ldx #>({1})
    jsr str_ltrim
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_SLICE
    MAC xm_str_rtrim
    lda #<({1})
    ldx #>({1})
    jsr str_rtrim
    ENDM
    ENDIF
    IFCONST X16_USE_STRING_SLICE
    MAC xm_str_trim
    lda #<({1})
    ldx #>({1})
    jsr str_trim
    ENDM
    ENDIF
