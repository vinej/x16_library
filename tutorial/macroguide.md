# x16lib Macro Guide — the friendly `xm_*` layer

Every routine in x16lib is called by loading an argument block and doing a
`jsr`: a 16-bit coordinate into `X16_P0`/`X16_P1`, a colour into `A`, and so on.
That is precise and fast, but writing a dozen `lda`/`sta` lines per call is a
chore. `core/sugar.asm` removes the chore: **one macro per routine**, named
`xm_<routine>`, that takes the arguments in order and makes the call.

```asm
+xm_shape_frrect 40, 40, 200, 110, 28, FILL    ; a filled rounded rectangle
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
   - [VERA](#vera-x16_use_vera) · [Screen](#screen-x16_use_screen) · [Palette](#palette-x16_use_palette) · [Tiles](#tiles-and-layers-x16_use_tile) · [Sprites](#sprites-x16_use_sprite)
   - [Bitmap 8bpp](#bitmap-8bpp-x16_use_bitmap) · [Bitmap 2bpp](#bitmap-2bpp-x16_use_bitmap2) · [Shapes](#shapes-x16_use_shapes) · [VERA FX](#vera-fx-x16_use_verafx)
   - [Interrupts](#interrupts-x16_use_irq) · [PSG](#psg-x16_use_psg) · [YM2151](#ym2151-x16_use_ym) · [PCM](#pcm-x16_use_pcm) · [ADPCM](#adpcm-x16_use_adpcm) · [Input](#input-x16_use_input) · [Serial](#serial-x16_use_serial) · [ZiModem](#zimodem-x16_use_serial_zimodem)
   - [Banked RAM](#banked-ram-x16_use_bank) · [Bank allocator](#bank-allocator-x16_use_bankalloc) · [Block memory](#block-memory-x16_use_mem) · [Load/save](#loadsave-x16_use_load) · [DOS](#dos-x16_use_dos) · [BMX](#bmx-x16_use_bmx)
   - [Math](#math-x16_use_math) · [Collision](#collision-x16_use_collide) · [Bits](#bits-x16_use_bits) · [Number](#number-x16_use_number) · [Fixed point](#fixed-point-x16_use_fixed)
   - [Integers 16/32](#integers-x16_use_int16-x16_use_int32) · [Float](#float-x16_use_float) · [Double](#double-x16_use_double) · [Clip](#clip-x16_use_clip) · [Buffers](#buffers-x16_use_buffers) · [Compression](#compression-x16_use_zx0-x16_use_tsc) · [Strings](#strings-x16_use_string-and-friends)
6. [Worked examples](#worked-examples)
7. [Other assemblers](#other-assemblers)

---

## Using the layer

Set your `X16_USE_*` gates first, then source the layer — **after** the gates and
**before** your own code:

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP2      = 1        ; your gates first
X16_USE_SHAPES_RRECT = 1
X16_USE_PALETTE      = 1

!source "core/sugar.asm"        ; <- the optional macros, after the gates

* = $0801
    +basic_stub
main
    +xm_gfx2_init
    +xm_gfx2_clear 0
    +xm_pal_set 1, $0F00        ; entry 1 = red
    +xm_shape_frrect 40, 40, 200, 110, 28, 1
    rts

!source "x16_code.asm"
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
    +xm_shape_polygon 320, 240, 80, 6, angle, 1   ; WRONG if `angle` is a variable
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
    +xm_shape_polygon 320, 240, 80, 6, 0, 1
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
    lda pos_x+1                 ; the live 16-bit position
    sta X16_P0
    lda pos_x+2
    sta X16_P1
    lda pos_y+1
    sta X16_P2
    lda pos_y+2
    sta X16_P3
    ldx #0
    jmp sprite_pos              ; not +xm_sprite_pos: the position is run-time
```

`examples/m_bounce.asm` is the honest picture: the one-shot setup (constant
arguments) is all `xm_*` macros, while the per-frame work on live values stays
hand-written.

**Argument-free routines.** Routines that take no arguments — the accumulator
operations (`i16_add`, `i16_mul`, `f_sqrt`, `f_sin`, `d_exp`), the toggles
(`sprites_on`, `fx_off`), the queries (`vera_has_fx`, `irq_frames`) — have **no
macro**. A wrapper would be nothing but `jsr name`, so just write that:

