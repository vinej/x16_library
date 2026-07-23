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
;       X16_USE_BITMAP2H     = 1
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
; video/vdc  (VERA display composer)
; =====================================================================
; -> A = DC_VIDEO
.if .def X16_USE_VERA_DC
.macro xm_vdc_get_video
    jsr vdc_get_video
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_set_video video
    lda #(:video)
    jsr vdc_set_video
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_set_output mode
    lda #(:mode)
    jsr vdc_set_output
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_set_layers mask
    lda #(:mask)
    jsr vdc_set_layers
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_layer_on mask
    lda #(:mask)
    jsr vdc_layer_on
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_layer_off mask
    lda #(:mask)
    jsr vdc_layer_off
    .endm
.endif
; -> A = HSCALE, X = VSCALE
.if .def X16_USE_VERA_DC
.macro xm_vdc_get_scale
    jsr vdc_get_scale
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_set_scale hscale, vscale
    lda #(:hscale)
    ldx #(:vscale)
    jsr vdc_set_scale
    .endm
.endif
; -> A = border palette index
.if .def X16_USE_VERA_DC
.macro xm_vdc_get_border
    jsr vdc_get_border
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_set_border color
    lda #(:color)
    jsr vdc_set_border
    .endm
.endif
; -> A = HSTART, X = HSTOP, Y = VSTART, r0L = VSTOP
.if .def X16_USE_VERA_DC
.macro xm_vdc_get_active_raw
    jsr vdc_get_active_raw
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_set_active_raw hstart, hstop, vstart, vstop
    lda #(:hstart)
    ldx #(:hstop)
    ldy #(:vstart)
    pha
    lda #(:vstop)
    sta r0L
    pla
    jsr vdc_set_active_raw
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_set_active hstart, hstop, vstart, vstop
    lda #<(:hstart)
    sta X16_P0
    lda #>(:hstart)
    sta X16_P1
    lda #<(:hstop)
    sta X16_P2
    lda #>(:hstop)
    sta X16_P3
    lda #<(:vstart)
    sta X16_P4
    lda #>(:vstart)
    sta X16_P5
    lda #<(:vstop)
    sta X16_P6
    lda #>(:vstop)
    sta X16_P7
    jsr vdc_set_active
    .endm
.endif
.if .def X16_USE_VERA_DC
.macro xm_vdc_fullscreen
    jsr vdc_fullscreen
    .endm
.endif
; -> carry set if valid, A = major, X = minor, Y = build
.if .def X16_USE_VERA_DC
.macro xm_vdc_get_version
    jsr vdc_get_version
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
; gfx/bitmap8l  (320x240 @ 8bpp)
; =====================================================================
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_init
    jsr gfx8l_init
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_clear col
    lda #(:col)
    jsr gfx8l_clear
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_pset x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    jsr gfx8l_pset
    .endm
.endif
; -> A = colour
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_read x, y
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    jsr gfx8l_read
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_hline x, y, len, col
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
    jsr gfx8l_hline
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_vline x, y, len, col
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
    jsr gfx8l_vline
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_rect x, y, w, h, col
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
    jsr gfx8l_rect
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_frame x, y, w, h, col
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
    jsr gfx8l_frame
    .endm
.endif
; A/X = the address of an 8x8 1bpp pattern
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_pattern_set pat
    lda #<(:pat)
    ldx #>(:pat)
    jsr gfx8l_pattern_set
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_pattern_rect x, y, w, h
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
    jsr gfx8l_pattern_rect
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_line x0, y0, x1, y1, col
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
    jsr gfx8l_line
    .endm
.endif
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_char code, x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #(:code)
    jsr gfx8l_char
    .endm
.endif
; str = a NUL-terminated string
.if .def X16_USE_BITMAP8L
.macro xm_gfx8l_text str, x, y, col
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
    jsr gfx8l_text
    .endm
.endif

; =====================================================================
; gfx/bitmap8h  (640x480 @ 8bpp; VERA_2 SDRAM layer)
; =====================================================================
.if .def X16_USE_BITMAP8H
.macro xm_gfx8h_has
    jsr gfx8h_has
    .endm
.macro xm_gfx8h_init
    jsr gfx8h_init
    .endm
.macro xm_gfx8h_off
    jsr gfx8h_off
    .endm
.macro xm_gfx8h_passthru_on
    jsr gfx8h_passthru_on
    .endm
.macro xm_gfx8h_passthru_off
    jsr gfx8h_passthru_off
    .endm
.macro xm_gfx8h_pal_set index, lo, hi
    ldx #(:index)
    lda #(:lo)
    ldy #(:hi)
    jsr gfx8h_pal_set
    .endm
.macro xm_gfx8h_pal_load src, first, count
    lda #<(:src)
    sta X16_PTR0
    lda #>(:src)
    sta X16_PTR0+1
    lda #(:first)
    ldx #(:count)
    jsr gfx8h_pal_load
    .endm
.macro xm_gfx8h_clear col
    lda #(:col)
    jsr gfx8h_clear
    .endm
.macro xm_gfx8h_pset x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #(:col)
    jsr gfx8h_pset
    .endm
.macro xm_gfx8h_read x, y
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    jsr gfx8h_read
    .endm
.macro xm_gfx8h_hline x, y, len, col
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
    jsr gfx8h_hline
    .endm
.macro xm_gfx8h_vline x, y, len, col
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
    jsr gfx8h_vline
    .endm
.macro xm_gfx8h_rect x, y, w, h, col
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
    jsr gfx8h_rect
    .endm
.macro xm_gfx8h_frame x, y, w, h, col
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
    jsr gfx8h_frame
    .endm
.macro xm_gfx8h_line x0, y0, x1, y1, col
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
    jsr gfx8h_line
    .endm
.macro xm_gfx8h_pattern_set pat, bg, fg
    lda #(:bg)
    sta X16_P4
    lda #(:fg)
    sta X16_P5
    lda #<(:pat)
    ldx #>(:pat)
    jsr gfx8h_pattern_set
    .endm
.macro xm_gfx8h_pattern_rect x, y, w, h
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
    jsr gfx8h_pattern_rect
    .endm
.macro xm_gfx8h_copy src, dst, len
    lda #<(:src)
    sta X16_P0
    lda #>((:src) >> 8)
    sta X16_P1
    lda #>((:src) >> 16)
    sta X16_P2
    lda #<(:dst)
    sta X16_P3
    lda #>((:dst) >> 8)
    sta X16_P4
    lda #>((:dst) >> 16)
    sta X16_P5
    lda #<(:len)
    ldx #>((:len) >> 8)
    ldy #>((:len) >> 16)
    jsr gfx8h_copy
    .endm
.endif

; =====================================================================
; gfx/bitmap2h  (640x480 @ 2bpp; colour in A)
; =====================================================================
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_init
    jsr gfx2h_init
    .endm
.endif
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_clear col
    lda #(:col)
    jsr gfx2h_clear
    .endm
.endif
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_pset x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #(:col)
    jsr gfx2h_pset
    .endm
.endif
; -> A = colour, carry set if (x,y) is off screen
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_read x, y
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    jsr gfx2h_read
    .endm
.endif
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_hline x, y, len, col
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
    jsr gfx2h_hline
    .endm
