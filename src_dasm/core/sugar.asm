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
; video/vdc  (VERA display composer)
; =====================================================================
; -> A = DC_VIDEO
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_get_video
    jsr vdc_get_video
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_set_video
    lda #({1})
    jsr vdc_set_video
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_set_output
    lda #({1})
    jsr vdc_set_output
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_set_layers
    lda #({1})
    jsr vdc_set_layers
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_layer_on
    lda #({1})
    jsr vdc_layer_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_layer_off
    lda #({1})
    jsr vdc_layer_off
    ENDM
    ENDIF
; -> A = HSCALE, X = VSCALE
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_get_scale
    jsr vdc_get_scale
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_set_scale
    lda #({1})
    ldx #({2})
    jsr vdc_set_scale
    ENDM
    ENDIF
; -> A = border palette index
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_get_border
    jsr vdc_get_border
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_set_border
    lda #({1})
    jsr vdc_set_border
    ENDM
    ENDIF
; -> A = HSTART, X = HSTOP, Y = VSTART, r0L = VSTOP
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_get_active_raw
    jsr vdc_get_active_raw
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_set_active_raw
    lda #({1})
    ldx #({2})
    ldy #({3})
    pha
    lda #({4})
    sta r0L
    pla
    jsr vdc_set_active_raw
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_set_active
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
    jsr vdc_set_active
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_fullscreen
    jsr vdc_fullscreen
    ENDM
    ENDIF
; -> carry set if valid, A = major, X = minor, Y = build
    IFCONST X16_USE_VERA_DC
    MAC xm_vdc_get_version
    jsr vdc_get_version
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
; point VERA port 0 at a character cell, for the blit calls below
    IFCONST X16_USE_SCREEN
    MAC xm_screen_addr
    ldx #({1})
    ldy #({2})
    jsr screen_addr
    ENDM
    ENDIF
; ...and port 1, which is where a vera_copy destination goes
    IFCONST X16_USE_SCREEN
    MAC xm_screen_addr1
    ldx #({1})
    ldy #({2})
    jsr screen_addr1
    ENDM
    ENDIF
; slide a rectangle of text rows: sugar_dir 0 moves the picture up, 1 down
    IFCONST X16_USE_SCREEN
    MAC xm_screen_scroll
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
    jsr screen_scroll
    ENDM
    ENDIF
; PETSCII -> screen code
    IFCONST X16_USE_SCREEN
    MAC xm_screen_scode
    lda #({1})
    jsr screen_scode
    ENDM
    ENDIF
; write sugar_count characters from sugar_addr, all in colour sugar_col (fg | bg << 4)
    IFCONST X16_USE_SCREEN
    MAC xm_screen_blit
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    ldx #({3})
    jsr screen_blit
    ENDM
    ENDIF
; write sugar_count copies of sugar_ch in colour sugar_col
    IFCONST X16_USE_SCREEN
    MAC xm_screen_blitfill
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr screen_blitfill
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
; The same call with the address already split, so every argument can be
; a variable: vbank = address bit 16, vaddr = the low 16 bits.
    IFCONST X16_USE_SPRITE
    MAC xm_sprite_image_at
    ldx #({1})
    lda #<({3})
    sta X16_P0
    lda #>({3})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({4})
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
; gfx/bitmap8l  (320x240 @ 8bpp)
; =====================================================================
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_init
    jsr gfx8l_init
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_clear
    lda #({1})
    jsr gfx8l_clear
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_pset
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    jsr gfx8l_pset
    ENDM
    ENDIF
; -> A = colour
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_read
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    jsr gfx8l_read
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_hline
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
    jsr gfx8l_hline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_vline
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
    jsr gfx8l_vline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_rect
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
    jsr gfx8l_rect
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_frame
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
    jsr gfx8l_frame
    ENDM
    ENDIF
; A/X = the address of an 8x8 1bpp pattern
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_pattern_set
    lda #<({1})
    ldx #>({1})
    jsr gfx8l_pattern_set
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_pattern_rect
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
    jsr gfx8l_pattern_rect
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_line
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
    jsr gfx8l_line
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_char
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    lda #({4})
    sta X16_P3
    lda #({1})
    jsr gfx8l_char
    ENDM
    ENDIF
; str = a NUL-terminated string
    IFCONST X16_USE_BITMAP8L
    MAC xm_gfx8l_text
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
    jsr gfx8l_text
    ENDM
    ENDIF

; =====================================================================
; gfx/bitmap8h  (640x480 @ 8bpp; VERA_2 SDRAM layer)
; =====================================================================
    IFCONST X16_USE_BITMAP8H
    MAC xm_gfx8h_has
    jsr gfx8h_has
    ENDM
    MAC xm_gfx8h_init
    jsr gfx8h_init
    ENDM
    MAC xm_gfx8h_off
    jsr gfx8h_off
    ENDM
    MAC xm_gfx8h_passthru_on
    jsr gfx8h_passthru_on
    ENDM
    MAC xm_gfx8h_passthru_off
    jsr gfx8h_passthru_off
    ENDM
    MAC xm_gfx8h_pal_set
    ldx #({1})
    lda #({2})
    ldy #({3})
    jsr gfx8h_pal_set
    ENDM
    MAC xm_gfx8h_pal_load
    lda #<({1})
    sta X16_PTR0
    lda #>({1})
    sta X16_PTR0+1
    lda #({2})
    ldx #({3})
    jsr gfx8h_pal_load
    ENDM
    MAC xm_gfx8h_clear
    lda #({1})
    jsr gfx8h_clear
    ENDM
    MAC xm_gfx8h_pset
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    jsr gfx8h_pset
    ENDM
    MAC xm_gfx8h_read
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr gfx8h_read
    ENDM
    MAC xm_gfx8h_hline
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
    jsr gfx8h_hline
    ENDM
    MAC xm_gfx8h_vline
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
    jsr gfx8h_vline
    ENDM
    MAC xm_gfx8h_rect
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
    jsr gfx8h_rect
    ENDM
    MAC xm_gfx8h_frame
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
    jsr gfx8h_frame
    ENDM
    MAC xm_gfx8h_line
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
    jsr gfx8h_line
    ENDM
    MAC xm_gfx8h_pattern_set
    lda #({2})
    sta X16_P4
    lda #({3})
    sta X16_P5
    lda #<({1})
    ldx #>({1})
    jsr gfx8h_pattern_set
    ENDM
    MAC xm_gfx8h_pattern_rect
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
    jsr gfx8h_pattern_rect
    ENDM
    MAC xm_gfx8h_copy
    lda #<({1})
    sta X16_P0
    lda #>(({1}) >> 8)
    sta X16_P1
    lda #>(({1}) >> 16)
    sta X16_P2
    lda #<({2})
    sta X16_P3
    lda #>(({2}) >> 8)
    sta X16_P4
    lda #>(({2}) >> 16)
    sta X16_P5
    lda #<({3})
    ldx #>(({3}) >> 8)
    ldy #>(({3}) >> 16)
    jsr gfx8h_copy
    ENDM
    ENDIF

; =====================================================================
; gfx/bitmap2h  (640x480 @ 2bpp; colour in A)
; =====================================================================
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_init
    jsr gfx2h_init
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_clear
    lda #({1})
    jsr gfx2h_clear
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_pset
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    jsr gfx2h_pset
    ENDM
    ENDIF
; -> A = colour, carry set if (x,y) is off screen
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_read
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr gfx2h_read
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_hline
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
    jsr gfx2h_hline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_vline
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
    jsr gfx2h_vline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_rect
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
    jsr gfx2h_rect
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_frame
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
    jsr gfx2h_frame
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_line
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
    jsr gfx2h_line
    ENDM
    ENDIF
