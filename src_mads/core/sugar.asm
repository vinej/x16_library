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
.if .def X16_USE_VERA
.macro xm_vera_set_addr0 l, m, h
    lda #(:l)
    ldx #(:m)
    ldy #(:h)
    jsr vera_set_addr0
    .endm
.endif
; point port 1
.if .def X16_USE_VERA
.macro xm_vera_set_addr1 l, m, h
    lda #(:l)
    ldx #(:m)
    ldy #(:h)
    jsr vera_set_addr1
    .endm
.endif
; fill `count` bytes with `val` from the current port address
.if .def X16_USE_VERA
.macro xm_vera_fill val, count
    lda #(:val)
    ldx #<(:count)
    ldy #>(:count)
    jsr vera_fill
    .endm
.endif
; copy `count` bytes port0 -> port1 (both pre-pointed)
.if .def X16_USE_VERA
.macro xm_vera_copy count
    ldx #<(:count)
    ldy #>(:count)
    jsr vera_copy
    .endm
.endif

; =====================================================================
; video/screen
; =====================================================================
; -> carry set if the mode is unsupported
.if .def X16_USE_SCREEN
.macro xm_screen_set_mode mode
    lda #(:mode)
    jsr screen_set_mode
    .endm
.endif
.if .def X16_USE_SCREEN
.macro xm_screen_reset
    jsr screen_reset
    .endm
.endif
.if .def X16_USE_SCREEN
.macro xm_screen_cls
    jsr screen_cls
    .endm
.endif
.if .def X16_USE_SCREEN
.macro xm_screen_chrout ch
    lda #(:ch)
    jsr screen_chrout
    .endm
.endif
.if .def X16_USE_SCREEN
.macro xm_screen_color fg, bg
    lda #(:fg)
    ldx #(:bg)
    jsr screen_color
    .endm
.endif
.if .def X16_USE_SCREEN
.macro xm_screen_border col
    lda #(:col)
    jsr screen_border
    .endm
.endif
.if .def X16_USE_SCREEN
.macro xm_screen_locate row, col
    ldx #(:row)
    ldy #(:col)
    jsr screen_locate
    .endm
.endif
.if .def X16_USE_SCREEN
.macro xm_screen_charset cs
    lda #(:cs)
    jsr screen_charset
    .endm
.endif
; print a NUL-terminated string
.if .def X16_USE_SCREEN
.macro xm_screen_puts addr
    lda #<(:addr)
    ldx #>(:addr)
    jsr screen_puts
    .endm
.endif

; =====================================================================
; video/palette
; =====================================================================
; set one entry; rgb is a 12-bit $0RGB value
.if .def X16_USE_PALETTE
.macro xm_pal_set index, rgb
    ldx #(:index)
    lda #<(:rgb)
    ldy #>(:rgb)
    jsr pal_set
    .endm
.endif
; bulk-load `count` entries from RAM (2 bytes each, low first)
.if .def X16_USE_PALETTE
.macro xm_pal_load src, first, count
    lda #<(:src)
    sta X16_PTR0
    lda #>(:src)
    sta X16_PTR0+1
    lda #(:first)
    ldx #(:count)
    jsr pal_load
    .endm
.endif

; =====================================================================
; video/tile  (layer config + tilemap cells)
; =====================================================================
.if .def X16_USE_TILE
.macro xm_layer_on layer
    lda #(:layer)
    jsr layer_on
    .endm
.endif
.if .def X16_USE_TILE
.macro xm_layer_off layer
    lda #(:layer)
    jsr layer_off
    .endm
.endif
.if .def X16_USE_TILE
.macro xm_layer_set_config layer, cfg
    ldx #(:layer)
    lda #(:cfg)
    jsr layer_set_config
    .endm
.endif
.if .def X16_USE_TILE
.macro xm_layer_set_mapbase layer, base
    ldx #(:layer)
    lda #(:base)
    jsr layer_set_mapbase
    .endm
.endif
.if .def X16_USE_TILE
.macro xm_layer_scroll_x layer, val
    ldx #(:layer)
    lda #<(:val)
    sta X16_P0
    lda #>(:val)
    sta X16_P1
    jsr layer_scroll_x
    .endm
.endif
.if .def X16_USE_TILE
.macro xm_layer_scroll_y layer, val
    ldx #(:layer)
    lda #<(:val)
    sta X16_P0
    lda #>(:val)
    sta X16_P1
    jsr layer_scroll_y
    .endm
.endif
.if .def X16_USE_TILE
.macro xm_tile_setptr col, row
    ldx #(:col)
    ldy #(:row)
    jsr tile_setptr
    .endm
.endif
.if .def X16_USE_TILE
.macro xm_tile_put col, row, code, attr
    ldx #(:col)
    ldy #(:row)
    lda #(:code)
    sta X16_P0
    lda #(:attr)
    sta X16_P1
    jsr tile_put
    .endm
.endif
; -> A = screen code, X = attribute
.if .def X16_USE_TILE
.macro xm_tile_get col, row
    ldx #(:col)
    ldy #(:row)
    jsr tile_get
    .endm
.endif

; =====================================================================
; sprite/sprite
; =====================================================================
.if .def X16_USE_SPRITE
.macro xm_sprites_on
    jsr sprites_on
    .endm
.endif
.if .def X16_USE_SPRITE
.macro xm_sprites_off
    jsr sprites_off
    .endm
.endif
.if .def X16_USE_SPRITE
.macro xm_sprite_init_all
    jsr sprite_init_all
    .endm
.endif
.if .def X16_USE_SPRITE
.macro xm_sprite_pos sprite, x, y
    ldx #(:sprite)
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    jsr sprite_pos
    .endm
.endif
; -> P0/1 = x, P2/3 = y
.if .def X16_USE_SPRITE
.macro xm_sprite_get_pos sprite
    ldx #(:sprite)
    jsr sprite_get_pos
    .endm
