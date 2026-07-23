# Bits Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BITS` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_BITS
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_catnib(hi, lo)`

| Field | Details |
|---|---|
| Macro | `xm_catnib(hi, lo)` |
| Purpose | combine two nibbles |
| Input parameters | `hi, lo` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_BITS
#import "x16.asm"

main
    xm_catnib(hi, lo)
    rts
```

## `xm_hinib byte / xm_lonib byte`

| Field | Details |
|---|---|
| Macro | `xm_hinib(byte)` / `xm_lonib(byte)` |
| Purpose | extract high/low nibble |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_BITS
#import "x16.asm"

main
    xm_hinib(byte)
    rts
```

## `xm_bit_set addr, mask / xm_bit_clr addr, mask / xm_bit_test addr, mask`

| Field | Details |
|---|---|
| Macro | `xm_bit_set(addr, mask)` / `xm_bit_clr(addr, mask)` / `xm_bit_test(addr, mask)` |
| Purpose | bit operations |
| Input parameters | `addr, mask` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BITS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_BITS
#import "x16.asm"

main
    xm_bit_set(addr, mask)
    rts
```