.endif
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_vline x, y, len, col
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
    jsr gfx2h_vline
    .endm
.endif
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_rect x, y, w, h, col
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
    jsr gfx2h_rect
    .endm
.endif
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_frame x, y, w, h, col
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
    jsr gfx2h_frame
    .endm
.endif
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_line x0, y0, x1, y1, col
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
    jsr gfx2h_line
    .endm
.endif
; A/X = the address of an 8x8 1bpp pattern
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_pattern_set pat
    lda #<(:pat)
    ldx #>(:pat)
    jsr gfx2h_pattern_set
    .endm
.endif
.if .def X16_USE_BITMAP2H
.macro xm_gfx2h_pattern_rect x, y, w, h
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
    jsr gfx2h_pattern_rect
    .endm
.endif

; =====================================================================
; gfx/bitmap2l  (320x240 @ 2bpp; colour in A)
; =====================================================================
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_init
    jsr gfx2l_init
    .endm
.endif
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_clear col
    lda #(:col)
    jsr gfx2l_clear
    .endm
.endif
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_pset x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #(:col)
    jsr gfx2l_pset
    .endm
.endif
; -> A = colour, carry set if (x,y) is off screen
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_read x, y
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    jsr gfx2l_read
    .endm
.endif
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_hline x, y, len, col
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
    jsr gfx2l_hline
    .endm
.endif
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_vline x, y, len, col
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
    jsr gfx2l_vline
    .endm
.endif
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_rect x, y, w, h, col
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
    jsr gfx2l_rect
    .endm
.endif
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_frame x, y, w, h, col
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
    jsr gfx2l_frame
    .endm
.endif
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_line x0, y0, x1, y1, col
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
    jsr gfx2l_line
    .endm
.endif
; A/X = the address of an 8x8 1bpp pattern
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_pattern_set pat
    lda #<(:pat)
    ldx #>(:pat)
    jsr gfx2l_pattern_set
    .endm
.endif
.if .def X16_USE_BITMAP2L
.macro xm_gfx2l_pattern_rect x, y, w, h
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
    jsr gfx2l_pattern_rect
    .endm
.endif

; =====================================================================
; gfx/bitmap4l  (320x240 @ 4bpp)
; =====================================================================
.if .def X16_USE_BITMAP4L
.macro xm_gfx4l_init
    jsr gfx4l_init
    .endm
.macro xm_gfx4l_clear col
    lda #(:col)
    jsr gfx4l_clear
    .endm
.macro xm_gfx4l_pset x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    jsr gfx4l_pset
    .endm
.macro xm_gfx4l_read x, y
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    jsr gfx4l_read
    .endm
.macro xm_gfx4l_hline x, y, len, col
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
    jsr gfx4l_hline
    .endm
.macro xm_gfx4l_vline x, y, len, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #(:len)
    sta X16_P4
    jsr gfx4l_vline
    .endm
.macro xm_gfx4l_rect x, y, w, h, col
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
    jsr gfx4l_rect
    .endm
.macro xm_gfx4l_frame x, y, w, h, col
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
    jsr gfx4l_frame
    .endm
.macro xm_gfx4l_line x0, y0, x1, y1, col
    lda #<(:x0)
    sta X16_P0
    lda #>(:x0)
    sta X16_P1
    lda #(:y0)
    sta X16_P2
    lda #<(:x1)
    sta X16_P3
    lda #>(:x1)
    sta X16_P4
    lda #(:y1)
    sta X16_P5
    lda #(:col)
    sta X16_P6
    jsr gfx4l_line
    .endm
.macro xm_gfx4l_pattern_set pat, bg, fg
    lda #(:bg)
    sta X16_P4
    lda #(:fg)
    sta X16_P5
    lda #<(:pat)
    ldx #>(:pat)
    jsr gfx4l_pattern_set
    .endm
.macro xm_gfx4l_pattern_rect x, y, w, h
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
    jsr gfx4l_pattern_rect
    .endm
.macro xm_gfx4l_char code, x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #(:y)
    sta X16_P2
    lda #(:col)
    sta X16_P3
    lda #(:code)
    jsr gfx4l_char
    .endm
.macro xm_gfx4l_text str, x, y, col
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
    jsr gfx4l_text
    .endm
.endif

; =====================================================================
; gfx/bitmap4h  (640x480 @ 4bpp; VERA_2 SDRAM layer)
; =====================================================================
.if .def X16_USE_BITMAP4H
.macro xm_gfx4h_has
    jsr gfx4h_has
    .endm
.macro xm_gfx4h_init
    jsr gfx4h_init
    .endm
.macro xm_gfx4h_off
    jsr gfx4h_off
    .endm
.macro xm_gfx4h_passthru_on
    jsr gfx4h_passthru_on
    .endm
.macro xm_gfx4h_passthru_off
    jsr gfx4h_passthru_off
    .endm
.macro xm_gfx4h_pal_set index, lo, hi
    ldx #(:index)
    lda #(:lo)
    ldy #(:hi)
    jsr gfx4h_pal_set
    .endm
.macro xm_gfx4h_pal_load src, first, count
    lda #<(:src)
    sta X16_PTR0
    lda #>(:src)
    sta X16_PTR0+1
    lda #(:first)
    ldx #(:count)
    jsr gfx4h_pal_load
    .endm
.macro xm_gfx4h_clear col
    lda #(:col)
    jsr gfx4h_clear
    .endm
.macro xm_gfx4h_pset x, y, col
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    lda #(:col)
    jsr gfx4h_pset
    .endm
.macro xm_gfx4h_read x, y
    lda #<(:x)
    sta X16_P0
    lda #>(:x)
    sta X16_P1
    lda #<(:y)
    sta X16_P2
    lda #>(:y)
    sta X16_P3
    jsr gfx4h_read
    .endm
.macro xm_gfx4h_hline x, y, len, col
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
    jsr gfx4h_hline
    .endm
.macro xm_gfx4h_vline x, y, len, col
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
    jsr gfx4h_vline
    .endm
.macro xm_gfx4h_rect x, y, w, h, col
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
    jsr gfx4h_rect
    .endm
.macro xm_gfx4h_frame x, y, w, h, col
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
    jsr gfx4h_frame
    .endm
.macro xm_gfx4h_line x0, y0, x1, y1, col
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
    jsr gfx4h_line
    .endm
.macro xm_gfx4h_pattern_set pat, bg, fg
    lda #(:bg)
    sta X16_P4
    lda #(:fg)
    sta X16_P5
    lda #<(:pat)
    ldx #>(:pat)
    jsr gfx4h_pattern_set
    .endm
.macro xm_gfx4h_pattern_rect x, y, w, h
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
    jsr gfx4h_pattern_rect
    .endm
.macro xm_gfx4h_copy src, dst, len
    lda #<(:src)
    sta X16_P0
    lda #>((:src) >> 8)
    sta X16_P1
    lda #>((:src) >> 16)
    sta X16_P2
    lda #<(:dst)
    sta X16_P3
    lda #>((:dst) >> 8)
    sta X16_P4
    lda #>((:dst) >> 16)
    sta X16_P5
    lda #<(:len)
    ldx #>((:len) >> 8)
    ldy #>((:len) >> 16)
    jsr gfx4h_copy
    .endm
