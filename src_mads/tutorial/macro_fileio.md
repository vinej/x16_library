# File I/O Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_FILEIO` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_FILEIO = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_fio_set_lfs logical, device, secondary / xm_fio_set_name name, len`

| Field | Details |
|---|---|
| Macro | `xm_fio_set_lfs logical, device, secondary` / `xm_fio_set_name name, len` |
| Purpose | KERNAL file setup |
| Input parameters | `logical, device, secondary`; `name, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FILEIO = 1
    icl "x16.asm"

main
    xm_fio_set_lfs logical, device, secondary
    rts
```

## `xm_fio_open_named/open_read/open_write name, len, logical, device, secondary`

| Field | Details |
|---|---|
| Macro | `xm_fio_open_named/open_read/open_write name, len, logical, device, secondary` |
| Purpose | open helpers |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FILEIO = 1
    icl "x16.asm"

main
    xm_fio_open_named
    rts
```

## `xm_fio_close logical / xm_fio_close_named logical`

| Field | Details |
|---|---|
| Macro | `xm_fio_close logical` / `xm_fio_close_named logical` |
| Purpose | close helpers |
| Input parameters | `logical` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FILEIO = 1
    icl "x16.asm"

main
    xm_fio_close logical
    rts
```

## `xm_fio_chkin logical / xm_fio_chkout logical / xm_fio_clrchn`

| Field | Details |
|---|---|
| Macro | `xm_fio_chkin logical` / `xm_fio_chkout logical` / `xm_fio_clrchn` |
| Purpose | channel helpers |
| Input parameters | `logical` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FILEIO = 1
    icl "x16.asm"

main
    xm_fio_chkin logical
    rts
```

## `xm_fio_chrin / xm_fio_chrout byte / xm_fio_getin`

| Field | Details |
|---|---|
| Macro | `xm_fio_chrin` / `xm_fio_chrout byte` / `xm_fio_getin` |
| Purpose | byte I/O helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FILEIO = 1
    icl "x16.asm"

main
    xm_fio_chrin
    rts
```

## `xm_fio_readst`

| Field | Details |
|---|---|
| Macro | `xm_fio_readst` |
| Purpose | read KERNAL status |
| Input parameters | No macro arguments. |
| Output parameters | read KERNAL status |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FILEIO = 1
    icl "x16.asm"

main
    xm_fio_readst
    rts
```

## `xm_fio_close_all / xm_fio_close_device device`

| Field | Details |
|---|---|
| Macro | `xm_fio_close_all` / `xm_fio_close_device device` |
| Purpose | bulk close helpers |
| Input parameters | `device` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_FILEIO` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_FILEIO = 1
    icl "x16.asm"

main
    xm_fio_close_all
    rts
```
