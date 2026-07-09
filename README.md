# x16lib

An assembly library for the Commander X16. Write programs directly in 6502,
without re-deriving the machine's hardware surface every time.

The capability list comes from the ForthX16 help pages in [`doc/`](doc/); the
hardware facts come from the official VERA references in the same folder and
from the r49 ROM sources. No Forth code is used — this is a fresh assembly
implementation with an assembly-shaped API.

## Prerequisites

Two third-party tools are expected in the working tree but are **not** committed
(see `.gitignore` — they are not ours to redistribute):

| Path | What | Where from |
|---|---|---|
| `acme\acme.exe` | ACME 0.97 assembler | <https://sourceforge.net/projects/acme-crossass/> |
| `emulator\x16emu.exe` + `rom.bin` | X16 emulator r49 | <https://github.com/X16Community/x16-emulator>, ROM from <https://github.com/X16Community/x16-rom> |

Use the **r49** emulator and ROM: the constants in `src/core/` are transcribed
from the r49 ROM sources, and the test suite asserts against r49 behaviour.

The official X16 and VERA reference documents are likewise omitted from the
repo; they live upstream at <https://github.com/X16Community/x16-docs>. Only the
ForthX16 help pages (`doc/*.TXT`) are committed here.

## Quick start

```powershell
.\build.ps1                 # assemble examples\hello.asm -> build\HELLO.PRG
.\build.ps1 -Run            # ...and run it in the emulator
.\build.ps1 -Test           # headless regression suite
```

## Writing a program

```asm
!cpu 65c02
!source "x16.asm"           ; constants + macros. Emits no code.

X16_USE_VERA = 1            ; pick your modules (or X16_USE_ALL = 1)

* = $0801
    +basic_stub             ; 10 SYS 2061

main
    +vera_addr 0, VRAM_TEXT, VERA_INC_2   ; step 2: screen codes only
    lda #$2A                              ; '*'
    ldx #80
    ldy #0
    jsr vera_fill
    rts

!source "x16_code.asm"      ; library routines land here
```

Assemble with `src\` on the include path:

```
acme -I src -f cbm -o OUT.PRG myprog.asm
```

`x16.asm` must come **before** any code, because ACME macros have to be defined
before they are called. `x16_code.asm` goes wherever you want the library's
machine code to sit, and must be sourced exactly once. ACME has no linker, so
unused routines cannot be stripped automatically — that is what the `X16_USE_*`
gates are for.

## Conventions

| | |
|---|---|
| Constants | `UPPER_SNAKE` — `VERA_ADDR_L`, `BANK_AUDIO` |
| Routines | `module_action` — `vera_fill`, `screen_border`, `pal_set` |
| Macros | same, invoked with ACME's `+` — `+vera_addr`, `+jsrfar` |
| Arguments | `A`/`X`/`Y`; more than three go in `X16_P0..P7` |
| Clobbers | `A`, `X`, `Y` and flags, unless a routine's header says otherwise |
| Errors | carry set, or a status byte in `A` |

**Zero page.** The library claims 16 bytes at `X16_ZP` (default `$22`, the start
of the free user window). Define `X16_ZP` yourself before `!source "x16.asm"` to
move it. `r0`–`r15` (`$02`–`$21`) are the KERNAL's virtual registers and are
treated as caller-save scratch.

## Modules

| Gate | Provides |
|---|---|
| `X16_USE_VERA` | `vera_set_addr0/1`, `vera_fill`, `vera_copy`, `vera_has_fx` |
| `X16_USE_SCREEN` | `screen_set_mode`/`get_mode`/`reset`/`cls`/`color`/`border`, `screen_locate`, `screen_get_cursor`, `screen_charset`, `screen_puts` |
| `X16_USE_PALETTE` | `pal_set`, `pal_load` |

Planned: sprites, bitmap graphics + VERA FX, PSG/YM2151/PCM audio, joystick /
mouse / keyboard, load-save, banked RAM, VSYNC + IRQ, fixed-point and collision
utilities.

## Things the hardware will get you wrong

Each of these is enforced by a macro or covered by a test.

**VERA has two independent data ports.** `DATA0` always reads and writes port 0,
`DATA1` always port 1, no matter what `ADDRSEL` says. `ADDRSEL` only picks whose
`ADDR_L/M/H` are visible at `$9F20`. That is why `vera_copy` can stream through
both ports without touching `CTRL` in its inner loop.

**`CTRL` packs three things into one byte:** `RESET` (bit 7), `DCSEL` (bits 6:1)
and `ADDRSEL` (bit 0). A plain `lda #2 : sta VERA_CTRL` to select an FX register
bank silently clears `ADDRSEL` out from under whoever was using port 1. Use
`+vera_dcsel` and `+vera_addrsel`, which read-modify-write. Never set bit 7.

**The address-increment field is an index, not a byte count.** `0..15` maps to
`0,1,2,4,8,…,512` *and* `40,80,160,320,640`. Use the `VERA_INC_*` constants.
Those odd values make tilemap-row and bitmap-row striding free.

**The YM2151 is at `$9F40`/`$9F41`**, not `$9FE0`.

**Audio and graphics are not in the `$FFxx` KERNAL table.** They live at `$C000+`
inside `BANK_AUDIO` (`$0A`) and `BANK_GRAPH` (`$08`). Reach them with `+jsrfar`,
which saves and restores the caller's ROM bank while preserving `A`/`X`/`Y` and
flags. Do not hand-roll the bank switch: after the `jsr`, the saved bank byte is
buried on the stack under the callee's return values, and you cannot recover it
without destroying them. `jsrfar` works because it reserves the slot up front.

**`$1F9C0`–`$1FFFF` (PSG, palette, sprite attributes) is write-only.** Reads
return the last value the *host* wrote, not the hardware's state. Reading back
your own writes is fine — the tests rely on it — but you cannot discover the
state after a reset that way.

## Tests

`test/runner.asm` runs on the real emulated machine. Each test drives the
library one way and verifies through an independent path (write via port 0, read
back via port 1), so a bug in the address plumbing cannot hide behind itself.
Results are printed over `CHROUT`; `build.ps1 -Test` greps them and fails the
build on any `FAIL`, on a pass count that disagrees with the reported total, or
on a run that never prints `DONE`.

The suite has been mutation-tested: breaking `+vera_dcsel` into a naive store,
removing `vera_fill`'s zero-count guard, and corrupting an expected value each
make exactly the corresponding test fail and the build exit non-zero.

## Layout

```
acme/        ACME 0.97 assembler
doc/         ForthX16 help pages + official X16/VERA references
emulator/    x16emu r49 + rom.bin
src/
  x16.asm        constants + macros (source first, emits nothing)
  x16_code.asm   routine modules, gated by X16_USE_*
  core/          const_zp, const_vera, const_kernal, const_rom, macros
  video/         vera, screen, palette
examples/    hello.asm
test/        runner.asm, testlib.asm
build.ps1
```