.endif

; =====================================================================
; gfx/graph  (KERNAL GRAPH API)
; =====================================================================
.if .def X16_USE_GRAPH
.macro xm_graph_init_default
    stz r0L
    stz r0H
    jsr graph_init
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_init driver
    lda #<(:driver)
    sta r0L
    lda #>(:driver)
    sta r0H
    jsr graph_init
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_clear
    jsr graph_clear
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_set_window x, y, w, h
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    lda #<(:w)
    sta r2L
    lda #>(:w)
    sta r2H
    lda #<(:h)
    sta r3L
    lda #>(:h)
    sta r3H
    jsr graph_set_window
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_set_colors stroke, fill, background
    lda #(:stroke)
    ldx #(:fill)
    ldy #(:background)
    jsr graph_set_colors
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_draw_line x1, y1, x2, y2
    lda #<(:x1)
    sta r0L
    lda #>(:x1)
    sta r0H
    lda #<(:y1)
    sta r1L
    lda #>(:y1)
    sta r1H
    lda #<(:x2)
    sta r2L
    lda #>(:x2)
    sta r2H
    lda #<(:y2)
    sta r3L
    lda #>(:y2)
    sta r3H
    jsr graph_draw_line
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_draw_rect_outline x, y, w, h, radius
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    lda #<(:w)
    sta r2L
    lda #>(:w)
    sta r2H
    lda #<(:h)
    sta r3L
    lda #>(:h)
    sta r3H
    lda #<(:radius)
    sta r4L
    lda #>(:radius)
    sta r4H
    clc
    jsr graph_draw_rect
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_draw_rect_fill x, y, w, h, radius
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    lda #<(:w)
    sta r2L
    lda #>(:w)
    sta r2H
    lda #<(:h)
    sta r3L
    lda #>(:h)
    sta r3H
    lda #<(:radius)
    sta r4L
    lda #>(:radius)
    sta r4H
    sec
    jsr graph_draw_rect
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_move_rect sx, sy, tx, ty, w, h
    lda #<(:sx)
    sta r0L
    lda #>(:sx)
    sta r0H
    lda #<(:sy)
    sta r1L
    lda #>(:sy)
    sta r1H
    lda #<(:tx)
    sta r2L
    lda #>(:tx)
    sta r2H
    lda #<(:ty)
    sta r3L
    lda #>(:ty)
    sta r3H
    lda #<(:w)
    sta r4L
    lda #>(:w)
    sta r4H
    lda #<(:h)
    sta r5L
    lda #>(:h)
    sta r5H
    jsr graph_move_rect
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_draw_oval_outline x, y, w, h
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    lda #<(:w)
    sta r2L
    lda #>(:w)
    sta r2H
    lda #<(:h)
    sta r3L
    lda #>(:h)
    sta r3H
    clc
    jsr graph_draw_oval
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_draw_oval_fill x, y, w, h
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    lda #<(:w)
    sta r2L
    lda #>(:w)
    sta r2H
    lda #<(:h)
    sta r3L
    lda #>(:h)
    sta r3H
    sec
    jsr graph_draw_oval
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_draw_image x, y, image, w, h
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    lda #<(:image)
    sta r2L
    lda #>(:image)
    sta r2H
    lda #<(:w)
    sta r3L
    lda #>(:w)
    sta r3H
    lda #<(:h)
    sta r4L
    lda #>(:h)
    sta r4H
    jsr graph_draw_image
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_set_font_default
    stz r0L
    stz r0H
    jsr graph_set_font
    .endm
.endif
.if .def X16_USE_GRAPH
.macro xm_graph_set_font font
    lda #<(:font)
    sta r0L
    lda #>(:font)
    sta r0H
    jsr graph_set_font
    .endm
.endif
; -> printable: C clear, A baseline, X width, Y height; control: C set
.if .def X16_USE_GRAPH
.macro xm_graph_get_char_size char, style
    lda #(:char)
    ldx #(:style)
    jsr graph_get_char_size
    .endm
.endif
; -> r0/r1 updated, carry set if outside bounds
.if .def X16_USE_GRAPH
.macro xm_graph_put_char char, x, y
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    lda #(:char)
    jsr graph_put_char
    .endm
.endif

; =====================================================================
; gfx/console  (KERNAL console API)
; =====================================================================
.if .def X16_USE_CONSOLE
.macro xm_con_init_fullscreen
    stz r0L
    stz r0H
    stz r1L
    stz r1H
    stz r2L
    stz r2H
    stz r3L
    stz r3H
    jsr con_init
    .endm
.endif
.if .def X16_USE_CONSOLE
.macro xm_con_init x, y, w, h
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    lda #<(:w)
    sta r2L
    lda #>(:w)
    sta r2H
    lda #<(:h)
    sta r3L
    lda #>(:h)
    sta r3H
    jsr con_init
    .endm
.endif
.if .def X16_USE_CONSOLE
.macro xm_con_set_paging_message msg
    lda #<(:msg)
    sta r0L
    lda #>(:msg)
    sta r0H
    jsr con_set_paging_message
    .endm
.endif
.if .def X16_USE_CONSOLE
.macro xm_con_disable_paging
    jsr con_disable_paging
    .endm
.endif
.if .def X16_USE_CONSOLE
.macro xm_con_put_char_wrap char
    lda #(:char)
    clc
    jsr con_put_char
    .endm
.endif
.if .def X16_USE_CONSOLE
.macro xm_con_put_char_word char
    lda #(:char)
    sec
    jsr con_put_char
    .endm
.endif
.if .def X16_USE_CONSOLE
.macro xm_con_get_char
    jsr con_get_char
    .endm
.endif
.if .def X16_USE_CONSOLE
.macro xm_con_put_image image, w, h
    lda #<(:image)
    sta r0L
    lda #>(:image)
    sta r0H
    lda #<(:w)
    sta r1L
    lda #>(:w)
    sta r1H
    lda #<(:h)
    sta r2L
    lda #>(:h)
    sta r2H
    jsr con_put_image
    .endm
.endif

; =====================================================================
; gfx/fb  (KERNAL framebuffer API)
; =====================================================================
.if .def X16_USE_FB
.macro xm_fb_init
    jsr fb_init
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_get_info
    jsr fb_get_info
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_set_palette data, start, count
    lda #<(:data)
    sta r0L
    lda #>(:data)
    sta r0H
    lda #(:start)
    ldx #(:count)
    jsr fb_set_palette
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_cursor_position x, y
    lda #<(:x)
    sta r0L
    lda #>(:x)
    sta r0H
    lda #<(:y)
    sta r1L
    lda #>(:y)
    sta r1H
    jsr fb_cursor_position
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_cursor_next_line
    jsr fb_cursor_next_line
    .endm
