# Screen Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_SCREEN` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_screen_set_mode mode`

| Field | Details |
|---|---|
| Macro | `xm_screen_set_mode mode` |
| Purpose | set the screen mode |
| Input parameters | `mode` |
| Output parameters | carry set if unsupported) |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_set_mode mode
    rts
```

## `xm_screen_reset`

| Field | Details |
|---|---|
| Macro | `xm_screen_reset` |
| Purpose | restore the default text mode |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_reset
    rts
```

## `xm_screen_cls`

| Field | Details |
|---|---|
| Macro | `xm_screen_cls` |
| Purpose | clear the text screen |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_cls
    rts
```

## `xm_screen_chrout ch`

| Field | Details |
|---|---|
| Macro | `xm_screen_chrout ch` |
| Purpose | print one character, safely |
| Input parameters | `ch` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_chrout ch
    rts
```

## `xm_screen_color fg, bg`

| Field | Details |
|---|---|
| Macro | `xm_screen_color fg, bg` |
| Purpose | text foreground / background (0-15) |
| Input parameters | `fg, bg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_color fg, bg
    rts
```

## `xm_screen_border col`

| Field | Details |
|---|---|
| Macro | `xm_screen_border col` |
| Purpose | border colour (0-15) |
| Input parameters | `col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_border col
    rts
```

## `xm_screen_locate row, col`

| Field | Details |
|---|---|
| Macro | `xm_screen_locate row, col` |
| Purpose | move the text cursor |
| Input parameters | `row, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_locate row, col
    rts
```

## `xm_screen_charset cs`

| Field | Details |
|---|---|
| Macro | `xm_screen_charset cs` |
| Purpose | select a charset |
| Input parameters | `cs` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_charset cs
    rts
```

## `xm_screen_puts addr`

| Field | Details |
|---|---|
| Macro | `xm_screen_puts addr` |
| Purpose | print a NUL-terminated string |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SCREEN = 1
    icl "x16.asm"

main
    xm_screen_puts addr
    rts
```
