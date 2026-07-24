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
; video/vdc  (VERA display composer)
; =====================================================================
; -> A = DC_VIDEO
    ifdef X16_USE_VERA_DC
    macro xm_vdc_get_video
    jsr vdc_get_video
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_set_video
    lda #(\1)
    jsr vdc_set_video
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_set_output
    lda #(\1)
    jsr vdc_set_output
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_set_layers
    lda #(\1)
    jsr vdc_set_layers
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_layer_on
    lda #(\1)
    jsr vdc_layer_on
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_layer_off
    lda #(\1)
    jsr vdc_layer_off
    endm
    endif
; -> A = HSCALE, X = VSCALE
    ifdef X16_USE_VERA_DC
    macro xm_vdc_get_scale
    jsr vdc_get_scale
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_set_scale
    lda #(\1)
    ldx #(\2)
    jsr vdc_set_scale
    endm
    endif
; -> A = border palette index
    ifdef X16_USE_VERA_DC
    macro xm_vdc_get_border
    jsr vdc_get_border
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_set_border
    lda #(\1)
    jsr vdc_set_border
    endm
    endif
; -> A = HSTART, X = HSTOP, Y = VSTART, r0L = VSTOP
    ifdef X16_USE_VERA_DC
    macro xm_vdc_get_active_raw
    jsr vdc_get_active_raw
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_set_active_raw
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    pha
    lda #(\4)
    sta r0L
    pla
    jsr vdc_set_active_raw
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_set_active
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
    jsr vdc_set_active
    endm
    endif
    ifdef X16_USE_VERA_DC
    macro xm_vdc_fullscreen
    jsr vdc_fullscreen
    endm
    endif
; -> carry set if valid, A = major, X = minor, Y = build
    ifdef X16_USE_VERA_DC
    macro xm_vdc_get_version
    jsr vdc_get_version
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
; gfx/bitmap8l  (320x240 @ 8bpp)
; =====================================================================
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_init
    jsr gfx8l_init
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_clear
    lda #(\1)
    jsr gfx8l_clear
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_pset
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\3)
    sta X16_P3
    jsr gfx8l_pset
    endm
    endif
; -> A = colour
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_read
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    jsr gfx8l_read
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_hline
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
    jsr gfx8l_hline
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_vline
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
    jsr gfx8l_vline
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_rect
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
    jsr gfx8l_rect
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_frame
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
    jsr gfx8l_frame
    endm
    endif
; A/X = the address of an 8x8 1bpp pattern
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_pattern_set
    lda #<(\1)
    ldx #>(\1)
    jsr gfx8l_pattern_set
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_pattern_rect
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
    jsr gfx8l_pattern_rect
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_line
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
    jsr gfx8l_line
    endm
    endif
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_char
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #(\3)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    lda #(\1)
    jsr gfx8l_char
    endm
    endif
; str = a NUL-terminated string
    ifdef X16_USE_BITMAP8L
    macro xm_gfx8l_text
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
    jsr gfx8l_text
    endm
    endif

; =====================================================================
; gfx/bitmap8h  (640x480 @ 8bpp; VERA_2 SDRAM layer)
; =====================================================================
    ifdef X16_USE_BITMAP8H
    macro xm_gfx8h_has
    jsr gfx8h_has
    endm
    macro xm_gfx8h_init
    jsr gfx8h_init
    endm
    macro xm_gfx8h_off
    jsr gfx8h_off
    endm
    macro xm_gfx8h_passthru_on
    jsr gfx8h_passthru_on
    endm
    macro xm_gfx8h_passthru_off
    jsr gfx8h_passthru_off
    endm
    macro xm_gfx8h_pal_set
    ldx #(\1)
    lda #(\2)
    ldy #(\3)
    jsr gfx8h_pal_set
    endm
    macro xm_gfx8h_pal_load
    lda #<(\1)
    sta X16_PTR0
    lda #>(\1)
    sta X16_PTR0+1
    lda #(\2)
    ldx #(\3)
    jsr gfx8h_pal_load
    endm
    macro xm_gfx8h_clear
    lda #(\1)
    jsr gfx8h_clear
    endm
    macro xm_gfx8h_pset
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    jsr gfx8h_pset
    endm
    macro xm_gfx8h_read
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr gfx8h_read
    endm
    macro xm_gfx8h_hline
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
    jsr gfx8h_hline
    endm
    macro xm_gfx8h_vline
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
    jsr gfx8h_vline
    endm
    macro xm_gfx8h_rect
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
    jsr gfx8h_rect
    endm
    macro xm_gfx8h_frame
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
    jsr gfx8h_frame
    endm
    macro xm_gfx8h_line
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
    jsr gfx8h_line
    endm
    macro xm_gfx8h_pattern_set
    lda #(\2)
    sta X16_P4
    lda #(\3)
    sta X16_P5
    lda #<(\1)
    ldx #>(\1)
    jsr gfx8h_pattern_set
    endm
    macro xm_gfx8h_pattern_rect
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
    jsr gfx8h_pattern_rect
    endm
    macro xm_gfx8h_copy
    lda #<(\1)
    sta X16_P0
    lda #>((\1) >> 8)
    sta X16_P1
    lda #>((\1) >> 16)
    sta X16_P2
    lda #<(\2)
    sta X16_P3
    lda #>((\2) >> 8)
    sta X16_P4
    lda #>((\2) >> 16)
    sta X16_P5
    lda #<(\3)
    ldx #>((\3) >> 8)
    ldy #>((\3) >> 16)
    jsr gfx8h_copy
    endm
    endif

