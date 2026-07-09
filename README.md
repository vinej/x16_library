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

Double-click a `.bat`, or from a shell:

```
run-hello.bat               assemble and run examples\hello.asm
run-bounce.bat              assemble and run examples\bounce.asm
run.bat <example> [scale]   any file in examples\, at an optional window scale
test.bat                    the headless regression suite
```

`run.bat` runs the emulator **windowed**. `-testbench` is headless and raises no
VSYNC interrupt, so anything calling `vsync_wait` would hang there.

Or drive the PowerShell script directly, which is what the batch files do:

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
| `X16_USE_SCREEN` | `screen_set_mode`/`get_mode`/`reset`/`cls`/`chrout`/`color`/`border`, `screen_locate`, `screen_get_cursor`, `screen_charset`, `screen_puts` |
| `X16_USE_PALETTE` | `pal_set`, `pal_load` |
| `X16_USE_TILE` | `layer_on`/`off`, `layer_set_config`/`mapbase`/`tilebase`, `layer_scroll_x`/`y`, `tile_setptr`, `tile_put`, `tile_get` |
| `X16_USE_SPRITE` | `sprites_on`/`off`, `sprite_pos`, `sprite_get_pos`, `sprite_image`, `sprite_flags`, `sprite_z`, `sprite_size`, `sprite_init_all` |
| `X16_USE_BITMAP` | `gfx_init`, `gfx_clear`, `gfx_pset`, `gfx_hline`, `gfx_vline`, `gfx_rect`, `gfx_frame`, `gfx_line` |
| `X16_USE_VERAFX` | `fx_mult` (signed 16×16→32 in hardware), `fx_fill`, `fx_clear`, `fx_off` |
| `X16_USE_IRQ` | `irq_install`, `irq_remove`, `irq_frames`, `vsync_wait` |
| `X16_USE_PSG` | `psg_init`, `psg_set_freq`/`vol`/`wave`, `psg_note_off` |
| `X16_USE_YM` | `ym_write` (raw), `ym_busy`, `ym_init`, `ym_poke`, `ym_patch`, `ym_note`, `ym_note_bas`, `ym_release_note`, `ym_vol`, `ym_pan`, `ym_drum`, `ym_get_pan`, `ym_get_vol` |
| `X16_USE_PCM` | `pcm_ctrl`, `pcm_rate`, `pcm_reset`, `pcm_full`/`empty`, `pcm_put`, `pcm_write` |
| `X16_USE_INPUT` | `joy_scan`, `joy_get`, `mouse_show`/`hide`/`get`, `key_get`, `key_wait`, `key_peek` |
| `X16_USE_BANK` | `bank_set`/`get`, `bank_peek`/`poke`, `mem_to_bank`, `bank_to_mem` |
| `X16_USE_LOAD` | `fs_setname`, `fs_load`, `fs_save`, `fs_vload` |
| `X16_USE_FIXED` | `umul16`, `mul88` (signed 8.8) |
| `X16_USE_COLLIDE` | `collide8`, `collide16` (AABB overlap) |
| `X16_USE_BITS` | `catnib`, `hinib`, `lonib`, `bit_set`/`clr`/`put`/`test` |
| `X16_USE_NUMBER` | `u16_to_dec`, `u16_to_hex`, `dec_to_u16` |

Gates pull in their dependencies (`X16_USE_SPRITE` implies `X16_USE_VERA`), and
asking for a module twice is not an error.

`tile_*` reads `L1_CONFIG` and `L1_MAPBASE` at run time rather than assuming a
screen width, so it keeps working across `screen_set_mode`.

`irq_install` chains onto the KERNAL's `CINV` vector rather than replacing it,
so the keyboard, mouse, cursor and the VERA VSYNC acknowledge all keep running.
It is idempotent on purpose: a second install that stored `irq_handler` as its
own "previous" vector would make the chaining `jmp (irq_old_vector)` jump to
itself and hang the machine.

