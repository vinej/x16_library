# Banked RAM Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BANK` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_BANK = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_bank_set bank`

| Field | Details |
|---|---|
| Macro | `xm_bank_set bank` |
| Purpose | map a RAM bank at `$A000` |
| Input parameters | `bank` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_BANK = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; map a RAM bank at `$A000`
    xm_bank_set 1
    rts

    icl "x16_code.asm"
```

## `xm_bank_peek bank, offset (-> A = byte) / xm_bank_poke bank, offset, byte`

| Field | Details |
|---|---|
| Macro | `xm_bank_peek bank, offset` (-> A = byte) / `xm_bank_poke bank, offset, byte` |
| Purpose | one byte |
| Input parameters | `bank, offset`; `bank, offset, byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_BANK = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; one byte
    xm_bank_peek 1, 0
    xm_bank_poke 1, 0, 'A'
    rts

    icl "x16_code.asm"
```

## `xm_mem_to_bank src, bank, offset, count`

| Field | Details |
|---|---|
| Macro | `xm_mem_to_bank src, bank, offset, count` |
| Purpose | copy low RAM into a bank |
| Input parameters | `src, bank, offset, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BANK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_BANK = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; copy low RAM into a bank
    xm_mem_to_bank pixel_run, 1, 0, 32
    rts

pixel_run .byte 1, 2, 3, 4, 4, 3, 2, 1

    icl "x16_code.asm"
```
