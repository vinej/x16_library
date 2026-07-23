# GRAPH Macros

Detailed reference for the `X16_USE_GRAPH` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_GRAPH = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `+xm_graph_init_default / +xm_graph_init driver`

| Field | Details |
|---|---|
| Macro | `+xm_graph_init_default` / `+xm_graph_init driver` |
| Purpose | init GRAPH with default/custom FB driver |
| Input parameters | `driver` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_init_default
    rts
```

## `+xm_graph_clear / +xm_graph_set_window x, y, w, h`

| Field | Details |
|---|---|
| Macro | `+xm_graph_clear` / `+xm_graph_set_window x, y, w, h` |
| Purpose | clear/window |
| Input parameters | `x, y, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_clear
    rts
```

## `+xm_graph_set_colors stroke, fill, background`

| Field | Details |
|---|---|
| Macro | `+xm_graph_set_colors stroke, fill, background` |
| Purpose | drawing colours |
| Input parameters | `stroke, fill, background` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_set_colors stroke, fill, background
    rts
```

## `+xm_graph_draw_line x1, y1, x2, y2`

| Field | Details |
|---|---|
| Macro | `+xm_graph_draw_line x1, y1, x2, y2` |
| Purpose | line |
| Input parameters | `x1, y1, x2, y2` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_draw_line x1, y1, x2, y2
    rts
```

## `+xm_graph_draw_rect_outline/fill x, y, w, h, radius`

| Field | Details |
|---|---|
| Macro | `+xm_graph_draw_rect_outline/fill x, y, w, h, radius` |
| Purpose | rectangles |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_draw_rect_outline
    rts
```

## `+xm_graph_move_rect sx, sy, tx, ty, w, h`

| Field | Details |
|---|---|
| Macro | `+xm_graph_move_rect sx, sy, tx, ty, w, h` |
| Purpose | move rectangle |
| Input parameters | `sx, sy, tx, ty, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_move_rect sx, sy, tx, ty, w, h
    rts
```

## `+xm_graph_draw_oval_outline/fill x, y, w, h`

| Field | Details |
|---|---|
| Macro | `+xm_graph_draw_oval_outline/fill x, y, w, h` |
| Purpose | ovals |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_draw_oval_outline
    rts
```

## `+xm_graph_draw_image x, y, image, w, h`

| Field | Details |
|---|---|
| Macro | `+xm_graph_draw_image x, y, image, w, h` |
| Purpose | image bytes |
| Input parameters | `x, y, image, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_draw_image x, y, image, w, h
    rts
```

## `+xm_graph_set_font_default / +xm_graph_set_font font`

| Field | Details |
|---|---|
| Macro | `+xm_graph_set_font_default` / `+xm_graph_set_font font` |
| Purpose | font |
| Input parameters | `font` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_set_font_default
    rts
```

## `+xm_graph_get_char_size char, style / +xm_graph_put_char char, x, y`

| Field | Details |
|---|---|
| Macro | `+xm_graph_get_char_size char, style` / `+xm_graph_put_char char, x, y` |
| Purpose | text metrics/draw |
| Input parameters | `char, style`; `char, x, y` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_GRAPH` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_GRAPH = 1
!source "x16.asm"

main
    +xm_graph_get_char_size char, style
    rts
```

