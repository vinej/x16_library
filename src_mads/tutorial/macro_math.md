# Math Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_MATH` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_MATH = 1
    icl "x16.asm"
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
X16_USE_MATH = 1
    icl "x16.asm"

main
    xm_rnd_seed seed
    rts
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
X16_USE_MATH = 1
    icl "x16.asm"

main
    xm_sin8 angle
    rts
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
X16_USE_MATH = 1
    icl "x16.asm"

main
    xm_sin8u angle
    rts
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
X16_USE_MATH = 1
    icl "x16.asm"

main
    xm_atan2 dx, dy
    rts
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
X16_USE_MATH = 1
    icl "x16.asm"

main
    xm_lerp8 a, b, t
    rts
```