```asm
    +i16_const i16_a, 1000      ; load the operands (a macro from core/macros.asm)
    +i16_const i16_b, 7
    jsr i16_divmod              ; the operation itself takes no arguments
```

Load operands into `i16_a`/`i16_b`, `FAC`, `d_ac` with the existing
`+i16_const`/`+i32_const` macros or the `xm_*_load`/`xm_*_from_*` macros, then
`jsr` the operation.

---

## Reference

Every macro, grouped by module. Each takes the routine's arguments in order;
16-bit values (coordinates, sizes, addresses) are passed whole and split inside
the macro. A `→` note is what the routine returns — the macro does not capture
it, so read it from the registers/flags/P-block afterwards. Angles are the
`sin8`/`cos8` byte convention: `0` = east, `64` = south.

### VERA (`X16_USE_VERA`)

| Macro | Does |
|---|---|
| `+xm_vera_set_addr0 l, m, h` | point data port 0 (compose the H byte yourself) |
| `+xm_vera_set_addr1 l, m, h` | point data port 1 |
| `+xm_vera_fill val, count` | write `val` `count` times from the current address |
| `+xm_vera_copy count` | copy `count` bytes port 0 → port 1 (both pre-pointed) |

### Screen (`X16_USE_SCREEN`)

| Macro | Does |
|---|---|
| `+xm_screen_set_mode mode` | set the screen mode (→ carry set if unsupported) |
| `+xm_screen_reset` | restore the default text mode |
| `+xm_screen_cls` | clear the text screen |
| `+xm_screen_chrout ch` | print one character, safely |
| `+xm_screen_color fg, bg` | text foreground / background (0–15) |
| `+xm_screen_border col` | border colour (0–15) |
| `+xm_screen_locate row, col` | move the text cursor |
| `+xm_screen_charset cs` | select a charset |
| `+xm_screen_puts addr` | print a NUL-terminated string |

### Palette (`X16_USE_PALETTE`)

| Macro | Does |
|---|---|
| `+xm_pal_set index, rgb` | set one entry; `rgb` is a 12-bit `$0RGB` value |
| `+xm_pal_load src, first, count` | bulk-load `count` entries from RAM |

### Tiles and layers (`X16_USE_TILE`)

| Macro | Does |
|---|---|
| `+xm_layer_on layer` / `+xm_layer_off layer` | enable / disable a layer |
| `+xm_layer_set_config layer, cfg` | the layer's CONFIG byte |
| `+xm_layer_set_mapbase layer, base` | where the map lives (VRAM ≫ 9) |
| `+xm_layer_scroll_x layer, val` / `+xm_layer_scroll_y layer, val` | 12-bit hardware scroll |
| `+xm_tile_setptr col, row` | point port 0 at a layer-1 map cell |
| `+xm_tile_put col, row, code, attr` | write one cell |
| `+xm_tile_get col, row` | read one cell (→ A = code, X = attribute) |

### Sprites (`X16_USE_SPRITE`)

| Macro | Does |
|---|---|
| `+xm_sprites_on` / `+xm_sprites_off` | the sprite renderer as a whole |
| `+xm_sprite_init_all` | zero all 128 attribute records |
| `+xm_sprite_pos sprite, x, y` | set a sprite's 10-bit position |
| `+xm_sprite_get_pos sprite` | read it back (→ P0/1 = x, P2/3 = y) |
| `+xm_sprite_image sprite, vaddr, mode` | point at pixels; `mode` = `SPRITE_MODE_4BPP`/`8BPP` |
| `+xm_sprite_flags sprite, flags` | byte 6: collision mask, Z, flips |
| `+xm_sprite_z sprite, z` | change only the Z-depth |
| `+xm_sprite_size sprite, wcode, hcode, paloff` | size codes + palette offset |

### Bitmap 8bpp (`X16_USE_BITMAP`)

| Macro | Does |
|---|---|
| `+xm_gfx_init` / `+xm_gfx_clear col` | 320×240×256 mode / clear |
| `+xm_gfx_pset x, y, col` | one pixel, clipped |
| `+xm_gfx_read x, y` | read one pixel (→ A = colour) |
| `+xm_gfx_hline x, y, len, col` / `+xm_gfx_vline …` | spans (no clip) |
| `+xm_gfx_rect x, y, w, h, col` / `+xm_gfx_frame …` | filled / outline rectangle |
| `+xm_gfx_line x0, y0, x1, y1, col` | Bresenham line |
| `+xm_gfx_pattern_set pat` / `+xm_gfx_pattern_rect x, y, w, h` | 8×8 pattern fill |
| `+xm_gfx_char code, x, y, col` / `+xm_gfx_text str, x, y, col` | glyph / string |

