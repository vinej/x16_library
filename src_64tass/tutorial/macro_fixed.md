# Fixed point Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_FIXED` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_FIXED = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `#xm_umul16 a, b`

| Field | Details |
|---|---|
| Macro | `#xm_umul16 a, b` |
| Purpose | unsigned 16x16 multiply; -> P4..P7 = product |
| Input parameters | `a, b` |
| Output parameters | P4..P7 = product |
| More info | Available when `X16_USE_FIXED` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FIXED = 1
.include "x16.asm"

main
    #xm_umul16 a, b
    rts
```

## `#xm_mul88 a, b`

| Field | Details |
|---|---|
| Macro | `#xm_mul88 a, b` |
| Purpose | signed 8.8 multiply; -> P0/1 |
| Input parameters | `a, b` |
| Output parameters | P0/1 |
| More info | Available when `X16_USE_FIXED` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FIXED = 1
.include "x16.asm"

main
    #xm_mul88 a, b
    rts
```