; A/X = the address of an 8x8 1bpp pattern
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_pattern_set
    lda #<({1})
    ldx #>({1})
    jsr gfx2h_pattern_set
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2H
    MAC xm_gfx2h_pattern_rect
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
    jsr gfx2h_pattern_rect
    ENDM
    ENDIF

; =====================================================================
; gfx/bitmap2l  (320x240 @ 2bpp; colour in A)
; =====================================================================
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_init
    jsr gfx2l_init
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_clear
    lda #({1})
    jsr gfx2l_clear
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_pset
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    jsr gfx2l_pset
    ENDM
    ENDIF
; -> A = colour, carry set if (x,y) is off screen
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_read
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr gfx2l_read
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_hline
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
    jsr gfx2l_hline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_vline
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
    jsr gfx2l_vline
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_rect
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
    jsr gfx2l_rect
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_frame
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
    jsr gfx2l_frame
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_line
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
    jsr gfx2l_line
    ENDM
    ENDIF
; A/X = the address of an 8x8 1bpp pattern
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_pattern_set
    lda #<({1})
    ldx #>({1})
    jsr gfx2l_pattern_set
    ENDM
    ENDIF
    IFCONST X16_USE_BITMAP2L
    MAC xm_gfx2l_pattern_rect
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
    jsr gfx2l_pattern_rect
    ENDM
    ENDIF

; =====================================================================
; gfx/bitmap4l  (320x240 @ 4bpp)
; =====================================================================
    IFCONST X16_USE_BITMAP4L
    MAC xm_gfx4l_init
    jsr gfx4l_init
    ENDM
    MAC xm_gfx4l_clear
    lda #({1})
    jsr gfx4l_clear
    ENDM
    MAC xm_gfx4l_pset
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    jsr gfx4l_pset
    ENDM
    MAC xm_gfx4l_read
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    jsr gfx4l_read
    ENDM
    MAC xm_gfx4l_hline
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
    jsr gfx4l_hline
    ENDM
    MAC xm_gfx4l_vline
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({4})
    sta X16_P3
    lda #({3})
    sta X16_P4
    jsr gfx4l_vline
    ENDM
    MAC xm_gfx4l_rect
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
    jsr gfx4l_rect
    ENDM
    MAC xm_gfx4l_frame
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
    jsr gfx4l_frame
    ENDM
    MAC xm_gfx4l_line
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
    lda #({4})
    sta X16_P5
    lda #({5})
    sta X16_P6
    jsr gfx4l_line
    ENDM
    MAC xm_gfx4l_pattern_set
    lda #({2})
    sta X16_P4
    lda #({3})
    sta X16_P5
    lda #<({1})
    ldx #>({1})
    jsr gfx4l_pattern_set
    ENDM
    MAC xm_gfx4l_pattern_rect
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
    jsr gfx4l_pattern_rect
    ENDM
    MAC xm_gfx4l_char
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    lda #({4})
    sta X16_P3
    lda #({1})
    jsr gfx4l_char
    ENDM
    MAC xm_gfx4l_text
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
    jsr gfx4l_text
    ENDM
    ENDIF

; =====================================================================
; gfx/bitmap4h  (640x480 @ 4bpp; VERA_2 SDRAM layer)
; =====================================================================
    IFCONST X16_USE_BITMAP4H
    MAC xm_gfx4h_has
    jsr gfx4h_has
    ENDM
    MAC xm_gfx4h_init
    jsr gfx4h_init
    ENDM
    MAC xm_gfx4h_off
    jsr gfx4h_off
    ENDM
    MAC xm_gfx4h_passthru_on
    jsr gfx4h_passthru_on
    ENDM
    MAC xm_gfx4h_passthru_off
    jsr gfx4h_passthru_off
    ENDM
    MAC xm_gfx4h_pal_set
    ldx #({1})
    lda #({2})
    ldy #({3})
    jsr gfx4h_pal_set
    ENDM
    MAC xm_gfx4h_pal_load
    lda #<({1})
    sta X16_PTR0
    lda #>({1})
    sta X16_PTR0+1
    lda #({2})
    ldx #({3})
    jsr gfx4h_pal_load
    ENDM
    MAC xm_gfx4h_clear
    lda #({1})
    jsr gfx4h_clear
    ENDM
    MAC xm_gfx4h_pset
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    lda #({3})
    jsr gfx4h_pset
    ENDM
    MAC xm_gfx4h_read
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr gfx4h_read
    ENDM
    MAC xm_gfx4h_hline
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
    jsr gfx4h_hline
    ENDM
    MAC xm_gfx4h_vline
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
    jsr gfx4h_vline
    ENDM
    MAC xm_gfx4h_rect
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
    jsr gfx4h_rect
    ENDM
    MAC xm_gfx4h_frame
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
    jsr gfx4h_frame
    ENDM
    MAC xm_gfx4h_line
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
    jsr gfx4h_line
    ENDM
    MAC xm_gfx4h_pattern_set
    lda #({2})
    sta X16_P4
    lda #({3})
    sta X16_P5
    lda #<({1})
    ldx #>({1})
    jsr gfx4h_pattern_set
    ENDM
    MAC xm_gfx4h_pattern_rect
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
    jsr gfx4h_pattern_rect
    ENDM
    MAC xm_gfx4h_copy
    lda #<({1})
    sta X16_P0
    lda #>(({1}) >> 8)
    sta X16_P1
    lda #>(({1}) >> 16)
    sta X16_P2
    lda #<({2})
    sta X16_P3
    lda #>(({2}) >> 8)
    sta X16_P4
    lda #>(({2}) >> 16)
    sta X16_P5
    lda #<({3})
    ldx #>(({3}) >> 8)
    ldy #>(({3}) >> 16)
    jsr gfx4h_copy
    ENDM
    ENDIF

; =====================================================================
; gfx/graph  (KERNAL GRAPH API)
; =====================================================================
    IFCONST X16_USE_GRAPH
    MAC xm_graph_init_default
    stz r0L
    stz r0H
    jsr graph_init
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_init
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    jsr graph_init
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_clear
    jsr graph_clear
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_set_window
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    jsr graph_set_window
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_set_colors
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr graph_set_colors
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_draw_line
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    jsr graph_draw_line
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_draw_rect_outline
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    lda #<({5})
    sta r4L
    lda #>({5})
    sta r4H
    clc
    jsr graph_draw_rect
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_draw_rect_fill
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    lda #<({5})
    sta r4L
    lda #>({5})
    sta r4H
    sec
    jsr graph_draw_rect
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_move_rect
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    lda #<({5})
    sta r4L
    lda #>({5})
    sta r4H
    lda #<({6})
    sta r5L
    lda #>({6})
    sta r5H
    jsr graph_move_rect
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_draw_oval_outline
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    clc
    jsr graph_draw_oval
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_draw_oval_fill
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    sec
    jsr graph_draw_oval
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_draw_image
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    lda #<({5})
    sta r4L
    lda #>({5})
    sta r4H
    jsr graph_draw_image
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_set_font_default
    stz r0L
    stz r0H
    jsr graph_set_font
    ENDM
    ENDIF
    IFCONST X16_USE_GRAPH
    MAC xm_graph_set_font
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    jsr graph_set_font
    ENDM
    ENDIF
; -> printable: C clear, A baseline, X width, Y height; control: C set
    IFCONST X16_USE_GRAPH
    MAC xm_graph_get_char_size
    lda #({1})
    ldx #({2})
    jsr graph_get_char_size
    ENDM
    ENDIF
