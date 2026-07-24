# Input Macros

Detailed reference for the `X16_USE_INPUT` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_INPUT = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `+xm_joy_scan / +xm_joy_get pad`

| Field | Details |
|---|---|
| Macro | `+xm_joy_scan` / `+xm_joy_get pad` |
| Purpose | sample / read a joystick |
| Input parameters | `pad` |
| Output parameters | A/X/Y = buttons) |
| More info | Available when `X16_USE_INPUT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_INPUT = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; sample / read a joystick
    +xm_joy_scan
    +xm_joy_get 1
    rts

!source "x16_code.asm"
```

## `+xm_mouse_show cursor / +xm_mouse_hide / +xm_mouse_get`

| Field | Details |
|---|---|
| Macro | `+xm_mouse_show cursor` / `+xm_mouse_hide` / `+xm_mouse_get` |
| Purpose | mouse |
| Input parameters | `cursor` |
| Output parameters | P0/1 = x, P2/3 = y, A = buttons) |
| More info | Available when `X16_USE_INPUT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_INPUT = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; mouse
    +xm_mouse_show 0
    +xm_mouse_hide
    +xm_mouse_get
    rts

!source "x16_code.asm"
```

## `+xm_key_get / +xm_key_wait / +xm_key_peek`

| Field | Details |
|---|---|
| Macro | `+xm_key_get` / `+xm_key_wait` / `+xm_key_peek` |
| Purpose | keyboard |
| Input parameters | No macro arguments. |
| Output parameters | A = PETSCII) |
| More info | Available when `X16_USE_INPUT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_INPUT = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; keyboard
    +xm_key_get
    +xm_key_wait
    +xm_key_peek
    rts

!source "x16_code.asm"
```