.endif
; -> A = color
.if .def X16_USE_FB
.macro xm_fb_get_pixel x, y
    xm_fb_cursor_position :x,:y
    jsr fb_get_pixel
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_set_pixel x, y, color
    xm_fb_cursor_position :x,:y
    lda #(:color)
    jsr fb_set_pixel
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_get_pixels dest, count
    lda #<(:dest)
    sta r0L
    lda #>(:dest)
    sta r0H
    lda #<(:count)
    sta r1L
    lda #>(:count)
    sta r1H
    jsr fb_get_pixels
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_set_pixels src, count
    lda #<(:src)
    sta r0L
    lda #>(:src)
    sta r0H
    lda #<(:count)
    sta r1L
    lda #>(:count)
    sta r1H
    jsr fb_set_pixels
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_set_8_pixels pattern, color
    lda #(:pattern)
    ldx #(:color)
    jsr fb_set_8_pixels
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_set_8_pixels_opaque mask, pattern, fg, bg
    lda #<(:pattern)
    sta r0L
    lda #(:mask)
    ldx #(:fg)
    ldy #(:bg)
    jsr fb_set_8_pixels_opaque
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_fill_pixels count, step, color
    lda #<(:count)
    sta r0L
    lda #>(:count)
    sta r0H
    lda #<(:step)
    sta r1L
    lda #>(:step)
    sta r1H
    lda #(:color)
    jsr fb_fill_pixels
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_filter_pixels count, filter
    lda #<(:count)
    sta r0L
    lda #>(:count)
    sta r0H
    lda #<(:filter)
    sta r1L
    lda #>(:filter)
    sta r1H
    jsr fb_filter_pixels
    .endm
.endif
.if .def X16_USE_FB
.macro xm_fb_move_pixels sx, sy, tx, ty, count
    lda #<(:sx)
    sta r0L
    lda #>(:sx)
    sta r0H
    lda #<(:sy)
    sta r1L
    lda #>(:sy)
    sta r1H
    lda #<(:tx)
    sta r2L
    lda #>(:tx)
    sta r2H
    lda #<(:ty)
    sta r3L
    lda #>(:ty)
    sta r3H
    lda #<(:count)
    sta r4L
    lda #>(:count)
    sta r4H
    jsr fb_move_pixels
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
; gfx/verafx_utils  (low-level VERA FX primitives)
; =====================================================================
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_off
    jsr fxu_off
    .endm
.endif
; -> A = FX_CTRL
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_get_ctrl
    jsr fxu_get_ctrl
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_set_ctrl ctrl
    lda #(:ctrl)
    jsr fxu_set_ctrl
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_ctrl_on mask
    lda #(:mask)
    jsr fxu_ctrl_on
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_ctrl_off mask
    lda #(:mask)
    jsr fxu_ctrl_off
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_addr1_mode mode
    lda #(:mode)
    jsr fxu_addr1_mode
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_write_on
    jsr fxu_cache_write_on
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_write_off
    jsr fxu_cache_write_off
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_fill_on
    jsr fxu_cache_fill_on
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_fill_off
    jsr fxu_cache_fill_off
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_cycle_on
    jsr fxu_cache_cycle_on
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_cycle_off
    jsr fxu_cache_cycle_off
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_transparent_on
    jsr fxu_transparent_on
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_transparent_off
    jsr fxu_transparent_off
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_4bit_on
    jsr fxu_4bit_on
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_4bit_off
    jsr fxu_4bit_off
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_hop_on
    jsr fxu_hop_on
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_hop_off
    jsr fxu_hop_off
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_set_mult mult
    lda #(:mult)
    jsr fxu_set_mult
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_set_cache b0, b1, b2, b3
    lda #(:b0)
    sta X16_P0
    lda #(:b1)
    sta X16_P1
    lda #(:b2)
    sta X16_P2
    lda #(:b3)
    sta X16_P3
    jsr fxu_set_cache
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_reset_accum
    jsr fxu_reset_accum
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_accumulate
    jsr fxu_accumulate
    .endm
.endif
; -> A = DATA0 read
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_fill0
    jsr fxu_cache_fill0
    .endm
.endif
; -> A = DATA1 read
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_fill1
    jsr fxu_cache_fill1
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_write0 mask
    lda #(:mask)
    jsr fxu_cache_write0
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_cache_write1 mask
    lda #(:mask)
    jsr fxu_cache_write1
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_set_incr xinc, yinc
    lda #<(:xinc)
    sta X16_P0
    lda #>(:xinc)
    sta X16_P1
    lda #<(:yinc)
    sta X16_P2
    lda #>(:yinc)
    sta X16_P3
    jsr fxu_set_incr
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_set_pos xpos, ypos
    lda #<(:xpos)
    sta X16_P0
    lda #>(:xpos)
    sta X16_P1
    lda #<(:ypos)
    sta X16_P2
    lda #>(:ypos)
    sta X16_P3
    jsr fxu_set_pos
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_set_subpos xsub, ysub
    lda #(:xsub)
    ldx #(:ysub)
    jsr fxu_set_subpos
    .endm
.endif
; -> A = poly fill low, X = high
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_get_poly_fill
    jsr fxu_get_poly_fill
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_set_tilebase value
    lda #(:value)
    jsr fxu_set_tilebase
    .endm
