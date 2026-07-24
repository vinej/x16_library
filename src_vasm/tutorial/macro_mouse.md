# Mouse Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_MOUSE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_MOUSE = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_mse_config cursor, width8, height8`

| Field | Details |
|---|---|
| Macro | `xm_mse_config cursor, width8, height8` |
| Purpose | configure mouse cursor |
| Input parameters | `cursor, width8, height8` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MOUSE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_MOUSE = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; configure mouse cursor
    xm_mse_config 0, 1, 1
    rts

    include "x16_code.asm"
```

## `xm_mse_scan / xm_mse_get / xm_mse_get_to zp`

| Field | Details |
|---|---|
| Macro | `xm_mse_scan` / `xm_mse_get` / `xm_mse_get_to zp` |
| Purpose | mouse sample/read helpers |
| Input parameters | `zp` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MOUSE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_MOUSE = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; mouse sample/read helpers
    xm_mse_scan
    xm_mse_get
    xm_mse_get_to 1
    rts

    include "x16_code.asm"
```

## `xm_mse_show cursor / xm_mse_show_keep / xm_mse_hide`

| Field | Details |
|---|---|
| Macro | `xm_mse_show cursor` / `xm_mse_show_keep` / `xm_mse_hide` |
| Purpose | mouse visibility helpers |
| Input parameters | `cursor` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_MOUSE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_MOUSE = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; mouse visibility helpers
    xm_mse_show 0
    xm_mse_show_keep
    xm_mse_hide
    rts

    include "x16_code.asm"
```
