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
; are produced by tools/acme2*.py -- it is NOT in their SKIP set).
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
!ifdef X16_USE_VERA {
!macro xm_vera_set_addr0 .l, .m, .h {
    lda #(.l)
    ldx #(.m)
    ldy #(.h)
    jsr vera_set_addr0
}
}
; point port 1
!ifdef X16_USE_VERA {
!macro xm_vera_set_addr1 .l, .m, .h {
    lda #(.l)
    ldx #(.m)
    ldy #(.h)
    jsr vera_set_addr1
}
}
; fill `count` bytes with `val` from the current port address
!ifdef X16_USE_VERA {
!macro xm_vera_fill .val, .count {
    lda #(.val)
    ldx #<(.count)
    ldy #>(.count)
    jsr vera_fill
}
}
; copy `count` bytes port0 -> port1 (both pre-pointed)
!ifdef X16_USE_VERA {
!macro xm_vera_copy .count {
    ldx #<(.count)
    ldy #>(.count)
    jsr vera_copy
}
}

; =====================================================================
; video/vdc  (VERA display composer)
; =====================================================================
; -> A = DC_VIDEO
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_get_video {
    jsr vdc_get_video
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_set_video .video {
    lda #(.video)
    jsr vdc_set_video
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_set_output .mode {
    lda #(.mode)
    jsr vdc_set_output
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_set_layers .mask {
    lda #(.mask)
    jsr vdc_set_layers
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_layer_on .mask {
    lda #(.mask)
    jsr vdc_layer_on
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_layer_off .mask {
    lda #(.mask)
    jsr vdc_layer_off
}
}
; -> A = HSCALE, X = VSCALE
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_get_scale {
    jsr vdc_get_scale
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_set_scale .hscale, .vscale {
    lda #(.hscale)
    ldx #(.vscale)
    jsr vdc_set_scale
}
}
; -> A = border palette index
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_get_border {
    jsr vdc_get_border
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_set_border .color {
    lda #(.color)
    jsr vdc_set_border
}
}
; -> A = HSTART, X = HSTOP, Y = VSTART, r0L = VSTOP
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_get_active_raw {
    jsr vdc_get_active_raw
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_set_active_raw .hstart, .hstop, .vstart, .vstop {
    lda #(.hstart)
    ldx #(.hstop)
    ldy #(.vstart)
    pha
    lda #(.vstop)
    sta r0L
    pla
    jsr vdc_set_active_raw
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_set_active .hstart, .hstop, .vstart, .vstop {
    lda #<(.hstart)
    sta X16_P0
    lda #>(.hstart)
    sta X16_P1
    lda #<(.hstop)
    sta X16_P2
    lda #>(.hstop)
    sta X16_P3
    lda #<(.vstart)
    sta X16_P4
    lda #>(.vstart)
    sta X16_P5
    lda #<(.vstop)
    sta X16_P6
    lda #>(.vstop)
    sta X16_P7
    jsr vdc_set_active
}
}
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_fullscreen {
    jsr vdc_fullscreen
}
}
; -> carry set if valid, A = major, X = minor, Y = build
!ifdef X16_USE_VERA_DC {
!macro xm_vdc_get_version {
    jsr vdc_get_version
}
}

; =====================================================================
; video/screen
; =====================================================================
; -> carry set if the mode is unsupported
!ifdef X16_USE_SCREEN {
!macro xm_screen_set_mode .mode {
    lda #(.mode)
    jsr screen_set_mode
}
}
!ifdef X16_USE_SCREEN {
!macro xm_screen_reset {
    jsr screen_reset
}
}
!ifdef X16_USE_SCREEN {
!macro xm_screen_cls {
    jsr screen_cls
}
}
!ifdef X16_USE_SCREEN {
!macro xm_screen_chrout .ch {
    lda #(.ch)
    jsr screen_chrout
}
}
!ifdef X16_USE_SCREEN {
!macro xm_screen_color .fg, .bg {
    lda #(.fg)
    ldx #(.bg)
    jsr screen_color
}
}
!ifdef X16_USE_SCREEN {
!macro xm_screen_border .col {
    lda #(.col)
    jsr screen_border
}
}
!ifdef X16_USE_SCREEN {
!macro xm_screen_locate .row, .col {
    ldx #(.row)
    ldy #(.col)
    jsr screen_locate
}
}
!ifdef X16_USE_SCREEN {
!macro xm_screen_charset .cs {
    lda #(.cs)
    jsr screen_charset
}
}
; print a NUL-terminated string
!ifdef X16_USE_SCREEN {
!macro xm_screen_puts .addr {
    lda #<(.addr)
    ldx #>(.addr)
    jsr screen_puts
}
}

; =====================================================================
; video/palette
; =====================================================================
; set one entry; rgb is a 12-bit $0RGB value
!ifdef X16_USE_PALETTE {
!macro xm_pal_set .index, .rgb {
    ldx #(.index)
    lda #<(.rgb)
    ldy #>(.rgb)
    jsr pal_set
}
}
; bulk-load `count` entries from RAM (2 bytes each, low first)
!ifdef X16_USE_PALETTE {
!macro xm_pal_load .src, .first, .count {
    lda #<(.src)
    sta X16_PTR0
    lda #>(.src)
    sta X16_PTR0+1
    lda #(.first)
    ldx #(.count)
    jsr pal_load
}
}

; =====================================================================
; video/tile  (layer config + tilemap cells)
; =====================================================================
!ifdef X16_USE_TILE {
!macro xm_layer_on .layer {
    lda #(.layer)
    jsr layer_on
}
}
!ifdef X16_USE_TILE {
!macro xm_layer_off .layer {
    lda #(.layer)
    jsr layer_off
}
}
!ifdef X16_USE_TILE {
!macro xm_layer_set_config .layer, .cfg {
    ldx #(.layer)
    lda #(.cfg)
    jsr layer_set_config
}
}
!ifdef X16_USE_TILE {
!macro xm_layer_set_mapbase .layer, .base {
    ldx #(.layer)
    lda #(.base)
    jsr layer_set_mapbase
}
}
!ifdef X16_USE_TILE {
!macro xm_layer_scroll_x .layer, .val {
    ldx #(.layer)
    lda #<(.val)
    sta X16_P0
    lda #>(.val)
    sta X16_P1
    jsr layer_scroll_x
}
}
!ifdef X16_USE_TILE {
!macro xm_layer_scroll_y .layer, .val {
    ldx #(.layer)
    lda #<(.val)
    sta X16_P0
    lda #>(.val)
    sta X16_P1
    jsr layer_scroll_y
}
}
!ifdef X16_USE_TILE {
!macro xm_tile_setptr .col, .row {
    ldx #(.col)
    ldy #(.row)
    jsr tile_setptr
}
}
!ifdef X16_USE_TILE {
!macro xm_tile_put .col, .row, .code, .attr {
    ldx #(.col)
    ldy #(.row)
    lda #(.code)
    sta X16_P0
    lda #(.attr)
    sta X16_P1
    jsr tile_put
}
}
; -> A = screen code, X = attribute
!ifdef X16_USE_TILE {
!macro xm_tile_get .col, .row {
    ldx #(.col)
    ldy #(.row)
    jsr tile_get
}
}

; =====================================================================
; sprite/sprite
; =====================================================================
!ifdef X16_USE_SPRITE {
!macro xm_sprites_on {
    jsr sprites_on
}
}
!ifdef X16_USE_SPRITE {
!macro xm_sprites_off {
    jsr sprites_off
}
}
!ifdef X16_USE_SPRITE {
!macro xm_sprite_init_all {
    jsr sprite_init_all
}
}
!ifdef X16_USE_SPRITE {
!macro xm_sprite_pos .sprite, .x, .y {
    ldx #(.sprite)
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    jsr sprite_pos
}
}
; -> P0/1 = x, P2/3 = y
!ifdef X16_USE_SPRITE {
!macro xm_sprite_get_pos .sprite {
    ldx #(.sprite)
    jsr sprite_get_pos
}
}
; vaddr = 32-byte-aligned 17-bit VRAM address; mode = SPRITE_MODE_4BPP/8BPP
!ifdef X16_USE_SPRITE {
!macro xm_sprite_image .sprite, .vaddr, .mode {
    ldx #(.sprite)
    lda #<(.vaddr)
    sta X16_P0
    lda #>(.vaddr)
    sta X16_P1
    lda #<((.vaddr) >>> 16)
    sta X16_P2
    lda #(.mode)
    jsr sprite_image
}
}
!ifdef X16_USE_SPRITE {
!macro xm_sprite_flags .sprite, .flags {
    ldx #(.sprite)
    lda #(.flags)
    jsr sprite_flags
}
}
!ifdef X16_USE_SPRITE {
!macro xm_sprite_z .sprite, .z {
    ldx #(.sprite)
    lda #(.z)
    jsr sprite_z
}
}
; width/height are SPRITE_SIZE_8/16/32/64 codes
!ifdef X16_USE_SPRITE {
!macro xm_sprite_size .sprite, .wcode, .hcode, .paloff {
    ldx #(.sprite)
    lda #(.paloff)
    sta X16_P0
    ldy #(.hcode)
    lda #(.wcode)
    jsr sprite_size
}
}

; =====================================================================
; gfx/bitmap8l  (320x240 @ 8bpp)
; =====================================================================
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_init {
    jsr gfx8l_init
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_clear .col {
    lda #(.col)
    jsr gfx8l_clear
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_pset .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    jsr gfx8l_pset
}
}
; -> A = colour
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_read .x, .y {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    jsr gfx8l_read
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_hline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    jsr gfx8l_hline
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_vline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    jsr gfx8l_vline
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_rect .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #(.h)
    sta X16_P6
    jsr gfx8l_rect
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_frame .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #(.h)
    sta X16_P6
    jsr gfx8l_frame
}
}
; A/X = the address of an 8x8 1bpp pattern
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_pattern_set .pat {
    lda #<(.pat)
    ldx #>(.pat)
    jsr gfx8l_pattern_set
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_pattern_rect .x, .y, .w, .h {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #(.h)
    sta X16_P6
    jsr gfx8l_pattern_rect
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_line .x0, .y0, .x1, .y1, .col {
    lda #<(.x0)
    sta X16_P0
    lda #>(.x0)
    sta X16_P1
    lda #(.y0)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.x1)
    sta X16_P4
    lda #>(.x1)
    sta X16_P5
    lda #(.y1)
    sta X16_P6
    jsr gfx8l_line
}
}
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_char .code, .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #(.code)
    jsr gfx8l_char
}
}
; str = a NUL-terminated string
!ifdef X16_USE_BITMAP8L {
!macro xm_gfx8l_text .str, .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.str)
    ldx #>(.str)
    jsr gfx8l_text
}
}

; =====================================================================
; gfx/bitmap8h  (640x480 @ 8bpp; VERA_2 SDRAM layer)
; =====================================================================
!ifdef X16_USE_BITMAP8H {
!macro xm_gfx8h_has {
    jsr gfx8h_has
}
!macro xm_gfx8h_init {
    jsr gfx8h_init
}
!macro xm_gfx8h_off {
    jsr gfx8h_off
}
!macro xm_gfx8h_passthru_on {
    jsr gfx8h_passthru_on
}
!macro xm_gfx8h_passthru_off {
    jsr gfx8h_passthru_off
}
!macro xm_gfx8h_pal_set .index, .lo, .hi {
    ldx #(.index)
    lda #(.lo)
    ldy #(.hi)
    jsr gfx8h_pal_set
}
!macro xm_gfx8h_pal_load .src, .first, .count {
    lda #<(.src)
    sta X16_PTR0
    lda #>(.src)
    sta X16_PTR0+1
    lda #(.first)
    ldx #(.count)
    jsr gfx8h_pal_load
}
!macro xm_gfx8h_clear .col {
    lda #(.col)
    jsr gfx8h_clear
}
!macro xm_gfx8h_pset .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #(.col)
    jsr gfx8h_pset
}
!macro xm_gfx8h_read .x, .y {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    jsr gfx8h_read
}
!macro xm_gfx8h_hline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    lda #(.col)
    jsr gfx8h_hline
}
!macro xm_gfx8h_vline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    lda #(.col)
    jsr gfx8h_vline
}
!macro xm_gfx8h_rect .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    lda #(.col)
    jsr gfx8h_rect
}
!macro xm_gfx8h_frame .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    lda #(.col)
    jsr gfx8h_frame
}
!macro xm_gfx8h_line .x0, .y0, .x1, .y1, .col {
    lda #<(.x0)
    sta X16_P0
    lda #>(.x0)
    sta X16_P1
    lda #<(.y0)
    sta X16_P2
    lda #>(.y0)
    sta X16_P3
    lda #<(.x1)
    sta X16_P4
    lda #>(.x1)
    sta X16_P5
    lda #<(.y1)
    sta X16_P6
    lda #>(.y1)
    sta X16_P7
    lda #(.col)
    jsr gfx8h_line
}
!macro xm_gfx8h_pattern_set .pat, .bg, .fg {
    lda #(.bg)
    sta X16_P4
    lda #(.fg)
    sta X16_P5
    lda #<(.pat)
    ldx #>(.pat)
    jsr gfx8h_pattern_set
}
!macro xm_gfx8h_pattern_rect .x, .y, .w, .h {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    jsr gfx8h_pattern_rect
}
!macro xm_gfx8h_copy .src, .dst, .len {
    lda #<(.src)
    sta X16_P0
    lda #>((.src) >> 8)
    sta X16_P1
    lda #>((.src) >> 16)
    sta X16_P2
    lda #<(.dst)
    sta X16_P3
    lda #>((.dst) >> 8)
    sta X16_P4
    lda #>((.dst) >> 16)
    sta X16_P5
    lda #<(.len)
    ldx #>((.len) >> 8)
    ldy #>((.len) >> 16)
    jsr gfx8h_copy
}
}

