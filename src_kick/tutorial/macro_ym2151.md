# YM2151 Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_YM` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_YM
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_ym_init()`

| Field | Details |
|---|---|
| Macro | `xm_ym_init()` |
| Purpose | reset the chip, load the default patches |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_YM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // reset the chip, load the default patches
    xm_ym_init()
    rts

#import "x16_code.asm"
```

## `xm_ym_write reg, val / xm_ym_poke reg, val`

| Field | Details |
|---|---|
| Macro | `xm_ym_write(reg, val)` / `xm_ym_poke(reg, val)` |
| Purpose | raw register write / shadowed write |
| Input parameters | `reg, val` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_YM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // raw register write / shadowed write
    xm_ym_write($20, $20)
    xm_ym_poke($20, $20)
    rts

#import "x16_code.asm"
```

## `xm_ym_patch_rom(channel, index)`

| Field | Details |
|---|---|
| Macro | `xm_ym_patch_rom(channel, index)` |
| Purpose | load a built-in ROM patch (0-162) |
| Input parameters | `channel, index` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_YM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // load a built-in ROM patch (0-162)
    xm_ym_patch_rom(0, 1)
    rts

#import "x16_code.asm"
```

## `xm_ym_note(channel, kc, kf)`

| Field | Details |
|---|---|
| Macro | `xm_ym_note(channel, kc, kf)` |
| Purpose | play a raw key code |
| Input parameters | `channel, kc, kf` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_YM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // play a raw key code
    xm_ym_note(0, $4c, 0)
    rts

#import "x16_code.asm"
```

## `xm_ym_note_bas(channel, note)`

| Field | Details |
|---|---|
| Macro | `xm_ym_note_bas(channel, note)` |
| Purpose | play a packed note (0 releases) |
| Input parameters | `channel, note` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_YM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // play a packed note (0 releases)
    xm_ym_note_bas(0, 60)
    rts

#import "x16_code.asm"
```

## `xm_ym_release_note(channel)`

| Field | Details |
|---|---|
| Macro | `xm_ym_release_note(channel)` |
| Purpose | release |
| Input parameters | `channel` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_YM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // release
    xm_ym_release_note(0)
    rts

#import "x16_code.asm"
```

## `xm_ym_vol channel, atten / xm_ym_pan channel, pan`

| Field | Details |
|---|---|
| Macro | `xm_ym_vol(channel, atten)` / `xm_ym_pan(channel, pan)` |
| Purpose | volume / pan |
| Input parameters | `channel, atten`; `channel, pan` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_YM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // volume / pan
    xm_ym_vol(0, 1)
    xm_ym_pan(0, $c0)
    rts

#import "x16_code.asm"
```

## `xm_ym_drum(channel, note)`

| Field | Details |
|---|---|
| Macro | `xm_ym_drum(channel, note)` |
| Purpose | a drum voice |
| Input parameters | `channel, note` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_YM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_YM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // a drum voice
    xm_ym_drum(0, 60)
    rts

#import "x16_code.asm"
```