.endif
; vaddr = 32-byte-aligned 17-bit VRAM address; mode = SPRITE_MODE_4BPP/8BPP
.if .def X16_USE_SPRITE
.macro xm_sprite_image sprite, vaddr, mode
    ldx #(:sprite)
    lda #<(:vaddr)
    sta X16_P0
    lda #>(:vaddr)
    sta X16_P1
    lda #<((:vaddr) >> 16)
    sta X16_P2
    lda #(:mode)
    jsr sprite_image
    .endm
.endif
.if .def X16_USE_SPRITE
.macro xm_sprite_flags sprite, flags
    ldx #(:sprite)
    lda #(:flags)
    jsr sprite_flags
    .endm
.endif
.if .def X16_USE_SPRITE
.macro xm_sprite_z sprite, z
    ldx #(:sprite)
    lda #(:z)
    jsr sprite_z
    .endm
.endif
; width/height are SPRITE_SIZE_8/16/32/64 codes
.if .def X16_USE_SPRITE
.macro xm_sprite_size sprite, wcode, hcode, paloff
    ldx #(:sprite)
    lda #(:paloff)
    sta X16_P0
    ldy #(:hcode)
    lda #(:wcode)
    jsr sprite_size
    .endm
.endif

; =====================================================================
; gfx/bitmap  (320x240 @ 8bpp)
; =====================================================================
.if .def X16_USE_BITMAP
.macro xm_gfx_init
    jsr gfx_init
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_clear col
    lda #(:col)
    jsr gfx_clear
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_pset x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    jsr gfx_pset
    .endm
.endif
; -> A = colour
.if .def X16_USE_BITMAP
.macro xm_gfx_read x, y
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    jsr gfx_read
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_hline x, y, len, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #<(:len)
    sta X16_P4
    lda #>(:len)
    sta X16_P5
    jsr gfx_hline
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_vline x, y, len, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #<(:len)
    sta X16_P4
    lda #>(:len)
    sta X16_P5
    jsr gfx_vline
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_rect x, y, w, h, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #<(:w)
    sta X16_P4
    lda #>(:w)
    sta X16_P5
    lda #(:h)
    sta X16_P6
    jsr gfx_rect
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_frame x, y, w, h, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #<(:w)
    sta X16_P4
    lda #>(:w)
    sta X16_P5
    lda #(:h)
    sta X16_P6
    jsr gfx_frame
    .endm
.endif
; A/X = the address of an 8x8 1bpp pattern
.if .def X16_USE_BITMAP
.macro xm_gfx_pattern_set pat
    lda #<(:pat)
    ldx #>(:pat)
    jsr gfx_pattern_set
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_pattern_rect x, y, w, h
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #<(:w)
    sta X16_P4
    lda #>(:w)
    sta X16_P5
    lda #(:h)
    sta X16_P6
    jsr gfx_pattern_rect
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_line x0, y0, x1, y1, col
    lda #<(:x0)
    sta X16_P0
    lda #>(:x0)
    sta X16_P1
    lda #(:y0)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #<(:x1)
    sta X16_P4
    lda #>(:x1)
    sta X16_P5
    lda #(:y1)
    sta X16_P6
    jsr gfx_line
    .endm
.endif
.if .def X16_USE_BITMAP
.macro xm_gfx_char code, x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #(:code)
    jsr gfx_char
    .endm
.endif
; str = a NUL-terminated string
.if .def X16_USE_BITMAP
.macro xm_gfx_text str, x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #<(:str)
    ldx #>(:str)
    jsr gfx_text
    .endm
.endif

; =====================================================================
; gfx/bitmap2  (640x480 @ 2bpp; colour in A)
; =====================================================================
.if .def X16_USE_BITMAP2
.macro xm_gfx2_init
    jsr gfx2_init
    .endm
.endif
.if .def X16_USE_BITMAP2
.macro xm_gfx2_clear col
    lda #(:col)
    jsr gfx2_clear
    .endm
.endif
.if .def X16_USE_BITMAP2
.macro xm_gfx2_pset x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #(:col)
    jsr gfx2_pset
    .endm
.endif
; -> A = colour, carry set if (x,y) is off screen
.if .def X16_USE_BITMAP2
.macro xm_gfx2_read x, y
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    jsr gfx2_read
    .endm
.endif
.if .def X16_USE_BITMAP2
.macro xm_gfx2_hline x, y, len, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #<(:len)
    sta X16_P4
    lda #>(:len)
    sta X16_P5
    lda #(:col)
    jsr gfx2_hline
    .endm
.endif
.if .def X16_USE_BITMAP2
.macro xm_gfx2_vline x, y, len, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #<(:len)
    sta X16_P4
    lda #>(:len)
    sta X16_P5
    lda #(:col)
    jsr gfx2_vline
    .endm
.endif
.if .def X16_USE_BITMAP2
.macro xm_gfx2_rect x, y, w, h, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #<(:w)
    sta X16_P4
    lda #>(:w)
    sta X16_P5
    lda #<(:h)
    sta X16_P6
    lda #>(:h)
    sta X16_P7
    lda #(:col)
    jsr gfx2_rect
    .endm
.endif
.if .def X16_USE_BITMAP2
.macro xm_gfx2_frame x, y, w, h, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #<(:w)
    sta X16_P4
    lda #>(:w)
    sta X16_P5
    lda #<(:h)
    sta X16_P6
    lda #>(:h)
    sta X16_P7
    lda #(:col)
    jsr gfx2_frame
    .endm
.endif
.if .def X16_USE_BITMAP2
.macro xm_gfx2_line x0, y0, x1, y1, col
    lda #<(:x0)
    sta X16_P0
    lda #>(:x0)
    sta X16_P1
    lda #<(:y0)
    sta X16_P2
    lda #>(:y0)
    sta X16_P3
    lda #<(:x1)
    sta X16_P4
    lda #>(:x1)
    sta X16_P5
    lda #<(:y1)
    sta X16_P6
    lda #>(:y1)
    sta X16_P7
    lda #(:col)
    jsr gfx2_line
    .endm
