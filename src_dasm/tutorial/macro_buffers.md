# Buffers Macros

> Generated dasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BUFFERS` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_BUFFERS = 1
include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_rb_init / xm_rb_count`

| Field | Details |
|---|---|
| Macro | `xm_rb_init` / `xm_rb_count` |
| Purpose | ring buffer init / count |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_BUFFERS = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; ring buffer init / count
    xm_rb_init
    xm_rb_count
    rts

include "x16_code.asm"
```

## `xm_rb_put byte`

| Field | Details |
|---|---|
| Macro | `xm_rb_put byte` |
| Purpose | ring buffer put; -> carry set = full |
| Input parameters | `byte` |
| Output parameters | carry set = full |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_BUFFERS = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; ring buffer put; -> carry set = full
    xm_rb_put 'A'
    rts

include "x16_code.asm"
```

## `xm_rb_get`

| Field | Details |
|---|---|
| Macro | `xm_rb_get` |
| Purpose | ring buffer get; -> A = byte, carry set = empty |
| Input parameters | No macro arguments. |
| Output parameters | A = byte, carry set = empty |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_BUFFERS = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; ring buffer get; -> A = byte, carry set = empty
    xm_rb_get
    rts

include "x16_code.asm"
```

## `xm_stk_init / xm_stk_push byte / xm_stk_pop / xm_stk_depth`

| Field | Details |
|---|---|
| Macro | `xm_stk_init` / `xm_stk_push byte` / `xm_stk_pop` / `xm_stk_depth` |
| Purpose | byte stack helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_BUFFERS = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; byte stack helpers
    xm_stk_init
    xm_stk_push 'A'
    xm_stk_pop
    xm_stk_depth
    rts

include "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## The 8 KB banked stack and ring buffer

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `xm_stack_pop`

| Field | Details |
|---|---|
| Macro | `xm_stack_pop` |
| Purpose | pop one byte |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_stack_popw`

| Field | Details |
|---|---|
| Macro | `xm_stack_popw` |
| Purpose | pop one word |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_stack_size`

| Field | Details |
|---|---|
| Macro | `xm_stack_size` |
| Purpose | bytes stored = STACK_TOP - sp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_stack_free`

| Field | Details |
|---|---|
| Macro | `xm_stack_free` |
| Purpose | bytes free = sp |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_stack_isempty`

| Field | Details |
|---|---|
| Macro | `xm_stack_isempty` |
| Purpose | sp == STACK_TOP |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_stack_isfull`

| Field | Details |
|---|---|
| Macro | `xm_stack_isfull` |
| Purpose | carry set if less than 2 bytes remain |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_ring_get`

| Field | Details |
|---|---|
| Macro | `xm_ring_get` |
| Purpose | dequeue one byte |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `xm_ring_getw`

| Field | Details |
|---|---|
| Macro | `xm_ring_getw` |
| Purpose | dequeue one word |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `xm_ring_size`

| Field | Details |
|---|---|
| Macro | `xm_ring_size` |
| Purpose | bytes queued = fill |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `xm_ring_free`

| Field | Details |
|---|---|
| Macro | `xm_ring_free` |
| Purpose | usable bytes free |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A` = low, `X` = high. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `xm_ring_isempty`

| Field | Details |
|---|---|
| Macro | `xm_ring_isempty` |
| Purpose | fill == 0 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `xm_ring_isfull`

| Field | Details |
|---|---|
| Macro | `xm_ring_isfull` |
| Purpose | fill >= 8191 |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `xm_stack_init bank`

| Field | Details |
|---|---|
| Macro | `xm_stack_init bank` |
| Purpose | claim a bank and empty the stack |
| Input parameters | `bank` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_ring_init bank`

| Field | Details |
|---|---|
| Macro | `xm_ring_init bank` |
| Purpose | claim a bank and empty the queue |
| Input parameters | `bank` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `xm_stack_push byte`

| Field | Details |
|---|---|
| Macro | `xm_stack_push byte` |
| Purpose | push one byte |
| Input parameters | `byte` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_ring_put byte`

| Field | Details |
|---|---|
| Macro | `xm_ring_put byte` |
| Purpose | enqueue one byte |
| Input parameters | `byte` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |

## `xm_stack_pushw value`

| Field | Details |
|---|---|
| Macro | `xm_stack_pushw value` |
| Purpose | push one word (low byte first, then high) |
| Input parameters | `value` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STACK` is enabled. |

## `xm_ring_putw value`

| Field | Details |
|---|---|
| Macro | `xm_ring_putw value` |
| Purpose | enqueue one word (low byte first) |
| Input parameters | `value` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_RINGBUFFER` is enabled. |
