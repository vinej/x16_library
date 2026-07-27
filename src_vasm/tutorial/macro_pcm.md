# PCM Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_PCM, X16_USE_PCM_STREAM` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_PCM = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_pcm_ctrl byte / xm_pcm_rate rate / xm_pcm_reset`

| Field | Details |
|---|---|
| Macro | `xm_pcm_ctrl byte` / `xm_pcm_rate rate` / `xm_pcm_reset` |
| Purpose | `PCM` gate |
| Input parameters | `byte`; `rate` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_PCM = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; `PCM` gate
    xm_pcm_ctrl 'A'
    xm_pcm_rate 1
    xm_pcm_reset
    rts

    include "x16_code.asm"
```

## `xm_pcm_put sample / xm_pcm_write src, count`

| Field | Details |
|---|---|
| Macro | `xm_pcm_put sample` / `xm_pcm_write src, count` |
| Purpose | `PCM` gate |
| Input parameters | `sample`; `src, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_PCM = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; `PCM` gate
    xm_pcm_put 1
    xm_pcm_write sample_data, 32
    rts

sample_data byte $80, $88, $90, $88, $80, $78, $70, $78

    include "x16_code.asm"
```

## `xm_pcm_stream_start src, count, loop / xm_pcm_stream_stop`

| Field | Details |
|---|---|
| Macro | `xm_pcm_stream_start src, count, loop` / `xm_pcm_stream_stop` |
| Purpose | `PCM_STREAM` gate |
| Input parameters | `src, count, loop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
; vasm: pass -c02 on the command line
    include "x16.asm"

X16_USE_PCM_STREAM = 1
    include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; `PCM_STREAM` gate
    xm_pcm_stream_start sample_data, 32, 1
    xm_pcm_stream_stop
    rts

sample_data byte $80, $88, $90, $88, $80, $78, $70, $78

    include "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of pcm

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `xm_pcm_full`

| Field | Details |
|---|---|
| Macro | `xm_pcm_full` |
| Purpose | carry set if the FIFO cannot take another byte |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_PCM` is enabled. |

## `xm_pcm_empty`

| Field | Details |
|---|---|
| Macro | `xm_pcm_empty` |
| Purpose | carry set if the FIFO has run dry |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_PCM` is enabled. |

## `xm_pcm_stream_active`

| Field | Details |
|---|---|
| Macro | `xm_pcm_stream_active` |
| Purpose | A = 1 while data remains, 0 when the whole |
| Input parameters | None — operates on the module's own state. |
| Output parameters | Returns `A`. |
| More info | Available when `X16_USE_PCM_STREAM` is enabled. |

## `xm_pcm_stream_start_bank offset, count, counthi, bank, rate`

| Field | Details |
|---|---|
| Macro | `xm_pcm_stream_start_bank offset, count, counthi, bank, rate` |
| Purpose | play a sample living in banked RAM |
| Input parameters | `offset`, `count`, `counthi`, `bank`, `rate` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_PCM_STREAM` is enabled. |

## Reference: routines not covered above

Taken from each routine's own header in the source, so this
stays true as the module changes.

| Routine | Purpose | In | Out |
|---|---|---|---|
| `pcm_stream_isr` | the AFLOW service, called from irq_handler. | -- | -- |
| `pcm_stream_fill` | -- | -- | -- |