.endif
; A/X = the address of an 8x8 1bpp pattern
.if .def X16_USE_BITMAP2
.macro xm_gfx2_pattern_set pat
    lda #<(:pat)
    ldx #>(:pat)
    jsr gfx2_pattern_set
    .endm
.endif
.if .def X16_USE_BITMAP2
.macro xm_gfx2_pattern_rect x, y, w, h
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #<(:w)
    sta X16_P4
    lda #>(:w)
    sta X16_P5
    lda #<(:h)
    sta X16_P6
    lda #>(:h)
    sta X16_P7
    jsr gfx2_pattern_rect
    .endm
.endif

; =====================================================================
; gfx/shapes  (engine-agnostic; bind SHP_* to pick the engine)
; =====================================================================
.if .def X16_USE_SHAPES
.macro xm_shape_circle cx, cy, r, col
    lda #<(:cx)
    sta X16_P0
    lda #>(:cx)
    sta X16_P1
    lda #<(:cy)
    sta X16_P2
    lda #>(:cy)
    sta X16_P3
    lda #(:r)
    sta X16_P4
    lda #(:col)
    jsr shape_circle
    .endm
.endif
.if .def X16_USE_SHAPES
.macro xm_shape_disc cx, cy, r, col
    lda #<(:cx)
    sta X16_P0
    lda #>(:cx)
    sta X16_P1
    lda #<(:cy)
    sta X16_P2
    lda #>(:cy)
    sta X16_P3
    lda #(:r)
    sta X16_P4
    lda #(:col)
    jsr shape_disc
    .endm
.endif
.if .def X16_USE_SHAPES
.macro xm_shape_ellipse cx, cy, rx, ry, col
    lda #<(:cx)
    sta X16_P0
    lda #>(:cx)
    sta X16_P1
    lda #<(:cy)
    sta X16_P2
    lda #>(:cy)
    sta X16_P3
    lda #(:rx)
    sta X16_P4
    lda #(:ry)
    sta X16_P5
    lda #(:col)
    jsr shape_ellipse
    .endm
.endif
.if .def X16_USE_SHAPES
.macro xm_shape_fellipse cx, cy, rx, ry, col
    lda #<(:cx)
    sta X16_P0
    lda #>(:cx)
    sta X16_P1
    lda #<(:cy)
    sta X16_P2
    lda #>(:cy)
    sta X16_P3
    lda #(:rx)
    sta X16_P4
    lda #(:ry)
    sta X16_P5
    lda #(:col)
    jsr shape_fellipse
    .endm
.endif
.if .def X16_USE_SHAPES_RRECT
.macro xm_shape_rrect x, y, w, h, r, col
    lda #<(:x)
    sta rr_x
    lda #>(:x)
    sta rr_x+1
    lda #<(:y)
    sta rr_y
    lda #>(:y)
    sta rr_y+1
    lda #<(:w)
    sta rr_w
    lda #>(:w)
    sta rr_w+1
    lda #<(:h)
    sta rr_h
    lda #>(:h)
    sta rr_h+1
    lda #(:r)
    sta rr_r
    lda #(:col)
    jsr shape_rrect
    .endm
.endif
.if .def X16_USE_SHAPES_RRECT
.macro xm_shape_frrect x, y, w, h, r, col
    lda #<(:x)
    sta rr_x
    lda #>(:x)
    sta rr_x+1
    lda #<(:y)
    sta rr_y
    lda #>(:y)
    sta rr_y+1
    lda #<(:w)
    sta rr_w
    lda #>(:w)
    sta rr_w+1
    lda #<(:h)
    sta rr_h
    lda #>(:h)
    sta rr_h+1
    lda #(:r)
    sta rr_r
    lda #(:col)
    jsr shape_frrect
    .endm
.endif
.if .def X16_USE_SHAPES_POLY
.macro xm_shape_polygon cx, cy, r, sides, rot, col
    lda #<(:cx)
    sta X16_P0
    lda #>(:cx)
    sta X16_P1
    lda #<(:cy)
    sta X16_P2
    lda #>(:cy)
    sta X16_P3
    lda #(:r)
    sta X16_P4
    lda #(:sides)
    sta X16_P5
    lda #(:rot)
    sta X16_P6
    lda #(:col)
    jsr shape_polygon
    .endm
.endif
.if .def X16_USE_SHAPES_POLY
.macro xm_shape_fpolygon cx, cy, r, sides, rot, col
    lda #<(:cx)
    sta X16_P0
    lda #>(:cx)
    sta X16_P1
    lda #<(:cy)
    sta X16_P2
    lda #>(:cy)
    sta X16_P3
    lda #(:r)
    sta X16_P4
    lda #(:sides)
    sta X16_P5
    lda #(:rot)
    sta X16_P6
    lda #(:col)
    jsr shape_fpolygon
    .endm
.endif
.if .def X16_USE_SHAPES_ARC
.macro xm_shape_arc cx, cy, r, a0, a1, col
    lda #<(:cx)
    sta X16_P0
    lda #>(:cx)
    sta X16_P1
    lda #<(:cy)
    sta X16_P2
    lda #>(:cy)
    sta X16_P3
    lda #(:r)
    sta X16_P4
    lda #(:a0)
    sta X16_P5
    lda #(:a1)
    sta X16_P6
    lda #(:col)
    jsr shape_arc
    .endm
.endif
.if .def X16_USE_SHAPES_PIE
.macro xm_shape_pie cx, cy, r, a0, a1, col
    lda #<(:cx)
    sta X16_P0
    lda #>(:cx)
    sta X16_P1
    lda #<(:cy)
    sta X16_P2
    lda #>(:cy)
    sta X16_P3
    lda #(:r)
    sta X16_P4
    lda #(:a0)
    sta X16_P5
    lda #(:a1)
    sta X16_P6
    lda #(:col)
    jsr shape_pie
    .endm
