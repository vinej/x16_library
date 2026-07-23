# Compression Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_ZX0, X16_USE_TSC` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_ZX0 = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_zx0_decompress src, dst`

| Field | Details |
|---|---|
| Macro | `xm_zx0_decompress src, dst` |
| Purpose | decompress ZX0; -> A/X = one past the last output byte |
| Input parameters | `src, dst` |
| Output parameters | A/X = one past the last output byte |
| More info | Available when `X16_USE_ZX0, X16_USE_TSC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_ZX0 = 1
    icl "x16.asm"

main
    xm_zx0_decompress src, dst
    rts
```

## `xm_tsc_decompress src, dst`

| Field | Details |
|---|---|
| Macro | `xm_tsc_decompress src, dst` |
| Purpose | decompress TSC; -> A/X = one past the last output byte |
| Input parameters | `src, dst` |
| Output parameters | A/X = one past the last output byte |
| More info | Available when `X16_USE_ZX0, X16_USE_TSC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_ZX0 = 1
    icl "x16.asm"

main
    xm_tsc_decompress src, dst
    rts
```
