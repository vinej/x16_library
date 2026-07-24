# Keyboard Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_KEYBOARD` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_KEYBOARD = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_kbd_scan / xm_kbd_peek / xm_kbd_put key`

| Field | Details |
|---|---|
| Macro | `xm_kbd_scan` / `xm_kbd_peek` / `xm_kbd_put key` |
| Purpose | keyboard scan/read/write helpers |
| Input parameters | `key` |
| Output parameters | keyboard scan/read/write helpers |
| More info | Available when `X16_USE_KEYBOARD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_KEYBOARD = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; keyboard scan/read/write helpers
    xm_kbd_scan
    xm_kbd_peek
    xm_kbd_put 'Y'
    rts

    icl "x16_code.asm"
```

## `xm_kbd_get_modifiers`

| Field | Details |
|---|---|
| Macro | `xm_kbd_get_modifiers` |
| Purpose | read modifier state |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_KEYBOARD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_KEYBOARD = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; read modifier state
    xm_kbd_get_modifiers
    rts

    icl "x16_code.asm"
```

## `xm_kbd_get_keymap / xm_kbd_set_keymap name`

| Field | Details |
|---|---|
| Macro | `xm_kbd_get_keymap` / `xm_kbd_set_keymap name` |
| Purpose | keymap helpers |
| Input parameters | `name` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_KEYBOARD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_KEYBOARD = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; keymap helpers
    xm_kbd_get_keymap
    xm_kbd_set_keymap file_name
    rts

file_name .byte "SAVEGAME,S,R", 0

    icl "x16_code.asm"
```
