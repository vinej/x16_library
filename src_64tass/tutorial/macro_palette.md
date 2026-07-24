# Palette Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_PALETTE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_PALETTE = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `#xm_pal_set index, rgb`

| Field | Details |
|---|---|
| Macro | `#xm_pal_set index, rgb` |
| Purpose | set one entry; `rgb` is a 12-bit `$0RGB` value |
| Input parameters | `index, rgb` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PALETTE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_PALETTE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Install a small four-color palette.
    #xm_pal_set 1, $0f00
    rts

.include "x16_code.asm"
```

## `#xm_pal_load src, first, count`

| Field | Details |
|---|---|
| Macro | `#xm_pal_load src, first, count` |
| Purpose | bulk-load `count` entries from RAM |
| Input parameters | `src, first, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PALETTE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_PALETTE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Install a small four-color palette.
    #xm_pal_load palette_data, 0, 4
    rts

palette_data .word $000, $00f, $0f0, $f00

.include "x16_code.asm"
```