### Bitmap 2bpp (`X16_USE_BITMAP2`)

Same family at 640×480×4 (colour in `A`; width and height are 16-bit):
`+xm_gfx2_init`, `+xm_gfx2_clear col`, `+xm_gfx2_pset x, y, col`,
`+xm_gfx2_read x, y` (→ A = colour, carry set if off screen),
`+xm_gfx2_hline / _vline x, y, len, col`, `+xm_gfx2_rect / _frame x, y, w, h, col`,
`+xm_gfx2_line x0, y0, x1, y1, col`, `+xm_gfx2_pattern_set pat`,
`+xm_gfx2_pattern_rect x, y, w, h`.

### Shapes (`X16_USE_SHAPES` + sub-gates)

Engine-agnostic; bind `SHP_*` to pick the engine (defaults to 2bpp).

| Macro | Gate |
|---|---|
| `+xm_shape_circle cx, cy, r, col` / `+xm_shape_disc …` | `SHAPES` |
| `+xm_shape_ellipse cx, cy, rx, ry, col` / `+xm_shape_fellipse …` | `SHAPES` |
| `+xm_shape_flood x, y, col` (→ carry = stack overflowed) | `SHAPES` |
| `+xm_shape_polygon cx, cy, r, sides, rot, col` / `+xm_shape_fpolygon …` | `SHAPES_POLY` |
| `+xm_shape_rrect x, y, w, h, r, col` / `+xm_shape_frrect …` | `SHAPES_RRECT` |
| `+xm_shape_arc cx, cy, r, a0, a1, col` | `SHAPES_ARC` |
| `+xm_shape_pie cx, cy, r, a0, a1, col` | `SHAPES_PIE` |
| `+xm_shape_bezier x0, y0, x1, y1, x2, y2, x3, y3, col` | `SHAPES_BEZIER` |

### VERA FX (`X16_USE_VERAFX`)

| Macro | Does |
|---|---|
| `+xm_fx_off` | disable FX (leaves DCSEL/ADDRSEL = 0) |
| `+xm_fx_mult a, b` | signed 16×16 (→ P4..P7 = product) |
| `+xm_fx_fill val, count` | fast fill from the current address |
| `+xm_fx_clear addrlo, addrmid, addrhi, count` | zero a VRAM region |
| `+xm_fx_transp_on` / `+xm_fx_transp_off` | transparent VRAM writes |
| `+xm_fx_line x0, y0, x1, y1, col` | hardware-assisted line |

### Interrupts (`X16_USE_IRQ`)

| Macro | Does |
|---|---|
| `+xm_irq_install` / `+xm_irq_remove` | hook / unhook the frame counter |
| `+xm_vsync_wait` | block until the next frame boundary |
| `+xm_irq_line_install handler` | call a handler at a scanline |
| `+xm_irq_sprcol_install handler` (`handler` = 0 polls) / `+xm_irq_sprcol_remove` | sprite-collision interrupt |

### PSG (`X16_USE_PSG`)

| Macro | Does |
|---|---|
| `+xm_psg_init` | silence all 16 voices |
| `+xm_psg_set_freq voice, freq` | frequency word |
| `+xm_psg_set_vol voice, vol, pan` | volume (0–63) + pan |
| `+xm_psg_set_wave voice, wave, width` | waveform + pulse width |
| `+xm_psg_note_off voice` | volume to zero, keep the rest |
| `+xm_psg_env_start / _release / _stop voice` | ASR envelope control |
| `+xm_psg_env_tick` | advance every armed envelope (once a frame) |

### YM2151 (`X16_USE_YM`)