; =====================================================================
; gfx/bitmap2h  (640x480 @ 2bpp; colour in A)
; =====================================================================
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_init
    jsr gfx2h_init
    endm
    endif
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_clear
    lda #(\1)
    jsr gfx2h_clear
    endm
    endif
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_pset
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    jsr gfx2h_pset
    endm
    endif
; -> A = colour, carry set if (x,y) is off screen
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_read
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr gfx2h_read
    endm
    endif
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_hline
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
    jsr gfx2h_hline
    endm
    endif
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_vline
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
    jsr gfx2h_vline
    endm
    endif
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_rect
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
    jsr gfx2h_rect
    endm
    endif
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_frame
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
    jsr gfx2h_frame
    endm
    endif
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_line
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
    jsr gfx2h_line
    endm
    endif
; A/X = the address of an 8x8 1bpp pattern
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_pattern_set
    lda #<(\1)
    ldx #>(\1)
    jsr gfx2h_pattern_set
    endm
    endif
    ifdef X16_USE_BITMAP2H
    macro xm_gfx2h_pattern_rect
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
    jsr gfx2h_pattern_rect
    endm
    endif

; =====================================================================
; gfx/bitmap2l  (320x240 @ 2bpp; colour in A)
; =====================================================================
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_init
    jsr gfx2l_init
    endm
    endif
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_clear
    lda #(\1)
    jsr gfx2l_clear
    endm
    endif
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_pset
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    jsr gfx2l_pset
    endm
    endif
; -> A = colour, carry set if (x,y) is off screen
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_read
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr gfx2l_read
    endm
    endif
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_hline
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
    jsr gfx2l_hline
    endm
    endif
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_vline
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
    jsr gfx2l_vline
    endm
    endif
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_rect
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
    jsr gfx2l_rect
    endm
    endif
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_frame
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
    jsr gfx2l_frame
    endm
    endif
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_line
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
    jsr gfx2l_line
    endm
    endif
; A/X = the address of an 8x8 1bpp pattern
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_pattern_set
    lda #<(\1)
    ldx #>(\1)
    jsr gfx2l_pattern_set
    endm
    endif
    ifdef X16_USE_BITMAP2L
    macro xm_gfx2l_pattern_rect
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
    jsr gfx2l_pattern_rect
    endm
    endif

; =====================================================================
; gfx/bitmap4l  (320x240 @ 4bpp)
; =====================================================================
    ifdef X16_USE_BITMAP4L
    macro xm_gfx4l_init
    jsr gfx4l_init
    endm
    macro xm_gfx4l_clear
    lda #(\1)
    jsr gfx4l_clear
    endm
    macro xm_gfx4l_pset
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\3)
    sta X16_P3
    jsr gfx4l_pset
    endm
    macro xm_gfx4l_read
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    jsr gfx4l_read
    endm
    macro xm_gfx4l_hline
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
    jsr gfx4l_hline
    endm
    macro xm_gfx4l_vline
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    lda #(\3)
    sta X16_P4
    jsr gfx4l_vline
    endm
    macro xm_gfx4l_rect
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
    jsr gfx4l_rect
    endm
    macro xm_gfx4l_frame
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
    jsr gfx4l_frame
    endm
    macro xm_gfx4l_line
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
    lda #(\4)
    sta X16_P5
    lda #(\5)
    sta X16_P6
    jsr gfx4l_line
    endm
    macro xm_gfx4l_pattern_set
    lda #(\2)
    sta X16_P4
    lda #(\3)
    sta X16_P5
    lda #<(\1)
    ldx #>(\1)
    jsr gfx4l_pattern_set
    endm
    macro xm_gfx4l_pattern_rect
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
    jsr gfx4l_pattern_rect
    endm
    macro xm_gfx4l_char
    lda #<(\2)
    sta X16_P0
    lda #>(\2)
    sta X16_P1
    lda #(\3)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    lda #(\1)
    jsr gfx4l_char
    endm
    macro xm_gfx4l_text
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
    jsr gfx4l_text
    endm
    endif

