# Interrupts Macros

> Generated ca65 edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_IRQ` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_IRQ = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_irq_install / xm_irq_remove`

| Field | Details |
|---|---|
| Macro | `xm_irq_install` / `xm_irq_remove` |
| Purpose | hook / unhook the frame counter |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IRQ = 1
.include "x16.asm"

main
    xm_irq_install
    rts
```

## `xm_vsync_wait`

| Field | Details |
|---|---|
| Macro | `xm_vsync_wait` |
| Purpose | block until the next frame boundary |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IRQ = 1
.include "x16.asm"

main
    xm_vsync_wait
    rts
```

## `xm_irq_line_install handler`

| Field | Details |
|---|---|
| Macro | `xm_irq_line_install handler` |
| Purpose | call a handler at a scanline |
| Input parameters | `handler` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IRQ = 1
.include "x16.asm"

main
    xm_irq_line_install handler
    rts
```

## `xm_irq_sprcol_install handler (handler = 0 polls) / xm_irq_sprcol_remove`

| Field | Details |
|---|---|
| Macro | `xm_irq_sprcol_install handler` (`handler` = 0 polls) / `xm_irq_sprcol_remove` |
| Purpose | sprite-collision interrupt |
| Input parameters | `handler` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IRQ` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IRQ = 1
.include "x16.asm"

main
    xm_irq_sprcol_install handler
    rts
```