| Macro | Does |
|---|---|
| `+xm_ym_init` | reset the chip, load the default patches |
| `+xm_ym_write reg, val` / `+xm_ym_poke reg, val` | raw register write / shadowed write |
| `+xm_ym_patch_rom channel, index` | load a built-in ROM patch (0–162) |
| `+xm_ym_note channel, kc, kf` | play a raw key code |
| `+xm_ym_note_bas channel, note` | play a packed note (0 releases) |
| `+xm_ym_release_note channel` | release |
| `+xm_ym_vol channel, atten` / `+xm_ym_pan channel, pan` | volume / pan |
| `+xm_ym_drum channel, note` | a drum voice |

### PCM (`X16_USE_PCM`, `X16_USE_PCM_STREAM`)

| Macro | Gate |
|---|---|
| `+xm_pcm_ctrl byte` / `+xm_pcm_rate rate` / `+xm_pcm_reset` | `PCM` |
| `+xm_pcm_put sample` / `+xm_pcm_write src, count` | `PCM` |
| `+xm_pcm_stream_start src, count, loop` / `+xm_pcm_stream_stop` | `PCM_STREAM` |

### ADPCM (`X16_USE_ADPCM`)

`+xm_adpcm_init`, `+xm_adpcm_nibble code`, `+xm_adpcm_block src, dst, count`.

### Input (`X16_USE_INPUT`)

| Macro | Does |
|---|---|
| `+xm_joy_scan` / `+xm_joy_get pad` | sample / read a joystick (→ A/X/Y = buttons) |
| `+xm_mouse_show cursor` / `+xm_mouse_hide` / `+xm_mouse_get` | mouse (→ P0/1 = x, P2/3 = y, A = buttons) |
| `+xm_key_get` / `+xm_key_wait` / `+xm_key_peek` | keyboard (→ A = PETSCII) |

### Serial (`X16_USE_SERIAL`)

The serial / WiFi card's 16C550 UARTs. `base` is a UART address (from
`ser_detect`, or `$9F60`); `divisor` is a `SER_BAUD_*` constant.

| Macro | Does |
|---|---|
| `+xm_ser_detect` | scan for UARTs (→ A = count, `ser_u0`/`ser_u1` = bases) |
| `+xm_ser_init base, divisor` | 8N1, FIFOs, auto-flow; selects that UART |
| `+xm_ser_avail` | → carry set if a byte is waiting |
| `+xm_ser_get` | non-blocking read (→ carry set = empty, else A = byte) |
| `+xm_ser_get_wait` | blocking read (→ A = byte) |
| `+xm_ser_put byte` | send one byte |
| `+xm_ser_puts addr` | send a NUL-terminated string |
| `+xm_ser_write addr, len` | send `len` bytes (binary-safe) |
| `+xm_ser_read_until match, buffer, max` | read into buffer until `match` (→ P4/5 = count) |
| `+xm_ser_discard_until match` | read and discard until `match` |

### ZiModem (`X16_USE_SERIAL_ZIMODEM`)

The ESP32 WiFi modem on top of Serial. Most of these block on the board's
reply, so they are for real hardware; `+xm_zi_hexdecode` is pure and
handy on its own.

| Macro | Does |
|---|---|
| `+xm_zi_init base, divisor` | reset the modem to a known state |
| `+xm_zi_cmd addr` | send an `AT…` command line (+ CR/LF) |
| `+xm_zi_wait_ok` | read/discard the reply up to `OK\r\n` |
| `+xm_zi_reset` | `ATZ` |
| `+xm_zi_get_ip buffer` | IPv4 address into buffer (via `ATI2`) |
| `+xm_zi_hex_open filename` | begin a hex-mode download (→ carry set = not found) |
| `+xm_zi_hex_chunk buffer` | next payload chunk (→ A = bytes, 0 = done) |
| `+xm_zi_hex_close` | swallow the trailing `OK` |
| `+xm_zi_hexdecode src, digits, dest` | pack ASCII hex → bytes (→ A = `digits`/2) |

### Banked RAM (`X16_USE_BANK`)

| Macro | Does |
|---|---|
| `+xm_bank_set bank` | map a RAM bank at `$A000` |
| `+xm_bank_peek bank, offset` (→ A = byte) / `+xm_bank_poke bank, offset, byte` | one byte |
| `+xm_mem_to_bank src, bank, offset, count` | copy low RAM into a bank |

### Bank allocator (`X16_USE_BANKALLOC`)

`+xm_bank_alloc_init first, last`, `+xm_bank_alloc` (→ carry clear, A = bank),
`+xm_bank_free bank`, `+xm_bank_reserve bank`.

