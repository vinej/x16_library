# YM2151 Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_YM` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_YM = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_ym_init`

| Field | Details |
|---|---|
| Macro | `xm_ym_init` |
| Purpose | reset the chip, load the default patches |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_YM = 1
    include "x16.asm"

main
    xm_ym_init
    rts
```

## `xm_ym_write reg, val / xm_ym_poke reg, val`

| Field | Details |
|---|---|
| Macro | `xm_ym_write reg, val` / `xm_ym_poke reg, val` |
| Purpose | raw register write / shadowed write |
| Input parameters | `reg, val` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_YM = 1
    include "x16.asm"

main
    xm_ym_write reg, val
    rts
```

## `xm_ym_patch_rom channel, index`

| Field | Details |
|---|---|
| Macro | `xm_ym_patch_rom channel, index` |
| Purpose | load a built-in ROM patch (0-162) |
| Input parameters | `channel, index` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_YM = 1
    include "x16.asm"

main
    xm_ym_patch_rom channel, index
    rts
```

## `xm_ym_note channel, kc, kf`

| Field | Details |
|---|---|
| Macro | `xm_ym_note channel, kc, kf` |
| Purpose | play a raw key code |
| Input parameters | `channel, kc, kf` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_YM = 1
    include "x16.asm"

main
    xm_ym_note channel, kc, kf
    rts
```

## `xm_ym_note_bas channel, note`

| Field | Details |
|---|---|
| Macro | `xm_ym_note_bas channel, note` |
| Purpose | play a packed note (0 releases) |
| Input parameters | `channel, note` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_YM = 1
    include "x16.asm"

main
    xm_ym_note_bas channel, note
    rts
```

## `xm_ym_release_note channel`

| Field | Details |
|---|---|
| Macro | `xm_ym_release_note channel` |
| Purpose | release |
| Input parameters | `channel` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_YM = 1
    include "x16.asm"

main
    xm_ym_release_note channel
    rts
```

## `xm_ym_vol channel, atten / xm_ym_pan channel, pan`

| Field | Details |
|---|---|
| Macro | `xm_ym_vol channel, atten` / `xm_ym_pan channel, pan` |
| Purpose | volume / pan |
| Input parameters | `channel, atten`; `channel, pan` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_YM = 1
    include "x16.asm"

main
    xm_ym_vol channel, atten
    rts
```

## `xm_ym_drum channel, note`

| Field | Details |
|---|---|
| Macro | `xm_ym_drum channel, note` |
| Purpose | a drum voice |
| Input parameters | `channel, note` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_YM = 1
    include "x16.asm"

main
    xm_ym_drum channel, note
    rts
```