; -> r0/r1 updated, carry set if outside bounds
    IFCONST X16_USE_GRAPH
    MAC xm_graph_put_char
    lda #<({2})
    sta r0L
    lda #>({2})
    sta r0H
    lda #<({3})
    sta r1L
    lda #>({3})
    sta r1H
    lda #({1})
    jsr graph_put_char
    ENDM
    ENDIF

; =====================================================================
; gfx/console  (KERNAL console API)
; =====================================================================
    IFCONST X16_USE_CONSOLE
    MAC xm_con_init_fullscreen
    stz r0L
    stz r0H
    stz r1L
    stz r1H
    stz r2L
    stz r2H
    stz r3L
    stz r3H
    jsr con_init
    ENDM
    ENDIF
    IFCONST X16_USE_CONSOLE
    MAC xm_con_init
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    jsr con_init
    ENDM
    ENDIF
    IFCONST X16_USE_CONSOLE
    MAC xm_con_set_paging_message
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    jsr con_set_paging_message
    ENDM
    ENDIF
    IFCONST X16_USE_CONSOLE
    MAC xm_con_disable_paging
    jsr con_disable_paging
    ENDM
    ENDIF
    IFCONST X16_USE_CONSOLE
    MAC xm_con_put_char_wrap
    lda #({1})
    clc
    jsr con_put_char
    ENDM
    ENDIF
    IFCONST X16_USE_CONSOLE
    MAC xm_con_put_char_word
    lda #({1})
    sec
    jsr con_put_char
    ENDM
    ENDIF
    IFCONST X16_USE_CONSOLE
    MAC xm_con_get_char
    jsr con_get_char
    ENDM
    ENDIF
    IFCONST X16_USE_CONSOLE
    MAC xm_con_put_image
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    jsr con_put_image
    ENDM
    ENDIF

; =====================================================================
; gfx/fb  (KERNAL framebuffer API)
; =====================================================================
    IFCONST X16_USE_FB
    MAC xm_fb_init
    jsr fb_init
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_get_info
    jsr fb_get_info
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_set_palette
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #({2})
    ldx #({3})
    jsr fb_set_palette
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_cursor_position
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    jsr fb_cursor_position
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_cursor_next_line
    jsr fb_cursor_next_line
    ENDM
    ENDIF
; -> A = color
    IFCONST X16_USE_FB
    MAC xm_fb_get_pixel
    xm_fb_cursor_position {1}, {2}
    jsr fb_get_pixel
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_set_pixel
    xm_fb_cursor_position {1}, {2}
    lda #({3})
    jsr fb_set_pixel
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_get_pixels
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    jsr fb_get_pixels
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_set_pixels
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    jsr fb_set_pixels
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_set_8_pixels
    lda #({1})
    ldx #({2})
    jsr fb_set_8_pixels
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_set_8_pixels_opaque
    lda #<({2})
    sta r0L
    lda #({1})
    ldx #({3})
    ldy #({4})
    jsr fb_set_8_pixels_opaque
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_fill_pixels
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #({3})
    jsr fb_fill_pixels
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_filter_pixels
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    jsr fb_filter_pixels
    ENDM
    ENDIF
    IFCONST X16_USE_FB
    MAC xm_fb_move_pixels
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    lda #<({3})
    sta r2L
    lda #>({3})
    sta r2H
    lda #<({4})
    sta r3L
    lda #>({4})
    sta r3H
    lda #<({5})
    sta r4L
    lda #>({5})
    sta r4H
    jsr fb_move_pixels
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
; gfx/verafx_utils  (low-level VERA FX primitives)
; =====================================================================
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_off
    jsr fxu_off
    ENDM
    ENDIF
; -> A = FX_CTRL
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_get_ctrl
    jsr fxu_get_ctrl
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_set_ctrl
    lda #({1})
    jsr fxu_set_ctrl
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_ctrl_on
    lda #({1})
    jsr fxu_ctrl_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_ctrl_off
    lda #({1})
    jsr fxu_ctrl_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_addr1_mode
    lda #({1})
    jsr fxu_addr1_mode
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_write_on
    jsr fxu_cache_write_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_write_off
    jsr fxu_cache_write_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_fill_on
    jsr fxu_cache_fill_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_fill_off
    jsr fxu_cache_fill_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_cycle_on
    jsr fxu_cache_cycle_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_cycle_off
    jsr fxu_cache_cycle_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_transparent_on
    jsr fxu_transparent_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_transparent_off
    jsr fxu_transparent_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_4bit_on
    jsr fxu_4bit_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_4bit_off
    jsr fxu_4bit_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_hop_on
    jsr fxu_hop_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_hop_off
    jsr fxu_hop_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_set_mult
    lda #({1})
    jsr fxu_set_mult
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_set_cache
    lda #({1})
    sta X16_P0
    lda #({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    lda #({4})
    sta X16_P3
    jsr fxu_set_cache
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_reset_accum
    jsr fxu_reset_accum
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_accumulate
    jsr fxu_accumulate
    ENDM
    ENDIF
; -> A = DATA0 read
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_fill0
    jsr fxu_cache_fill0
    ENDM
    ENDIF
; -> A = DATA1 read
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_fill1
    jsr fxu_cache_fill1
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_write0
    lda #({1})
    jsr fxu_cache_write0
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_cache_write1
    lda #({1})
    jsr fxu_cache_write1
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_set_incr
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr fxu_set_incr
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_set_pos
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr fxu_set_pos
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_set_subpos
    lda #({1})
    ldx #({2})
    jsr fxu_set_subpos
    ENDM
    ENDIF
