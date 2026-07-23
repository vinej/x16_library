# PCM Macros

> Generated ca65 edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_PCM, X16_USE_PCM_STREAM` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_PCM = 1
.include "x16.asm"
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
X16_USE_PCM = 1
.include "x16.asm"

main
    xm_pcm_ctrl byte
    rts
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
X16_USE_PCM = 1
.include "x16.asm"

main
    xm_pcm_put sample
    rts
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
X16_USE_PCM = 1
.include "x16.asm"

main
    xm_pcm_stream_start src, count, loop
    rts
```
