//ACME
// =====================================================================
// x16lib :: x16_code.asm -- the library routines
// =====================================================================
// Source this EXACTLY ONCE, at the point in your program where you want
// the library's machine code to sit (normally after your own code).
//
// ACME has no linker, so unused routines cannot be stripped for you.
// Instead, pick the modules you need by defining X16_USE_* before
// sourcing this file -- or define X16_USE_ALL to pull in everything.
//
//       X16_USE_VERA = 1
//       #import "x16_code.asm"
//
// or from the build script:  acme -DX16_USE_ALL=1 ...
//
// These gates must be resolvable on the FIRST pass, so always define
// them ahead of this !source, never after it.
// ---------------------------------------------------------------------
// Module            Provides
//   X16_USE_VERA      vera_set_addr0/1, vera_fill, vera_copy, vera_has_fx
//   X16_USE_SCREEN    screen_set_mode/get_mode/reset/cls/chrout/color/
//                     border, screen_locate, screen_get_cursor,
//                     screen_charset, screen_puts
//   X16_USE_PALETTE   pal_set, pal_load
//   X16_USE_TILE      layer_on/off, layer_set_config/mapbase/tilebase,
//                     layer_scroll_x/y, tile_setptr, tile_put, tile_get
//   X16_USE_SPRITE    sprites_on/off, sprite_pos, sprite_get_pos,
//                     sprite_image, sprite_flags, sprite_z, sprite_size,
//                     sprite_init_all
//   X16_USE_BITMAP    gfx_init, gfx_clear, gfx_read, gfx_pset,
//                     gfx_pattern_set, gfx_pattern_rect, gfx_blit,
//                     gfx_blitm (colour-key), gfx_hline,
//                     gfx_vline, gfx_rect, gfx_frame, gfx_line,
//                     gfx_char, gfx_text (circle/disc/flood are in
//                     X16_USE_SHAPES now, shared with gfx2)
//   X16_USE_BITMAP2   gfx2_init, gfx2_clear, gfx2_setptr, gfx2_pset,
//                     gfx2_read, gfx2_hline, gfx2_vline, gfx2_rect,
//                     gfx2_frame, gfx2_line, gfx2_pattern_set,
//                     gfx2_pattern_rect, gfx2_blit, gfx2_blitm
//                     (640x480@2bpp; pulls in VERA and VERAFX)
//   X16_USE_SHAPES    shape_circle, shape_disc, shape_ellipse,
//                     shape_fellipse, shape_flood -- engine-
//                     agnostic: they draw through SHP_PSET/SHP_READ/
//                     SHP_HLINE (+ SHP_W/SHP_H bounds), which default to
//                     the 2bpp module; predefine them to bind any engine
//   X16_USE_SHAPES_POLY  + shape_polygon, shape_fpolygon (regular convex
//                     N-gons, outline and filled; pulls in MATH for the
//                     sin8/cos8 vertex placement)
//   X16_USE_VERAFX    all of the below, as it always has been
//     _MULT           fx_mult
//     _FILL           fx_fill, fx_clear
//     _COPY           fx_copy
//     _TRANSP         fx_transp_on/off
//     _AFFINE         fx_affine_on/ray/span (rotozoom sampling)
//     _LINE           fx_line
//     _TRI            fx_triangle
//                     fx_off comes with any of them. The parts exist
//                     because the whole is 2.5 KB and a program that
//                     wants one fast fill should not carry a rotozoom
//                     sampler to get it: BITMAP2 asks for _FILL alone
//                     and is 2,162 bytes lighter for it.
//   X16_USE_IRQ       irq_install, irq_remove, irq_frames, vsync_wait,
//                     irq_line_install/remove, irq_sprcol_install/
//                     remove, sprite_collisions
//   X16_USE_PSG       psg_init, psg_set_freq/vol/wave, psg_note_off,
//                     psg_env_start/release/stop/tick (ASR envelopes)
//   X16_USE_YM        ym_write, ym_busy, ym_init, ym_poke, ym_patch,
//                     ym_note, ym_note_bas, ym_release_note, ym_vol,
//                     ym_pan, ym_drum, ym_get_pan, ym_get_vol
//   X16_USE_PCM       pcm_ctrl, pcm_rate, pcm_reset, pcm_full/empty,
//                     pcm_put, pcm_write
//   X16_USE_PCM_STREAM  pcm_stream_start/stop/active (AFLOW-driven;
//                     pulls in PCM and IRQ)
//   X16_USE_INPUT     joy_scan, joy_get, mouse_show/hide/get,
//                     key_get, key_wait, key_peek
//   X16_USE_BANK      bank_set/get, bank_peek/poke, mem_to_bank,
//                     bank_to_mem, bank_copy_far
//   X16_USE_BANKALLOC bank_alloc_init, bank_alloc, bank_free,
//                     bank_reserve
//   X16_USE_MEM       mem_fill, mem_copy, mem_crc, mem_decompress
//                     (KERNAL block ops; they stream to/from VERA too)
//   X16_USE_LOAD      fs_setname, fs_load, fs_save, fs_vload
//   X16_USE_DOS       dos_cmd, dos_status, dos_delete, dos_rename,
//                     dos_mkdir, dos_rmdir, dos_chdir
//   X16_USE_BMX       bmx_load, bmx_save (the X16's native bitmap
//                     format: header + palette + pixels)
//   X16_USE_MATH      rnd_seed/rnd8/rnd16, sin8/cos8 (+u), atan2, lerp8
//   X16_USE_CLIP      clip_set, clip_line (Cohen-Sutherland, feeds
//                     gfx_line/fx_line's parameter block)
//   X16_USE_BUFFERS   rb_init/put/get/count, stk_init/push/pop/depth
//   X16_USE_ADPCM     adpcm_init, adpcm_nibble, adpcm_block (IMA 4:1)
//   X16_USE_ZX0       zx0_decompress (tighter than the ROM's LZSA2)
//   X16_USE_TSC       tsc_decompress (TSCrunch: faster unpack)
//   X16_USE_FIXED     umul16, mul88
//   X16_USE_COLLIDE   collide8, collide16
//   X16_USE_BITS      catnib, hinib, lonib, bit_set/clr/put/test
//   X16_USE_NUMBER    u16_to_dec, u16_to_hex, dec_to_u16
//   X16_USE_INT16     i16_add/sub/neg/abs/mul/divmod/divmod_s,
//                     i16_cmps/cmpu, i16_shl/shr/asr, i16_sqrt,
//                     i16_to_dec/dec_s, +i16_const   (needs NUMBER)
//   X16_USE_INT32     i32_add/sub/neg/abs/mul/divmod, i32_cmps/cmpu,
//                     i32_shl/shr/asr, i32_from_u16/s16, i32_to_s16,
//                     i32_to_dec, +i32_const
//   X16_USE_FLOAT     f_load/store, f_add/sub/mul/div, f_rsub/rdiv,
//                     f_pow, f_cmp, f_sqrt, f_ln, f_exp, f_sin, f_cos,
//                     f_tan, f_atan, f_from_s16/u8/str, f_to_s16/str
//   X16_USE_DOUBLE    64-bit software binary64 (~15-16 digits) on a d_ac
//                     accumulator -- a scientific calculator core with
//                     decimal I/O: d_load/store, d_from_s16/s32, d_to_s32,
//                     d_neg/abs, d_cmp, d_add/sub/mul/div, d_from_str,
//                     d_to_str, d_sqrt, d_exp, d_ln, d_pow, d_sin, d_cos,
//                     d_tan, d_atan
// =====================================================================

