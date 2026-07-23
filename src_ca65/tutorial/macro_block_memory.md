# Block memory Macros

> Generated ca65 edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_MEM` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_MEM = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_mem_fill dst, count, val`

| Field | Details |
|---|---|
| Macro | `xm_mem_fill dst, count, val` |
| Purpose | fill (streams to VERA too) |
| Input parameters | `dst, count, val` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_MEM = 1
.include "x16.asm"

main
    xm_mem_fill dst, count, val
    rts
```

## `xm_mem_copy src, dst, count`

| Field | Details |
|---|---|
| Macro | `xm_mem_copy src, dst, count` |
| Purpose | copy |
| Input parameters | `src, dst, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_MEM = 1
.include "x16.asm"

main
    xm_mem_copy src, dst, count
    rts
```

## `xm_mem_crc addr, count`

| Field | Details |
|---|---|
| Macro | `xm_mem_crc addr, count` |
| Purpose | CRC-16 |
| Input parameters | `addr, count` |
| Output parameters | A/X) |
| More info | Available when `X16_USE_MEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_MEM = 1
.include "x16.asm"

main
    xm_mem_crc addr, count
    rts
```

## `xm_mem_decompress src, dst`

| Field | Details |
|---|---|
| Macro | `xm_mem_decompress src, dst` |
| Purpose | LZSA2 |
| Input parameters | `src, dst` |
| Output parameters | A/X = one past the end) |
| More info | Available when `X16_USE_MEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_MEM = 1
.include "x16.asm"

main
    xm_mem_decompress src, dst
    rts
```