; =====================================================================
; gfx/bitmap4h  (640x480 @ 4bpp; VERA_2 SDRAM layer)
; =====================================================================
    ifdef X16_USE_BITMAP4H
    macro xm_gfx4h_has
    jsr gfx4h_has
    endm
    macro xm_gfx4h_init
    jsr gfx4h_init
    endm
    macro xm_gfx4h_off
    jsr gfx4h_off
    endm
    macro xm_gfx4h_passthru_on
    jsr gfx4h_passthru_on
    endm
    macro xm_gfx4h_passthru_off
    jsr gfx4h_passthru_off
    endm
    macro xm_gfx4h_pal_set
    ldx #(\1)
    lda #(\2)
    ldy #(\3)
    jsr gfx4h_pal_set
    endm
    macro xm_gfx4h_pal_load
    lda #<(\1)
    sta X16_PTR0
    lda #>(\1)
    sta X16_PTR0+1
    lda #(\2)
    ldx #(\3)
    jsr gfx4h_pal_load
    endm
    macro xm_gfx4h_clear
    lda #(\1)
    jsr gfx4h_clear
    endm
    macro xm_gfx4h_pset
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    lda #(\3)
    jsr gfx4h_pset
    endm
    macro xm_gfx4h_read
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr gfx4h_read
    endm
    macro xm_gfx4h_hline
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
    jsr gfx4h_hline
    endm
    macro xm_gfx4h_vline
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
    jsr gfx4h_vline
    endm
    macro xm_gfx4h_rect
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
    jsr gfx4h_rect
    endm
    macro xm_gfx4h_frame
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
    jsr gfx4h_frame
    endm
    macro xm_gfx4h_line
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
    jsr gfx4h_line
    endm
    macro xm_gfx4h_pattern_set
    lda #(\2)
    sta X16_P4
    lda #(\3)
    sta X16_P5
    lda #<(\1)
    ldx #>(\1)
    jsr gfx4h_pattern_set
    endm
    macro xm_gfx4h_pattern_rect
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
    jsr gfx4h_pattern_rect
    endm
    macro xm_gfx4h_copy
    lda #<(\1)
    sta X16_P0
    lda #>((\1) >> 8)
    sta X16_P1
    lda #>((\1) >> 16)
    sta X16_P2
    lda #<(\2)
    sta X16_P3
    lda #>((\2) >> 8)
    sta X16_P4
    lda #>((\2) >> 16)
    sta X16_P5
    lda #<(\3)
    ldx #>((\3) >> 8)
    ldy #>((\3) >> 16)
    jsr gfx4h_copy
    endm
    endif

; =====================================================================
; gfx/graph  (KERNAL GRAPH API)
; =====================================================================
    ifdef X16_USE_GRAPH
    macro xm_graph_init_default
    stz r0L
    stz r0H
    jsr graph_init
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_init
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    jsr graph_init
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_clear
    jsr graph_clear
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_set_window
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    jsr graph_set_window
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_set_colors
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr graph_set_colors
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_draw_line
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    jsr graph_draw_line
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_draw_rect_outline
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    lda #<(\5)
    sta r4L
    lda #>(\5)
    sta r4H
    clc
    jsr graph_draw_rect
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_draw_rect_fill
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    lda #<(\5)
    sta r4L
    lda #>(\5)
    sta r4H
    sec
    jsr graph_draw_rect
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_move_rect
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    lda #<(\5)
    sta r4L
    lda #>(\5)
    sta r4H
    lda #<(\6)
    sta r5L
    lda #>(\6)
    sta r5H
    jsr graph_move_rect
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_draw_oval_outline
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    clc
    jsr graph_draw_oval
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_draw_oval_fill
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    sec
    jsr graph_draw_oval
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_draw_image
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    lda #<(\5)
    sta r4L
    lda #>(\5)
    sta r4H
    jsr graph_draw_image
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_set_font_default
    stz r0L
    stz r0H
    jsr graph_set_font
    endm
    endif
    ifdef X16_USE_GRAPH
    macro xm_graph_set_font
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    jsr graph_set_font
    endm
    endif
; -> printable: C clear, A baseline, X width, Y height; control: C set
    ifdef X16_USE_GRAPH
    macro xm_graph_get_char_size
    lda #(\1)
    ldx #(\2)
    jsr graph_get_char_size
    endm
    endif
; -> r0/r1 updated, carry set if outside bounds
    ifdef X16_USE_GRAPH
    macro xm_graph_put_char
    lda #<(\2)
    sta r0L
    lda #>(\2)
    sta r0H
    lda #<(\3)
    sta r1L
    lda #>(\3)
    sta r1H
    lda #(\1)
    jsr graph_put_char
    endm
    endif

