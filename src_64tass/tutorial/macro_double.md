# Double Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_DOUBLE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_DOUBLE = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `d_ac / addr`

| Field | Details |
|---|---|
| Macro | `d_ac` / `addr` |
| Purpose | accumulator / pointer to an 8-byte double in memory |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_DOUBLE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Store d_ac in memory, then restore it before another operation.
    #xm_d_from_s16 250
    #xm_d_store saved_double
    #xm_d_load saved_double
    rts

saved_double .fill 8, 0

.include "x16_code.asm"
```

## `d_exp, d_sqrt, d_sin, ...`

| Field | Details |
|---|---|
| Macro | `d_exp`, `d_sqrt`, `d_sin`, ... |
| Purpose | argument-free unary routines; call directly |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_DOUBLE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Unary double routines consume and replace d_ac directly.
    #xm_d_from_s16 144
    jsr d_sqrt
    jsr d_to_str
    rts

.include "x16_code.asm"
```

## `#xm_d_from_s16 value / #xm_d_from_str str, len`

| Field | Details |
|---|---|
| Macro | `#xm_d_from_s16 value` / `#xm_d_from_str str, len` |
| Purpose | build d_ac |
| Input parameters | `value`; `str, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_DOUBLE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; build d_ac
    #xm_d_from_s16 $1234
    #xm_d_from_str source_text, 16
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
```

## `#xm_d_load addr / #xm_d_store addr`

| Field | Details |
|---|---|
| Macro | `#xm_d_load addr` / `#xm_d_store addr` |
| Purpose | d_ac <-> memory |
| Input parameters | `addr` |
| Output parameters | memory |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_DOUBLE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; d_ac <-> memory
    #xm_d_load work_buffer
    #xm_d_store work_buffer
    rts

work_buffer .fill 64, 0

.include "x16_code.asm"
```

## `#xm_d_add / _sub / _mul / _div addr`

| Field | Details |
|---|---|
| Macro | `#xm_d_add / _sub / _mul / _div addr` |
| Purpose | d_ac op mem |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_DOUBLE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; d_ac op mem
    #xm_d_add work_buffer
    #xm_d_sub work_buffer
    #xm_d_mul work_buffer
    #xm_d_div work_buffer
    rts

work_buffer .fill 64, 0

.include "x16_code.asm"
```

## `#xm_d_pow addr`

| Field | Details |
|---|---|
| Macro | `#xm_d_pow addr` |
| Purpose | d_ac = d_ac ^ mem |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_DOUBLE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; d_ac = d_ac ^ mem
    #xm_d_pow work_buffer
    rts

work_buffer .fill 64, 0

.include "x16_code.asm"
```

## `#xm_d_cmp addr`

| Field | Details |
|---|---|
| Macro | `#xm_d_cmp addr` |
| Purpose | -> A = -1 / 0 / 1 |
| Input parameters | `addr` |
| Output parameters | A = -1 / 0 / 1 |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_DOUBLE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; -> A = -1 / 0 / 1
    #xm_d_cmp work_buffer
    rts

work_buffer .fill 64, 0

.include "x16_code.asm"
```
