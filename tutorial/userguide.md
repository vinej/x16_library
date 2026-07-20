# x16lib User Guide

x16lib is an assembly library for the Commander X16: write 6502 programs
without re-deriving the machine's hardware surface every time. This guide
explains every routine — its parameters, its results, and a small working
example for each.

All examples are in **ACME** syntax (the reference dialect). The library also
ships as native ca65, 64tass and KickAssembler source trees with identical
routine contracts — see [Using another assembler](#using-another-assembler)
for the dialect differences. Everything else in this guide (registers,
parameters, behaviour) applies to all four unchanged.

---

## Table of contents

1. [Getting started](#getting-started)
2. [Core conventions](#core-conventions)
3. [Macros](#macros)
4. [VERA data ports (`X16_USE_VERA`)](#vera-data-ports)
5. [Screen and text (`X16_USE_SCREEN`)](#screen-and-text)
6. [Palette (`X16_USE_PALETTE`)](#palette)
7. [Tiles and layers (`X16_USE_TILE`)](#tiles-and-layers)
8. [Sprites (`X16_USE_SPRITE`)](#sprites)
9. [Bitmap graphics (`X16_USE_BITMAP`)](#bitmap-graphics)
10. [VERA FX (`X16_USE_VERAFX`)](#vera-fx)
11. [Interrupts (`X16_USE_IRQ`)](#interrupts)
12. [PSG audio (`X16_USE_PSG`)](#psg-audio)
13. [YM2151 FM synthesis (`X16_USE_YM`)](#ym2151-fm-synthesis)
14. [PCM audio (`X16_USE_PCM`, `X16_USE_PCM_STREAM`)](#pcm-audio)
15. [ADPCM decoding (`X16_USE_ADPCM`)](#adpcm-decoding)
16. [Input (`X16_USE_INPUT`)](#input)
17. [Banked RAM (`X16_USE_BANK`)](#banked-ram)
18. [Bank allocator (`X16_USE_BANKALLOC`)](#bank-allocator)
19. [Block memory operations (`X16_USE_MEM`)](#block-memory-operations)
20. [Loading and saving (`X16_USE_LOAD`)](#loading-and-saving)
21. [DOS commands (`X16_USE_DOS`)](#dos-commands)
22. [BMX images (`X16_USE_BMX`)](#bmx-images)
23. [Game math (`X16_USE_MATH`)](#game-math)
24. [Line clipping (`X16_USE_CLIP`)](#line-clipping)
25. [Ring buffer and stack (`X16_USE_BUFFERS`)](#ring-buffer-and-stack)
26. [Compression (`X16_USE_ZX0`, `X16_USE_TSC`)](#compression)
27. [Fixed point (`X16_USE_FIXED`)](#fixed-point)
28. [Collision (`X16_USE_COLLIDE`)](#collision)
29. [Bit helpers (`X16_USE_BITS`)](#bit-helpers)
30. [Number formatting (`X16_USE_NUMBER`)](#number-formatting)
31. [16-bit integers (`X16_USE_INT16`)](#16-bit-integers)
32. [32-bit integers (`X16_USE_INT32`)](#32-bit-integers)
33. [Floating point (`X16_USE_FLOAT`)](#floating-point)

---

## Getting started

### A minimal program

```asm
!cpu 65c02
!source "x16.asm"           ; constants + macros. Emits no code.

X16_USE_SCREEN = 1          ; pick your modules (or X16_USE_ALL = 1)

* = $0801
    +basic_stub             ; 10 SYS 2061

main
    lda #<hello
    ldx #>hello
    jsr screen_puts
    rts

hello !text "HELLO, X16!", $0D, $00

!source "x16_code.asm"      ; library routines land here
```

Assemble with the source tree on the include path and run it:

```
acme\acme -I src_acme -f cbm -o build\HELLO.PRG myprog.asm
emulator\x16emu -prg build\HELLO.PRG -run
```

Two rules, both enforced by ACME's pass model:

1. `x16.asm` comes **before** any code — macros must be defined before use.
2. `x16_code.asm` is sourced **exactly once**, wherever you want the
   library's machine code to sit (normally after your own code), and all
   `X16_USE_*` gates are defined before it.

### Picking modules

ACME has no linker, so unused routines can't be stripped automatically.
Instead, define only the gates you need — each pulls in one source module —
or define `X16_USE_ALL = 1` for everything. Dependencies resolve themselves
(e.g. `X16_USE_SPRITE` pulls in `X16_USE_VERA`; `X16_USE_PCM_STREAM` pulls
in PCM and IRQ). The full gate list is in the table of contents above: each
section of this guide is one gate.

### Using another assembler

The same library exists as four native source trees with the same layout,
gates and contracts, each paired with a repo-local toolchain folder:

| Port | Sources | Toolchain | Build script |
|---|---|---|---|
| ACME (reference) | `src_acme\` | `acme\acme.exe` | `build_acme.ps1` |
| ca65 | `src_ca65\` | `cc65\ca65.exe` + `ld65.exe` | `build_ca65.ps1` |
| 64tass | `src_64tass\` | `64tass\64tass.exe` | `build_64tass.ps1` |
| KickAssembler | `src_kick\` | `kickass\KickAss.jar` | `build_kick.ps1` |

Dialect differences from the ACME examples in this guide:

- **ca65** — `.include "x16.asm"` instead of `!source`, no `+` prefix on
  macro calls, `X16_USE_*` gating via symbol definitions before the include.
- **64tass** — same `X16_USE_VERA = 1` spelling as ACME; gates default to 0
  via `.weak`.
- **KickAssembler** — `#define X16_USE_*` before `#import "x16_code.asm"`;
  zero-page overrides go before the `x16.asm` import.

There is also a **prebuilt binary** route needing no source tree at all:
`dist\x16lib.bin` (the whole library at `$6000`) plus a generated
`x16lib.inc` binding per dialect. See the README's "Prebuilt binary +
bindings" section.

---

## Core conventions

### Registers and the parameter block

Every routine takes small arguments in `A`, `X`, `Y`. When a routine needs
more than three bytes, the extra arguments go in the **parameter block** —
16 bytes of zero page at `$22` (relocatable: define `X16_ZP` before
sourcing `x16.asm`):

| Name | Bytes | Role |
|---|---|---|
| `X16_P0`..`X16_P7` | 8 | routine parameters (yours to write before a call) |
| `X16_T0`..`X16_T7` | 8 | library-private scratch — never rely on it across a call |
| `X16_PTR0`..`X16_PTR3` | — | 16-bit aliases over `P0/P1`, `P2/P3`, `P4/P5`, `P6/P7` |

Ground rules:

- `A`, `X`, `Y` and the flags are **clobbered** unless a routine's contract
  says otherwise.
- The parameter block is **caller-save**: some routines consume it
  (documented per routine).
- The KERNAL's virtual registers `r0`–`r15` (`$02`–`$21`) are available as
  named symbols; the library uses `r0`–`r5` freely.
- Errors come back in the **carry flag**: carry set = failure, with an
  error code in `A` where there is one.

Loading a 16-bit parameter looks like this throughout the guide:

```asm
    lda #<320
    sta X16_P0
    lda #>320
    sta X16_P1
```

### Values with their own registers

Three module families operate on values too wide for the parameter block.
They use named memory "registers" you write directly: `i16_a`/`i16_b`
(16-bit ints), `i32_a`/`i32_b` (32-bit), `cl_ax`.. (collide16),
`tri_x0`.. (fx_triangle), `clipl_x0`.. (clip_line). Each is documented in
its section.

### Interrupt safety

Everything here assumes main-program context. To call library routines
from an interrupt callback, bracket them with `irq_save_regs` /
`irq_restore_regs` — see [Interrupts](#interrupts).

---

## Macros

Defined in `core/macros.asm`, available after `!source "x16.asm"`. Macros
emit inline code — no `jsr` needed, but also no gate required.

> These are the low-level plumbing macros. There is also an optional,
> higher-level convenience layer — `core/sugar.asm`, one `+xm_<routine>` macro
> per library call — documented separately in the [Macro Guide](macroguide.md).

### `+vera_addr port, addr, inc` — point a data port at VRAM

The workhorse. Points VERA data port 0 or 1 at a 17-bit VRAM address with
an auto-increment. `inc` is an **index**, not a byte amount — use the
`VERA_INC_*` constants (`VERA_INC_0/1/2/4/…/512` plus the special strides
`VERA_INC_40/80/160/320/640`). Clobbers `A` and flags.

```asm
    +vera_addr 0, VRAM_TEXT, VERA_INC_2     ; text map, step 2 = chars only
    lda #$51                                ; screen code of a ball
    sta VERA_DATA0                          ; write, port steps by 2
    sta VERA_DATA0
```

`+vera_addr_decr` is the same with the port stepping backwards.

### `+vpoke addr, value` — one-off VRAM write

```asm
    +vpoke VRAM_TEXT + 2*40, $01            ; poke a char at row 1, col 0
```

### `+vera_addrsel port` — select which port's address registers show

`ADDRSEL` (bit 0 of `VERA_CTRL`) picks which port's `ADDR_L/M/H` are
visible at `$9F20`–`$9F22`. Done with read-modify-write so the `DCSEL`
field is preserved. Note `DATA0`/`DATA1` always talk to port 0/1
regardless of `ADDRSEL`.

```asm
    +vera_addrsel 0             ; the KERNAL requires ADDRSEL = 0
```

### `+vera_dcsel n` — select the banked register set (0–63)

The registers at `$9F29`–`$9F2C` are banked by `DCSEL`. This macro
preserves `ADDRSEL` and never writes bit 7 (which would reset VERA).

```asm
    +vera_dcsel 2               ; FX_CTRL bank
```

### `+set_rambank n` / `+set_rombank n` — bank switching

```asm
    +set_rambank 4              ; bank 4 now visible at $A000-$BFFF
```

### `+jsrfar addr, bank` — call into another ROM/RAM bank

The KERNAL's own far-call mechanism (`$FF6E`): saves the caller's bank,
switches, calls, restores — preserving `A`, `X`, `Y` and flags, reentrant
(IRQ-safe). Do not hand-roll this.

```asm
    lda #0                      ; channel 0
    ldx #64                     ; attenuation
    +jsrfar rom_ym_setatten, BANK_AUDIO
```

`+rom_call_fast bank, entry` is ~40 cycles cheaper but clobbers `A`,
leaves `ROM_BANK` switched, and is not IRQ-safe. You restore the bank
yourself.

### `+i16_const dest, value` / `+i32_const dest, value` — load literals

Load a 16/32-bit literal into a little-endian buffer (made for `i16_a`,
`i32_a` and friends).

```asm
    +i16_const i16_a, 1000
    +i32_const i32_b, 100000
```

### `+basic_stub` — autorun header

Emits `10 SYS 2061`. Must be the very first thing at `$0801`; your code
then starts immediately after (at `$080D` = 2061).

```asm
* = $0801
    +basic_stub
main                            ; execution starts here
```

---

## VERA data ports

`X16_USE_VERA` — `video/vera.asm`. VRAM is reached through two
auto-incrementing data ports; these routines are the runtime counterparts
of the `+vera_addr` macro plus the two bulk primitives everything else
builds on.

### `vera_set_addr0` / `vera_set_addr1` — point a port at a runtime address

- **In:** `A` = `ADDR_L`, `X` = `ADDR_M`, `Y` = `ADDR_H` (bank bit |
  `VERA_ADDR_H_DECR` | increment index << 4)

For addresses known at assembly time, prefer `+vera_addr`.

```asm
    lda my_addr                 ; low byte, computed at run time
    ldx my_addr+1               ; middle byte
    ldy #(VERA_INC_1 << 4)      ; bank 0, increment 1
    jsr vera_set_addr0
```

### `vera_fill` — write one value N times through port 0

- **In:** `A` = byte value, `X`/`Y` = count low/high (16-bit; 0 writes nothing)
- **Pre:** port 0 already points at the destination with the increment you want

```asm
    +vera_addr 0, VRAM_TEXT, VERA_INC_2
    lda #$2A                    ; '*'
    ldx #<80
    ldy #>80
    jsr vera_fill               ; a row of stars
```

The increment gives it shapes: `VERA_INC_320` stripes down a bitmap
column, `VERA_INC_2` walks the text map touching only characters.

### `vera_copy` — VRAM-to-VRAM copy, both ports

- **In:** `X`/`Y` = count low/high
- **Pre:** port 0 points at the **source**, port 1 at the **destination**,
  each with its own increment

```asm
    +vera_addr 0, VRAM_BITMAP, VERA_INC_1          ; read from row 0
    +vera_addr 1, VRAM_BITMAP + 320, VERA_INC_1    ; write to row 1
    ldx #<320
    ldy #>320
    jsr vera_copy               ; duplicate a scanline
```

Leaves `ADDRSEL` on port 1 — emit `+vera_addrsel 0` before calling the
KERNAL afterwards (or print via `screen_chrout`, which does it for you).

### `vera_has_fx` — probe for the FX register set

- **Out:** carry set if the VERA firmware has FX (v0.3.1+); `A` = major
  version when carry is set

```asm
    jsr vera_has_fx
    bcc no_fx                   ; fall back to gfx_line etc.
    jsr fx_line
```

---

## Screen and text

`X16_USE_SCREEN` — `video/screen.asm`. Text output, screen modes, colours.
These wrappers exist because several KERNAL screen routines silently
require `ADDRSEL = 0`; every routine here that enters the KERNAL
establishes that first.

### `screen_set_mode` — set the screen mode

- **In:** `A` = mode: `$00` 80×60, `$01` 80×30, `$02` 40×60, `$03` 40×30,
  `$04` 40×15, `$05` 20×30, `$06` 20×15, `$07` 22×23, `$08` 64×50,
  `$09` 64×25, `$0A` 32×50, `$0B` 32×25, `$80` 320×240@256c bitmap + 40×30 text
- **Out:** carry clear on success, set if the mode is unsupported

```asm
    lda #$03                    ; 40x30 text
    jsr screen_set_mode
```

### `screen_get_mode` — read the current mode

- **Out:** `A` = mode

### `screen_reset` — restore the default text mode (KERNAL `CINT`)

### `screen_cls` — clear the text screen

```asm
    jsr screen_cls
```

### `screen_chrout` — print one character, safely

- **In:** `A` = PETSCII character

`CHROUT` with the `ADDRSEL = 0` precondition established. Use this (not
raw `CHROUT`) any time you may have touched data port 1.

```asm
    lda #PETSCII_RETURN
    jsr screen_chrout
```

### `screen_puts` — print a NUL-terminated string

- **In:** `A` = address low, `X` = address high (strings > 255 bytes are
  truncated)

```asm
    lda #<msg
    ldx #>msg
    jsr screen_puts
    ...
msg !text "SCORE: ", $00
```

### `screen_color` — set the text colour

- **In:** `A` = foreground (0–15), `X` = background (0–15)

Affects every subsequent character print. Touches no VERA state.

```asm
    lda #5                      ; green ink
    ldx #0                      ; black paper
    jsr screen_color
```

### `screen_border` — set the border colour

- **In:** `A` = colour (0–15)

```asm
    lda #2                      ; red border
    jsr screen_border
```

### `screen_locate` / `screen_get_cursor` — move/read the text cursor

- **In (locate):** `X` = row, `Y` = column
- **Out (get_cursor):** `X` = row, `Y` = column

```asm
    ldx #10
    ldy #5
    jsr screen_locate           ; row 10, column 5
    lda #<msg : ldx #>msg
    jsr screen_puts
```

### `screen_charset` — select a charset

- **In:** `A` = charset (1 = ISO, 2 = PETSCII upper/graphics,
  3 = PETSCII upper/lower, … 12 = Katakana)

```asm
    lda #3                      ; upper/lower
    jsr screen_charset
```

---

## Palette

`X16_USE_PALETTE` — `video/palette.asm`. 256 entries × 2 bytes at VRAM
`$1FA00`; a 12-bit `$0RGB` colour stores little-endian: byte 0 =
`Green<<4 | Blue`, byte 1 = `Red`.

### `pal_set` — set one palette entry

- **In:** `X` = palette index (0–255), `A` = low byte (`G<<4|B`),
  `Y` = high byte (`R`)

```asm
    ldx #1                      ; entry 1 = pure red ($0F00)
    lda #$00
    ldy #$0F
    jsr pal_set
```

### `pal_load` — bulk-load entries from RAM

- **In:** `X16_PTR0` = source (2 bytes/entry, low byte first),
  `A` = first index, `X` = entry count (1–128; 0 loads nothing)

```asm
    lda #<mypal : sta X16_P0
    lda #>mypal : sta X16_P1
    lda #16                     ; start at entry 16
    ldx #4                      ; four entries
    jsr pal_load
    ...
mypal !word $0000, $0F00, $00F0, $000F   ; black, red, green, blue
```

Caution: the palette region of VRAM is write-only — reads return the last
value *you* wrote, not the hardware state after a reset.

---

## Tiles and layers

`X16_USE_TILE` — `video/tile.asm`. Layer configuration for both layers,
plus cell access to layer 1's tilemap (the text screen in the default
modes). The `tile_*` routines read `L1_CONFIG`/`L1_MAPBASE` at run time,
so they keep working after a mode change.

### `layer_on` / `layer_off` — enable/disable a layer

- **In:** `A` = layer (0 or 1)

```asm
    lda #0
    jsr layer_on                ; show layer 0
```

### `layer_set_config` — the layer's CONFIG byte

- **In:** `X` = layer, `A` = config: map height (7:6) | map width (5:4) |
  `VERA_LAYER_T256C` | `VERA_LAYER_BITMAP` | bpp (1:0)

```asm
    ldx #0
    lda #(VERA_LAYER_MAPW_64 | VERA_LAYER_MAPH_32 | VERA_LAYER_BPP_4)
    jsr layer_set_config        ; 64x32 map of 4bpp tiles
```

### `layer_set_mapbase` — where the map lives

- **In:** `X` = layer, `A` = VRAM address >> 9 (so the map is 512-byte
  aligned)

```asm
    ldx #0
    lda #($10000 >> 9)          ; map at VRAM $10000
    jsr layer_set_mapbase
```

### `layer_set_tilebase` — where the tile images live

- **In:** `X` = layer, `A` = (base >> 11) << 2 | tile size bits
  (bit 0 = 16-px wide, bit 1 = 16-px tall)

```asm
    ldx #0
    lda #(($12000 >> 11) << 2)  ; 8x8 tiles at VRAM $12000
    jsr layer_set_tilebase
```

### `layer_scroll_x` / `layer_scroll_y` — 12-bit hardware scroll

- **In:** `X` = layer, `X16_P0/P1` = scroll value (0–4095)

```asm
    ldx #0
    lda scroll : sta X16_P0
    lda scroll+1 : sta X16_P1
    jsr layer_scroll_x          ; smooth-scroll layer 0
```

### `tile_setptr` — point port 0 at a layer-1 map cell

- **In:** `X` = column, `Y` = row

Leaves `ADDRSEL = 0`, so it is KERNAL-safe afterwards.

### `tile_put` — write one cell

- **In:** `X` = column, `Y` = row, `X16_P0` = screen code,
  `X16_P1` = attribute (fg | bg<<4)

```asm
    ldx #5                      ; column 5
    ldy #3                      ; row 3
    lda #$51 : sta X16_P0       ; ball glyph
    lda #$61 : sta X16_P1       ; white on dark grey
    jsr tile_put
```

### `tile_get` — read one cell

- **In:** `X` = column, `Y` = row
- **Out:** `A` = screen code, `X` = attribute

```asm
    ldx #5
    ldy #3
    jsr tile_get                ; what's at (5,3)?
    cmp #$51
    beq hit_ball
```

---

## Sprites

`X16_USE_SPRITE` — `sprite/sprite.asm`. 128 hardware sprites, one 8-byte
attribute record each at VRAM `$1FC00`. That region is **write-only**:
read-modify-write routines (`sprite_z`) only work on records this program
already initialised — call `sprite_init_all` first.

### `sprite_init_all` — zero all 128 records

Disables every sprite and gives the write-only attribute RAM a known
shadow. Call once at startup.

```asm
    jsr sprite_init_all
    jsr sprites_on
```

### `sprites_on` / `sprites_off` — the sprite renderer as a whole

### `sprite_image` — point a sprite at its pixel data

- **In:** `X` = sprite (0–127), `X16_P0` = address low, `X16_P1` = address
  mid, `X16_P2` = address bit 16, `A` = `SPRITE_MODE_4BPP` or
  `SPRITE_MODE_8BPP`

The record stores address bits 16:5, so the image data must be 32-byte
aligned.

```asm
    ldx #0                      ; sprite 0
    lda #<$13000 : sta X16_P0   ; image at VRAM $13000
    lda #>$13000 : sta X16_P1
    lda #0       : sta X16_P2
    lda #SPRITE_MODE_8BPP
    jsr sprite_image
```

### `sprite_pos` — set the 10-bit position

- **In:** `X` = sprite, `X16_P0/P1` = x, `X16_P2/P3` = y

```asm
    ldx #0
    lda #<160 : sta X16_P0
    lda #>160 : sta X16_P1
    lda #120  : sta X16_P2
    stz X16_P3
    jsr sprite_pos              ; centre of a 320x240 screen
```

### `sprite_get_pos` — read the position back

- **In:** `X` = sprite. **Out:** `X16_P0/P1` = x, `X16_P2/P3` = y

### `sprite_flags` — collision mask, Z-depth, flips (attribute byte 6)

- **In:** `X` = sprite, `A` = collision<<4 | Z | vflip | hflip

```asm
    ldx #0
    lda #(SPRITE_Z_FRONT | SPRITE_HFLIP)
    jsr sprite_flags            ; visible in front, mirrored
```

### `sprite_z` — change only the Z-depth

- **In:** `X` = sprite, `A` = `SPRITE_Z_DISABLED`/`BEHIND`/`MIDDLE`/`FRONT`

Read-modify-write on byte 6, preserving mask and flips. `SPRITE_Z_DISABLED`
hides the sprite without losing its setup.

```asm
    ldx #0
    lda #SPRITE_Z_DISABLED
    jsr sprite_z                ; hide sprite 0
```

### `sprite_size` — size codes and palette offset (attribute byte 7)

- **In:** `X` = sprite, `A` = width code, `Y` = height code
  (`SPRITE_SIZE_8/16/32/64`), `X16_P0` = palette offset (0–15)

```asm
    ldx #0
    lda #SPRITE_SIZE_16
    tay                         ; 16x16
    stz X16_P0                  ; palette offset 0
    jsr sprite_size
```

---

## Bitmap graphics

`X16_USE_BITMAP` — `gfx/bitmap.asm`. Drawing on the 320×240@8bpp
framebuffer at VRAM `$00000` (one byte per pixel, rows of 320).
`gfx_pset`, `gfx_circle`, `gfx_disc`, `gfx_char`/`gfx_text` and
`gfx_flood` clip; the line and rectangle primitives do **not** — keep
their arguments on screen, or clip first with `clip_line`
([Line clipping](#line-clipping)).

### `gfx_init` — switch to bitmap mode

320×240@256c bitmap on layer 0, 40×30 text on layer 1. Call once; the
drawing routines themselves only touch VRAM.

```asm
    jsr gfx_init
    lda #0
    jsr gfx_clear               ; black screen
```

### `gfx_clear` — fill the whole screen

- **In:** `A` = colour

### `gfx_setptr` — point port 0 at pixel (x, y)

- **In:** `A` = increment index (`VERA_INC_*`), `X16_P0/P1` = x,
  `X16_P2` = y

The building block for custom effects: with `VERA_INC_320` the port then
walks straight down a column.

### `gfx_pset` — set one pixel (clipped)

- **In:** `X16_P0/P1` = x, `X16_P2` = y, `X16_P3` = colour

```asm
    lda #<100 : sta X16_P0
    lda #>100 : sta X16_P1
    lda #50   : sta X16_P2      ; (100, 50)
    lda #2    : sta X16_P3      ; red
    jsr gfx_pset
```

### `gfx_hline` / `gfx_vline` — horizontal / vertical line

- **In:** `X16_P0/P1` = x, `X16_P2` = y, `X16_P3` = colour,
  `X16_P4/P5` = length (`gfx_vline`: `X16_P4` only, 1–255)

```asm
    lda #<10 : sta X16_P0
    lda #>10 : sta X16_P1
    lda #100 : sta X16_P2
    lda #7   : sta X16_P3
    lda #<300 : sta X16_P4
    lda #>300 : sta X16_P5
    jsr gfx_hline               ; 300px line from (10,100)
```

### `gfx_rect` / `gfx_frame` — filled rectangle / outline

- **In:** `X16_P0/P1` = x, `X16_P2` = y, `X16_P3` = colour,
  `X16_P4/P5` = width, `X16_P6` = height

```asm
    lda #<60 : sta X16_P0
    lda #>60 : sta X16_P1
    lda #40  : sta X16_P2
    lda #5   : sta X16_P3       ; green
    lda #<200 : sta X16_P4
    lda #>200 : sta X16_P5
    lda #100 : sta X16_P6
    jsr gfx_rect                ; 200x100 box at (60,40)
```

### `gfx_line` — Bresenham line, any direction

- **In:** `X16_P0/P1` = x0, `X16_P2` = y0, `X16_P3/P4` = x1, `X16_P5` = y1,
  `X16_P6` = colour

```asm
    stz X16_P0 : stz X16_P1     ; (0,0)
    stz X16_P2
    lda #<319 : sta X16_P3
    lda #>319 : sta X16_P4
    lda #239  : sta X16_P5      ; to (319,239)
    lda #1    : sta X16_P6      ; white
    jsr gfx_line
```

### `gfx_circle` / `gfx_disc` — circle outline / filled circle

- **In:** `X16_P0/P1` = centre x, `X16_P2` = centre y, `X16_P3` = colour,
  `X16_P4` = radius (0–120). Both clip; both preserve `X16_P0..P4`.

```asm
    lda #<160 : sta X16_P0
    lda #>160 : sta X16_P1
    lda #120  : sta X16_P2
    lda #8    : sta X16_P3
    lda #50   : sta X16_P4
    jsr gfx_disc                ; filled circle, centre screen
```

### `gfx_char` — draw one glyph into the bitmap

- **In:** `A` = screen code, `X16_P0/P1` = x, `X16_P2` = y,
  `X16_P3` = colour. Preserves `X16_P0..P3`.

Reads the 8×8 glyph from the KERNAL's charset in VRAM; set bits become
colour pixels (clipped), clear bits stay transparent.

### `gfx_text` — draw a NUL-terminated string

- **In:** `A` = string low, `X` = string high; `X16_P0..P3` as `gfx_char`.
  ASCII `'A'`–`'Z'` are converted to screen codes. Leaves `X16_P0/P1` one
  past the final character (so calls chain).

```asm
    lda #<20 : sta X16_P0
    lda #>20 : sta X16_P1
    lda #10  : sta X16_P2       ; (20,10)
    lda #1   : sta X16_P3       ; white
    lda #<label : ldx #>label
    jsr gfx_text
    ...
label !text "GAME OVER", $00
```

### `gfx_flood` — scanline flood fill

- **In:** `X16_P0/P1` = seed x, `X16_P2` = seed y, `X16_P3` = fill colour
- **Out:** carry clear = filled completely; carry set = the 170-entry span
  stack overflowed and the fill is incomplete (pathological shapes)

Fills the 4-connected region of the seed's colour. Filling with the colour
already under the seed is a no-op.

```asm
    lda #<160 : sta X16_P0
    lda #>160 : sta X16_P1
    lda #120  : sta X16_P2
    lda #3    : sta X16_P3      ; cyan
    jsr gfx_flood               ; fill the enclosed shape under (160,120)
```

---

## VERA FX

`X16_USE_VERAFX` — `gfx/verafx.asm`. Hardware multiply, cached
fills/copies, line/polygon/affine helpers. Requires VERA firmware v0.3.1+
(emulator R44+) — **probe with `vera_has_fx` first**; on older VERA these
write to registers that do not exist. Every routine leaves FX disabled and
`DCSEL` back at 0.

### `fx_off` — disable FX

Safe to call whether or not FX was ever on; also forces `ADDRSEL` back to
port 0.

### `fx_mult` — signed 16×16 → 32 hardware multiply

- **In:** `X16_P0/P1` = a, `X16_P2/P3` = b
- **Out:** `X16_P4..P7` = product, low byte first

```asm
    +i16_const X16_P0, -300
    +i16_const X16_P2, 100
    jsr fx_mult                 ; X16_P4..P7 = -30000
```

(The macro trick works because `X16_P0` names zero-page bytes; you can
also store the four bytes by hand.)

### `fx_fill` — cached VRAM fill (~4× a byte loop)

- **In:** `A` = byte value, `X16_P0/P1/P2` = destination (17-bit),
  `X16_P3/P4` = byte count

```asm
    lda #0
    stz X16_P0 : stz X16_P1 : stz X16_P2    ; VRAM $00000
    lda #<19200 : sta X16_P3
    lda #>19200 : sta X16_P4
    lda #6                       ; blue
    jsr fx_fill                  ; top quarter of the bitmap
```

### `fx_clear` — zero a VRAM region

- **In:** `X16_P0/P1/P2` = address, `X16_P3/P4` = byte count

### `fx_copy` — cached VRAM-to-VRAM copy (~4× a byte loop)

- **In:** `X16_P0/P1/P2` = source (any alignment),
  `X16_P3/P4/P5` = destination (**4-byte aligned**), `X16_P6/P7` = count

```asm
    stz X16_P0 : stz X16_P1 : stz X16_P2     ; source: row 0
    lda #<(320*100) : sta X16_P3             ; dest: row 100
    lda #>(320*100) : sta X16_P4
    stz X16_P5
    lda #<320 : sta X16_P6
    lda #>320 : sta X16_P7
    jsr fx_copy
```

### `fx_transp_on` / `fx_transp_off` — transparent writes

While on, a **zero byte** written to either data port (or flushed from
the cache) leaves the target untouched — colour 0 acts as transparency
for blits. Note the other `fx_*` helpers reset FX on exit, turning this
off again: enable, blit, disable.

```asm
    jsr fx_transp_on
    ; ...copy a sprite sheet region: 0-pixels don't overwrite...
    jsr fx_transp_off
```

### `fx_line` — hardware-assisted line

- **In:** same as `gfx_line` (`X16_P0/P1` x0, `X16_P2` y0, `X16_P3/P4` x1,
  `X16_P5` y1, `X16_P6` colour)

VERA tracks the Bresenham error itself; the CPU does one store per pixel.
Assumes `gfx_init`'s framebuffer. Does **not** clip.

### `fx_triangle` — filled triangle via the polygon helper

- **In:** the `tri_*` variables, written directly (too many for the
  parameter block): `tri_x0`/`tri_y0`, `tri_x1`/`tri_y1`,
  `tri_x2`/`tri_y2` (x words 0–319, y bytes 0–239), `tri_color`

Vertices in any order. Half-open rasterisation: the bottom row isn't
drawn, so adjacent triangles never double-paint a shared edge. No clipping.

```asm
    lda #<160 : sta tri_x0
    lda #>160 : sta tri_x0+1
    lda #20   : sta tri_y0
    +i16_const tri_x1, 60
    lda #200  : sta tri_y1
    +i16_const tri_x2, 260
    lda #200  : sta tri_y2
    lda #4    : sta tri_color
    jsr fx_triangle
```

### `fx_affine_on` / `fx_affine_ray` / `fx_affine_span` — rotozoom sampling

The mode-7 pipeline. `fx_affine_on` enters affine mode and describes a
square tile texture; `fx_affine_ray` aims a fixed-point sampling ray;
`fx_affine_span` streams texels to wherever port 0 points.

- **`fx_affine_on` in:** `X16_P0/P1/P2` = tile data VRAM address (2 KB
  aligned), `X16_P3/P4/P5` = tile map address (2 KB aligned), `X16_P6` =
  map size code (0=2×2, 1=8×8, 2=32×32, 3=128×128 tiles), `X16_P7` bit 0:
  1 = clip outside the map to tile 0, 0 = wrap
- **`fx_affine_ray` in:** `X16_P0/P1` = start x texel, `X16_P2/P3` = start
  y texel, `X16_P4/P5` = dx per read, `X16_P6/P7` = dy per read (signed,
  1/512-texel units: 512 = one texel per read)
- **`fx_affine_span` in:** `X16_P0/P1` = texel count; port 0 already aimed
  at the destination

One rotated, scaled scanline per ray+span pair; per-scanline dx/dy come
from `sin8`/`cos8` and your zoom factor:

```asm
    ; per frame, per scanline y:
    jsr fx_affine_ray           ; X16_P0..P7 = start + direction
    +vera_addr 0, VRAM_BITMAP + y*320, VERA_INC_1
    +i16_const X16_P0, 320
    jsr fx_affine_span          ; one mode-7 scanline
```

---

## Interrupts

`X16_USE_IRQ` — `system/irq.asm`. Chains onto the KERNAL's `CINV` vector,
so the keyboard, mouse and cursor keep working. Callbacks run **inside**
the interrupt: keep them short, and save any VERA state you touch.

### `irq_install` — hook the interrupt and start counting frames

Idempotent. Required before `vsync_wait`, the line/collision handlers and
the PCM streamer.

```asm
    jsr irq_install
```

### `irq_remove` — restore the previous handler, disable our sources

### `irq_frames` — read the frame counter

- **Out:** `A` = frames (wraps at 256; byte subtraction survives the wrap)

```asm
    jsr irq_frames
    sta t0
    ; ... work ...
    jsr irq_frames
    sec
    sbc t0                      ; = frames elapsed
```

### `vsync_wait` — block until the next frame boundary

Frame-locked (waits for the counter to *change*), so it can't miss a frame
or run twice in one. Needs `irq_install` and interrupts enabled. This is
the game loop's heartbeat:

```asm
game_loop
    jsr vsync_wait
    jsr update
    jsr draw
    bra game_loop
```

### `irq_line_install` / `irq_line_remove` — raster line interrupt

- **In:** `A` = handler low, `X` = handler high, `X16_P0/P1` = scanline
  (0–511; visible display is 0–479)

The handler runs every frame at that scanline, inside the IRQ. The classic
use is a raster split: change a VERA register mid-frame, restore it in a
second handler or in the VSYNC path.

```asm
    lda #<split : ldx #>split
    +i16_const X16_P0, 240
    jsr irq_line_install
    ...
split                           ; called at scanline 240 every frame
    ; change scroll/palette here (registers are free to clobber)
    rts
```

### `irq_sprcol_install` / `irq_sprcol_remove` — sprite collision interrupt

- **In:** `A`/`X` = handler address, or `A = X = 0` for polling only

VERA reports collisions between sprites whose collision masks (set via
`sprite_flags`) share a bit, once per frame. The handler gets the group
bits in `A`; with a null handler the groups still accumulate for:

### `sprite_collisions` — read and clear accumulated collision groups

- **Out:** `A` = group bits seen since the last call (Z set if none)

```asm
    lda #0
    tax
    jsr irq_sprcol_install      ; polling mode
game_frame
    jsr sprite_collisions
    beq no_hit                  ; no collision groups this frame
    ; handle the hit...
```

### `irq_save_regs` / `irq_restore_regs` — make callbacks library-safe

The parameter block and `r0`–`r15` belong to whatever code the interrupt
cut off. A callback that calls **any** library routine must bracket
itself:

```asm
my_handler
    jsr irq_save_regs
    ; ...anything at all: mem_copy, psg_env_tick, gfx_pset...
    jsr irq_restore_regs
    rts
```

One buffer, no nesting (interrupts don't nest here either).

---

## PSG audio

`X16_USE_PSG` — `audio/psg.asm`. VERA's 16-voice programmable sound
generator. `freq_word ≈ Hz × 2.68435`, so A4 (440 Hz) is 1181.

### `psg_init` — silence all 16 voices

```asm
    jsr psg_init
```

### `psg_set_freq` — set a voice's pitch

- **In:** `X` = voice (0–15), `X16_P0/P1` = frequency word

Written high byte first, so a pitch change never clicks.

```asm
    ldx #0
    +i16_const X16_P0, 1181     ; A4
    jsr psg_set_freq
```

### `psg_set_vol` — volume and panning

- **In:** `X` = voice, `A` = volume (0–63), `Y` = pan
  (`PSG_PAN_LEFT`/`PSG_PAN_RIGHT`/`PSG_PAN_BOTH`)

### `psg_set_wave` — waveform

- **In:** `X` = voice, `A` = `PSG_WAVE_PULSE`/`SAWTOOTH`/`TRIANGLE`/`NOISE`,
  `Y` = pulse width / XOR (0–63)

### `psg_note_off` — volume to zero, everything else kept

- **In:** `X` = voice

A complete beep:

```asm
    ldx #0
    +i16_const X16_P0, 1181
    jsr psg_set_freq
    ldx #0
    lda #PSG_WAVE_TRIANGLE
    ldy #0
    jsr psg_set_wave
    ldx #0
    lda #48
    ldy #PSG_PAN_BOTH
    jsr psg_set_vol             ; sounding now
    ; ... later ...
    ldx #0
    jsr psg_note_off
```

### `psg_env_start` — trigger an attack/sustain/release envelope

- **In:** `A` = voice, `X16_P0` = peak volume (0–63), `X16_P1` = attack
  step per tick (0 = jump to peak), `X16_P2` = sustain ticks (0 = release
  immediately, 255 = hold until `psg_env_release`), `X16_P3` = release
  step per tick (0 = hold until `psg_env_stop`)

Set the voice's frequency, wave and pan first; the envelope drives only
the volume bits.

### `psg_env_release` / `psg_env_stop` — enter release / silence now

- **In:** `A` = voice

### `psg_env_tick` — advance all envelopes one step

Call once per frame (from your `vsync_wait` loop, or a VSYNC callback
bracketed with `irq_save_regs`).

```asm
    lda #0                      ; voice 0
    lda #48 : sta X16_P0        ; peak 48
    lda #8  : sta X16_P1        ; fast attack
    lda #10 : sta X16_P2        ; hold 10 frames
    lda #2  : sta X16_P3        ; gentle fade
    lda #0
    jsr psg_env_start
game_loop
    jsr vsync_wait
    jsr psg_env_tick            ; the envelope plays itself
    bra game_loop
```

---

## YM2151 FM synthesis

`X16_USE_YM` — `audio/ym.asm`. The FM chip at `$9F40`. Two routes that do
not mix freely: `ym_write` hits the chip raw (fast, complete access, but
leaves the ROM driver's volume/pan shadows stale); everything else goes
through the ROM audio driver, keeping them coherent.

**The ROM-driver calls take the channel in `A` and the payload in `X`** —
the opposite of what you'd guess. Getting it backwards plays a
valid-looking note on the wrong channel.

### `ym_init` — reset the chip, load default patches

- **Out:** carry set on failure. Must run before `ym_patch`.

### `ym_write` — raw register write

- **In:** `A` = value, `X` = register. **Out:** carry set if the chip
  stayed busy. Preserves `A`/`X`.

### `ym_poke` — register write through the ROM driver

- **In:** `A` = value, `X` = register. Keeps the shadows coherent.

### `ym_busy` — out: carry set while the chip is busy

### `ym_patch` — load an instrument

- **In:** `A` = channel (0–7); carry **set**: `X` = ROM patch index
  (0–162); carry **clear**: `X`/`Y` = address of a patch in RAM
- **Out:** carry set on failure

### `ym_note` — play a raw key code

- **In:** `A` = channel, `X` = KC (key code), `Y` = KF (key fraction);
  carry clear to retrigger the envelope, set to just change pitch

### `ym_note_bas` — play a packed note (the one you want for tunes)

- **In:** `A` = channel, `X` = `(octave << 4) | note 1..12` (0 releases);
  carry clear to retrigger
- **Out:** carry set on failure

```asm
    jsr ym_init
    bcs fail
    lda #0                      ; channel 0
    sec
    ldx #3                      ; ROM patch 3
    jsr ym_patch
    lda #0
    ldx #$4A                    ; octave 4, note 10 (A-4)
    clc                         ; retrigger
    jsr ym_note_bas
```

### `ym_release_note` — in: `A` = channel

### `ym_vol` — in: `A` = channel, `X` = attenuation (0 = patch volume, larger = quieter)

### `ym_pan` — in: `A` = channel, `X` = 0 off, 1 left, 2 right, 3 both

### `ym_get_vol` / `ym_get_pan` — in: `A` = channel; out: `X` = value

Read the ROM driver's shadows — only meaningful if you've been writing
through the driver, not raw `ym_write`.

### `ym_drum` — in: `A` = channel, `X` = drum note (25–87)

```asm
    lda #7
    ldx #36                     ; kick drum
    jsr ym_drum
```

---

## PCM audio

`X16_USE_PCM` — `audio/pcm.asm`. VERA's 4 KB sample FIFO. Samples are
signed two's-complement; the rate register runs 0 (stop) to 128
(48828 Hz). Golden rule: **prime the FIFO before setting the rate**, or
it underruns at t=0.

### `pcm_ctrl` — format, volume, reset

- **In:** `A` = control byte: volume (0–15) | `PCM_STEREO` | `PCM_16BIT` |
  `PCM_FIFO_RESET`

### `pcm_rate` — in: `A` = rate (0 stops, 128 = full speed)

### `pcm_reset` — clear the FIFO, keeping format and volume

### `pcm_full` / `pcm_empty` — out: carry set if full / empty

### `pcm_put` — in: `A` = one sample byte (silently dropped if full)

### `pcm_write` — push a block

- **In:** `X16_P0/P1` = source, `X16_P2/P3` = byte count

Does not throttle — intended for priming up to 4 KB. Pace longer data
with `pcm_full`.

```asm
    lda #(PCM_FIFO_RESET | 8)   ; mono 8-bit, volume 8
    jsr pcm_ctrl
    lda #<sample : sta X16_P0
    lda #>sample : sta X16_P1
    lda #<2048   : sta X16_P2
    lda #>2048   : sta X16_P3
    jsr pcm_write               ; prime first...
    lda #43                     ; ...then start (~16.4 kHz)
    jsr pcm_rate
```

### PCM streaming (`X16_USE_PCM_STREAM`)

For anything longer than the FIFO. VERA's AFLOW interrupt refills the
FIFO from your buffer automatically; needs interrupts enabled (installs
the IRQ hook itself). Set format/volume with `pcm_ctrl` first; set
`pcm_str_loop` nonzero to repeat.

#### `pcm_stream_start` — stream from low RAM

- **In:** `X16_P0/P1` = sample data, `X16_P2/P3` = byte count,
  `A` = rate (1–128)

#### `pcm_stream_start_bank` — stream from banked RAM

- **In:** `X16_P0/P1` = offset within the bank window (0–8191),
  `X16_P2/P3/P4` = byte count (24-bit — whole songs), `X16_P5` = starting
  bank, `A` = rate

The refiller maps banks in as it goes and always restores the interrupted
code's `RAM_BANK`.

#### `pcm_stream_stop` — stop refilling (queued audio finishes; use `pcm_reset` for instant silence)

#### `pcm_stream_active` — out: `A` = 1 while data remains, 0 when done (Z mirrors A)

```asm
    lda #(PCM_FIFO_RESET | 10)
    jsr pcm_ctrl
    stz X16_P0 : stz X16_P1     ; bank offset 0
    lda #<24576 : sta X16_P2    ; 24 KB = banks 2,3,4
    lda #>24576 : sta X16_P3
    stz X16_P4
    lda #2      : sta X16_P5    ; starting at bank 2
    lda #64                     ; ~24.4 kHz
    jsr pcm_stream_start_bank
wait
    jsr pcm_stream_active
    bne wait                    ; play to the end
```

---

## ADPCM decoding

`X16_USE_ADPCM` — `audio/adpcm.asm`. IMA ADPCM: 16-bit samples stored as
4-bit deltas (4:1). One second of 16-bit mono at 16 kHz becomes 8 KB —
one RAM bank — which is what makes disk streaming practical. Standard
IMA/DVI (the WAV flavour, low nibble first). Decoder state (`adpcm_pred`,
`adpcm_index`) is exposed; IMA WAV block headers carry initial values —
store them before decoding the block payload.

### `adpcm_init` — reset the decoder (predictor 0, index 0)

### `adpcm_nibble` — decode one 4-bit code

- **In:** `A` = code (0–15). **Out:** `A`/`X` = sample low/high (signed).

### `adpcm_block` — decode a run of bytes

- **In:** `X16_P0/P1` = source, `X16_P2/P3` = destination (4 bytes out per
  byte in), `X16_P4/P5` = **source** byte count

Pointers advance and state carries across calls, so slicing a block works.

```asm
    jsr adpcm_init
    lda #<packed : sta X16_P0
    lda #>packed : sta X16_P1
    lda #<pcmbuf : sta X16_P2
    lda #>pcmbuf : sta X16_P3
    +i16_const X16_P4, 512      ; 512 bytes in -> 1024 samples out
    jsr adpcm_block
```

---

## Input

`X16_USE_INPUT` — `input/input.asm`. Joystick, mouse, keyboard, through
the KERNAL.

### `joy_get` — read a joystick

- **In:** `A` = joystick (0 = keyboard joystick, 1–4 = gamepads)
- **Out:** `A` = buttons byte 0 (`JOY_B/Y/SELECT/START/UP/DOWN/LEFT/RIGHT`),
  `X` = byte 1 (`JOY_A/X/L/R`), `Y` = `$00` present / `$FF` absent

Bits are **active low** — test with a mask and branch on zero:

```asm
    lda #0
    jsr joy_get
    tay                          ; keep byte 0
    and #JOY_LEFT
    beq move_left                ; bit clear = pressed
    tya
    and #JOY_RIGHT
    beq move_right
```

### `joy_scan` — sample the joysticks yourself

Only needed if you've taken over the IRQ; the KERNAL's handler normally
does it every frame.

### `mouse_show` / `mouse_hide` — the mouse pointer

- **In (show):** `A` = `$00` hide, `$FF` show without changing the cursor,
  or n = show cursor sprite n. Screen size is left unchanged.

### `mouse_get` — position and buttons

- **Out:** `X16_P0/P1` = x, `X16_P2/P3` = y, `A` = buttons (bit 0 left,
  1 right, 2 middle)

```asm
    lda #$FF
    jsr mouse_show
poll
    jsr mouse_get
    and #%00000001
    beq poll                    ; wait for a left click
```

### `key_get` — out: `A` = PETSCII code, 0 if none (non-blocking)

### `key_wait` — block until a key; out: `A` = PETSCII code

### `key_peek` — out: `A` = next key without consuming; `X` = queue depth (Z set when empty)

```asm
    jsr key_wait
    cmp #'Q'
    beq quit
```

---

## Banked RAM

`X16_USE_BANK` — `storage/bank.asm`. `RAM_BANK` (`$00`) selects which
8 KB bank appears at `$A000`–`$BFFF`. Bank 0 belongs to the KERNAL; banks
1–255 are yours. All routines here save and restore `RAM_BANK`. Offsets
are 0–8191 into the window; the bulk copies roll across bank boundaries
automatically.

### `bank_set` / `bank_get` — in/out: `A` = the mapped bank

### `bank_peek` — read a byte from any bank

- **In:** `A` = bank, `X16_P0/P1` = offset (0–8191). **Out:** `A` = byte.

### `bank_poke` — write a byte into any bank

- **In:** `A` = byte, `X` = bank, `X16_P0/P1` = offset

```asm
    lda #$42
    ldx #3
    +i16_const X16_P0, 100
    jsr bank_poke               ; bank 3, offset 100 = $42
    lda #3
    jsr bank_peek               ; A = $42 (same X16_P0)
```

### `mem_to_bank` — copy low RAM into banked RAM

- **In:** `X16_P0/P1` = source, `X16_P2` = destination bank,
  `X16_P3/P4` = destination offset, `X16_P5/P6` = byte count

### `bank_to_mem` — the inverse

- **In:** `X16_P0` = source bank, `X16_P1/P2` = source offset,
  `X16_P3/P4` = destination address, `X16_P5/P6` = byte count

```asm
    lda #<level : sta X16_P0    ; stash 2 KB of level data
    lda #>level : sta X16_P1
    lda #5      : sta X16_P2    ; into bank 5
    stz X16_P3  : stz X16_P4    ; offset 0
    +i16_const X16_P5, 2048
    jsr mem_to_bank
```

### `bank_copy_far` — banked RAM to banked RAM

- **In:** `X16_P0` = source bank, `X16_P1/P2` = source offset,
  `X16_P3` = destination bank, `X16_P4/P5` = destination offset,
  `X16_P6/P7` = byte count. The parameter block is consumed.

---

## Bank allocator

`X16_USE_BANKALLOC` — `storage/bankalloc.asm`. A bitmap allocator that
hands out whole bank **numbers** (it never touches `RAM_BANK` itself).

### `bank_alloc_init` — define the pool

- **In:** `A` = first bank, `X` = last bank (inclusive). Calling again
  resets the pool.

### `bank_alloc` — take the lowest free bank

- **Out:** carry clear, `A` = bank — or carry set: pool exhausted

### `bank_free` — in: `A` = bank number. Returns it to the pool.

### `bank_reserve` — claim a specific bank

- **In:** `A` = bank. **Out:** carry clear = now yours; carry set =
  already taken or outside the pool.

```asm
    lda #1
    ldx #63                     ; manage banks 1-63 (512K machine)
    jsr bank_alloc_init
    jsr bank_alloc
    bcs out_of_memory
    sta sample_bank             ; got one
    ...
    lda sample_bank
    jsr bank_free               ; give it back
```

---

## Block memory operations

`X16_USE_MEM` — `storage/mem.asm`. KERNAL block routines with one special
property: addresses in `$9F00`–`$9FFF` are **not incremented** during the
operation. Point a VERA data port somewhere and pass `VERA_DATA0` as
source or target, and these stream into or out of VRAM at the port's own
increment.

### `mem_fill` — set a block to one value

- **In:** `X16_P0/P1` = target, `X16_P2/P3` = byte count, `A` = value

```asm
    lda #<buf : sta X16_P0
    lda #>buf : sta X16_P1
    +i16_const X16_P2, 1000
    lda #0
    jsr mem_fill                ; zero a kilobyte
```

### `mem_copy` — copy a block (regions may overlap)

- **In:** `X16_P0/P1` = source, `X16_P2/P3` = target, `X16_P4/P5` = count

Uploading to VRAM:

```asm
    +vera_addr 0, VRAM_BITMAP, VERA_INC_1
    lda #<image : sta X16_P0
    lda #>image : sta X16_P1
    lda #<VERA_DATA0 : sta X16_P2   ; the magic target
    lda #>VERA_DATA0 : sta X16_P3
    +i16_const X16_P4, 4096
    jsr mem_copy                ; 4 KB straight into video memory
```

### `mem_crc` — CRC-16/IBM-3740 of a block

- **In:** `X16_P0/P1` = address, `X16_P2/P3` = count.
  **Out:** `A` = CRC low, `X` = CRC high. (Empty block ⇒ `$FFFF`.)

### `mem_decompress` — unpack an LZSA2 block

- **In:** `X16_P0/P1` = compressed data, `X16_P2/P3` = output address
- **Out:** `A`/`X` = one past the last output byte

Compress with `lzsa -r -f2 in out` (raw LZSA2). Cannot decompress in
place. Target `VERA_DATA0` (port pointed first) to unpack assets straight
into VRAM with no staging buffer.

---

## Loading and saving

`X16_USE_LOAD` — `storage/load.asm`. KERNAL LOAD/SAVE on device 8 (the SD
card). Filenames are (address, length), not NUL-terminated.

### `fs_load` — load a file

- **In:** `X16_P0/P1` = filename address, `X16_P2` = length,
  `X16_P3` = device (usually 8), `X16_P4` = secondary address:
  `FS_SA_ADDR` (0: skip the 2-byte PRG header, load at your address),
  `FS_SA_HEADER` (1: load where the header says),
  `FS_SA_RAW` (2: no header, load everything at your address);
  `X16_P5/P6` = destination (ignored for `FS_SA_HEADER`)
- **Out:** carry clear on success (`X`/`Y` = one past the last byte);
  carry set with `A` = KERNAL error code

```asm
    lda #<name : sta X16_P0
    lda #>name : sta X16_P1
    lda #9     : sta X16_P2     ; length of "LEVEL.BIN"
    lda #8     : sta X16_P3
    lda #FS_SA_ADDR : sta X16_P4
    lda #<$4000 : sta X16_P5
    lda #>$4000 : sta X16_P6
    jsr fs_load
    bcs load_failed
    ...
name !text "LEVEL.BIN"
```

### `fs_save` — save a memory block as a PRG

- **In:** `X16_P0/P1` = filename, `X16_P2` = length, `X16_P3` = device,
  `X16_P5/P6` = start address, `X16_T6/T7` = end address (one past the
  last byte — it rides in T-space because the P block is full)
- **Out:** carry clear on success; carry set with `A` = error code

```asm
    lda #<name2 : sta X16_P0
    lda #>name2 : sta X16_P1
    lda #8      : sta X16_P2
    lda #8      : sta X16_P3
    lda #<$4000 : sta X16_P5
    lda #>$4000 : sta X16_P6
    lda #<$4800 : sta X16_T6    ; save $4000-$47FF
    lda #>$4800 : sta X16_T7
    jsr fs_save
    ...
name2 !text "SAVE.PRG"
```

### `fs_vload` — load a file straight into VRAM

- **In:** as `fs_load`, but `X16_P4` = VRAM bank (0/1) and
  `X16_P5/P6` = the VRAM address within that bank. PRG header is skipped.

```asm
    lda #<img : sta X16_P0
    lda #>img : sta X16_P1
    lda #7    : sta X16_P2
    lda #8    : sta X16_P3
    stz X16_P4                  ; VRAM bank 0
    stz X16_P5 : stz X16_P6     ; address $00000: the bitmap
    jsr fs_vload
    ...
img !text "PIC.BIN"
```

### `fs_setname` — in: `X16_P0/P1` = filename, `A` = length

The low-level piece (`fs_load`/`fs_save` call it for you).

---

## DOS commands

`X16_USE_DOS` — `storage/dos.asm`. `fs_load`/`fs_save` report *that* they
failed; channel 15 says *why*. Codes below 20 are success, 20+ are errors
(CBM DOS convention). The device defaults to 8 — store to `dos_device` to
change it. All the wrappers return like `dos_cmd`.

### `dos_status` — read the drive's pending status line

- **Out:** `A` = status code (0–99; 255 if the channel wouldn't open),
  carry set when it's an error, `dos_msg` = the full NUL-terminated text,
  `Y` = its length

The first read after power-on returns 73 (the DOS version banner) by
design.

```asm
    jsr fs_load
    bcc ok
    jsr dos_status              ; carry was set -- ask why
    ; A = 62 for FILE NOT FOUND; dos_msg = "62,FILE NOT FOUND,00,00"
    lda #<dos_msg : ldx #>dos_msg
    jsr screen_puts
```

### `dos_cmd` — send a raw DOS command

- **In:** `A` = command low, `X` = command high, `Y` = length (0 = just
  read status). **Out:** as `dos_status`.

### `dos_delete` / `dos_mkdir` / `dos_rmdir` / `dos_chdir`

- **In:** `A` = name low, `X` = name high, `Y` = name length

Scratch a file / make / remove / change directory (`"//"` is the root).

```asm
    lda #<fname : ldx #>fname : ldy #8
    jsr dos_delete              ; S:OLD.SAVE
    bcs drive_said_no
    ...
fname !text "OLD.SAVE"
```

### `dos_rename` — rename a file

- **In:** old name in `X16_P0/P1` with length in `X16_P2`; new name in
  `A`/`X` with length in `Y`

```asm
    lda #<oldn : sta X16_P0
    lda #>oldn : sta X16_P1
    lda #7     : sta X16_P2
    lda #<newn : ldx #>newn : ldy #7
    jsr dos_rename              ; R:NEW=OLD
```

---

## BMX images

`X16_USE_BMX` — `storage/bmx.asm`. BMX is the X16's native bitmap file
format (the one Prog8 and the community tools write): a 16-byte header,
the palette, then pixels. Rows land in VRAM `bmx_stride` bytes apart
(default 320) — a full-width image is a plain load, a narrower one is a
"stamp" that leaves its surroundings alone.

Errors: `BMX_ERR_IO` (1) open/read/write failed or file truncated,
`BMX_ERR_FORMAT` (2) not a BMX / not version 1, `BMX_ERR_PACKED` (3)
compressed BMX unsupported.

### `bmx_load` — load: palette into VERA, pixels into VRAM

- **In:** `X16_P0/P1` = filename, `X16_P2` = length, `X16_P3` = device,
  `X16_P4` = VRAM bank, `X16_P5/P6` = VRAM address
- **Out:** carry clear on success; carry set with `A` = `BMX_ERR_*`.
  `bmx_width/height/bpp/palstart/palcount/border` reflect the file.

```asm
    jsr gfx_init                ; bitmap mode
    lda #<pic : sta X16_P0
    lda #>pic : sta X16_P1
    lda #9    : sta X16_P2
    lda #8    : sta X16_P3
    stz X16_P4                  ; bank 0
    stz X16_P5 : stz X16_P6     ; VRAM $00000
    jsr bmx_load
    bcs show_error              ; A = BMX_ERR_*
    ...
pic !text "TITLE.BMX"
```

### `bmx_save` — write a BMX from VRAM

- **In:** same filename/device/VRAM parameters; `bmx_width`, `bmx_height`,
  `bmx_bpp`, `bmx_palstart`, `bmx_palcount`, `bmx_border`, `bmx_stride`
  describe what to save (defaults: 8 bpp, stride 320)
- **Out:** carry clear on success; carry set with `A` = `BMX_ERR_IO`

Caveat: the palette written comes from VRAM's host-write shadow, so it is
only meaningful if this program set those entries itself (`pal_set` /
`pal_load` / a previous `bmx_load`).

```asm
    +i16_const bmx_width, 320   ; describe the screen
    +i16_const bmx_height, 240
    lda #<shot : sta X16_P0
    lda #>shot : sta X16_P1
    lda #8     : sta X16_P2
    lda #8     : sta X16_P3
    stz X16_P4
    stz X16_P5 : stz X16_P6
    jsr bmx_save                ; screenshot to SHOT.BMX
    ...
shot !text "SHOT.BMX"
```

---

## Game math

`X16_USE_MATH` — `util/math.asm`. Angles are bytes: a full circle is 256,
so 64 = 90°, and wrap-around is free. Angle 0 points east (+x), 64 points
south (+y, down the screen) — `atan2` and the sine tables agree, so
`x += cos8(a)*speed>>7 : y += sin8(a)*speed>>7` moves along a returned
heading.

### `rnd_seed` — seed the PRNG

- **In:** `A` = low, `X` = high (a zero seed is nudged to 1)

### `rnd8` / `rnd16` — next pseudo-random value

- **Out:** `A` = byte (`rnd16` also: `X` = high byte)

16-bit xorshift: period 65535, a handful of cycles.

```asm
    lda #$34
    ldx #$12
    jsr rnd_seed                ; deterministic sequence from here
    jsr rnd8
    and #7                      ; 0-7: pick a spawn point
```

### `sin8` / `cos8` — signed sine/cosine

- **In:** `A` = angle 0–255. **Out:** `A` = −127..127. Preserve `X`.

### `sin8u` / `cos8u` — unsigned variants

- **Out:** `A` = 1..255 (128 + signed value — handy for volumes/scales)

### `atan2` — the angle of a vector

- **In:** `A` = dx, `X` = dy (signed bytes). **Out:** `A` = angle 0–255.

```asm
    ; aim at the player
    lda player_x
    sec : sbc enemy_x           ; dx
    tay
    lda player_y
    sec : sbc enemy_y           ; dy
    tax
    tya
    jsr atan2                   ; A = heading
    sta enemy_dir
    jsr cos8                    ; A = cos(heading), -127..127
    ; scale by speed, >> 7, add to enemy_x; same with sin8 for y
```

### `lerp8` — linear interpolation

- **In:** `X16_P0` = a, `X16_P1` = b, `A` = t (0 = a … 255 = b)
- **Out:** `A` = the interpolated value (exact at both ends)

```asm
    lda #0   : sta X16_P0
    lda #63  : sta X16_P1
    lda fade_t
    jsr lerp8                   ; volume fades 0 -> 63 as t rises
```

---

## Line clipping

`X16_USE_CLIP` — `util/clip.asm`. Cohen–Sutherland. Give it a segment in
16-bit **signed** coordinates (±4095) and it rejects it or hands back the
visible part **already loaded into `gfx_line`/`fx_line`'s parameter
block**. The rectangle is inclusive, defaulting to the full 320×240.

### `clip_set` — change the rectangle

- **In:** `X16_P0/P1` = xmin, `X16_P2/P3` = ymin, `X16_P4/P5` = xmax,
  `X16_P6/P7` = ymax (inclusive)

### `clip_line` — clip the segment in `clipl_x0/y0/x1/y1`

- **In:** the four `clipl_*` words, written directly
- **Out:** carry set = entirely outside; carry clear = `X16_P0..P5` are
  loaded for the line drawers

```asm
    +i16_const clipl_x0, -50    ; starts off screen
    +i16_const clipl_y0, 10
    +i16_const clipl_x1, 400    ; ends off screen too
    +i16_const clipl_y1, 200
    jsr clip_line
    bcs nothing_visible
    lda #1
    sta X16_P6                  ; colour is the only thing left to set
    jsr gfx_line                ; draws exactly the on-screen part
```

---

## Ring buffer and stack

`X16_USE_BUFFERS` — `util/buffers.asm`. One static byte ring buffer and
one byte stack, 255 capacity each. If one side runs in an IRQ, wrap the
other side's calls in `php`/`sei` … `plp`.

### `rb_init` / `rb_put` / `rb_get` / `rb_count`

- `rb_put` in: `A` = byte; carry set = full, not stored
- `rb_get` out: `A` = byte; carry set = empty
- `rb_count` out: `A` = bytes queued (Z reflects it)
- put/get preserve `X`/`Y`

```asm
    jsr rb_init
    lda #42
    jsr rb_put                  ; queue
    jsr rb_get                  ; A = 42, FIFO order
    bcs was_empty
```

### `stk_init` / `stk_push` / `stk_pop` / `stk_depth`

Same contracts, LIFO order.

```asm
    jsr stk_init
    lda #1 : jsr stk_push
    lda #2 : jsr stk_push
    jsr stk_pop                 ; A = 2 -- last in, first out
```

---

## Compression

Three decompressors, one trade-off dial. All are RAM→RAM, forward-only,
and cannot decompress in place:

| Routine | Gate | Format | Character |
|---|---|---|---|
| `mem_decompress` | `X16_USE_MEM` | LZSA2 (`lzsa -r -f2`) | free (ROM), can target VRAM |
| `zx0_decompress` | `X16_USE_ZX0` | ZX0 v2 (`salvador`/`zx0`) | packs tightest |
| `tsc_decompress` | `X16_USE_TSC` | TSCrunch (`tscrunch`) | unpacks fastest |

### `zx0_decompress` / `tsc_decompress`

- **In:** `X16_P0/P1` = compressed data, `X16_P2/P3` = output address
- **Out:** `A`/`X` = one past the last output byte (`X16_P0..P3` consumed)

```asm
    lda #<data_zx0 : sta X16_P0
    lda #>data_zx0 : sta X16_P1
    lda #<$5000    : sta X16_P2
    lda #>$5000    : sta X16_P3
    jsr zx0_decompress          ; A/X = end of the unpacked data
```

(`tsc_decompress` is called identically.)

---

## Fixed point

`X16_USE_FIXED` — `util/fixed.asm`.

### `umul16` — unsigned 16×16 → 32

- **In:** `X16_P0/P1` = a, `X16_P2/P3` = b
- **Out:** `X16_P4..P7` = product, low byte first

```asm
    +i16_const X16_P0, 1000
    +i16_const X16_P2, 500
    jsr umul16                  ; X16_P4..P7 = 500000
```

### `mul88` — signed 8.8 fixed-point multiply

- **In:** `X16_P0/P1` = a, `X16_P2/P3` = b (signed 8.8)
- **Out:** `X16_P0/P1` = `(a*b) >> 8`

The tool for fractional sprite speeds: keep positions in 8.8, add an 8.8
velocity per frame, take the high byte as the pixel.

```asm
    +i16_const X16_P0, $0180    ; 1.5
    +i16_const X16_P2, $0200    ; 2.0
    jsr mul88                   ; X16_P0/P1 = $0300 = 3.0
```

---

## Collision

`X16_USE_COLLIDE` — `util/collide.asm`. Axis-aligned box overlap. Edges
that merely touch do **not** collide.

### `collide8` — 8-bit boxes

- **In:** `X16_P0..P3` = ax, ay, aw, ah; `X16_P4..P7` = bx, by, bw, bh
  (unsigned bytes)
- **Out:** carry set if they overlap

```asm
    lda px : sta X16_P0
    lda py : sta X16_P1
    lda #16 : sta X16_P2 : sta X16_P3   ; player: 16x16
    lda ex : sta X16_P4
    lda ey : sta X16_P5
    lda #8 : sta X16_P6 : sta X16_P7    ; enemy: 8x8
    jsr collide8
    bcs hit
```

### `collide16` — 16-bit boxes

- **In:** the `cl_*` words, written directly (eight 16-bit fields don't
  fit the parameter block): `cl_ax/ay/aw/ah`, `cl_bx/by/bw/bh`
- **Out:** carry set if they overlap

Needed in display space: the default 80×60 text screen is 640×480, past
what a byte can address.

```asm
    +i16_const cl_ax, 600       ; a box on the right half
    +i16_const cl_ay, 100
    +i16_const cl_aw, 32
    +i16_const cl_ah, 32
    +i16_const cl_bx, 610
    +i16_const cl_by, 90
    +i16_const cl_bw, 16
    +i16_const cl_bh, 40
    jsr collide16
    bcs hit
```

---

## Bit helpers

`X16_USE_BITS` — `util/bits.asm`.

### `catnib` — in: `A` = high nibble, `X` = low. Out: `A` = `(A<<4)|X`.

### `hinib` / `lonib` — in: `A` = byte. Out: `A` = that nibble in bits 3:0.

```asm
    lda #$0C
    ldx #$05
    jsr catnib                  ; A = $C5
    jsr hinib                   ; A = $0C again
```

### `bit_set` / `bit_clr` / `bit_put` / `bit_test` — masked bits in memory

- **In:** `X16_PTR0` = address, `A` = mask; `bit_put` also `X` (≠0 set,
  0 clear)
- **`bit_test` out:** Z clear if any masked bit is set

```asm
    lda #<flags : sta X16_P0
    lda #>flags : sta X16_P1
    lda #%00000100
    jsr bit_set                 ; flags |= 4
    lda #%00000100
    jsr bit_test
    bne flag_is_on
```

---

## Number formatting

`X16_USE_NUMBER` — `util/number.asm`. Results land in a shared buffer the
next call overwrites; copy the string out to keep it.

### `u16_to_dec` — unsigned 16-bit to decimal

- **In:** `X16_P0/P1` = value (consumed)
- **Out:** `A`/`X` = buffer low/high, `Y` = length; NUL-terminated

```asm
    lda score   : sta X16_P0
    lda score+1 : sta X16_P1
    jsr u16_to_dec
    jsr screen_puts             ; A/X are already the arguments
```

### `u16_to_hex` — four hex digits

- **In:** `X16_P0/P1` = value. **Out:** `A`/`X` = buffer, `Y` = 4.

### `dec_to_u16` — parse decimal digits

- **In:** `X16_P0/P1` = string address, `X16_P2` = length
- **Out:** `X16_P4/P5` = value; carry set if a non-digit was found

```asm
    lda #<input : sta X16_P0
    lda #>input : sta X16_P1
    lda #3      : sta X16_P2
    jsr dec_to_u16
    bcs not_a_number            ; X16_P4/P5 = 123
    ...
input !text "123"
```

---

## 16-bit integers

`X16_USE_INT16` — `util/int16.asm` (pulls in `X16_USE_NUMBER`). Values
live in named two-byte registers you write directly: `i16_a` (the
accumulator — most routines read and overwrite it), `i16_b` (the
operand), `i16_r` (remainder from the divides). Add, subtract, negate,
multiply and left shift serve signed and unsigned alike; comparison,
division, right shift and printing come in signed/unsigned pairs.

### Loading: `+i16_const`, `i16_from_u8`, `i16_from_s8`

- macro: `+i16_const i16_a, 1000`
- `i16_from_u8` / `i16_from_s8` — in: `A`; `i16_a` = A zero-/sign-extended

### `i16_add` / `i16_sub` — `i16_a ± i16_b → i16_a`

### `i16_neg` / `i16_abs` — negate / absolute value of `i16_a`

### `i16_shl` / `i16_shr` / `i16_asr` — shift `i16_a` one bit

Left / logical right / arithmetic right; carry = the bit shifted out.

### `i16_cmpu` / `i16_cmps` — compare `i16_a` with `i16_b`

- **Out:** `A` = `$FF` if a < b, 0 if equal, 1 if a > b (Z set on equal);
  operands unmodified

### `i16_mul` — `i16_a = i16_a * i16_b` (low 16 bits)

For the full 32-bit product use `umul16`.

### `i16_divmod` — unsigned divide

- `i16_a = i16_a / i16_b`, `i16_r` = remainder
- **Out:** carry set if `i16_b` was zero (nothing changed)

### `i16_divmod_s` — signed divide, truncating toward zero

Remainder takes the dividend's sign (like C): −7 / 2 = −3 rem −1.

### `i16_sqrt` — floor(√`i16_a`)

- **Out:** `A` = the root (0–255). Consumes `i16_a`.

### `i16_to_dec` / `i16_to_dec_s` — to decimal text

- **Out:** `A`/`X` = buffer, `Y` = length; NUL-terminated. Consume `i16_a`.

Putting it together:

```asm
    +i16_const i16_a, -1000
    +i16_const i16_b, 7
    jsr i16_divmod_s            ; i16_a = -142, i16_r = -6
    jsr i16_to_dec_s
    jsr screen_puts             ; prints -142
```

```asm
    +i16_const i16_a, 1024
    jsr i16_sqrt                ; A = 32
```

---

## 32-bit integers

`X16_USE_INT32` — `util/int32.asm`. Same shape as int16, one size up:
`i32_a`, `i32_b`, `i32_r` are four-byte little-endian registers.

### Loading: `+i32_const`, `i32_from_u16`, `i32_from_s16`, `i32_to_s16`

- macro: `+i32_const i32_a, 100000`
- `i32_from_u16`/`i32_from_s16` — in: `A` = low, `X` = high, zero-/sign-extended
- `i32_to_s16` — out: `A` = low, `X` = high (top bytes lost)

### `i32_add` / `i32_sub` / `i32_neg` / `i32_abs` — as int16

### `i32_shl` / `i32_shr` / `i32_asr` — one-bit shifts, carry = bit out

### `i32_cmpu` / `i32_cmps` — out: `A` = $FF / 0 / 1 (operands unmodified)

### `i32_mul` — `i32_a = i32_a * i32_b` (low 32 bits)

### `i32_divmod` — unsigned divide; carry set if `i32_b` was zero

### `i32_to_dec` — to decimal text

- **Out:** `A`/`X` = buffer, `Y` = length; NUL-terminated. Consumes
  `i32_a` **and** `i32_b`.

```asm
    +i32_const i32_a, 1000000
    +i32_const i32_b, 7
    jsr i32_divmod              ; i32_a = 142857, i32_r = 1
    jsr i32_to_dec
    jsr screen_puts             ; prints 142857
```

---

## Floating point

`X16_USE_FLOAT` — `util/float.asm`. A **binding** to the ROM's complete
C128/C65-compatible FP library in `BANK_BASIC` — not a reimplementation.
Everything operates on FAC, the floating accumulator; a float in memory
is 5 bytes (`FP_SIZE`) — reserve with `!fill 5, 0`. Pointer arguments are
`A` = low, `Y` = high.

Every call crosses a ROM bank (via `jsrfar`), which is not free: for hot
per-frame maths prefer 8.8 fixed point or int32.

### Loading and storing

- `f_load` — in: `A`/`Y` = address. FAC = the float there.
- `f_store` — in: `A`/`Y` = address. Store round(FAC) there.
- `f_from_u8` — in: `A` = 0–255. FAC = A.
- `f_from_s16` — in: `A` = low, `X` = high. FAC = the signed value.
- `f_to_s16` — out: `A` = low, `X` = high. **Floors** (via the ROM's
  `qint`), so `0.04 * 100` comes out 3 — round by adding 0.5 first.
- `f_from_str` — in: `A`/`Y` = string address, `X` = length. FAC = its value.
- `f_to_str` — out: `A`/`X` = a NUL-terminated string (in `$0100`; copy it
  out before pushing the stack deep or converting again). Positive numbers
  get BASIC's leading space; `f_to_str_trim` skips it.

### Arithmetic (FAC op memory)

- `f_add` / `f_mul` — FAC = FAC + / × mem
- `f_sub` / `f_div` — FAC = FAC − / ÷ mem (the intuitive direction)
- `f_rsub` / `f_rdiv` — FAC = mem − / ÷ FAC (the ROM's native order — one
  bank crossing instead of three; `f_rdiv` is the reciprocal form)
- `f_pow` — FAC = FAC ^ mem; `f_rpow` — FAC = mem ^ FAC

### Unary and tests

- `f_zero` — FAC = 0; `f_neg` — FAC = −FAC; `f_abs` — FAC = |FAC|
- `f_int` — FAC = int(FAC), toward −∞
- `f_sgn` — out: `A` = $FF / 0 / 1
- `f_cmp` — in: `A`/`Y` = address; out: `A` = $FF (FAC < mem), 0, 1

### Transcendentals

`f_sqrt`, `f_ln`, `f_exp`, `f_sin`, `f_cos`, `f_tan`, `f_atan` — each
replaces FAC (the trig ones also destroy ARG).

A complete calculation — the hypotenuse of (30, 40):

```asm
    lda #30 : jsr f_from_u8               ; FAC = 30
    lda #<fa : ldy #>fa : jsr f_store     ; fa = 30
    lda #<fa : ldy #>fa : jsr f_mul       ; FAC = 30*30
    lda #<fb : ldy #>fb : jsr f_store     ; fb = 900
    lda #40 : jsr f_from_u8
    lda #<fa : ldy #>fa : jsr f_store     ; fa = 40
    lda #<fa : ldy #>fa : jsr f_mul       ; FAC = 40*40
    lda #<fb : ldy #>fb : jsr f_add       ; FAC = 2500
    jsr f_sqrt                            ; FAC = 50
    jsr f_to_s16                          ; A = 50, X = 0
    ...
fa !fill 5, 0
fb !fill 5, 0
```

---

## Where to go next

- `examples/` — `hello.asm`, `bounce.asm` (sprites, PSG envelopes, VSYNC),
  `numbers.asm` (int16/int32/float output) are working programs built on
  everything above.
- `test_acme/runner.asm` — every routine in this guide has at least one
  on-target test there; when in doubt about a contract, the test is the
  executable answer.
- The README's "Things the hardware will get you wrong" section — the
  ADDRSEL trap, the write-only VRAM ranges, the non-linear increment
  codes — is worth reading once before debugging anything VERA-related.
