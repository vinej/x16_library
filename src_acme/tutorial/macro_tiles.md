# Tiles and layers Macros

Detailed reference for the `X16_USE_TILE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_TILE = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `+xm_layer_on layer / +xm_layer_off layer`

| Field | Details |
|---|---|
| Macro | `+xm_layer_on layer` / `+xm_layer_off layer` |
| Purpose | enable / disable a layer |
| Input parameters | `layer` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_TILE = 1
!source "x16.asm"

main
    +xm_layer_on layer
    rts
```

## `+xm_layer_set_config layer, cfg`

| Field | Details |
|---|---|
| Macro | `+xm_layer_set_config layer, cfg` |
| Purpose | the layer's CONFIG byte |
| Input parameters | `layer, cfg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_TILE = 1
!source "x16.asm"

main
    +xm_layer_set_config layer, cfg
    rts
```

## `+xm_layer_set_mapbase layer, base`

| Field | Details |
|---|---|
| Macro | `+xm_layer_set_mapbase layer, base` |
| Purpose | where the map lives (VRAM >> 9) |
| Input parameters | `layer, base` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_TILE = 1
!source "x16.asm"

main
    +xm_layer_set_mapbase layer, base
    rts
```

## `+xm_layer_scroll_x layer, val / +xm_layer_scroll_y layer, val`

| Field | Details |
|---|---|
| Macro | `+xm_layer_scroll_x layer, val` / `+xm_layer_scroll_y layer, val` |
| Purpose | 12-bit hardware scroll |
| Input parameters | `layer, val` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_TILE = 1
!source "x16.asm"

main
    +xm_layer_scroll_x layer, val
    rts
```

## `+xm_tile_setptr col, row`

| Field | Details |
|---|---|
| Macro | `+xm_tile_setptr col, row` |
| Purpose | point port 0 at a layer-1 map cell |
| Input parameters | `col, row` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_TILE = 1
!source "x16.asm"

main
    +xm_tile_setptr col, row
    rts
```

## `+xm_tile_put col, row, code, attr`

| Field | Details |
|---|---|
| Macro | `+xm_tile_put col, row, code, attr` |
| Purpose | write one cell |
| Input parameters | `col, row, code, attr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_TILE = 1
!source "x16.asm"

main
    +xm_tile_put col, row, code, attr
    rts
```

## `+xm_tile_get col, row`

| Field | Details |
|---|---|
| Macro | `+xm_tile_get col, row` |
| Purpose | read one cell |
| Input parameters | `col, row` |
| Output parameters | A = code, X = attribute) |
| More info | Available when `X16_USE_TILE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_TILE = 1
!source "x16.asm"

main
    +xm_tile_get col, row
    rts
```

