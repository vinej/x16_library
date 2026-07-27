# Screen Macros

Detailed reference for the `X16_USE_SCREEN` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_SCREEN = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `+xm_screen_set_mode mode`

| Field | Details |
|---|---|
| Macro | `+xm_screen_set_mode mode` |
| Purpose | set the screen mode |
| Input parameters | `mode` |
| Output parameters | carry set if unsupported) |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_set_mode 0
    rts

!source "x16_code.asm"
```

## `+xm_screen_reset`

| Field | Details |
|---|---|
| Macro | `+xm_screen_reset` |
| Purpose | restore the default text mode |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_reset
    rts

!source "x16_code.asm"
```

## `+xm_screen_cls`

| Field | Details |
|---|---|
| Macro | `+xm_screen_cls` |
| Purpose | clear the text screen |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_cls
    rts

!source "x16_code.asm"
```

## `+xm_screen_chrout ch`

| Field | Details |
|---|---|
| Macro | `+xm_screen_chrout ch` |
| Purpose | print one character, safely |
| Input parameters | `ch` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_chrout '/'
    rts

!source "x16_code.asm"
```

## `+xm_screen_color fg, bg`

| Field | Details |
|---|---|
| Macro | `+xm_screen_color fg, bg` |
| Purpose | text foreground / background (0-15) |
| Input parameters | `fg, bg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_color 15, 0
    rts

!source "x16_code.asm"
```

## `+xm_screen_border col`

| Field | Details |
|---|---|
| Macro | `+xm_screen_border col` |
| Purpose | border colour (0-15) |
| Input parameters | `col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_border 14
    rts

!source "x16_code.asm"
```

## `+xm_screen_locate row, col`

| Field | Details |
|---|---|
| Macro | `+xm_screen_locate row, col` |
| Purpose | move the text cursor |
| Input parameters | `row, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_locate 5, 14
    rts

!source "x16_code.asm"
```

## `+xm_screen_charset cs`

| Field | Details |
|---|---|
| Macro | `+xm_screen_charset cs` |
| Purpose | select a charset |
| Input parameters | `cs` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_charset 1
    rts

!source "x16_code.asm"
```

## `+xm_screen_puts addr`

| Field | Details |
|---|---|
| Macro | `+xm_screen_puts addr` |
| Purpose | print a NUL-terminated string |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SCREEN` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Write a status line on the text screen.
    +xm_screen_puts work_buffer
    rts

work_buffer !fill 64, 0

