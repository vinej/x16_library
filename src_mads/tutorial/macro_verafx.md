# VERA FX Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_VERAFX` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_VERAFX = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_fx_off`

| Field | Details |
|---|---|
| Macro | `xm_fx_off` |
| Purpose | disable FX (leaves DCSEL/ADDRSEL = 0) |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_VERAFX = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; disable FX (leaves DCSEL/ADDRSEL = 0)
    xm_fx_off
    rts

    icl "x16_code.asm"
```

## `xm_fx_mult a, b`

| Field | Details |
|---|---|
| Macro | `xm_fx_mult a, b` |
| Purpose | signed 16x16 |
| Input parameters | `a, b` |
| Output parameters | P4..P7 = product) |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_VERAFX = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; signed 16x16
    xm_fx_mult $20, $a0
    rts

    icl "x16_code.asm"
```

## `xm_fx_fill val, count`

| Field | Details |
|---|---|
| Macro | `xm_fx_fill val, count` |
| Purpose | fast fill from the current address |
| Input parameters | `val, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_VERAFX = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; fast fill from the current address
    xm_fx_fill $20, 32
    rts

    icl "x16_code.asm"
```

## `xm_fx_clear addrlo, addrmid, addrhi, count`

| Field | Details |
|---|---|
| Macro | `xm_fx_clear addrlo, addrmid, addrhi, count` |
| Purpose | zero a VRAM region |
| Input parameters | `addrlo, addrmid, addrhi, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_VERAFX = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; zero a VRAM region
    xm_fx_clear $00, $20, $10, 32
    rts

    icl "x16_code.asm"
```

## `xm_fx_transp_on / xm_fx_transp_off`

| Field | Details |
|---|---|
| Macro | `xm_fx_transp_on` / `xm_fx_transp_off` |
| Purpose | transparent VRAM writes |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_VERAFX = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; transparent VRAM writes
    xm_fx_transp_on
    xm_fx_transp_off
    rts

    icl "x16_code.asm"
```

## `xm_fx_line x0, y0, x1, y1, col`

| Field | Details |
|---|---|
| Macro | `xm_fx_line x0, y0, x1, y1, col` |
| Purpose | hardware-assisted line |
| Input parameters | `x0, y0, x1, y1, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_VERAFX = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; hardware-assisted line
    xm_fx_line 24, 32, 96, 96, 14
    rts

    icl "x16_code.asm"
```
