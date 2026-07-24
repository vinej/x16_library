# ZSM Macros

Detailed reference for the `X16_USE_ZSM, X16_USE_ZSM_PCM` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_ZSM = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `+xm_zsm_init header / +xm_zsm_init_stream stream, loop`

| Field | Details |
|---|---|
| Macro | `+xm_zsm_init header` / `+xm_zsm_init_stream stream, loop` |
| Purpose | `ZSM` gate |
| Input parameters | `header`; `stream, loop` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ZSM, X16_USE_ZSM_PCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_ZSM = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `ZSM` gate
    +xm_zsm_init zsm_header
    +xm_zsm_init_stream zsm_stream, 1
    rts

zsm_header  !word zsm_stream
zsm_stream  !byte 0

!source "x16_code.asm"
```

## `+xm_zsm_play / +xm_zsm_stop / +xm_zsm_rewind`

| Field | Details |
|---|---|
| Macro | `+xm_zsm_play` / `+xm_zsm_stop` / `+xm_zsm_rewind` |
| Purpose | `ZSM` gate |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ZSM, X16_USE_ZSM_PCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_ZSM = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `ZSM` gate
    +xm_zsm_play
    +xm_zsm_stop
    +xm_zsm_rewind
    rts

!source "x16_code.asm"
```

## `+xm_zsm_get_tickrate / +xm_zsm_status / +xm_zsm_tick`

| Field | Details |
|---|---|
| Macro | `+xm_zsm_get_tickrate` / `+xm_zsm_status` / `+xm_zsm_tick` |
| Purpose | `ZSM` gate |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ZSM, X16_USE_ZSM_PCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_ZSM = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `ZSM` gate
    +xm_zsm_get_tickrate
    +xm_zsm_status
    +xm_zsm_tick
    rts

!source "x16_code.asm"
```

## `+xm_zsm_pcm_present / +xm_zsm_pcm_trigger instrument`

| Field | Details |
|---|---|
| Macro | `+xm_zsm_pcm_present` / `+xm_zsm_pcm_trigger instrument` |
| Purpose | `ZSM_PCM` gate |
| Input parameters | `instrument` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ZSM, X16_USE_ZSM_PCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_ZSM = 1
X16_USE_ZSM_PCM = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; `ZSM_PCM` gate
    +xm_zsm_pcm_present
    +xm_zsm_pcm_trigger 0
    rts

!source "x16_code.asm"
```