.endif
.if .def X16_USE_SHAPES_BEZIER
.macro xm_shape_bezier x0, y0, x1, y1, x2, y2, x3, y3, col
    lda #<(:x0)
    sta bez_x0
    lda #>(:x0)
    sta bez_x0+1
    lda #<(:y0)
    sta bez_y0
    lda #>(:y0)
    sta bez_y0+1
    lda #<(:x1)
    sta bez_x1
    lda #>(:x1)
    sta bez_x1+1
    lda #<(:y1)
    sta bez_y1
    lda #>(:y1)
    sta bez_y1+1
    lda #<(:x2)
    sta bez_x2
    lda #>(:x2)
    sta bez_x2+1
    lda #<(:y2)
    sta bez_y2
    lda #>(:y2)
    sta bez_y2+1
    lda #<(:x3)
    sta bez_x3
    lda #>(:x3)
    sta bez_x3+1
    lda #<(:y3)
    sta bez_y3
    lda #>(:y3)
    sta bez_y3+1
    lda #(:col)
    jsr shape_bezier
    .endm
.endif
; -> carry set if the seed stack overflowed
.if .def X16_USE_SHAPES
.macro xm_shape_flood x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #(:col)
    jsr shape_flood
    .endm
.endif

; =====================================================================
; gfx/verafx  (VERA FX; check vera_has_fx first)
; =====================================================================
.if .def X16_USE_VERAFX
.macro xm_fx_off
    jsr fx_off
    .endm
.endif
; -> P4..P7 = signed 16x16 product
.if .def X16_USE_VERAFX
.macro xm_fx_mult a, b
    lda #<(:a)
    sta X16_P0
    lda #>(:a)
    sta X16_P1
    lda #<(:b)
    sta X16_P2
    lda #>(:b)
    sta X16_P3
    jsr fx_mult
    .endm
.endif
; fill `count` bytes with `val` from the current port address
.if .def X16_USE_VERAFX
.macro xm_fx_fill val, count
    lda #(:val)
    ldx #<(:count)
    ldy #>(:count)
    jsr fx_fill
    .endm
.endif
.if .def X16_USE_VERAFX
.macro xm_fx_clear addrlo, addrmid, addrhi, count
    lda #(:addrlo)
    sta X16_P0
    lda #(:addrmid)
    sta X16_P1
    lda #(:addrhi)
    sta X16_P2
    lda #<(:count)
    sta X16_P3
    lda #>(:count)
    sta X16_P4
    jsr fx_clear
    .endm
.endif
.if .def X16_USE_VERAFX
.macro xm_fx_transp_on
    jsr fx_transp_on
    .endm
.endif
.if .def X16_USE_VERAFX
.macro xm_fx_transp_off
    jsr fx_transp_off
    .endm
.endif
.if .def X16_USE_VERAFX
.macro xm_fx_line x0, y0, x1, y1, col
    lda #<(:x0)
    sta X16_P0
    lda #>(:x0)
    sta X16_P1
    lda #(:y0)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #<(:x1)
    sta X16_P4
    lda #>(:x1)
    sta X16_P5
    lda #(:y1)
    sta X16_P6
    jsr fx_line
    .endm
.endif

; =====================================================================
; system/irq
; =====================================================================
.if .def X16_USE_IRQ
.macro xm_irq_install
    jsr irq_install
    .endm
.endif
.if .def X16_USE_IRQ
.macro xm_irq_remove
    jsr irq_remove
    .endm
.endif
.if .def X16_USE_IRQ
.macro xm_vsync_wait
    jsr vsync_wait
    .endm
.endif
.if .def X16_USE_IRQ
.macro xm_irq_line_install handler
    lda #<(:handler)
    ldx #>(:handler)
    jsr irq_line_install
    .endm
.endif
; handler = 0 for polling (read with sprite_collisions)
.if .def X16_USE_IRQ
.macro xm_irq_sprcol_install handler
    lda #<(:handler)
    ldx #>(:handler)
    jsr irq_sprcol_install
    .endm
.endif
.if .def X16_USE_IRQ
.macro xm_irq_sprcol_remove
    jsr irq_sprcol_remove
    .endm
.endif

; =====================================================================
; audio/psg
; =====================================================================
.if .def X16_USE_PSG
.macro xm_psg_init
    jsr psg_init
    .endm
.endif
.if .def X16_USE_PSG
.macro xm_psg_set_freq voice, freq
    ldx #(:voice)
    lda #<(:freq)
    sta X16_P0
    lda #>(:freq)
    sta X16_P1
    jsr psg_set_freq
    .endm
.endif
.if .def X16_USE_PSG
.macro xm_psg_set_vol voice, vol, pan
    ldx #(:voice)
    lda #(:vol)
    ldy #(:pan)
    jsr psg_set_vol
    .endm
.endif
.if .def X16_USE_PSG
.macro xm_psg_set_wave voice, wave, width
    ldx #(:voice)
    lda #(:wave)
    ldy #(:width)
    jsr psg_set_wave
    .endm
.endif
.if .def X16_USE_PSG
.macro xm_psg_note_off voice
    ldx #(:voice)
    jsr psg_note_off
    .endm
.endif
.if .def X16_USE_PSG
.macro xm_psg_env_start voice
    lda #(:voice)
    jsr psg_env_start
    .endm
.endif
.if .def X16_USE_PSG
.macro xm_psg_env_release voice
    lda #(:voice)
    jsr psg_env_release
    .endm
.endif
.if .def X16_USE_PSG
.macro xm_psg_env_stop voice
    lda #(:voice)
    jsr psg_env_stop
    .endm
.endif
.if .def X16_USE_PSG
.macro xm_psg_env_tick
    jsr psg_env_tick
    .endm
.endif

; =====================================================================
; audio/ym  (YM2151 FM)
; =====================================================================
.if .def X16_USE_YM
.macro xm_ym_init
    jsr ym_init
    .endm
.endif
.if .def X16_USE_YM
.macro xm_ym_write reg, val
    lda #(:val)
    ldx #(:reg)
    jsr ym_write
    .endm