; =====================================================================
; gfx/bitmap2h  (640x480 @ 2bpp; colour in A)
; =====================================================================
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_init {
    jsr gfx2h_init
}
}
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_clear .col {
    lda #(.col)
    jsr gfx2h_clear
}
}
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_pset .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #(.col)
    jsr gfx2h_pset
}
}
; -> A = colour, carry set if (x,y) is off screen
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_read .x, .y {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    jsr gfx2h_read
}
}
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_hline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    lda #(.col)
    jsr gfx2h_hline
}
}
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_vline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    lda #(.col)
    jsr gfx2h_vline
}
}
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_rect .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    lda #(.col)
    jsr gfx2h_rect
}
}
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_frame .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    lda #(.col)
    jsr gfx2h_frame
}
}
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_line .x0, .y0, .x1, .y1, .col {
    lda #<(.x0)
    sta X16_P0
    lda #>(.x0)
    sta X16_P1
    lda #<(.y0)
    sta X16_P2
    lda #>(.y0)
    sta X16_P3
    lda #<(.x1)
    sta X16_P4
    lda #>(.x1)
    sta X16_P5
    lda #<(.y1)
    sta X16_P6
    lda #>(.y1)
    sta X16_P7
    lda #(.col)
    jsr gfx2h_line
}
}
; A/X = the address of an 8x8 1bpp pattern
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_pattern_set .pat {
    lda #<(.pat)
    ldx #>(.pat)
    jsr gfx2h_pattern_set
}
}
!ifdef X16_USE_BITMAP2H {
!macro xm_gfx2h_pattern_rect .x, .y, .w, .h {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    jsr gfx2h_pattern_rect
}
}

; =====================================================================
; gfx/bitmap2l  (320x240 @ 2bpp; colour in A)
; =====================================================================
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_init {
    jsr gfx2l_init
}
}
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_clear .col {
    lda #(.col)
    jsr gfx2l_clear
}
}
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_pset .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #(.col)
    jsr gfx2l_pset
}
}
; -> A = colour, carry set if (x,y) is off screen
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_read .x, .y {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    jsr gfx2l_read
}
}
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_hline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    lda #(.col)
    jsr gfx2l_hline
}
}
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_vline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    lda #(.col)
    jsr gfx2l_vline
}
}
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_rect .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    lda #(.col)
    jsr gfx2l_rect
}
}
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_frame .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    lda #(.col)
    jsr gfx2l_frame
}
}
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_line .x0, .y0, .x1, .y1, .col {
    lda #<(.x0)
    sta X16_P0
    lda #>(.x0)
    sta X16_P1
    lda #<(.y0)
    sta X16_P2
    lda #>(.y0)
    sta X16_P3
    lda #<(.x1)
    sta X16_P4
    lda #>(.x1)
    sta X16_P5
    lda #<(.y1)
    sta X16_P6
    lda #>(.y1)
    sta X16_P7
    lda #(.col)
    jsr gfx2l_line
}
}
; A/X = the address of an 8x8 1bpp pattern
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_pattern_set .pat {
    lda #<(.pat)
    ldx #>(.pat)
    jsr gfx2l_pattern_set
}
}
!ifdef X16_USE_BITMAP2L {
!macro xm_gfx2l_pattern_rect .x, .y, .w, .h {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    jsr gfx2l_pattern_rect
}
}

; =====================================================================
; gfx/bitmap4l  (320x240 @ 4bpp)
; =====================================================================
!ifdef X16_USE_BITMAP4L {
!macro xm_gfx4l_init {
    jsr gfx4l_init
}
!macro xm_gfx4l_clear .col {
    lda #(.col)
    jsr gfx4l_clear
}
!macro xm_gfx4l_pset .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    jsr gfx4l_pset
}
!macro xm_gfx4l_read .x, .y {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    jsr gfx4l_read
}
!macro xm_gfx4l_hline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    jsr gfx4l_hline
}
!macro xm_gfx4l_vline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #(.len)
    sta X16_P4
    jsr gfx4l_vline
}
!macro xm_gfx4l_rect .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #(.h)
    sta X16_P6
    jsr gfx4l_rect
}
!macro xm_gfx4l_frame .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #(.h)
    sta X16_P6
    jsr gfx4l_frame
}
!macro xm_gfx4l_line .x0, .y0, .x1, .y1, .col {
    lda #<(.x0)
    sta X16_P0
    lda #>(.x0)
    sta X16_P1
    lda #(.y0)
    sta X16_P2
    lda #<(.x1)
    sta X16_P3
    lda #>(.x1)
    sta X16_P4
    lda #(.y1)
    sta X16_P5
    lda #(.col)
    sta X16_P6
    jsr gfx4l_line
}
!macro xm_gfx4l_pattern_set .pat, .bg, .fg {
    lda #(.bg)
    sta X16_P4
    lda #(.fg)
    sta X16_P5
    lda #<(.pat)
    ldx #>(.pat)
    jsr gfx4l_pattern_set
}
!macro xm_gfx4l_pattern_rect .x, .y, .w, .h {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #(.h)
    sta X16_P6
    jsr gfx4l_pattern_rect
}
!macro xm_gfx4l_char .code, .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #(.code)
    jsr gfx4l_char
}
!macro xm_gfx4l_text .str, .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #(.y)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.str)
    ldx #>(.str)
    jsr gfx4l_text
}
}

; =====================================================================
; gfx/bitmap4h  (640x480 @ 4bpp; VERA_2 SDRAM layer)
; =====================================================================
!ifdef X16_USE_BITMAP4H {
!macro xm_gfx4h_has {
    jsr gfx4h_has
}
!macro xm_gfx4h_init {
    jsr gfx4h_init
}
!macro xm_gfx4h_off {
    jsr gfx4h_off
}
!macro xm_gfx4h_passthru_on {
    jsr gfx4h_passthru_on
}
!macro xm_gfx4h_passthru_off {
    jsr gfx4h_passthru_off
}
!macro xm_gfx4h_pal_set .index, .lo, .hi {
    ldx #(.index)
    lda #(.lo)
    ldy #(.hi)
    jsr gfx4h_pal_set
}
!macro xm_gfx4h_pal_load .src, .first, .count {
    lda #<(.src)
    sta X16_PTR0
    lda #>(.src)
    sta X16_PTR0+1
    lda #(.first)
    ldx #(.count)
    jsr gfx4h_pal_load
}
!macro xm_gfx4h_clear .col {
    lda #(.col)
    jsr gfx4h_clear
}
!macro xm_gfx4h_pset .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #(.col)
    jsr gfx4h_pset
}
!macro xm_gfx4h_read .x, .y {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    jsr gfx4h_read
}
!macro xm_gfx4h_hline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    lda #(.col)
    jsr gfx4h_hline
}
!macro xm_gfx4h_vline .x, .y, .len, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.len)
    sta X16_P4
    lda #>(.len)
    sta X16_P5
    lda #(.col)
    jsr gfx4h_vline
}
!macro xm_gfx4h_rect .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    lda #(.col)
    jsr gfx4h_rect
}
!macro xm_gfx4h_frame .x, .y, .w, .h, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    lda #(.col)
    jsr gfx4h_frame
}
!macro xm_gfx4h_line .x0, .y0, .x1, .y1, .col {
    lda #<(.x0)
    sta X16_P0
    lda #>(.x0)
    sta X16_P1
    lda #<(.y0)
    sta X16_P2
    lda #>(.y0)
    sta X16_P3
    lda #<(.x1)
    sta X16_P4
    lda #>(.x1)
    sta X16_P5
    lda #<(.y1)
    sta X16_P6
    lda #>(.y1)
    sta X16_P7
    lda #(.col)
    jsr gfx4h_line
}
!macro xm_gfx4h_pattern_set .pat, .bg, .fg {
    lda #(.bg)
    sta X16_P4
    lda #(.fg)
    sta X16_P5
    lda #<(.pat)
    ldx #>(.pat)
    jsr gfx4h_pattern_set
}
!macro xm_gfx4h_pattern_rect .x, .y, .w, .h {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #<(.w)
    sta X16_P4
    lda #>(.w)
    sta X16_P5
    lda #<(.h)
    sta X16_P6
    lda #>(.h)
    sta X16_P7
    jsr gfx4h_pattern_rect
}
!macro xm_gfx4h_copy .src, .dst, .len {
    lda #<(.src)
    sta X16_P0
    lda #>((.src) >> 8)
    sta X16_P1
    lda #>((.src) >> 16)
    sta X16_P2
    lda #<(.dst)
    sta X16_P3
    lda #>((.dst) >> 8)
    sta X16_P4
    lda #>((.dst) >> 16)
    sta X16_P5
    lda #<(.len)
    ldx #>((.len) >> 8)
    ldy #>((.len) >> 16)
    jsr gfx4h_copy
}
}

