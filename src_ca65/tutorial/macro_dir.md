# Directory Macros

> Generated ca65 edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_DIR` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_DIR = 1
.include "x16.asm"
```

A drive hands its directory over as a BASIC program listing -- link
bytes, the block count posing as a line number, the name in quotes, the
type as text. `dir_open`/`dir_next` walk that so you never see it.

The header line comes back as `DIR_TYPE_HOST` and the trailing "BLOCKS
FREE." line as `DIR_TYPE_NONE` with an empty name. They are not hidden:
a file browser skips them, a disk-info panel shows them, and neither has
to parse anything twice.

## `xm_dir_open path, len, device`

| Field | Details |
|---|---|
| Macro | `xm_dir_open path, len, device` |
| Purpose | open a directory for reading |
| Input parameters | `path, len, device` -- a `len` of 0 asks for the current directory |
| Output parameters | carry set if the directory could not be opened |
| More info | Available when `X16_USE_DIR` is enabled. |
| Example | See below. |

## `xm_dir_next buf, size`

| Field | Details |
|---|---|
| Macro | `xm_dir_next buf, size` |
| Purpose | read the next entry's name into `buf` |
| Input parameters | `buf, size` -- the size is honoured, so a long name cannot overrun it |
| Output parameters | carry **set** if an entry was read, **clear** at the end of the listing |
| More info | `dir_type` (A = `DIR_TYPE_*`) and `dir_blocks` (X/Y) then describe it. |
| Example | See below. |

```asm
.setcpu "65C02"
.include "x16.asm"

X16_USE_DIR = 1
X16_USE_SCREEN = 1
.include "core/sugar.asm"

.segment "LOADADDR"
    .word $0801
.segment "CODE"
    basic_stub

main
    xm_dir_open path, 0, 8  ; 0 = the current directory
    bcs no_dir

loop
    xm_dir_next namebuf, 40
    bcc done  ; carry CLEAR: the listing ended
    jsr dir_type
    cmp #DIR_TYPE_PRG  ; programs only
    bne loop
    lda #<namebuf
    ldx #>namebuf
    jsr screen_puts
    lda #13
    jsr screen_chrout
    bra loop

done
    jsr dir_close
no_dir
    rts

path .byte "$"
namebuf .res 40, 0

.include "x16_code.asm"
```