.endif
.if .def X16_USE_YM
.macro xm_ym_poke reg, val
    lda #(:val)
    ldx #(:reg)
    jsr ym_poke
    .endm
.endif
; load a built-in ROM patch (0-162) into a channel
.if .def X16_USE_YM
.macro xm_ym_patch_rom channel, index
    lda #(:channel)
    ldx #(:index)
    sec
    jsr ym_patch
    .endm
.endif
.if .def X16_USE_YM
.macro xm_ym_note channel, kc, kf
    lda #(:channel)
    ldx #(:kc)
    ldy #(:kf)
    jsr ym_note
    .endm
.endif
; note = (octave<<4)|1..12; note 0 releases
.if .def X16_USE_YM
.macro xm_ym_note_bas channel, note
    lda #(:channel)
    ldx #(:note)
    jsr ym_note_bas
    .endm
.endif
.if .def X16_USE_YM
.macro xm_ym_release_note channel
    lda #(:channel)
    jsr ym_release_note
    .endm
.endif
.if .def X16_USE_YM
.macro xm_ym_vol channel, atten
    lda #(:channel)
    ldx #(:atten)
    jsr ym_vol
    .endm
.endif
.if .def X16_USE_YM
.macro xm_ym_pan channel, pan
    lda #(:channel)
    ldx #(:pan)
    jsr ym_pan
    .endm
.endif
.if .def X16_USE_YM
.macro xm_ym_drum channel, note
    lda #(:channel)
    ldx #(:note)
    jsr ym_drum
    .endm
.endif

; =====================================================================
; audio/pcm
; =====================================================================
.if .def X16_USE_PCM
.macro xm_pcm_ctrl byte
    lda #(:byte)
    jsr pcm_ctrl
    .endm
.endif
.if .def X16_USE_PCM
.macro xm_pcm_rate rate
    lda #(:rate)
    jsr pcm_rate
    .endm
.endif
.if .def X16_USE_PCM
.macro xm_pcm_reset
    jsr pcm_reset
    .endm
.endif
.if .def X16_USE_PCM
.macro xm_pcm_put sample
    lda #(:sample)
    jsr pcm_put
    .endm
.endif
.if .def X16_USE_PCM
.macro xm_pcm_write src, count
    lda #<(:src)
    sta X16_P0
    lda #>(:src)
    sta X16_P1
    lda #<(:count)
    sta X16_P2
    lda #>(:count)
    sta X16_P3
    jsr pcm_write
    .endm
.endif
.if .def X16_USE_PCM_STREAM
.macro xm_pcm_stream_start src, count, loop
    lda #<(:src)
    sta X16_P0
    lda #>(:src)
    sta X16_P1
    lda #<(:count)
    sta X16_P2
    lda #>(:count)
    sta X16_P3
    lda #(:loop)
    sta X16_P4
    jsr pcm_stream_start
    .endm
.endif
.if .def X16_USE_PCM_STREAM
.macro xm_pcm_stream_stop
    jsr pcm_stream_stop
    .endm
.endif

; =====================================================================
; audio/adpcm
; =====================================================================
.if .def X16_USE_ADPCM
.macro xm_adpcm_init
    jsr adpcm_init
    .endm
.endif
.if .def X16_USE_ADPCM
.macro xm_adpcm_nibble code
    lda #(:code)
    jsr adpcm_nibble
    .endm
.endif
.if .def X16_USE_ADPCM
.macro xm_adpcm_block src, dst, count
    lda #<(:src)
    sta X16_P0
    lda #>(:src)
    sta X16_P1
    lda #<(:dst)
    sta X16_P2
    lda #>(:dst)
    sta X16_P3
    lda #<(:count)
    sta X16_P4
    lda #>(:count)
    sta X16_P5
    jsr adpcm_block
    .endm
.endif

; =====================================================================
; input/input
; =====================================================================
.if .def X16_USE_INPUT
.macro xm_joy_scan
    jsr joy_scan
    .endm
.endif
; -> A/X/Y = button bytes
.if .def X16_USE_INPUT
.macro xm_joy_get pad
    lda #(:pad)
    jsr joy_get
    .endm
.endif
.if .def X16_USE_INPUT
.macro xm_mouse_show cursor
    lda #(:cursor)
    jsr mouse_show
    .endm
.endif
.if .def X16_USE_INPUT
.macro xm_mouse_hide
    jsr mouse_hide
    .endm
.endif
; -> P0/1 = x, P2/3 = y, A = buttons
.if .def X16_USE_INPUT
.macro xm_mouse_get
    jsr mouse_get
    .endm
.endif
; -> A = PETSCII, 0 if none waiting
.if .def X16_USE_INPUT
.macro xm_key_get
    jsr key_get
    .endm
.endif
; -> A = PETSCII (blocks)
.if .def X16_USE_INPUT
.macro xm_key_wait
    jsr key_wait
    .endm
.endif
; -> A = next key without consuming it
.if .def X16_USE_INPUT
.macro xm_key_peek
    jsr key_peek
    .endm
.endif

; =====================================================================
; storage/bank  (banked RAM)
; =====================================================================
.if .def X16_USE_BANK
.macro xm_bank_set bank
    lda #(:bank)
    jsr bank_set
    .endm
.endif
; -> A = byte
.if .def X16_USE_BANK
.macro xm_bank_peek bank, offset
    lda #<(:offset)
    sta X16_P0
    lda #>(:offset)
    sta X16_P1
    lda #(:bank)
    jsr bank_peek
    .endm
.endif
.if .def X16_USE_BANK
.macro xm_bank_poke bank, offset, byte
    lda #<(:offset)
    sta X16_P0
    lda #>(:offset)
    sta X16_P1
    lda #(:byte)
    ldx #(:bank)
    jsr bank_poke
    .endm
.endif
.if .def X16_USE_BANK
.macro xm_mem_to_bank src, bank, offset, count
    lda #<(:src)
    sta X16_P0
    lda #>(:src)
    sta X16_P1
    lda #(:bank)
    sta X16_P2
    lda #<(:offset)
    sta X16_P3
    lda #>(:offset)
    sta X16_P4
    lda #<(:count)
    sta X16_P5
    lda #>(:count)
    sta X16_P6
    jsr mem_to_bank
    .endm