### Block memory (`X16_USE_MEM`)

| Macro | Does |
|---|---|
| `+xm_mem_fill dst, count, val` | fill (streams to VERA too) |
| `+xm_mem_copy src, dst, count` | copy |
| `+xm_mem_crc addr, count` | CRC-16 (→ A/X) |
| `+xm_mem_decompress src, dst` | LZSA2 (→ A/X = one past the end) |

### Load/save (`X16_USE_LOAD`)

`+xm_fs_setname name, len`, `+xm_fs_load name, len, device, sa, dst`
(→ carry set = error, A = code), `+xm_fs_vload name, len, device, vbank, vaddr`.

### DOS (`X16_USE_DOS`)

`+xm_dos_cmd cmd, len` (→ A = status), `+xm_dos_status`, `+xm_dos_delete name, len`.

### BMX (`X16_USE_BMX`)

`+xm_bmx_load name, len, device, vbank, vaddr`.

### Math (`X16_USE_MATH`)

| Macro | Does |
|---|---|
| `+xm_rnd_seed seed` | seed the PRNG (16-bit) |
| `+xm_sin8 angle` / `+xm_cos8 angle` | → A = −127..127 |
| `+xm_sin8u angle` / `+xm_cos8u angle` | → A = 1..255 |
| `+xm_atan2 dx, dy` | → A = angle 0–255 (`dx`,`dy` signed bytes) |
| `+xm_lerp8 a, b, t` | → A = interpolated value |

### Collision (`X16_USE_COLLIDE`)

`+xm_collide8 ax, ay, aw, ah, bx, by, bw, bh` (8-bit) and
`+xm_collide16 …` (16-bit) — both → carry set if the two boxes overlap.

### Bits (`X16_USE_BITS`)

`+xm_catnib hi, lo`, `+xm_hinib byte`, `+xm_lonib byte`,
`+xm_bit_set addr, mask`, `+xm_bit_clr addr, mask`, `+xm_bit_test addr, mask`.

### Number (`X16_USE_NUMBER`)

`+xm_u16_to_dec value` / `+xm_u16_to_hex value` (→ A/X = buffer, Y = length),
`+xm_dec_to_u16 str, len` (→ P4/5 = value, carry set on a bad digit).

### Fixed point (`X16_USE_FIXED`)

`+xm_umul16 a, b` (→ P4..P7 = product), `+xm_mul88 a, b` (signed 8.8 → P0/1).

### Integers (`X16_USE_INT16`, `X16_USE_INT32`)

The operations (`i16_add`, `i16_mul`, `i32_divmod`, …) take no arguments — load
`i16_a`/`i16_b`, `i32_a`/`i32_b` with `+i16_const`/`+i32_const`, then `jsr`. The
loaders that DO take a register:
`+xm_i16_from_u8 byte`, `+xm_i16_from_s8 byte`,
`+xm_i32_from_u16 value`, `+xm_i32_from_s16 value`.

### Float (`X16_USE_FLOAT`)

The accumulator is `FAC`; `addr` points at a 5-byte float in memory. Unary
operations (`f_sqrt`, `f_sin`, `f_ln`, `f_int`, …) take no argument — call them
directly.

| Macro | Does |
|---|---|
| `+xm_f_from_u8 byte` / `+xm_f_from_s16 value` | build FAC from an integer |
| `+xm_f_from_str str, len` | parse a string into FAC |
| `+xm_f_load addr` / `+xm_f_store addr` | FAC ↔ memory |
| `+xm_f_add / _sub / _mul / _div addr` | FAC ⊕ mem |
| `+xm_f_rsub addr` / `+xm_f_rdiv addr` | mem − FAC / mem ÷ FAC |
| `+xm_f_pow addr` | FAC = FAC ^ mem |
| `+xm_f_cmp addr` | → A = −1 / 0 / 1 |

### Double (`X16_USE_DOUBLE`)

The accumulator is `d_ac`; `addr` points at an 8-byte double. As with float, the
unary transcendentals (`d_exp`, `d_sqrt`, `d_sin`, …) are called directly.