!source "x16_code.asm"
```


## Painting the text screen directly

`CHROUT` is the right call for a line of output, but the wrong one for a
screenful. Every character pays for the editor's scroll checks, colour handling
and cursor bookkeeping -- several hundred cycles each -- so a program that
repaints an 80x60 grid on every keystroke, a spreadsheet or a file browser or
any full-screen TUI, spends most of its time inside the KERNAL.

The macros below write VERA's tile map instead. `+xm_screen_addr` points port 0
at a character cell with auto-increment 1; after that each pair of bytes is one
character and its colour, and the address walks the row by itself. A whole line
costs one set-up and two stores per column.

They do not scroll, do not wrap and do not move the `CHROUT` cursor, so do not
write past the end of a row. Text goes in as PETSCII -- the same bytes you would
hand `CHROUT` -- and is folded to screen codes on the way. The colour byte is
`foreground | background << 4`, the layout `+xm_screen_color` builds.

## `+xm_screen_addr row, col`

| Field | Details |
|---|---|
| Macro | `+xm_screen_addr row, col` |
| Purpose | point VERA port 0 at a character cell, auto-incrementing by one |
| Input parameters | `row`, `col` |
| Output parameters | Leaves `ADDRSEL` = 0. Reads `L1_MAPBASE` / `L1_CONFIG`, so it follows whatever `screen_set_mode` left behind. |
| More info | Available when `X16_USE_SCREEN_EXTRA` is enabled. |
| Example | See below. |

## `+xm_screen_addr1 row, col`

| Field | Details |
|---|---|
| Macro | `+xm_screen_addr1 row, col` |
| Purpose | the same, for VERA **port 1** |
| Input parameters | `row`, `col` |
| Output parameters | Leaves `ADDRSEL` = 1. |
| More info | Available when `X16_USE_SCREEN_EXTRA` is enabled. Port 1 is where a `vera_copy` destination goes, so this is the partner of `+xm_screen_addr` when moving text about. |
| Example | See below. |

## `+xm_screen_blit addr, count, col`

| Field | Details |
|---|---|
| Macro | `+xm_screen_blit addr, count, col` |
| Purpose | write `count` PETSCII characters from `addr`, all in colour `col` |
| Input parameters | `addr`, `count` (1-255), `col` |
| Output parameters | Port 0 is left pointing just past the last cell, so runs chain. |
| More info | Available when `X16_USE_SCREEN_EXTRA` is enabled. |
| Example | See below. |

## `+xm_screen_blitfill count, col, ch`

| Field | Details |
|---|---|
| Macro | `+xm_screen_blitfill count, col, ch` |
| Purpose | write `count` copies of one character -- the usual way to blank part of a line |
| Input parameters | `count` (1-255), `col`, `ch` |
| Output parameters | Same contract as `+xm_screen_blit`. |
| More info | Available when `X16_USE_SCREEN_EXTRA` is enabled. |
| Example | See below. |

## `+xm_screen_scode ch`

| Field | Details |
|---|---|
| Macro | `+xm_screen_scode ch` |
| Purpose | fold one PETSCII code to its screen code |
| Input parameters | `ch` |
| Output parameters | `A` = screen code. |
| More info | Available when `X16_USE_SCREEN_EXTRA` is enabled. Only needed if you are building tile data yourself; the blits fold their own text. |
| Example | See below. |

## `+xm_screen_scroll top, left, height, width, rows, dir`

| Field | Details |
|---|---|
| Macro | `+xm_screen_scroll top, left, height, width, rows, dir` |
| Purpose | slide a rectangle of the text screen up (`dir` 0) or down (`dir` 1) |
| Input parameters | `top`, `left`, `height`, `width`, `rows`, `dir` |
| Output parameters | The rows uncovered at the trailing edge keep their old contents -- draw what belongs there yourself. Does nothing if `rows` is 0, or large enough that nothing would survive, so you can simply repaint in that case. |
| More info | Available when `X16_USE_SCREEN_EXTRA` is enabled. Vertical only: scrolling sideways would move a row onto itself, and `vera_copy` walks forward. |
| Example | See below. |

A full-screen program that re-renders its whole grid to scroll one line pays for
every cell it draws -- and for a spreadsheet or a directory listing, most of that
cost is *formatting* the contents, not drawing them. Moving the picture inside
VRAM and rendering only the row that appears costs one row instead of a
screenful, whatever the contents happen to be.

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN_EXTRA = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

WHITE_ON_BLUE = 1 | (6 << 4)

main
    ; A status bar across the top, then a listing that scrolls up one line
    ; with only the newly exposed row drawn.
    +xm_screen_addr 0, 0
    +xm_screen_blit title, 5, WHITE_ON_BLUE
    +xm_screen_blitfill 75, WHITE_ON_BLUE, ' '

    +xm_screen_scroll 2, 0, 56, 80, 1, 0
    +xm_screen_addr 57, 0
    +xm_screen_blit newrow, 11, WHITE_ON_BLUE
    +xm_screen_blitfill 69, WHITE_ON_BLUE, ' '
    rts

title  !text "READY"
newrow !text "the new row"

!source "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of screen

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `+xm_screen_get_mode`

| Field | Details |
|---|---|
| Macro | `+xm_screen_get_mode` |
| Purpose | read back the current screen mode |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_SCREEN_EXTRA` is enabled. |

## `+xm_screen_get_cursor`

| Field | Details |
|---|---|
| Macro | `+xm_screen_get_cursor` |
| Purpose | read it back |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_SCREEN_EXTRA` is enabled. |

## Reference: routines not covered above

Taken from each routine's own header in the source, so this
stays true as the module changes.

| Routine | Purpose | In | Out |
|---|---|---|---|
| `screen_get_size` | the live text grid, after any screen_set_mode | -- | X = columns, Y = rows |
| `screen_addr_store` | -- | -- | -- |
| `screen_addr_calc` | -- | -- | -- |
