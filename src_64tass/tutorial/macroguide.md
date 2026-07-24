# x16lib Macro Guide — the friendly `xm_*` layer

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Every routine in x16lib is called by loading an argument block and doing a
`jsr`: a 16-bit coordinate into `X16_P0`/`X16_P1`, a colour into `A`, and so on.
That is precise and fast, but writing a dozen `lda`/`sta` lines per call is a
chore. `core/sugar.asm` removes the chore: **one macro per routine**, named
`xm_<routine>`, that takes the arguments in order and makes the call.

```asm
#xm_shape_frrect 40, 40, 200, 110, 28, FILL  ; a filled rounded rectangle
```

is exactly

```asm
    lda #<40  : sta rr_x  : lda #>40  : sta rr_x+1
    lda #<40  : sta rr_y  : lda #>40  : sta rr_y+1
    lda #<200 : sta rr_w  : lda #>200 : sta rr_w+1
    lda #<110 : sta rr_h  : lda #>110 : sta rr_h+1
    lda #28   : sta rr_r
    lda #FILL
    jsr shape_frrect
```

This is the same idea as the CXRF `asmsdk` `cxm_*` layer, adapted to x16lib.
It is **optional** — it changes nothing about the library, and this guide is a
companion to the [User Guide](userguide.md), which documents the routines
themselves. If a macro's behaviour is unclear, read its routine there; the macro
just fills in the argument block.

---

## Table of contents