; -> A = poly fill low, X = high
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_get_poly_fill
    jsr fxu_get_poly_fill
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_set_tilebase
    lda #({1})
    jsr fxu_set_tilebase
    ENDM
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    MAC xm_fxu_set_mapbase
    lda #({1})
    jsr fxu_set_mapbase
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
; audio/rom  (full BANK_AUDIO API)
; =====================================================================
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_audio_init
    jsr ar_audio_init
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_playstring_voice
    lda #({1})
    jsr ar_playstring_voice
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_fmplaystring
    lda #({2})
    ldx #<({1})
    ldy #>({1})
    jsr ar_fmplaystring
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_fmchordstring
    lda #({2})
    ldx #<({1})
    ldy #>({1})
    jsr ar_fmchordstring
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psgplaystring
    lda #({2})
    ldx #<({1})
    ldy #>({1})
    jsr ar_psgplaystring
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psgchordstring
    lda #({2})
    ldx #<({1})
    ldy #>({1})
    jsr ar_psgchordstring
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_fmfreq
    lda #({1})
    ldx #<({2})
    ldy #>({2})
    clc
    jsr ar_fmfreq
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_fmfreq_no_retrigger
    lda #({1})
    ldx #<({2})
    ldy #>({2})
    sec
    jsr ar_fmfreq
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_fmnote
    lda #({1})
    ldx #({2})
    ldy #({3})
    clc
    jsr ar_fmnote
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_fmnote_no_retrigger
    lda #({1})
    ldx #({2})
    ldy #({3})
    sec
    jsr ar_fmnote
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_fmvib
    lda #({1})
    ldx #({2})
    jsr ar_fmvib
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psgfreq
    lda #({1})
    ldx #<({2})
    ldy #>({2})
    jsr ar_psgfreq
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psgnote
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr ar_psgnote
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psgwav
    lda #({1})
    ldx #({2})
    jsr ar_psgwav
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_bas2fm
    ldx #({1})
    jsr ar_note_bas2fm
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_bas2midi
    ldx #({1})
    jsr ar_note_bas2midi
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_bas2psg
    ldx #({1})
    ldy #({2})
    jsr ar_note_bas2psg
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_fm2bas
    ldx #({1})
    jsr ar_note_fm2bas
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_fm2midi
    ldx #({1})
    jsr ar_note_fm2midi
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_fm2psg
    ldx #({1})
    ldy #({2})
    jsr ar_note_fm2psg
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_freq2bas
    ldx #<({1})
    ldy #>({1})
    jsr ar_note_freq2bas
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_freq2fm
    ldx #<({1})
    ldy #>({1})
    jsr ar_note_freq2fm
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_freq2midi
    ldx #<({1})
    ldy #>({1})
    jsr ar_note_freq2midi
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_freq2psg
    ldx #<({1})
    ldy #>({1})
    jsr ar_note_freq2psg
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_midi2bas
    lda #({1})
    jsr ar_note_midi2bas
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_midi2fm
    ldx #({1})
    jsr ar_note_midi2fm
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_midi2psg
    ldx #({1})
    ldy #({2})
    jsr ar_note_midi2psg
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_psg2bas
    ldx #<({1})
    ldy #>({1})
    jsr ar_note_psg2bas
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_psg2fm
    ldx #<({1})
    ldy #>({1})
    jsr ar_note_psg2fm
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_note_psg2midi
    ldx #<({1})
    ldy #>({1})
    jsr ar_note_psg2midi
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_init
    jsr ar_psg_init
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_playfreq
    lda #({1})
    ldx #<({2})
    ldy #>({2})
    jsr ar_psg_playfreq
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_read_raw
    ldx #({1})
    clc
    jsr ar_psg_read
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_read_cooked
    ldx #({1})
    sec
    jsr ar_psg_read
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_setatten
    lda #({1})
    ldx #({2})
    jsr ar_psg_setatten
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_setfreq
    lda #({1})
    ldx #<({2})
    ldy #>({2})
    jsr ar_psg_setfreq
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_setpan
    lda #({1})
    ldx #({2})
    jsr ar_psg_setpan
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_setvol
    lda #({1})
    ldx #({2})
    jsr ar_psg_setvol
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_write
    lda #({2})
    ldx #({1})
    jsr ar_psg_write
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_write_fast
    lda #({2})
    ldx #({1})
    jsr ar_psg_write_fast
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_getatten
    lda #({1})
    jsr ar_psg_getatten
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_psg_getpan
    lda #({1})
    jsr ar_psg_getpan
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_init
    jsr ar_ym_init
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_loaddefpatches
    jsr ar_ym_loaddefpatches
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_loadpatch_rom
    lda #({1})
    ldx #({2})
    sec
    jsr ar_ym_loadpatch
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_loadpatchlfn
    lda #({1})
    ldx #({2})
    jsr ar_ym_loadpatchlfn
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_playdrum
    lda #({1})
    ldx #({2})
    jsr ar_ym_playdrum
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_playnote
    lda #({1})
    ldx #({2})
    ldy #({3})
    clc
    jsr ar_ym_playnote
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_setatten
    lda #({1})
    ldx #({2})
    jsr ar_ym_setatten
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_setdrum
    lda #({1})
    ldx #({2})
    jsr ar_ym_setdrum
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_setnote
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr ar_ym_setnote
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_setpan
    lda #({1})
    ldx #({2})
    jsr ar_ym_setpan
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_read_raw
    ldx #({1})
    clc
    jsr ar_ym_read
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_read_cooked
    ldx #({1})
    sec
    jsr ar_ym_read
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_release
    lda #({1})
    jsr ar_ym_release
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_trigger
    lda #({1})
    clc
    jsr ar_ym_trigger
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_trigger_no_retrigger
    lda #({1})
    sec
    jsr ar_ym_trigger
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_write
    lda #({2})
    ldx #({1})
    jsr ar_ym_write
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_getatten
    lda #({1})
    jsr ar_ym_getatten
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_getpan
    lda #({1})
    jsr ar_ym_getpan
    ENDM
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    MAC xm_ar_ym_get_chip_type
    jsr ar_ym_get_chip_type
    ENDM
    ENDIF

; =====================================================================
; audio/zsm  (compact ZSM stream player)
; =====================================================================
; -> A = ZSM_ERR_* from the last zsm_init
    IFCONST X16_USE_ZSM
    MAC xm_zsm_lasterr
    jsr zsm_lasterr
    ENDM
    ENDIF
    IFCONST X16_USE_ZSM
    MAC xm_zsm_init
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    jsr zsm_init
    ENDM
    ENDIF
    IFCONST X16_USE_ZSM
    MAC xm_zsm_init_stream
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    jsr zsm_init_stream
    ENDM
    ENDIF
    IFCONST X16_USE_ZSM
    MAC xm_zsm_play
    jsr zsm_play
    ENDM
    ENDIF
    IFCONST X16_USE_ZSM
    MAC xm_zsm_stop
    jsr zsm_stop
    ENDM
    ENDIF
    IFCONST X16_USE_ZSM
    MAC xm_zsm_rewind
    jsr zsm_rewind
    ENDM
    ENDIF
; -> A = low byte, X = high byte
    IFCONST X16_USE_ZSM
    MAC xm_zsm_get_tickrate
    jsr zsm_get_tickrate
    ENDM
    ENDIF
; -> A = ZSM_FLAG_* bits, carry set if active
    IFCONST X16_USE_ZSM
    MAC xm_zsm_status
    jsr zsm_status
    ENDM
    ENDIF
; -> A = ZSM_FLAG_* bits, carry set if active
    IFCONST X16_USE_ZSM
    MAC xm_zsm_tick
    jsr zsm_tick
    ENDM
    ENDIF
; -> carry set if a supported PCM table is present
    IFCONST X16_USE_ZSM_PCM
    MAC xm_zsm_pcm_present
    jsr zsm_pcm_present
    ENDM
    ENDIF
    IFCONST X16_USE_ZSM_PCM
    MAC xm_zsm_pcm_trigger
    lda #({1})
    jsr zsm_pcm_trigger
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
; input/mouse
; =====================================================================
    IFCONST X16_USE_MOUSE
    MAC xm_mse_config
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr mse_config
    ENDM
    ENDIF
    IFCONST X16_USE_MOUSE
    MAC xm_mse_scan
    jsr mse_scan
    ENDM
    ENDIF
; -> P0/1 = x, P2/3 = y, A = buttons, X = wheel delta
    IFCONST X16_USE_MOUSE
    MAC xm_mse_get
    jsr mse_get
    ENDM
    ENDIF
; -> sugar_zp/sugar_zp+1 = x, sugar_zp+2/sugar_zp+3 = y, A = buttons, X = wheel delta
    IFCONST X16_USE_MOUSE
    MAC xm_mse_get_to
    ldx #({1})
    jsr mse_get_to
    ENDM
    ENDIF
    IFCONST X16_USE_MOUSE
    MAC xm_mse_show
    lda #({1})
    jsr mse_show
    ENDM
    ENDIF
    IFCONST X16_USE_MOUSE
    MAC xm_mse_show_keep
    jsr mse_show_keep
    ENDM
    ENDIF
    IFCONST X16_USE_MOUSE
    MAC xm_mse_hide
    jsr mse_hide
    ENDM
    ENDIF

; =====================================================================
; input/keyboard
; =====================================================================
    IFCONST X16_USE_KEYBOARD
    MAC xm_kbd_scan
    jsr kbd_scan
    ENDM
    ENDIF
; -> A = next PETSCII key, X = queued key count, Z set when empty
    IFCONST X16_USE_KEYBOARD
    MAC xm_kbd_peek
    jsr kbd_peek
    ENDM
    ENDIF
    IFCONST X16_USE_KEYBOARD
    MAC xm_kbd_put
    lda #({1})
    jsr kbd_put
    ENDM
    ENDIF
; -> A = KBD_MOD_* bitfield
    IFCONST X16_USE_KEYBOARD
    MAC xm_kbd_get_modifiers
    jsr kbd_get_modifiers
    ENDM
    ENDIF
