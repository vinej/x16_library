# Bitmap graphics Macros

Detailed reference for the `X16_USE_BITMAP8L/2H/2L/4L/4H/8H` macro gates.

Set the gate before sourcing the macro layer:

```asm
!source "x16.asm"
X16_USE_BITMAP8L = 1
!source "core/sugar.asm"
```

This page expands the compact listing from `macroguide.md`. The bitmap macros
are immediate-argument helpers over the `gfx*` routines: pass assembly-time
coordinates, colours, lengths, pattern pointers, or string pointers.

## `X16_USE_BITMAP8L / gfx8l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP8L` / `gfx8l` |
| Purpose | 320x240, 8 bpp, VERA VRAM; init, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, char/text |
| Input parameters | Depends on the selected `+xm_gfx8l_*` macro. Coordinates are 16-bit X and 8-bit Y; colour is an 8-bit palette index. |
| Output parameters | Read helpers return colour in `A`; draw helpers update the bitmap. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP8L = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw an 8 bpp status panel with text in low-resolution VRAM.
    +xm_gfx8l_init
    +xm_gfx8l_clear 0
    +xm_gfx8l_frame 16, 16, 144, 64, 15
    +xm_gfx8l_rect 18, 18, 140, 60, 2
    +xm_gfx8l_text panel_msg, 28, 36, 15
    rts

panel_msg !text "READY", 0

!source "x16_code.asm"
```

## `X16_USE_BITMAP4L / gfx4l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP4L` / `gfx4l` |
| Purpose | 320x240, 4 bpp, VERA VRAM; same as 8L, with 4-bit pixels |
| Input parameters | Depends on the selected `+xm_gfx4l_*` macro. Colours are 0-15. |
| Output parameters | Read helpers return colour in `A`; draw helpers update the bitmap. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP4L = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw a compact 16-colour dialog box.
    +xm_gfx4l_init
    +xm_gfx4l_clear 0
    +xm_gfx4l_frame 24, 24, 128, 56, 12
    +xm_gfx4l_text title, 40, 40, 15
    rts

title !text "PAUSED", 0

!source "x16_code.asm"
```

## `X16_USE_BITMAP2L / gfx2l`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP2L` / `gfx2l` |
| Purpose | 320x240, 2 bpp, VERA VRAM; init, clear, setptr, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm |
| Input parameters | Depends on the selected `+xm_gfx2l_*` macro. Colours are 0-3. |
| Output parameters | Read helpers return colour in `A`; draw helpers update the bitmap. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP2L = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw a 2 bpp minimap frame and a filled marker.
    +xm_gfx2l_init
    +xm_gfx2l_clear 0
    +xm_gfx2l_frame 8, 8, 96, 64, 3
    +xm_gfx2l_rect 44, 32, 10, 10, 2
    +xm_gfx2l_line 8, 8, 103, 71, 1
    rts

!source "x16_code.asm"
```

## `X16_USE_BITMAP2H / gfx2h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP2H` / `gfx2h` |
| Purpose | 640x480, 2 bpp, MiSTer VERA_2 SDRAM; same as 2L at high resolution |
| Input parameters | Depends on the selected `+xm_gfx2h_*` macro. X and Y are 16-bit coordinates; colours are 0-3. |
| Output parameters | Read helpers return colour in `A`; draw helpers update the bitmap. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP2H = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw high-resolution crosshairs on the VERA_2 SDRAM bitmap.
    +xm_gfx2h_init
    +xm_gfx2h_clear 0
    +xm_gfx2h_hline 260, 240, 120, 3
    +xm_gfx2h_vline 320, 180, 120, 3
    +xm_gfx2h_frame 240, 160, 160, 160, 1
    rts

!source "x16_code.asm"
```

## `X16_USE_BITMAP4H / gfx4h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP4H` / `gfx4h` |
| Purpose | 640x480, 4 bpp, MiSTer VERA_2 SDRAM; `has/init/off`, passthru, palette, clear, pset/read, hline/vline, rect/frame, line, pattern, blit/blitm, copy |
| Input parameters | Depends on the selected `+xm_gfx4h_*` macro. X/Y/width/height are 16-bit where applicable; colours are 0-15. |
| Output parameters | `+xm_gfx4h_has` reports VERA_2 support; draw helpers update the SDRAM bitmap. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP4H = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw a high-resolution 16-colour panel when VERA_2 is present.
    +xm_gfx4h_has
    bcs .no_vera2
    +xm_gfx4h_init
    +xm_gfx4h_clear 0
    +xm_gfx4h_pal_set 1, $0f, $00
    +xm_gfx4h_frame 96, 72, 448, 304, 1
    +xm_gfx4h_pattern_set hatch, 0, 2
    +xm_gfx4h_pattern_rect 112, 88, 416, 272
.no_vera2
    rts

hatch !byte %10101010, %01010101, %10101010, %01010101
      !byte %10101010, %01010101, %10101010, %01010101

!source "x16_code.asm"
```

## `X16_USE_BITMAP8H / gfx8h`

| Field | Details |
|---|---|
| Macro | `X16_USE_BITMAP8H` / `gfx8h` |
| Purpose | 640x480, 8 bpp, MiSTer VERA_2 SDRAM; same as 4H, with 8-bit pixels |
| Input parameters | Depends on the selected `+xm_gfx8h_*` macro. Colours are full 8-bit palette indexes. |
| Output parameters | `+xm_gfx8h_has` reports VERA_2 support; draw helpers update the SDRAM bitmap. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP8H = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw a high-resolution 256-colour loading bar when VERA_2 is present.
    +xm_gfx8h_has
    bcs .no_vera2
    +xm_gfx8h_init
    +xm_gfx8h_clear 0
    +xm_gfx8h_frame 120, 220, 400, 24, 15
    +xm_gfx8h_rect 124, 224, 192, 16, 42
    +xm_gfx8h_line 120, 252, 520, 252, 63
.no_vera2
    rts

!source "x16_code.asm"
```
