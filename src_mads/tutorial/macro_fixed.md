# Fixed point Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_FIXED` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_FIXED = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_umul16 a, b`

| Field | Details |
|---|---|
| Macro | `xm_umul16 a, b` |
| Purpose | unsigned 16x16 multiply; -> P4..P7 = product |
| Input parameters | `a, b` |
| Output parameters | P4..P7 = product |
| More info | Available when `X16_USE_FIXED` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FIXED = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; unsigned 16x16 multiply; -> P4..P7 = product
    xm_umul16 $20, $a0
    rts

    icl "x16_code.asm"
```

## `xm_mul88 a, b`

| Field | Details |
|---|---|
| Macro | `xm_mul88 a, b` |
| Purpose | signed 8.8 multiply; -> P0/1 |
| Input parameters | `a, b` |
| Output parameters | P0/1 |
| More info | Available when `X16_USE_FIXED` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FIXED = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; signed 8.8 multiply; -> P0/1
    xm_mul88 $20, $a0
    rts

    icl "x16_code.asm"
```
