# PCM Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_PCM, X16_USE_PCM_STREAM` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_PCM
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_pcm_ctrl byte / xm_pcm_rate rate / xm_pcm_reset`

| Field | Details |
|---|---|
| Macro | `xm_pcm_ctrl(byte)` / `xm_pcm_rate(rate)` / `xm_pcm_reset()` |
| Purpose | `PCM` gate |
| Input parameters | `byte`; `rate` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_PCM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // `PCM` gate
    xm_pcm_ctrl('A')
    xm_pcm_rate(1)
    xm_pcm_reset()
    rts

#import "x16_code.asm"
```

## `xm_pcm_put sample / xm_pcm_write src, count`

| Field | Details |
|---|---|
| Macro | `xm_pcm_put(sample)` / `xm_pcm_write(src, count)` |
| Purpose | `PCM` gate |
| Input parameters | `sample`; `src, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_PCM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // `PCM` gate
    xm_pcm_put(1)
    xm_pcm_write(sample_data, 32)
    rts

sample_data .byte $80, $88, $90, $88, $80, $78, $70, $78

#import "x16_code.asm"
```

## `xm_pcm_stream_start src, count, loop / xm_pcm_stream_stop`

| Field | Details |
|---|---|
| Macro | `xm_pcm_stream_start(src, count, loop)` / `xm_pcm_stream_stop()` |
| Purpose | `PCM_STREAM` gate |
| Input parameters | `src, count, loop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PCM, X16_USE_PCM_STREAM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_PCM_STREAM
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // `PCM_STREAM` gate
    xm_pcm_stream_start(sample_data, 32, 1)
    xm_pcm_stream_stop()
    rts

sample_data .byte $80, $88, $90, $88, $80, $78, $70, $78

#import "x16_code.asm"
```