; =====================================================================
; gfx/console  (KERNAL console API)
; =====================================================================
    ifdef X16_USE_CONSOLE
    macro xm_con_init_fullscreen
    stz r0L
    stz r0H
    stz r1L
    stz r1H
    stz r2L
    stz r2H
    stz r3L
    stz r3H
    jsr con_init
    endm
    endif
    ifdef X16_USE_CONSOLE
    macro xm_con_init
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    jsr con_init
    endm
    endif
    ifdef X16_USE_CONSOLE
    macro xm_con_set_paging_message
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    jsr con_set_paging_message
    endm
    endif
    ifdef X16_USE_CONSOLE
    macro xm_con_disable_paging
    jsr con_disable_paging
    endm
    endif
    ifdef X16_USE_CONSOLE
    macro xm_con_put_char_wrap
    lda #(\1)
    clc
    jsr con_put_char
    endm
    endif
    ifdef X16_USE_CONSOLE
    macro xm_con_put_char_word
    lda #(\1)
    sec
    jsr con_put_char
    endm
    endif
    ifdef X16_USE_CONSOLE
    macro xm_con_get_char
    jsr con_get_char
    endm
    endif
    ifdef X16_USE_CONSOLE
    macro xm_con_put_image
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    jsr con_put_image
    endm
    endif

; =====================================================================
; gfx/fb  (KERNAL framebuffer API)
; =====================================================================
    ifdef X16_USE_FB
    macro xm_fb_init
    jsr fb_init
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_get_info
    jsr fb_get_info
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_set_palette
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #(\2)
    ldx #(\3)
    jsr fb_set_palette
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_cursor_position
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    jsr fb_cursor_position
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_cursor_next_line
    jsr fb_cursor_next_line
    endm
    endif
; -> A = color
    ifdef X16_USE_FB
    macro xm_fb_get_pixel
    xm_fb_cursor_position \1, \2
    jsr fb_get_pixel
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_set_pixel
    xm_fb_cursor_position \1, \2
    lda #(\3)
    jsr fb_set_pixel
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_get_pixels
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    jsr fb_get_pixels
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_set_pixels
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    jsr fb_set_pixels
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_set_8_pixels
    lda #(\1)
    ldx #(\2)
    jsr fb_set_8_pixels
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_set_8_pixels_opaque
    lda #<(\2)
    sta r0L
    lda #(\1)
    ldx #(\3)
    ldy #(\4)
    jsr fb_set_8_pixels_opaque
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_fill_pixels
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #(\3)
    jsr fb_fill_pixels
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_filter_pixels
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    jsr fb_filter_pixels
    endm
    endif
    ifdef X16_USE_FB
    macro xm_fb_move_pixels
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    lda #<(\3)
    sta r2L
    lda #>(\3)
    sta r2H
    lda #<(\4)
    sta r3L
    lda #>(\4)
    sta r3H
    lda #<(\5)
    sta r4L
    lda #>(\5)
    sta r4H
    jsr fb_move_pixels
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
; gfx/verafx_utils  (low-level VERA FX primitives)
; =====================================================================
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_off
    jsr fxu_off
    endm
    endif
; -> A = FX_CTRL
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_get_ctrl
    jsr fxu_get_ctrl
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_set_ctrl
    lda #(\1)
    jsr fxu_set_ctrl
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_ctrl_on
    lda #(\1)
    jsr fxu_ctrl_on
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_ctrl_off
    lda #(\1)
    jsr fxu_ctrl_off
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_addr1_mode
    lda #(\1)
    jsr fxu_addr1_mode
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_write_on
    jsr fxu_cache_write_on
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_write_off
    jsr fxu_cache_write_off
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_fill_on
    jsr fxu_cache_fill_on
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_fill_off
    jsr fxu_cache_fill_off
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_cycle_on
    jsr fxu_cache_cycle_on
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_cycle_off
    jsr fxu_cache_cycle_off
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_transparent_on
    jsr fxu_transparent_on
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_transparent_off
    jsr fxu_transparent_off
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_4bit_on
    jsr fxu_4bit_on
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_4bit_off
    jsr fxu_4bit_off
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_hop_on
    jsr fxu_hop_on
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_hop_off
    jsr fxu_hop_off
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_set_mult
    lda #(\1)
    jsr fxu_set_mult
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_set_cache
    lda #(\1)
    sta X16_P0
    lda #(\2)
    sta X16_P1
    lda #(\3)
    sta X16_P2
    lda #(\4)
    sta X16_P3
    jsr fxu_set_cache
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_reset_accum
    jsr fxu_reset_accum
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_accumulate
    jsr fxu_accumulate
    endm
    endif