1. [Using the layer](#using-the-layer)
2. [The three rules](#the-three-rules)
3. [Before and after](#before-and-after)
4. [Run-time values and argument-free calls](#run-time-values-and-argument-free-calls)
5. [Reference](#reference)
   - Modules are listed there as bold entries, for example
     `**VERA (X16_USE_VERA)**`.
6. [Worked examples](#worked-examples)
7. [Other assemblers](#other-assemblers)

---

## Using the layer

Set your `X16_USE_*` gates first, then source the layer — **after** the gates and
**before** your own code:

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_BITMAP2H     = 1  ; your gates first
X16_USE_SHAPES_RRECT = 1
X16_USE_PALETTE      = 1

.include "core/sugar.asm"  ; <- the optional macros, after the gates

* = $0801
    #basic_stub
main
    #xm_gfx2h_init
    #xm_gfx2h_clear 0
    #xm_pal_set 1, $0F00  ; entry 1 = red
    #xm_shape_frrect 40, 40, 200, 110, 28, 1
    rts

.include "x16_code.asm"
```

Order matters for two reasons. `x16.asm` defines `X16_P0…P7` and the constants
the macros use, so it comes first. And each module's macros are wrapped in that
module's gate (see the next section), so the gates must be set before the layer
is sourced.

---

## The three rules

**1. It is purely additive.** A program that does not source `core/sugar.asm`, or
sources it but invokes no macro, assembles to byte-for-byte the same bytes as
before. Each macro expands to exactly the hand-written setup plus the `jsr` — no
hidden cost, no wrapper subroutine, nothing at run time.

**2. Macros are gated by their module.** `xm_pal_set` only exists when
`X16_USE_PALETTE` is set, `xm_shape_arc` only when `X16_USE_SHAPES_ARC` is set,
and so on. This keeps a macro from ever naming a routine you did not build (which
the stricter assemblers reject outright). The practical consequence: **set the
gate to get its macros.** The sub-gates (`SHAPES_RRECT`, `PCM_STREAM`, …) each
gate their own — enabling `X16_USE_SHAPES` gives you `xm_shape_circle` but not
`xm_shape_rrect` until you also set `X16_USE_SHAPES_RRECT`.

**3. Arguments are immediates.** A macro loads each argument with `lda #arg`, so
pass **constants or assemble-time expressions**. You cannot feed a macro a value
held in a variable:

```asm
    #xm_shape_polygon 320, 240, 80, 6, angle, 1  ; WRONG if `angle` is a variable
```

`#angle` is the *address* of `angle`, not the rotation stored there. When an
argument is computed at run time, set the block by hand and `jsr` the routine —
see [Run-time values](#run-time-values-and-argument-free-calls).

---

## Before and after

A hexagon, outlined, at a fixed rotation:

```asm
  ; --- by hand ---
    lda #<320 : sta X16_P0 : lda #>320 : sta X16_P1
    lda #<240 : sta X16_P2 : lda #>240 : sta X16_P3
    lda #80   : sta X16_P4
    lda #6    : sta X16_P5
    lda #0    : sta X16_P6
    lda #1
    jsr shape_polygon

  ; --- with the macro ---
    #xm_shape_polygon 320, 240, 80, 6, 0, 1
```

Both assemble to the same machine code. The macro is just a name for the
argument order.

---

## Run-time values and argument-free calls

Two kinds of call keep the hand-written form, on purpose.

**Run-time arguments.** Anything that changes as the program runs — a sprite's
live position, a decaying volume, a frame counter — has to go into the argument
block by hand, because the macro would try to load the *address* of the variable
instead of its value:

```asm
draw_sprite
    lda pos_x+1  ; the live 16-bit position
    sta X16_P0
    lda pos_x+2
    sta X16_P1
    lda pos_y+1
    sta X16_P2
    lda pos_y+2
    sta X16_P3
    ldx #0
    jmp sprite_pos  ; not #xm_sprite_pos: the position is run-time
```

`examples/m_bounce.asm` is the honest picture: the one-shot setup (constant
arguments) is all `xm_*` macros, while the per-frame work on live values stays
hand-written.

**Argument-free routines.** Routines that take no arguments — the accumulator
operations (`i16_add`, `i16_mul`, `f_sqrt`, `f_sin`, `d_exp`), the toggles
(`sprites_on`, `fx_off`), the queries (`vera_has_fx`, `irq_frames`) — have **no
macro**. A wrapper would be nothing but `jsr name`, so just write that:

```asm
    #i16_const i16_a, 1000  ; load the operands (a macro from core/macros.asm)
    #i16_const i16_b, 7
    jsr i16_divmod  ; the operation itself takes no arguments
```

Load operands into `i16_a`/`i16_b`, `FAC`, `d_ac` with the existing
`#i16_const`/`#i32_const` macros or the `xm_*_load`/`xm_*_from_*` macros, then
`jsr` the operation.

---

## Reference

Every macro, grouped by module. Each takes the routine's arguments in order;
16-bit values (coordinates, sizes, addresses) are passed whole and split inside
the macro. A `→` note is what the routine returns — the macro does not capture
it, so read it from the registers/flags/P-block afterwards. Angles are the
`sin8`/`cos8` byte convention: `0` = east, `64` = south.

**VERA (X16_USE_VERA)**

[Detailed macro reference](macro_vera.md)

| Macro | Does |
|---|---|
| `#xm_vera_set_addr0 l, m, h` | point data port 0 (compose the H byte yourself) |
| `#xm_vera_set_addr1 l, m, h` | point data port 1 |
| `#xm_vera_fill val, count` | write `val` `count` times from the current address |
| `#xm_vera_copy count` | copy `count` bytes port 0 → port 1 (both pre-pointed) |

**Display composer (X16_USE_VERA_DC)**

[Detailed macro reference](macro_display_composer.md)

| Macro | Does |
|---|---|
| `#xm_vdc_get_video` / `#xm_vdc_set_video video` | read/write `DC_VIDEO` |
| `#xm_vdc_set_output mode` | set output mode while preserving other video bits |
| `#xm_vdc_set_layers mask` / `#xm_vdc_layer_on mask` / `#xm_vdc_layer_off mask` | layer/sprite enables |
| `#xm_vdc_get_scale` / `#xm_vdc_set_scale hscale, vscale` | read/write composer scale |
| `#xm_vdc_get_border` / `#xm_vdc_set_border color` | border palette index |
| `#xm_vdc_get_active_raw` / `#xm_vdc_set_active_raw hstart, hstop, vstart, vstop` | raw active-display registers |
| `#xm_vdc_set_active hstart, hstop, vstart, vstop` / `#xm_vdc_fullscreen` | pixel-coordinate active display |
| `#xm_vdc_get_version` | VERA bitstream version (-> carry set if valid) |

**Screen (X16_USE_SCREEN)**

[Detailed macro reference](macro_screen.md)

| Macro | Does |
|---|---|
| `#xm_screen_set_mode mode` | set the screen mode (→ carry set if unsupported) |
| `#xm_screen_reset` | restore the default text mode |
| `#xm_screen_cls` | clear the text screen |
| `#xm_screen_chrout ch` | print one character, safely |
| `#xm_screen_color fg, bg` | text foreground / background (0–15) |
| `#xm_screen_border col` | border colour (0–15) |
| `#xm_screen_locate row, col` | move the text cursor |
| `#xm_screen_charset cs` | select a charset |
| `#xm_screen_puts addr` | print a NUL-terminated string |

**Palette (X16_USE_PALETTE)**

[Detailed macro reference](macro_palette.md)

| Macro | Does |
|---|---|
| `#xm_pal_set index, rgb` | set one entry; `rgb` is a 12-bit `$0RGB` value |
| `#xm_pal_load src, first, count` | bulk-load `count` entries from RAM |

**Tiles and layers (X16_USE_TILE)**

[Detailed macro reference](macro_tiles.md)

| Macro | Does |
|---|---|
| `#xm_layer_on layer` / `#xm_layer_off layer` | enable / disable a layer |
| `#xm_layer_set_config layer, cfg` | the layer's CONFIG byte |
| `#xm_layer_set_mapbase layer, base` | where the map lives (VRAM ≫ 9) |
| `#xm_layer_scroll_x layer, val` / `#xm_layer_scroll_y layer, val` | 12-bit hardware scroll |
| `#xm_tile_setptr col, row` | point port 0 at a layer-1 map cell |
| `#xm_tile_put col, row, code, attr` | write one cell |
| `#xm_tile_get col, row` | read one cell (→ A = code, X = attribute) |

**Sprites (X16_USE_SPRITE)**

[Detailed macro reference](macro_sprites.md)

| Macro | Does |
|---|---|
| `#xm_sprites_on` / `#xm_sprites_off` | the sprite renderer as a whole |
| `#xm_sprite_init_all` | zero all 128 attribute records |
| `#xm_sprite_pos sprite, x, y` | set a sprite's 10-bit position |
| `#xm_sprite_get_pos sprite` | read it back (→ P0/1 = x, P2/3 = y) |
| `#xm_sprite_image sprite, vaddr, mode` | point at pixels; `mode` = `SPRITE_MODE_4BPP`/`8BPP` |
| `#xm_sprite_flags sprite, flags` | byte 6: collision mask, Z, flips |
| `#xm_sprite_z sprite, z` | change only the Z-depth |
| `#xm_sprite_size sprite, wcode, hcode, paloff` | size codes + palette offset |

**Bitmap graphics (X16_USE_BITMAP8L/2H/2L/4L/4H/8H)**

[Detailed macro reference](macro_bitmap.md)

| Gate / prefix | Does |
|---|---|
| `X16_USE_BITMAP8L` / `gfx8l` | 320x240, 8 bpp, VERA VRAM; init, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, char/text |
| `X16_USE_BITMAP4L` / `gfx4l` | 320x240, 4 bpp, VERA VRAM; same as 8L, with 4-bit pixels |
| `X16_USE_BITMAP2L` / `gfx2l` | 320x240, 2 bpp, VERA VRAM; init, clear, setptr, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm |
| `X16_USE_BITMAP2H` / `gfx2h` | 640x480, 2 bpp, MiSTer VERA_2 SDRAM; same as 2L at high resolution |
| `X16_USE_BITMAP4H` / `gfx4h` | 640x480, 4 bpp, MiSTer VERA_2 SDRAM; `has/init/off`, passthru, palette, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, copy |
| `X16_USE_BITMAP8H` / `gfx8h` | 640x480, 8 bpp, MiSTer VERA_2 SDRAM; same as 4H, with 8-bit pixels |

**Framebuffer (X16_USE_FB)**

[Detailed macro reference](macro_framebuffer.md)

| Macro | Does |
|---|---|
| `#xm_fb_init` / `#xm_fb_get_info` | active KERNAL framebuffer driver |
| `#xm_fb_set_palette data, start, count` | set palette entries |
| `#xm_fb_cursor_position x, y` / `#xm_fb_cursor_next_line` | framebuffer cursor |
| `#xm_fb_get_pixel x, y` / `#xm_fb_set_pixel x, y, color` | one pixel |
| `#xm_fb_get_pixels dest, count` / `#xm_fb_set_pixels src, count` | pixel runs |
| `#xm_fb_set_8_pixels pattern, color` / `#xm_fb_set_8_pixels_opaque mask, pattern, fg, bg` | 8-pixel pattern helpers |
| `#xm_fb_fill_pixels count, step, color` / `#xm_fb_filter_pixels count, filter` | fill/filter from cursor |
| `#xm_fb_move_pixels sx, sy, tx, ty, count` | move a horizontal span |

**GRAPH (X16_USE_GRAPH)**

[Detailed macro reference](macro_graph.md)

| Macro | Does |
|---|---|
| `#xm_graph_init_default` / `#xm_graph_init driver` | init GRAPH with default/custom FB driver |
| `#xm_graph_clear` / `#xm_graph_set_window x, y, w, h` | clear/window |
| `#xm_graph_set_colors stroke, fill, background` | drawing colours |
| `#xm_graph_draw_line x1, y1, x2, y2` | line |
| `#xm_graph_draw_rect_outline/fill x, y, w, h, radius` | rectangles |
| `#xm_graph_move_rect sx, sy, tx, ty, w, h` | move rectangle |
| `#xm_graph_draw_oval_outline/fill x, y, w, h` | ovals |
| `#xm_graph_draw_image x, y, image, w, h` | image bytes |
| `#xm_graph_set_font_default` / `#xm_graph_set_font font` | font |
| `#xm_graph_get_char_size char, style` / `#xm_graph_put_char char, x, y` | text metrics/draw |

**Console (X16_USE_CONSOLE)**

[Detailed macro reference](macro_console.md)

| Macro | Does |
|---|---|
| `#xm_con_init_fullscreen` / `#xm_con_init x, y, w, h` | initialize console |
| `#xm_con_set_paging_message msg` / `#xm_con_disable_paging` | paging controls |
| `#xm_con_put_char_wrap char` / `#xm_con_put_char_word char` | print with wrapping |
| `#xm_con_get_char` | read one console character |
| `#xm_con_put_image image, w, h` | draw console image data |

**Shapes (X16_USE_SHAPES + sub-gates)**

[Detailed macro reference](macro_shapes.md)

| Macro | Does |
|---|---|
| `SHP_*` bindings | engine selection; default is 2 bpp |
| `#xm_shape_circle cx, cy, r, col` / `#xm_shape_disc ...` | `SHAPES` gate |
| `#xm_shape_ellipse cx, cy, rx, ry, col` / `#xm_shape_fellipse ...` | `SHAPES` gate |
| `#xm_shape_flood x, y, col` | `SHAPES` gate; → carry set = stack overflowed |
| `#xm_shape_polygon cx, cy, r, sides, rot, col` / `#xm_shape_fpolygon ...` | `SHAPES_POLY` gate |
| `#xm_shape_rrect x, y, w, h, r, col` / `#xm_shape_frrect ...` | `SHAPES_RRECT` gate |
| `#xm_shape_arc cx, cy, r, a0, a1, col` | `SHAPES_ARC` gate |
| `#xm_shape_pie cx, cy, r, a0, a1, col` | `SHAPES_PIE` gate |
| `#xm_shape_bezier x0, y0, x1, y1, x2, y2, x3, y3, col` | `SHAPES_BEZIER` gate |

**VERA FX (X16_USE_VERAFX)**

[Detailed macro reference](macro_verafx.md)

| Macro | Does |
|---|---|
| `#xm_fx_off` | disable FX (leaves DCSEL/ADDRSEL = 0) |
| `#xm_fx_mult a, b` | signed 16×16 (→ P4..P7 = product) |
| `#xm_fx_fill val, count` | fast fill from the current address |
| `#xm_fx_clear addrlo, addrmid, addrhi, count` | zero a VRAM region |
| `#xm_fx_transp_on` / `#xm_fx_transp_off` | transparent VRAM writes |
| `#xm_fx_line x0, y0, x1, y1, col` | hardware-assisted line |

**VERA FX utilities (X16_USE_VERAFX_UTILS)**

[Detailed macro reference](macro_verafx_utils.md)

| Macro | Does |
|---|---|
| `#xm_fxu_off` / `#xm_fxu_get_ctrl` / `#xm_fxu_set_ctrl ctrl` | FX control |
| `#xm_fxu_ctrl_on mask` / `#xm_fxu_ctrl_off mask` | set/clear FX bits |
| `#xm_fxu_addr1_mode mode` | ADDR1 mode bits |
| `#xm_fxu_cache_write_on/off`, `#xm_fxu_cache_fill_on/off`, `#xm_fxu_cache_cycle_on/off` | cache modes |
| `#xm_fxu_transparent_on/off`, `#xm_fxu_4bit_on/off`, `#xm_fxu_hop_on/off` | transparent, 4-bit, 16-bit hop |
| `#xm_fxu_set_mult mult` / `#xm_fxu_set_cache b0, b1, b2, b3` | multiplier/cache registers |
| `#xm_fxu_reset_accum` / `#xm_fxu_accumulate` | accumulator helpers |
| `#xm_fxu_cache_fill0/1` / `#xm_fxu_cache_write0/1 mask` | cache fill/write primitives |
| `#xm_fxu_set_incr xinc, yinc` / `#xm_fxu_set_pos xpos, ypos` / `#xm_fxu_set_subpos xsub, ysub` | affine stepping state |
| `#xm_fxu_get_poly_fill` / `#xm_fxu_set_tilebase value` / `#xm_fxu_set_mapbase value` | polygon/tile/map helpers |

**Interrupts (X16_USE_IRQ)**

[Detailed macro reference](macro_interrupts.md)

| Macro | Does |
|---|---|
| `#xm_irq_install` / `#xm_irq_remove` | hook / unhook the frame counter |
| `#xm_vsync_wait` | block until the next frame boundary |
| `#xm_irq_line_install handler` | call a handler at a scanline |
| `#xm_irq_sprcol_install handler` (`handler` = 0 polls) / `#xm_irq_sprcol_remove` | sprite-collision interrupt |

**PSG (X16_USE_PSG)**

[Detailed macro reference](macro_psg.md)

| Macro | Does |
|---|---|
| `#xm_psg_init` | silence all 16 voices |
| `#xm_psg_set_freq voice, freq` | frequency word |
| `#xm_psg_set_vol voice, vol, pan` | volume (0–63) + pan |
| `#xm_psg_set_wave voice, wave, width` | waveform + pulse width |
| `#xm_psg_note_off voice` | volume to zero, keep the rest |
| `#xm_psg_env_start / _release / _stop voice` | ASR envelope control |
| `#xm_psg_env_tick` | advance every armed envelope (once a frame) |

**YM2151 (X16_USE_YM)**

[Detailed macro reference](macro_ym2151.md)

| Macro | Does |
|---|---|
| `#xm_ym_init` | reset the chip, load the default patches |
| `#xm_ym_write reg, val` / `#xm_ym_poke reg, val` | raw register write / shadowed write |
| `#xm_ym_patch_rom channel, index` | load a built-in ROM patch (0–162) |
| `#xm_ym_note channel, kc, kf` | play a raw key code |
| `#xm_ym_note_bas channel, note` | play a packed note (0 releases) |
| `#xm_ym_release_note channel` | release |
| `#xm_ym_vol channel, atten` / `#xm_ym_pan channel, pan` | volume / pan |
| `#xm_ym_drum channel, note` | a drum voice |

**ROM audio (X16_USE_AUDIO_ROM)**

[Detailed macro reference](macro_rom_audio.md)

| Macro | Does |
|---|---|
| Scope | thin ROM `BANK_AUDIO` wrappers; separate from local PSG/YM modules |
| `#xm_ar_audio_init`, `#xm_ar_playstring_voice voice` | general ROM audio helpers |
| `#xm_ar_fmplaystring str, len`, `#xm_ar_fmchordstring str, len`, `#xm_ar_psgplaystring str, len`, `#xm_ar_psgchordstring str, len` | play strings/chords |
| `#xm_ar_fmfreq channel, hz`, `#xm_ar_fmfreq_no_retrigger channel, hz`, `#xm_ar_fmnote channel, note, kf`, `#xm_ar_fmnote_no_retrigger channel, note, kf`, `#xm_ar_fmvib speed, depth` | FM helpers |
| `#xm_ar_psgfreq voice, hz`, `#xm_ar_psgnote voice, note, kf`, `#xm_ar_psgwav voice, wave` | PSG helpers |
| `#xm_ar_note_bas2fm`, `bas2midi`, `bas2psg`, `fm2bas`, `fm2midi`, `fm2psg`, `freq2bas/fm/midi/psg`, `midi2bas/fm/psg`, `psg2bas/fm/midi` | note conversion |
| `#xm_ar_psg_init`, `#xm_ar_psg_playfreq`, `#xm_ar_psg_read_raw/cooked`, `#xm_ar_psg_setatten/freq/pan/vol`, `#xm_ar_psg_write`, `#xm_ar_psg_write_fast`, `#xm_ar_psg_getatten/pan` | ROM PSG shadows |
| `#xm_ar_ym_init`, `#xm_ar_ym_loaddefpatches`, `#xm_ar_ym_loadpatch_rom`, `#xm_ar_ym_loadpatchlfn`, `#xm_ar_ym_playdrum/playnote`, `#xm_ar_ym_setatten/drum/note/pan`, `#xm_ar_ym_read_raw/cooked`, `#xm_ar_ym_release`, `#xm_ar_ym_trigger`, `#xm_ar_ym_trigger_no_retrigger`, `#xm_ar_ym_write`, `#xm_ar_ym_getatten/pan`, `#xm_ar_ym_get_chip_type` | ROM YM shadows |

**PCM (X16_USE_PCM, X16_USE_PCM_STREAM)**

[Detailed macro reference](macro_pcm.md)

| Macro | Does |
|---|---|
| `#xm_pcm_ctrl byte` / `#xm_pcm_rate rate` / `#xm_pcm_reset` | `PCM` gate |
| `#xm_pcm_put sample` / `#xm_pcm_write src, count` | `PCM` gate |
| `#xm_pcm_stream_start src, count, loop` / `#xm_pcm_stream_stop` | `PCM_STREAM` gate |

**ZSM (X16_USE_ZSM, X16_USE_ZSM_PCM)**

[Detailed macro reference](macro_zsm.md)

| Macro | Does |
|---|---|
| `#xm_zsm_init header` / `#xm_zsm_init_stream stream, loop` | `ZSM` gate |
| `#xm_zsm_play` / `#xm_zsm_stop` / `#xm_zsm_rewind` | `ZSM` gate |
| `#xm_zsm_get_tickrate` / `#xm_zsm_status` / `#xm_zsm_tick` | `ZSM` gate |
| `#xm_zsm_pcm_present` / `#xm_zsm_pcm_trigger instrument` | `ZSM_PCM` gate |

**ADPCM (X16_USE_ADPCM)**

[Detailed macro reference](macro_adpcm.md)

| Macro | Does |
|---|---|
| `#xm_adpcm_init` | initialize ADPCM state |
| `#xm_adpcm_nibble code` | decode one ADPCM nibble |
| `#xm_adpcm_block src, dst, count` | decode a block |

**WAV (X16_USE_WAV)**

| Macro | Does |
|---|---|
| `#xm_wav_parse_header buf` | parse a RIFF/WAVE header from a buffer into `wav_format`/`wav_channels`/`wav_rate`/`wav_bits`/`wav_data_off`/`wav_data_len`; → carry set on failure |

**Input (X16_USE_INPUT)**

[Detailed macro reference](macro_input.md)

| Macro | Does |
|---|---|
| `#xm_joy_scan` / `#xm_joy_get pad` | sample / read a joystick (→ A/X/Y = buttons) |
| `#xm_mouse_show cursor` / `#xm_mouse_hide` / `#xm_mouse_get` | mouse (→ P0/1 = x, P2/3 = y, A = buttons) |
| `#xm_key_get` / `#xm_key_wait` / `#xm_key_peek` | keyboard (→ A = PETSCII) |

**Keyboard (X16_USE_KEYBOARD)**

[Detailed macro reference](macro_keyboard.md)

| Macro | Does |
|---|---|
| `#xm_kbd_scan` / `#xm_kbd_peek` / `#xm_kbd_put key` | keyboard scan/read/write helpers |
| `#xm_kbd_get_modifiers` | read modifier state |
| `#xm_kbd_get_keymap` / `#xm_kbd_set_keymap name` | keymap helpers |

**Mouse (X16_USE_MOUSE)**

[Detailed macro reference](macro_mouse.md)

| Macro | Does |
|---|---|
| `#xm_mse_config cursor, width8, height8` | configure mouse cursor |
| `#xm_mse_scan` / `#xm_mse_get` / `#xm_mse_get_to zp` | mouse sample/read helpers |
| `#xm_mse_show cursor` / `#xm_mse_show_keep` / `#xm_mse_hide` | mouse visibility helpers |

**Serial (X16_USE_SERIAL)**

[Detailed macro reference](macro_serial.md)

| Macro | Does |
|---|---|
| `base` / `divisor` | `base` is from `ser_detect` or `$9F60`; `divisor` is a `SER_BAUD_*` constant |
| `#xm_ser_detect` | scan for UARTs (→ A = count, `ser_u0`/`ser_u1` = bases) |
| `#xm_ser_init base, divisor` | 8N1, FIFOs, auto-flow; selects that UART |
| `#xm_ser_avail` | → carry set if a byte is waiting |
| `#xm_ser_get` | non-blocking read (→ carry set = empty, else A = byte) |
| `#xm_ser_get_wait` | blocking read (→ A = byte) |
| `#xm_ser_put byte` | send one byte |
| `#xm_ser_puts addr` | send a NUL-terminated string |
| `#xm_ser_write addr, len` | send `len` bytes (binary-safe) |
| `#xm_ser_read_until match, buffer, max` | read into buffer until `match` (→ P4/5 = count) |
| `#xm_ser_discard_until match` | read and discard until `match` |

**ZiModem (X16_USE_SERIAL_ZIMODEM)**

[Detailed macro reference](macro_zimodem.md)

| Macro | Does |
|---|---|
| Scope | ESP32 WiFi modem helpers on top of Serial; most block on real hardware replies |
| `#xm_zi_init base, divisor` | reset the modem to a known state |
| `#xm_zi_cmd addr` | send an `AT…` command line (+ CR/LF) |
| `#xm_zi_wait_ok` | read/discard the reply up to `OK\r\n` |
| `#xm_zi_reset` | `ATZ` |
| `#xm_zi_get_ip buffer` | IPv4 address into buffer (via `ATI2`) |
| `#xm_zi_hex_open filename` | begin a hex-mode download (→ carry set = not found) |
| `#xm_zi_hex_chunk buffer` | next payload chunk (→ A = bytes, 0 = done) |
| `#xm_zi_hex_close` | swallow the trailing `OK` |
| `#xm_zi_hexdecode src, digits, dest` | pack ASCII hex → bytes (→ A = `digits`/2) |

**I2C (X16_USE_I2C)**

[Detailed macro reference](macro_i2c.md)

| Macro | Does |
|---|---|
| `#xm_i2c_read_byte device, offset` | read one byte |
| `#xm_i2c_write_byte value, device, offset` | write one byte |
| `#xm_i2c_batch_read device, buffer, count` | read a sequence |
| `#xm_i2c_batch_read_fixed device, buffer, count` | read from a fixed register |
| `#xm_i2c_batch_write device, buffer, count` | write a sequence |

**VERA SPI (X16_USE_VERA_SPI)**

[Detailed macro reference](macro_vera_spi.md)

| Macro | Does |
|---|---|
| `#xm_spi_get_ctrl` / `#xm_spi_set_ctrl ctrl` | read/write SPI control |
| `#xm_spi_select` / `#xm_spi_deselect` | chip select helpers |
| `#xm_spi_slow` / `#xm_spi_fast` | clock speed helpers |
| `#xm_spi_autotx_on` / `#xm_spi_autotx_off` | auto-transmit controls |
| `#xm_spi_wait` | wait for SPI ready |
| `#xm_spi_transfer byte` | transfer one byte |
| `#xm_spi_read` / `#xm_spi_write byte` / `#xm_spi_autotx_read` | byte I/O helpers |
| `#xm_spi_read_bytes buffer, count` / `#xm_spi_write_bytes buffer, count` | block I/O helpers |

**Banked RAM (X16_USE_BANK)**

[Detailed macro reference](macro_banked_ram.md)

| Macro | Does |
|---|---|
| `#xm_bank_set bank` | map a RAM bank at `$A000` |
| `#xm_bank_peek bank, offset` (→ A = byte) / `#xm_bank_poke bank, offset, byte` | one byte |
| `#xm_mem_to_bank src, bank, offset, count` | copy low RAM into a bank |

**Bank allocator (X16_USE_BANKALLOC)**

[Detailed macro reference](macro_bank_allocator.md)

| Macro | Does |
|---|---|
| `#xm_bank_alloc_init first, last` | initialize allocator range |
| `#xm_bank_alloc` | allocate one bank; → carry clear, A = bank |
| `#xm_bank_free bank` | free one bank |
| `#xm_bank_reserve bank` | reserve one bank |

**Block memory (X16_USE_MEM)**

[Detailed macro reference](macro_block_memory.md)

| Macro | Does |
|---|---|
| `#xm_mem_fill dst, count, val` | fill (streams to VERA too) |
| `#xm_mem_copy src, dst, count` | copy |
| `#xm_mem_crc addr, count` | CRC-16 (→ A/X) |
| `#xm_mem_decompress src, dst` | LZSA2 (→ A/X = one past the end) |

**Load/save (X16_USE_LOAD)**

[Detailed macro reference](macro_load.md)

| Macro | Does |
|---|---|
| `#xm_fs_setname name, len` | set KERNAL filename |
| `#xm_fs_load name, len, device, sa, dst` | load to RAM; → carry set = error, A = code |
| `#xm_fs_vload name, len, device, vbank, vaddr` | load to VRAM |

**File I/O (X16_USE_FILEIO)**

[Detailed macro reference](macro_fileio.md)

| Macro | Does |
|---|---|
| `#xm_fio_set_lfs logical, device, secondary` / `#xm_fio_set_name name, len` | KERNAL file setup |
| `#xm_fio_open_named/open_read/open_write name, len, logical, device, secondary` | open helpers |
| `#xm_fio_close logical` / `#xm_fio_close_named logical` | close helpers |
| `#xm_fio_chkin logical` / `#xm_fio_chkout logical` / `#xm_fio_clrchn` | channel helpers |
| `#xm_fio_chrin` / `#xm_fio_chrout byte` / `#xm_fio_getin` | byte I/O helpers |
| `#xm_fio_readst` | read KERNAL status |
| `#xm_fio_close_all` / `#xm_fio_close_device device` | bulk close helpers |

**IEC (X16_USE_IEC)**

[Detailed macro reference](macro_iec.md)

| Macro | Does |
|---|---|
| `#xm_iec_listen device` / `#xm_iec_talk device` | bus attention helpers |
| `#xm_iec_second command` / `#xm_iec_tksa command` | secondary address helpers |
| `#xm_iec_ciout byte` / `#xm_iec_acptr` | byte I/O helpers |
| `#xm_iec_unlisten` / `#xm_iec_untalk` | release bus helpers |
| `#xm_iec_set_timeout control` / `#xm_iec_readst` | timeout/status helpers |
| `#xm_iec_macptr dest, count` / `#xm_iec_mciout src, count` | block I/O helpers |
| `#xm_iec_open_channel device, secondary` / `#xm_iec_data_channel device, secondary` / `#xm_iec_talk_channel device, secondary` / `#xm_iec_close_channel device, secondary` | channel helpers |

**DOS (X16_USE_DOS)**

[Detailed macro reference](macro_dos.md)

| Macro | Does |
|---|---|
| `#xm_dos_cmd cmd, len` | execute command; → A = status |
| `#xm_dos_status` | read DOS status |
| `#xm_dos_delete name, len` | delete file |

**BMX (X16_USE_BMX)**

[Detailed macro reference](macro_bmx.md)

| Macro | Does |
|---|---|
| `#xm_bmx_load name, len, device, vbank, vaddr` | load BMX image to VRAM |
| `#xm_bmx_load_hires name, len, device` | load BMX image to the VERA_2 640x480 8bpp SDRAM bitmap |

**Clock (X16_USE_CLOCK)**

[Detailed macro reference](macro_clock.md)

| Macro | Does |
|---|---|
| `#xm_clock_update` | update clock state |
| `#xm_clock_get_timer` / `#xm_clock_set_timer ticks` | jiffy timer helpers |
| `#xm_clock_get_date_time` | read date/time |
| `#xm_clock_set_date_time_raw year1900, month, day, hours, minutes, seconds, jiffies, weekday` | set raw date/time |
| `#xm_clock_set_date_time year, month, day, hours, minutes, seconds, weekday` | set date/time |

**Math (X16_USE_MATH)**

[Detailed macro reference](macro_math.md)

| Macro | Does |
|---|---|
| `#xm_rnd_seed seed` | seed the PRNG (16-bit) |
| `#xm_sin8 angle` / `#xm_cos8 angle` | → A = −127..127 |
| `#xm_sin8u angle` / `#xm_cos8u angle` | → A = 1..255 |
| `#xm_atan2 dx, dy` | → A = angle 0–255 (`dx`,`dy` signed bytes) |
| `#xm_lerp8 a, b, t` | → A = interpolated value |

**Collision (X16_USE_COLLIDE)**

[Detailed macro reference](macro_collision.md)

| Macro | Does |
|---|---|
| `#xm_collide8 ax, ay, aw, ah, bx, by, bw, bh` | 8-bit AABB test; → carry set if overlap |
| `#xm_collide16 ...` | 16-bit AABB test; → carry set if overlap |

**Bits (X16_USE_BITS)**

[Detailed macro reference](macro_bits.md)

| Macro | Does |
|---|---|
| `#xm_catnib hi, lo` | combine two nibbles |
| `#xm_hinib byte` / `#xm_lonib byte` | extract high/low nibble |
| `#xm_bit_set addr, mask` / `#xm_bit_clr addr, mask` / `#xm_bit_test addr, mask` | bit operations |

**Number (X16_USE_NUMBER)**

[Detailed macro reference](macro_number.md)

| Macro | Does |
|---|---|
| `#xm_u16_to_dec value` / `#xm_u16_to_hex value` | format unsigned 16-bit; → A/X = buffer, Y = length |
| `#xm_u8_to_dec value` / `#xm_u8_to_hex value` / `#xm_u8_to_bin value` | format unsigned 8-bit as decimal / 2 hex / 8 binary digits |
| `#xm_u16_to_bin value` | format unsigned 16-bit as 16 binary digits |
| `#xm_s8_to_dec value` / `#xm_s16_to_dec value` | format signed 8/16-bit as decimal with a leading '-' |

**Sort (X16_USE_SORT)**

[Detailed macro reference](macro_sort.md)

| Macro | Does |
|---|---|
| `#xm_sort_u8 ptr, count` / `#xm_sort_s8 ptr, count` | sort a block of unsigned / signed bytes in place |
| `#xm_sort_u16 ptr, count` / `#xm_sort_s16 ptr, count` | sort a block of unsigned / signed words in place |
| `#xm_sort_ptr ptr, count, cmp` | sort 2-byte elements with a caller comparator |
| `#xm_dec_to_u16 str, len` | parse decimal; → P4/5 = value, carry set on bad digit |

**Fixed point (X16_USE_FIXED)**

[Detailed macro reference](macro_fixed.md)

| Macro | Does |
|---|---|
| `#xm_umul16 a, b` | unsigned 16x16 multiply; → P4..P7 = product |
| `#xm_mul88 a, b` | signed 8.8 multiply; → P0/1 |

**Integers (X16_USE_INT16, X16_USE_INT32)**

[Detailed macro reference](macro_integers.md)

| Macro / routine | Does |
|---|---|
| `i16_add`, `i16_mul`, `i32_divmod`, … | argument-free routines; load `i16_a`/`i16_b` or `i32_a`/`i32_b`, then `jsr` |
| `#xm_i16_from_u8 byte` / `#xm_i16_from_s8 byte` | integer loaders |
| `#xm_i32_from_u16 value` / `#xm_i32_from_s16 value` | integer loaders |

**Float (X16_USE_FLOAT)**

[Detailed macro reference](macro_float.md)

| Macro | Does |
|---|---|
| `FAC` / `addr` | accumulator / pointer to a 5-byte float in memory |
| `f_sqrt`, `f_sin`, `f_ln`, `f_int`, … | argument-free unary routines; call directly |
| `#xm_f_from_u8 byte` / `#xm_f_from_s16 value` | build FAC from an integer |
| `#xm_f_from_str str, len` | parse a string into FAC |
| `#xm_f_load addr` / `#xm_f_store addr` | FAC ↔ memory |
| `#xm_f_add / _sub / _mul / _div addr` | FAC ⊕ mem |
| `#xm_f_rsub addr` / `#xm_f_rdiv addr` | mem − FAC / mem ÷ FAC |
| `#xm_f_pow addr` | FAC = FAC ^ mem |
| `#xm_f_cmp addr` | → A = −1 / 0 / 1 |

**Double (X16_USE_DOUBLE)**

[Detailed macro reference](macro_double.md)

| Macro | Does |
|---|---|
| `d_ac` / `addr` | accumulator / pointer to an 8-byte double in memory |
| `d_exp`, `d_sqrt`, `d_sin`, … | argument-free unary routines; call directly |
| `#xm_d_from_s16 value` / `#xm_d_from_str str, len` | build d_ac |
| `#xm_d_load addr` / `#xm_d_store addr` | d_ac ↔ memory |
| `#xm_d_add / _sub / _mul / _div addr` | d_ac ⊕ mem |
| `#xm_d_pow addr` | d_ac = d_ac ^ mem |
| `#xm_d_cmp addr` | → A = −1 / 0 / 1 |

**Clip (X16_USE_CLIP)**

[Detailed macro reference](macro_clip.md)

| Macro | Does |
|---|---|
| `#xm_clip_set xmin, ymin, xmax, ymax` | set the clip rectangle |

**Buffers (X16_USE_BUFFERS)**

[Detailed macro reference](macro_buffers.md)

| Macro | Does |
|---|---|
| `#xm_rb_init` / `#xm_rb_count` | ring buffer init / count |
| `#xm_rb_put byte` | ring buffer put; → carry set = full |
| `#xm_rb_get` | ring buffer get; → A = byte, carry set = empty |
| `#xm_stk_init` / `#xm_stk_push byte` / `#xm_stk_pop` / `#xm_stk_depth` | byte stack helpers |

**Compression (X16_USE_ZX0, X16_USE_TSC)**

[Detailed macro reference](macro_compression.md)

| Macro | Does |
|---|---|
| `#xm_zx0_decompress src, dst` | decompress ZX0; → A/X = one past the last output byte |
| `#xm_tsc_decompress src, dst` | decompress TSC; → A/X = one past the last output byte |

**Strings (X16_USE_STRING and friends)**

[Detailed macro reference](macro_strings.md)

| Macro | Does |
|---|---|
| Gates / arguments | each string gate is separate; `str`/`src`/`dst` are addresses, `ch` and lengths are immediates |
| `#xm_str_length str` | → Y = length |
| `#xm_str_copy src, dst` | copy (→ Y = length) |
| `#xm_str_ncopy src, dst, max` | copy, capped |
| `#xm_str_append tgt, suffix` | → A = new length |
| `#xm_str_nappend tgt, suffix, max` | append, capped |
| `#xm_str_compare s1, s2` | → A = −1 / 0 / 1 |
| `#xm_str_hash str` | → A = hash |
| `#xm_str_lower str` / `#xm_str_lower_iso str` | lower-case in place |
| `#xm_str_upper str` / `#xm_str_upper_iso str` | upper-case in place |
| `#xm_str_compare_nocase s1, s2` (+ `_iso`) | case-insensitive compare |
| `#xm_str_find str, ch` / `#xm_str_rfind str, ch` | → carry + A = index |
| `#xm_str_find_eol str` | first CR/LF |
| `#xm_str_contains str, ch` | → carry set if present |
| `#xm_str_pattern_match str, pattern` | `?`/`*` match → carry |
| `#xm_str_left src, dst, len` / `#xm_str_right …` | copy an end |
| `#xm_str_slice src, dst, start, len` | copy a middle run |
| `#xm_str_sort ptr, count` | sort an array of string pointers ascending (X16_USE_STRING_SORT) |
| `#xm_str_ltrim str` / `#xm_str_rtrim str` / `#xm_str_trim str` | trim whitespace in place |
| `str_isdigit`, `str_lowerchar`, … | character already in `A`; call directly |

---

## Worked examples

A four-colour scene, entirely through the layer:

```asm
X16_USE_BITMAP2H      = 1
X16_USE_SHAPES_RRECT  = 1
X16_USE_SHAPES_ARC    = 1
X16_USE_PALETTE       = 1
.include "core/sugar.asm"
  ; ...
    #xm_gfx2h_init
    #xm_gfx2h_clear 0
    #xm_pal_set 1, $0FFF  ; white
    #xm_pal_set 2, $00F0  ; green
    #xm_shape_frrect 40, 40, 200, 110, 28, 2  ; a green panel
    #xm_shape_rrect 40, 40, 200, 110, 28, 1  ; white outline on top
    #xm_shape_arc 400, 240, 90, 0, 128, 1  ; a white half-circle
```

Setup versus per-frame (from `examples/m_bounce.asm`):

```asm
  ; setup: constant arguments -> macros
    #xm_sprite_image 0, $13000, SPRITE_MODE_8BPP
    #xm_sprite_size 0, SPRITE_SIZE_16, SPRITE_SIZE_16, 0
    #xm_sprite_flags 0, SPRITE_Z_FRONT
    #xm_sprites_on

loop
    #xm_vsync_wait
    jsr move_sprite  ; per-frame: the live position is
    jsr draw_sprite  ;   hand-written inside these
    ...
```

The plain examples each have a macro edition — `m_hello.asm`, `m_polygons.asm`,
`m_polyspin.asm`, `m_bounce.asm`, `m_numbers.asm` — that show the layer in use.
Run one with `run.bat m_bounce`. (`m_numbers.asm` prints output identical to
`numbers.asm`, so it doubles as a check that the macros carry the right bytes.)

---

## Other assemblers

`core/sugar.asm` is written for ACME and, like the rest of the library, the six
other dialect trees are generated from it, so the same macros exist in ca65,
64tass, KickAssembler, dasm, MADS and vasm — you just invoke them in each
assembler's own way (`#xm_pal_set …` in ACME, `xm_pal_set …` in ca65,
`xm_pal_set(…)` in KickAssembler, and so on; the converters handle it). Source
the converted `core/sugar` from your tree after setting the gates, exactly as
above.
