# PSG Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_PSG` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_PSG = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_psg_init`

| Field | Details |
|---|---|
| Macro | `xm_psg_init` |
| Purpose | silence all 16 voices |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PSG = 1
    include "x16.asm"

main
    xm_psg_init
    rts
```

## `xm_psg_set_freq voice, freq`

| Field | Details |
|---|---|
| Macro | `xm_psg_set_freq voice, freq` |
| Purpose | frequency word |
| Input parameters | `voice, freq` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PSG = 1
    include "x16.asm"

main
    xm_psg_set_freq voice, freq
    rts
```

## `xm_psg_set_vol voice, vol, pan`

| Field | Details |
|---|---|
| Macro | `xm_psg_set_vol voice, vol, pan` |
| Purpose | volume (0-63) + pan |
| Input parameters | `voice, vol, pan` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PSG = 1
    include "x16.asm"

main
    xm_psg_set_vol voice, vol, pan
    rts
```

## `xm_psg_set_wave voice, wave, width`

| Field | Details |
|---|---|
| Macro | `xm_psg_set_wave voice, wave, width` |
| Purpose | waveform + pulse width |
| Input parameters | `voice, wave, width` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PSG = 1
    include "x16.asm"

main
    xm_psg_set_wave voice, wave, width
    rts
```

## `xm_psg_note_off voice`

| Field | Details |
|---|---|
| Macro | `xm_psg_note_off voice` |
| Purpose | volume to zero, keep the rest |
| Input parameters | `voice` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PSG = 1
    include "x16.asm"

main
    xm_psg_note_off voice
    rts
```

## `xm_psg_env_start / _release / _stop voice`

| Field | Details |
|---|---|
| Macro | `xm_psg_env_start / _release / _stop voice` |
| Purpose | ASR envelope control |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PSG = 1
    include "x16.asm"

main
    xm_psg_env_start
    rts
```

## `xm_psg_env_tick`

| Field | Details |
|---|---|
| Macro | `xm_psg_env_tick` |
| Purpose | advance every armed envelope (once a frame) |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_PSG` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_PSG = 1
    include "x16.asm"

main
    xm_psg_env_tick
    rts
```