.endif

; =====================================================================
; storage/bankalloc
; =====================================================================
.if .def X16_USE_BANKALLOC
.macro xm_bank_alloc_init first, last
    lda #(:first)
    ldx #(:last)
    jsr bank_alloc_init
    .endm
.endif
; -> carry clear, A = the bank number
.if .def X16_USE_BANKALLOC
.macro xm_bank_alloc
    jsr bank_alloc
    .endm
.endif
.if .def X16_USE_BANKALLOC
.macro xm_bank_free bank
    lda #(:bank)
    jsr bank_free
    .endm
.endif
.if .def X16_USE_BANKALLOC
.macro xm_bank_reserve bank
    lda #(:bank)
    jsr bank_reserve
    .endm
.endif

; =====================================================================
; storage/mem  (KERNAL block ops; stream to/from VERA_DATA0 too)
; =====================================================================
.if .def X16_USE_MEM
.macro xm_mem_fill dst, count, val
    lda #<(:dst)
    sta X16_P0
    lda #>(:dst)
    sta X16_P1
    lda #<(:count)
    sta X16_P2
    lda #>(:count)
    sta X16_P3
    lda #(:val)
    jsr mem_fill
    .endm
.endif
.if .def X16_USE_MEM
.macro xm_mem_copy src, dst, count
    lda #<(:src)
    sta X16_P0
    lda #>(:src)
    sta X16_P1
    lda #<(:dst)
    sta X16_P2
    lda #>(:dst)
    sta X16_P3
    lda #<(:count)
    sta X16_P4
    lda #>(:count)
    sta X16_P5
    jsr mem_copy
    .endm
.endif
; -> A = CRC low, X = CRC high
.if .def X16_USE_MEM
.macro xm_mem_crc addr, count
    lda #<(:addr)
    sta X16_P0
    lda #>(:addr)
    sta X16_P1
    lda #<(:count)
    sta X16_P2
    lda #>(:count)
    sta X16_P3
    jsr mem_crc
    .endm
.endif
; -> A/X = one past the last output byte
.if .def X16_USE_MEM
.macro xm_mem_decompress src, dst
    lda #<(:src)
    sta X16_P0
    lda #>(:src)
    sta X16_P1
    lda #<(:dst)
    sta X16_P2
    lda #>(:dst)
    sta X16_P3
    jsr mem_decompress
    .endm
.endif

; =====================================================================
; storage/load
; =====================================================================
.if .def X16_USE_LOAD
.macro xm_fs_setname name, len
    lda #<(:name)
    sta X16_P0
    lda #>(:name)
    sta X16_P1
    lda #(:len)
    jsr fs_setname
    .endm
.endif
; -> carry set = error, A = KERNAL error code
.if .def X16_USE_LOAD
.macro xm_fs_load name, len, device, sa, dst
    lda #<(:name)
    sta X16_P0
    lda #>(:name)
    sta X16_P1
    lda #(:len)
    sta X16_P2
    lda #(:device)
    sta X16_P3
    lda #(:sa)
    sta X16_P4
    lda #<(:dst)
    sta X16_P5
    lda #>(:dst)
    sta X16_P6
    jsr fs_load
    .endm
.endif
.if .def X16_USE_LOAD
.macro xm_fs_vload name, len, device, vbank, vaddr
    lda #<(:name)
    sta X16_P0
    lda #>(:name)
    sta X16_P1
    lda #(:len)
    sta X16_P2
    lda #(:device)
    sta X16_P3
    lda #(:vbank)
    sta X16_P4
    lda #<(:vaddr)
    sta X16_P5
    lda #>(:vaddr)
    sta X16_P6
    jsr fs_vload
    .endm
.endif

; =====================================================================
; storage/dos
; =====================================================================
; -> A = status code
.if .def X16_USE_DOS
.macro xm_dos_cmd cmd, len
    lda #<(:cmd)
    ldx #>(:cmd)
    ldy #(:len)
    jsr dos_cmd
    .endm
.endif
.if .def X16_USE_DOS
.macro xm_dos_status
    jsr dos_status
    .endm
.endif
.if .def X16_USE_DOS
.macro xm_dos_delete name, len
    lda #<(:name)
    ldx #>(:name)
    ldy #(:len)
    jsr dos_delete
    .endm
.endif

; =====================================================================
; storage/bmx
; =====================================================================
.if .def X16_USE_BMX
.macro xm_bmx_load name, len, device, vbank, vaddr
    lda #<(:name)
    sta X16_P0
    lda #>(:name)
    sta X16_P1
    lda #(:len)
    sta X16_P2
    lda #(:device)
    sta X16_P3
    lda #(:vbank)
    sta X16_P4
    lda #<(:vaddr)
    sta X16_P5
    lda #>(:vaddr)
    sta X16_P6
    jsr bmx_load
    .endm
.endif

; =====================================================================
; util/math
; =====================================================================
.if .def X16_USE_MATH
.macro xm_rnd_seed seed
    lda #<(:seed)
    ldx #>(:seed)
    jsr rnd_seed
    .endm
.endif
; -> A = -127..127
.if .def X16_USE_MATH
.macro xm_sin8 angle
    lda #(:angle)
    jsr sin8
    .endm
.endif
.if .def X16_USE_MATH
.macro xm_cos8 angle
    lda #(:angle)
    jsr cos8
    .endm
.endif
; -> A = 1..255
.if .def X16_USE_MATH
.macro xm_sin8u angle
    lda #(:angle)
    jsr sin8u
    .endm
.endif
.if .def X16_USE_MATH
.macro xm_cos8u angle
    lda #(:angle)
    jsr cos8u
    .endm
.endif
; -> A = angle 0-255
.if .def X16_USE_MATH
.macro xm_atan2 dx, dy
    lda #(:dx)
    ldx #(:dy)
    jsr atan2
    .endm