; -> A = DATA0 read
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_fill0
    jsr fxu_cache_fill0
    endm
    endif
; -> A = DATA1 read
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_fill1
    jsr fxu_cache_fill1
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_write0
    lda #(\1)
    jsr fxu_cache_write0
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_cache_write1
    lda #(\1)
    jsr fxu_cache_write1
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_set_incr
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr fxu_set_incr
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_set_pos
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #<(\2)
    sta X16_P2
    lda #>(\2)
    sta X16_P3
    jsr fxu_set_pos
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_set_subpos
    lda #(\1)
    ldx #(\2)
    jsr fxu_set_subpos
    endm
    endif
; -> A = poly fill low, X = high
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_get_poly_fill
    jsr fxu_get_poly_fill
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_set_tilebase
    lda #(\1)
    jsr fxu_set_tilebase
    endm
    endif
    ifdef X16_USE_VERAFX_UTILS
    macro xm_fxu_set_mapbase
    lda #(\1)
    jsr fxu_set_mapbase
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
; audio/rom  (full BANK_AUDIO API)
; =====================================================================
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_audio_init
    jsr ar_audio_init
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_playstring_voice
    lda #(\1)
    jsr ar_playstring_voice
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_fmplaystring
    lda #(\2)
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_fmplaystring
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_fmchordstring
    lda #(\2)
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_fmchordstring
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psgplaystring
    lda #(\2)
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_psgplaystring
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psgchordstring
    lda #(\2)
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_psgchordstring
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_fmfreq
    lda #(\1)
    ldx #<(\2)
    ldy #>(\2)
    clc
    jsr ar_fmfreq
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_fmfreq_no_retrigger
    lda #(\1)
    ldx #<(\2)
    ldy #>(\2)
    sec
    jsr ar_fmfreq
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_fmnote
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    clc
    jsr ar_fmnote
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_fmnote_no_retrigger
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    sec
    jsr ar_fmnote
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_fmvib
    lda #(\1)
    ldx #(\2)
    jsr ar_fmvib
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psgfreq
    lda #(\1)
    ldx #<(\2)
    ldy #>(\2)
    jsr ar_psgfreq
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psgnote
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr ar_psgnote
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psgwav
    lda #(\1)
    ldx #(\2)
    jsr ar_psgwav
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_bas2fm
    ldx #(\1)
    jsr ar_note_bas2fm
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_bas2midi
    ldx #(\1)
    jsr ar_note_bas2midi
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_bas2psg
    ldx #(\1)
    ldy #(\2)
    jsr ar_note_bas2psg
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_fm2bas
    ldx #(\1)
    jsr ar_note_fm2bas
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_fm2midi
    ldx #(\1)
    jsr ar_note_fm2midi
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_fm2psg
    ldx #(\1)
    ldy #(\2)
    jsr ar_note_fm2psg
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_freq2bas
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_note_freq2bas
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_freq2fm
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_note_freq2fm
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_freq2midi
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_note_freq2midi
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_freq2psg
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_note_freq2psg
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_midi2bas
    lda #(\1)
    jsr ar_note_midi2bas
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_midi2fm
    ldx #(\1)
    jsr ar_note_midi2fm
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_midi2psg
    ldx #(\1)
    ldy #(\2)
    jsr ar_note_midi2psg
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_psg2bas
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_note_psg2bas
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_psg2fm
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_note_psg2fm
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_note_psg2midi
    ldx #<(\1)
    ldy #>(\1)
    jsr ar_note_psg2midi
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_init
    jsr ar_psg_init
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_playfreq
    lda #(\1)
    ldx #<(\2)
    ldy #>(\2)
    jsr ar_psg_playfreq
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_read_raw
    ldx #(\1)
    clc
    jsr ar_psg_read
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_read_cooked
    ldx #(\1)
    sec
    jsr ar_psg_read
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_setatten
    lda #(\1)
    ldx #(\2)
    jsr ar_psg_setatten
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_setfreq
    lda #(\1)
    ldx #<(\2)
    ldy #>(\2)
    jsr ar_psg_setfreq
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_setpan
    lda #(\1)
    ldx #(\2)
    jsr ar_psg_setpan
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_setvol
    lda #(\1)
    ldx #(\2)
    jsr ar_psg_setvol
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_write
    lda #(\2)
    ldx #(\1)
    jsr ar_psg_write
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_write_fast
    lda #(\2)
    ldx #(\1)
    jsr ar_psg_write_fast
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_getatten
    lda #(\1)
    jsr ar_psg_getatten
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_psg_getpan
    lda #(\1)
    jsr ar_psg_getpan
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_init
    jsr ar_ym_init
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_loaddefpatches
    jsr ar_ym_loaddefpatches
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_loadpatch_rom
    lda #(\1)
    ldx #(\2)
    sec
    jsr ar_ym_loadpatch
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_loadpatchlfn
    lda #(\1)
    ldx #(\2)
    jsr ar_ym_loadpatchlfn
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_playdrum
    lda #(\1)
    ldx #(\2)
    jsr ar_ym_playdrum
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_playnote
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    clc
    jsr ar_ym_playnote
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_setatten
    lda #(\1)
    ldx #(\2)
    jsr ar_ym_setatten
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_setdrum
    lda #(\1)
    ldx #(\2)
    jsr ar_ym_setdrum
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_setnote
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr ar_ym_setnote
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_setpan
    lda #(\1)
    ldx #(\2)
    jsr ar_ym_setpan
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_read_raw
    ldx #(\1)
    clc
    jsr ar_ym_read
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_read_cooked
    ldx #(\1)
    sec
    jsr ar_ym_read
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_release
    lda #(\1)
    jsr ar_ym_release
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_trigger
    lda #(\1)
    clc
    jsr ar_ym_trigger
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_trigger_no_retrigger
    lda #(\1)
    sec
    jsr ar_ym_trigger
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_write
    lda #(\2)
    ldx #(\1)
    jsr ar_ym_write
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_getatten
    lda #(\1)
    jsr ar_ym_getatten
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_getpan
    lda #(\1)
    jsr ar_ym_getpan
    endm
    endif
    ifdef X16_USE_AUDIO_ROM
    macro xm_ar_ym_get_chip_type
    jsr ar_ym_get_chip_type
    endm
    endif