; -> A = layout index, X/Y = current NUL-terminated layout string
    IFCONST X16_USE_KEYBOARD
    MAC xm_kbd_get_keymap
    jsr kbd_get_keymap
    ENDM
    ENDIF
; -> carry clear on success, carry set on unknown layout
    IFCONST X16_USE_KEYBOARD
    MAC xm_kbd_set_keymap
    ldx #<({1})
    ldy #>({1})
    jsr kbd_set_keymap
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
; storage/iec
; =====================================================================
    IFCONST X16_USE_IEC
    MAC xm_iec_listen
    lda #({1})
    jsr iec_listen
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_talk
    lda #({1})
    jsr iec_talk
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_second
    lda #({1})
    jsr iec_second
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_tksa
    lda #({1})
    jsr iec_tksa
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_ciout
    lda #({1})
    jsr iec_ciout
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_acptr
    jsr iec_acptr
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_unlisten
    jsr iec_unlisten
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_untalk
    jsr iec_untalk
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_set_timeout
    lda #({1})
    jsr iec_set_timeout
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_readst
    jsr iec_readst
    ENDM
    ENDIF
; -> X/Y = bytes read, carry set when unsupported/error
    IFCONST X16_USE_IEC
    MAC xm_iec_macptr
    lda #({2})
    ldx #<({1})
    ldy #>({1})
    jsr iec_macptr
    ENDM
    ENDIF
; -> X/Y = bytes written, carry set when unsupported/error
    IFCONST X16_USE_IEC
    MAC xm_iec_mciout
    lda #({2})
    ldx #<({1})
    ldy #>({1})
    jsr iec_mciout
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_open_channel
    lda #({1})
    ldy #({2})
    jsr iec_open_channel
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_data_channel
    lda #({1})
    ldy #({2})
    jsr iec_data_channel
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_talk_channel
    lda #({1})
    ldy #({2})
    jsr iec_talk_channel
    ENDM
    ENDIF
    IFCONST X16_USE_IEC
    MAC xm_iec_close_channel
    lda #({1})
    ldy #({2})
    jsr iec_close_channel
    ENDM
    ENDIF

; =====================================================================
; storage/fileio
; =====================================================================
    IFCONST X16_USE_FILEIO
    MAC xm_fio_set_lfs
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr fio_set_lfs
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_set_name
    lda #({2})
    ldx #<({1})
    ldy #>({1})
    jsr fio_set_name
    ENDM
    ENDIF
; -> carry set = KERNAL open error
    IFCONST X16_USE_FILEIO
    MAC xm_fio_open_named
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
    lda #({5})
    sta X16_P5
    jsr fio_open_named
    ENDM
    ENDIF
; -> carry set = OPEN or CHKIN error
    IFCONST X16_USE_FILEIO
    MAC xm_fio_open_read
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
    lda #({5})
    sta X16_P5
    jsr fio_open_read
    ENDM
    ENDIF
; -> carry set = OPEN or CHKOUT error
    IFCONST X16_USE_FILEIO
    MAC xm_fio_open_write
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
    lda #({5})
    sta X16_P5
    jsr fio_open_write
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_close
    lda #({1})
    jsr fio_close
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_close_named
    lda #({1})
    sta X16_P3
    jsr fio_close_named
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_chkin
    ldx #({1})
    jsr fio_chkin
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_chkout
    ldx #({1})
    jsr fio_chkout
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_clrchn
    jsr fio_clrchn
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_chrin
    jsr fio_chrin
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_chrout
    lda #({1})
    jsr fio_chrout
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_readst
    jsr fio_readst
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_getin
    jsr fio_getin
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_close_all
    jsr fio_close_all
    ENDM
    ENDIF
    IFCONST X16_USE_FILEIO
    MAC xm_fio_close_device
    lda #({1})
    jsr fio_close_device
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
; -> X/Y = entry address, or $0000 if the file has no BASIC stub
    IFCONST X16_USE_LOAD
    MAC xm_fs_prg_entry
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    jsr fs_prg_entry
    ENDM
    ENDIF

; -> A = BMX_ERR_* from the last bmx_* call, or 0 if it worked
    IFCONST X16_USE_BMX
    MAC xm_bmx_lasterr
    jsr bmx_lasterr
    ENDM
    ENDIF

; =====================================================================
; storage/dir
; =====================================================================
; a length of 0 asks for the current directory; -> carry set = failed
    IFCONST X16_USE_DIR
    MAC xm_dir_open
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    jsr dir_open
    ENDM
    ENDIF
; -> carry SET = an entry was read, CLEAR at the end of the listing
    IFCONST X16_USE_DIR
    MAC xm_dir_next
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    jsr dir_next
    ENDM
    ENDIF

; -> A = DIR_TYPE_PRG / _DIR / _HOST / ... for the entry just read
    IFCONST X16_USE_DIR
    MAC xm_dir_type
    jsr dir_type
    ENDM
    ENDIF
; -> X/Y = the block count for the entry just read
    IFCONST X16_USE_DIR
    MAC xm_dir_blocks
    jsr dir_blocks
    ENDM
    ENDIF
    IFCONST X16_USE_DIR
    MAC xm_dir_close
    jsr dir_close
    ENDM
    ENDIF

; =====================================================================
; ui/filepick
; =====================================================================
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_cache
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    jsr fp_cache
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_filter
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr fp_filter
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_primary
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr fp_primary
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_style
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr fp_style
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_heading
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr fp_heading
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_footing
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr fp_footing
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_saveunder
    lda #<({2})
    sta X16_P0
    lda #>({2})
    sta X16_P1
    lda #({3})
    sta X16_P2
    lda #({1})
    jsr fp_saveunder
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_charset
    lda #({1})
    jsr fp_charset
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_start_dir
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr fp_start_dir
    ENDM
    ENDIF
; -> A = FPK_NONE (cancelled), FPK_PICK (a file), FPK_ALT (the second gesture)
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_open
    jsr fp_open
    ENDM
    ENDIF
; -> A = as fp_open
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_resume
    jsr fp_resume
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_close
    jsr fp_close
    ENDM
    ENDIF
; -> X/Y = the absolute path of the chosen entry
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_path
    jsr fp_path
    ENDM
    ENDIF
; -> X/Y = the chosen entry's name, without the directory
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_name
    jsr fp_name
    ENDM
    ENDIF
; -> X/Y = the directory being browsed
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_dir
    jsr fp_dir
    ENDM
    ENDIF
; -> carry SET when the chosen entry matches the primary pattern
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_is_primary
    jsr fp_is_primary
    ENDM
    ENDIF
; -> carry SET when the name matches the pattern list
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_match
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr fp_match
    ENDM
    ENDIF
; -> A = the panel's first row
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_panel_top
    jsr fp_panel_top
    ENDM
    ENDIF
; -> A = the panel's left column
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_panel_left
    jsr fp_panel_left
    ENDM
    ENDIF
; -> A = the panel's width in cells
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_panel_width
    jsr fp_panel_width
    ENDM
    ENDIF
; -> A = how many entry rows the panel has
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_panel_rows
    jsr fp_panel_rows
    ENDM
    ENDIF
    IFCONST X16_USE_FILEPICK
    MAC xm_fp_redraw
    jsr fp_redraw
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
; -> A = the status code from the last dos_* call
    IFCONST X16_USE_DOS
    MAC xm_dos_lasterr
    jsr dos_lasterr
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
    IFCONST X16_USE_BMX
    MAC xm_bmx_load_hires
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    jsr bmx_load_hires
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
; -> A/X = buffer, Y = length
    IFCONST X16_USE_NUMBER
    MAC xm_u8_to_dec
    lda #({1})
    jsr u8_to_dec
    ENDM
    ENDIF