.endif
.if .def X16_USE_VERAFX_UTILS
.macro xm_fxu_set_mapbase value
    lda #(:value)
    jsr fxu_set_mapbase
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
; audio/rom  (full BANK_AUDIO API)
; =====================================================================
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_audio_init
    jsr ar_audio_init
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_playstring_voice voice
    lda #(:voice)
    jsr ar_playstring_voice
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_fmplaystring str, len
    lda #(:len)
    ldx #<(:str)
    ldy #>(:str)
    jsr ar_fmplaystring
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_fmchordstring str, len
    lda #(:len)
    ldx #<(:str)
    ldy #>(:str)
    jsr ar_fmchordstring
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psgplaystring str, len
    lda #(:len)
    ldx #<(:str)
    ldy #>(:str)
    jsr ar_psgplaystring
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psgchordstring str, len
    lda #(:len)
    ldx #<(:str)
    ldy #>(:str)
    jsr ar_psgchordstring
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_fmfreq channel, hz
    lda #(:channel)
    ldx #<(:hz)
    ldy #>(:hz)
    clc
    jsr ar_fmfreq
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_fmfreq_no_retrigger channel, hz
    lda #(:channel)
    ldx #<(:hz)
    ldy #>(:hz)
    sec
    jsr ar_fmfreq
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_fmnote channel, note, kf
    lda #(:channel)
    ldx #(:note)
    ldy #(:kf)
    clc
    jsr ar_fmnote
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_fmnote_no_retrigger channel, note, kf
    lda #(:channel)
    ldx #(:note)
    ldy #(:kf)
    sec
    jsr ar_fmnote
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_fmvib speed, depth
    lda #(:speed)
    ldx #(:depth)
    jsr ar_fmvib
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psgfreq voice, hz
    lda #(:voice)
    ldx #<(:hz)
    ldy #>(:hz)
    jsr ar_psgfreq
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psgnote voice, note, kf
    lda #(:voice)
    ldx #(:note)
    ldy #(:kf)
    jsr ar_psgnote
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psgwav voice, wave
    lda #(:voice)
    ldx #(:wave)
    jsr ar_psgwav
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_bas2fm note
    ldx #(:note)
    jsr ar_note_bas2fm
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_bas2midi note
    ldx #(:note)
    jsr ar_note_bas2midi
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_bas2psg note, kf
    ldx #(:note)
    ldy #(:kf)
    jsr ar_note_bas2psg
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_fm2bas kc
    ldx #(:kc)
    jsr ar_note_fm2bas
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_fm2midi kc
    ldx #(:kc)
    jsr ar_note_fm2midi
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_fm2psg kc, kf
    ldx #(:kc)
    ldy #(:kf)
    jsr ar_note_fm2psg
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_freq2bas hz
    ldx #<(:hz)
    ldy #>(:hz)
    jsr ar_note_freq2bas
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_freq2fm hz
    ldx #<(:hz)
    ldy #>(:hz)
    jsr ar_note_freq2fm
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_freq2midi hz
    ldx #<(:hz)
    ldy #>(:hz)
    jsr ar_note_freq2midi
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_freq2psg hz
    ldx #<(:hz)
    ldy #>(:hz)
    jsr ar_note_freq2psg
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_midi2bas note
    lda #(:note)
    jsr ar_note_midi2bas
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_midi2fm note
    ldx #(:note)
    jsr ar_note_midi2fm
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_midi2psg note, kf
    ldx #(:note)
    ldy #(:kf)
    jsr ar_note_midi2psg
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_psg2bas freq
    ldx #<(:freq)
    ldy #>(:freq)
    jsr ar_note_psg2bas
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_psg2fm freq
    ldx #<(:freq)
    ldy #>(:freq)
    jsr ar_note_psg2fm
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_note_psg2midi freq
    ldx #<(:freq)
    ldy #>(:freq)
    jsr ar_note_psg2midi
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_init
    jsr ar_psg_init
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_playfreq voice, freq
    lda #(:voice)
    ldx #<(:freq)
    ldy #>(:freq)
    jsr ar_psg_playfreq
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_read_raw reg
    ldx #(:reg)
    clc
    jsr ar_psg_read
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_read_cooked reg
    ldx #(:reg)
    sec
    jsr ar_psg_read
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_setatten voice, atten
    lda #(:voice)
    ldx #(:atten)
    jsr ar_psg_setatten
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_setfreq voice, freq
    lda #(:voice)
    ldx #<(:freq)
    ldy #>(:freq)
    jsr ar_psg_setfreq
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_setpan voice, pan
    lda #(:voice)
    ldx #(:pan)
    jsr ar_psg_setpan
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_setvol voice, vol
    lda #(:voice)
    ldx #(:vol)
    jsr ar_psg_setvol
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_write reg, value
    lda #(:value)
    ldx #(:reg)
    jsr ar_psg_write
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_write_fast reg, value
    lda #(:value)
    ldx #(:reg)
    jsr ar_psg_write_fast
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_getatten voice
    lda #(:voice)
    jsr ar_psg_getatten
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_psg_getpan voice
    lda #(:voice)
    jsr ar_psg_getpan
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_init
    jsr ar_ym_init
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_loaddefpatches
    jsr ar_ym_loaddefpatches
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_loadpatch_rom channel, patch
    lda #(:channel)
    ldx #(:patch)
    sec
    jsr ar_ym_loadpatch
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_loadpatchlfn channel, lfn
    lda #(:channel)
    ldx #(:lfn)
    jsr ar_ym_loadpatchlfn
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_playdrum channel, note
    lda #(:channel)
    ldx #(:note)
    jsr ar_ym_playdrum
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_playnote channel, kc, kf
    lda #(:channel)
    ldx #(:kc)
    ldy #(:kf)
    clc
    jsr ar_ym_playnote
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_setatten channel, atten
    lda #(:channel)
    ldx #(:atten)
    jsr ar_ym_setatten
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_setdrum channel, note
    lda #(:channel)
    ldx #(:note)
    jsr ar_ym_setdrum
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_setnote channel, kc, kf
    lda #(:channel)
    ldx #(:kc)
    ldy #(:kf)
    jsr ar_ym_setnote
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_setpan channel, pan
    lda #(:channel)
    ldx #(:pan)
    jsr ar_ym_setpan
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_read_raw reg
    ldx #(:reg)
    clc
    jsr ar_ym_read
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_read_cooked reg
    ldx #(:reg)
    sec
    jsr ar_ym_read
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_release channel
    lda #(:channel)
    jsr ar_ym_release
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_trigger channel
    lda #(:channel)
    clc
    jsr ar_ym_trigger
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_trigger_no_retrigger channel
    lda #(:channel)
    sec
    jsr ar_ym_trigger
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_write reg, value
    lda #(:value)
    ldx #(:reg)
    jsr ar_ym_write
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_getatten channel
    lda #(:channel)
    jsr ar_ym_getatten
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_getpan channel
    lda #(:channel)
    jsr ar_ym_getpan
    .endm
.endif
.if .def X16_USE_AUDIO_ROM
.macro xm_ar_ym_get_chip_type
    jsr ar_ym_get_chip_type
    .endm
.endif

; =====================================================================
; audio/zsm  (compact ZSM stream player)
; =====================================================================
.if .def X16_USE_ZSM
.macro xm_zsm_init header
    lda #<(:header)
    sta r0L
    lda #>(:header)
    sta r0H
    jsr zsm_init
    .endm
.endif
.if .def X16_USE_ZSM
.macro xm_zsm_init_stream stream, loop
    lda #<(:stream)
    sta r0L
    lda #>(:stream)
    sta r0H
    lda #<(:loop)
    sta r1L
    lda #>(:loop)
    sta r1H
    jsr zsm_init_stream
    .endm
.endif
.if .def X16_USE_ZSM
.macro xm_zsm_play
    jsr zsm_play
    .endm
.endif
.if .def X16_USE_ZSM
.macro xm_zsm_stop
    jsr zsm_stop
    .endm
.endif
.if .def X16_USE_ZSM
.macro xm_zsm_rewind
    jsr zsm_rewind
    .endm
.endif
; -> A = low byte, X = high byte
.if .def X16_USE_ZSM
.macro xm_zsm_get_tickrate
    jsr zsm_get_tickrate
    .endm
.endif
; -> A = ZSM_FLAG_* bits, carry set if active
.if .def X16_USE_ZSM
.macro xm_zsm_status
    jsr zsm_status
    .endm
.endif
; -> A = ZSM_FLAG_* bits, carry set if active
.if .def X16_USE_ZSM
.macro xm_zsm_tick
    jsr zsm_tick
    .endm
.endif
; -> carry set if a supported PCM table is present
.if .def X16_USE_ZSM_PCM
.macro xm_zsm_pcm_present
    jsr zsm_pcm_present
    .endm
.endif
.if .def X16_USE_ZSM_PCM
.macro xm_zsm_pcm_trigger instrument
    lda #(:instrument)
    jsr zsm_pcm_trigger
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
; input/mouse
; =====================================================================
.if .def X16_USE_MOUSE
.macro xm_mse_config cursor, width8, height8
    lda #(:cursor)
    ldx #(:width8)
    ldy #(:height8)
    jsr mse_config
    .endm
.endif
.if .def X16_USE_MOUSE
.macro xm_mse_scan
    jsr mse_scan
    .endm
.endif
; -> P0/1 = x, P2/3 = y, A = buttons, X = wheel delta
.if .def X16_USE_MOUSE
.macro xm_mse_get
    jsr mse_get
    .endm
.endif
; -> sugar_zp/sugar_zp+1 = x, sugar_zp+2/sugar_zp+3 = y, A = buttons, X = wheel delta
.if .def X16_USE_MOUSE
.macro xm_mse_get_to zp
    ldx #(:zp)
    jsr mse_get_to
    .endm
