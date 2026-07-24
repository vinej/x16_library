# Float Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_FLOAT` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_FLOAT = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `FAC / addr`

| Field | Details |
|---|---|
| Macro | `FAC` / `addr` |
| Purpose | accumulator / pointer to a 5-byte float in memory |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; Store a calculated value in memory, then load it again later.
    xm_f_from_s16 250
    xm_f_store saved_float
    xm_f_load saved_float
    rts

saved_float
:(5) dta 0

    icl "x16_code.asm"
```

## `f_sqrt, f_sin, f_ln, f_int, ...`

| Field | Details |
|---|---|
| Macro | `f_sqrt`, `f_sin`, `f_ln`, `f_int`, ... |
| Purpose | argument-free unary routines; call directly |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; The unary routines operate directly on FAC after a loader macro.
    xm_f_from_s16 144
    jsr f_sqrt
    jsr f_to_str_trim
    rts

    icl "x16_code.asm"
```

## `xm_f_from_u8 byte / xm_f_from_s16 value`

| Field | Details |
|---|---|
| Macro | `xm_f_from_u8 byte` / `xm_f_from_s16 value` |
| Purpose | build FAC from an integer |
| Input parameters | `byte`; `value` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; build FAC from an integer
    xm_f_from_u8 'A'
    xm_f_from_s16 $1234
    rts

    icl "x16_code.asm"
```

## `xm_f_from_str str, len`

| Field | Details |
|---|---|
| Macro | `xm_f_from_str str, len` |
| Purpose | parse a string into FAC |
| Input parameters | `str, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; parse a string into FAC
    xm_f_from_str source_text, 16
    rts

source_text .byte "LEVEL/01", 0

    icl "x16_code.asm"
```

## `xm_f_load addr / xm_f_store addr`

| Field | Details |
|---|---|
| Macro | `xm_f_load addr` / `xm_f_store addr` |
| Purpose | FAC <-> memory |
| Input parameters | `addr` |
| Output parameters | memory |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; FAC <-> memory
    xm_f_load work_buffer
    xm_f_store work_buffer
    rts

work_buffer
:(64) dta 0

    icl "x16_code.asm"
```

## `xm_f_add / _sub / _mul / _div addr`

| Field | Details |
|---|---|
| Macro | `xm_f_add / _sub / _mul / _div addr` |
| Purpose | FAC op mem |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; FAC op mem
    xm_f_add work_buffer
    xm_f_sub work_buffer
    xm_f_mul work_buffer
    xm_f_div work_buffer
    rts

work_buffer
:(64) dta 0

    icl "x16_code.asm"
```

## `xm_f_rsub addr / xm_f_rdiv addr`

| Field | Details |
|---|---|
| Macro | `xm_f_rsub addr` / `xm_f_rdiv addr` |
| Purpose | mem - FAC / mem / FAC |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; mem - FAC / mem / FAC
    xm_f_rsub work_buffer
    xm_f_rdiv work_buffer
    rts

work_buffer
:(64) dta 0

    icl "x16_code.asm"
```

## `xm_f_pow addr`

| Field | Details |
|---|---|
| Macro | `xm_f_pow addr` |
| Purpose | FAC = FAC ^ mem |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; FAC = FAC ^ mem
    xm_f_pow work_buffer
    rts

work_buffer
:(64) dta 0

    icl "x16_code.asm"
```

## `xm_f_cmp addr`

| Field | Details |
|---|---|
| Macro | `xm_f_cmp addr` |
| Purpose | -> A = -1 / 0 / 1 |
| Input parameters | `addr` |
| Output parameters | A = -1 / 0 / 1 |
| More info | Available when `X16_USE_FLOAT` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; MADS: assemble for 65C02
    icl "x16.asm"

X16_USE_FLOAT = 1
    icl "core/sugar.asm"

    org $0801
    basic_stub

main
  ; -> A = -1 / 0 / 1
    xm_f_cmp work_buffer
    rts

work_buffer
:(64) dta 0

    icl "x16_code.asm"
```
