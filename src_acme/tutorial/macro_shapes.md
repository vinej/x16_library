# Shapes Macros

Detailed reference for the `X16_USE_SHAPES + sub-gates` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_SHAPES = 1
!source "x16.asm"
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
!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP2H = 1
X16_USE_SHAPES = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Use the default SHP_* binding: shapes draw to the 640x480 2bpp bitmap.
    +xm_gfx2h_init
    +xm_gfx2h_clear 0
    +xm_shape_disc 160, 120, 24, 3
    rts

!source "x16_code.asm"
```

## `+xm_shape_circle cx, cy, r, col / +xm_shape_disc ...`

| Field | Details |
|---|---|
| Macro | `+xm_shape_circle cx, cy, r, col` / `+xm_shape_disc ...` |
| Purpose | `SHAPES` gate |
| Input parameters | `cx, cy, r, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_BEZIER = 1
X16_USE_SHAPES_PIE = 1
X16_USE_SHAPES_ARC = 1
X16_USE_SHAPES_RRECT = 1
X16_USE_SHAPES_POLY = 1
X16_USE_BITMAP2H = 1
X16_USE_SHAPES = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw a simple mark on the active bitmap target.
    +xm_shape_circle 160, 120, 24, 14
    +xm_shape_disc 160, 120, 24, 14
    rts

!source "x16_code.asm"
```

## `+xm_shape_ellipse cx, cy, rx, ry, col / +xm_shape_fellipse ...`

| Field | Details |
|---|---|
| Macro | `+xm_shape_ellipse cx, cy, rx, ry, col` / `+xm_shape_fellipse ...` |
| Purpose | `SHAPES` gate |
| Input parameters | `cx, cy, rx, ry, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_BEZIER = 1
X16_USE_SHAPES_PIE = 1
X16_USE_SHAPES_ARC = 1
X16_USE_SHAPES_RRECT = 1
X16_USE_SHAPES_POLY = 1
X16_USE_BITMAP2H = 1
X16_USE_SHAPES = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw a simple mark on the active bitmap target.
    +xm_shape_ellipse 160, 120, 48, 20, 14
    +xm_shape_fellipse 160, 120, 48, 20, 14
    rts

!source "x16_code.asm"
```

## `+xm_shape_flood x, y, col`

| Field | Details |
|---|---|
| Macro | `+xm_shape_flood x, y, col` |
| Purpose | `SHAPES` gate; -> carry set = stack overflowed |
| Input parameters | `x, y, col` |
| Output parameters | carry set = stack overflowed |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_BEZIER = 1
X16_USE_SHAPES_PIE = 1
X16_USE_SHAPES_ARC = 1
X16_USE_SHAPES_RRECT = 1
X16_USE_SHAPES_POLY = 1
X16_USE_BITMAP2H = 1
X16_USE_SHAPES = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Draw a simple mark on the active bitmap target.
    +xm_shape_flood 32, 40, 14
    rts

!source "x16_code.asm"
```

## `+xm_shape_polygon cx, cy, r, sides, rot, col / +xm_shape_fpolygon ...`

| Field | Details |
|---|---|
| Macro | `+xm_shape_polygon cx, cy, r, sides, rot, col` / `+xm_shape_fpolygon ...` |
| Purpose | `SHAPES_POLY` gate |
| Input parameters | `cx, cy, r, sides, rot, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_BEZIER = 1
X16_USE_SHAPES_PIE = 1
X16_USE_SHAPES_ARC = 1
X16_USE_SHAPES_RRECT = 1
X16_USE_SHAPES = 1
X16_USE_BITMAP2H = 1
X16_USE_SHAPES_POLY = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `SHAPES_POLY` gate
    +xm_shape_polygon 160, 120, 24, 6, 16, 14
    +xm_shape_fpolygon 160, 120, 24, 6, 16, 14
    rts

!source "x16_code.asm"
```

## `+xm_shape_rrect x, y, w, h, r, col / +xm_shape_frrect ...`

| Field | Details |
|---|---|
| Macro | `+xm_shape_rrect x, y, w, h, r, col` / `+xm_shape_frrect ...` |
| Purpose | `SHAPES_RRECT` gate |
| Input parameters | `x, y, w, h, r, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_BEZIER = 1
X16_USE_SHAPES_PIE = 1
X16_USE_SHAPES_ARC = 1
X16_USE_SHAPES_POLY = 1
X16_USE_SHAPES = 1
X16_USE_BITMAP2H = 1
X16_USE_SHAPES_RRECT = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `SHAPES_RRECT` gate
    +xm_shape_rrect 32, 40, 96, 64, 24, 14
    +xm_shape_frrect 32, 40, 96, 64, 24, 14
    rts

!source "x16_code.asm"
```

## `+xm_shape_arc cx, cy, r, a0, a1, col`

| Field | Details |
|---|---|
| Macro | `+xm_shape_arc cx, cy, r, a0, a1, col` |
| Purpose | `SHAPES_ARC` gate |
| Input parameters | `cx, cy, r, a0, a1, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_BEZIER = 1
X16_USE_SHAPES_PIE = 1
X16_USE_SHAPES_RRECT = 1
X16_USE_SHAPES_POLY = 1
X16_USE_SHAPES = 1
X16_USE_BITMAP2H = 1
X16_USE_SHAPES_ARC = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `SHAPES_ARC` gate
    +xm_shape_arc 160, 120, 24, 0, 64, 14
    rts

!source "x16_code.asm"
```

## `+xm_shape_pie cx, cy, r, a0, a1, col`

| Field | Details |
|---|---|
| Macro | `+xm_shape_pie cx, cy, r, a0, a1, col` |
| Purpose | `SHAPES_PIE` gate |
| Input parameters | `cx, cy, r, a0, a1, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_BEZIER = 1
X16_USE_SHAPES_ARC = 1
X16_USE_SHAPES_RRECT = 1
X16_USE_SHAPES_POLY = 1
X16_USE_SHAPES = 1
X16_USE_BITMAP2H = 1
X16_USE_SHAPES_PIE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `SHAPES_PIE` gate
    +xm_shape_pie 160, 120, 24, 0, 64, 14
    rts

!source "x16_code.asm"
```

## `+xm_shape_bezier x0, y0, x1, y1, x2, y2, x3, y3, col`

| Field | Details |
|---|---|
| Macro | `+xm_shape_bezier x0, y0, x1, y1, x2, y2, x3, y3, col` |
| Purpose | `SHAPES_BEZIER` gate |
| Input parameters | `x0, y0, x1, y1, x2, y2, x3, y3, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SHAPES + sub-gates` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_PIE = 1
X16_USE_SHAPES_ARC = 1
X16_USE_SHAPES_RRECT = 1
X16_USE_SHAPES_POLY = 1
X16_USE_SHAPES = 1
X16_USE_BITMAP2H = 1
X16_USE_SHAPES_BEZIER = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `SHAPES_BEZIER` gate
    +xm_shape_bezier 24, 32, 96, 96, 160, 48, 224, 112, 14
    rts

!source "x16_code.asm"
```

