# Interrupts Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_IRQ` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_IRQ
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_irq_install / xm_irq_remove`

| Field | Details |
|---|---|
| Macro | `xm_irq_install()` / `xm_irq_remove()` |
| Purpose | hook / unhook the frame counter |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_IRQ
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // hook / unhook the frame counter
    xm_irq_install()
    xm_irq_remove()
    rts

#import "x16_code.asm"
```

## `xm_vsync_wait()`

| Field | Details |
|---|---|
| Macro | `xm_vsync_wait()` |
| Purpose | block until the next frame boundary |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_IRQ
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // block until the next frame boundary
    xm_vsync_wait()
    rts

#import "x16_code.asm"
```

## `xm_irq_line_install(handler)`

| Field | Details |
|---|---|
| Macro | `xm_irq_line_install(handler)` |
| Purpose | call a handler at a scanline |
| Input parameters | `handler` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_IRQ
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // call a handler at a scanline
    xm_irq_line_install(1)
    rts

#import "x16_code.asm"
```

## `xm_irq_sprcol_install handler (handler = 0 polls) / xm_irq_sprcol_remove`

| Field | Details |
|---|---|
| Macro | `xm_irq_sprcol_install(handler)` (`handler` = 0 polls) / `xm_irq_sprcol_remove()` |
| Purpose | sprite-collision interrupt |
| Input parameters | `handler` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_IRQ
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // sprite-collision interrupt
    xm_irq_sprcol_install(1)
    xm_irq_sprcol_remove()
    rts

#import "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of irq

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `xm_irq_line_remove()`

| Field | Details |
|---|---|
| Macro | `xm_irq_line_remove()` |
| Purpose | stop the raster-line interrupt and acknowledge any pending one |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_IRQ_ANY` is enabled. |

## `xm_irq_save_regs()`

| Field | Details |
|---|---|
| Macro | `xm_irq_save_regs()` |
| Purpose | bracket a callback that calls |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_IRQ_ANY` is enabled. |

## `xm_irq_restore_regs()`

| Field | Details |
|---|---|
| Macro | `xm_irq_restore_regs()` |
| Purpose | bracket a callback that calls |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_IRQ_ANY` is enabled. |

## `xm_irq_frames()`

| Field | Details |
|---|---|
| Macro | `xm_irq_frames()` |
| Purpose | Byte subtraction wraps correctly, so deltas are valid across the wrap: |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_IRQ_ANY` is enabled. |

## `xm_sprite_collisions()`

| Field | Details |
|---|---|
| Macro | `xm_sprite_collisions()` |
| Purpose | read and clear the accumulated collision groups |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_IRQ_SPRCOL_API` is enabled. |

## Reference: routines not covered above

Taken from each routine's own header in the source, so this
stays true as the module changes.

| Routine | Purpose | In | Out |
|---|---|---|---|
| `irq_handler` | services VSYNC / LINE / SPRCOL, then chains | -- | -- |
