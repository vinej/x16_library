# Bitmap graphics Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_BITMAP8L = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `X16_USE_BITMAP8L / gfx8l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP8L` / `gfx8l` |
| Purpose | 320x240, 8 bpp, VERA VRAM; init, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, char/text |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BITMAP8L = 1
.include "x16.asm"

main
    #xm_gfx8l_init
    rts
```

## `X16_USE_BITMAP4L / gfx4l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP4L` / `gfx4l` |
| Purpose | 320x240, 4 bpp, VERA VRAM; same as 8L, with 4-bit pixels |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BITMAP4L = 1
.include "x16.asm"

main
    #xm_gfx4l_init
    rts
```

## `X16_USE_BITMAP2L / gfx2l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP2L` / `gfx2l` |
| Purpose | 320x240, 2 bpp, VERA VRAM; init, clear, setptr, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BITMAP2L = 1
.include "x16.asm"

main
    #xm_gfx2l_init
    rts
```

## `X16_USE_BITMAP2H / gfx2h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP2H` / `gfx2h` |
| Purpose | 640x480, 2 bpp, MiSTer VERA_2 SDRAM; same as 2L at high resolution |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BITMAP2H = 1
.include "x16.asm"

main
    #xm_gfx2h_init
    rts
```

## `X16_USE_BITMAP4H / gfx4h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP4H` / `gfx4h` |
| Purpose | 640x480, 4 bpp, MiSTer VERA_2 SDRAM; `has/init/off`, passthru, palette, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, copy |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BITMAP4H = 1
.include "x16.asm"

main
    #xm_gfx4h_init
    rts
```

## `X16_USE_BITMAP8H / gfx8h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP8H` / `gfx8h` |
| Purpose | 640x480, 8 bpp, MiSTer VERA_2 SDRAM; same as 4H, with 8-bit pixels |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BITMAP8H = 1
.include "x16.asm"

main
    #xm_gfx8h_init
    rts
```
