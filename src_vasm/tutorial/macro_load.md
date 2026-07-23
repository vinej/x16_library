# Load/save Macros

> Generated vasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_LOAD` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_LOAD = 1
    include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_fs_setname name, len`

| Field | Details |
|---|---|
| Macro | `xm_fs_setname name, len` |
| Purpose | set KERNAL filename |
| Input parameters | `name, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_LOAD = 1
    include "x16.asm"

main
    xm_fs_setname name, len
    rts
```

## `xm_fs_load name, len, device, sa, dst`

| Field | Details |
|---|---|
| Macro | `xm_fs_load name, len, device, sa, dst` |
| Purpose | load to RAM; -> carry set = error, A = code |
| Input parameters | `name, len, device, sa, dst` |
| Output parameters | carry set = error, A = code |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_LOAD = 1
    include "x16.asm"

main
    xm_fs_load name, len, device, sa, dst
    rts
```

## `xm_fs_vload name, len, device, vbank, vaddr`

| Field | Details |
|---|---|
| Macro | `xm_fs_vload name, len, device, vbank, vaddr` |
| Purpose | load to VRAM |
| Input parameters | `name, len, device, vbank, vaddr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_LOAD = 1
    include "x16.asm"

main
    xm_fs_vload name, len, device, vbank, vaddr
    rts
```