; =====================================================================
; audio/zsm  (compact ZSM stream player)
; =====================================================================
    ifdef X16_USE_ZSM
    macro xm_zsm_init
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    jsr zsm_init
    endm
    endif
    ifdef X16_USE_ZSM
    macro xm_zsm_init_stream
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    jsr zsm_init_stream
    endm
    endif
    ifdef X16_USE_ZSM
    macro xm_zsm_play
    jsr zsm_play
    endm
    endif
    ifdef X16_USE_ZSM
    macro xm_zsm_stop
    jsr zsm_stop
    endm
    endif
    ifdef X16_USE_ZSM
    macro xm_zsm_rewind
    jsr zsm_rewind
    endm
    endif
; -> A = low byte, X = high byte
    ifdef X16_USE_ZSM
    macro xm_zsm_get_tickrate
    jsr zsm_get_tickrate
    endm
    endif
; -> A = ZSM_FLAG_* bits, carry set if active
    ifdef X16_USE_ZSM
    macro xm_zsm_status
    jsr zsm_status
    endm
    endif
; -> A = ZSM_FLAG_* bits, carry set if active
    ifdef X16_USE_ZSM
    macro xm_zsm_tick
    jsr zsm_tick
    endm
    endif
; -> carry set if a supported PCM table is present
    ifdef X16_USE_ZSM_PCM
    macro xm_zsm_pcm_present
    jsr zsm_pcm_present
    endm
    endif
    ifdef X16_USE_ZSM_PCM
    macro xm_zsm_pcm_trigger
    lda #(\1)
    jsr zsm_pcm_trigger
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
; input/mouse
; =====================================================================
    ifdef X16_USE_MOUSE
    macro xm_mse_config
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr mse_config
    endm
    endif
    ifdef X16_USE_MOUSE
    macro xm_mse_scan
    jsr mse_scan
    endm
    endif
; -> P0/1 = x, P2/3 = y, A = buttons, X = wheel delta
    ifdef X16_USE_MOUSE
    macro xm_mse_get
    jsr mse_get
    endm
    endif
; -> sugar_zp/sugar_zp+1 = x, sugar_zp+2/sugar_zp+3 = y, A = buttons, X = wheel delta
    ifdef X16_USE_MOUSE
    macro xm_mse_get_to
    ldx #(\1)
    jsr mse_get_to
    endm
    endif
    ifdef X16_USE_MOUSE
    macro xm_mse_show
    lda #(\1)
    jsr mse_show
    endm
    endif
    ifdef X16_USE_MOUSE
    macro xm_mse_show_keep
    jsr mse_show_keep
    endm
    endif
    ifdef X16_USE_MOUSE
    macro xm_mse_hide
    jsr mse_hide
    endm
    endif

; =====================================================================
; input/keyboard
; =====================================================================
    ifdef X16_USE_KEYBOARD
    macro xm_kbd_scan
    jsr kbd_scan
    endm
    endif
; -> A = next PETSCII key, X = queued key count, Z set when empty
    ifdef X16_USE_KEYBOARD
    macro xm_kbd_peek
    jsr kbd_peek
    endm
    endif
    ifdef X16_USE_KEYBOARD
    macro xm_kbd_put
    lda #(\1)
    jsr kbd_put
    endm
    endif