; -> A/X = buffer, Y = 2
    IFCONST X16_USE_NUMBER
    MAC xm_u8_to_hex
    lda #({1})
    jsr u8_to_hex
    ENDM
    ENDIF
; -> A/X = buffer, Y = 8
    IFCONST X16_USE_NUMBER
    MAC xm_u8_to_bin
    lda #({1})
    jsr u8_to_bin
    ENDM
    ENDIF
; -> A/X = buffer, Y = 16
    IFCONST X16_USE_NUMBER
    MAC xm_u16_to_bin
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr u16_to_bin
    ENDM
    ENDIF
; -> A/X = buffer, Y = length
    IFCONST X16_USE_NUMBER
    MAC xm_s8_to_dec
    lda #({1})
    jsr s8_to_dec
    ENDM
    ENDIF
; -> A/X = buffer, Y = length
    IFCONST X16_USE_NUMBER
    MAC xm_s16_to_dec
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr s16_to_dec
    ENDM
    ENDIF

; =====================================================================
; util/sort  (base pointer + element count; sorts in place)
; =====================================================================
    IFCONST X16_USE_SORT
    MAC xm_sort_u8
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr sort_u8
    ENDM
    ENDIF
    IFCONST X16_USE_SORT
    MAC xm_sort_s8
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr sort_s8
    ENDM
    ENDIF
    IFCONST X16_USE_SORT
    MAC xm_sort_u16
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr sort_u16
    ENDM
    ENDIF
    IFCONST X16_USE_SORT
    MAC xm_sort_s16
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr sort_s16
    ENDM
    ENDIF
    IFCONST X16_USE_SORT
    MAC xm_sort_ptr
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
    jsr sort_ptr
    ENDM
    ENDIF

; =====================================================================
; string/strsort
; =====================================================================
    IFCONST X16_USE_STRING_SORT
    MAC xm_str_sort
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #<({2})
    sta X16_P2
    lda #>({2})
    sta X16_P3
    jsr str_sort
    ENDM
    ENDIF

; =====================================================================
; audio/wavfile
; =====================================================================
; -> carry set on failure; wav_format/channels/rate/bits/data_off/data_len set
    IFCONST X16_USE_WAV
    MAC xm_wav_parse_header
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr wav_parse_header
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
; system/clock
; =====================================================================
; -> A/X/Y = 24-bit 60 Hz timer, low to high
    IFCONST X16_USE_CLOCK
    MAC xm_clock_get_timer
    jsr clock_get_timer
    ENDM
    ENDIF
    IFCONST X16_USE_CLOCK
    MAC xm_clock_set_timer
    lda #<({1})
    ldx #>(({1}) >> 8)
    ldy #>(({1}) >> 16)
    jsr clock_set_timer
    ENDM
    ENDIF
    IFCONST X16_USE_CLOCK
    MAC xm_clock_update
    jsr clock_update
    ENDM
    ENDIF
; -> r0..r3 = year/month/day/hour/min/sec/jiffy/weekday
    IFCONST X16_USE_CLOCK
    MAC xm_clock_get_date_time
    jsr clock_get_date_time
    ENDM
    ENDIF
; sugar_year1900 is the KERNAL byte value: full year minus 1900.
    IFCONST X16_USE_CLOCK
    MAC xm_clock_set_date_time_raw
    lda #<({1})
    sta r0L
    lda #<({2})
    sta r0H
    lda #<({3})
    sta r1L
    lda #<({4})
    sta r1H
    lda #<({5})
    sta r2L
    lda #<({6})
    sta r2H
    lda #<({7})
    sta r3L
    lda #<({8})
    sta r3H
    jsr clock_set_date_time
    ENDM
    ENDIF
; Friendly form: sugar_year is the full year, e.g. 2026; jiffies are set to 0.
    IFCONST X16_USE_CLOCK
    MAC xm_clock_set_date_time
    lda #<(({1}) - 1900)
    sta r0L
    lda #<({2})
    sta r0H
    lda #<({3})
    sta r1L
    lda #<({4})
    sta r1H
    lda #<({5})
    sta r2L
    lda #<({6})
    sta r2H
    stz r3L
    lda #<({7})
    sta r3H
    jsr clock_set_date_time
    ENDM
    ENDIF

; =====================================================================
; comms/i2c
; =====================================================================
; -> A = value, carry set on NAK/error
    IFCONST X16_USE_I2C
    MAC xm_i2c_read_byte
    ldx #({1})
    ldy #({2})
    jsr i2c_read_byte
    ENDM
    ENDIF
; -> carry set on NAK/error
    IFCONST X16_USE_I2C
    MAC xm_i2c_write_byte
    lda #({1})
    ldx #({2})
    ldy #({3})
    jsr i2c_write_byte
    ENDM
    ENDIF
; -> carry set on NAK/error
    IFCONST X16_USE_I2C
    MAC xm_i2c_batch_read
    lda #<({2})
    sta r0
    lda #>({2})
    sta r0+1
    lda #<({3})
    sta r1
    lda #>({3})
    sta r1+1
    ldx #({1})
    clc
    jsr i2c_batch_read
    ENDM
    ENDIF
; -> carry set on NAK/error; reads repeatedly into the same address
    IFCONST X16_USE_I2C
    MAC xm_i2c_batch_read_fixed
    lda #<({2})
    sta r0
    lda #>({2})
    sta r0+1
    lda #<({3})
    sta r1
    lda #>({3})
    sta r1+1
    ldx #({1})
    sec
    jsr i2c_batch_read
    ENDM
    ENDIF
; -> r2 = bytes written, carry set on NAK/error
    IFCONST X16_USE_I2C
    MAC xm_i2c_batch_write
    lda #<({2})
    sta r0
    lda #>({2})
    sta r0+1
    lda #<({3})
    sta r1
    lda #>({3})
    sta r1+1
    ldx #({1})
    jsr i2c_batch_write
    ENDM
    ENDIF

; =====================================================================
; comms/spi  (VERA SPI controller)
; =====================================================================
; -> A = VERA_SPI_* control/status bits
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_get_ctrl
    jsr spi_get_ctrl
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_set_ctrl
    lda #({1})
    jsr spi_set_ctrl
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_select
    jsr spi_select
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_deselect
    jsr spi_deselect
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_slow
    jsr spi_slow
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_fast
    jsr spi_fast
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_autotx_on
    jsr spi_autotx_on
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_autotx_off
    jsr spi_autotx_off
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_wait
    jsr spi_wait
    ENDM
    ENDIF
; -> A = received byte
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_transfer
    lda #({1})
    jsr spi_transfer
    ENDM
    ENDIF
; -> A = received byte
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_read
    jsr spi_read
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_write
    lda #({1})
    jsr spi_write
    ENDM
    ENDIF
; -> A = received byte; starts the next Auto-TX transfer
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_autotx_read
    jsr spi_autotx_read
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_read_bytes
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    jsr spi_read_bytes
    ENDM
    ENDIF
    IFCONST X16_USE_VERA_SPI
    MAC xm_spi_write_bytes
    lda #<({1})
    sta r0L
    lda #>({1})
    sta r0H
    lda #<({2})
    sta r1L
    lda #>({2})
    sta r1H
    jsr spi_write_bytes
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
; -> A = index, or 255 if not found
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

