# ADPCM Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_ADPCM` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_ADPCM = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_adpcm_init`

| Field | Details |
|---|---|
| Macro | `xm_adpcm_init` |
| Purpose | initialize ADPCM state |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ADPCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_ADPCM = 1
    icl "x16.asm"

main
    xm_adpcm_init
    rts
```

## `xm_adpcm_nibble code`

| Field | Details |
|---|---|
| Macro | `xm_adpcm_nibble code` |
| Purpose | decode one ADPCM nibble |
| Input parameters | `code` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ADPCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_ADPCM = 1
    icl "x16.asm"

main
    xm_adpcm_nibble code
    rts
```

## `xm_adpcm_block src, dst, count`

| Field | Details |
|---|---|
| Macro | `xm_adpcm_block src, dst, count` |
| Purpose | decode a block |
| Input parameters | `src, dst, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_ADPCM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_ADPCM = 1
    icl "x16.asm"

main
    xm_adpcm_block src, dst, count
    rts
```
