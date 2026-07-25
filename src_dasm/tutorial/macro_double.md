# Double Macros

> Generated dasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_DOUBLE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_DOUBLE = 1
include "x16.asm"
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
processor 65c02
include "x16.asm"

X16_USE_DOUBLE = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; Store d_ac in memory, then restore it before another operation.
    xm_d_from_s16 250
    xm_d_store saved_double
    xm_d_load saved_double
    rts

saved_double ds 8, 0

include "x16_code.asm"
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
processor 65c02
include "x16.asm"

X16_USE_DOUBLE = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; Unary double routines consume and replace d_ac directly.
    xm_d_from_s16 144
    jsr d_sqrt
    jsr d_to_str
    rts

include "x16_code.asm"
```

## `xm_d_from_s16 value / xm_d_from_str str, len`

| Field | Details |
|---|---|
| Macro | `xm_d_from_s16 value` / `xm_d_from_str str, len` |
| Purpose | build d_ac |
| Input parameters | `value`; `str, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_DOUBLE = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; build d_ac
    xm_d_from_s16 $1234
    xm_d_from_str source_text, 16
    rts

source_text dc.b "LEVEL/01", 0

include "x16_code.asm"
```

## `xm_d_load addr / xm_d_store addr`

| Field | Details |
|---|---|
| Macro | `xm_d_load addr` / `xm_d_store addr` |
| Purpose | d_ac <-> memory |
| Input parameters | `addr` |
| Output parameters | memory |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_DOUBLE = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; d_ac <-> memory
    xm_d_load work_buffer
    xm_d_store work_buffer
    rts

work_buffer ds 64, 0

include "x16_code.asm"
```

## `xm_d_add / _sub / _mul / _div addr`

| Field | Details |
|---|---|
| Macro | `xm_d_add / _sub / _mul / _div addr` |
| Purpose | d_ac op mem |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_DOUBLE = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; d_ac op mem
    xm_d_add work_buffer
    xm_d_sub work_buffer
    xm_d_mul work_buffer
    xm_d_div work_buffer
    rts

work_buffer ds 64, 0

include "x16_code.asm"
```

## `xm_d_pow addr`

| Field | Details |
|---|---|
| Macro | `xm_d_pow addr` |
| Purpose | d_ac = d_ac ^ mem |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_DOUBLE = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; d_ac = d_ac ^ mem
    xm_d_pow work_buffer
    rts

work_buffer ds 64, 0

include "x16_code.asm"
```

## `xm_d_cmp addr`

| Field | Details |
|---|---|
| Macro | `xm_d_cmp addr` |
| Purpose | -> A = -1 / 0 / 1 |
| Input parameters | `addr` |
| Output parameters | A = -1 / 0 / 1 |
| More info | Available when `X16_USE_DOUBLE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_DOUBLE = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; -> A = -1 / 0 / 1
    xm_d_cmp work_buffer
    rts

work_buffer ds 64, 0

include "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of double

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `xm_d_neg`

| Field | Details |
|---|---|
| Macro | `xm_d_neg` |
| Purpose | d_ac = -d_ac d_abs -- d_ac = |d_ac| |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_abs`

| Field | Details |
|---|---|
| Macro | `xm_d_abs` |
| Purpose | d_ac = |d_ac| |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_to_s32`

| Field | Details |
|---|---|
| Macro | `xm_d_to_s32` |
| Purpose | X16_P0..P3 = (s32) d_ac, truncated toward zero |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_sqrt`

| Field | Details |
|---|---|
| Macro | `xm_d_sqrt` |
| Purpose | d_ac = sqrt(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_exp`

| Field | Details |
|---|---|
| Macro | `xm_d_exp` |
| Purpose | d_ac = e^d_ac |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_ln`

| Field | Details |
|---|---|
| Macro | `xm_d_ln` |
| Purpose | d_ac = ln(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_sin`

| Field | Details |
|---|---|
| Macro | `xm_d_sin` |
| Purpose | d_ac = sin/cos/tan(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_cos`

| Field | Details |
|---|---|
| Macro | `xm_d_cos` |
| Purpose | d_ac = sin/cos/tan(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_tan`

| Field | Details |
|---|---|
| Macro | `xm_d_tan` |
| Purpose | d_ac = sin/cos/tan(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_atan`

| Field | Details |
|---|---|
| Macro | `xm_d_atan` |
| Purpose | d_ac = atan(d_ac) |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_sinh`

| Field | Details |
|---|---|
| Macro | `xm_d_sinh` |
| Purpose | d_ac = sinh/cosh/tanh(d_ac), via exp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_cosh`

| Field | Details |
|---|---|
| Macro | `xm_d_cosh` |
| Purpose | d_ac = sinh/cosh/tanh(d_ac), via exp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_tanh`

| Field | Details |
|---|---|
| Macro | `xm_d_tanh` |
| Purpose | d_ac = sinh/cosh/tanh(d_ac), via exp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_to_str`

| Field | Details |
|---|---|
| Macro | `xm_d_to_str` |
| Purpose | format d_ac as a NUL-terminated decimal string |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |

## `xm_d_from_s32 addr`

| Field | Details |
|---|---|
| Macro | `xm_d_from_s32 addr` |
| Purpose | in: X16_P0..P3 = signed 32-bit, little-endian |
| Input parameters | `addr` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOUBLE` is enabled. |