; =====================================================================
; Routines that had no friendly macro until now. Most work on their
; module's accumulator -- FAC, d_ac, i16_a/i16_b, i32_a/i32_b,
; bcd_a/bcd_b, the stack or the queue -- so they take no arguments;
; the rest carry the parameters their own header documents.
; =====================================================================
    IFCONST X16_USE_FLOAT
    MAC xm_f_zero
    jsr f_zero
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_neg
    jsr f_neg
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_abs
    jsr f_abs
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_int
    jsr f_int
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_sgn
    jsr f_sgn
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_to_s16
    jsr f_to_s16
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_sqrt
    jsr f_sqrt
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_ln
    jsr f_ln
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_exp
    jsr f_exp
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_sin
    jsr f_sin
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_cos
    jsr f_cos
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_tan
    jsr f_tan
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_atan
    jsr f_atan
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_to_str
    jsr f_to_str
    ENDM
    ENDIF

    IFCONST X16_USE_FLOAT
    MAC xm_f_to_str_trim
    jsr f_to_str_trim
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_neg
    jsr d_neg
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_abs
    jsr d_abs
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_to_s32
    jsr d_to_s32
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_sqrt
    jsr d_sqrt
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_exp
    jsr d_exp
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_ln
    jsr d_ln
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_sin
    jsr d_sin
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_cos
    jsr d_cos
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_tan
    jsr d_tan
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_atan
    jsr d_atan
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_sinh
    jsr d_sinh
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_cosh
    jsr d_cosh
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_tanh
    jsr d_tanh
    ENDM
    ENDIF

    IFCONST X16_USE_DOUBLE
    MAC xm_d_to_str
    jsr d_to_str
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_add
    jsr i16_add
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_sub
    jsr i16_sub
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_neg
    jsr i16_neg
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_abs
    jsr i16_abs
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_shl
    jsr i16_shl
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_shr
    jsr i16_shr
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_asr
    jsr i16_asr
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_cmpu
    jsr i16_cmpu
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_cmps
    jsr i16_cmps
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_mul
    jsr i16_mul
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_divmod
    jsr i16_divmod
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_divmod_s
    jsr i16_divmod_s
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_sqrt
    jsr i16_sqrt
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_to_dec
    jsr i16_to_dec
    ENDM
    ENDIF

    IFCONST X16_USE_INT16
    MAC xm_i16_to_dec_s
    jsr i16_to_dec_s
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_to_s16
    jsr i32_to_s16
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_add
    jsr i32_add
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_sub
    jsr i32_sub
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_neg
    jsr i32_neg
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_abs
    jsr i32_abs
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_shl
    jsr i32_shl
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_shr
    jsr i32_shr
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_asr
    jsr i32_asr
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_cmpu
    jsr i32_cmpu
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_cmps
    jsr i32_cmps
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_mul
    jsr i32_mul
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_divmod
    jsr i32_divmod
    ENDM
    ENDIF

    IFCONST X16_USE_INT32
    MAC xm_i32_to_dec
    jsr i32_to_dec
    ENDM
    ENDIF

    IFCONST X16_USE_BCD
    MAC xm_bcd_add8
    jsr bcd_add8
    ENDM
    ENDIF

    IFCONST X16_USE_BCD
    MAC xm_bcd_add16
    jsr bcd_add16
    ENDM
    ENDIF

    IFCONST X16_USE_BCD
    MAC xm_bcd_add32
    jsr bcd_add32
    ENDM
    ENDIF

    IFCONST X16_USE_BCD
    MAC xm_bcd_sub8
    jsr bcd_sub8
    ENDM
    ENDIF

    IFCONST X16_USE_BCD
    MAC xm_bcd_sub16
    jsr bcd_sub16
    ENDM
    ENDIF

    IFCONST X16_USE_BCD
    MAC xm_bcd_sub32
    jsr bcd_sub32
    ENDM
    ENDIF

    IFCONST X16_USE_STACK
    MAC xm_stack_pop
    jsr stack_pop
    ENDM
    ENDIF

    IFCONST X16_USE_STACK
    MAC xm_stack_popw
    jsr stack_popw
    ENDM
    ENDIF

    IFCONST X16_USE_STACK
    MAC xm_stack_size
    jsr stack_size
    ENDM
    ENDIF

    IFCONST X16_USE_STACK
    MAC xm_stack_free
    jsr stack_free
    ENDM
    ENDIF

    IFCONST X16_USE_STACK
    MAC xm_stack_isempty
    jsr stack_isempty
    ENDM
    ENDIF

    IFCONST X16_USE_STACK
    MAC xm_stack_isfull
    jsr stack_isfull
    ENDM
    ENDIF

    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_get
    jsr ring_get
    ENDM
    ENDIF

    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_getw
    jsr ring_getw
    ENDM
    ENDIF

    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_size
    jsr ring_size
    ENDM
    ENDIF

    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_free
    jsr ring_free
    ENDM
    ENDIF

    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_isempty
    jsr ring_isempty
    ENDM
    ENDIF

    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_isfull
    jsr ring_isfull
    ENDM
    ENDIF

    IFCONST X16_USE_PCM
    MAC xm_pcm_full
    jsr pcm_full
    ENDM
    ENDIF

    IFCONST X16_USE_PCM
    MAC xm_pcm_empty
    jsr pcm_empty
    ENDM
    ENDIF

    IFCONST X16_USE_PCM_STREAM
    MAC xm_pcm_stream_active
    jsr pcm_stream_active
    ENDM
    ENDIF

    IFCONST X16_USE_YM
    MAC xm_ym_busy
    jsr ym_busy
    ENDM
    ENDIF

    IFCONST X16_USE_BANK
    MAC xm_bank_get
    jsr bank_get
    ENDM
    ENDIF

    IFCONST X16_USE_IRQ_ANY
    MAC xm_irq_line_remove
    jsr irq_line_remove
    ENDM
    ENDIF

    IFCONST X16_USE_IRQ_ANY
    MAC xm_irq_save_regs
    jsr irq_save_regs
    ENDM
    ENDIF

    IFCONST X16_USE_IRQ_ANY
    MAC xm_irq_restore_regs
    jsr irq_restore_regs
    ENDM
    ENDIF

    IFCONST X16_USE_IRQ_ANY
    MAC xm_irq_frames
    jsr irq_frames
    ENDM
    ENDIF

    IFCONST X16_USE_IRQ_SPRCOL_API
    MAC xm_sprite_collisions
    jsr sprite_collisions
    ENDM
    ENDIF

    IFCONST X16_USE_CLIP
    MAC xm_clip_line
    jsr clip_line
    ENDM
    ENDIF

    IFCONST X16_USE_VERAFX_TRI
    MAC xm_fx_triangle
    jsr fx_triangle
    ENDM
    ENDIF

    IFCONST X16_USE_MATH
    MAC xm_rnd16
    jsr rnd16
    ENDM
    ENDIF

    IFCONST X16_USE_SCREEN_EXTRA
    MAC xm_screen_get_mode
    jsr screen_get_mode
    ENDM
    ENDIF

    IFCONST X16_USE_SCREEN_EXTRA
    MAC xm_screen_get_cursor
    jsr screen_get_cursor
    ENDM
    ENDIF

    IFCONST X16_USE_VERA_FXPROBE
    MAC xm_vera_has_fx
    jsr vera_has_fx
    ENDM
    ENDIF

    IFCONST X16_USE_FILEIO
    MAC xm_fio_open
    jsr fio_open
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isdigit
    lda #({1})
    jsr str_isdigit
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isxdigit
    lda #({1})
    jsr str_isxdigit
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_islower
    lda #({1})
    jsr str_islower
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isupper
    lda #({1})
    jsr str_isupper
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isupper_iso
    lda #({1})
    jsr str_isupper_iso
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isletter
    lda #({1})
    jsr str_isletter
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isletter_iso
    lda #({1})
    jsr str_isletter_iso
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isspace
    lda #({1})
    jsr str_isspace
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isprint
    lda #({1})
    jsr str_isprint
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CTYPE
    MAC xm_str_isprint_iso
    lda #({1})
    jsr str_isprint_iso
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CASE
    MAC xm_str_lowerchar
    lda #({1})
    jsr str_lowerchar
    ENDM
    ENDIF

    IFCONST X16_USE_STRING_CASE
    MAC xm_str_upperchar
    lda #({1})
    jsr str_upperchar
    ENDM
    ENDIF

    IFCONST X16_USE_STACK
    MAC xm_stack_init
    lda #({1})
    jsr stack_init
    ENDM
    ENDIF

    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_init
    lda #({1})
    jsr ring_init
    ENDM
    ENDIF

    IFCONST X16_USE_STACK
    MAC xm_stack_push
    lda #({1})
    jsr stack_push
    ENDM
    ENDIF

    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_put
    lda #({1})
    jsr ring_put
    ENDM
    ENDIF

    IFCONST X16_USE_YM
    MAC xm_ym_get_pan
    lda #({1})
    jsr ym_get_pan
    ENDM
    ENDIF

    IFCONST X16_USE_YM
    MAC xm_ym_get_vol
    lda #({1})
    jsr ym_get_vol
    ENDM
    ENDIF