; -> A = KBD_MOD_* bitfield
    ifdef X16_USE_KEYBOARD
    macro xm_kbd_get_modifiers
    jsr kbd_get_modifiers
    endm
    endif
; -> A = layout index, X/Y = current NUL-terminated layout string
    ifdef X16_USE_KEYBOARD
    macro xm_kbd_get_keymap
    jsr kbd_get_keymap
    endm
    endif
; -> carry clear on success, carry set on unknown layout
    ifdef X16_USE_KEYBOARD
    macro xm_kbd_set_keymap
    ldx #<(\1)
    ldy #>(\1)
    jsr kbd_set_keymap
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
; storage/iec
; =====================================================================
    ifdef X16_USE_IEC
    macro xm_iec_listen
    lda #(\1)
    jsr iec_listen
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_talk
    lda #(\1)
    jsr iec_talk
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_second
    lda #(\1)
    jsr iec_second
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_tksa
    lda #(\1)
    jsr iec_tksa
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_ciout
    lda #(\1)
    jsr iec_ciout
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_acptr
    jsr iec_acptr
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_unlisten
    jsr iec_unlisten
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_untalk
    jsr iec_untalk
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_set_timeout
    lda #(\1)
    jsr iec_set_timeout
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_readst
    jsr iec_readst
    endm
    endif
; -> X/Y = bytes read, carry set when unsupported/error
    ifdef X16_USE_IEC
    macro xm_iec_macptr
    lda #(\2)
    ldx #<(\1)
    ldy #>(\1)
    jsr iec_macptr
    endm
    endif
; -> X/Y = bytes written, carry set when unsupported/error
    ifdef X16_USE_IEC
    macro xm_iec_mciout
    lda #(\2)
    ldx #<(\1)
    ldy #>(\1)
    jsr iec_mciout
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_open_channel
    lda #(\1)
    ldy #(\2)
    jsr iec_open_channel
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_data_channel
    lda #(\1)
    ldy #(\2)
    jsr iec_data_channel
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_talk_channel
    lda #(\1)
    ldy #(\2)
    jsr iec_talk_channel
    endm
    endif
    ifdef X16_USE_IEC
    macro xm_iec_close_channel
    lda #(\1)
    ldy #(\2)
    jsr iec_close_channel
    endm
    endif

; =====================================================================
; storage/fileio
; =====================================================================
    ifdef X16_USE_FILEIO
    macro xm_fio_set_lfs
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr fio_set_lfs
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_set_name
    lda #(\2)
    ldx #<(\1)
    ldy #>(\1)
    jsr fio_set_name
    endm
    endif
; -> carry set = KERNAL open error
    ifdef X16_USE_FILEIO
    macro xm_fio_open_named
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
    lda #(\5)
    sta X16_P5
    jsr fio_open_named
    endm
    endif
; -> carry set = OPEN or CHKIN error
    ifdef X16_USE_FILEIO
    macro xm_fio_open_read
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
    lda #(\5)
    sta X16_P5
    jsr fio_open_read
    endm
    endif
; -> carry set = OPEN or CHKOUT error
    ifdef X16_USE_FILEIO
    macro xm_fio_open_write
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
    lda #(\5)
    sta X16_P5
    jsr fio_open_write
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_close
    lda #(\1)
    jsr fio_close
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_close_named
    lda #(\1)
    sta X16_P3
    jsr fio_close_named
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_chkin
    ldx #(\1)
    jsr fio_chkin
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_chkout
    ldx #(\1)
    jsr fio_chkout
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_clrchn
    jsr fio_clrchn
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_chrin
    jsr fio_chrin
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_chrout
    lda #(\1)
    jsr fio_chrout
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_readst
    jsr fio_readst
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_getin
    jsr fio_getin
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_close_all
    jsr fio_close_all
    endm
    endif
    ifdef X16_USE_FILEIO
    macro xm_fio_close_device
    lda #(\1)
    jsr fio_close_device
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
    ifdef X16_USE_BMX
    macro xm_bmx_load_hires
    lda #<(\1)
    sta X16_P0
    lda #>(\1)
    sta X16_P1
    lda #(\2)
    sta X16_P2
    lda #(\3)
    sta X16_P3
    jsr bmx_load_hires
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
; system/clock
; =====================================================================
; -> A/X/Y = 24-bit 60 Hz timer, low to high
    ifdef X16_USE_CLOCK
    macro xm_clock_get_timer
    jsr clock_get_timer
    endm
    endif
    ifdef X16_USE_CLOCK
    macro xm_clock_set_timer
    lda #<(\1)
    ldx #>((\1) >> 8)
    ldy #>((\1) >> 16)
    jsr clock_set_timer
    endm
    endif
    ifdef X16_USE_CLOCK
    macro xm_clock_update
    jsr clock_update
    endm
    endif