; =====================================================================
; gfx/graph  (KERNAL GRAPH API)
; =====================================================================
!ifdef X16_USE_GRAPH {
!macro xm_graph_init_default {
    stz r0L
    stz r0H
    jsr graph_init
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_init .driver {
    lda #<(.driver)
    sta r0L
    lda #>(.driver)
    sta r0H
    jsr graph_init
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_clear {
    jsr graph_clear
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_set_window .x, .y, .w, .h {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    lda #<(.w)
    sta r2L
    lda #>(.w)
    sta r2H
    lda #<(.h)
    sta r3L
    lda #>(.h)
    sta r3H
    jsr graph_set_window
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_set_colors .stroke, .fill, .background {
    lda #(.stroke)
    ldx #(.fill)
    ldy #(.background)
    jsr graph_set_colors
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_draw_line .x1, .y1, .x2, .y2 {
    lda #<(.x1)
    sta r0L
    lda #>(.x1)
    sta r0H
    lda #<(.y1)
    sta r1L
    lda #>(.y1)
    sta r1H
    lda #<(.x2)
    sta r2L
    lda #>(.x2)
    sta r2H
    lda #<(.y2)
    sta r3L
    lda #>(.y2)
    sta r3H
    jsr graph_draw_line
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_draw_rect_outline .x, .y, .w, .h, .radius {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    lda #<(.w)
    sta r2L
    lda #>(.w)
    sta r2H
    lda #<(.h)
    sta r3L
    lda #>(.h)
    sta r3H
    lda #<(.radius)
    sta r4L
    lda #>(.radius)
    sta r4H
    clc
    jsr graph_draw_rect
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_draw_rect_fill .x, .y, .w, .h, .radius {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    lda #<(.w)
    sta r2L
    lda #>(.w)
    sta r2H
    lda #<(.h)
    sta r3L
    lda #>(.h)
    sta r3H
    lda #<(.radius)
    sta r4L
    lda #>(.radius)
    sta r4H
    sec
    jsr graph_draw_rect
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_move_rect .sx, .sy, .tx, .ty, .w, .h {
    lda #<(.sx)
    sta r0L
    lda #>(.sx)
    sta r0H
    lda #<(.sy)
    sta r1L
    lda #>(.sy)
    sta r1H
    lda #<(.tx)
    sta r2L
    lda #>(.tx)
    sta r2H
    lda #<(.ty)
    sta r3L
    lda #>(.ty)
    sta r3H
    lda #<(.w)
    sta r4L
    lda #>(.w)
    sta r4H
    lda #<(.h)
    sta r5L
    lda #>(.h)
    sta r5H
    jsr graph_move_rect
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_draw_oval_outline .x, .y, .w, .h {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    lda #<(.w)
    sta r2L
    lda #>(.w)
    sta r2H
    lda #<(.h)
    sta r3L
    lda #>(.h)
    sta r3H
    clc
    jsr graph_draw_oval
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_draw_oval_fill .x, .y, .w, .h {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    lda #<(.w)
    sta r2L
    lda #>(.w)
    sta r2H
    lda #<(.h)
    sta r3L
    lda #>(.h)
    sta r3H
    sec
    jsr graph_draw_oval
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_draw_image .x, .y, .image, .w, .h {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    lda #<(.image)
    sta r2L
    lda #>(.image)
    sta r2H
    lda #<(.w)
    sta r3L
    lda #>(.w)
    sta r3H
    lda #<(.h)
    sta r4L
    lda #>(.h)
    sta r4H
    jsr graph_draw_image
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_set_font_default {
    stz r0L
    stz r0H
    jsr graph_set_font
}
}
!ifdef X16_USE_GRAPH {
!macro xm_graph_set_font .font {
    lda #<(.font)
    sta r0L
    lda #>(.font)
    sta r0H
    jsr graph_set_font
}
}
; -> printable: C clear, A baseline, X width, Y height; control: C set
!ifdef X16_USE_GRAPH {
!macro xm_graph_get_char_size .char, .style {
    lda #(.char)
    ldx #(.style)
    jsr graph_get_char_size
}
}
; -> r0/r1 updated, carry set if outside bounds
!ifdef X16_USE_GRAPH {
!macro xm_graph_put_char .char, .x, .y {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    lda #(.char)
    jsr graph_put_char
}
}

; =====================================================================
; gfx/console  (KERNAL console API)
; =====================================================================
!ifdef X16_USE_CONSOLE {
!macro xm_con_init_fullscreen {
    stz r0L
    stz r0H
    stz r1L
    stz r1H
    stz r2L
    stz r2H
    stz r3L
    stz r3H
    jsr con_init
}
}
!ifdef X16_USE_CONSOLE {
!macro xm_con_init .x, .y, .w, .h {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    lda #<(.w)
    sta r2L
    lda #>(.w)
    sta r2H
    lda #<(.h)
    sta r3L
    lda #>(.h)
    sta r3H
    jsr con_init
}
}
!ifdef X16_USE_CONSOLE {
!macro xm_con_set_paging_message .msg {
    lda #<(.msg)
    sta r0L
    lda #>(.msg)
    sta r0H
    jsr con_set_paging_message
}
}
!ifdef X16_USE_CONSOLE {
!macro xm_con_disable_paging {
    jsr con_disable_paging
}
}
!ifdef X16_USE_CONSOLE {
!macro xm_con_put_char_wrap .char {
    lda #(.char)
    clc
    jsr con_put_char
}
}
!ifdef X16_USE_CONSOLE {
!macro xm_con_put_char_word .char {
    lda #(.char)
    sec
    jsr con_put_char
}
}
!ifdef X16_USE_CONSOLE {
!macro xm_con_get_char {
    jsr con_get_char
}
}
!ifdef X16_USE_CONSOLE {
!macro xm_con_put_image .image, .w, .h {
    lda #<(.image)
    sta r0L
    lda #>(.image)
    sta r0H
    lda #<(.w)
    sta r1L
    lda #>(.w)
    sta r1H
    lda #<(.h)
    sta r2L
    lda #>(.h)
    sta r2H
    jsr con_put_image
}
}

; =====================================================================
; gfx/fb  (KERNAL framebuffer API)
; =====================================================================
!ifdef X16_USE_FB {
!macro xm_fb_init {
    jsr fb_init
}
}
!ifdef X16_USE_FB {
!macro xm_fb_get_info {
    jsr fb_get_info
}
}
!ifdef X16_USE_FB {
!macro xm_fb_set_palette .data, .start, .count {
    lda #<(.data)
    sta r0L
    lda #>(.data)
    sta r0H
    lda #(.start)
    ldx #(.count)
    jsr fb_set_palette
}
}
!ifdef X16_USE_FB {
!macro xm_fb_cursor_position .x, .y {
    lda #<(.x)
    sta r0L
    lda #>(.x)
    sta r0H
    lda #<(.y)
    sta r1L
    lda #>(.y)
    sta r1H
    jsr fb_cursor_position
}
}
!ifdef X16_USE_FB {
!macro xm_fb_cursor_next_line {
    jsr fb_cursor_next_line
}
}
; -> A = color
!ifdef X16_USE_FB {
!macro xm_fb_get_pixel .x, .y {
    +xm_fb_cursor_position .x, .y
    jsr fb_get_pixel
}
}
!ifdef X16_USE_FB {
!macro xm_fb_set_pixel .x, .y, .color {
    +xm_fb_cursor_position .x, .y
    lda #(.color)
    jsr fb_set_pixel
}
}
!ifdef X16_USE_FB {
!macro xm_fb_get_pixels .dest, .count {
    lda #<(.dest)
    sta r0L
    lda #>(.dest)
    sta r0H
    lda #<(.count)
    sta r1L
    lda #>(.count)
    sta r1H
    jsr fb_get_pixels
}
}
!ifdef X16_USE_FB {
!macro xm_fb_set_pixels .src, .count {
    lda #<(.src)
    sta r0L
    lda #>(.src)
    sta r0H
    lda #<(.count)
    sta r1L
    lda #>(.count)
    sta r1H
    jsr fb_set_pixels
}
}
!ifdef X16_USE_FB {
!macro xm_fb_set_8_pixels .pattern, .color {
    lda #(.pattern)
    ldx #(.color)
    jsr fb_set_8_pixels
}
}
!ifdef X16_USE_FB {
!macro xm_fb_set_8_pixels_opaque .mask, .pattern, .fg, .bg {
    lda #<(.pattern)
    sta r0L
    lda #(.mask)
    ldx #(.fg)
    ldy #(.bg)
    jsr fb_set_8_pixels_opaque
}
}
!ifdef X16_USE_FB {
!macro xm_fb_fill_pixels .count, .step, .color {
    lda #<(.count)
    sta r0L
    lda #>(.count)
    sta r0H
    lda #<(.step)
    sta r1L
    lda #>(.step)
    sta r1H
    lda #(.color)
    jsr fb_fill_pixels
}
}
!ifdef X16_USE_FB {
!macro xm_fb_filter_pixels .count, .filter {
    lda #<(.count)
    sta r0L
    lda #>(.count)
    sta r0H
    lda #<(.filter)
    sta r1L
    lda #>(.filter)
    sta r1H
    jsr fb_filter_pixels
}
}
!ifdef X16_USE_FB {
!macro xm_fb_move_pixels .sx, .sy, .tx, .ty, .count {
    lda #<(.sx)
    sta r0L
    lda #>(.sx)
    sta r0H
    lda #<(.sy)
    sta r1L
    lda #>(.sy)
    sta r1H
    lda #<(.tx)
    sta r2L
    lda #>(.tx)
    sta r2H
    lda #<(.ty)
    sta r3L
    lda #>(.ty)
    sta r3H
    lda #<(.count)
    sta r4L
    lda #>(.count)
    sta r4H
    jsr fb_move_pixels
}
}

; =====================================================================
; gfx/shapes  (engine-agnostic; bind SHP_* to pick the engine)
; =====================================================================
!ifdef X16_USE_SHAPES {
!macro xm_shape_circle .cx, .cy, .r, .col {
    lda #<(.cx)
    sta X16_P0
    lda #>(.cx)
    sta X16_P1
    lda #<(.cy)
    sta X16_P2
    lda #>(.cy)
    sta X16_P3
    lda #(.r)
    sta X16_P4
    lda #(.col)
    jsr shape_circle
}
}
!ifdef X16_USE_SHAPES {
!macro xm_shape_disc .cx, .cy, .r, .col {
    lda #<(.cx)
    sta X16_P0
    lda #>(.cx)
    sta X16_P1
    lda #<(.cy)
    sta X16_P2
    lda #>(.cy)
    sta X16_P3
    lda #(.r)
    sta X16_P4
    lda #(.col)
    jsr shape_disc
}
}
!ifdef X16_USE_SHAPES {
!macro xm_shape_ellipse .cx, .cy, .rx, .ry, .col {
    lda #<(.cx)
    sta X16_P0
    lda #>(.cx)
    sta X16_P1
    lda #<(.cy)
    sta X16_P2
    lda #>(.cy)
    sta X16_P3
    lda #(.rx)
    sta X16_P4
    lda #(.ry)
    sta X16_P5
    lda #(.col)
    jsr shape_ellipse
}
}
!ifdef X16_USE_SHAPES {
!macro xm_shape_fellipse .cx, .cy, .rx, .ry, .col {
    lda #<(.cx)
    sta X16_P0
    lda #>(.cx)
    sta X16_P1
    lda #<(.cy)
    sta X16_P2
    lda #>(.cy)
    sta X16_P3
    lda #(.rx)
    sta X16_P4
    lda #(.ry)
    sta X16_P5
    lda #(.col)
    jsr shape_fellipse
}
}
!ifdef X16_USE_SHAPES_RRECT {
!macro xm_shape_rrect .x, .y, .w, .h, .r, .col {
    lda #<(.x)
    sta rr_x
    lda #>(.x)
    sta rr_x+1
    lda #<(.y)
    sta rr_y
    lda #>(.y)
    sta rr_y+1
    lda #<(.w)
    sta rr_w
    lda #>(.w)
    sta rr_w+1
    lda #<(.h)
    sta rr_h
    lda #>(.h)
    sta rr_h+1
    lda #(.r)
    sta rr_r
    lda #(.col)
    jsr shape_rrect
}
}
!ifdef X16_USE_SHAPES_RRECT {
!macro xm_shape_frrect .x, .y, .w, .h, .r, .col {
    lda #<(.x)
    sta rr_x
    lda #>(.x)
    sta rr_x+1
    lda #<(.y)
    sta rr_y
    lda #>(.y)
    sta rr_y+1
    lda #<(.w)
    sta rr_w
    lda #>(.w)
    sta rr_w+1
    lda #<(.h)
    sta rr_h
    lda #>(.h)
    sta rr_h+1
    lda #(.r)
    sta rr_r
    lda #(.col)
    jsr shape_frrect
}
}
!ifdef X16_USE_SHAPES_POLY {
!macro xm_shape_polygon .cx, .cy, .r, .sides, .rot, .col {
    lda #<(.cx)
    sta X16_P0
    lda #>(.cx)
    sta X16_P1
    lda #<(.cy)
    sta X16_P2
    lda #>(.cy)
    sta X16_P3
    lda #(.r)
    sta X16_P4
    lda #(.sides)
    sta X16_P5
    lda #(.rot)
    sta X16_P6
    lda #(.col)
    jsr shape_polygon
}
}
!ifdef X16_USE_SHAPES_POLY {
!macro xm_shape_fpolygon .cx, .cy, .r, .sides, .rot, .col {
    lda #<(.cx)
    sta X16_P0
    lda #>(.cx)
    sta X16_P1
    lda #<(.cy)
    sta X16_P2
    lda #>(.cy)
    sta X16_P3
    lda #(.r)
    sta X16_P4
    lda #(.sides)
    sta X16_P5
    lda #(.rot)
    sta X16_P6
    lda #(.col)
    jsr shape_fpolygon
}
}
!ifdef X16_USE_SHAPES_ARC {
!macro xm_shape_arc .cx, .cy, .r, .a0, .a1, .col {
    lda #<(.cx)
    sta X16_P0
    lda #>(.cx)
    sta X16_P1
    lda #<(.cy)
    sta X16_P2
    lda #>(.cy)
    sta X16_P3
    lda #(.r)
    sta X16_P4
    lda #(.a0)
    sta X16_P5
    lda #(.a1)
    sta X16_P6
    lda #(.col)
    jsr shape_arc
}
}
!ifdef X16_USE_SHAPES_PIE {
!macro xm_shape_pie .cx, .cy, .r, .a0, .a1, .col {
    lda #<(.cx)
    sta X16_P0
    lda #>(.cx)
    sta X16_P1
    lda #<(.cy)
    sta X16_P2
    lda #>(.cy)
    sta X16_P3
    lda #(.r)
    sta X16_P4
    lda #(.a0)
    sta X16_P5
    lda #(.a1)
    sta X16_P6
    lda #(.col)
    jsr shape_pie
}
}
!ifdef X16_USE_SHAPES_BEZIER {
!macro xm_shape_bezier .x0, .y0, .x1, .y1, .x2, .y2, .x3, .y3, .col {
    lda #<(.x0)
    sta bez_x0
    lda #>(.x0)
    sta bez_x0+1
    lda #<(.y0)
    sta bez_y0
    lda #>(.y0)
    sta bez_y0+1
    lda #<(.x1)
    sta bez_x1
    lda #>(.x1)
    sta bez_x1+1
    lda #<(.y1)
    sta bez_y1
    lda #>(.y1)
    sta bez_y1+1
    lda #<(.x2)
    sta bez_x2
    lda #>(.x2)
    sta bez_x2+1
    lda #<(.y2)
    sta bez_y2
    lda #>(.y2)
    sta bez_y2+1
    lda #<(.x3)
    sta bez_x3
    lda #>(.x3)
    sta bez_x3+1
    lda #<(.y3)
    sta bez_y3
    lda #>(.y3)
    sta bez_y3+1
    lda #(.col)
    jsr shape_bezier
}
}
; -> carry set if the seed stack overflowed
!ifdef X16_USE_SHAPES {
!macro xm_shape_flood .x, .y, .col {
    lda #<(.x)
    sta X16_P0
    lda #>(.x)
    sta X16_P1
    lda #<(.y)
    sta X16_P2
    lda #>(.y)
    sta X16_P3
    lda #(.col)
    jsr shape_flood
}
}

; =====================================================================
; gfx/verafx  (VERA FX; check vera_has_fx first)
; =====================================================================
!ifdef X16_USE_VERAFX {
!macro xm_fx_off {
    jsr fx_off
}
}
; -> P4..P7 = signed 16x16 product
!ifdef X16_USE_VERAFX {
!macro xm_fx_mult .a, .b {
    lda #<(.a)
    sta X16_P0
    lda #>(.a)
    sta X16_P1
    lda #<(.b)
    sta X16_P2
    lda #>(.b)
    sta X16_P3
    jsr fx_mult
}
}
; fill `count` bytes with `val` from the current port address
!ifdef X16_USE_VERAFX {
!macro xm_fx_fill .val, .count {
    lda #(.val)
    ldx #<(.count)
    ldy #>(.count)
    jsr fx_fill
}
}
!ifdef X16_USE_VERAFX {
!macro xm_fx_clear .addrlo, .addrmid, .addrhi, .count {
    lda #(.addrlo)
    sta X16_P0
    lda #(.addrmid)
    sta X16_P1
    lda #(.addrhi)
    sta X16_P2
    lda #<(.count)
    sta X16_P3
    lda #>(.count)
    sta X16_P4
    jsr fx_clear
}
}
!ifdef X16_USE_VERAFX {
!macro xm_fx_transp_on {
    jsr fx_transp_on
}
}
!ifdef X16_USE_VERAFX {
!macro xm_fx_transp_off {
    jsr fx_transp_off
}
}
!ifdef X16_USE_VERAFX {
!macro xm_fx_line .x0, .y0, .x1, .y1, .col {
    lda #<(.x0)
    sta X16_P0
    lda #>(.x0)
    sta X16_P1
    lda #(.y0)
    sta X16_P2
    lda #(.col)
    sta X16_P3
    lda #<(.x1)
    sta X16_P4
    lda #>(.x1)
    sta X16_P5
    lda #(.y1)
    sta X16_P6
    jsr fx_line
}
}

; =====================================================================
; gfx/verafx_utils  (low-level VERA FX primitives)
; =====================================================================
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_off {
    jsr fxu_off
}
}
; -> A = FX_CTRL
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_get_ctrl {
    jsr fxu_get_ctrl
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_set_ctrl .ctrl {
    lda #(.ctrl)
    jsr fxu_set_ctrl
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_ctrl_on .mask {
    lda #(.mask)
    jsr fxu_ctrl_on
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_ctrl_off .mask {
    lda #(.mask)
    jsr fxu_ctrl_off
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_addr1_mode .mode {
    lda #(.mode)
    jsr fxu_addr1_mode
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_write_on {
    jsr fxu_cache_write_on
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_write_off {
    jsr fxu_cache_write_off
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_fill_on {
    jsr fxu_cache_fill_on
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_fill_off {
    jsr fxu_cache_fill_off
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_cycle_on {
    jsr fxu_cache_cycle_on
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_cycle_off {
    jsr fxu_cache_cycle_off
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_transparent_on {
    jsr fxu_transparent_on
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_transparent_off {
    jsr fxu_transparent_off
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_4bit_on {
    jsr fxu_4bit_on
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_4bit_off {
    jsr fxu_4bit_off
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_hop_on {
    jsr fxu_hop_on
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_hop_off {
    jsr fxu_hop_off
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_set_mult .mult {
    lda #(.mult)
    jsr fxu_set_mult
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_set_cache .b0, .b1, .b2, .b3 {
    lda #(.b0)
    sta X16_P0
    lda #(.b1)
    sta X16_P1
    lda #(.b2)
    sta X16_P2
    lda #(.b3)
    sta X16_P3
    jsr fxu_set_cache
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_reset_accum {
    jsr fxu_reset_accum
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_accumulate {
    jsr fxu_accumulate
}
}
; -> A = DATA0 read
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_fill0 {
    jsr fxu_cache_fill0
}
}
; -> A = DATA1 read
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_fill1 {
    jsr fxu_cache_fill1
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_write0 .mask {
    lda #(.mask)
    jsr fxu_cache_write0
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_cache_write1 .mask {
    lda #(.mask)
    jsr fxu_cache_write1
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_set_incr .xinc, .yinc {
    lda #<(.xinc)
    sta X16_P0
    lda #>(.xinc)
    sta X16_P1
    lda #<(.yinc)
    sta X16_P2
    lda #>(.yinc)
    sta X16_P3
    jsr fxu_set_incr
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_set_pos .xpos, .ypos {
    lda #<(.xpos)
    sta X16_P0
    lda #>(.xpos)
    sta X16_P1
    lda #<(.ypos)
    sta X16_P2
    lda #>(.ypos)
    sta X16_P3
    jsr fxu_set_pos
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_set_subpos .xsub, .ysub {
    lda #(.xsub)
    ldx #(.ysub)
    jsr fxu_set_subpos
}
}
; -> A = poly fill low, X = high
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_get_poly_fill {
    jsr fxu_get_poly_fill
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_set_tilebase .value {
    lda #(.value)
    jsr fxu_set_tilebase
}
}
!ifdef X16_USE_VERAFX_UTILS {
!macro xm_fxu_set_mapbase .value {
    lda #(.value)
    jsr fxu_set_mapbase
}
}

; =====================================================================
; system/irq
; =====================================================================
!ifdef X16_USE_IRQ {
!macro xm_irq_install {
    jsr irq_install
}
}
!ifdef X16_USE_IRQ {
!macro xm_irq_remove {
    jsr irq_remove
}
}
!ifdef X16_USE_IRQ {
!macro xm_vsync_wait {
    jsr vsync_wait
}
}
!ifdef X16_USE_IRQ {
!macro xm_irq_line_install .handler {
    lda #<(.handler)
    ldx #>(.handler)
    jsr irq_line_install
}
}
; handler = 0 for polling (read with sprite_collisions)
!ifdef X16_USE_IRQ {
!macro xm_irq_sprcol_install .handler {
    lda #<(.handler)
    ldx #>(.handler)
    jsr irq_sprcol_install
}
}
!ifdef X16_USE_IRQ {
!macro xm_irq_sprcol_remove {
    jsr irq_sprcol_remove
}
}

; =====================================================================
; audio/psg
; =====================================================================
!ifdef X16_USE_PSG {
!macro xm_psg_init {
    jsr psg_init
}
}
!ifdef X16_USE_PSG {
!macro xm_psg_set_freq .voice, .freq {
    ldx #(.voice)
    lda #<(.freq)
    sta X16_P0
    lda #>(.freq)
    sta X16_P1
    jsr psg_set_freq
}
}
!ifdef X16_USE_PSG {
!macro xm_psg_set_vol .voice, .vol, .pan {
    ldx #(.voice)
    lda #(.vol)
    ldy #(.pan)
    jsr psg_set_vol
}
}
!ifdef X16_USE_PSG {
!macro xm_psg_set_wave .voice, .wave, .width {
    ldx #(.voice)
    lda #(.wave)
    ldy #(.width)
    jsr psg_set_wave
}
}
!ifdef X16_USE_PSG {
!macro xm_psg_note_off .voice {
    ldx #(.voice)
    jsr psg_note_off
}
}
!ifdef X16_USE_PSG {
!macro xm_psg_env_start .voice {
    lda #(.voice)
    jsr psg_env_start
}
}
!ifdef X16_USE_PSG {
!macro xm_psg_env_release .voice {
    lda #(.voice)
    jsr psg_env_release
}
}
!ifdef X16_USE_PSG {
!macro xm_psg_env_stop .voice {
    lda #(.voice)
    jsr psg_env_stop
}
}
!ifdef X16_USE_PSG {
!macro xm_psg_env_tick {
    jsr psg_env_tick
}
}

; =====================================================================
; audio/ym  (YM2151 FM)
; =====================================================================
!ifdef X16_USE_YM {
!macro xm_ym_init {
    jsr ym_init
}
}
!ifdef X16_USE_YM {
!macro xm_ym_write .reg, .val {
    lda #(.val)
    ldx #(.reg)
    jsr ym_write
}
}
!ifdef X16_USE_YM {
!macro xm_ym_poke .reg, .val {
    lda #(.val)
    ldx #(.reg)
    jsr ym_poke
}
}
; load a built-in ROM patch (0-162) into a channel
!ifdef X16_USE_YM {
!macro xm_ym_patch_rom .channel, .index {
    lda #(.channel)
    ldx #(.index)
    sec
    jsr ym_patch
}
}
!ifdef X16_USE_YM {
!macro xm_ym_note .channel, .kc, .kf {
    lda #(.channel)
    ldx #(.kc)
    ldy #(.kf)
    jsr ym_note
}
}
; note = (octave<<4)|1..12; note 0 releases
!ifdef X16_USE_YM {
!macro xm_ym_note_bas .channel, .note {
    lda #(.channel)
    ldx #(.note)
    jsr ym_note_bas
}
}
!ifdef X16_USE_YM {
!macro xm_ym_release_note .channel {
    lda #(.channel)
    jsr ym_release_note
}
}
!ifdef X16_USE_YM {
!macro xm_ym_vol .channel, .atten {
    lda #(.channel)
    ldx #(.atten)
    jsr ym_vol
}
}
!ifdef X16_USE_YM {
!macro xm_ym_pan .channel, .pan {
    lda #(.channel)
    ldx #(.pan)
    jsr ym_pan
}
}
!ifdef X16_USE_YM {
!macro xm_ym_drum .channel, .note {
    lda #(.channel)
    ldx #(.note)
    jsr ym_drum
}
}

; =====================================================================
; audio/rom  (full BANK_AUDIO API)
; =====================================================================
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_audio_init {
    jsr ar_audio_init
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_playstring_voice .voice {
    lda #(.voice)
    jsr ar_playstring_voice
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_fmplaystring .str, .len {
    lda #(.len)
    ldx #<(.str)
    ldy #>(.str)
    jsr ar_fmplaystring
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_fmchordstring .str, .len {
    lda #(.len)
    ldx #<(.str)
    ldy #>(.str)
    jsr ar_fmchordstring
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psgplaystring .str, .len {
    lda #(.len)
    ldx #<(.str)
    ldy #>(.str)
    jsr ar_psgplaystring
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psgchordstring .str, .len {
    lda #(.len)
    ldx #<(.str)
    ldy #>(.str)
    jsr ar_psgchordstring
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_fmfreq .channel, .hz {
    lda #(.channel)
    ldx #<(.hz)
    ldy #>(.hz)
    clc
    jsr ar_fmfreq
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_fmfreq_no_retrigger .channel, .hz {
    lda #(.channel)
    ldx #<(.hz)
    ldy #>(.hz)
    sec
    jsr ar_fmfreq
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_fmnote .channel, .note, .kf {
    lda #(.channel)
    ldx #(.note)
    ldy #(.kf)
    clc
    jsr ar_fmnote
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_fmnote_no_retrigger .channel, .note, .kf {
    lda #(.channel)
    ldx #(.note)
    ldy #(.kf)
    sec
    jsr ar_fmnote
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_fmvib .speed, .depth {
    lda #(.speed)
    ldx #(.depth)
    jsr ar_fmvib
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psgfreq .voice, .hz {
    lda #(.voice)
    ldx #<(.hz)
    ldy #>(.hz)
    jsr ar_psgfreq
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psgnote .voice, .note, .kf {
    lda #(.voice)
    ldx #(.note)
    ldy #(.kf)
    jsr ar_psgnote
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psgwav .voice, .wave {
    lda #(.voice)
    ldx #(.wave)
    jsr ar_psgwav
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_bas2fm .note {
    ldx #(.note)
    jsr ar_note_bas2fm
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_bas2midi .note {
    ldx #(.note)
    jsr ar_note_bas2midi
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_bas2psg .note, .kf {
    ldx #(.note)
    ldy #(.kf)
    jsr ar_note_bas2psg
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_fm2bas .kc {
    ldx #(.kc)
    jsr ar_note_fm2bas
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_fm2midi .kc {
    ldx #(.kc)
    jsr ar_note_fm2midi
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_fm2psg .kc, .kf {
    ldx #(.kc)
    ldy #(.kf)
    jsr ar_note_fm2psg
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_freq2bas .hz {
    ldx #<(.hz)
    ldy #>(.hz)
    jsr ar_note_freq2bas
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_freq2fm .hz {
    ldx #<(.hz)
    ldy #>(.hz)
    jsr ar_note_freq2fm
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_freq2midi .hz {
    ldx #<(.hz)
    ldy #>(.hz)
    jsr ar_note_freq2midi
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_freq2psg .hz {
    ldx #<(.hz)
    ldy #>(.hz)
    jsr ar_note_freq2psg
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_midi2bas .note {
    lda #(.note)
    jsr ar_note_midi2bas
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_midi2fm .note {
    ldx #(.note)
    jsr ar_note_midi2fm
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_midi2psg .note, .kf {
    ldx #(.note)
    ldy #(.kf)
    jsr ar_note_midi2psg
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_psg2bas .freq {
    ldx #<(.freq)
    ldy #>(.freq)
    jsr ar_note_psg2bas
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_psg2fm .freq {
    ldx #<(.freq)
    ldy #>(.freq)
    jsr ar_note_psg2fm
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_note_psg2midi .freq {
    ldx #<(.freq)
    ldy #>(.freq)
    jsr ar_note_psg2midi
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_init {
    jsr ar_psg_init
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_playfreq .voice, .freq {
    lda #(.voice)
    ldx #<(.freq)
    ldy #>(.freq)
    jsr ar_psg_playfreq
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_read_raw .reg {
    ldx #(.reg)
    clc
    jsr ar_psg_read
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_read_cooked .reg {
    ldx #(.reg)
    sec
    jsr ar_psg_read
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_setatten .voice, .atten {
    lda #(.voice)
    ldx #(.atten)
    jsr ar_psg_setatten
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_setfreq .voice, .freq {
    lda #(.voice)
    ldx #<(.freq)
    ldy #>(.freq)
    jsr ar_psg_setfreq
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_setpan .voice, .pan {
    lda #(.voice)
    ldx #(.pan)
    jsr ar_psg_setpan
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_setvol .voice, .vol {
    lda #(.voice)
    ldx #(.vol)
    jsr ar_psg_setvol
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_write .reg, .value {
    lda #(.value)
    ldx #(.reg)
    jsr ar_psg_write
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_write_fast .reg, .value {
    lda #(.value)
    ldx #(.reg)
    jsr ar_psg_write_fast
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_getatten .voice {
    lda #(.voice)
    jsr ar_psg_getatten
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_psg_getpan .voice {
    lda #(.voice)
    jsr ar_psg_getpan
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_init {
    jsr ar_ym_init
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_loaddefpatches {
    jsr ar_ym_loaddefpatches
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_loadpatch_rom .channel, .patch {
    lda #(.channel)
    ldx #(.patch)
    sec
    jsr ar_ym_loadpatch
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_loadpatchlfn .channel, .lfn {
    lda #(.channel)
    ldx #(.lfn)
    jsr ar_ym_loadpatchlfn
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_playdrum .channel, .note {
    lda #(.channel)
    ldx #(.note)
    jsr ar_ym_playdrum
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_playnote .channel, .kc, .kf {
    lda #(.channel)
    ldx #(.kc)
    ldy #(.kf)
    clc
    jsr ar_ym_playnote
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_setatten .channel, .atten {
    lda #(.channel)
    ldx #(.atten)
    jsr ar_ym_setatten
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_setdrum .channel, .note {
    lda #(.channel)
    ldx #(.note)
    jsr ar_ym_setdrum
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_setnote .channel, .kc, .kf {
    lda #(.channel)
    ldx #(.kc)
    ldy #(.kf)
    jsr ar_ym_setnote
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_setpan .channel, .pan {
    lda #(.channel)
    ldx #(.pan)
    jsr ar_ym_setpan
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_read_raw .reg {
    ldx #(.reg)
    clc
    jsr ar_ym_read
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_read_cooked .reg {
    ldx #(.reg)
    sec
    jsr ar_ym_read
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_release .channel {
    lda #(.channel)
    jsr ar_ym_release
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_trigger .channel {
    lda #(.channel)
    clc
    jsr ar_ym_trigger
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_trigger_no_retrigger .channel {
    lda #(.channel)
    sec
    jsr ar_ym_trigger
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_write .reg, .value {
    lda #(.value)
    ldx #(.reg)
    jsr ar_ym_write
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_getatten .channel {
    lda #(.channel)
    jsr ar_ym_getatten
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_getpan .channel {
    lda #(.channel)
    jsr ar_ym_getpan
}
}
!ifdef X16_USE_AUDIO_ROM {
!macro xm_ar_ym_get_chip_type {
    jsr ar_ym_get_chip_type
}
}

; =====================================================================
; audio/zsm  (compact ZSM stream player)
; =====================================================================
!ifdef X16_USE_ZSM {
!macro xm_zsm_init .header {
    lda #<(.header)
    sta r0L
    lda #>(.header)
    sta r0H
    jsr zsm_init
}
}
!ifdef X16_USE_ZSM {
!macro xm_zsm_init_stream .stream, .loop {
    lda #<(.stream)
    sta r0L
    lda #>(.stream)
    sta r0H
    lda #<(.loop)
    sta r1L
    lda #>(.loop)
    sta r1H
    jsr zsm_init_stream
}
}
!ifdef X16_USE_ZSM {
!macro xm_zsm_play {
    jsr zsm_play
}
}
!ifdef X16_USE_ZSM {
!macro xm_zsm_stop {
    jsr zsm_stop
}
}
!ifdef X16_USE_ZSM {
!macro xm_zsm_rewind {
    jsr zsm_rewind
}
}
; -> A = low byte, X = high byte
!ifdef X16_USE_ZSM {
!macro xm_zsm_get_tickrate {
    jsr zsm_get_tickrate
}
}
; -> A = ZSM_FLAG_* bits, carry set if active
!ifdef X16_USE_ZSM {
!macro xm_zsm_status {
    jsr zsm_status
}
}
; -> A = ZSM_FLAG_* bits, carry set if active
!ifdef X16_USE_ZSM {
!macro xm_zsm_tick {
    jsr zsm_tick
}
}
; -> carry set if a supported PCM table is present
!ifdef X16_USE_ZSM_PCM {
!macro xm_zsm_pcm_present {
    jsr zsm_pcm_present
}
}
!ifdef X16_USE_ZSM_PCM {
!macro xm_zsm_pcm_trigger .instrument {
    lda #(.instrument)
    jsr zsm_pcm_trigger
}
}

; =====================================================================
; audio/pcm
; =====================================================================
!ifdef X16_USE_PCM {
!macro xm_pcm_ctrl .byte {
    lda #(.byte)
    jsr pcm_ctrl
}
}
!ifdef X16_USE_PCM {
!macro xm_pcm_rate .rate {
    lda #(.rate)
    jsr pcm_rate
}
}
!ifdef X16_USE_PCM {
!macro xm_pcm_reset {
    jsr pcm_reset
}
}
!ifdef X16_USE_PCM {
!macro xm_pcm_put .sample {
    lda #(.sample)
    jsr pcm_put
}
}
!ifdef X16_USE_PCM {
!macro xm_pcm_write .src, .count {
    lda #<(.src)
    sta X16_P0
    lda #>(.src)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    jsr pcm_write
}
}
!ifdef X16_USE_PCM_STREAM {
!macro xm_pcm_stream_start .src, .count, .loop {
    lda #<(.src)
    sta X16_P0
    lda #>(.src)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    lda #(.loop)
    sta X16_P4
    jsr pcm_stream_start
}
}
!ifdef X16_USE_PCM_STREAM {
!macro xm_pcm_stream_stop {
    jsr pcm_stream_stop
}
}

; =====================================================================
; audio/adpcm
; =====================================================================
!ifdef X16_USE_ADPCM {
!macro xm_adpcm_init {
    jsr adpcm_init
}
}
!ifdef X16_USE_ADPCM {
!macro xm_adpcm_nibble .code {
    lda #(.code)
    jsr adpcm_nibble
}
}
!ifdef X16_USE_ADPCM {
!macro xm_adpcm_block .src, .dst, .count {
    lda #<(.src)
    sta X16_P0
    lda #>(.src)
    sta X16_P1
    lda #<(.dst)
    sta X16_P2
    lda #>(.dst)
    sta X16_P3
    lda #<(.count)
    sta X16_P4
    lda #>(.count)
    sta X16_P5
    jsr adpcm_block
}
}

; =====================================================================
; input/mouse
; =====================================================================
!ifdef X16_USE_MOUSE {
!macro xm_mse_config .cursor, .width8, .height8 {
    lda #(.cursor)
    ldx #(.width8)
    ldy #(.height8)
    jsr mse_config
}
}
!ifdef X16_USE_MOUSE {
!macro xm_mse_scan {
    jsr mse_scan
}
}
; -> P0/1 = x, P2/3 = y, A = buttons, X = wheel delta
!ifdef X16_USE_MOUSE {
!macro xm_mse_get {
    jsr mse_get
}
}
; -> .zp/.zp+1 = x, .zp+2/.zp+3 = y, A = buttons, X = wheel delta
!ifdef X16_USE_MOUSE {
!macro xm_mse_get_to .zp {
    ldx #(.zp)
    jsr mse_get_to
}
}
!ifdef X16_USE_MOUSE {
!macro xm_mse_show .cursor {
    lda #(.cursor)
    jsr mse_show
}
}
!ifdef X16_USE_MOUSE {
!macro xm_mse_show_keep {
    jsr mse_show_keep
}
}
!ifdef X16_USE_MOUSE {
!macro xm_mse_hide {
    jsr mse_hide
}
}

; =====================================================================
; input/keyboard
; =====================================================================
!ifdef X16_USE_KEYBOARD {
!macro xm_kbd_scan {
    jsr kbd_scan
}
}
; -> A = next PETSCII key, X = queued key count, Z set when empty
!ifdef X16_USE_KEYBOARD {
!macro xm_kbd_peek {
    jsr kbd_peek
}
}
!ifdef X16_USE_KEYBOARD {
!macro xm_kbd_put .key {
    lda #(.key)
    jsr kbd_put
}
}
; -> A = KBD_MOD_* bitfield
!ifdef X16_USE_KEYBOARD {
!macro xm_kbd_get_modifiers {
    jsr kbd_get_modifiers
}
}
; -> A = layout index, X/Y = current NUL-terminated layout string
!ifdef X16_USE_KEYBOARD {
!macro xm_kbd_get_keymap {
    jsr kbd_get_keymap
}
}
; -> carry clear on success, carry set on unknown layout
!ifdef X16_USE_KEYBOARD {
!macro xm_kbd_set_keymap .name {
    ldx #<(.name)
    ldy #>(.name)
    jsr kbd_set_keymap
}
}

; =====================================================================
; input/input
; =====================================================================
!ifdef X16_USE_INPUT {
!macro xm_joy_scan {
    jsr joy_scan
}
}
; -> A/X/Y = button bytes
!ifdef X16_USE_INPUT {
!macro xm_joy_get .pad {
    lda #(.pad)
    jsr joy_get
}
}
!ifdef X16_USE_INPUT {
!macro xm_mouse_show .cursor {
    lda #(.cursor)
    jsr mouse_show
}
}
!ifdef X16_USE_INPUT {
!macro xm_mouse_hide {
    jsr mouse_hide
}
}
; -> P0/1 = x, P2/3 = y, A = buttons
!ifdef X16_USE_INPUT {
!macro xm_mouse_get {
    jsr mouse_get
}
}
; -> A = PETSCII, 0 if none waiting
!ifdef X16_USE_INPUT {
!macro xm_key_get {
    jsr key_get
}
}
; -> A = PETSCII (blocks)
!ifdef X16_USE_INPUT {
!macro xm_key_wait {
    jsr key_wait
}
}
; -> A = next key without consuming it
!ifdef X16_USE_INPUT {
!macro xm_key_peek {
    jsr key_peek
}
}

; =====================================================================
; storage/bank  (banked RAM)
; =====================================================================
!ifdef X16_USE_BANK {
!macro xm_bank_set .bank {
    lda #(.bank)
    jsr bank_set
}
}
; -> A = byte
!ifdef X16_USE_BANK {
!macro xm_bank_peek .bank, .offset {
    lda #<(.offset)
    sta X16_P0
    lda #>(.offset)
    sta X16_P1
    lda #(.bank)
    jsr bank_peek
}
}
!ifdef X16_USE_BANK {
!macro xm_bank_poke .bank, .offset, .byte {
    lda #<(.offset)
    sta X16_P0
    lda #>(.offset)
    sta X16_P1
    lda #(.byte)
    ldx #(.bank)
    jsr bank_poke
}
}
!ifdef X16_USE_BANK {
!macro xm_mem_to_bank .src, .bank, .offset, .count {
    lda #<(.src)
    sta X16_P0
    lda #>(.src)
    sta X16_P1
    lda #(.bank)
    sta X16_P2
    lda #<(.offset)
    sta X16_P3
    lda #>(.offset)
    sta X16_P4
    lda #<(.count)
    sta X16_P5
    lda #>(.count)
    sta X16_P6
    jsr mem_to_bank
}
}

; =====================================================================
; storage/bankalloc
; =====================================================================
!ifdef X16_USE_BANKALLOC {
!macro xm_bank_alloc_init .first, .last {
    lda #(.first)
    ldx #(.last)
    jsr bank_alloc_init
}
}
; -> carry clear, A = the bank number
!ifdef X16_USE_BANKALLOC {
!macro xm_bank_alloc {
    jsr bank_alloc
}
}
!ifdef X16_USE_BANKALLOC {
!macro xm_bank_free .bank {
    lda #(.bank)
    jsr bank_free
}
}
!ifdef X16_USE_BANKALLOC {
!macro xm_bank_reserve .bank {
    lda #(.bank)
    jsr bank_reserve
}
}

; =====================================================================
; storage/mem  (KERNAL block ops; stream to/from VERA_DATA0 too)
; =====================================================================
!ifdef X16_USE_MEM {
!macro xm_mem_fill .dst, .count, .val {
    lda #<(.dst)
    sta X16_P0
    lda #>(.dst)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    lda #(.val)
    jsr mem_fill
}
}
!ifdef X16_USE_MEM {
!macro xm_mem_copy .src, .dst, .count {
    lda #<(.src)
    sta X16_P0
    lda #>(.src)
    sta X16_P1
    lda #<(.dst)
    sta X16_P2
    lda #>(.dst)
    sta X16_P3
    lda #<(.count)
    sta X16_P4
    lda #>(.count)
    sta X16_P5
    jsr mem_copy
}
}
; -> A = CRC low, X = CRC high
!ifdef X16_USE_MEM {
!macro xm_mem_crc .addr, .count {
    lda #<(.addr)
    sta X16_P0
    lda #>(.addr)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    jsr mem_crc
}
}
; -> A/X = one past the last output byte
!ifdef X16_USE_MEM {
!macro xm_mem_decompress .src, .dst {
    lda #<(.src)
    sta X16_P0
    lda #>(.src)
    sta X16_P1
    lda #<(.dst)
    sta X16_P2
    lda #>(.dst)
    sta X16_P3
    jsr mem_decompress
}
}

; =====================================================================
; storage/iec
; =====================================================================
!ifdef X16_USE_IEC {
!macro xm_iec_listen .device {
    lda #(.device)
    jsr iec_listen
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_talk .device {
    lda #(.device)
    jsr iec_talk
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_second .command {
    lda #(.command)
    jsr iec_second
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_tksa .command {
    lda #(.command)
    jsr iec_tksa
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_ciout .byte {
    lda #(.byte)
    jsr iec_ciout
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_acptr {
    jsr iec_acptr
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_unlisten {
    jsr iec_unlisten
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_untalk {
    jsr iec_untalk
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_set_timeout .control {
    lda #(.control)
    jsr iec_set_timeout
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_readst {
    jsr iec_readst
}
}
; -> X/Y = bytes read, carry set when unsupported/error
!ifdef X16_USE_IEC {
!macro xm_iec_macptr .dest, .count {
    lda #(.count)
    ldx #<(.dest)
    ldy #>(.dest)
    jsr iec_macptr
}
}
; -> X/Y = bytes written, carry set when unsupported/error
!ifdef X16_USE_IEC {
!macro xm_iec_mciout .src, .count {
    lda #(.count)
    ldx #<(.src)
    ldy #>(.src)
    jsr iec_mciout
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_open_channel .device, .secondary {
    lda #(.device)
    ldy #(.secondary)
    jsr iec_open_channel
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_data_channel .device, .secondary {
    lda #(.device)
    ldy #(.secondary)
    jsr iec_data_channel
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_talk_channel .device, .secondary {
    lda #(.device)
    ldy #(.secondary)
    jsr iec_talk_channel
}
}
!ifdef X16_USE_IEC {
!macro xm_iec_close_channel .device, .secondary {
    lda #(.device)
    ldy #(.secondary)
    jsr iec_close_channel
}
}

; =====================================================================
; storage/fileio
; =====================================================================
!ifdef X16_USE_FILEIO {
!macro xm_fio_set_lfs .logical, .device, .secondary {
    lda #(.logical)
    ldx #(.device)
    ldy #(.secondary)
    jsr fio_set_lfs
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_set_name .name, .len {
    lda #(.len)
    ldx #<(.name)
    ldy #>(.name)
    jsr fio_set_name
}
}
; -> carry set = KERNAL open error
!ifdef X16_USE_FILEIO {
!macro xm_fio_open_named .name, .len, .logical, .device, .secondary {
    lda #<(.name)
    sta X16_P0
    lda #>(.name)
    sta X16_P1
    lda #(.len)
    sta X16_P2
    lda #(.logical)
    sta X16_P3
    lda #(.device)
    sta X16_P4
    lda #(.secondary)
    sta X16_P5
    jsr fio_open_named
}
}
; -> carry set = OPEN or CHKIN error
!ifdef X16_USE_FILEIO {
!macro xm_fio_open_read .name, .len, .logical, .device, .secondary {
    lda #<(.name)
    sta X16_P0
    lda #>(.name)
    sta X16_P1
    lda #(.len)
    sta X16_P2
    lda #(.logical)
    sta X16_P3
    lda #(.device)
    sta X16_P4
    lda #(.secondary)
    sta X16_P5
    jsr fio_open_read
}
}
; -> carry set = OPEN or CHKOUT error
!ifdef X16_USE_FILEIO {
!macro xm_fio_open_write .name, .len, .logical, .device, .secondary {
    lda #<(.name)
    sta X16_P0
    lda #>(.name)
    sta X16_P1
    lda #(.len)
    sta X16_P2
    lda #(.logical)
    sta X16_P3
    lda #(.device)
    sta X16_P4
    lda #(.secondary)
    sta X16_P5
    jsr fio_open_write
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_close .logical {
    lda #(.logical)
    jsr fio_close
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_close_named .logical {
    lda #(.logical)
    sta X16_P3
    jsr fio_close_named
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_chkin .logical {
    ldx #(.logical)
    jsr fio_chkin
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_chkout .logical {
    ldx #(.logical)
    jsr fio_chkout
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_clrchn {
    jsr fio_clrchn
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_chrin {
    jsr fio_chrin
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_chrout .byte {
    lda #(.byte)
    jsr fio_chrout
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_readst {
    jsr fio_readst
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_getin {
    jsr fio_getin
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_close_all {
    jsr fio_close_all
}
}
!ifdef X16_USE_FILEIO {
!macro xm_fio_close_device .device {
    lda #(.device)
    jsr fio_close_device
}
}

; =====================================================================
; storage/load
; =====================================================================
!ifdef X16_USE_LOAD {
!macro xm_fs_setname .name, .len {
    lda #<(.name)
    sta X16_P0
    lda #>(.name)
    sta X16_P1
    lda #(.len)
    jsr fs_setname
}
}
; -> carry set = error, A = KERNAL error code
!ifdef X16_USE_LOAD {
!macro xm_fs_load .name, .len, .device, .sa, .dst {
    lda #<(.name)
    sta X16_P0
    lda #>(.name)
    sta X16_P1
    lda #(.len)
    sta X16_P2
    lda #(.device)
    sta X16_P3
    lda #(.sa)
    sta X16_P4
    lda #<(.dst)
    sta X16_P5
    lda #>(.dst)
    sta X16_P6
    jsr fs_load
}
}
!ifdef X16_USE_LOAD {
!macro xm_fs_vload .name, .len, .device, .vbank, .vaddr {
    lda #<(.name)
    sta X16_P0
    lda #>(.name)
    sta X16_P1
    lda #(.len)
    sta X16_P2
    lda #(.device)
    sta X16_P3
    lda #(.vbank)
    sta X16_P4
    lda #<(.vaddr)
    sta X16_P5
    lda #>(.vaddr)
    sta X16_P6
    jsr fs_vload
}
}

; =====================================================================
; storage/dos
; =====================================================================
; -> A = status code
!ifdef X16_USE_DOS {
!macro xm_dos_cmd .cmd, .len {
    lda #<(.cmd)
    ldx #>(.cmd)
    ldy #(.len)
    jsr dos_cmd
}
}
!ifdef X16_USE_DOS {
!macro xm_dos_status {
    jsr dos_status
}
}
!ifdef X16_USE_DOS {
!macro xm_dos_delete .name, .len {
    lda #<(.name)
    ldx #>(.name)
    ldy #(.len)
    jsr dos_delete
}
}

; =====================================================================
; storage/bmx
; =====================================================================
!ifdef X16_USE_BMX {
!macro xm_bmx_load .name, .len, .device, .vbank, .vaddr {
    lda #<(.name)
    sta X16_P0
    lda #>(.name)
    sta X16_P1
    lda #(.len)
    sta X16_P2
    lda #(.device)
    sta X16_P3
    lda #(.vbank)
    sta X16_P4
    lda #<(.vaddr)
    sta X16_P5
    lda #>(.vaddr)
    sta X16_P6
    jsr bmx_load
}
}
!ifdef X16_USE_BMX {
!macro xm_bmx_load_hires .name, .len, .device {
    lda #<(.name)
    sta X16_P0
    lda #>(.name)
    sta X16_P1
    lda #(.len)
    sta X16_P2
    lda #(.device)
    sta X16_P3
    jsr bmx_load_hires
}
}

; =====================================================================
; util/math
; =====================================================================
!ifdef X16_USE_MATH {
!macro xm_rnd_seed .seed {
    lda #<(.seed)
    ldx #>(.seed)
    jsr rnd_seed
}
}
; -> A = -127..127
!ifdef X16_USE_MATH {
!macro xm_sin8 .angle {
    lda #(.angle)
    jsr sin8
}
}
!ifdef X16_USE_MATH {
!macro xm_cos8 .angle {
    lda #(.angle)
    jsr cos8
}
}
; -> A = 1..255
!ifdef X16_USE_MATH {
!macro xm_sin8u .angle {
    lda #(.angle)
    jsr sin8u
}
}
!ifdef X16_USE_MATH {
!macro xm_cos8u .angle {
    lda #(.angle)
    jsr cos8u
}
}
; -> A = angle 0-255
!ifdef X16_USE_MATH {
!macro xm_atan2 .dx, .dy {
    lda #(.dx)
    ldx #(.dy)
    jsr atan2
}
}
; -> A = interpolated value
!ifdef X16_USE_MATH {
!macro xm_lerp8 .a, .b, .t {
    lda #(.a)
    sta X16_P0
    lda #(.b)
    sta X16_P1
    lda #(.t)
    jsr lerp8
}
}

; =====================================================================
; util/collide
; =====================================================================
; -> carry set if the two boxes overlap (8-bit coordinates and sizes)
!ifdef X16_USE_COLLIDE {
!macro xm_collide8 .ax, .ay, .aw, .ah, .bx, .by, .bw, .bh {
    lda #(.ax)
    sta X16_P0
    lda #(.ay)
    sta X16_P1
    lda #(.aw)
    sta X16_P2
    lda #(.ah)
    sta X16_P3
    lda #(.bx)
    sta X16_P4
    lda #(.by)
    sta X16_P5
    lda #(.bw)
    sta X16_P6
    lda #(.bh)
    sta X16_P7
    jsr collide8
}
}
; -> carry set if the two boxes overlap (16-bit; writes cl_* directly)
!ifdef X16_USE_COLLIDE {
!macro xm_collide16 .ax, .ay, .aw, .ah, .bx, .by, .bw, .bh {
    lda #<(.ax)
    sta cl_ax
    lda #>(.ax)
    sta cl_ax+1
    lda #<(.ay)
    sta cl_ay
    lda #>(.ay)
    sta cl_ay+1
    lda #<(.aw)
    sta cl_aw
    lda #>(.aw)
    sta cl_aw+1
    lda #<(.ah)
    sta cl_ah
    lda #>(.ah)
    sta cl_ah+1
    lda #<(.bx)
    sta cl_bx
    lda #>(.bx)
    sta cl_bx+1
    lda #<(.by)
    sta cl_by
    lda #>(.by)
    sta cl_by+1
    lda #<(.bw)
    sta cl_bw
    lda #>(.bw)
    sta cl_bw+1
    lda #<(.bh)
    sta cl_bh
    lda #>(.bh)
    sta cl_bh+1
    jsr collide16
}
}

; =====================================================================
; util/bits
; =====================================================================
!ifdef X16_USE_BITS {
!macro xm_catnib .hi, .lo {
    lda #(.hi)
    ldx #(.lo)
    jsr catnib
}
}
!ifdef X16_USE_BITS {
!macro xm_hinib .byte {
    lda #(.byte)
    jsr hinib
}
}
!ifdef X16_USE_BITS {
!macro xm_lonib .byte {
    lda #(.byte)
    jsr lonib
}
}
!ifdef X16_USE_BITS {
!macro xm_bit_set .addr, .mask {
    lda #<(.addr)
    sta X16_PTR0
    lda #>(.addr)
    sta X16_PTR0+1
    lda #(.mask)
    jsr bit_set
}
}
!ifdef X16_USE_BITS {
!macro xm_bit_clr .addr, .mask {
    lda #<(.addr)
    sta X16_PTR0
    lda #>(.addr)
    sta X16_PTR0+1
    lda #(.mask)
    jsr bit_clr
}
}
; -> Z clear if any masked bit was set
!ifdef X16_USE_BITS {
!macro xm_bit_test .addr, .mask {
    lda #<(.addr)
    sta X16_PTR0
    lda #>(.addr)
    sta X16_PTR0+1
    lda #(.mask)
    jsr bit_test
}
}

; =====================================================================
; util/number
; =====================================================================
; -> A/X = buffer, Y = length
!ifdef X16_USE_NUMBER {
!macro xm_u16_to_dec .value {
    lda #<(.value)
    sta X16_P0
    lda #>(.value)
    sta X16_P1
    jsr u16_to_dec
}
}
; -> A/X = buffer, Y = 4
!ifdef X16_USE_NUMBER {
!macro xm_u16_to_hex .value {
    lda #<(.value)
    sta X16_P0
    lda #>(.value)
    sta X16_P1
    jsr u16_to_hex
}
}
; -> P4/5 = value, carry set on a bad digit
!ifdef X16_USE_NUMBER {
!macro xm_dec_to_u16 .str, .len {
    lda #<(.str)
    sta X16_P0
    lda #>(.str)
    sta X16_P1
    lda #(.len)
    sta X16_P2
    jsr dec_to_u16
}
}
; -> A/X = buffer, Y = length
!ifdef X16_USE_NUMBER {
!macro xm_u8_to_dec .value {
    lda #(.value)
    jsr u8_to_dec
}
}
; -> A/X = buffer, Y = 2
!ifdef X16_USE_NUMBER {
!macro xm_u8_to_hex .value {
    lda #(.value)
    jsr u8_to_hex
}
}
; -> A/X = buffer, Y = 8
!ifdef X16_USE_NUMBER {
!macro xm_u8_to_bin .value {
    lda #(.value)
    jsr u8_to_bin
}
}
; -> A/X = buffer, Y = 16
!ifdef X16_USE_NUMBER {
!macro xm_u16_to_bin .value {
    lda #<(.value)
    sta X16_P0
    lda #>(.value)
    sta X16_P1
    jsr u16_to_bin
}
}
; -> A/X = buffer, Y = length
!ifdef X16_USE_NUMBER {
!macro xm_s8_to_dec .value {
    lda #(.value)
    jsr s8_to_dec
}
}
; -> A/X = buffer, Y = length
!ifdef X16_USE_NUMBER {
!macro xm_s16_to_dec .value {
    lda #<(.value)
    sta X16_P0
    lda #>(.value)
    sta X16_P1
    jsr s16_to_dec
}
}

; =====================================================================
; util/sort  (base pointer + element count; sorts in place)
; =====================================================================
!ifdef X16_USE_SORT {
!macro xm_sort_u8 .ptr, .count {
    lda #<(.ptr)
    sta X16_P0
    lda #>(.ptr)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    jsr sort_u8
}
}
!ifdef X16_USE_SORT {
!macro xm_sort_s8 .ptr, .count {
    lda #<(.ptr)
    sta X16_P0
    lda #>(.ptr)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    jsr sort_s8
}
}
!ifdef X16_USE_SORT {
!macro xm_sort_u16 .ptr, .count {
    lda #<(.ptr)
    sta X16_P0
    lda #>(.ptr)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    jsr sort_u16
}
}
!ifdef X16_USE_SORT {
!macro xm_sort_s16 .ptr, .count {
    lda #<(.ptr)
    sta X16_P0
    lda #>(.ptr)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    jsr sort_s16
}
}
!ifdef X16_USE_SORT {
!macro xm_sort_ptr .ptr, .count, .cmp {
    lda #<(.ptr)
    sta X16_P0
    lda #>(.ptr)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    lda #<(.cmp)
    sta X16_P4
    lda #>(.cmp)
    sta X16_P5
    jsr sort_ptr
}
}

; =====================================================================
; string/strsort
; =====================================================================
!ifdef X16_USE_STRING_SORT {
!macro xm_str_sort .ptr, .count {
    lda #<(.ptr)
    sta X16_P0
    lda #>(.ptr)
    sta X16_P1
    lda #<(.count)
    sta X16_P2
    lda #>(.count)
    sta X16_P3
    jsr str_sort
}
}

; =====================================================================
; audio/wavfile
; =====================================================================
; -> carry set on failure; wav_format/channels/rate/bits/data_off/data_len set
!ifdef X16_USE_WAV {
!macro xm_wav_parse_header .buf {
    lda #<(.buf)
    sta X16_P0
    lda #>(.buf)
    sta X16_P1
    jsr wav_parse_header
}
}

; =====================================================================
; util/fixed
; =====================================================================
; -> P4..P7 = product
!ifdef X16_USE_FIXED {
!macro xm_umul16 .a, .b {
    lda #<(.a)
    sta X16_P0
    lda #>(.a)
    sta X16_P1
    lda #<(.b)
    sta X16_P2
    lda #>(.b)
    sta X16_P3
    jsr umul16
}
}
; signed 8.8; -> P0/1 = result
!ifdef X16_USE_FIXED {
!macro xm_mul88 .a, .b {
    lda #<(.a)
    sta X16_P0
    lda #>(.a)
    sta X16_P1
    lda #<(.b)
    sta X16_P2
    lda #>(.b)
    sta X16_P3
    jsr mul88
}
}

; =====================================================================
; util/int16  (load i16_a / i16_b with +i16_const; ops are argument-free)
; =====================================================================
!ifdef X16_USE_INT16 {
!macro xm_i16_from_u8 .byte {
    lda #(.byte)
    jsr i16_from_u8
}
}
!ifdef X16_USE_INT16 {
!macro xm_i16_from_s8 .byte {
    lda #(.byte)
    jsr i16_from_s8
}
}

; =====================================================================
; util/int32  (load i32_a / i32_b with +i32_const)
; =====================================================================
!ifdef X16_USE_INT32 {
!macro xm_i32_from_u16 .value {
    lda #<(.value)
    ldx #>(.value)
    jsr i32_from_u16
}
}
!ifdef X16_USE_INT32 {
!macro xm_i32_from_s16 .value {
    lda #<(.value)
    ldx #>(.value)
    jsr i32_from_s16
}
}

; =====================================================================
; util/float  (FAC is the accumulator; addr = a 5-byte float in memory)
; =====================================================================
!ifdef X16_USE_FLOAT {
!macro xm_f_from_u8 .byte {
    lda #(.byte)
    jsr f_from_u8
}
}
!ifdef X16_USE_FLOAT {
!macro xm_f_from_s16 .value {
    lda #<(.value)
    ldx #>(.value)
    jsr f_from_s16
}
}
!ifdef X16_USE_FLOAT {
!macro xm_f_load .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_load
}
}
!ifdef X16_USE_FLOAT {
!macro xm_f_store .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_store
}
}
!ifdef X16_USE_FLOAT {
!macro xm_f_add .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_add
}
}
!ifdef X16_USE_FLOAT {
!macro xm_f_sub .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_sub
}
}
!ifdef X16_USE_FLOAT {
!macro xm_f_mul .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_mul
}
}
!ifdef X16_USE_FLOAT {
!macro xm_f_div .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_div
}
}
!ifdef X16_USE_FLOAT {
!macro xm_f_cmp .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_cmp
}
}
; FAC = mem - FAC
!ifdef X16_USE_FLOAT {
!macro xm_f_rsub .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_rsub
}
}
; FAC = mem / FAC
!ifdef X16_USE_FLOAT {
!macro xm_f_rdiv .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_rdiv
}
}
; FAC = FAC ^ mem
!ifdef X16_USE_FLOAT {
!macro xm_f_pow .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_pow
}
}
; FAC = the value parsed from a string of `len` chars
!ifdef X16_USE_FLOAT {
!macro xm_f_from_str .str, .len {
    lda #<(.str)
    ldy #>(.str)
    ldx #(.len)
    jsr f_from_str
}
}

; =====================================================================
; util/double  (d_ac is the accumulator; addr = an 8-byte double in memory)
; =====================================================================
!ifdef X16_USE_DOUBLE {
!macro xm_d_load .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr d_load
}
}
!ifdef X16_USE_DOUBLE {
!macro xm_d_store .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr d_store
}
}
!ifdef X16_USE_DOUBLE {
!macro xm_d_add .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr d_add
}
}
!ifdef X16_USE_DOUBLE {
!macro xm_d_sub .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr d_sub
}
}
!ifdef X16_USE_DOUBLE {
!macro xm_d_mul .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr d_mul
}
}
!ifdef X16_USE_DOUBLE {
!macro xm_d_div .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr d_div
}
}
!ifdef X16_USE_DOUBLE {
!macro xm_d_cmp .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr d_cmp
}
}
; d_ac = d_ac ^ mem  (base ^ exponent)
!ifdef X16_USE_DOUBLE {
!macro xm_d_pow .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr d_pow
}
}
; d_ac = the value parsed from a string of `len` chars
!ifdef X16_USE_DOUBLE {
!macro xm_d_from_str .str, .len {
    lda #<(.str)
    ldy #>(.str)
    ldx #(.len)
    jsr d_from_str
}
}
!ifdef X16_USE_DOUBLE {
!macro xm_d_from_s16 .value {
    lda #<(.value)
    ldx #>(.value)
    jsr d_from_s16
}
}

; =====================================================================
; util/clip
; =====================================================================
!ifdef X16_USE_CLIP {
!macro xm_clip_set .xmin, .ymin, .xmax, .ymax {
    lda #<(.xmin)
    sta X16_P0
    lda #>(.xmin)
    sta X16_P1
    lda #<(.ymin)
    sta X16_P2
    lda #>(.ymin)
    sta X16_P3
    lda #<(.xmax)
    sta X16_P4
    lda #>(.xmax)
    sta X16_P5
    lda #<(.ymax)
    sta X16_P6
    lda #>(.ymax)
    sta X16_P7
    jsr clip_set
}
}

; =====================================================================
; util/buffers  (ring buffer + byte stack)
; =====================================================================
!ifdef X16_USE_BUFFERS {
!macro xm_rb_init {
    jsr rb_init
}
}
; -> carry set if the buffer was full
!ifdef X16_USE_BUFFERS {
!macro xm_rb_put .byte {
    lda #(.byte)
    jsr rb_put
}
}
; -> A = byte, carry set if empty
!ifdef X16_USE_BUFFERS {
!macro xm_rb_get {
    jsr rb_get
}
}
!ifdef X16_USE_BUFFERS {
!macro xm_rb_count {
    jsr rb_count
}
}
!ifdef X16_USE_BUFFERS {
!macro xm_stk_init {
    jsr stk_init
}
}
; -> carry set if the stack was full
!ifdef X16_USE_BUFFERS {
!macro xm_stk_push .byte {
    lda #(.byte)
    jsr stk_push
}
}
; -> A = byte, carry set if empty
!ifdef X16_USE_BUFFERS {
!macro xm_stk_pop {
    jsr stk_pop
}
}
!ifdef X16_USE_BUFFERS {
!macro xm_stk_depth {
    jsr stk_depth
}
}

; =====================================================================
; util/zx0 and util/tscrunch
; =====================================================================
; -> A/X = one past the last output byte
!ifdef X16_USE_ZX0 {
!macro xm_zx0_decompress .src, .dst {
    lda #<(.src)
    sta X16_P0
    lda #>(.src)
    sta X16_P1
    lda #<(.dst)
    sta X16_P2
    lda #>(.dst)
    sta X16_P3
    jsr zx0_decompress
}
}
!ifdef X16_USE_TSC {
!macro xm_tsc_decompress .src, .dst {
    lda #<(.src)
    sta X16_P0
    lda #>(.src)
    sta X16_P1
    lda #<(.dst)
    sta X16_P2
    lda #>(.dst)
    sta X16_P3
    jsr tsc_decompress
}
}

; =====================================================================
; system/clock
; =====================================================================
; -> A/X/Y = 24-bit 60 Hz timer, low to high
!ifdef X16_USE_CLOCK {
!macro xm_clock_get_timer {
    jsr clock_get_timer
}
}
!ifdef X16_USE_CLOCK {
!macro xm_clock_set_timer .ticks {
    lda #<(.ticks)
    ldx #>((.ticks) >> 8)
    ldy #>((.ticks) >> 16)
    jsr clock_set_timer
}
}
!ifdef X16_USE_CLOCK {
!macro xm_clock_update {
    jsr clock_update
}
}
; -> r0..r3 = year/month/day/hour/min/sec/jiffy/weekday
!ifdef X16_USE_CLOCK {
!macro xm_clock_get_date_time {
    jsr clock_get_date_time
}
}
; .year1900 is the KERNAL byte value: full year minus 1900.
!ifdef X16_USE_CLOCK {
!macro xm_clock_set_date_time_raw .year1900, .month, .day, .hours, .minutes, .seconds, .jiffies, .weekday {
    lda #<(.year1900)
    sta r0L
    lda #<(.month)
    sta r0H
    lda #<(.day)
    sta r1L
    lda #<(.hours)
    sta r1H
    lda #<(.minutes)
    sta r2L
    lda #<(.seconds)
    sta r2H
    lda #<(.jiffies)
    sta r3L
    lda #<(.weekday)
    sta r3H
    jsr clock_set_date_time
}
}
; Friendly form: .year is the full year, e.g. 2026; jiffies are set to 0.
!ifdef X16_USE_CLOCK {
!macro xm_clock_set_date_time .year, .month, .day, .hours, .minutes, .seconds, .weekday {
    lda #<((.year) - 1900)
    sta r0L
    lda #<(.month)
    sta r0H
    lda #<(.day)
    sta r1L
    lda #<(.hours)
    sta r1H
    lda #<(.minutes)
    sta r2L
    lda #<(.seconds)
    sta r2H
    stz r3L
    lda #<(.weekday)
    sta r3H
    jsr clock_set_date_time
}
}

; =====================================================================
; comms/i2c
; =====================================================================
; -> A = value, carry set on NAK/error
!ifdef X16_USE_I2C {
!macro xm_i2c_read_byte .device, .offset {
    ldx #(.device)
    ldy #(.offset)
    jsr i2c_read_byte
}
}
; -> carry set on NAK/error
!ifdef X16_USE_I2C {
!macro xm_i2c_write_byte .value, .device, .offset {
    lda #(.value)
    ldx #(.device)
    ldy #(.offset)
    jsr i2c_write_byte
}
}
; -> carry set on NAK/error
!ifdef X16_USE_I2C {
!macro xm_i2c_batch_read .device, .buffer, .count {
    lda #<(.buffer)
    sta r0
    lda #>(.buffer)
    sta r0+1
    lda #<(.count)
    sta r1
    lda #>(.count)
    sta r1+1
    ldx #(.device)
    clc
    jsr i2c_batch_read
}
}
; -> carry set on NAK/error; reads repeatedly into the same address
!ifdef X16_USE_I2C {
!macro xm_i2c_batch_read_fixed .device, .buffer, .count {
    lda #<(.buffer)
    sta r0
    lda #>(.buffer)
    sta r0+1
    lda #<(.count)
    sta r1
    lda #>(.count)
    sta r1+1
    ldx #(.device)
    sec
    jsr i2c_batch_read
}
}
; -> r2 = bytes written, carry set on NAK/error
!ifdef X16_USE_I2C {
!macro xm_i2c_batch_write .device, .buffer, .count {
    lda #<(.buffer)
    sta r0
    lda #>(.buffer)
    sta r0+1
    lda #<(.count)
    sta r1
    lda #>(.count)
    sta r1+1
    ldx #(.device)
    jsr i2c_batch_write
}
}

; =====================================================================
; comms/spi  (VERA SPI controller)
; =====================================================================
; -> A = VERA_SPI_* control/status bits
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_get_ctrl {
    jsr spi_get_ctrl
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_set_ctrl .ctrl {
    lda #(.ctrl)
    jsr spi_set_ctrl
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_select {
    jsr spi_select
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_deselect {
    jsr spi_deselect
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_slow {
    jsr spi_slow
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_fast {
    jsr spi_fast
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_autotx_on {
    jsr spi_autotx_on
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_autotx_off {
    jsr spi_autotx_off
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_wait {
    jsr spi_wait
}
}
; -> A = received byte
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_transfer .byte {
    lda #(.byte)
    jsr spi_transfer
}
}
; -> A = received byte
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_read {
    jsr spi_read
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_write .byte {
    lda #(.byte)
    jsr spi_write
}
}
; -> A = received byte; starts the next Auto-TX transfer
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_autotx_read {
    jsr spi_autotx_read
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_read_bytes .buffer, .count {
    lda #<(.buffer)
    sta r0L
    lda #>(.buffer)
    sta r0H
    lda #<(.count)
    sta r1L
    lda #>(.count)
    sta r1H
    jsr spi_read_bytes
}
}
!ifdef X16_USE_VERA_SPI {
!macro xm_spi_write_bytes .buffer, .count {
    lda #<(.buffer)
    sta r0L
    lda #>(.buffer)
    sta r0H
    lda #<(.count)
    sta r1L
    lda #>(.count)
    sta r1H
    jsr spi_write_bytes
}
}

; =====================================================================
; comms/serial
; =====================================================================
; -> A = count (0-2), carry clear if any found, ser_u0/ser_u1 = bases
!ifdef X16_USE_SERIAL {
!macro xm_ser_detect {
    jsr ser_detect
}
}
!ifdef X16_USE_SERIAL {
!macro xm_ser_init .base, .divisor {
    lda #<(.divisor)
    sta X16_P0
    lda #>(.divisor)
    sta X16_P1
    lda #<(.base)
    ldx #>(.base)
    jsr ser_init
}
}
; -> carry set if a received byte is waiting
!ifdef X16_USE_SERIAL {
!macro xm_ser_avail {
    jsr ser_avail
}
}
; -> carry clear + A = byte, or carry set if the RX FIFO was empty
!ifdef X16_USE_SERIAL {
!macro xm_ser_get {
    jsr ser_get
}
}
; -> A = byte (blocks until one arrives)
!ifdef X16_USE_SERIAL {
!macro xm_ser_get_wait {
    jsr ser_get_wait
}
}
!ifdef X16_USE_SERIAL {
!macro xm_ser_put .byte {
    lda #(.byte)
    jsr ser_put
}
}
!ifdef X16_USE_SERIAL {
!macro xm_ser_puts .addr {
    lda #<(.addr)
    ldx #>(.addr)
    jsr ser_puts
}
}
!ifdef X16_USE_SERIAL {
!macro xm_ser_write .addr, .len {
    ldy #(.len)
    lda #<(.addr)
    ldx #>(.addr)
    jsr ser_write
}
}
; -> X16_P4/P5 = bytes stored
!ifdef X16_USE_SERIAL {
!macro xm_ser_read_until .match, .buffer, .max {
    lda #<(.buffer)
    sta X16_P0
    lda #>(.buffer)
    sta X16_P1
    lda #<(.max)
    sta X16_P2
    lda #>(.max)
    sta X16_P3
    lda #<(.match)
    ldx #>(.match)
    jsr ser_read_until
}
}
!ifdef X16_USE_SERIAL {
!macro xm_ser_discard_until .match {
    lda #<(.match)
    ldx #>(.match)
    jsr ser_discard_until
}
}

; =====================================================================
; comms/zimodem
; =====================================================================
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_init .base, .divisor {
    lda #<(.divisor)
    sta X16_P0
    lda #>(.divisor)
    sta X16_P1
    lda #<(.base)
    ldx #>(.base)
    jsr zi_init
}
}
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_cmd .addr {
    lda #<(.addr)
    ldx #>(.addr)
    jsr zi_cmd
}
}
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_wait_ok {
    jsr zi_wait_ok
}
}
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_reset {
    jsr zi_reset
}
}
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_get_ip .buffer {
    lda #<(.buffer)
    ldx #>(.buffer)
    jsr zi_get_ip
}
}
; -> carry clear if the transfer started, carry set if not found
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_hex_open .filename {
    lda #<(.filename)
    ldx #>(.filename)
    jsr zi_hex_open
}
}
; -> A = bytes decoded into the buffer, 0 when the file is done
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_hex_chunk .buffer {
    lda #<(.buffer)
    ldx #>(.buffer)
    jsr zi_hex_chunk
}
}
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_hex_close {
    jsr zi_hex_close
}
}
; -> A = bytes written (.digits / 2)
!ifdef X16_USE_SERIAL_ZIMODEM {
!macro xm_zi_hexdecode .src, .digits, .dest {
    lda #<(.dest)
    sta X16_P0
    lda #>(.dest)
    sta X16_P1
    ldy #(.digits)
    lda #<(.src)
    ldx #>(.src)
    jsr zi_hexdecode
}
}

; =====================================================================
; string/string
; =====================================================================
; -> Y = length
!ifdef X16_USE_STRING {
!macro xm_str_length .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_length
}
}
; -> Y = length copied
!ifdef X16_USE_STRING {
!macro xm_str_copy .src, .dst {
    lda #<(.dst)
    sta X16_P0
    lda #>(.dst)
    sta X16_P1
    lda #<(.src)
    ldx #>(.src)
    jsr str_copy
}
}
!ifdef X16_USE_STRING {
!macro xm_str_ncopy .src, .dst, .max {
    lda #<(.dst)
    sta X16_P0
    lda #>(.dst)
    sta X16_P1
    ldy #(.max)
    lda #<(.src)
    ldx #>(.src)
    jsr str_ncopy
}
}
; -> A = resulting length
!ifdef X16_USE_STRING {
!macro xm_str_append .tgt, .suffix {
    lda #<(.suffix)
    sta X16_P0
    lda #>(.suffix)
    sta X16_P1
    lda #<(.tgt)
    ldx #>(.tgt)
    jsr str_append
}
}
!ifdef X16_USE_STRING {
!macro xm_str_nappend .tgt, .suffix, .max {
    lda #<(.suffix)
    sta X16_P0
    lda #>(.suffix)
    sta X16_P1
    ldy #(.max)
    lda #<(.tgt)
    ldx #>(.tgt)
    jsr str_nappend
}
}
; -> A = -1 / 0 / 1
!ifdef X16_USE_STRING {
!macro xm_str_compare .s1, .s2 {
    lda #<(.s2)
    sta X16_P0
    lda #>(.s2)
    sta X16_P1
    lda #<(.s1)
    ldx #>(.s1)
    jsr str_compare
}
}
; -> A = hash
!ifdef X16_USE_STRING {
!macro xm_str_hash .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_hash
}
}

; =====================================================================
; string/case
; =====================================================================
!ifdef X16_USE_STRING_CASE {
!macro xm_str_lower .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_lower
}
}
!ifdef X16_USE_STRING_CASE {
!macro xm_str_lower_iso .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_lower_iso
}
}
!ifdef X16_USE_STRING_CASE {
!macro xm_str_upper .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_upper
}
}
!ifdef X16_USE_STRING_CASE {
!macro xm_str_upper_iso .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_upper_iso
}
}
; -> A = -1 / 0 / 1
!ifdef X16_USE_STRING_CASE {
!macro xm_str_compare_nocase .s1, .s2 {
    lda #<(.s2)
    sta X16_P0
    lda #>(.s2)
    sta X16_P1
    lda #<(.s1)
    ldx #>(.s1)
    jsr str_compare_nocase
}
}
!ifdef X16_USE_STRING_CASE {
!macro xm_str_compare_nocase_iso .s1, .s2 {
    lda #<(.s2)
    sta X16_P0
    lda #>(.s2)
    sta X16_P1
    lda #<(.s1)
    ldx #>(.s1)
    jsr str_compare_nocase_iso
}
}

; =====================================================================
; string/find
; =====================================================================
; -> carry set + A = index if found
!ifdef X16_USE_STRING_FIND {
!macro xm_str_find .str, .ch {
    ldy #(.ch)
    lda #<(.str)
    ldx #>(.str)
    jsr str_find
}
}
!ifdef X16_USE_STRING_FIND {
!macro xm_str_rfind .str, .ch {
    ldy #(.ch)
    lda #<(.str)
    ldx #>(.str)
    jsr str_rfind
}
}
!ifdef X16_USE_STRING_FIND {
!macro xm_str_find_eol .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_find_eol
}
}
; -> carry set if the character occurs
!ifdef X16_USE_STRING_FIND {
!macro xm_str_contains .str, .ch {
    ldy #(.ch)
    lda #<(.str)
    ldx #>(.str)
    jsr str_contains
}
}
; -> carry set (A = 1) if it matches
!ifdef X16_USE_STRING_FIND {
!macro xm_str_pattern_match .str, .pattern {
    lda #<(.pattern)
    sta X16_P0
    lda #>(.pattern)
    sta X16_P1
    lda #<(.str)
    ldx #>(.str)
    jsr str_pattern_match
}
}

; =====================================================================
; string/slice
; =====================================================================
!ifdef X16_USE_STRING_SLICE {
!macro xm_str_left .src, .dst, .len {
    lda #<(.dst)
    sta X16_P0
    lda #>(.dst)
    sta X16_P1
    ldy #(.len)
    lda #<(.src)
    ldx #>(.src)
    jsr str_left
}
}
!ifdef X16_USE_STRING_SLICE {
!macro xm_str_right .src, .dst, .len {
    lda #<(.dst)
    sta X16_P0
    lda #>(.dst)
    sta X16_P1
    ldy #(.len)
    lda #<(.src)
    ldx #>(.src)
    jsr str_right
}
}
!ifdef X16_USE_STRING_SLICE {
!macro xm_str_slice .src, .dst, .start, .len {
    lda #<(.dst)
    sta X16_P0
    lda #>(.dst)
    sta X16_P1
    lda #(.start)
    sta X16_P2
    ldy #(.len)
    lda #<(.src)
    ldx #>(.src)
    jsr str_slice
}
}
; -> Y = new length
!ifdef X16_USE_STRING_SLICE {
!macro xm_str_ltrim .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_ltrim
}
}
!ifdef X16_USE_STRING_SLICE {
!macro xm_str_rtrim .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_rtrim
}
}
!ifdef X16_USE_STRING_SLICE {
!macro xm_str_trim .str {
    lda #<(.str)
    ldx #>(.str)
    jsr str_trim
}
}
