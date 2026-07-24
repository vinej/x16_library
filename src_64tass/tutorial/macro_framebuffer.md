# Framebuffer Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_FB` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_FB = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `#xm_fb_init / #xm_fb_get_info`

| Field | Details |
|---|---|
| Macro | `#xm_fb_init` / `#xm_fb_get_info` |
| Purpose | active KERNAL framebuffer driver |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_FB = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Draw through the KERNAL framebuffer cursor.
    #xm_fb_init
    #xm_fb_get_info
    rts

.include "x16_code.asm"
```

## `#xm_fb_set_palette data, start, count`

| Field | Details |
|---|---|
| Macro | `#xm_fb_set_palette data, start, count` |
| Purpose | set palette entries |
| Input parameters | `data, start, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_FB = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Draw through the KERNAL framebuffer cursor.
    #xm_fb_set_palette palette_data, 4, 4
    rts

palette_data .word $000, $00f, $0f0, $f00

.include "x16_code.asm"
```

## `#xm_fb_cursor_position x, y / #xm_fb_cursor_next_line`

| Field | Details |
|---|---|
| Macro | `#xm_fb_cursor_position x, y` / `#xm_fb_cursor_next_line` |
| Purpose | framebuffer cursor |
| Input parameters | `x, y` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_FB = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Draw through the KERNAL framebuffer cursor.
    #xm_fb_cursor_position 32, 40
    #xm_fb_cursor_next_line
    rts

.include "x16_code.asm"
```

## `#xm_fb_get_pixel x, y / #xm_fb_set_pixel x, y, color`

| Field | Details |
|---|---|
| Macro | `#xm_fb_get_pixel x, y` / `#xm_fb_set_pixel x, y, color` |
| Purpose | one pixel |
| Input parameters | `x, y`; `x, y, color` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_FB = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Draw through the KERNAL framebuffer cursor.
    #xm_fb_get_pixel 32, 40
    #xm_fb_set_pixel 32, 40, 14
    rts

.include "x16_code.asm"
```

## `#xm_fb_get_pixels dest, count / #xm_fb_set_pixels src, count`

| Field | Details |
|---|---|
| Macro | `#xm_fb_get_pixels dest, count` / `#xm_fb_set_pixels src, count` |
| Purpose | pixel runs |
| Input parameters | `dest, count`; `src, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_FB = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Draw through the KERNAL framebuffer cursor.
    #xm_fb_get_pixels work_buffer, 8
    #xm_fb_set_pixels pixel_run, 8
    rts

work_buffer .fill 64, 0
pixel_run .byte 1, 2, 3, 4, 4, 3, 2, 1

.include "x16_code.asm"
```

## `#xm_fb_set_8_pixels pattern, color / #xm_fb_set_8_pixels_opaque mask, pattern, fg, bg`

| Field | Details |
|---|---|
| Macro | `#xm_fb_set_8_pixels pattern, color` / `#xm_fb_set_8_pixels_opaque mask, pattern, fg, bg` |
| Purpose | 8-pixel pattern helpers |
| Input parameters | `pattern, color`; `mask, pattern, fg, bg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_FB = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Draw through the KERNAL framebuffer cursor.
    #xm_fb_set_8_pixels %10101010, 14
    #xm_fb_set_8_pixels_opaque $01, %10101010, 15, 0
    rts

.include "x16_code.asm"
```

## `#xm_fb_fill_pixels count, step, color / #xm_fb_filter_pixels count, filter`

| Field | Details |
|---|---|
| Macro | `#xm_fb_fill_pixels count, step, color` / `#xm_fb_filter_pixels count, filter` |
| Purpose | fill/filter from cursor |
| Input parameters | `count, step, color`; `count, filter` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_FB = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Draw through the KERNAL framebuffer cursor.
    #xm_fb_fill_pixels 32, 1, 14
    #xm_fb_filter_pixels 32, 1
    rts

.include "x16_code.asm"
```

## `#xm_fb_move_pixels sx, sy, tx, ty, count`

| Field | Details |
|---|---|
| Macro | `#xm_fb_move_pixels sx, sy, tx, ty, count` |
| Purpose | move a horizontal span |
| Input parameters | `sx, sy, tx, ty, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FB` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_FB = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Draw through the KERNAL framebuffer cursor.
    #xm_fb_move_pixels 8, 16, 40, 16, 32
    rts

.include "x16_code.asm"
```
