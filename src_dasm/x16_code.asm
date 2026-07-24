;ACME
; =====================================================================
; x16lib :: x16_code.asm -- the library routines
; =====================================================================
; Source this EXACTLY ONCE, at the point in your program where you want
; the library's machine code to sit (normally after your own code).
;
; ACME has no linker, so unused routines cannot be stripped for you.
; Instead, pick the modules you need by defining X16_USE_* before
; sourcing this file. You can select individual modules, or select one
; of the section gates below and let it expand to that whole area.
;
;       X16_USE_VERA = 1
;       !source "x16_code.asm"
;
; or from the build script:  acme -DX16_USE_VIDEO=1 ...
;
; These gates must be resolvable on the FIRST pass, so always define
; them ahead of this !source, never after it.
; ---------------------------------------------------------------------
; Module            Provides
;   Section bundles:
;   X16_USE_VIDEO    VERA, VERA_DC, SCREEN, PALETTE, TILE, SPRITE
;   X16_USE_GRAPHICS bitmaps, shapes, framebuffer, GRAPH/CONSOLE,
;                    VERAFX and VERAFX_UTILS
;   X16_USE_AUDIO    PSG, YM, AUDIO_ROM, ZSM/ZSM_PCM, PCM/PCM_STREAM,
;                    ADPCM
;   X16_USE_INPUT_DEVICES  INPUT, KEYBOARD, MOUSE
;   X16_USE_COMMUNICATIONS I2C, VERA_SPI, SERIAL, SERIAL_ZIMODEM
;   X16_USE_STORAGE  BANK, BANKALLOC, STACK, RINGBUFFER, MEM, FILEIO,
;                    IEC, LOAD, DOS, BMX
;   X16_USE_UTILITIES MATH, CLIP, BUFFERS, compression, fixed/BCD,
;                    collide/bits/number, INT16/INT32, FLOAT, DOUBLE
;   X16_USE_STRINGS  all five string/ gates
;   X16_USE_SYSTEM   IRQ, CLOCK
;
;   X16_USE_VERA      vera_set_addr0/1, vera_fill, vera_copy, vera_has_fx
;   X16_USE_VERA_DC   vdc_get/set_video, vdc_set_output/layers,
;                     vdc_get/set_scale/border/active, vdc_get_version
;   X16_USE_SCREEN    screen_set_mode/get_mode/reset/cls/chrout/color/
;                     border, screen_locate, screen_get_cursor,
;                     screen_charset, screen_puts
;   X16_USE_PALETTE   pal_set, pal_load
;   X16_USE_TILE      layer_on/off, layer_set_config/mapbase/tilebase,
;                     layer_scroll_x/y, tile_setptr, tile_put, tile_get
;   X16_USE_SPRITE    sprites_on/off, sprite_pos, sprite_get_pos,
;                     sprite_image, sprite_flags, sprite_z, sprite_size,
;                     sprite_init_all
;   X16_USE_BITMAP8L  gfx8l_init, gfx8l_clear, gfx8l_read,
;                     gfx8l_pset, gfx8l_pattern_set,
;                     gfx8l_pattern_rect, gfx8l_blit,
;                     gfx8l_blitm (colour-key), gfx8l_hline,
;                     gfx8l_vline, gfx8l_rect, gfx8l_frame,
;                     gfx8l_line, gfx8l_char, gfx8l_text
;   X16_USE_BITMAP8H  gfx8h_has, gfx8h_init/off,
;                     gfx8h_passthru_on/off, gfx8h_pal_set/load,
;                     gfx8h_clear, gfx8h_setptr, gfx8h_pset,
;                     gfx8h_read, gfx8h_hline, gfx8h_vline,
;                     gfx8h_rect, gfx8h_frame, gfx8h_line,
;                     gfx8h_pattern_set, gfx8h_pattern_rect,
;                     gfx8h_blit, gfx8h_blitm, gfx8h_copy
;                     (640x480@8bpp; MiSTer VERA_2 SDRAM layer)
;   X16_USE_BITMAP2H  gfx2h_init, gfx2h_clear, gfx2h_setptr,
;                     gfx2h_pset, gfx2h_read, gfx2h_hline,
;                     gfx2h_vline, gfx2h_rect, gfx2h_frame,
;                     gfx2h_line, gfx2h_pattern_set,
;                     gfx2h_pattern_rect, gfx2h_blit, gfx2h_blitm
;                     (640x480@2bpp; pulls in VERA and VERAFX)
;   X16_USE_BITMAP2L  gfx2l_init, gfx2l_clear, gfx2l_setptr,
;                     gfx2l_pset, gfx2l_read, gfx2l_hline,
;                     gfx2l_vline, gfx2l_rect, gfx2l_frame,
;                     gfx2l_line, gfx2l_pattern_set,
;                     gfx2l_pattern_rect, gfx2l_blit, gfx2l_blitm
;                     (320x240@2bpp; pulls in VERA and VERAFX)
;   X16_USE_BITMAP4L  gfx4l_init, gfx4l_clear, gfx4l_read,
;                     gfx4l_pset, gfx4l_pattern_set,
;                     gfx4l_pattern_rect, gfx4l_blit,
;                     gfx4l_blitm, gfx4l_hline, gfx4l_vline,
;                     gfx4l_rect, gfx4l_frame, gfx4l_line,
;                     gfx4l_char, gfx4l_text
;   X16_USE_BITMAP4H  gfx4h_has, gfx4h_init/off,
;                     gfx4h_passthru_on/off, gfx4h_pal_set/load,
;                     gfx4h_clear, gfx4h_setptr, gfx4h_pset,
;                     gfx4h_read, gfx4h_hline, gfx4h_vline,
;                     gfx4h_rect, gfx4h_frame, gfx4h_line,
;                     gfx4h_pattern_set, gfx4h_pattern_rect,
;                     gfx4h_blit, gfx4h_blitm, gfx4h_copy
;                     (640x480@4bpp; MiSTer VERA_2 SDRAM layer)
;   X16_USE_FB        fb_init/info/palette/cursor,
;                     fb_get/set/fill/filter/move pixels
;   X16_USE_GRAPH     graph_init/clear/window/colors,
;                     graph_line/rect/oval/image/text
;   X16_USE_CONSOLE   con_init, con_put/get_char, con_put_image,
;                     con_set_paging_message
;   X16_USE_CLOCK     clock_update, clock_get/set_timer,
;                     clock_get/set_date_time
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
;   X16_USE_VERAFX_UTILS  fxu_* low-level FX ctrl/cache/mult/accum/
;                     16-bit-hop/polygon primitives; separate from
;                     X16_USE_VERAFX to keep that bundle stable
;   X16_USE_IRQ       irq_install, irq_remove, irq_frames, vsync_wait,
;                     irq_line_install/remove, irq_sprcol_install/
;                     remove, sprite_collisions
;   X16_USE_PSG       psg_init, psg_set_freq/vol/wave, psg_note_off,
;                     psg_env_start/release/stop/tick (ASR envelopes)
;   X16_USE_YM        ym_write, ym_busy, ym_init, ym_poke, ym_patch,
;                     ym_note, ym_note_bas, ym_release_note, ym_vol,
;                     ym_pan, ym_drum, ym_get_pan, ym_get_vol
;   X16_USE_AUDIO_ROM ar_* wrappers for the full BANK_AUDIO API:
;                     note conversion, ROM PSG/YM shadows, play strings
;   X16_USE_ZSM       zsm_init/tick/play/stop/status; compact ZSM
;                     stream player for PSG/YM plus PCM ctrl/rate
;   X16_USE_ZSM_PCM   + PCM instrument triggers from a ZSM PCM table
;                     using the AFLOW PCM streamer (pulls PCM_STREAM)
;   X16_USE_PCM       pcm_ctrl, pcm_rate, pcm_reset, pcm_full/empty,
;                     pcm_put, pcm_write
;   X16_USE_PCM_STREAM  pcm_stream_start/stop/active (AFLOW-driven;
;                     pulls in PCM and IRQ)
;   X16_USE_INPUT     joy_scan, joy_get, mouse_show/hide/get,
;                     key_get, key_wait, key_peek
;   X16_USE_KEYBOARD  kbd_scan, kbd_peek/put, kbd_get_modifiers,
;                     kbd_get/set_keymap
;   X16_USE_MOUSE     mse_config/scan/get/get_to,
;                     mse_show/show_keep/hide
;   X16_USE_I2C       i2c_read_byte/write_byte,
;                     i2c_batch_read/write
;   X16_USE_VERA_SPI  spi_get/set_ctrl, spi_select/deselect,
;                     spi_slow/fast, spi_transfer/read/write,
;                     spi_read/write_bytes
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
;   X16_USE_FILEIO    fio_set_lfs/name, fio_open/close,
;                     fio_chkin/chkout, fio_chrin/chrout, fio_readst
;   X16_USE_IEC       iec_listen/talk/second/tksa, iec_ciout/acptr,
;                     iec_unlisten/untalk, iec_macptr/mciout
;   X16_USE_LOAD      fs_setname, fs_load, fs_save, fs_vload
;   X16_USE_DOS       dos_cmd, dos_status, dos_delete, dos_rename,
;                     dos_mkdir, dos_rmdir, dos_chdir
;   X16_USE_BMX       bmx_load, bmx_save (the X16's native bitmap
;                     format: header + palette + pixels)
;   X16_USE_MATH      rnd_seed/rnd8/rnd16, sin8/cos8 (+u), atan2, lerp8
;   X16_USE_CLIP      clip_set, clip_line (Cohen-Sutherland, feeds
;                     gfx8l_line/fx_line's parameter block)
;   X16_USE_BUFFERS   rb_init/put/get/count, stk_init/push/pop/depth
;   X16_USE_ADPCM     adpcm_init, adpcm_nibble, adpcm_block (IMA 4:1)
;   X16_USE_WAV       wav_parse_header (RIFF/WAVE header -> PCM format)
;   X16_USE_ZX0       zx0_decompress (tighter than the ROM's LZSA2)
;   X16_USE_TSC       tsc_decompress (TSCrunch: faster unpack)
;   X16_USE_FIXED     umul16, mul88
;   X16_USE_BCD       bcd_add8/16/32, bcd_sub8/16/32, bcd_addto,
;                     bcd_subfrom -- packed-BCD (decimal-mode) arithmetic
;   X16_USE_COLLIDE   collide8, collide16
;   X16_USE_BITS      catnib, hinib, lonib, bit_set/clr/put/test
;   X16_USE_NUMBER    u16_to_dec, u16_to_hex, dec_to_u16, u8_to_dec,
;                     u8_to_hex, u8_to_bin, u16_to_bin, s8_to_dec, s16_to_dec
;   X16_USE_SORT      sort_u8/s8/u16/s16 (memory block), sort_ptr (comparator)
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
;   X16_USE_STRING_SORT   str_sort -- sort an array of string pointers
;                     (the five string gates are independent; set what you
;                      use. Number<->string conversion stays in NUMBER,
;                      INT16/INT32, FLOAT, DOUBLE.)
; =====================================================================

; Section gates are set with !ifndef so that asking for a module twice --
; say via a section gate and again through a dependency -- is not a
; redefinition error, and so an explicit X16_USE_* in your program still
; works.
    IFCONST X16_USE_VIDEO
    IFNCONST X16_USE_VERA
X16_USE_VERA    = 1
    ENDIF
    IFNCONST X16_USE_VERA_DC
X16_USE_VERA_DC = 1
    ENDIF
    IFNCONST X16_USE_SCREEN
X16_USE_SCREEN  = 1
    ENDIF
    IFNCONST X16_USE_PALETTE
X16_USE_PALETTE = 1
    ENDIF
    IFNCONST X16_USE_TILE
X16_USE_TILE    = 1
    ENDIF
    IFNCONST X16_USE_SPRITE
X16_USE_SPRITE  = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_GRAPHICS
    IFNCONST X16_USE_BITMAP8L
X16_USE_BITMAP8L = 1
    ENDIF
    IFNCONST X16_USE_BITMAP8H
X16_USE_BITMAP8H = 1
    ENDIF
    IFNCONST X16_USE_BITMAP2H
X16_USE_BITMAP2H = 1
    ENDIF
    IFNCONST X16_USE_BITMAP2L
X16_USE_BITMAP2L = 1
    ENDIF
    IFNCONST X16_USE_BITMAP4L
X16_USE_BITMAP4L = 1
    ENDIF
    IFNCONST X16_USE_BITMAP4H
X16_USE_BITMAP4H = 1
    ENDIF
    IFNCONST X16_USE_FB
X16_USE_FB       = 1
    ENDIF
    IFNCONST X16_USE_GRAPH
X16_USE_GRAPH    = 1
    ENDIF
    IFNCONST X16_USE_CONSOLE
X16_USE_CONSOLE  = 1
    ENDIF
    IFNCONST X16_USE_SHAPES
X16_USE_SHAPES   = 1
    ENDIF
    IFNCONST X16_USE_SHAPES_POLY
X16_USE_SHAPES_POLY = 1
    ENDIF
    IFNCONST X16_USE_SHAPES_RRECT
X16_USE_SHAPES_RRECT = 1
    ENDIF
    IFNCONST X16_USE_SHAPES_ARC
X16_USE_SHAPES_ARC = 1
    ENDIF
    IFNCONST X16_USE_SHAPES_PIE
X16_USE_SHAPES_PIE = 1
    ENDIF
    IFNCONST X16_USE_SHAPES_BEZIER
X16_USE_SHAPES_BEZIER = 1
    ENDIF
    IFNCONST X16_USE_VERAFX
X16_USE_VERAFX = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_UTILS
X16_USE_VERAFX_UTILS = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_AUDIO
    IFNCONST X16_USE_PSG
X16_USE_PSG       = 1
    ENDIF
    IFNCONST X16_USE_YM
X16_USE_YM        = 1
    ENDIF
    IFNCONST X16_USE_AUDIO_ROM
X16_USE_AUDIO_ROM = 1
    ENDIF
    IFNCONST X16_USE_ZSM
X16_USE_ZSM       = 1
    ENDIF
    IFNCONST X16_USE_ZSM_PCM
X16_USE_ZSM_PCM   = 1
    ENDIF
    IFNCONST X16_USE_PCM
X16_USE_PCM       = 1
    ENDIF
    IFNCONST X16_USE_PCM_STREAM
X16_USE_PCM_STREAM = 1
    ENDIF
    IFNCONST X16_USE_ADPCM
X16_USE_ADPCM     = 1
    ENDIF
    IFNCONST X16_USE_WAV
X16_USE_WAV       = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_INPUT_DEVICES
    IFNCONST X16_USE_INPUT
X16_USE_INPUT    = 1
    ENDIF
    IFNCONST X16_USE_KEYBOARD
X16_USE_KEYBOARD = 1
    ENDIF
    IFNCONST X16_USE_MOUSE
X16_USE_MOUSE    = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_COMMUNICATIONS
    IFNCONST X16_USE_I2C
X16_USE_I2C      = 1
    ENDIF
    IFNCONST X16_USE_VERA_SPI
X16_USE_VERA_SPI = 1
    ENDIF
    IFNCONST X16_USE_SERIAL
X16_USE_SERIAL   = 1
    ENDIF
    IFNCONST X16_USE_SERIAL_ZIMODEM
X16_USE_SERIAL_ZIMODEM = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_STORAGE
    IFNCONST X16_USE_BANK
X16_USE_BANK       = 1
    ENDIF
    IFNCONST X16_USE_BANKALLOC
X16_USE_BANKALLOC  = 1
    ENDIF
    IFNCONST X16_USE_STACK
X16_USE_STACK      = 1
    ENDIF
    IFNCONST X16_USE_RINGBUFFER
X16_USE_RINGBUFFER = 1
    ENDIF
    IFNCONST X16_USE_MEM
X16_USE_MEM        = 1
    ENDIF
    IFNCONST X16_USE_FILEIO
X16_USE_FILEIO     = 1
    ENDIF
    IFNCONST X16_USE_IEC
X16_USE_IEC        = 1
    ENDIF
    IFNCONST X16_USE_LOAD
X16_USE_LOAD       = 1
    ENDIF
    IFNCONST X16_USE_DOS
X16_USE_DOS        = 1
    ENDIF
    IFNCONST X16_USE_BMX
X16_USE_BMX        = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_UTILITIES
    IFNCONST X16_USE_MATH
X16_USE_MATH    = 1
    ENDIF
    IFNCONST X16_USE_CLIP
X16_USE_CLIP    = 1
    ENDIF
    IFNCONST X16_USE_BUFFERS
X16_USE_BUFFERS = 1
    ENDIF
    IFNCONST X16_USE_ZX0
X16_USE_ZX0     = 1
    ENDIF
    IFNCONST X16_USE_TSC
X16_USE_TSC     = 1
    ENDIF
    IFNCONST X16_USE_FIXED
X16_USE_FIXED   = 1
    ENDIF
    IFNCONST X16_USE_BCD
X16_USE_BCD     = 1
    ENDIF
    IFNCONST X16_USE_COLLIDE
X16_USE_COLLIDE = 1
    ENDIF
    IFNCONST X16_USE_BITS
X16_USE_BITS    = 1
    ENDIF
    IFNCONST X16_USE_NUMBER
X16_USE_NUMBER  = 1
    ENDIF
    IFNCONST X16_USE_INT16
X16_USE_INT16   = 1
    ENDIF
    IFNCONST X16_USE_INT32
X16_USE_INT32   = 1
    ENDIF
    IFNCONST X16_USE_FLOAT
X16_USE_FLOAT   = 1
    ENDIF
    IFNCONST X16_USE_DOUBLE
X16_USE_DOUBLE  = 1
    ENDIF
    IFNCONST X16_USE_SORT
X16_USE_SORT    = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_STRINGS
    IFNCONST X16_USE_STRING
X16_USE_STRING       = 1
    ENDIF
    IFNCONST X16_USE_STRING_CTYPE
X16_USE_STRING_CTYPE = 1
    ENDIF
    IFNCONST X16_USE_STRING_CASE
X16_USE_STRING_CASE  = 1
    ENDIF
    IFNCONST X16_USE_STRING_FIND
X16_USE_STRING_FIND  = 1
    ENDIF
    IFNCONST X16_USE_STRING_SLICE
X16_USE_STRING_SLICE = 1
    ENDIF
    IFNCONST X16_USE_STRING_SORT
X16_USE_STRING_SORT  = 1
    ENDIF
    ENDIF
; str_sort needs str_compare from the STRING fundamentals.
    IFCONST X16_USE_STRING_SORT
    IFNCONST X16_USE_STRING
X16_USE_STRING = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SYSTEM
    IFNCONST X16_USE_IRQ
X16_USE_IRQ   = 1
    ENDIF
    IFNCONST X16_USE_CLOCK
X16_USE_CLOCK = 1
    ENDIF
    ENDIF

; --- dependencies ----------------------------------------------------
; sprite_init_all, psg_init, gfx8l_clear and gfx8l_hline all call vera_fill.
; gfx8l_init calls screen_set_mode. The PCM streamer's AFLOW service runs
; inside irq_handler, so it needs the IRQ module (and PCM itself).
    IFCONST X16_USE_SPRITE
    IFNCONST X16_USE_VERA
X16_USE_VERA = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_PSG
    IFNCONST X16_USE_VERA
X16_USE_VERA = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_INT16
    IFNCONST X16_USE_NUMBER
X16_USE_NUMBER = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_BITMAP8L
    IFNCONST X16_USE_VERA
X16_USE_VERA   = 1
    ENDIF
    IFNCONST X16_USE_SCREEN
X16_USE_SCREEN = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SHAPES_POLY
    IFNCONST X16_USE_SHAPES
X16_USE_SHAPES = 1
    ENDIF
    IFNCONST X16_USE_MATH
X16_USE_MATH   = 1
    ENDIF
    ENDIF
; The curve shapes. PIE reuses ARC's trig point helper, so it pulls ARC;
; ARC and BEZIER share one 16-bit Bresenham (the internal X16_USE_SHP_LINE).
; Ordered so a pulled gate's own dependencies still get a turn below it:
; PIE sets ARC, then ARC sets MATH + SHP_LINE, then SHP_LINE sets SHAPES.
    IFCONST X16_USE_SHAPES_PIE
    IFNCONST X16_USE_SHAPES
X16_USE_SHAPES     = 1
    ENDIF
    IFNCONST X16_USE_SHAPES_ARC
X16_USE_SHAPES_ARC = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SHAPES_ARC
    IFNCONST X16_USE_SHAPES
X16_USE_SHAPES   = 1
    ENDIF
    IFNCONST X16_USE_MATH
X16_USE_MATH     = 1
    ENDIF
    IFNCONST X16_USE_SHP_LINE
X16_USE_SHP_LINE = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SHAPES_RRECT
    IFNCONST X16_USE_SHAPES
X16_USE_SHAPES = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SHAPES_BEZIER
    IFNCONST X16_USE_SHAPES
X16_USE_SHAPES   = 1
    ENDIF
    IFNCONST X16_USE_SHP_LINE
X16_USE_SHP_LINE = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SHP_LINE
    IFNCONST X16_USE_SHAPES
X16_USE_SHAPES = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SHAPES
    IFNCONST SHP_PSET
    IFNCONST X16_USE_BITMAP2H
X16_USE_BITMAP2H = 1
    ENDIF
    ENDIF
    ENDIF
; util/double.asm stands alone (no module dependencies). This otherwise
; empty gate block is what makes the 64tass gate-model generator register
; xuse_double -- it scans the dependency section here, not the module
; !source lines below.
    IFCONST X16_USE_DOUBLE
    ENDIF
; comms/serial.asm stands alone too -- same empty-block trick to register
; xuse_serial in the 64tass gate model. It is not part of the dist blob:
; it drives a specific add-on card, so you enable the gate to pay for it,
; and a program that never talks serial carries none of it.
    IFCONST X16_USE_SERIAL
    ENDIF
; comms/i2c.asm is pay-per-use.
    IFCONST X16_USE_I2C
    ENDIF
; comms/spi.asm is pay-per-use.
    IFCONST X16_USE_VERA_SPI
    ENDIF
; video/vdc.asm is pay-per-use.
    IFCONST X16_USE_VERA_DC
    ENDIF
; system/clock.asm is pay-per-use.
    IFCONST X16_USE_CLOCK
    ENDIF
; storage/fileio.asm is pay-per-use.
    IFCONST X16_USE_FILEIO
    ENDIF
; input/keyboard.asm is pay-per-use.
    IFCONST X16_USE_KEYBOARD
    ENDIF
; input/mouse.asm is pay-per-use.
    IFCONST X16_USE_MOUSE
    ENDIF
; gfx/fb.asm is pay-per-use.
    IFCONST X16_USE_FB
    ENDIF
; gfx/graph.asm is pay-per-use.
    IFCONST X16_USE_GRAPH
    ENDIF
; gfx/console.asm is pay-per-use.
    IFCONST X16_USE_CONSOLE
    ENDIF
; storage/iec.asm is pay-per-use.
    IFCONST X16_USE_IEC
    ENDIF
; comms/zimodem.asm layers the ESP32 WiFi AT-command protocol over SERIAL.
; Also pay-per-use; pulls SERIAL in.
    IFCONST X16_USE_SERIAL_ZIMODEM
    IFNCONST X16_USE_SERIAL
X16_USE_SERIAL = 1
    ENDIF
    ENDIF
; util/bcd.asm stands alone (decimal-mode add/sub). Empty block registers
; xuse_bcd in the 64tass gate model.
    IFCONST X16_USE_BCD
    ENDIF
; storage/stack.asm and storage/ringbuffer.asm each own an 8 KB HIRAM bank.
; Standalone; empty blocks register xuse_stack / xuse_ringbuffer in the
; 64tass gate model.
    IFCONST X16_USE_STACK
    ENDIF
    IFCONST X16_USE_RINGBUFFER
    ENDIF
; The five string/ modules are independent and self-contained; these empty
; blocks register their gates in the 64tass gate model. All pay-per-use.
    IFCONST X16_USE_STRING
    ENDIF
    IFCONST X16_USE_STRING_CTYPE
    ENDIF
    IFCONST X16_USE_STRING_CASE
    ENDIF
    IFCONST X16_USE_STRING_FIND
    ENDIF
    IFCONST X16_USE_STRING_SLICE
    ENDIF
    IFCONST X16_USE_BITMAP2H
    IFNCONST X16_USE_VERA
X16_USE_VERA        = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_FILL
X16_USE_VERAFX_FILL = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_BITMAP2L
    IFNCONST X16_USE_VERA
X16_USE_VERA        = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_FILL
X16_USE_VERAFX_FILL = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_BITMAP4L
    IFNCONST X16_USE_VERA
X16_USE_VERA        = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_BITMAP8H
    ENDIF
    IFCONST X16_USE_BITMAP4H
    ENDIF

; --- VERAFX's parts --------------------------------------------------
; X16_USE_VERAFX still means all of it, so nothing that exists breaks.
; The sub-gates are for programs that want one part and not 2.5 KB of
; the others: bitmap2h/bitmap2l ask for FILL alone and save 2,162 bytes by it.
; Every part leaves FX through fx_off, so _ANY carries it.
    IFCONST X16_USE_VERAFX
    IFNCONST X16_USE_VERAFX_MULT
X16_USE_VERAFX_MULT   = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_FILL
X16_USE_VERAFX_FILL   = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_COPY
X16_USE_VERAFX_COPY   = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_TRANSP
X16_USE_VERAFX_TRANSP = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_AFFINE
X16_USE_VERAFX_AFFINE = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_LINE
X16_USE_VERAFX_LINE   = 1
    ENDIF
    IFNCONST X16_USE_VERAFX_TRI
X16_USE_VERAFX_TRI    = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_MULT
    IFNCONST X16_USE_VERAFX_ANY
X16_USE_VERAFX_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_FILL
    IFNCONST X16_USE_VERAFX_ANY
X16_USE_VERAFX_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_COPY
    IFNCONST X16_USE_VERAFX_ANY
X16_USE_VERAFX_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_TRANSP
    IFNCONST X16_USE_VERAFX_ANY
X16_USE_VERAFX_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_AFFINE
    IFNCONST X16_USE_VERAFX_ANY
X16_USE_VERAFX_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_LINE
    IFNCONST X16_USE_VERAFX_ANY
X16_USE_VERAFX_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_TRI
    IFNCONST X16_USE_VERAFX_ANY
X16_USE_VERAFX_ANY = 1
    ENDIF
    ENDIF
; LINE and TRI share verafx.asm's x16_code_udiv24 / x16_code_pix_addr helpers; either
; one carries them (internal gate, not meant to be set by programs).
    IFCONST X16_USE_VERAFX_LINE
    IFNCONST X16_USE_VERAFX_LINETRI
X16_USE_VERAFX_LINETRI = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_TRI
    IFNCONST X16_USE_VERAFX_LINETRI
X16_USE_VERAFX_LINETRI = 1
    ENDIF
    ENDIF
; gfx/verafx_utils.asm is pay-per-use and deliberately kept OUT of
; X16_USE_VERAFX.
    IFCONST X16_USE_VERAFX_UTILS
    ENDIF
; audio/rom.asm is pay-per-use.
    IFCONST X16_USE_AUDIO_ROM
    ENDIF
; audio/zsm.asm is pay-per-use.
    IFCONST X16_USE_ZSM
    ENDIF
; audio/zsm.asm's PCM sample layer is also pay-per-use. Enabling this
; gate pulls in ZSM plus the AFLOW PCM streamer, but not through USE_ALL.
    IFCONST X16_USE_ZSM_PCM
    IFNCONST X16_USE_ZSM
X16_USE_ZSM = 1
    ENDIF
    IFNCONST X16_USE_PCM_STREAM
X16_USE_PCM_STREAM = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_PCM_STREAM
    IFNCONST X16_USE_PCM
X16_USE_PCM = 1
    ENDIF
    IFNCONST X16_USE_IRQ
X16_USE_IRQ = 1
    ENDIF
    ENDIF

; --- split modules ---------------------------------------------------
; Same shape as VERAFX above: the umbrella gate still means the whole
; module, so nothing that exists breaks; a program that wants the core
; and not a rarely-used extra sets the _CORE gate and leaves the extra
; out. _ANY sources the file.
;   VERA   core = _ADDR + _FILL + _FXPROBE;   _COPY = vera_copy;
;          _ADDR = vera_set_addr0/1; _FILL = vera_fill; _FXPROBE = vera_has_fx
;   IRQ    core = install/line/frames/handler; _REMOVE = irq_remove;
;          _VSYNC = vsync_wait;
;          _SPRCOL = collision capture (handler accumulate + mask);
;          _SPRCOL_API = install/remove/sprite_collisions/callback
;   INPUT  core = mouse/joy/key_get;      _KEYWAIT = key_wait/key_peek
;   SCREEN core = set_mode/reset/cls/chrout/color/locate;
;          _EXTRA = get_mode/border/get_cursor/charset/puts
    IFCONST X16_USE_VERA
    IFNCONST X16_USE_VERA_CORE
X16_USE_VERA_CORE = 1
    ENDIF
    IFNCONST X16_USE_VERA_COPY
X16_USE_VERA_COPY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERA_CORE
    IFNCONST X16_USE_VERA_ADDR
X16_USE_VERA_ADDR    = 1
    ENDIF
    IFNCONST X16_USE_VERA_FILL
X16_USE_VERA_FILL    = 1
    ENDIF
    IFNCONST X16_USE_VERA_FXPROBE
X16_USE_VERA_FXPROBE = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERA_ADDR
    IFNCONST X16_USE_VERA_ANY
X16_USE_VERA_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERA_FILL
    IFNCONST X16_USE_VERA_ANY
X16_USE_VERA_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERA_FXPROBE
    IFNCONST X16_USE_VERA_ANY
X16_USE_VERA_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_VERA_COPY
    IFNCONST X16_USE_VERA_ANY
X16_USE_VERA_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_IRQ
    IFNCONST X16_USE_IRQ_CORE
X16_USE_IRQ_CORE       = 1
    ENDIF
    IFNCONST X16_USE_IRQ_REMOVE
X16_USE_IRQ_REMOVE     = 1
    ENDIF
    IFNCONST X16_USE_IRQ_VSYNC
X16_USE_IRQ_VSYNC      = 1
    ENDIF
    IFNCONST X16_USE_IRQ_SPRCOL
X16_USE_IRQ_SPRCOL     = 1
    ENDIF
    IFNCONST X16_USE_IRQ_SPRCOL_API
X16_USE_IRQ_SPRCOL_API = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_IRQ_SPRCOL_API
    IFNCONST X16_USE_IRQ_SPRCOL
X16_USE_IRQ_SPRCOL = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_IRQ_CORE
    IFNCONST X16_USE_IRQ_ANY
X16_USE_IRQ_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_IRQ_REMOVE
    IFNCONST X16_USE_IRQ_ANY
X16_USE_IRQ_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_IRQ_VSYNC
    IFNCONST X16_USE_IRQ_ANY
X16_USE_IRQ_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_IRQ_SPRCOL
    IFNCONST X16_USE_IRQ_ANY
X16_USE_IRQ_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_INPUT
    IFNCONST X16_USE_INPUT_CORE
X16_USE_INPUT_CORE    = 1
    ENDIF
    IFNCONST X16_USE_INPUT_KEYWAIT
X16_USE_INPUT_KEYWAIT = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_INPUT_CORE
    IFNCONST X16_USE_INPUT_ANY
X16_USE_INPUT_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_INPUT_KEYWAIT
    IFNCONST X16_USE_INPUT_ANY
X16_USE_INPUT_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SCREEN
    IFNCONST X16_USE_SCREEN_CORE
X16_USE_SCREEN_CORE  = 1
    ENDIF
    IFNCONST X16_USE_SCREEN_EXTRA
X16_USE_SCREEN_EXTRA = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SCREEN_CORE
    IFNCONST X16_USE_SCREEN_ANY
X16_USE_SCREEN_ANY = 1
    ENDIF
    ENDIF
    IFCONST X16_USE_SCREEN_EXTRA
    IFNCONST X16_USE_SCREEN_ANY
X16_USE_SCREEN_ANY = 1
    ENDIF
    ENDIF

; --- modules ---------------------------------------------------------
    IFCONST X16_USE_VERA_ANY
    include "video/vera.asm"
    ENDIF
    IFCONST X16_USE_VERA_DC
    include "video/vdc.asm"
    ENDIF
    IFCONST X16_USE_SCREEN_ANY
    include "video/screen.asm"
    ENDIF
    IFCONST X16_USE_PALETTE
    include "video/palette.asm"
    ENDIF
    IFCONST X16_USE_TILE
    include "video/tile.asm"
    ENDIF
    IFCONST X16_USE_SPRITE
    include "sprite/sprite.asm"
    ENDIF
    IFCONST X16_USE_BITMAP8L
    include "gfx/bitmap8l.asm"
    ENDIF
    IFCONST X16_USE_BITMAP8H
    include "gfx/bitmap8h.asm"
    ENDIF
    IFCONST X16_USE_BITMAP2H
    include "gfx/bitmap2h.asm"
    ENDIF
    IFCONST X16_USE_BITMAP2L
    include "gfx/bitmap2l.asm"
    ENDIF
    IFCONST X16_USE_BITMAP4L
    include "gfx/bitmap4l.asm"
    ENDIF
    IFCONST X16_USE_BITMAP4H
    include "gfx/bitmap4h.asm"
    ENDIF
    IFCONST X16_USE_FB
    include "gfx/fb.asm"
    ENDIF
    IFCONST X16_USE_GRAPH
    include "gfx/graph.asm"
    ENDIF
    IFCONST X16_USE_CONSOLE
    include "gfx/console.asm"
    ENDIF
; X16_SKIP_SHAPES / X16_SKIP_MATH (below): a program that sources these two
; modules itself -- e.g. a custom bank layout, or a gate pulled in only for a
; dependency like X16_USE_SHAPES_POLY -> X16_USE_SHAPES/MATH -- defines the
; matching skip symbol to keep this wrapper's flat include quiet, so the
; module's symbols are not defined twice.
    IFCONST X16_USE_SHAPES
    IFNCONST X16_SKIP_SHAPES
    include "gfx/shapes.asm"
    ENDIF
    ENDIF
    IFCONST X16_USE_VERAFX_ANY
    include "gfx/verafx.asm"
    ENDIF
    IFCONST X16_USE_VERAFX_UTILS
    include "gfx/verafx_utils.asm"
    ENDIF
    IFCONST X16_USE_CLOCK
    include "system/clock.asm"
    ENDIF
    IFCONST X16_USE_IRQ_ANY
    include "system/irq.asm"
    ENDIF
    IFCONST X16_USE_PSG
    include "audio/psg.asm"
    ENDIF
    IFCONST X16_USE_YM
    include "audio/ym.asm"
    ENDIF
    IFCONST X16_USE_AUDIO_ROM
    include "audio/rom.asm"
    ENDIF
    IFCONST X16_USE_ZSM
    include "audio/zsm.asm"
    ENDIF
    IFCONST X16_USE_PCM
    include "audio/pcm.asm"
    ENDIF
    IFCONST X16_USE_INPUT_ANY
    include "input/input.asm"
    ENDIF
    IFCONST X16_USE_KEYBOARD
    include "input/keyboard.asm"
    ENDIF
    IFCONST X16_USE_MOUSE
    include "input/mouse.asm"
    ENDIF
    IFCONST X16_USE_I2C
    include "comms/i2c.asm"
    ENDIF
    IFCONST X16_USE_VERA_SPI
    include "comms/spi.asm"
    ENDIF
    IFCONST X16_USE_SERIAL
    include "comms/serial.asm"
    ENDIF
    IFCONST X16_USE_SERIAL_ZIMODEM
    include "comms/zimodem.asm"
    ENDIF
    IFCONST X16_USE_BANK
    include "storage/bank.asm"
    ENDIF
    IFCONST X16_USE_BANKALLOC
    include "storage/bankalloc.asm"
    ENDIF
    IFCONST X16_USE_STACK
    include "storage/stack.asm"
    ENDIF
    IFCONST X16_USE_RINGBUFFER
    include "storage/ringbuffer.asm"
    ENDIF
    IFCONST X16_USE_MEM
    include "storage/mem.asm"
    ENDIF
    IFCONST X16_USE_FILEIO
    include "storage/fileio.asm"
    ENDIF
    IFCONST X16_USE_IEC
    include "storage/iec.asm"
    ENDIF
    IFCONST X16_USE_LOAD
    include "storage/load.asm"
    ENDIF
    IFCONST X16_USE_DOS
    include "storage/dos.asm"
    ENDIF
    IFCONST X16_USE_BMX
    include "storage/bmx.asm"
    ENDIF
    IFCONST X16_USE_MATH
    IFNCONST X16_SKIP_MATH
    include "util/math.asm"
    ENDIF
    ENDIF
    IFCONST X16_USE_CLIP
    include "util/clip.asm"
    ENDIF
    IFCONST X16_USE_BUFFERS
    include "util/buffers.asm"
    ENDIF
    IFCONST X16_USE_ADPCM
    include "audio/adpcm.asm"
    ENDIF
    IFCONST X16_USE_WAV
    include "audio/wavfile.asm"
    ENDIF
    IFCONST X16_USE_ZX0
    include "util/zx0.asm"
    ENDIF
    IFCONST X16_USE_TSC
    include "util/tscrunch.asm"
    ENDIF
    IFCONST X16_USE_FIXED
    include "util/fixed.asm"
    ENDIF
    IFCONST X16_USE_BCD
    include "util/bcd.asm"
    ENDIF
    IFCONST X16_USE_COLLIDE
    include "util/collide.asm"
    ENDIF
    IFCONST X16_USE_BITS
    include "util/bits.asm"
    ENDIF
    IFCONST X16_USE_NUMBER
    include "util/number.asm"
    ENDIF
    IFCONST X16_USE_SORT
    include "util/sort.asm"
    ENDIF
    IFCONST X16_USE_INT16
    include "util/int16.asm"
    ENDIF
    IFCONST X16_USE_INT32
    include "util/int32.asm"
    ENDIF
    IFCONST X16_USE_FLOAT
    include "util/float.asm"
    ENDIF
    IFCONST X16_USE_DOUBLE
    include "util/double.asm"
    ENDIF
    IFCONST X16_USE_STRING
    include "string/string.asm"
    ENDIF
    IFCONST X16_USE_STRING_CTYPE
    include "string/ctype.asm"
    ENDIF
    IFCONST X16_USE_STRING_CASE
    include "string/case.asm"
    ENDIF
    IFCONST X16_USE_STRING_FIND
    include "string/find.asm"
    ENDIF
    IFCONST X16_USE_STRING_SLICE
    include "string/slice.asm"
    ENDIF
    IFCONST X16_USE_STRING_SORT
    include "string/strsort.asm"
    ENDIF
