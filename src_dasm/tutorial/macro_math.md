# Math Macros

> Generated dasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_MATH` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_MATH = 1
include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_rnd_seed seed`

| Field | Details |
|---|---|
| Macro | `xm_rnd_seed seed` |
| Purpose | seed the PRNG (16-bit) |
| Input parameters | `seed` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_MATH = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; Calculate small game-control values from constants.
    xm_rnd_seed $ace1
    rts

include "x16_code.asm"
```

## `xm_sin8 angle / xm_cos8 angle`

| Field | Details |
|---|---|
| Macro | `xm_sin8 angle` / `xm_cos8 angle` |
| Purpose | -> A = -127..127 |
| Input parameters | `angle` |
| Output parameters | A = -127..127 |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_MATH = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; Calculate small game-control values from constants.
    xm_sin8 32
    xm_cos8 32
    rts

include "x16_code.asm"
```

## `xm_sin8u angle / xm_cos8u angle`

| Field | Details |
|---|---|
| Macro | `xm_sin8u angle` / `xm_cos8u angle` |
| Purpose | -> A = 1..255 |
| Input parameters | `angle` |
| Output parameters | A = 1..255 |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_MATH = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; Calculate small game-control values from constants.
    xm_sin8u 32
    xm_cos8u 32
    rts

include "x16_code.asm"
```

## `xm_atan2 dx, dy`

| Field | Details |
|---|---|
| Macro | `xm_atan2 dx, dy` |
| Purpose | -> A = angle 0-255 (`dx`,`dy` signed bytes) |
| Input parameters | `dx, dy` |
| Output parameters | A = angle 0-255 (`dx`,`dy` signed bytes) |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_MATH = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; Calculate small game-control values from constants.
    xm_atan2 40, -16
    rts

include "x16_code.asm"
```

## `xm_lerp8 a, b, t`

| Field | Details |
|---|---|
| Macro | `xm_lerp8 a, b, t` |
| Purpose | -> A = interpolated value |
| Input parameters | `a, b, t` |
| Output parameters | A = interpolated value |
| More info | Available when `X16_USE_MATH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_MATH = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; Calculate small game-control values from constants.
    xm_lerp8 $20, $a0, 96
    rts

include "x16_code.asm"
```
