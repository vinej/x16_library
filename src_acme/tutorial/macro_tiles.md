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
!cpu 65c02
!source "x16.asm"

X16_USE_TILE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write one tile into layer 0's map.
    +xm_layer_on 0
    +xm_layer_off 0
    rts

!source "x16_code.asm"
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
!cpu 65c02
!source "x16.asm"

X16_USE_TILE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write one tile into layer 0's map.
    +xm_layer_set_config 0, $10
    rts

!source "x16_code.asm"
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
!cpu 65c02
!source "x16.asm"

X16_USE_TILE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write one tile into layer 0's map.
    +xm_layer_set_mapbase 0, $9f60
    rts

!source "x16_code.asm"
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
!cpu 65c02
!source "x16.asm"

X16_USE_TILE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write one tile into layer 0's map.
    +xm_layer_scroll_x 0, $20
    +xm_layer_scroll_y 0, $20
    rts

!source "x16_code.asm"
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
!cpu 65c02
!source "x16.asm"

X16_USE_TILE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write one tile into layer 0's map.
    +xm_tile_setptr 14, 5
    rts

!source "x16_code.asm"
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
!cpu 65c02
!source "x16.asm"

X16_USE_TILE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write one tile into layer 0's map.
    +xm_tile_put 14, 5, 'A', $10
    rts

!source "x16_code.asm"
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
!cpu 65c02
!source "x16.asm"

X16_USE_TILE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write one tile into layer 0's map.
    +xm_tile_get 14, 5
    rts

!source "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of tile

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `+xm_layer_set_tilebase layer, base`

| Field | Details |
|---|---|
| Macro | `+xm_layer_set_tilebase layer, base` |
| Purpose | in: X = layer, A = base>>11<<2 | tile size bits |
| Input parameters | `layer`, `base` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_TILE` is enabled. |

## Reference: routines not covered above

Taken from each routine's own header in the source, so this
stays true as the module changes.

| Routine | Purpose | In | Out |
|---|---|---|---|
| `layer_index` | turn a layer number into the register offset. | X = layer (0 or 1) | X = 0 or 7 (L1_CONFIG is 7 bytes past L0_CONFIG) Preserves A. |
