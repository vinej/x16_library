# Bits Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BITS` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_BITS = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `#xm_catnib hi, lo`

| Field | Details |
|---|---|
| Macro | `#xm_catnib hi, lo` |
| Purpose | combine two nibbles |
| Input parameters | `hi, lo` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_BITS = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; combine two nibbles
    #xm_catnib $0f, $00
    rts

.include "x16_code.asm"
```

## `#xm_hinib byte / #xm_lonib byte`

| Field | Details |
|---|---|
| Macro | `#xm_hinib byte` / `#xm_lonib byte` |
| Purpose | extract high/low nibble |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_BITS = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; extract high/low nibble
    #xm_hinib 'A'
    #xm_lonib 'A'
    rts

.include "x16_code.asm"
```

## `#xm_bit_set addr, mask / #xm_bit_clr addr, mask / #xm_bit_test addr, mask`

| Field | Details |
|---|---|
| Macro | `#xm_bit_set addr, mask` / `#xm_bit_clr addr, mask` / `#xm_bit_test addr, mask` |
| Purpose | bit operations |
| Input parameters | `addr, mask` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_BITS = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; bit operations
    #xm_bit_set work_buffer, $01
    #xm_bit_clr work_buffer, $01
    #xm_bit_test work_buffer, $01
    rts

work_buffer .fill 64, 0

.include "x16_code.asm"
```