.endif
.if .def X16_USE_MOUSE
.macro xm_mse_show cursor
    lda #(:cursor)
    jsr mse_show
    .endm
.endif
.if .def X16_USE_MOUSE
.macro xm_mse_show_keep
    jsr mse_show_keep
    .endm
.endif
.if .def X16_USE_MOUSE
.macro xm_mse_hide
    jsr mse_hide
    .endm
.endif

; =====================================================================
; input/keyboard
; =====================================================================
.if .def X16_USE_KEYBOARD
.macro xm_kbd_scan
    jsr kbd_scan
    .endm
.endif
; -> A = next PETSCII key, X = queued key count, Z set when empty
.if .def X16_USE_KEYBOARD
.macro xm_kbd_peek
    jsr kbd_peek
    .endm
.endif
.if .def X16_USE_KEYBOARD
.macro xm_kbd_put key
    lda #(:key)
    jsr kbd_put
    .endm
.endif
; -> A = KBD_MOD_* bitfield
.if .def X16_USE_KEYBOARD
.macro xm_kbd_get_modifiers
    jsr kbd_get_modifiers
    .endm
.endif
; -> A = layout index, X/Y = current NUL-terminated layout string
.if .def X16_USE_KEYBOARD
.macro xm_kbd_get_keymap
    jsr kbd_get_keymap
    .endm
.endif
; -> carry clear on success, carry set on unknown layout
.if .def X16_USE_KEYBOARD
.macro xm_kbd_set_keymap name
    ldx #<(:name)
    ldy #>(:name)
    jsr kbd_set_keymap
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
; storage/iec
; =====================================================================
.if .def X16_USE_IEC
.macro xm_iec_listen device
    lda #(:device)
    jsr iec_listen
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_talk device
    lda #(:device)
    jsr iec_talk
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_second command
    lda #(:command)
    jsr iec_second
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_tksa command
    lda #(:command)
    jsr iec_tksa
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_ciout byte
    lda #(:byte)
    jsr iec_ciout
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_acptr
    jsr iec_acptr
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_unlisten
    jsr iec_unlisten
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_untalk
    jsr iec_untalk
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_set_timeout control
    lda #(:control)
    jsr iec_set_timeout
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_readst
    jsr iec_readst
    .endm
.endif
; -> X/Y = bytes read, carry set when unsupported/error
.if .def X16_USE_IEC
.macro xm_iec_macptr dest, count
    lda #(:count)
    ldx #<(:dest)
    ldy #>(:dest)
    jsr iec_macptr
    .endm
.endif
; -> X/Y = bytes written, carry set when unsupported/error
.if .def X16_USE_IEC
.macro xm_iec_mciout src, count
    lda #(:count)
    ldx #<(:src)
    ldy #>(:src)
    jsr iec_mciout
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_open_channel device, secondary
    lda #(:device)
    ldy #(:secondary)
    jsr iec_open_channel
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_data_channel device, secondary
    lda #(:device)
    ldy #(:secondary)
    jsr iec_data_channel
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_talk_channel device, secondary
    lda #(:device)
    ldy #(:secondary)
    jsr iec_talk_channel
    .endm
.endif
.if .def X16_USE_IEC
.macro xm_iec_close_channel device, secondary
    lda #(:device)
    ldy #(:secondary)
    jsr iec_close_channel
    .endm
.endif

; =====================================================================
; storage/fileio
; =====================================================================
.if .def X16_USE_FILEIO
.macro xm_fio_set_lfs logical, device, secondary
    lda #(:logical)
    ldx #(:device)
    ldy #(:secondary)
    jsr fio_set_lfs
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_set_name name, len
    lda #(:len)
    ldx #<(:name)
    ldy #>(:name)
    jsr fio_set_name
    .endm
.endif
; -> carry set = KERNAL open error
.if .def X16_USE_FILEIO
.macro xm_fio_open_named name, len, logical, device, secondary
    lda #<(:name)
    sta X16_P0
    lda #>(:name)
    sta X16_P1
    lda #(:len)
    sta X16_P2
    lda #(:logical)
    sta X16_P3
    lda #(:device)
    sta X16_P4
    lda #(:secondary)
    sta X16_P5
    jsr fio_open_named
    .endm
.endif
; -> carry set = OPEN or CHKIN error
.if .def X16_USE_FILEIO
.macro xm_fio_open_read name, len, logical, device, secondary
    lda #<(:name)
    sta X16_P0
    lda #>(:name)
    sta X16_P1
    lda #(:len)
    sta X16_P2
    lda #(:logical)
    sta X16_P3
    lda #(:device)
    sta X16_P4
    lda #(:secondary)
    sta X16_P5
    jsr fio_open_read
    .endm
.endif
; -> carry set = OPEN or CHKOUT error
.if .def X16_USE_FILEIO
.macro xm_fio_open_write name, len, logical, device, secondary
    lda #<(:name)
    sta X16_P0
    lda #>(:name)
    sta X16_P1
    lda #(:len)
    sta X16_P2
    lda #(:logical)
    sta X16_P3
    lda #(:device)
    sta X16_P4
    lda #(:secondary)
    sta X16_P5
    jsr fio_open_write
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_close logical
    lda #(:logical)
    jsr fio_close
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_close_named logical
    lda #(:logical)
    sta X16_P3
    jsr fio_close_named
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_chkin logical
    ldx #(:logical)
    jsr fio_chkin
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_chkout logical
    ldx #(:logical)
    jsr fio_chkout
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_clrchn
    jsr fio_clrchn
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_chrin
    jsr fio_chrin
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_chrout byte
    lda #(:byte)
    jsr fio_chrout
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_readst
    jsr fio_readst
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_getin
    jsr fio_getin
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_close_all
    jsr fio_close_all
    .endm
.endif
.if .def X16_USE_FILEIO
.macro xm_fio_close_device device
    lda #(:device)
    jsr fio_close_device
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

; =====================================================================
; system/clock
; =====================================================================
; -> A/X/Y = 24-bit 60 Hz timer, low to high
.if .def X16_USE_CLOCK
.macro xm_clock_get_timer
    jsr clock_get_timer
    .endm
.endif
.if .def X16_USE_CLOCK
.macro xm_clock_set_timer ticks
    lda #<(:ticks)
    ldx #>((:ticks) >> 8)
    ldy #>((:ticks) >> 16)
    jsr clock_set_timer
    .endm
.endif
.if .def X16_USE_CLOCK
.macro xm_clock_update
    jsr clock_update
    .endm
.endif
; -> r0..r3 = year/month/day/hour/min/sec/jiffy/weekday
.if .def X16_USE_CLOCK
.macro xm_clock_get_date_time
    jsr clock_get_date_time
    .endm
.endif
; sugar_year1900 is the KERNAL byte value: full year minus 1900.
.if .def X16_USE_CLOCK
.macro xm_clock_set_date_time_raw year1900, month, day, hours, minutes, seconds, jiffies, weekday
    lda #<(:year1900)
    sta r0L
    lda #<(:month)
    sta r0H
    lda #<(:day)
    sta r1L
    lda #<(:hours)
    sta r1H
    lda #<(:minutes)
    sta r2L
    lda #<(:seconds)
    sta r2H
    lda #<(:jiffies)
    sta r3L
    lda #<(:weekday)
    sta r3H
    jsr clock_set_date_time
    .endm
