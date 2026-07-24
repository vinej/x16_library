# Number Macros

> Generated dasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_NUMBER` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_NUMBER = 1
include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_u16_to_dec value / xm_u16_to_hex value`

| Field | Details |
|---|---|
| Macro | `xm_u16_to_dec value` / `xm_u16_to_hex value` |
| Purpose | format unsigned 16-bit; -> A/X = buffer, Y = length |
| Input parameters | `value` |
| Output parameters | A/X = buffer, Y = length |
| More info | Available when `X16_USE_NUMBER` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_NUMBER = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; format unsigned 16-bit; -> A/X = buffer, Y = length
    xm_u16_to_dec $1234
    xm_u16_to_hex $1234
    rts

include "x16_code.asm"
```

## `xm_dec_to_u16 str, len`

| Field | Details |
|---|---|
| Macro | `xm_dec_to_u16 str, len` |
| Purpose | parse decimal; -> P4/5 = value, carry set on bad digit |
| Input parameters | `str, len` |
| Output parameters | P4/5 = value, carry set on bad digit |
| More info | Available when `X16_USE_NUMBER` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_NUMBER = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; parse decimal; -> P4/5 = value, carry set on bad digit
    xm_dec_to_u16 source_text, 16
    rts

source_text dc.b "LEVEL/01", 0

include "x16_code.asm"
```
