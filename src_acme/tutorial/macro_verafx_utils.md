# VERA FX utilities Macros

Detailed reference for the `X16_USE_VERAFX_UTILS` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_VERAFX_UTILS = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `+xm_fxu_off / +xm_fxu_get_ctrl / +xm_fxu_set_ctrl ctrl`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_off` / `+xm_fxu_get_ctrl` / `+xm_fxu_set_ctrl ctrl` |
| Purpose | FX control |
| Input parameters | `ctrl` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; FX control
    +xm_fxu_off
    +xm_fxu_get_ctrl
    +xm_fxu_set_ctrl $01
    rts

!source "x16_code.asm"
```

## `+xm_fxu_ctrl_on mask / +xm_fxu_ctrl_off mask`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_ctrl_on mask` / `+xm_fxu_ctrl_off mask` |
| Purpose | set/clear FX bits |
| Input parameters | `mask` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; set/clear FX bits
    +xm_fxu_ctrl_on $01
    +xm_fxu_ctrl_off $01
    rts

!source "x16_code.asm"
```

## `+xm_fxu_addr1_mode mode`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_addr1_mode mode` |
| Purpose | ADDR1 mode bits |
| Input parameters | `mode` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; ADDR1 mode bits
    +xm_fxu_addr1_mode 0
    rts

!source "x16_code.asm"
```

## `+xm_fxu_cache_write_on/off, +xm_fxu_cache_fill_on/off, +xm_fxu_cache_cycle_on/off`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_cache_write_on/off`, `+xm_fxu_cache_fill_on/off`, `+xm_fxu_cache_cycle_on/off` |
| Purpose | cache modes |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; cache modes
    +xm_fxu_cache_write_on
    +xm_fxu_cache_write_off
    rts

!source "x16_code.asm"
```

## `+xm_fxu_transparent_on/off, +xm_fxu_4bit_on/off, +xm_fxu_hop_on/off`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_transparent_on/off`, `+xm_fxu_4bit_on/off`, `+xm_fxu_hop_on/off` |
| Purpose | transparent, 4-bit, 16-bit hop |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; transparent, 4-bit, 16-bit hop
    +xm_fxu_transparent_on
    +xm_fxu_transparent_off
    rts

!source "x16_code.asm"
```

## `+xm_fxu_set_mult mult / +xm_fxu_set_cache b0, b1, b2, b3`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_set_mult mult` / `+xm_fxu_set_cache b0, b1, b2, b3` |
| Purpose | multiplier/cache registers |
| Input parameters | `mult`; `b0, b1, b2, b3` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; multiplier/cache registers
    +xm_fxu_set_mult 16
    +xm_fxu_set_cache 1, 1, 1, 1
    rts

!source "x16_code.asm"
```

## `+xm_fxu_reset_accum / +xm_fxu_accumulate`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_reset_accum` / `+xm_fxu_accumulate` |
| Purpose | accumulator helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; accumulator helpers
    +xm_fxu_reset_accum
    +xm_fxu_accumulate
    rts

!source "x16_code.asm"
```

## `+xm_fxu_cache_fill0/1 / +xm_fxu_cache_write0/1 mask`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_cache_fill0/1` / `+xm_fxu_cache_write0/1 mask` |
| Purpose | cache fill/write primitives |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; cache fill/write primitives
    +xm_fxu_cache_fill0
    +xm_fxu_cache_write0 $01
    +xm_fxu_cache_fill1
    rts

!source "x16_code.asm"
```

## `+xm_fxu_set_incr xinc, yinc / +xm_fxu_set_pos xpos, ypos / +xm_fxu_set_subpos xsub, ysub`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_set_incr xinc, yinc` / `+xm_fxu_set_pos xpos, ypos` / `+xm_fxu_set_subpos xsub, ysub` |
| Purpose | affine stepping state |
| Input parameters | `xinc, yinc`; `xpos, ypos`; `xsub, ysub` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; affine stepping state
    +xm_fxu_set_incr $0100, $0100
    +xm_fxu_set_pos 0, 0
    +xm_fxu_set_subpos 0, 0
    rts

!source "x16_code.asm"
```

## `+xm_fxu_get_poly_fill / +xm_fxu_set_tilebase value / +xm_fxu_set_mapbase value`

| Field | Details |
|---|---|
| Macro | `+xm_fxu_get_poly_fill` / `+xm_fxu_set_tilebase value` / `+xm_fxu_set_mapbase value` |
| Purpose | polygon/tile/map helpers |
| Input parameters | `value` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX_UTILS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_VERAFX_UTILS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; polygon/tile/map helpers
    +xm_fxu_get_poly_fill
    +xm_fxu_set_tilebase $1234
    +xm_fxu_set_mapbase $1234
    rts

!source "x16_code.asm"
```

