# ROM audio Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_AUDIO_ROM` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `Scope`

| Field | Details |
|---|---|
| Macro | Scope |
| Purpose | thin ROM `BANK_AUDIO` wrappers; separate from local PSG/YM modules |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"

main
  ; see macro listing above
    rts
```

## `#xm_ar_audio_init, #xm_ar_playstring_voice voice`

| Field | Details |
|---|---|
| Macro | `#xm_ar_audio_init`, `#xm_ar_playstring_voice voice` |
| Purpose | general ROM audio helpers |
| Input parameters | `voice` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"

main
    #xm_ar_audio_init
    rts
```

## `#xm_ar_fmplaystring str, len, #xm_ar_fmchordstring str, len, #xm_ar_psgplaystring str, len, #xm_ar_psgchordstring str, len`

| Field | Details |
|---|---|
| Macro | `#xm_ar_fmplaystring str, len`, `#xm_ar_fmchordstring str, len`, `#xm_ar_psgplaystring str, len`, `#xm_ar_psgchordstring str, len` |
| Purpose | play strings/chords |
| Input parameters | `str, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"

main
    #xm_ar_fmplaystring str, len
    rts
```

## `#xm_ar_fmfreq channel, hz, #xm_ar_fmfreq_no_retrigger channel, hz, #xm_ar_fmnote channel, note, kf, #xm_ar_fmnote_no_retrigger channel, note, kf, #xm_ar_fmvib speed, depth`

| Field | Details |
|---|---|
| Macro | `#xm_ar_fmfreq channel, hz`, `#xm_ar_fmfreq_no_retrigger channel, hz`, `#xm_ar_fmnote channel, note, kf`, `#xm_ar_fmnote_no_retrigger channel, note, kf`, `#xm_ar_fmvib speed, depth` |
| Purpose | FM helpers |
| Input parameters | `channel, hz`; `channel, note, kf`; `speed, depth` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"

main
    #xm_ar_fmfreq channel, hz
    rts
```

## `#xm_ar_psgfreq voice, hz, #xm_ar_psgnote voice, note, kf, #xm_ar_psgwav voice, wave`

| Field | Details |
|---|---|
| Macro | `#xm_ar_psgfreq voice, hz`, `#xm_ar_psgnote voice, note, kf`, `#xm_ar_psgwav voice, wave` |
| Purpose | PSG helpers |
| Input parameters | `voice, hz`; `voice, note, kf`; `voice, wave` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"

main
    #xm_ar_psgfreq voice, hz
    rts
```

## `#xm_ar_note_bas2fm, bas2midi, bas2psg, fm2bas, fm2midi, fm2psg, freq2bas/fm/midi/psg, midi2bas/fm/psg, psg2bas/fm/midi`

| Field | Details |
|---|---|
| Macro | `#xm_ar_note_bas2fm`, `bas2midi`, `bas2psg`, `fm2bas`, `fm2midi`, `fm2psg`, `freq2bas/fm/midi/psg`, `midi2bas/fm/psg`, `psg2bas/fm/midi` |
| Purpose | note conversion |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"

main
    #xm_ar_note_bas2fm
    rts
```

## `#xm_ar_psg_init, #xm_ar_psg_playfreq, #xm_ar_psg_read_raw/cooked, #xm_ar_psg_setatten/freq/pan/vol, #xm_ar_psg_write, #xm_ar_psg_write_fast, #xm_ar_psg_getatten/pan`

| Field | Details |
|---|---|
| Macro | `#xm_ar_psg_init`, `#xm_ar_psg_playfreq`, `#xm_ar_psg_read_raw/cooked`, `#xm_ar_psg_setatten/freq/pan/vol`, `#xm_ar_psg_write`, `#xm_ar_psg_write_fast`, `#xm_ar_psg_getatten/pan` |
| Purpose | ROM PSG shadows |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"

main
    #xm_ar_psg_init
    rts
```

## `#xm_ar_ym_init, #xm_ar_ym_loaddefpatches, #xm_ar_ym_loadpatch_rom, #xm_ar_ym_loadpatchlfn, #xm_ar_ym_playdrum/playnote, #xm_ar_ym_setatten/drum/note/pan, #xm_ar_ym_read_raw/cooked, #xm_ar_ym_release, #xm_ar_ym_trigger, #xm_ar_ym_trigger_no_retrigger, #xm_ar_ym_write, #xm_ar_ym_getatten/pan, #xm_ar_ym_get_chip_type`

| Field | Details |
|---|---|
| Macro | `#xm_ar_ym_init`, `#xm_ar_ym_loaddefpatches`, `#xm_ar_ym_loadpatch_rom`, `#xm_ar_ym_loadpatchlfn`, `#xm_ar_ym_playdrum/playnote`, `#xm_ar_ym_setatten/drum/note/pan`, `#xm_ar_ym_read_raw/cooked`, `#xm_ar_ym_release`, `#xm_ar_ym_trigger`, `#xm_ar_ym_trigger_no_retrigger`, `#xm_ar_ym_write`, `#xm_ar_ym_getatten/pan`, `#xm_ar_ym_get_chip_type` |
| Purpose | ROM YM shadows |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_AUDIO_ROM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_AUDIO_ROM = 1
.include "x16.asm"

main
    #xm_ar_ym_init
    rts
```