; push one word (low byte first, then high)
    IFCONST X16_USE_STACK
    MAC xm_stack_pushw
    lda #<({1})
    ldx #>({1})
    jsr stack_pushw
    ENDM
    ENDIF

; enqueue one word (low byte first)
    IFCONST X16_USE_RINGBUFFER
    MAC xm_ring_putw
    lda #<({1})
    ldx #>({1})
    jsr ring_putw
    ENDM
    ENDIF

; add bcd_b to a 4-byte BCD value in place
    IFCONST X16_USE_BCD
    MAC xm_bcd_addto
    lda #<({1})
    ldx #>({1})
    jsr bcd_addto
    ENDM
    ENDIF

; subtract bcd_b from a 4-byte BCD value in place
    IFCONST X16_USE_BCD
    MAC xm_bcd_subfrom
    lda #<({1})
    ldx #>({1})
    jsr bcd_subfrom
    ENDM
    ENDIF

; FAC = mem ^ FAC (the ROM's operand order)
    IFCONST X16_USE_FLOAT
    MAC xm_f_rpow
    lda #<({1})
    ldy #>({1})
    jsr f_rpow
    ENDM
    ENDIF

; d_ac = the signed 32-bit little-endian value at addr
    IFCONST X16_USE_DOUBLE
    MAC xm_d_from_s32
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr d_from_s32
    ENDM
    ENDIF

; tile data base for a layer (base>>11<<2 | tile size bits)
    IFCONST X16_USE_TILE
    MAC xm_layer_set_tilebase
    ldx #({1})
    lda #({2})
    jsr layer_set_tilebase
    ENDM
    ENDIF

; set (sugar_set != 0) or clear (sugar_set = 0) the masked bits at addr
    IFCONST X16_USE_BITS
    MAC xm_bit_put
    lda #<({1})
    sta X16_PTR0
    lda #>({1})
    sta X16_PTR0+1
    ldx #({3})
    lda #({2})
    jsr bit_put
    ENDM
    ENDIF

; load an instrument from a patch in RAM (the ROM-index form is xm_ym_patch_rom)
    IFCONST X16_USE_YM
    MAC xm_ym_patch_ram
    clc
    ldx #<({2})
    ldy #>({2})
    lda #({1})
    jsr ym_patch
    ENDM
    ENDIF

; make a directory
    IFCONST X16_USE_DOS
    MAC xm_dos_mkdir
    lda #<({1})
    ldx #>({1})
    ldy #({2})
    jsr dos_mkdir
    ENDM
    ENDIF

; remove a directory
    IFCONST X16_USE_DOS
    MAC xm_dos_rmdir
    lda #<({1})
    ldx #>({1})
    ldy #({2})
    jsr dos_rmdir
    ENDM
    ENDIF

; change directory ("//" is the root)
    IFCONST X16_USE_DOS
    MAC xm_dos_chdir
    lda #<({1})
    ldx #>({1})
    ldy #({2})
    jsr dos_chdir
    ENDM
    ENDIF

; rename oldname to newname
    IFCONST X16_USE_DOS
    MAC xm_dos_rename
    lda #<({3})
    sta X16_P0
    lda #>({3})
    sta X16_P1
    lda #({4})
    sta X16_P2
    lda #<({1})
    ldx #>({1})
    ldy #({2})
    jsr dos_rename
    ENDM
    ENDIF

; copy banked RAM to low RAM, advancing across bank boundaries
    IFCONST X16_USE_BANK
    MAC xm_bank_to_mem
    lda #<({2})
    sta X16_P1
    lda #>({2})
    sta X16_P2
    lda #<({3})
    sta X16_P3
    lda #>({3})
    sta X16_P4
    lda #<({4})
    sta X16_P5
    lda #>({4})
    sta X16_P6
    lda #({1})
    sta X16_P0
    jsr bank_to_mem
    ENDM
    ENDIF

; copy banked RAM to banked RAM
    IFCONST X16_USE_BANK
    MAC xm_bank_copy_far
    lda #<({2})
    sta X16_P1
    lda #>({2})
    sta X16_P2
    lda #<({4})
    sta X16_P4
    lda #>({4})
    sta X16_P5
    lda #<({5})
    sta X16_P6
    lda #>({5})
    sta X16_P7
    lda #({3})
    sta X16_P3
    lda #({1})
    sta X16_P0
    jsr bank_copy_far
    ENDM
    ENDIF

; save a block of memory as a PRG
    IFCONST X16_USE_LOAD
    MAC xm_fs_save
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    lda #({2})
    sta X16_P2
    lda #({3})
    sta X16_P3
    lda #<({4})
    sta X16_P5
    lda #>({4})
    sta X16_P6
    lda #<({5})
    sta X16_T6
    lda #>({5})
    sta X16_T7
    jsr fs_save
    ENDM
    ENDIF

; write a BMX file from VRAM (bmx_width/height/bpp/... describe the image)
    IFCONST X16_USE_BMX
    MAC xm_bmx_save
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
    jsr bmx_save
    ENDM
    ENDIF

; play a sample living in banked RAM (count is 24-bit: low word, then high byte)
    IFCONST X16_USE_PCM_STREAM
    MAC xm_pcm_stream_start_bank
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
    jsr pcm_stream_start_bank
    ENDM
    ENDIF

; VRAM to VRAM through the 32-bit cache; the destination must be 4-byte aligned
    IFCONST X16_USE_VERAFX_COPY
    MAC xm_fx_copy
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
    lda #({4})
    sta X16_P5
    lda #<({5})
    sta X16_P6
    lda #>({5})
    sta X16_P7
    jsr fx_copy
    ENDM
    ENDIF

; enter affine mode and describe the texture
    IFCONST X16_USE_VERAFX_AFFINE
    MAC xm_fx_affine_on
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
    lda #({4})
    sta X16_P5
    lda #({5})
    sta X16_P6
    lda #({6})
    sta X16_P7
    jsr fx_affine_on
    ENDM
    ENDIF

; aim the sampler (dx/dy signed, 1/512 texel units)
    IFCONST X16_USE_VERAFX_AFFINE
    MAC xm_fx_affine_ray
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
    jsr fx_affine_ray
    ENDM
    ENDIF

; fetch texels along the ray into VRAM; port 0 must already point at the destination
    IFCONST X16_USE_VERAFX_AFFINE
    MAC xm_fx_affine_span
    lda #<({1})
    sta X16_P0
    lda #>({1})
    sta X16_P1
    jsr fx_affine_span
    ENDM
    ENDIF
