# Bits Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BITS` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_BITS = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_catnib hi, lo`

| Field | Details |
|---|---|
| Macro | `xm_catnib hi, lo` |
| Purpose | combine two nibbles |
| Input parameters | `hi, lo` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_BITS = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; combine two nibbles
    xm_catnib $0f, $00
    rts

    include "x16_code.asm"
```

## `xm_hinib byte / xm_lonib byte`

| Field | Details |
|---|---|
| Macro | `xm_hinib byte` / `xm_lonib byte` |
| Purpose | extract high/low nibble |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_BITS = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; extract high/low nibble
    xm_hinib 'A'
    xm_lonib 'A'
    rts

    include "x16_code.asm"
```

## `xm_bit_set addr, mask / xm_bit_clr addr, mask / xm_bit_test addr, mask`

| Field | Details |
|---|---|
| Macro | `xm_bit_set addr, mask` / `xm_bit_clr addr, mask` / `xm_bit_test addr, mask` |
| Purpose | bit operations |
| Input parameters | `addr, mask` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_BITS = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; bit operations
    xm_bit_set work_buffer, $01
    xm_bit_clr work_buffer, $01
    xm_bit_test work_buffer, $01
    rts

work_buffer ds.b 64, 0

    include "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of bits

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `xm_bit_put addr, mask, set`

| Field | Details |
|---|---|
| Macro | `xm_bit_put addr, mask, set` |
| Purpose | -- in: X16_PTR0 = address, A = mask, |
| Input parameters | `addr`, `mask`, `set` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_BITS` is enabled. |