`fx_*` needs VERA firmware v0.3.1+ (emulator R44+) — probe with `vera_has_fx`
first. Every FX routine leaves `FX_CTRL = 0` and `DCSEL = 0` on exit, because a
lingering Addr1 Mode silently changes how ordinary VRAM addressing behaves for
everyone downstream.

The `bank_*` bulk copies auto-advance across the 8 KB bank boundary, and all of
them save and restore `RAM_BANK`.

`ym_write` talks to the chip directly — fast, and the only way to reach the LFO
and per-operator envelopes. But the ROM audio driver keeps RAM shadows of volume
and pan, and a raw write leaves those stale. If you also use the note API
(`ym_note`, `ym_vol`), poke registers through `ym_poke` instead. This is
`AUDIOYM.TXT`'s `YM!` versus `FMPOKE` distinction.

**Every FM note-API routine takes the channel in `A` and its payload in `X`** —
`ym_note_bas`, `ym_patch`, `ym_vol`, `ym_pan`, `ym_drum`, `ym_release_note`. That
is the opposite way round from the register-level `ym_write` (`A` = value,
`X` = register), and the opposite of what most people guess. Get it backwards and
you play a valid-looking note on the wrong channel: nothing crashes, nothing
complains. `YM_CHANNEL_IN_A` in the suite pins it.

`ym_init` must run before `ym_patch` — it resets the chip and loads the default
patch set, so without it there is nothing to select.

Joystick bits are **active low**: a pressed button reads 0. Test with
`and #JOY_LEFT : beq moving_left`.

## Examples

| | |
|---|---|
| `examples/hello.asm` | Smallest thing that proves the toolchain: assemble, autorun, print, touch VRAM. |
| `examples/bounce.asm` | A sprite bouncing over the full 640×480 display on fixed-point velocity, frame-locked to VSYNC. A PSG blip with a per-frame decay envelope on every wall bounce; a YM2151 FM note while it overlaps the outlined target box, released when it leaves. Exercises VSYNC, sprites, palette, fixed point, 16-bit collision, tilemap drawing, PSG, FM, and number formatting together. |

`bounce.asm` shows two audio patterns worth copying. **Play on the edge, not the
level:** `hit` is true for every frame of an overlap, so retriggering the FM note
each frame would buzz at 60 Hz — compare against the previous frame and act only
on the transition. **Envelopes belong in the frame loop:** `start_blip` just sets
pitch and arms a timer; `update_blip` scales the remaining frames into a PSG
volume once per frame, which is a linear decay for free.

It also shows how to move over a 640×480 field. A plain 8.8 word only has eight
integer bits, so the position is three bytes — an 8-bit fraction under a 16-bit
pixel coordinate — and the velocity's integer byte is sign-extended when it
ripples into the high half. Bounces **clamp to the edge** as well as reversing:
reversing alone leaves the sprite a fraction of a pixel outside the wall, and on
the left that is a negative coordinate which wraps to `$FFFF` and gets masked to
10 bits, flicking the sprite across the screen for a frame.

`bounce` needs real VSYNC, so run it windowed:
`.\build.ps1 -Source examples\bounce.asm -Run`

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

**The KERNAL requires `ADDRSEL = 0`.** Several of its screen routines write
`VERA_ADDR_L/M/H` before selecting a port, or never touch `VERA_CTRL` at all.
`screen_set_char` is the sharpest example: it sets all three address registers
and then does `sta VERA_DATA0`. With `ADDRSEL = 1` the address goes into port 1
while the character goes out of port 0, at whatever stale address it held — so
the character lands somewhere random and the screen corrupts.

This bites because `+vera_addr 1` and `vera_copy` both legitimately leave port 1
selected. The `screen_*` routines force `ADDRSEL = 0` before entering the
KERNAL; if you call `CHROUT` or `CINT` yourself, go through `screen_chrout` or
emit `+vera_addrsel 0` first. Note also that the KERNAL leaves `DCSEL = 0`, so a
`DCSEL` selection does not survive a call into it.