; -> r0..r3 = year/month/day/hour/min/sec/jiffy/weekday
    ifdef X16_USE_CLOCK
    macro xm_clock_get_date_time
    jsr clock_get_date_time
    endm
    endif
; sugar_year1900 is the KERNAL byte value: full year minus 1900.
    ifdef X16_USE_CLOCK
    macro xm_clock_set_date_time_raw
    lda #<(\1)
    sta r0L
    lda #<(\2)
    sta r0H
    lda #<(\3)
    sta r1L
    lda #<(\4)
    sta r1H
    lda #<(\5)
    sta r2L
    lda #<(\6)
    sta r2H
    lda #<(\7)
    sta r3L
    lda #<(\8)
    sta r3H
    jsr clock_set_date_time
    endm
    endif
; Friendly form: sugar_year is the full year, e.g. 2026; jiffies are set to 0.
    ifdef X16_USE_CLOCK
    macro xm_clock_set_date_time
    lda #<((\1) - 1900)
    sta r0L
    lda #<(\2)
    sta r0H
    lda #<(\3)
    sta r1L
    lda #<(\4)
    sta r1H
    lda #<(\5)
    sta r2L
    lda #<(\6)
    sta r2H
    stz r3L
    lda #<(\7)
    sta r3H
    jsr clock_set_date_time
    endm
    endif

; =====================================================================
; comms/i2c
; =====================================================================
; -> A = value, carry set on NAK/error
    ifdef X16_USE_I2C
    macro xm_i2c_read_byte
    ldx #(\1)
    ldy #(\2)
    jsr i2c_read_byte
    endm
    endif
; -> carry set on NAK/error
    ifdef X16_USE_I2C
    macro xm_i2c_write_byte
    lda #(\1)
    ldx #(\2)
    ldy #(\3)
    jsr i2c_write_byte
    endm
    endif
; -> carry set on NAK/error
    ifdef X16_USE_I2C
    macro xm_i2c_batch_read
    lda #<(\2)
    sta r0
    lda #>(\2)
    sta r0+1
    lda #<(\3)
    sta r1
    lda #>(\3)
    sta r1+1
    ldx #(\1)
    clc
    jsr i2c_batch_read
    endm
    endif
; -> carry set on NAK/error; reads repeatedly into the same address
    ifdef X16_USE_I2C
    macro xm_i2c_batch_read_fixed
    lda #<(\2)
    sta r0
    lda #>(\2)
    sta r0+1
    lda #<(\3)
    sta r1
    lda #>(\3)
    sta r1+1
    ldx #(\1)
    sec
    jsr i2c_batch_read
    endm
    endif
; -> r2 = bytes written, carry set on NAK/error
    ifdef X16_USE_I2C
    macro xm_i2c_batch_write
    lda #<(\2)
    sta r0
    lda #>(\2)
    sta r0+1
    lda #<(\3)
    sta r1
    lda #>(\3)
    sta r1+1
    ldx #(\1)
    jsr i2c_batch_write
    endm
    endif

; =====================================================================
; comms/spi  (VERA SPI controller)
; =====================================================================
; -> A = VERA_SPI_* control/status bits
    ifdef X16_USE_VERA_SPI
    macro xm_spi_get_ctrl
    jsr spi_get_ctrl
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_set_ctrl
    lda #(\1)
    jsr spi_set_ctrl
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_select
    jsr spi_select
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_deselect
    jsr spi_deselect
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_slow
    jsr spi_slow
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_fast
    jsr spi_fast
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_autotx_on
    jsr spi_autotx_on
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_autotx_off
    jsr spi_autotx_off
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_wait
    jsr spi_wait
    endm
    endif
; -> A = received byte
    ifdef X16_USE_VERA_SPI
    macro xm_spi_transfer
    lda #(\1)
    jsr spi_transfer
    endm
    endif
; -> A = received byte
    ifdef X16_USE_VERA_SPI
    macro xm_spi_read
    jsr spi_read
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_write
    lda #(\1)
    jsr spi_write
    endm
    endif
; -> A = received byte; starts the next Auto-TX transfer
    ifdef X16_USE_VERA_SPI
    macro xm_spi_autotx_read
    jsr spi_autotx_read
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_read_bytes
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    jsr spi_read_bytes
    endm
    endif
    ifdef X16_USE_VERA_SPI
    macro xm_spi_write_bytes
    lda #<(\1)
    sta r0L
    lda #>(\1)
    sta r0H
    lda #<(\2)
    sta r1L
    lda #>(\2)
    sta r1H
    jsr spi_write_bytes
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
