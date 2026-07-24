# Integers Macros

Detailed reference for the `X16_USE_INT16, X16_USE_INT32` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_INT16 = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `i16_add, i16_mul, i32_divmod, ...`

| Field | Details |
|---|---|
| Macro | `i16_add`, `i16_mul`, `i32_divmod`, ... |
| Purpose | argument-free routines; load `i16_a`/`i16_b` or `i32_a`/`i32_b`, then `jsr` |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_INT16, X16_USE_INT32` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_INT16 = 1
X16_USE_INT32 = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; Load the integer registers, then call argument-free arithmetic directly.
    +i16_const i16_a, 1000
    +i16_const i16_b, 7
    jsr i16_divmod

    +i32_const i32_a, 1000000
    +i32_const i32_b, 7
    jsr i32_divmod
    rts

!source "x16_code.asm"
```

## `+xm_i16_from_u8 byte / +xm_i16_from_s8 byte`

| Field | Details |
|---|---|
| Macro | `+xm_i16_from_u8 byte` / `+xm_i16_from_s8 byte` |
| Purpose | integer loaders |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_INT16, X16_USE_INT32` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_INT16 = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; integer loaders
    +xm_i16_from_u8 'A'
    +xm_i16_from_s8 'A'
    rts

!source "x16_code.asm"
```

## `+xm_i32_from_u16 value / +xm_i32_from_s16 value`

| Field | Details |
|---|---|
| Macro | `+xm_i32_from_u16 value` / `+xm_i32_from_s16 value` |
| Purpose | integer loaders |
| Input parameters | `value` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_INT16, X16_USE_INT32` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_INT32 = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; integer loaders
    +xm_i32_from_u16 $1234
    +xm_i32_from_s16 $1234
    rts

!source "x16_code.asm"
```

