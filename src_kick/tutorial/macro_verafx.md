# VERA FX Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_VERAFX` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_VERAFX
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_fx_off()`

| Field | Details |
|---|---|
| Macro | `xm_fx_off()` |
| Purpose | disable FX (leaves DCSEL/ADDRSEL = 0) |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_VERAFX
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // disable FX (leaves DCSEL/ADDRSEL = 0)
    xm_fx_off()
    rts

#import "x16_code.asm"
```

## `xm_fx_mult(a, b)`

| Field | Details |
|---|---|
| Macro | `xm_fx_mult(a, b)` |
| Purpose | signed 16x16 |
| Input parameters | `a, b` |
| Output parameters | P4..P7 = product) |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_VERAFX
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // signed 16x16
    xm_fx_mult($20, $a0)
    rts

#import "x16_code.asm"
```

## `xm_fx_fill(val, count)`

| Field | Details |
|---|---|
| Macro | `xm_fx_fill(val, count)` |
| Purpose | fast fill from the current address |
| Input parameters | `val, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_VERAFX
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // fast fill from the current address
    xm_fx_fill($20, 32)
    rts

#import "x16_code.asm"
```

## `xm_fx_clear(addrlo, addrmid, addrhi, count)`

| Field | Details |
|---|---|
| Macro | `xm_fx_clear(addrlo, addrmid, addrhi, count)` |
| Purpose | zero a VRAM region |
| Input parameters | `addrlo, addrmid, addrhi, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_VERAFX
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // zero a VRAM region
    xm_fx_clear($00, $20, $10, 32)
    rts

#import "x16_code.asm"
```

## `xm_fx_transp_on / xm_fx_transp_off`

| Field | Details |
|---|---|
| Macro | `xm_fx_transp_on()` / `xm_fx_transp_off()` |
| Purpose | transparent VRAM writes |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_VERAFX
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // transparent VRAM writes
    xm_fx_transp_on()
    xm_fx_transp_off()
    rts

#import "x16_code.asm"
```

## `xm_fx_line(x0, y0, x1, y1, col)`

| Field | Details |
|---|---|
| Macro | `xm_fx_line(x0, y0, x1, y1, col)` |
| Purpose | hardware-assisted line |
| Input parameters | `x0, y0, x1, y1, col` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERAFX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_VERAFX
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // hardware-assisted line
    xm_fx_line(24, 32, 96, 96, 14)
    rts

#import "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of verafx

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `xm_fx_triangle()`

| Field | Details |
|---|---|
| Macro | `xm_fx_triangle()` |
| Purpose | filled triangle via the polygon helper |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_TRI` is enabled. |

## `xm_fx_copy(src, srchi, dst, dsthi, count)`

| Field | Details |
|---|---|
| Macro | `xm_fx_copy(src, srchi, dst, dsthi, count)` |
| Purpose | VRAM to VRAM through the 32-bit cache (~4x a byte loop) |
| Input parameters | `src`, `srchi`, `dst`, `dsthi`, `count` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_COPY` is enabled. |

## `xm_fx_affine_on(tiledata, tiledatahi, tilemap, tilemaphi, mapsize, clip)`

| Field | Details |
|---|---|
| Macro | `xm_fx_affine_on(tiledata, tiledatahi, tilemap, tilemaphi, mapsize, clip)` |
| Purpose | enter affine mode and describe the texture |
| Input parameters | `tiledata`, `tiledatahi`, `tilemap`, `tilemaphi`, `mapsize`, `clip` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_AFFINE` is enabled. |

## `xm_fx_affine_ray(x, y, dx, dy)`

| Field | Details |
|---|---|
| Macro | `xm_fx_affine_ray(x, y, dx, dy)` |
| Purpose | aim the sampler |
| Input parameters | `x`, `y`, `dx`, `dy` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_AFFINE` is enabled. |

## `xm_fx_affine_span(count)`

| Field | Details |
|---|---|
| Macro | `xm_fx_affine_span(count)` |
| Purpose | fetch texels along the ray into VRAM |
| Input parameters | `count` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_VERAFX_AFFINE` is enabled. |