// Gates are set with !ifndef so that asking for a module twice -- say via
// X16_USE_ALL and again through a dependency -- is not a redefinition
// error, and so an explicit X16_USE_* in your program still works.
#if X16_USE_ALL
    #if !X16_USE_VERA
    #define X16_USE_VERA
    #endif
    #if !X16_USE_SCREEN
    #define X16_USE_SCREEN
    #endif
    #if !X16_USE_PALETTE
    #define X16_USE_PALETTE
    #endif
    #if !X16_USE_TILE
    #define X16_USE_TILE
    #endif
    #if !X16_USE_SPRITE
    #define X16_USE_SPRITE
    #endif
    #if !X16_USE_BITMAP
    #define X16_USE_BITMAP
    #endif
    #if !X16_USE_BITMAP2
    #define X16_USE_BITMAP2
    #endif
    #if !X16_USE_VERAFX
    #define X16_USE_VERAFX
    #endif
    #if !X16_USE_IRQ
    #define X16_USE_IRQ
    #endif
    #if !X16_USE_PSG
    #define X16_USE_PSG
    #endif
    #if !X16_USE_YM
    #define X16_USE_YM
    #endif
    #if !X16_USE_PCM
    #define X16_USE_PCM
    #endif
    #if !X16_USE_PCM_STREAM
    #define X16_USE_PCM_STREAM
    #endif
    #if !X16_USE_INPUT
    #define X16_USE_INPUT
    #endif
    #if !X16_USE_BANK
    #define X16_USE_BANK
    #endif
    #if !X16_USE_BANKALLOC
    #define X16_USE_BANKALLOC
    #endif
    #if !X16_USE_MEM
    #define X16_USE_MEM
    #endif
    #if !X16_USE_LOAD
    #define X16_USE_LOAD
    #endif
    #if !X16_USE_DOS
    #define X16_USE_DOS
    #endif
    #if !X16_USE_BMX
    #define X16_USE_BMX
    #endif
    #if !X16_USE_MATH
    #define X16_USE_MATH
    #endif
    #if !X16_USE_CLIP
    #define X16_USE_CLIP
    #endif
    #if !X16_USE_BUFFERS
    #define X16_USE_BUFFERS
    #endif
    #if !X16_USE_ADPCM
    #define X16_USE_ADPCM
    #endif
    #if !X16_USE_ZX0
    #define X16_USE_ZX0
    #endif
    #if !X16_USE_TSC
    #define X16_USE_TSC
    #endif
    #if !X16_USE_FIXED
    #define X16_USE_FIXED
    #endif
    #if !X16_USE_COLLIDE
    #define X16_USE_COLLIDE
    #endif
    #if !X16_USE_BITS
    #define X16_USE_BITS
    #endif
    #if !X16_USE_NUMBER
    #define X16_USE_NUMBER
    #endif
    #if !X16_USE_INT16
    #define X16_USE_INT16
    #endif
    #if !X16_USE_INT32
    #define X16_USE_INT32
    #endif
    #if !X16_USE_FLOAT
    #define X16_USE_FLOAT
    #endif