.endif
; -> A = interpolated value
.if .def X16_USE_MATH
.macro xm_lerp8 a, b, t
    lda #(:a)
    sta X16_P0
    lda #(:b)
    sta X16_P1
    lda #(:t)
    jsr lerp8
    .endm
.endif

; =====================================================================
; util/collide
; =====================================================================
; -> carry set if the two boxes overlap (8-bit coordinates and sizes)
.if .def X16_USE_COLLIDE
.macro xm_collide8 ax, ay, aw, ah, bx, by, bw, bh
    lda #(:ax)
    sta X16_P0
    lda #(:ay)
    sta X16_P1
    lda #(:aw)
    sta X16_P2
    lda #(:ah)
    sta X16_P3
    lda #(:bx)
    sta X16_P4
    lda #(:by)
    sta X16_P5
    lda #(:bw)
    sta X16_P6
    lda #(:bh)
    sta X16_P7
    jsr collide8
    .endm
.endif
; -> carry set if the two boxes overlap (16-bit; writes cl_* directly)
.if .def X16_USE_COLLIDE
.macro xm_collide16 ax, ay, aw, ah, bx, by, bw, bh
    lda #<(:ax)
    sta cl_ax
    lda #>(:ax)
    sta cl_ax+1
    lda #<(:ay)
    sta cl_ay
    lda #>(:ay)
    sta cl_ay+1
    lda #<(:aw)
    sta cl_aw
    lda #>(:aw)
    sta cl_aw+1
    lda #<(:ah)
    sta cl_ah
    lda #>(:ah)
    sta cl_ah+1
    lda #<(:bx)
    sta cl_bx
    lda #>(:bx)
    sta cl_bx+1
    lda #<(:by)
    sta cl_by
    lda #>(:by)
    sta cl_by+1
    lda #<(:bw)
    sta cl_bw
    lda #>(:bw)
    sta cl_bw+1
    lda #<(:bh)
    sta cl_bh
    lda #>(:bh)
    sta cl_bh+1
    jsr collide16
    .endm
.endif

; =====================================================================
; util/bits
; =====================================================================
.if .def X16_USE_BITS
.macro xm_catnib hi, lo
    lda #(:hi)
    ldx #(:lo)
    jsr catnib
    .endm
.endif
.if .def X16_USE_BITS
.macro xm_hinib byte
    lda #(:byte)
    jsr hinib
    .endm
.endif
.if .def X16_USE_BITS
.macro xm_lonib byte
    lda #(:byte)
    jsr lonib
    .endm
.endif
.if .def X16_USE_BITS
.macro xm_bit_set addr, mask
    lda #<(:addr)
    sta X16_PTR0
    lda #>(:addr)
    sta X16_PTR0+1
    lda #(:mask)
    jsr bit_set
    .endm
.endif
.if .def X16_USE_BITS
.macro xm_bit_clr addr, mask
    lda #<(:addr)
    sta X16_PTR0
    lda #>(:addr)
    sta X16_PTR0+1
    lda #(:mask)
    jsr bit_clr
    .endm
.endif
; -> Z clear if any masked bit was set
.if .def X16_USE_BITS
.macro xm_bit_test addr, mask
    lda #<(:addr)
    sta X16_PTR0
    lda #>(:addr)
    sta X16_PTR0+1
    lda #(:mask)
    jsr bit_test
    .endm
.endif

; =====================================================================
; util/number
; =====================================================================
; -> A/X = buffer, Y = length
.if .def X16_USE_NUMBER
.macro xm_u16_to_dec value
    lda #<(:value)
    sta X16_P0
    lda #>(:value)
    sta X16_P1
    jsr u16_to_dec
    .endm
.endif
; -> A/X = buffer, Y = 4
.if .def X16_USE_NUMBER
.macro xm_u16_to_hex value
    lda #<(:value)
    sta X16_P0
    lda #>(:value)
    sta X16_P1
    jsr u16_to_hex
    .endm
.endif
; -> P4/5 = value, carry set on a bad digit
.if .def X16_USE_NUMBER
.macro xm_dec_to_u16 str, len
    lda #<(:str)
    sta X16_P0
    lda #>(:str)
    sta X16_P1
    lda #(:len)
    sta X16_P2
    jsr dec_to_u16
    .endm
.endif

; =====================================================================
; util/fixed
; =====================================================================
; -> P4..P7 = product
.if .def X16_USE_FIXED
.macro xm_umul16 a, b
    lda #<(:a)
    sta X16_P0
    lda #>(:a)
    sta X16_P1
    lda #<(:b)
    sta X16_P2
    lda #>(:b)
    sta X16_P3
    jsr umul16
    .endm
.endif
; signed 8.8; -> P0/1 = result
.if .def X16_USE_FIXED
.macro xm_mul88 a, b
    lda #<(:a)
    sta X16_P0
    lda #>(:a)
    sta X16_P1
    lda #<(:b)
    sta X16_P2
    lda #>(:b)
    sta X16_P3
    jsr mul88
    .endm
.endif

; =====================================================================
; util/int16  (load i16_a / i16_b with +i16_const; ops are argument-free)
; =====================================================================
.if .def X16_USE_INT16
.macro xm_i16_from_u8 byte
    lda #(:byte)
    jsr i16_from_u8
    .endm
.endif
.if .def X16_USE_INT16
.macro xm_i16_from_s8 byte
    lda #(:byte)
    jsr i16_from_s8
    .endm
.endif

; =====================================================================
; util/int32  (load i32_a / i32_b with +i32_const)
; =====================================================================
.if .def X16_USE_INT32
.macro xm_i32_from_u16 value
    lda #<(:value)
    ldx #>(:value)
    jsr i32_from_u16
    .endm
.endif
.if .def X16_USE_INT32
.macro xm_i32_from_s16 value
    lda #<(:value)
    ldx #>(:value)
    jsr i32_from_s16
    .endm
.endif