.endif
; Friendly form: sugar_year is the full year, e.g. 2026; jiffies are set to 0.
.if .def X16_USE_CLOCK
.macro xm_clock_set_date_time year, month, day, hours, minutes, seconds, weekday
    lda #<((:year) - 1900)
    sta r0L
    lda #<(:month)
    sta r0H
    lda #<(:day)
    sta r1L
    lda #<(:hours)
    sta r1H
    lda #<(:minutes)
    sta r2L
    lda #<(:seconds)
    sta r2H
    stz r3L
    lda #<(:weekday)
    sta r3H
    jsr clock_set_date_time
    .endm
.endif

; =====================================================================
; comms/i2c
; =====================================================================
; -> A = value, carry set on NAK/error
.if .def X16_USE_I2C
.macro xm_i2c_read_byte device, offset
    ldx #(:device)
    ldy #(:offset)
    jsr i2c_read_byte
    .endm
.endif
; -> carry set on NAK/error
.if .def X16_USE_I2C
.macro xm_i2c_write_byte value, device, offset
    lda #(:value)
    ldx #(:device)
    ldy #(:offset)
    jsr i2c_write_byte
    .endm
.endif
; -> carry set on NAK/error
.if .def X16_USE_I2C
.macro xm_i2c_batch_read device, buffer, count
    lda #<(:buffer)
    sta r0
    lda #>(:buffer)
    sta r0+1
    lda #<(:count)
    sta r1
    lda #>(:count)
    sta r1+1
    ldx #(:device)
    clc
    jsr i2c_batch_read
    .endm
.endif
; -> carry set on NAK/error; reads repeatedly into the same address
.if .def X16_USE_I2C
.macro xm_i2c_batch_read_fixed device, buffer, count
    lda #<(:buffer)
    sta r0
    lda #>(:buffer)
    sta r0+1
    lda #<(:count)
    sta r1
    lda #>(:count)
    sta r1+1
    ldx #(:device)
    sec
    jsr i2c_batch_read
    .endm
.endif
; -> r2 = bytes written, carry set on NAK/error
.if .def X16_USE_I2C
.macro xm_i2c_batch_write device, buffer, count
    lda #<(:buffer)
    sta r0
    lda #>(:buffer)
    sta r0+1
    lda #<(:count)
    sta r1
    lda #>(:count)
    sta r1+1
    ldx #(:device)
    jsr i2c_batch_write
    .endm
.endif

; =====================================================================
; comms/spi  (VERA SPI controller)
; =====================================================================
; -> A = VERA_SPI_* control/status bits
.if .def X16_USE_VERA_SPI
.macro xm_spi_get_ctrl
    jsr spi_get_ctrl
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_set_ctrl ctrl
    lda #(:ctrl)
    jsr spi_set_ctrl
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_select
    jsr spi_select
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_deselect
    jsr spi_deselect
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_slow
    jsr spi_slow
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_fast
    jsr spi_fast
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_autotx_on
    jsr spi_autotx_on
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_autotx_off
    jsr spi_autotx_off
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_wait
    jsr spi_wait
    .endm
.endif
; -> A = received byte
.if .def X16_USE_VERA_SPI
.macro xm_spi_transfer byte
    lda #(:byte)
    jsr spi_transfer
    .endm
.endif
; -> A = received byte
.if .def X16_USE_VERA_SPI
.macro xm_spi_read
    jsr spi_read
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_write byte
    lda #(:byte)
    jsr spi_write
    .endm
.endif
; -> A = received byte; starts the next Auto-TX transfer
.if .def X16_USE_VERA_SPI
.macro xm_spi_autotx_read
    jsr spi_autotx_read
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_read_bytes buffer, count
    lda #<(:buffer)
    sta r0L
    lda #>(:buffer)
    sta r0H
    lda #<(:count)
    sta r1L
    lda #>(:count)
    sta r1H
    jsr spi_read_bytes
    .endm
.endif
.if .def X16_USE_VERA_SPI
.macro xm_spi_write_bytes buffer, count
    lda #<(:buffer)
    sta r0L
    lda #>(:buffer)
    sta r0H
    lda #<(:count)
    sta r1L
    lda #>(:count)
    sta r1H
    jsr spi_write_bytes
    .endm
.endif

; =====================================================================
; comms/serial
; =====================================================================
; -> A = count (0-2), carry clear if any found, ser_u0/ser_u1 = bases
.if .def X16_USE_SERIAL
.macro xm_ser_detect
    jsr ser_detect
    .endm
.endif
.if .def X16_USE_SERIAL
.macro xm_ser_init base, divisor
    lda #<(:divisor)
    sta X16_P0
    lda #>(:divisor)
    sta X16_P1
    lda #<(:base)
    ldx #>(:base)
    jsr ser_init
    .endm
.endif
; -> carry set if a received byte is waiting
.if .def X16_USE_SERIAL
.macro xm_ser_avail
    jsr ser_avail
    .endm
.endif
; -> carry clear + A = byte, or carry set if the RX FIFO was empty
.if .def X16_USE_SERIAL
.macro xm_ser_get
    jsr ser_get
    .endm
.endif
; -> A = byte (blocks until one arrives)
.if .def X16_USE_SERIAL
.macro xm_ser_get_wait
    jsr ser_get_wait
    .endm
.endif
.if .def X16_USE_SERIAL
.macro xm_ser_put byte
    lda #(:byte)
    jsr ser_put
    .endm
.endif
.if .def X16_USE_SERIAL
.macro xm_ser_puts addr
    lda #<(:addr)
    ldx #>(:addr)
    jsr ser_puts
    .endm
.endif
.if .def X16_USE_SERIAL
.macro xm_ser_write addr, len
    ldy #(:len)
    lda #<(:addr)
    ldx #>(:addr)
    jsr ser_write
    .endm
.endif
; -> X16_P4/P5 = bytes stored
.if .def X16_USE_SERIAL
.macro xm_ser_read_until match, buffer, max
    lda #<(:buffer)
    sta X16_P0
    lda #>(:buffer)
    sta X16_P1
    lda #<(:max)
    sta X16_P2
    lda #>(:max)
    sta X16_P3
    lda #<(:match)
    ldx #>(:match)
    jsr ser_read_until
    .endm
.endif
.if .def X16_USE_SERIAL
.macro xm_ser_discard_until match
    lda #<(:match)
    ldx #>(:match)
    jsr ser_discard_until
    .endm
.endif

; =====================================================================
; comms/zimodem
; =====================================================================
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_init base, divisor
    lda #<(:divisor)
    sta X16_P0
    lda #>(:divisor)
    sta X16_P1
    lda #<(:base)
    ldx #>(:base)
    jsr zi_init
    .endm
.endif
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_cmd addr
    lda #<(:addr)
    ldx #>(:addr)
    jsr zi_cmd
    .endm
.endif
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_wait_ok
    jsr zi_wait_ok
    .endm
.endif
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_reset
    jsr zi_reset
    .endm
