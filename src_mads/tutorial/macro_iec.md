# IEC Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_IEC` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_IEC = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_iec_listen device / xm_iec_talk device`

| Field | Details |
|---|---|
| Macro | `xm_iec_listen device` / `xm_iec_talk device` |
| Purpose | bus attention helpers |
| Input parameters | `device` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IEC = 1
    icl "x16.asm"

main
    xm_iec_listen device
    rts
```

## `xm_iec_second command / xm_iec_tksa command`

| Field | Details |
|---|---|
| Macro | `xm_iec_second command` / `xm_iec_tksa command` |
| Purpose | secondary address helpers |
| Input parameters | `command` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IEC = 1
    icl "x16.asm"

main
    xm_iec_second command
    rts
```

## `xm_iec_ciout byte / xm_iec_acptr`

| Field | Details |
|---|---|
| Macro | `xm_iec_ciout byte` / `xm_iec_acptr` |
| Purpose | byte I/O helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IEC = 1
    icl "x16.asm"

main
    xm_iec_ciout byte
    rts
```

## `xm_iec_unlisten / xm_iec_untalk`

| Field | Details |
|---|---|
| Macro | `xm_iec_unlisten` / `xm_iec_untalk` |
| Purpose | release bus helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IEC = 1
    icl "x16.asm"

main
    xm_iec_unlisten
    rts
```

## `xm_iec_set_timeout control / xm_iec_readst`

| Field | Details |
|---|---|
| Macro | `xm_iec_set_timeout control` / `xm_iec_readst` |
| Purpose | timeout/status helpers |
| Input parameters | `control` |
| Output parameters | timeout/status helpers |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IEC = 1
    icl "x16.asm"

main
    xm_iec_set_timeout control
    rts
```

## `xm_iec_macptr dest, count / xm_iec_mciout src, count`

| Field | Details |
|---|---|
| Macro | `xm_iec_macptr dest, count` / `xm_iec_mciout src, count` |
| Purpose | block I/O helpers |
| Input parameters | `dest, count`; `src, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IEC = 1
    icl "x16.asm"

main
    xm_iec_macptr dest, count
    rts
```

## `xm_iec_open_channel device, secondary / xm_iec_data_channel device, secondary / xm_iec_talk_channel device, secondary / xm_iec_close_channel device, secondary`

| Field | Details |
|---|---|
| Macro | `xm_iec_open_channel device, secondary` / `xm_iec_data_channel device, secondary` / `xm_iec_talk_channel device, secondary` / `xm_iec_close_channel device, secondary` |
| Purpose | channel helpers |
| Input parameters | `device, secondary` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_IEC` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_IEC = 1
    icl "x16.asm"

main
    xm_iec_open_channel device, secondary
    rts
```
