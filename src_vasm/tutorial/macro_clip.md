# Clip Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_CLIP` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_CLIP = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_clip_set xmin, ymin, xmax, ymax`

| Field | Details |
|---|---|
| Macro | `xm_clip_set xmin, ymin, xmax, ymax` |
| Purpose | set the clip rectangle |
| Input parameters | `xmin, ymin, xmax, ymax` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLIP` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_CLIP = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; set the clip rectangle
    xm_clip_set 0, 1, 319, 1
    rts

    include "x16_code.asm"
```