| Macro | Does |
|---|---|
| `+xm_d_from_s16 value` / `+xm_d_from_str str, len` | build d_ac |
| `+xm_d_load addr` / `+xm_d_store addr` | d_ac ↔ memory |
| `+xm_d_add / _sub / _mul / _div addr` | d_ac ⊕ mem |
| `+xm_d_pow addr` | d_ac = d_ac ^ mem |
| `+xm_d_cmp addr` | → A = −1 / 0 / 1 |

### Clip (`X16_USE_CLIP`)

`+xm_clip_set xmin, ymin, xmax, ymax` — set the clip rectangle.

### Buffers (`X16_USE_BUFFERS`)

Ring buffer: `+xm_rb_init`, `+xm_rb_put byte` (→ carry = full), `+xm_rb_get`
(→ A = byte, carry = empty), `+xm_rb_count`. Byte stack: `+xm_stk_init`,
`+xm_stk_push byte`, `+xm_stk_pop`, `+xm_stk_depth`.

### Compression (`X16_USE_ZX0`, `X16_USE_TSC`)

`+xm_zx0_decompress src, dst` and `+xm_tsc_decompress src, dst` — both
→ A/X = one past the last output byte.

### Strings (`X16_USE_STRING` and friends)

Each of the five string gates has its own macros; set the gates you use.
`str`/`src`/`dst` are string addresses; `ch` and lengths are immediates.

| Macro | Does |
|---|---|
| `+xm_str_length str` | → Y = length |
| `+xm_str_copy src, dst` | copy (→ Y = length) |
| `+xm_str_ncopy src, dst, max` | copy, capped |
| `+xm_str_append tgt, suffix` | → A = new length |
| `+xm_str_nappend tgt, suffix, max` | append, capped |
| `+xm_str_compare s1, s2` | → A = −1 / 0 / 1 |
| `+xm_str_hash str` | → A = hash |
| `+xm_str_lower str` / `+xm_str_lower_iso str` | lower-case in place |
| `+xm_str_upper str` / `+xm_str_upper_iso str` | upper-case in place |
| `+xm_str_compare_nocase s1, s2` (+ `_iso`) | case-insensitive compare |
| `+xm_str_find str, ch` / `+xm_str_rfind str, ch` | → carry + A = index |
| `+xm_str_find_eol str` | first CR/LF |
| `+xm_str_contains str, ch` | → carry set if present |
| `+xm_str_pattern_match str, pattern` | `?`/`*` match → carry |
| `+xm_str_left src, dst, len` / `+xm_str_right …` | copy an end |
| `+xm_str_slice src, dst, start, len` | copy a middle run |
| `+xm_str_ltrim str` / `+xm_str_rtrim str` / `+xm_str_trim str` | trim whitespace in place |

The single-character predicates (`str_isdigit` …) and char folders
(`str_lowerchar` …) take the character in `A` already, so call them
directly rather than through a macro.

---

## Worked examples

A four-colour scene, entirely through the layer:

```asm
X16_USE_BITMAP2       = 1
X16_USE_SHAPES_RRECT  = 1
X16_USE_SHAPES_ARC    = 1
X16_USE_PALETTE       = 1
!source "core/sugar.asm"
; ...
    +xm_gfx2_init
    +xm_gfx2_clear 0
    +xm_pal_set 1, $0FFF        ; white
    +xm_pal_set 2, $00F0        ; green
    +xm_shape_frrect 40, 40, 200, 110, 28, 2    ; a green panel
    +xm_shape_rrect  40, 40, 200, 110, 28, 1    ; white outline on top
    +xm_shape_arc 400, 240, 90, 0, 128, 1       ; a white half-circle
```

Setup versus per-frame (from `examples/m_bounce.asm`):

```asm
    ; setup: constant arguments -> macros
    +xm_sprite_image 0, $13000, SPRITE_MODE_8BPP
    +xm_sprite_size  0, SPRITE_SIZE_16, SPRITE_SIZE_16, 0
    +xm_sprite_flags 0, SPRITE_Z_FRONT
    +xm_sprites_on

loop
    +xm_vsync_wait
    jsr move_sprite             ; per-frame: the live position is
    jsr draw_sprite             ;   hand-written inside these
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
assembler's own way (`+xm_pal_set …` in ACME, `xm_pal_set …` in ca65,
`xm_pal_set(…)` in KickAssembler, and so on; the converters handle it). Source
the converted `core/sugar` from your tree after setting the gates, exactly as
above.
