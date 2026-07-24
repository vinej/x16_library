# Console Macros

Detailed reference for the `X16_USE_CONSOLE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_CONSOLE = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `+xm_con_init_fullscreen / +xm_con_init x, y, w, h`

| Field | Details |
|---|---|
| Macro | `+xm_con_init_fullscreen` / `+xm_con_init x, y, w, h` |
| Purpose | initialize console |
| Input parameters | `x, y, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_CONSOLE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; initialize console
    +xm_con_init_fullscreen
    +xm_con_init 32, 40, 96, 64
    rts

!source "x16_code.asm"
```

## `+xm_con_set_paging_message msg / +xm_con_disable_paging`

| Field | Details |
|---|---|
| Macro | `+xm_con_set_paging_message msg` / `+xm_con_disable_paging` |
| Purpose | paging controls |
| Input parameters | `msg` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_CONSOLE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; paging controls
    +xm_con_set_paging_message 1
    +xm_con_disable_paging
    rts

!source "x16_code.asm"
```

## `+xm_con_put_char_wrap char / +xm_con_put_char_word char`

| Field | Details |
|---|---|
| Macro | `+xm_con_put_char_wrap char` / `+xm_con_put_char_word char` |
| Purpose | print with wrapping |
| Input parameters | `char` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_CONSOLE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; print with wrapping
    +xm_con_put_char_wrap 1
    +xm_con_put_char_word 1
    rts

!source "x16_code.asm"
```

## `+xm_con_get_char`

| Field | Details |
|---|---|
| Macro | `+xm_con_get_char` |
| Purpose | read one console character |
| Input parameters | No macro arguments. |
| Output parameters | read one console character |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_CONSOLE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; read one console character
    +xm_con_get_char
    rts

!source "x16_code.asm"
```

## `+xm_con_put_image image, w, h`

| Field | Details |
|---|---|
| Macro | `+xm_con_put_image image, w, h` |
| Purpose | draw console image data |
| Input parameters | `image, w, h` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CONSOLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_CONSOLE = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; draw console image data
    +xm_con_put_image 1, 96, 64
    rts

!source "x16_code.asm"
```

