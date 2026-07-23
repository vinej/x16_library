# Bank allocator Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BANKALLOC` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_BANKALLOC = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_bank_alloc_init first, last`

| Field | Details |
|---|---|
| Macro | `xm_bank_alloc_init first, last` |
| Purpose | initialize allocator range |
| Input parameters | `first, last` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANKALLOC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BANKALLOC = 1
    include "x16.asm"

main
    xm_bank_alloc_init first, last
    rts
```

## `xm_bank_alloc`

| Field | Details |
|---|---|
| Macro | `xm_bank_alloc` |
| Purpose | allocate one bank; -> carry clear, A = bank |
| Input parameters | No macro arguments. |
| Output parameters | carry clear, A = bank |
| More info | Available when `X16_USE_BANKALLOC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BANKALLOC = 1
    include "x16.asm"

main
    xm_bank_alloc
    rts
```

## `xm_bank_free bank`

| Field | Details |
|---|---|
| Macro | `xm_bank_free bank` |
| Purpose | free one bank |
| Input parameters | `bank` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANKALLOC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BANKALLOC = 1
    include "x16.asm"

main
    xm_bank_free bank
    rts
```

## `xm_bank_reserve bank`

| Field | Details |
|---|---|
| Macro | `xm_bank_reserve bank` |
| Purpose | reserve one bank |
| Input parameters | `bank` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANKALLOC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BANKALLOC = 1
    include "x16.asm"

main
    xm_bank_reserve bank
    rts
```
