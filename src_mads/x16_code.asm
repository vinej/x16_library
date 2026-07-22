;ACME
; =====================================================================
; x16lib :: x16_code.asm -- the library routines
; =====================================================================
; Source this EXACTLY ONCE, at the point in your program where you want
; the library's machine code to sit (normally after your own code).
;
; ACME has no linker, so unused routines cannot be stripped for you.
; Instead, pick the modules you need by defining X16_USE_* before
; sourcing this file -- or define X16_USE_ALL to pull in everything.
;
;       X16_USE_VERA = 1
;       !source "x16_code.asm"
;
; or from the build script:  acme -DX16_USE_ALL=1 ...
;
; These gates must be resolvable on the FIRST pass, so always define
; them ahead of this !source, never after it.
; ---------------------------------------------------------------------
; Module            Provides
;   X16_USE_VERA      vera_set_addr0/1, vera_fill, vera_copy, vera_has_fx
;   X16_USE_SCREEN    screen_set_mode/get_mode/reset/cls/chrout/color/
;                     border, screen_locate, screen_get_cursor,
;                     screen_charset, screen_puts
;   X16_USE_PALETTE   pal_set, pal_load
;   X16_USE_TILE      layer_on/off, layer_set_config/mapbase/tilebase,
;                     layer_scroll_x/y, tile_setptr, tile_put, tile_get
;   X16_USE_SPRITE    sprites_on/off, sprite_pos, sprite_get_pos,
;                     sprite_image, sprite_flags, sprite_z, sprite_size,
;                     sprite_init_all
;   X16_USE_BITMAP    gfx_init, gfx_clear, gfx_read, gfx_pset,
;                     gfx_pattern_set, gfx_pattern_rect, gfx_blit,
;                     gfx_blitm (colour-key), gfx_hline,
;                     gfx_vline, gfx_rect, gfx_frame, gfx_line,
;                     gfx_char, gfx_text (circle/disc/flood are in
;                     X16_USE_SHAPES now, shared with gfx2)
;   X16_USE_BITMAP2   gfx2_init, gfx2_clear, gfx2_setptr, gfx2_pset,
;                     gfx2_read, gfx2_hline, gfx2_vline, gfx2_rect,
;                     gfx2_frame, gfx2_line, gfx2_pattern_set,
;                     gfx2_pattern_rect, gfx2_blit, gfx2_blitm
;                     (640x480@2bpp; pulls in VERA and VERAFX)
;   X16_USE_SHAPES    shape_circle, shape_disc, shape_ellipse,
;                     shape_fellipse, shape_flood -- engine-
;                     agnostic: they draw through SHP_PSET/SHP_READ/
;                     SHP_HLINE (+ SHP_W/SHP_H bounds), which default to
;                     the 2bpp module; predefine them to bind any engine
;   X16_USE_SHAPES_POLY  + shape_polygon, shape_fpolygon (regular convex
;                     N-gons, outline and filled; pulls in MATH for the
;                     sin8/cos8 vertex placement)
;   X16_USE_SHAPES_RRECT + shape_rrect, shape_frrect (rounded rectangle,
;                     outline and filled; self-contained, no trig)
;   X16_USE_SHAPES_ARC   + shape_arc (a portion of a circle outline
;                     between two byte-angles; pulls MATH + the shared
;                     line helper X16_USE_SHP_LINE)
;   X16_USE_SHAPES_PIE   + shape_pie (a filled wedge from the centre to
;                     the arc; pulls in SHAPES_ARC)
;   X16_USE_SHAPES_BEZIER + shape_bezier (a cubic Bezier curve through
;                     four control points; pulls the shared line helper)
;   X16_USE_VERAFX    all of the below, as it always has been
;     _MULT           fx_mult
;     _FILL           fx_fill, fx_clear
;     _COPY           fx_copy
;     _TRANSP         fx_transp_on/off
;     _AFFINE         fx_affine_on/ray/span (rotozoom sampling)
;     _LINE           fx_line
;     _TRI            fx_triangle
;                     fx_off comes with any of them. The parts exist
;                     because the whole is 2.5 KB and a program that
;                     wants one fast fill should not carry a rotozoom
;                     sampler to get it: BITMAP2 asks for _FILL alone
;                     and is 2,162 bytes lighter for it.
;   X16_USE_IRQ       irq_install, irq_remove, irq_frames, vsync_wait,
;                     irq_line_install/remove, irq_sprcol_install/
;                     remove, sprite_collisions
;   X16_USE_PSG       psg_init, psg_set_freq/vol/wave, psg_note_off,
;                     psg_env_start/release/stop/tick (ASR envelopes)
;   X16_USE_YM        ym_write, ym_busy, ym_init, ym_poke, ym_patch,
;                     ym_note, ym_note_bas, ym_release_note, ym_vol,
;                     ym_pan, ym_drum, ym_get_pan, ym_get_vol
;   X16_USE_PCM       pcm_ctrl, pcm_rate, pcm_reset, pcm_full/empty,
;                     pcm_put, pcm_write
;   X16_USE_PCM_STREAM  pcm_stream_start/stop/active (AFLOW-driven;
;                     pulls in PCM and IRQ)
;   X16_USE_INPUT     joy_scan, joy_get, mouse_show/hide/get,
;                     key_get, key_wait, key_peek
;   X16_USE_SERIAL    ser_detect, ser_init, ser_avail, ser_get,
;                     ser_get_wait, ser_put, ser_puts, ser_write,
;                     ser_read_until, ser_discard_until -- the serial /
;                     WiFi card's 16C550 UARTs at $9F60/$9F68
;   X16_USE_SERIAL_ZIMODEM  + zi_init, zi_cmd, zi_wait_ok, zi_reset,
;                     zi_get_ip, zi_hex_open/chunk/close, zi_hexdecode --
;                     the ESP32 WiFi modem (ZiModem AT commands) on top of
;                     SERIAL
;   X16_USE_BANK      bank_set/get, bank_peek/poke, mem_to_bank,
;                     bank_to_mem, bank_copy_far
;   X16_USE_BANKALLOC bank_alloc_init, bank_alloc, bank_free,
;                     bank_reserve
;   X16_USE_STACK     stack_init(bank), stack_push/pushw/pop/popw,
;                     stack_size/free/isempty/isfull -- an 8 KB LIFO in a
;                     HIRAM bank (the 256-byte stk_* live in BUFFERS)
;   X16_USE_RINGBUFFER ring_init(bank), ring_put/putw/get/getw,
;                     ring_size/free/isempty/isfull -- an 8 KB FIFO in a
;                     HIRAM bank (the 256-byte rb_* live in BUFFERS)
;   X16_USE_MEM       mem_fill, mem_copy, mem_crc, mem_decompress
;                     (KERNAL block ops; they stream to/from VERA too)
;   X16_USE_LOAD      fs_setname, fs_load, fs_save, fs_vload
;   X16_USE_DOS       dos_cmd, dos_status, dos_delete, dos_rename,
;                     dos_mkdir, dos_rmdir, dos_chdir
;   X16_USE_BMX       bmx_load, bmx_save (the X16's native bitmap
;                     format: header + palette + pixels)
;   X16_USE_MATH      rnd_seed/rnd8/rnd16, sin8/cos8 (+u), atan2, lerp8
;   X16_USE_CLIP      clip_set, clip_line (Cohen-Sutherland, feeds
;                     gfx_line/fx_line's parameter block)
;   X16_USE_BUFFERS   rb_init/put/get/count, stk_init/push/pop/depth
;   X16_USE_ADPCM     adpcm_init, adpcm_nibble, adpcm_block (IMA 4:1)
;   X16_USE_ZX0       zx0_decompress (tighter than the ROM's LZSA2)
;   X16_USE_TSC       tsc_decompress (TSCrunch: faster unpack)
;   X16_USE_FIXED     umul16, mul88
;   X16_USE_BCD       bcd_add8/16/32, bcd_sub8/16/32, bcd_addto,
;                     bcd_subfrom -- packed-BCD (decimal-mode) arithmetic
;   X16_USE_COLLIDE   collide8, collide16
;   X16_USE_BITS      catnib, hinib, lonib, bit_set/clr/put/test
;   X16_USE_NUMBER    u16_to_dec, u16_to_hex, dec_to_u16
;   X16_USE_INT16     i16_add/sub/neg/abs/mul/divmod/divmod_s,
;                     i16_cmps/cmpu, i16_shl/shr/asr, i16_sqrt,
;                     i16_to_dec/dec_s, +i16_const   (needs NUMBER)
;   X16_USE_INT32     i32_add/sub/neg/abs/mul/divmod, i32_cmps/cmpu,
;                     i32_shl/shr/asr, i32_from_u16/s16, i32_to_s16,
;                     i32_to_dec, +i32_const
;   X16_USE_FLOAT     f_load/store, f_add/sub/mul/div, f_rsub/rdiv,
;                     f_pow, f_cmp, f_sqrt, f_ln, f_exp, f_sin, f_cos,
;                     f_tan, f_atan, f_from_s16/u8/str, f_to_s16/str
;   X16_USE_DOUBLE    64-bit software binary64 (~15-16 digits) on a d_ac
;                     accumulator -- a scientific calculator core with
;                     decimal I/O: d_load/store, d_from_s16/s32, d_to_s32,
;                     d_neg/abs, d_cmp, d_add/sub/mul/div, d_from_str,
;                     d_to_str, d_sqrt, d_exp, d_ln, d_pow, d_sin, d_cos,
;                     d_tan, d_atan, d_sinh, d_cosh, d_tanh
;   X16_USE_STRING    str_length, str_copy, str_ncopy, str_append,
;                     str_nappend, str_compare, str_hash -- NUL-terminated
;                     string fundamentals (string/string.asm)
;   X16_USE_STRING_CTYPE  str_isdigit/isxdigit/islower/isspace and
;                     isupper/isletter/isprint (+ _iso) -- char predicates
;   X16_USE_STRING_CASE   str_lower/upper/lowerchar/upperchar (+ _iso),
;                     str_compare_nocase (+ _iso) -- case folding
;   X16_USE_STRING_FIND   str_find, str_rfind, str_find_eol, str_contains,
;                     str_pattern_match -- searching
;   X16_USE_STRING_SLICE  str_left, str_right, str_slice -- substrings
;                     (the five string gates are independent; set what you
;                      use. Number<->string conversion stays in NUMBER,
;                      INT16/INT32, FLOAT, DOUBLE.)
; =====================================================================

; Gates are set with !ifndef so that asking for a module twice -- say via
; X16_USE_ALL and again through a dependency -- is not a redefinition
; error, and so an explicit X16_USE_* in your program still works.
.if .def X16_USE_ALL
    .if !.def X16_USE_VERA
    X16_USE_VERA = 1
    .endif
    .if !.def X16_USE_SCREEN
    X16_USE_SCREEN = 1
    .endif
    .if !.def X16_USE_PALETTE
    X16_USE_PALETTE = 1
    .endif
    .if !.def X16_USE_TILE
    X16_USE_TILE = 1
    .endif
    .if !.def X16_USE_SPRITE
    X16_USE_SPRITE = 1
    .endif
    .if !.def X16_USE_BITMAP
    X16_USE_BITMAP = 1
    .endif
    .if !.def X16_USE_BITMAP2
    X16_USE_BITMAP2 = 1
    .endif
    .if !.def X16_USE_VERAFX
    X16_USE_VERAFX = 1
    .endif
    .if !.def X16_USE_IRQ
    X16_USE_IRQ = 1
    .endif
    .if !.def X16_USE_PSG
    X16_USE_PSG = 1
    .endif
    .if !.def X16_USE_YM
    X16_USE_YM = 1
    .endif
    .if !.def X16_USE_PCM
    X16_USE_PCM = 1
    .endif
    .if !.def X16_USE_PCM_STREAM
    X16_USE_PCM_STREAM = 1
    .endif
    .if !.def X16_USE_INPUT
    X16_USE_INPUT = 1
    .endif
    .if !.def X16_USE_BANK
    X16_USE_BANK = 1
    .endif
    .if !.def X16_USE_BANKALLOC
    X16_USE_BANKALLOC = 1
    .endif
    .if !.def X16_USE_MEM
    X16_USE_MEM = 1
    .endif
    .if !.def X16_USE_LOAD
    X16_USE_LOAD = 1
    .endif
    .if !.def X16_USE_DOS
    X16_USE_DOS = 1
    .endif
    .if !.def X16_USE_BMX
    X16_USE_BMX = 1
    .endif
    .if !.def X16_USE_MATH
    X16_USE_MATH = 1
    .endif
    .if !.def X16_USE_CLIP
    X16_USE_CLIP = 1
    .endif
    .if !.def X16_USE_BUFFERS
    X16_USE_BUFFERS = 1
    .endif
    .if !.def X16_USE_ADPCM
    X16_USE_ADPCM = 1
    .endif
    .if !.def X16_USE_ZX0
    X16_USE_ZX0 = 1
    .endif
    .if !.def X16_USE_TSC
    X16_USE_TSC = 1
    .endif
    .if !.def X16_USE_FIXED
    X16_USE_FIXED = 1
    .endif
    .if !.def X16_USE_COLLIDE
    X16_USE_COLLIDE = 1
    .endif
    .if !.def X16_USE_BITS
    X16_USE_BITS = 1
    .endif
    .if !.def X16_USE_NUMBER
    X16_USE_NUMBER = 1
    .endif
    .if !.def X16_USE_INT16
    X16_USE_INT16 = 1
    .endif
    .if !.def X16_USE_INT32
    X16_USE_INT32 = 1
    .endif
    .if !.def X16_USE_FLOAT
    X16_USE_FLOAT = 1
    .endif
.endif

; --- dependencies ----------------------------------------------------
; sprite_init_all, psg_init, gfx_clear and gfx_hline all call vera_fill.
; gfx_init calls screen_set_mode. The PCM streamer's AFLOW service runs
; inside irq_handler, so it needs the IRQ module (and PCM itself).
.if .def X16_USE_SPRITE
    .if !.def X16_USE_VERA
    X16_USE_VERA = 1
    .endif
.endif
.if .def X16_USE_PSG
    .if !.def X16_USE_VERA
    X16_USE_VERA = 1
    .endif
.endif
.if .def X16_USE_INT16
    .if !.def X16_USE_NUMBER
    X16_USE_NUMBER = 1
    .endif
.endif
.if .def X16_USE_BITMAP
    .if !.def X16_USE_VERA
    X16_USE_VERA = 1
    .endif
    .if !.def X16_USE_SCREEN
    X16_USE_SCREEN = 1
    .endif
.endif
.if .def X16_USE_SHAPES_POLY
    .if !.def X16_USE_SHAPES
    X16_USE_SHAPES = 1
    .endif
    .if !.def X16_USE_MATH
    X16_USE_MATH = 1
    .endif
.endif
; The curve shapes. PIE reuses ARC's trig point helper, so it pulls ARC;
; ARC and BEZIER share one 16-bit Bresenham (the internal X16_USE_SHP_LINE).
; Ordered so a pulled gate's own dependencies still get a turn below it:
; PIE sets ARC, then ARC sets MATH + SHP_LINE, then SHP_LINE sets SHAPES.
.if .def X16_USE_SHAPES_PIE
    .if !.def X16_USE_SHAPES
    X16_USE_SHAPES = 1
    .endif
    .if !.def X16_USE_SHAPES_ARC
    X16_USE_SHAPES_ARC = 1
    .endif
.endif
.if .def X16_USE_SHAPES_ARC
    .if !.def X16_USE_SHAPES
    X16_USE_SHAPES = 1
    .endif
    .if !.def X16_USE_MATH
    X16_USE_MATH = 1
    .endif
    .if !.def X16_USE_SHP_LINE
    X16_USE_SHP_LINE = 1
    .endif
.endif
.if .def X16_USE_SHAPES_RRECT
    .if !.def X16_USE_SHAPES
    X16_USE_SHAPES = 1
    .endif
.endif
.if .def X16_USE_SHAPES_BEZIER
    .if !.def X16_USE_SHAPES
    X16_USE_SHAPES = 1
    .endif
    .if !.def X16_USE_SHP_LINE
    X16_USE_SHP_LINE = 1
    .endif
.endif
.if .def X16_USE_SHP_LINE
    .if !.def X16_USE_SHAPES
    X16_USE_SHAPES = 1
    .endif
.endif
.if .def X16_USE_SHAPES
    .if !.def SHP_PSET
        .if !.def X16_USE_BITMAP2
        X16_USE_BITMAP2 = 1
        .endif
.endif
.endif
; util/double.asm stands alone (no module dependencies). This otherwise
; empty gate block is what makes the 64tass gate-model generator register
; xuse_double -- it scans the dependency section here, not the module
; !source lines below. DOUBLE is deliberately kept OUT of X16_USE_ALL so
; the dist blob stays under the $9EFF low-RAM ceiling.
.if .def X16_USE_DOUBLE
.endif
; comms/serial.asm stands alone too -- same empty-block trick to register
; xuse_serial in the 64tass gate model. Kept OUT of X16_USE_ALL / the dist
; blob: it drives a specific add-on card, so you enable the gate to pay for
; it, and a program that never talks serial carries none of it.
.if .def X16_USE_SERIAL
.endif
; comms/zimodem.asm layers the ESP32 WiFi AT-command protocol over SERIAL.
; Also pay-per-use (out of X16_USE_ALL); pulls SERIAL in.
.if .def X16_USE_SERIAL_ZIMODEM
    .if !.def X16_USE_SERIAL
    X16_USE_SERIAL = 1
    .endif
.endif
; util/bcd.asm stands alone (decimal-mode add/sub). Empty block registers
; xuse_bcd in the 64tass gate model; kept OUT of X16_USE_ALL (pay-per-use).
.if .def X16_USE_BCD
.endif
; storage/stack.asm and storage/ringbuffer.asm each own an 8 KB HIRAM bank.
; Standalone; empty blocks register xuse_stack / xuse_ringbuffer in the
; 64tass gate model. Both pay-per-use (out of X16_USE_ALL).
.if .def X16_USE_STACK
.endif
.if .def X16_USE_RINGBUFFER
.endif
; The five string/ modules are independent and self-contained; these empty
; blocks register their gates in the 64tass gate model. All pay-per-use.
.if .def X16_USE_STRING
.endif
.if .def X16_USE_STRING_CTYPE
.endif
.if .def X16_USE_STRING_CASE
.endif
.if .def X16_USE_STRING_FIND
.endif
.if .def X16_USE_STRING_SLICE
.endif
.if .def X16_USE_BITMAP2
    .if !.def X16_USE_VERA
    X16_USE_VERA = 1
    .endif
    .if !.def X16_USE_VERAFX_FILL
    X16_USE_VERAFX_FILL = 1
    .endif
.endif

; --- VERAFX's parts --------------------------------------------------
; X16_USE_VERAFX still means all of it, so nothing that exists breaks.
; The sub-gates are for programs that want one part and not 2.5 KB of
; the others: gfx2 asks for FILL alone and saves 2,162 bytes by it.
; Every part leaves FX through fx_off, so _ANY carries it.
.if .def X16_USE_VERAFX
    .if !.def X16_USE_VERAFX_MULT
    X16_USE_VERAFX_MULT = 1
    .endif
    .if !.def X16_USE_VERAFX_FILL
    X16_USE_VERAFX_FILL = 1
    .endif
    .if !.def X16_USE_VERAFX_COPY
    X16_USE_VERAFX_COPY = 1
    .endif
    .if !.def X16_USE_VERAFX_TRANSP
    X16_USE_VERAFX_TRANSP = 1
    .endif
    .if !.def X16_USE_VERAFX_AFFINE
    X16_USE_VERAFX_AFFINE = 1
    .endif
    .if !.def X16_USE_VERAFX_LINE
    X16_USE_VERAFX_LINE = 1
    .endif
    .if !.def X16_USE_VERAFX_TRI
    X16_USE_VERAFX_TRI = 1
    .endif
.endif
.if .def X16_USE_VERAFX_MULT
    .if !.def X16_USE_VERAFX_ANY
    X16_USE_VERAFX_ANY = 1
    .endif
.endif
.if .def X16_USE_VERAFX_FILL
    .if !.def X16_USE_VERAFX_ANY
    X16_USE_VERAFX_ANY = 1
    .endif
.endif
.if .def X16_USE_VERAFX_COPY
    .if !.def X16_USE_VERAFX_ANY
    X16_USE_VERAFX_ANY = 1
    .endif
.endif
.if .def X16_USE_VERAFX_TRANSP
    .if !.def X16_USE_VERAFX_ANY
    X16_USE_VERAFX_ANY = 1
    .endif
.endif
.if .def X16_USE_VERAFX_AFFINE
    .if !.def X16_USE_VERAFX_ANY
    X16_USE_VERAFX_ANY = 1
    .endif
.endif
.if .def X16_USE_VERAFX_LINE
    .if !.def X16_USE_VERAFX_ANY
    X16_USE_VERAFX_ANY = 1
    .endif
.endif
.if .def X16_USE_VERAFX_TRI
    .if !.def X16_USE_VERAFX_ANY
    X16_USE_VERAFX_ANY = 1
    .endif
.endif
; LINE and TRI share verafx.asm's x16_code_udiv24 / x16_code_pix_addr helpers; either
; one carries them (internal gate, not meant to be set by programs).
.if .def X16_USE_VERAFX_LINE
    .if !.def X16_USE_VERAFX_LINETRI
    X16_USE_VERAFX_LINETRI = 1
    .endif
.endif
.if .def X16_USE_VERAFX_TRI
    .if !.def X16_USE_VERAFX_LINETRI
    X16_USE_VERAFX_LINETRI = 1
    .endif
.endif
.if .def X16_USE_PCM_STREAM
    .if !.def X16_USE_PCM
    X16_USE_PCM = 1
    .endif
    .if !.def X16_USE_IRQ
    X16_USE_IRQ = 1
    .endif
.endif

; --- split modules ---------------------------------------------------
; Same shape as VERAFX above: the umbrella gate still means the whole
; module, so nothing that exists breaks; a program that wants the core
; and not a rarely-used extra sets the _CORE gate and leaves the extra
; out. _ANY sources the file.
;   VERA   core = set_addr/fill/has_fx;   _COPY   = vera_copy
;   IRQ    core = install/line/frames/handler; _VSYNC = vsync_wait;
;          _SPRCOL = collision capture (handler accumulate + mask);
;          _SPRCOL_API = install/remove/sprite_collisions/callback
;   INPUT  core = mouse/joy/key_get;      _KEYWAIT = key_wait/key_peek
;   SCREEN core = set_mode/reset/cls/chrout/color/locate;
;          _EXTRA = get_mode/border/get_cursor/charset/puts
.if .def X16_USE_VERA
    .if !.def X16_USE_VERA_CORE
    X16_USE_VERA_CORE = 1
    .endif
    .if !.def X16_USE_VERA_COPY
    X16_USE_VERA_COPY = 1
    .endif
.endif
.if .def X16_USE_VERA_CORE
    .if !.def X16_USE_VERA_ANY
    X16_USE_VERA_ANY = 1
    .endif
.endif
.if .def X16_USE_VERA_COPY
    .if !.def X16_USE_VERA_ANY
    X16_USE_VERA_ANY = 1
    .endif
.endif
.if .def X16_USE_IRQ
    .if !.def X16_USE_IRQ_CORE
    X16_USE_IRQ_CORE = 1
    .endif
    .if !.def X16_USE_IRQ_VSYNC
    X16_USE_IRQ_VSYNC = 1
    .endif
    .if !.def X16_USE_IRQ_SPRCOL
    X16_USE_IRQ_SPRCOL = 1
    .endif
    .if !.def X16_USE_IRQ_SPRCOL_API
    X16_USE_IRQ_SPRCOL_API = 1
    .endif
.endif
.if .def X16_USE_IRQ_SPRCOL_API
    .if !.def X16_USE_IRQ_SPRCOL
    X16_USE_IRQ_SPRCOL = 1
    .endif
.endif
.if .def X16_USE_IRQ_CORE
    .if !.def X16_USE_IRQ_ANY
    X16_USE_IRQ_ANY = 1
    .endif
.endif
.if .def X16_USE_IRQ_VSYNC
    .if !.def X16_USE_IRQ_ANY
    X16_USE_IRQ_ANY = 1
    .endif
.endif
.if .def X16_USE_IRQ_SPRCOL
    .if !.def X16_USE_IRQ_ANY
    X16_USE_IRQ_ANY = 1
    .endif
.endif
.if .def X16_USE_INPUT
    .if !.def X16_USE_INPUT_CORE
    X16_USE_INPUT_CORE = 1
    .endif
    .if !.def X16_USE_INPUT_KEYWAIT
    X16_USE_INPUT_KEYWAIT = 1
    .endif
.endif
.if .def X16_USE_INPUT_CORE
    .if !.def X16_USE_INPUT_ANY
    X16_USE_INPUT_ANY = 1
    .endif
.endif
.if .def X16_USE_INPUT_KEYWAIT
    .if !.def X16_USE_INPUT_ANY
    X16_USE_INPUT_ANY = 1
    .endif
.endif
.if .def X16_USE_SCREEN
    .if !.def X16_USE_SCREEN_CORE
    X16_USE_SCREEN_CORE = 1
    .endif
    .if !.def X16_USE_SCREEN_EXTRA
    X16_USE_SCREEN_EXTRA = 1
    .endif
.endif
.if .def X16_USE_SCREEN_CORE
    .if !.def X16_USE_SCREEN_ANY
    X16_USE_SCREEN_ANY = 1
    .endif
.endif
.if .def X16_USE_SCREEN_EXTRA
    .if !.def X16_USE_SCREEN_ANY
    X16_USE_SCREEN_ANY = 1
    .endif
.endif

; --- modules ---------------------------------------------------------
.if .def X16_USE_VERA_ANY
    icl "video/vera.asm"
.endif
.if .def X16_USE_SCREEN_ANY
    icl "video/screen.asm"
.endif
.if .def X16_USE_PALETTE
    icl "video/palette.asm"
.endif
.if .def X16_USE_TILE
    icl "video/tile.asm"
.endif
.if .def X16_USE_SPRITE
    icl "sprite/sprite.asm"
.endif
.if .def X16_USE_BITMAP
    icl "gfx/bitmap.asm"
.endif
.if .def X16_USE_BITMAP2
    icl "gfx/bitmap2.asm"
.endif
; X16_SKIP_SHAPES / X16_SKIP_MATH (below): a program that sources these two
; modules itself -- e.g. a custom bank layout, or a gate pulled in only for a
; dependency like X16_USE_SHAPES_POLY -> X16_USE_SHAPES/MATH -- defines the
; matching skip symbol to keep this wrapper's flat include quiet, so the
; module's symbols are not defined twice.
.if .def X16_USE_SHAPES
    .if !.def X16_SKIP_SHAPES
        icl "gfx/shapes.asm"
.endif
.endif
.if .def X16_USE_VERAFX_ANY
    icl "gfx/verafx.asm"
.endif
.if .def X16_USE_IRQ_ANY
    icl "system/irq.asm"
.endif
.if .def X16_USE_PSG
    icl "audio/psg.asm"
.endif
.if .def X16_USE_YM
    icl "audio/ym.asm"
.endif
.if .def X16_USE_PCM
    icl "audio/pcm.asm"
.endif
.if .def X16_USE_INPUT_ANY
    icl "input/input.asm"
.endif
.if .def X16_USE_SERIAL
    icl "comms/serial.asm"
.endif
.if .def X16_USE_SERIAL_ZIMODEM
    icl "comms/zimodem.asm"
.endif
.if .def X16_USE_BANK
    icl "storage/bank.asm"
.endif
.if .def X16_USE_BANKALLOC
    icl "storage/bankalloc.asm"
.endif
.if .def X16_USE_STACK
    icl "storage/stack.asm"
.endif
.if .def X16_USE_RINGBUFFER
    icl "storage/ringbuffer.asm"
.endif
.if .def X16_USE_MEM
    icl "storage/mem.asm"
.endif
.if .def X16_USE_LOAD
    icl "storage/load.asm"
.endif
.if .def X16_USE_DOS
    icl "storage/dos.asm"
.endif
.if .def X16_USE_BMX
    icl "storage/bmx.asm"
.endif
.if .def X16_USE_MATH
    .if !.def X16_SKIP_MATH
        icl "util/math.asm"
.endif
.endif
.if .def X16_USE_CLIP
    icl "util/clip.asm"
.endif
.if .def X16_USE_BUFFERS
    icl "util/buffers.asm"
.endif
.if .def X16_USE_ADPCM
    icl "audio/adpcm.asm"
.endif
.if .def X16_USE_ZX0
    icl "util/zx0.asm"
.endif
.if .def X16_USE_TSC
    icl "util/tscrunch.asm"
.endif
.if .def X16_USE_FIXED
    icl "util/fixed.asm"
.endif
.if .def X16_USE_BCD
    icl "util/bcd.asm"
.endif
.if .def X16_USE_COLLIDE
    icl "util/collide.asm"
.endif
.if .def X16_USE_BITS
    icl "util/bits.asm"
.endif
.if .def X16_USE_NUMBER
    icl "util/number.asm"
.endif
.if .def X16_USE_INT16
    icl "util/int16.asm"
.endif
.if .def X16_USE_INT32
    icl "util/int32.asm"
.endif
.if .def X16_USE_FLOAT
    icl "util/float.asm"
.endif
.if .def X16_USE_DOUBLE
    icl "util/double.asm"
.endif
.if .def X16_USE_STRING
    icl "string/string.asm"
.endif
.if .def X16_USE_STRING_CTYPE
    icl "string/ctype.asm"
.endif
.if .def X16_USE_STRING_CASE
    icl "string/case.asm"
.endif
.if .def X16_USE_STRING_FIND
    icl "string/find.asm"
.endif
.if .def X16_USE_STRING_SLICE
    icl "string/slice.asm"
.endif
