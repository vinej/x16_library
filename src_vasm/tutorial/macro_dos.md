# DOS Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_DOS` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_DOS = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_dos_cmd cmd, len`

| Field | Details |
|---|---|
| Macro | `xm_dos_cmd cmd, len` |
| Purpose | execute command; -> A = status |
| Input parameters | `cmd, len` |
| Output parameters | A = status |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_DOS = 1
    include "x16.asm"

main
    xm_dos_cmd cmd, len
    rts
```

## `xm_dos_status`

| Field | Details |
|---|---|
| Macro | `xm_dos_status` |
| Purpose | read DOS status |
| Input parameters | No macro arguments. |
| Output parameters | read DOS status |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_DOS = 1
    include "x16.asm"

main
    xm_dos_status
    rts
```

## `xm_dos_delete name, len`

| Field | Details |
|---|---|
| Macro | `xm_dos_delete name, len` |
| Purpose | delete file |
| Input parameters | `name, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_DOS = 1
    include "x16.asm"

main
    xm_dos_delete name, len
    rts
```