; =====================================================================
; util/float  (FAC is the accumulator; addr = a 5-byte float in memory)
; =====================================================================
.if .def X16_USE_FLOAT
.macro xm_f_from_u8 byte
    lda #(:byte)
    jsr f_from_u8
    .endm
.endif
.if .def X16_USE_FLOAT
.macro xm_f_from_s16 value
    lda #<(:value)
    ldx #>(:value)
    jsr f_from_s16
    .endm
.endif
.if .def X16_USE_FLOAT
.macro xm_f_load addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_load
    .endm
.endif
.if .def X16_USE_FLOAT
.macro xm_f_store addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_store
    .endm
.endif
.if .def X16_USE_FLOAT
.macro xm_f_add addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_add
    .endm
.endif
.if .def X16_USE_FLOAT
.macro xm_f_sub addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_sub
    .endm
.endif
.if .def X16_USE_FLOAT
.macro xm_f_mul addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_mul
    .endm
.endif
.if .def X16_USE_FLOAT
.macro xm_f_div addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_div
    .endm
.endif
.if .def X16_USE_FLOAT
.macro xm_f_cmp addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_cmp
    .endm
.endif
; FAC = mem - FAC
.if .def X16_USE_FLOAT
.macro xm_f_rsub addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_rsub
    .endm
.endif
; FAC = mem / FAC
.if .def X16_USE_FLOAT
.macro xm_f_rdiv addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_rdiv
    .endm
.endif
; FAC = FAC ^ mem
.if .def X16_USE_FLOAT
.macro xm_f_pow addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr f_pow
    .endm
.endif
; FAC = the value parsed from a string of `len` chars
.if .def X16_USE_FLOAT
.macro xm_f_from_str str, len
    lda #<(:str)
    ldy #>(:str)
    ldx #(:len)
    jsr f_from_str
    .endm
.endif

; =====================================================================
; util/double  (d_ac is the accumulator; addr = an 8-byte double in memory)
; =====================================================================
.if .def X16_USE_DOUBLE
.macro xm_d_load addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr d_load
    .endm
.endif
.if .def X16_USE_DOUBLE
.macro xm_d_store addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr d_store
    .endm
.endif
.if .def X16_USE_DOUBLE
.macro xm_d_add addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr d_add
    .endm
.endif
.if .def X16_USE_DOUBLE
.macro xm_d_sub addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr d_sub
    .endm
.endif
.if .def X16_USE_DOUBLE
.macro xm_d_mul addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr d_mul
    .endm
.endif
.if .def X16_USE_DOUBLE
.macro xm_d_div addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr d_div
    .endm
.endif
.if .def X16_USE_DOUBLE
.macro xm_d_cmp addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr d_cmp
    .endm
.endif
; d_ac = d_ac ^ mem  (base ^ exponent)
.if .def X16_USE_DOUBLE
.macro xm_d_pow addr
    lda #<(:addr)
    ldy #>(:addr)
    jsr d_pow
    .endm
.endif
; d_ac = the value parsed from a string of `len` chars
.if .def X16_USE_DOUBLE
.macro xm_d_from_str str, len
    lda #<(:str)
    ldy #>(:str)
    ldx #(:len)
    jsr d_from_str
    .endm
.endif
.if .def X16_USE_DOUBLE
.macro xm_d_from_s16 value
    lda #<(:value)
    ldx #>(:value)
    jsr d_from_s16
    .endm
.endif

; =====================================================================
; util/clip
; =====================================================================
.if .def X16_USE_CLIP
.macro xm_clip_set xmin, ymin, xmax, ymax
    lda #<(:xmin)
    sta X16_P0
    lda #>(:xmin)
    sta X16_P1
    lda #<(:ymin)
    sta X16_P2
    lda #>(:ymin)
    sta X16_P3
    lda #<(:xmax)
    sta X16_P4
    lda #>(:xmax)
    sta X16_P5
    lda #<(:ymax)
    sta X16_P6
    lda #>(:ymax)
    sta X16_P7
    jsr clip_set
    .endm
.endif

; =====================================================================
; util/buffers  (ring buffer + byte stack)
; =====================================================================
.if .def X16_USE_BUFFERS
.macro xm_rb_init
    jsr rb_init
    .endm
.endif
; -> carry set if the buffer was full
.if .def X16_USE_BUFFERS
.macro xm_rb_put byte
    lda #(:byte)
    jsr rb_put
    .endm
.endif
; -> A = byte, carry set if empty
.if .def X16_USE_BUFFERS
.macro xm_rb_get
    jsr rb_get
    .endm
.endif
.if .def X16_USE_BUFFERS
.macro xm_rb_count
    jsr rb_count
    .endm
.endif
.if .def X16_USE_BUFFERS
.macro xm_stk_init
    jsr stk_init
    .endm
.endif
; -> carry set if the stack was full
.if .def X16_USE_BUFFERS
.macro xm_stk_push byte
    lda #(:byte)
    jsr stk_push
    .endm
.endif
; -> A = byte, carry set if empty
.if .def X16_USE_BUFFERS
.macro xm_stk_pop
    jsr stk_pop
    .endm
.endif
.if .def X16_USE_BUFFERS
.macro xm_stk_depth
    jsr stk_depth
    .endm
.endif

; =====================================================================
; util/zx0 and util/tscrunch
; =====================================================================
; -> A/X = one past the last output byte
.if .def X16_USE_ZX0
.macro xm_zx0_decompress src, dst
    lda #<(:src)
    sta X16_P0
    lda #>(:src)
    sta X16_P1
    lda #<(:dst)
    sta X16_P2
    lda #>(:dst)
    sta X16_P3
    jsr zx0_decompress
    .endm
.endif
.if .def X16_USE_TSC
.macro xm_tsc_decompress src, dst
    lda #<(:src)
    sta X16_P0
    lda #>(:src)
    sta X16_P1
    lda #<(:dst)
    sta X16_P2
    lda #>(:dst)
    sta X16_P3
    jsr tsc_decompress
    .endm
.endif
