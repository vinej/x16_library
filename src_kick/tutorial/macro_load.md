# Load/save Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_LOAD` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_LOAD
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_fs_setname(name, len)`

| Field | Details |
|---|---|
| Macro | `xm_fs_setname(name, len)` |
| Purpose | set KERNAL filename |
| Input parameters | `name, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_LOAD
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // set KERNAL filename
    xm_fs_setname(file_name, 16)
    rts

file_name .text "SAVEGAME,S,R", 0

#import "x16_code.asm"
```

## `xm_fs_load(name, len, device, sa, dst)`

| Field | Details |
|---|---|
| Macro | `xm_fs_load(name, len, device, sa, dst)` |
| Purpose | load to RAM; -> carry set = error, A = code |
| Input parameters | `name, len, device, sa, dst` |
| Output parameters | carry set = error, A = code |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_LOAD
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // load to RAM; -> carry set = error, A = code
    xm_fs_load(file_name, 16, 8, 1, work_buffer)
    rts

file_name .text "SAVEGAME,S,R", 0
work_buffer .fill 64, 0

#import "x16_code.asm"
```

## `xm_fs_vload(name, len, device, vbank, vaddr)`

| Field | Details |
|---|---|
| Macro | `xm_fs_vload(name, len, device, vbank, vaddr)` |
| Purpose | load to VRAM |
| Input parameters | `name, len, device, vbank, vaddr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_LOAD` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu _65c02
#import "x16.asm"

#define X16_USE_LOAD
#import "core/sugar.asm"

.pc = $0801 "code"
    basic_stub()

main
 // load to VRAM
    xm_fs_vload(file_name, 16, 8, 1, $10000)
    rts

file_name .text "SAVEGAME,S,R", 0

#import "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of load

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `xm_fs_save(name, len, device, start, end)`

| Field | Details |
|---|---|
| Macro | `xm_fs_save(name, len, device, start, end)` |
| Purpose | save a block of memory as a PRG |
| Input parameters | `name`, `len`, `device`, `start`, `end` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_LOAD` is enabled. |
