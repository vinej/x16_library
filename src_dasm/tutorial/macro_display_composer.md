# Display composer Macros

> Generated dasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_VERA_DC` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_VERA_DC = 1
include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_vdc_get_video / xm_vdc_set_video video`

| Field | Details |
|---|---|
| Macro | `xm_vdc_get_video` / `xm_vdc_set_video video` |
| Purpose | read/write `DC_VIDEO` |
| Input parameters | `video` |
| Output parameters | read/write `DC_VIDEO` |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_DC = 1
include "x16.asm"

main
    xm_vdc_get_video
    rts
```

## `xm_vdc_set_output mode`

| Field | Details |
|---|---|
| Macro | `xm_vdc_set_output mode` |
| Purpose | set output mode while preserving other video bits |
| Input parameters | `mode` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_DC = 1
include "x16.asm"

main
    xm_vdc_set_output mode
    rts
```

## `xm_vdc_set_layers mask / xm_vdc_layer_on mask / xm_vdc_layer_off mask`

| Field | Details |
|---|---|
| Macro | `xm_vdc_set_layers mask` / `xm_vdc_layer_on mask` / `xm_vdc_layer_off mask` |
| Purpose | layer/sprite enables |
| Input parameters | `mask` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_DC = 1
include "x16.asm"

main
    xm_vdc_set_layers mask
    rts
```

## `xm_vdc_get_scale / xm_vdc_set_scale hscale, vscale`

| Field | Details |
|---|---|
| Macro | `xm_vdc_get_scale` / `xm_vdc_set_scale hscale, vscale` |
| Purpose | read/write composer scale |
| Input parameters | `hscale, vscale` |
| Output parameters | read/write composer scale |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_DC = 1
include "x16.asm"

main
    xm_vdc_get_scale
    rts
```

## `xm_vdc_get_border / xm_vdc_set_border color`

| Field | Details |
|---|---|
| Macro | `xm_vdc_get_border` / `xm_vdc_set_border color` |
| Purpose | border palette index |
| Input parameters | `color` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_DC = 1
include "x16.asm"

main
    xm_vdc_get_border
    rts
```

## `xm_vdc_get_active_raw / xm_vdc_set_active_raw hstart, hstop, vstart, vstop`

| Field | Details |
|---|---|
| Macro | `xm_vdc_get_active_raw` / `xm_vdc_set_active_raw hstart, hstop, vstart, vstop` |
| Purpose | raw active-display registers |
| Input parameters | `hstart, hstop, vstart, vstop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_DC = 1
include "x16.asm"

main
    xm_vdc_get_active_raw
    rts
```

## `xm_vdc_set_active hstart, hstop, vstart, vstop / xm_vdc_fullscreen`

| Field | Details |
|---|---|
| Macro | `xm_vdc_set_active hstart, hstop, vstart, vstop` / `xm_vdc_fullscreen` |
| Purpose | pixel-coordinate active display |
| Input parameters | `hstart, hstop, vstart, vstop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_DC = 1
include "x16.asm"

main
    xm_vdc_set_active hstart, hstop, vstart, vstop
    rts
```

## `xm_vdc_get_version`

| Field | Details |
|---|---|
| Macro | `xm_vdc_get_version` |
| Purpose | VERA bitstream version |
| Input parameters | No macro arguments. |
| Output parameters | carry set if valid) |
| More info | Available when `X16_USE_VERA_DC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_DC = 1
include "x16.asm"

main
    xm_vdc_get_version
    rts
```