**Sprite coordinates are display coordinates, and the default display is
640×480.** In the standard 80×60 text mode the KERNAL leaves `HSCALE`/`VSCALE` at
128, so a sprite's 10-bit X and Y address a 640×480 field. Only screen modes 2, 3
and `$80` shift the scale by one to give 320×240. Assume 320×240 in the default
mode and your sprite is confined to the top-left quarter of the screen — it moves
and bounces correctly, so it looks like a coordinate bug rather than a scale one.

This is also why `collide8` is not enough on its own: byte coordinates cannot
reach past x=255. Use `collide16` for anything positioned in display space.

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

**The FX multiplier adds into an accumulator before writing out.** If you drive
the FX registers yourself rather than through `fx_mult`, clear the accumulator
first (read `FX_ACCUM_RESET`) or a leftover value silently corrupts your product.

**A routine that answers in the carry is fragile.** `collide8` returns its result
in the carry, and so do `fs_load`/`fs_save`/`ym_write`. Almost anything you call
next clobbers it — `screen_locate` does a `clc` on its way into `PLOT`. Capture
the flag immediately (`lda #0 : rol`) before doing anything else. `bounce.asm`
has this exact trap commented at the point it bites.

## Tests

`test/runner.asm` runs on the real emulated machine. Each test drives the
library one way and verifies through an independent path (write via port 0, read
back via port 1), so a bug in the address plumbing cannot hide behind itself.
Results are printed over `CHROUT`; `build.ps1 -Test` greps them and fails the
build on any `FAIL`, on a pass count that disagrees with the reported total, or
on a run that never prints `DONE`.

The suite has been mutation-tested. Each of these makes exactly the corresponding
test fail and the build exit non-zero: breaking `+vera_dcsel` into a naive store;
removing `vera_fill`'s zero-count guard; deleting the `ADDRSEL` guard from
`screen_cls` or `screen_chrout`; dropping `irq_install`'s idempotency guard;
removing `mem_to_bank`'s bank roll; skipping `fx_fill`'s 1-3 byte tail; dropping
`fx_mult`'s accumulator reset; removing `gfx_pset`'s clipping; changing
`gfx_vline`'s stride off `VERA_INC_320`; losing `u16_to_dec`'s always-print-the-
units-digit rule; swapping the FM channel and payload registers; and corrupting
an expected value.

`FS_ROUNDTRIP` really saves and loads: `build.ps1 -Test` points `-fsroot` at
`test/fsroot`, so device 8 is a scratch directory rather than a real SD-card
image.

That exercise also earns its keep the other way. Removing the guard from
`screen_locate` changes nothing, because `PLOT` never touches VERA — so there is
no guard there, and a comment says why.

**Skips.** `x16emu -testbench` is headless: it runs no video, so VERA never
raises a VSYNC interrupt and the KERNAL's jiffy clock stands still. Rather than
drop `VSYNC_COUNTER` or let it fail, it consults the jiffy clock (`RDTIM`, which
only advances inside the IRQ) as an independent oracle — frames stuck *and*
jiffy stuck means no interrupts exist here, so it reports `SKIP`; frames stuck
while the jiffy moves is a real bug and reports `FAIL`. Skips are counted
separately and excluded from the pass/total, so they can never be mistaken for
passes. Run the suite windowed (`-run -warp -echo`, no `-testbench`) and
`VSYNC_COUNTER` passes.

## Layout

```
acme/        ACME 0.97 assembler
doc/         ForthX16 help pages + official X16/VERA references
emulator/    x16emu r49 + rom.bin
src/
  x16.asm        constants + macros (source first, emits nothing)
  x16_code.asm   routine modules, gated by X16_USE_*
  core/          const_zp, const_vera, const_kernal, const_rom, macros
  video/         vera, screen, palette, tile
  sprite/        sprite
  gfx/           bitmap, verafx
  audio/         psg, ym, pcm
  input/         input
  system/        irq
  storage/       bank, load
  util/          fixed, collide, bits, number
examples/    hello.asm, bounce.asm
test/        runner.asm, testlib.asm
build.ps1
```

ROM entry points in `core/const_rom.asm` carry a `rom_` prefix (`rom_ym_init`,
`rom_psg_init`), leaving the unprefixed names free for the library's own
routines.
