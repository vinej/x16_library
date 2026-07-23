# Palette Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_PALETTE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_PALETTE = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_pal_set index, rgb`

| Field | Details |
|---|---|
| Macro | `xm_pal_set index, rgb` |
| Purpose | set one entry; `rgb` is a 12-bit `$0RGB` value |
| Input parameters | `index, rgb` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PALETTE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PALETTE = 1
    include "x16.asm"

main
    xm_pal_set index, rgb
    rts
```

## `xm_pal_load src, first, count`

| Field | Details |
|---|---|
| Macro | `xm_pal_load src, first, count` |
| Purpose | bulk-load `count` entries from RAM |
| Input parameters | `src, first, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PALETTE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PALETTE = 1
    include "x16.asm"

main
    xm_pal_load src, first, count
    rts
```
