# BMX Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BMX` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_BMX
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_bmx_load(name, len, device, vbank, vaddr)`

| Field | Details |
|---|---|
| Macro | `xm_bmx_load(name, len, device, vbank, vaddr)` |
| Purpose | load BMX image to VRAM |
| Input parameters | `name, len, device, vbank, vaddr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BMX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_BMX
#import "x16.asm"

main
    xm_bmx_load(name, len, device, vbank, vaddr)
    rts
```
