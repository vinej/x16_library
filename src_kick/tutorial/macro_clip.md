# Clip Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_CLIP` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_CLIP
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_clip_set(xmin, ymin, xmax, ymax)`

| Field | Details |
|---|---|
| Macro | `xm_clip_set(xmin, ymin, xmax, ymax)` |
| Purpose | set the clip rectangle |
| Input parameters | `xmin, ymin, xmax, ymax` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLIP` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_CLIP
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // set the clip rectangle
    xm_clip_set(0, 1, 319, 1)
    rts

#import "x16_code.asm"
```