.endif
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_get_ip buffer
    lda #<(:buffer)
    ldx #>(:buffer)
    jsr zi_get_ip
    .endm
.endif
; -> carry clear if the transfer started, carry set if not found
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_hex_open filename
    lda #<(:filename)
    ldx #>(:filename)
    jsr zi_hex_open
    .endm
.endif
; -> A = bytes decoded into the buffer, 0 when the file is done
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_hex_chunk buffer
    lda #<(:buffer)
    ldx #>(:buffer)
    jsr zi_hex_chunk
    .endm
.endif
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_hex_close
    jsr zi_hex_close
    .endm
.endif
; -> A = bytes written (sugar_digits / 2)
.if .def X16_USE_SERIAL_ZIMODEM
.macro xm_zi_hexdecode src, digits, dest
    lda #<(:dest)
    sta X16_P0
    lda #>(:dest)
    sta X16_P1
    ldy #(:digits)
    lda #<(:src)
    ldx #>(:src)
    jsr zi_hexdecode
    .endm
.endif

; =====================================================================
; string/string
; =====================================================================
; -> Y = length
.if .def X16_USE_STRING
.macro xm_str_length str
    lda #<(:str)
    ldx #>(:str)
    jsr str_length
    .endm
.endif
; -> Y = length copied
.if .def X16_USE_STRING
.macro xm_str_copy src, dst
    lda #<(:dst)
    sta X16_P0
    lda #>(:dst)
    sta X16_P1
    lda #<(:src)
    ldx #>(:src)
    jsr str_copy
    .endm
.endif
.if .def X16_USE_STRING
.macro xm_str_ncopy src, dst, max
    lda #<(:dst)
    sta X16_P0
    lda #>(:dst)
    sta X16_P1
    ldy #(:max)
    lda #<(:src)
    ldx #>(:src)
    jsr str_ncopy
    .endm
.endif
; -> A = resulting length
.if .def X16_USE_STRING
.macro xm_str_append tgt, suffix
    lda #<(:suffix)
    sta X16_P0
    lda #>(:suffix)
    sta X16_P1
    lda #<(:tgt)
    ldx #>(:tgt)
    jsr str_append
    .endm
.endif
.if .def X16_USE_STRING
.macro xm_str_nappend tgt, suffix, max
    lda #<(:suffix)
    sta X16_P0
    lda #>(:suffix)
    sta X16_P1
    ldy #(:max)
    lda #<(:tgt)
    ldx #>(:tgt)
    jsr str_nappend
    .endm
.endif
; -> A = -1 / 0 / 1
.if .def X16_USE_STRING
.macro xm_str_compare s1, s2
    lda #<(:s2)
    sta X16_P0
    lda #>(:s2)
    sta X16_P1
    lda #<(:s1)
    ldx #>(:s1)
    jsr str_compare
    .endm
.endif
; -> A = hash
.if .def X16_USE_STRING
.macro xm_str_hash str
    lda #<(:str)
    ldx #>(:str)
    jsr str_hash
    .endm
.endif

; =====================================================================
; string/case
; =====================================================================
.if .def X16_USE_STRING_CASE
.macro xm_str_lower str
    lda #<(:str)
    ldx #>(:str)
    jsr str_lower
    .endm
.endif
.if .def X16_USE_STRING_CASE
.macro xm_str_lower_iso str
    lda #<(:str)
    ldx #>(:str)
    jsr str_lower_iso
    .endm
.endif
.if .def X16_USE_STRING_CASE
.macro xm_str_upper str
    lda #<(:str)
    ldx #>(:str)
    jsr str_upper
    .endm
.endif
.if .def X16_USE_STRING_CASE
.macro xm_str_upper_iso str
    lda #<(:str)
    ldx #>(:str)
    jsr str_upper_iso
    .endm
.endif
; -> A = -1 / 0 / 1
.if .def X16_USE_STRING_CASE
.macro xm_str_compare_nocase s1, s2
    lda #<(:s2)
    sta X16_P0
    lda #>(:s2)
    sta X16_P1
    lda #<(:s1)
    ldx #>(:s1)
    jsr str_compare_nocase
    .endm
.endif
.if .def X16_USE_STRING_CASE
.macro xm_str_compare_nocase_iso s1, s2
    lda #<(:s2)
    sta X16_P0
    lda #>(:s2)
    sta X16_P1
    lda #<(:s1)
    ldx #>(:s1)
    jsr str_compare_nocase_iso
    .endm
.endif

; =====================================================================
; string/find
; =====================================================================
; -> carry set + A = index if found
.if .def X16_USE_STRING_FIND
.macro xm_str_find str, ch
    ldy #(:ch)
    lda #<(:str)
    ldx #>(:str)
    jsr str_find
    .endm
.endif
.if .def X16_USE_STRING_FIND
.macro xm_str_rfind str, ch
    ldy #(:ch)
    lda #<(:str)
    ldx #>(:str)
    jsr str_rfind
    .endm
.endif
.if .def X16_USE_STRING_FIND
.macro xm_str_find_eol str
    lda #<(:str)
    ldx #>(:str)
    jsr str_find_eol
    .endm
.endif
; -> carry set if the character occurs
.if .def X16_USE_STRING_FIND
.macro xm_str_contains str, ch
    ldy #(:ch)
    lda #<(:str)
    ldx #>(:str)
    jsr str_contains
    .endm
.endif
; -> carry set (A = 1) if it matches
.if .def X16_USE_STRING_FIND
.macro xm_str_pattern_match str, pattern
    lda #<(:pattern)
    sta X16_P0
    lda #>(:pattern)
    sta X16_P1
    lda #<(:str)
    ldx #>(:str)
    jsr str_pattern_match
    .endm
.endif

; =====================================================================
; string/slice
; =====================================================================
.if .def X16_USE_STRING_SLICE
.macro xm_str_left src, dst, len
    lda #<(:dst)
    sta X16_P0
    lda #>(:dst)
    sta X16_P1
    ldy #(:len)
    lda #<(:src)
    ldx #>(:src)
    jsr str_left
    .endm
.endif
.if .def X16_USE_STRING_SLICE
.macro xm_str_right src, dst, len
    lda #<(:dst)
    sta X16_P0
    lda #>(:dst)
    sta X16_P1
    ldy #(:len)
    lda #<(:src)
    ldx #>(:src)
    jsr str_right
    .endm
.endif
.if .def X16_USE_STRING_SLICE
.macro xm_str_slice src, dst, start, len
    lda #<(:dst)
    sta X16_P0
    lda #>(:dst)
    sta X16_P1
    lda #(:start)
    sta X16_P2
    ldy #(:len)
    lda #<(:src)
    ldx #>(:src)
    jsr str_slice
    .endm
.endif
; -> Y = new length
.if .def X16_USE_STRING_SLICE
.macro xm_str_ltrim str
    lda #<(:str)
    ldx #>(:str)
    jsr str_ltrim
    .endm
.endif
.if .def X16_USE_STRING_SLICE
.macro xm_str_rtrim str
    lda #<(:str)
    ldx #>(:str)
    jsr str_rtrim
    .endm
.endif
.if .def X16_USE_STRING_SLICE
.macro xm_str_trim str
    lda #<(:str)
    ldx #>(:str)
    jsr str_trim
    .endm
.endif
