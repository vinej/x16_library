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
;   X16_USE_BITMAP    gfx_init, gfx_clear, gfx_pset, gfx_hline,
;                     gfx_vline, gfx_rect, gfx_frame, gfx_line
;   X16_USE_VERAFX    fx_mult, fx_fill, fx_clear, fx_off
;   X16_USE_IRQ       irq_install, irq_remove, irq_frames, vsync_wait
;   X16_USE_PSG       psg_init, psg_set_freq/vol/wave, psg_note_off
;   X16_USE_YM        ym_write, ym_busy, ym_init, ym_poke, ym_patch,
;                     ym_note, ym_note_bas, ym_release_note, ym_vol,
;                     ym_pan, ym_drum, ym_get_pan, ym_get_vol
;   X16_USE_PCM       pcm_ctrl, pcm_rate, pcm_reset, pcm_full/empty,
;                     pcm_put, pcm_write
;   X16_USE_INPUT     joy_scan, joy_get, mouse_show/hide/get,
;                     key_get, key_wait, key_peek
;   X16_USE_BANK      bank_set/get, bank_peek/poke, mem_to_bank,
;                     bank_to_mem
;   X16_USE_LOAD      fs_setname, fs_load, fs_save, fs_vload
;   X16_USE_FIXED     umul16, mul88
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
; =====================================================================

; Gates are set with !ifndef so that asking for a module twice -- say via
; X16_USE_ALL and again through a dependency -- is not a redefinition
; error, and so an explicit X16_USE_* in your program still works.
!ifdef X16_USE_ALL {
    !ifndef X16_USE_VERA    { X16_USE_VERA    = 1 }
    !ifndef X16_USE_SCREEN  { X16_USE_SCREEN  = 1 }
    !ifndef X16_USE_PALETTE { X16_USE_PALETTE = 1 }
    !ifndef X16_USE_TILE    { X16_USE_TILE    = 1 }
    !ifndef X16_USE_SPRITE  { X16_USE_SPRITE  = 1 }
    !ifndef X16_USE_BITMAP  { X16_USE_BITMAP  = 1 }
    !ifndef X16_USE_VERAFX  { X16_USE_VERAFX  = 1 }
    !ifndef X16_USE_IRQ     { X16_USE_IRQ     = 1 }
    !ifndef X16_USE_PSG     { X16_USE_PSG     = 1 }
    !ifndef X16_USE_YM      { X16_USE_YM      = 1 }
    !ifndef X16_USE_PCM     { X16_USE_PCM     = 1 }
    !ifndef X16_USE_INPUT   { X16_USE_INPUT   = 1 }
    !ifndef X16_USE_BANK    { X16_USE_BANK    = 1 }
    !ifndef X16_USE_LOAD    { X16_USE_LOAD    = 1 }
    !ifndef X16_USE_FIXED   { X16_USE_FIXED   = 1 }
    !ifndef X16_USE_COLLIDE { X16_USE_COLLIDE = 1 }
    !ifndef X16_USE_BITS    { X16_USE_BITS    = 1 }
    !ifndef X16_USE_NUMBER  { X16_USE_NUMBER  = 1 }
    !ifndef X16_USE_INT16   { X16_USE_INT16   = 1 }
    !ifndef X16_USE_INT32   { X16_USE_INT32   = 1 }
    !ifndef X16_USE_FLOAT   { X16_USE_FLOAT   = 1 }
}

; --- dependencies ----------------------------------------------------
; sprite_init_all, psg_init, gfx_clear and gfx_hline all call vera_fill.
; gfx_init calls screen_set_mode.
!ifdef X16_USE_SPRITE { !ifndef X16_USE_VERA { X16_USE_VERA = 1 } }
!ifdef X16_USE_PSG    { !ifndef X16_USE_VERA { X16_USE_VERA = 1 } }
!ifdef X16_USE_INT16  { !ifndef X16_USE_NUMBER { X16_USE_NUMBER = 1 } }
!ifdef X16_USE_BITMAP {
    !ifndef X16_USE_VERA   { X16_USE_VERA   = 1 }
    !ifndef X16_USE_SCREEN { X16_USE_SCREEN = 1 }
}

; --- modules ---------------------------------------------------------
!ifdef X16_USE_VERA    { !source "video/vera.asm" }
!ifdef X16_USE_SCREEN  { !source "video/screen.asm" }
!ifdef X16_USE_PALETTE { !source "video/palette.asm" }
!ifdef X16_USE_TILE    { !source "video/tile.asm" }
!ifdef X16_USE_SPRITE  { !source "sprite/sprite.asm" }
!ifdef X16_USE_BITMAP  { !source "gfx/bitmap.asm" }
!ifdef X16_USE_VERAFX  { !source "gfx/verafx.asm" }
!ifdef X16_USE_IRQ     { !source "system/irq.asm" }
!ifdef X16_USE_PSG     { !source "audio/psg.asm" }
!ifdef X16_USE_YM      { !source "audio/ym.asm" }
!ifdef X16_USE_PCM     { !source "audio/pcm.asm" }
!ifdef X16_USE_INPUT   { !source "input/input.asm" }
!ifdef X16_USE_BANK    { !source "storage/bank.asm" }
!ifdef X16_USE_LOAD    { !source "storage/load.asm" }
!ifdef X16_USE_FIXED   { !source "util/fixed.asm" }
!ifdef X16_USE_COLLIDE { !source "util/collide.asm" }
!ifdef X16_USE_BITS    { !source "util/bits.asm" }
!ifdef X16_USE_NUMBER  { !source "util/number.asm" }
!ifdef X16_USE_INT16   { !source "util/int16.asm" }
!ifdef X16_USE_INT32   { !source "util/int32.asm" }
!ifdef X16_USE_FLOAT   { !source "util/float.asm" }
