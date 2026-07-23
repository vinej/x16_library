# Shapes Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_SHAPES + sub-gates` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_SHAPES = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `SHP_* bindings`

| Field | Details |
|---|---|
| Macro | `SHP_*` bindings |
| Purpose | engine selection; default is 2 bpp |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
  ; see macro listing above
    rts
```

## `#xm_shape_circle cx, cy, r, col / #xm_shape_disc ...`

| Field | Details |
|---|---|
| Macro | `#xm_shape_circle cx, cy, r, col` / `#xm_shape_disc ...` |
| Purpose | `SHAPES` gate |
| Input parameters | `cx, cy, r, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
    #xm_shape_circle cx, cy, r, col
    rts
```

## `#xm_shape_ellipse cx, cy, rx, ry, col / #xm_shape_fellipse ...`

| Field | Details |
|---|---|
| Macro | `#xm_shape_ellipse cx, cy, rx, ry, col` / `#xm_shape_fellipse ...` |
| Purpose | `SHAPES` gate |
| Input parameters | `cx, cy, rx, ry, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
    #xm_shape_ellipse cx, cy, rx, ry, col
    rts
```

## `#xm_shape_flood x, y, col`

| Field | Details |
|---|---|
| Macro | `#xm_shape_flood x, y, col` |
| Purpose | `SHAPES` gate; -> carry set = stack overflowed |
| Input parameters | `x, y, col` |
| Output parameters | carry set = stack overflowed |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
    #xm_shape_flood x, y, col
    rts
```

## `#xm_shape_polygon cx, cy, r, sides, rot, col / #xm_shape_fpolygon ...`

| Field | Details |
|---|---|
| Macro | `#xm_shape_polygon cx, cy, r, sides, rot, col` / `#xm_shape_fpolygon ...` |
| Purpose | `SHAPES_POLY` gate |
| Input parameters | `cx, cy, r, sides, rot, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
    #xm_shape_polygon cx, cy, r, sides, rot, col
    rts
```

## `#xm_shape_rrect x, y, w, h, r, col / #xm_shape_frrect ...`

| Field | Details |
|---|---|
| Macro | `#xm_shape_rrect x, y, w, h, r, col` / `#xm_shape_frrect ...` |
| Purpose | `SHAPES_RRECT` gate |
| Input parameters | `x, y, w, h, r, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
    #xm_shape_rrect x, y, w, h, r, col
    rts
```

## `#xm_shape_arc cx, cy, r, a0, a1, col`

| Field | Details |
|---|---|
| Macro | `#xm_shape_arc cx, cy, r, a0, a1, col` |
| Purpose | `SHAPES_ARC` gate |
| Input parameters | `cx, cy, r, a0, a1, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
    #xm_shape_arc cx, cy, r, a0, a1, col
    rts
```

## `#xm_shape_pie cx, cy, r, a0, a1, col`

| Field | Details |
|---|---|
| Macro | `#xm_shape_pie cx, cy, r, a0, a1, col` |
| Purpose | `SHAPES_PIE` gate |
| Input parameters | `cx, cy, r, a0, a1, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
    #xm_shape_pie cx, cy, r, a0, a1, col
    rts
```

## `#xm_shape_bezier x0, y0, x1, y1, x2, y2, x3, y3, col`

| Field | Details |
|---|---|
| Macro | `#xm_shape_bezier x0, y0, x1, y1, x2, y2, x3, y3, col` |
| Purpose | `SHAPES_BEZIER` gate |
| Input parameters | `x0, y0, x1, y1, x2, y2, x3, y3, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SHAPES = 1
.include "x16.asm"

main
    #xm_shape_bezier x0, y0, x1, y1, x2, y2, x3, y3, col
    rts
```