#endif

// --- dependencies ----------------------------------------------------
// sprite_init_all, psg_init, gfx_clear and gfx_hline all call vera_fill.
// gfx_init calls screen_set_mode. The PCM streamer's AFLOW service runs
// inside irq_handler, so it needs the IRQ module (and PCM itself).
#if X16_USE_SPRITE
#if !X16_USE_VERA
#define X16_USE_VERA
#endif
#endif
#if X16_USE_PSG
#if !X16_USE_VERA
#define X16_USE_VERA
#endif
#endif
#if X16_USE_INT16
#if !X16_USE_NUMBER
#define X16_USE_NUMBER
#endif
#endif
#if X16_USE_BITMAP
    #if !X16_USE_VERA
    #define X16_USE_VERA
    #endif
    #if !X16_USE_SCREEN
    #define X16_USE_SCREEN
    #endif
#endif
#if X16_USE_SHAPES_POLY
    #if !X16_USE_SHAPES
    #define X16_USE_SHAPES
    #endif
    #if !X16_USE_MATH
    #define X16_USE_MATH
    #endif
#endif
#if X16_USE_SHAPES
    #if !SHP_PSET
        #if !X16_USE_BITMAP2
        #define X16_USE_BITMAP2
        #endif
#endif
#endif
// util/double.asm stands alone (no module dependencies). This otherwise
// empty gate block is what makes the 64tass gate-model generator register
// xuse_double -- it scans the dependency section here, not the module
// !source lines below. DOUBLE is deliberately kept OUT of X16_USE_ALL so
// the dist blob stays under the $9EFF low-RAM ceiling.
#if X16_USE_DOUBLE
#endif
#if X16_USE_BITMAP2
    #if !X16_USE_VERA
    #define X16_USE_VERA
    #endif
    #if !X16_USE_VERAFX_FILL
    #define X16_USE_VERAFX_FILL
    #endif
#endif

// --- VERAFX's parts --------------------------------------------------
// X16_USE_VERAFX still means all of it, so nothing that exists breaks.
// The sub-gates are for programs that want one part and not 2.5 KB of
// the others: gfx2 asks for FILL alone and saves 2,162 bytes by it.
// Every part leaves FX through fx_off, so _ANY carries it.
#if X16_USE_VERAFX
    #if !X16_USE_VERAFX_MULT
    #define X16_USE_VERAFX_MULT
    #endif
    #if !X16_USE_VERAFX_FILL
    #define X16_USE_VERAFX_FILL
    #endif
    #if !X16_USE_VERAFX_COPY
    #define X16_USE_VERAFX_COPY
    #endif
    #if !X16_USE_VERAFX_TRANSP
    #define X16_USE_VERAFX_TRANSP
    #endif
    #if !X16_USE_VERAFX_AFFINE
    #define X16_USE_VERAFX_AFFINE
    #endif
    #if !X16_USE_VERAFX_LINE
    #define X16_USE_VERAFX_LINE
    #endif
    #if !X16_USE_VERAFX_TRI
    #define X16_USE_VERAFX_TRI
    #endif
