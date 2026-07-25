# BMX Macros

> Generated dasm edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BMX` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_BMX = 1
include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_bmx_load name, len, device, vbank, vaddr`

| Field | Details |
|---|---|
| Macro | `xm_bmx_load name, len, device, vbank, vaddr` |
| Purpose | load BMX image to VRAM |
| Input parameters | `name, len, device, vbank, vaddr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BMX` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_BMX = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; load BMX image to VRAM
    xm_bmx_load file_name, 16, 8, 1, $10000
    rts

file_name dc.b "SAVEGAME,S,R", 0

include "x16_code.asm"
```

## `xm_bmx_load_hires name, len, device`

| Field | Details |
|---|---|
| Macro | `xm_bmx_load_hires name, len, device` |
| Purpose | load a BMX image into the VERA_2 640x480 8bpp SDRAM bitmap (the `gfx8h` engine) |
| Input parameters | `name`: filename address; `len`: filename length; `device`: device number (usually 8) |
| Output parameters | Carry clear on success; carry set with `A` = `BMX_ERR_*` on failure. `bmx_width`/`bmx_height`/`bmx_bpp`/`bmx_palstart`/`bmx_palcount`/`bmx_border` reflect the file. |
| More info | Like `bmx_load`, but the palette streams into the VERA_2 palette and the pixels stream (via MACPTR) into VERA_2 SDRAM starting at offset 0, rather than into VERA VRAM. Select the hi-res 8bpp mode first with `gfx8h_init`. Rows land 640 bytes apart, so a full-width 640x480 image is a plain contiguous load. |
| Example | See below. |

```asm
processor 65c02
include "x16.asm"

X16_USE_BMX = 1
include "core/sugar.asm"

    org $0801
    basic_stub

main
  ; load a BMX image into the VERA_2 640x480 8bpp SDRAM bitmap (the `gfx8h` engine)
    xm_bmx_load_hires file_name, 16, 8
    rts

file_name dc.b "SAVEGAME,S,R", 0

include "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of bmx

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `xm_bmx_save name, len, device, vbank, vaddr`

| Field | Details |
|---|---|
| Macro | `xm_bmx_save name, len, device, vbank, vaddr` |
| Purpose | write a BMX file from VRAM |
| Input parameters | `name`, `len`, `device`, `vbank`, `vaddr` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_BMX` is enabled. |
