# VERA SPI Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_VERA_SPI` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_spi_get_ctrl / xm_spi_set_ctrl ctrl`

| Field | Details |
|---|---|
| Macro | `xm_spi_get_ctrl` / `xm_spi_set_ctrl ctrl` |
| Purpose | read/write SPI control |
| Input parameters | `ctrl` |
| Output parameters | read/write SPI control |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"

main
    xm_spi_get_ctrl
    rts
```

## `xm_spi_select / xm_spi_deselect`

| Field | Details |
|---|---|
| Macro | `xm_spi_select` / `xm_spi_deselect` |
| Purpose | chip select helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"

main
    xm_spi_select
    rts
```

## `xm_spi_slow / xm_spi_fast`

| Field | Details |
|---|---|
| Macro | `xm_spi_slow` / `xm_spi_fast` |
| Purpose | clock speed helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"

main
    xm_spi_slow
    rts
```

## `xm_spi_autotx_on / xm_spi_autotx_off`

| Field | Details |
|---|---|
| Macro | `xm_spi_autotx_on` / `xm_spi_autotx_off` |
| Purpose | auto-transmit controls |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"

main
    xm_spi_autotx_on
    rts
```

## `xm_spi_wait`

| Field | Details |
|---|---|
| Macro | `xm_spi_wait` |
| Purpose | wait for SPI ready |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"

main
    xm_spi_wait
    rts
```

## `xm_spi_transfer byte`

| Field | Details |
|---|---|
| Macro | `xm_spi_transfer byte` |
| Purpose | transfer one byte |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"

main
    xm_spi_transfer byte
    rts
```

## `xm_spi_read / xm_spi_write byte / xm_spi_autotx_read`

| Field | Details |
|---|---|
| Macro | `xm_spi_read` / `xm_spi_write byte` / `xm_spi_autotx_read` |
| Purpose | byte I/O helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"

main
    xm_spi_read
    rts
```

## `xm_spi_read_bytes buffer, count / xm_spi_write_bytes buffer, count`

| Field | Details |
|---|---|
| Macro | `xm_spi_read_bytes buffer, count` / `xm_spi_write_bytes buffer, count` |
| Purpose | block I/O helpers |
| Input parameters | `buffer, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_VERA_SPI` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_VERA_SPI = 1
    icl "x16.asm"

main
    xm_spi_read_bytes buffer, count
    rts
```