#endif
#if X16_USE_VERAFX_MULT
#if !X16_USE_VERAFX_ANY
#define X16_USE_VERAFX_ANY
#endif
#endif
#if X16_USE_VERAFX_FILL
#if !X16_USE_VERAFX_ANY
#define X16_USE_VERAFX_ANY
#endif
#endif
#if X16_USE_VERAFX_COPY
#if !X16_USE_VERAFX_ANY
#define X16_USE_VERAFX_ANY
#endif
#endif
#if X16_USE_VERAFX_TRANSP
#if !X16_USE_VERAFX_ANY
#define X16_USE_VERAFX_ANY
#endif
#endif
#if X16_USE_VERAFX_AFFINE
#if !X16_USE_VERAFX_ANY
#define X16_USE_VERAFX_ANY
#endif
#endif
#if X16_USE_VERAFX_LINE
#if !X16_USE_VERAFX_ANY
#define X16_USE_VERAFX_ANY
#endif
#endif
#if X16_USE_VERAFX_TRI
#if !X16_USE_VERAFX_ANY
#define X16_USE_VERAFX_ANY
#endif
#endif
// LINE and TRI share verafx.asm's x16_code_udiv24 / x16_code_pix_addr helpers; either
// one carries them (internal gate, not meant to be set by programs).
#if X16_USE_VERAFX_LINE
#if !X16_USE_VERAFX_LINETRI
#define X16_USE_VERAFX_LINETRI
#endif
#endif
#if X16_USE_VERAFX_TRI
#if !X16_USE_VERAFX_LINETRI
#define X16_USE_VERAFX_LINETRI
#endif
#endif
#if X16_USE_PCM_STREAM
    #if !X16_USE_PCM
    #define X16_USE_PCM
    #endif
    #if !X16_USE_IRQ
    #define X16_USE_IRQ
    #endif
#endif

// --- split modules ---------------------------------------------------
// Same shape as VERAFX above: the umbrella gate still means the whole
// module, so nothing that exists breaks; a program that wants the core
// and not a rarely-used extra sets the _CORE gate and leaves the extra
// out. _ANY sources the file.
//   VERA   core = set_addr/fill/has_fx;   _COPY   = vera_copy
//   IRQ    core = install/line/frames/handler; _VSYNC = vsync_wait;
//          _SPRCOL = collision capture (handler accumulate + mask);
//          _SPRCOL_API = install/remove/sprite_collisions/callback
//   INPUT  core = mouse/joy/key_get;      _KEYWAIT = key_wait/key_peek
//   SCREEN core = set_mode/reset/cls/chrout/color/locate;
//          _EXTRA = get_mode/border/get_cursor/charset/puts
#if X16_USE_VERA
    #if !X16_USE_VERA_CORE
    #define X16_USE_VERA_CORE
    #endif
    #if !X16_USE_VERA_COPY
    #define X16_USE_VERA_COPY
    #endif
#endif
#if X16_USE_VERA_CORE
#if !X16_USE_VERA_ANY
#define X16_USE_VERA_ANY
#endif
#endif
#if X16_USE_VERA_COPY
#if !X16_USE_VERA_ANY
#define X16_USE_VERA_ANY
#endif
#endif
#if X16_USE_IRQ
    #if !X16_USE_IRQ_CORE
    #define X16_USE_IRQ_CORE
    #endif
    #if !X16_USE_IRQ_VSYNC
    #define X16_USE_IRQ_VSYNC
    #endif
    #if !X16_USE_IRQ_SPRCOL
    #define X16_USE_IRQ_SPRCOL
    #endif
    #if !X16_USE_IRQ_SPRCOL_API
    #define X16_USE_IRQ_SPRCOL_API
    #endif
#endif
#if X16_USE_IRQ_SPRCOL_API
#if !X16_USE_IRQ_SPRCOL
#define X16_USE_IRQ_SPRCOL
#endif
#endif
#if X16_USE_IRQ_CORE
#if !X16_USE_IRQ_ANY
#define X16_USE_IRQ_ANY
#endif
#endif
#if X16_USE_IRQ_VSYNC
#if !X16_USE_IRQ_ANY
#define X16_USE_IRQ_ANY
#endif
#endif
#if X16_USE_IRQ_SPRCOL
#if !X16_USE_IRQ_ANY
#define X16_USE_IRQ_ANY
#endif
#endif
#if X16_USE_INPUT
    #if !X16_USE_INPUT_CORE
    #define X16_USE_INPUT_CORE
    #endif
    #if !X16_USE_INPUT_KEYWAIT
    #define X16_USE_INPUT_KEYWAIT
    #endif
#endif
#if X16_USE_INPUT_CORE
#if !X16_USE_INPUT_ANY
#define X16_USE_INPUT_ANY
#endif
#endif
#if X16_USE_INPUT_KEYWAIT
#if !X16_USE_INPUT_ANY
#define X16_USE_INPUT_ANY
#endif
#endif
#if X16_USE_SCREEN
    #if !X16_USE_SCREEN_CORE
    #define X16_USE_SCREEN_CORE
    #endif
    #if !X16_USE_SCREEN_EXTRA
    #define X16_USE_SCREEN_EXTRA
    #endif
#endif
#if X16_USE_SCREEN_CORE
#if !X16_USE_SCREEN_ANY
#define X16_USE_SCREEN_ANY
#endif
#endif
#if X16_USE_SCREEN_EXTRA
#if !X16_USE_SCREEN_ANY
#define X16_USE_SCREEN_ANY
#endif
#endif

// --- modules ---------------------------------------------------------
#if X16_USE_VERA_ANY
#import "video/vera.asm"
#endif
#if X16_USE_SCREEN_ANY
#import "video/screen.asm"
#endif
#if X16_USE_PALETTE
#import "video/palette.asm"
#endif
#if X16_USE_TILE
#import "video/tile.asm"
#endif
#if X16_USE_SPRITE
#import "sprite/sprite.asm"
#endif
#if X16_USE_BITMAP
#import "gfx/bitmap.asm"
#endif
#if X16_USE_BITMAP2
#import "gfx/bitmap2.asm"
#endif
#if X16_USE_SHAPES
#import "gfx/shapes.asm"
#endif
#if X16_USE_VERAFX_ANY
#import "gfx/verafx.asm"
#endif
#if X16_USE_IRQ_ANY
#import "system/irq.asm"
#endif
#if X16_USE_PSG
#import "audio/psg.asm"
#endif
#if X16_USE_YM
#import "audio/ym.asm"
#endif
#if X16_USE_PCM
#import "audio/pcm.asm"
#endif
#if X16_USE_INPUT_ANY
#import "input/input.asm"
#endif
#if X16_USE_BANK
#import "storage/bank.asm"
#endif
#if X16_USE_BANKALLOC
#import "storage/bankalloc.asm"
#endif
#if X16_USE_MEM
#import "storage/mem.asm"
#endif
#if X16_USE_LOAD
#import "storage/load.asm"
#endif
#if X16_USE_DOS
#import "storage/dos.asm"
#endif
#if X16_USE_BMX
#import "storage/bmx.asm"
#endif
#if X16_USE_MATH
#import "util/math.asm"
#endif
#if X16_USE_CLIP
#import "util/clip.asm"
#endif
#if X16_USE_BUFFERS
#import "util/buffers.asm"
#endif
#if X16_USE_ADPCM
#import "audio/adpcm.asm"
#endif
#if X16_USE_ZX0
#import "util/zx0.asm"
#endif
#if X16_USE_TSC
#import "util/tscrunch.asm"
#endif
#if X16_USE_FIXED
#import "util/fixed.asm"
#endif
#if X16_USE_COLLIDE
#import "util/collide.asm"
#endif
#if X16_USE_BITS
#import "util/bits.asm"
#endif
#if X16_USE_NUMBER
#import "util/number.asm"
#endif
#if X16_USE_INT16
#import "util/int16.asm"
#endif
#if X16_USE_INT32
#import "util/int32.asm"
#endif
#if X16_USE_FLOAT
#import "util/float.asm"
#endif
#if X16_USE_DOUBLE
#import "util/double.asm"
#endif
