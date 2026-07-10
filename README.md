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
run-numbers.bat             assemble and run examples\numbers.asm
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

## Other assemblers: ca65, 64tass, KickAssembler

The ACME sources are the single, tested implementation, but you do not need
ACME to *use* the library. `dist.ps1` assembles the whole library into a
binary at a fixed address and generates bindings for the three other major
6502 assemblers straight from that build's symbol list, so the addresses can
never drift from the binary:

```
.\dist.ps1
```

produces

```
dist\x16lib.bin          the whole library at $6000 (raw, currently ~14.7 KB)
dist\X16LIB.PRG          the same with a load header, for a runtime LOAD
dist\ca65\x16lib.inc     constants + addresses + the macro layer, per dialect
dist\64tass\x16lib.inc
dist\kickass\x16lib.inc
dist\ca65\x16lib.cfg     ld65 linker config that embeds the blob
dist\examples\           a working hello for each assembler
```

Your program owns `$0801` up to the library's org (the generated includes
export it as `X16LIB_ORG`, currently `$6000`); the library claims zero page
`$22`–`$31`, exactly as under ACME. Include the binding file, embed
`x16lib.bin` at `$8000` (each example shows the dialect's way), and call the
same routines with the same registers — `screen_puts`, `u16_to_dec`,
`i16_divmod`, the data-port contract, everything in this README applies
unchanged. The macro layer (`vera_addr`, `jsrfar`, `basic_stub`, …) is ported
to each dialect inside the generated include.

```
ca65 --cpu 65C02 -I dist\ca65 --bin-include-dir dist -o hello.o dist\examples\hello-ca65.s
ld65 -C dist\ca65\x16lib.cfg -o HELLO.PRG hello.o

64tass -C -a --cbm-prg -I dist -o HELLO.PRG dist\examples\hello-64tass.asm

java -jar KickAss.jar dist\examples\hello-kickass.asm -o HELLO.PRG
```

Dialect notes, each learned the hard way:

- **64tass needs `-C`** (case-sensitive symbols): the `jsrfar` macro and the
  KERNAL's `JSRFAR` entry differ only in case. And its default `"none"`
  encoding converts ASCII to PETSCII — `'H'` becomes `$C8` — so the example
  defines an identity encoding for byte-exact `.text`.
- **ca65** wants `--cpu 65C02` (the VERA macros use `trb`/`tsb`), and finds
  the binary via `--bin-include-dir`. The supplied linker config pads the
  gap to the library org, making one self-contained ~37 KB PRG; drop the
  `X16LIB` area and `LOAD "X16LIB.PRG"` at run time if you want a small
  one. (Keep `x16lib.cfg`'s `LIB` start equal to `X16LIB_ORG`.)
- **KickAssembler** needs `.cpu _65c02` and `.encoding "ascii"` for CHROUT
  strings; the blob is embedded with `LoadBinary`/`.fill`.

A blob and its includes are one unit: regenerate both together with
`dist.ps1`, never mix files from different builds. The dist build is verified
on the emulator (`test\blobsmoke.asm` drives the blob purely through the
generated bindings), and the three examples assemble with ca65 V2.19,
64tass V1.60 and KickAssembler 5 (Java 8+) — pass `-Ca65`/`-Tass`/`-KickJar`
to `dist.ps1` to re-run that check yourself.

What the bindings do **not** give you: `X16_USE_*` module gating (the blob
always contains everything — currently ~14.7 KB) and a movable `X16_ZP`. If
you need either, or you want the routines inlined into your own PRG, use
the ACME sources directly.

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
| `X16_USE_BITMAP` | `gfx_init`, `gfx_clear`, `gfx_pset`, `gfx_hline`, `gfx_vline`, `gfx_rect`, `gfx_frame`, `gfx_line`, `gfx_circle`, `gfx_disc`, `gfx_char`, `gfx_text`, `gfx_flood` |
| `X16_USE_VERAFX` | `fx_mult` (signed 16×16→32 in hardware), `fx_fill`, `fx_clear`, `fx_off`, `fx_line` (hardware Bresenham), `fx_triangle` (polygon-filler triangles), `fx_copy` (cached VRAM→VRAM), `fx_transp_on`/`off`, `fx_affine_on`/`ray`/`span` (the rotozoom/mode-7 sampler) |
| `X16_USE_IRQ` | `irq_install`, `irq_remove`, `irq_frames`, `vsync_wait`, `irq_line_install`/`remove` (raster interrupts), `irq_sprcol_install`/`remove`, `sprite_collisions`, `irq_save_regs`/`irq_restore_regs` |
| `X16_USE_PSG` | `psg_init`, `psg_set_freq`/`vol`/`wave`, `psg_note_off`, `psg_env_start`/`release`/`stop`/`tick` (per-voice ASR envelopes) |
| `X16_USE_YM` | `ym_write` (raw), `ym_busy`, `ym_init`, `ym_poke`, `ym_patch`, `ym_note`, `ym_note_bas`, `ym_release_note`, `ym_vol`, `ym_pan`, `ym_drum`, `ym_get_pan`, `ym_get_vol` |
| `X16_USE_PCM` | `pcm_ctrl`, `pcm_rate`, `pcm_reset`, `pcm_full`/`empty`, `pcm_put`, `pcm_write` |
| `X16_USE_PCM_STREAM` | `pcm_stream_start`/`stop`/`active` — AFLOW-interrupt streaming beyond the 4 KB FIFO (pulls in PCM and IRQ) |
| `X16_USE_INPUT` | `joy_scan`, `joy_get`, `mouse_show`/`hide`/`get`, `key_get`, `key_wait`, `key_peek` |
| `X16_USE_BANK` | `bank_set`/`get`, `bank_peek`/`poke`, `mem_to_bank`, `bank_to_mem`, `bank_copy_far` |
| `X16_USE_BANKALLOC` | `bank_alloc_init`, `bank_alloc`, `bank_free`, `bank_reserve` |
| `X16_USE_MEM` | `mem_fill`, `mem_copy`, `mem_crc`, `mem_decompress` (KERNAL block ops, LZSA2) |
| `X16_USE_LOAD` | `fs_setname`, `fs_load`, `fs_save`, `fs_vload` |
| `X16_USE_DOS` | `dos_cmd`, `dos_status`, `dos_delete`, `dos_rename`, `dos_mkdir`, `dos_rmdir`, `dos_chdir` — the command channel, so a failed save can say *why* |
| `X16_USE_BMX` | `bmx_load`, `bmx_save` — the X16's native bitmap format (header + palette + pixels) |
| `X16_USE_MATH` | `rnd_seed`/`rnd8`/`rnd16` (xorshift), `sin8`/`cos8`/`sin8u`/`cos8u` (built-at-assembly tables), `atan2`, `lerp8` |
| `X16_USE_CLIP` | `clip_set`, `clip_line` (Cohen–Sutherland; feeds `gfx_line`/`fx_line`'s parameter block) |
| `X16_USE_BUFFERS` | `rb_init`/`put`/`get`/`count` (ring buffer), `stk_init`/`push`/`pop`/`depth` |
| `X16_USE_ADPCM` | `adpcm_init`, `adpcm_nibble`, `adpcm_block` — IMA ADPCM, 4:1 compressed PCM |
| `X16_USE_ZX0` | `zx0_decompress` — ZX0 v2 (salvador/zx0 output); packs tighter than the ROM's LZSA2 |
| `X16_USE_TSC` | `tsc_decompress` — TSCrunch; unpacks faster than either, packs a little looser |
| `X16_USE_FIXED` | `umul16`, `mul88` (signed 8.8) |
| `X16_USE_COLLIDE` | `collide8`, `collide16` (AABB overlap) |
| `X16_USE_BITS` | `catnib`, `hinib`, `lonib`, `bit_set`/`clr`/`put`/`test` |
| `X16_USE_NUMBER` | `u16_to_dec`, `u16_to_hex`, `dec_to_u16` |
| `X16_USE_INT16` | 16-bit integers: `i16_add`/`sub`/`neg`/`abs`/`mul`/`divmod`/`divmod_s`, `i16_cmps`/`cmpu`, `i16_shl`/`shr`/`asr`, `i16_sqrt`, `i16_from_u8`/`s8`, `i16_to_dec`/`dec_s`, `+i16_const` |
| `X16_USE_INT32` | 32-bit integers: `i32_add`/`sub`/`neg`/`abs`/`mul`/`divmod`, `i32_cmps`/`cmpu`, `i32_shl`/`shr`/`asr`, `i32_from_u16`/`s16`, `i32_to_s16`, `i32_to_dec`, `+i32_const` |
| `X16_USE_FLOAT` | `f_load`/`store`, `f_add`/`sub`/`mul`/`div`, `f_rsub`/`rdiv`, `f_pow`, `f_cmp`, `f_sqrt`, `f_ln`, `f_exp`, `f_sin`/`cos`/`tan`/`atan`, `f_abs`/`neg`/`sgn`/`int`, `f_from_s16`/`u8`/`str`, `f_to_s16`/`str`/`str_trim` |

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
them save and restore `RAM_BANK`. They run on the KERNAL's `MEMORY_COPY` one
bank-segment at a time, so they move whole segments per call rather than a
byte per loop. `bank_copy_far` copies banked RAM to banked RAM — only one
bank fits the window at a time, so it bounces through a small low-RAM
buffer. `bank_alloc`/`bank_free` hand out whole banks from a bitmap pool,
which is the natural allocation unit on this machine.

**The KERNAL block routines treat `$9F00-$9FFF` addresses as
non-incrementing.** That one property makes `mem_fill`, `mem_copy` and
`mem_decompress` stream to and from VERA: point a data port somewhere, pass
`VERA_DATA0` as the target, and the port's own increment walks VRAM.
`mem_decompress` unpacks an LZSA2 block (`lzsa -r -f2 in out` — raw blocks,
no frame header) either into RAM or *straight into video memory*, which is
how compressed tiles, maps and sprites should ship. It cannot decompress in
place; the input may live in banked RAM (8 KB limit).

`irq_line_install` runs a handler at a chosen scanline every frame — the
raster-split primitive (status bar over a scrolling playfield: repoint the
scroll registers in the line handler, restore them in a VSYNC or second line
handler). The library acknowledges LINE and SPRCOL itself; the KERNAL only
ever acknowledges VSYNC, and an unacknowledged source refires forever.
`irq_sprcol_install` + `sprite_collisions` expose VERA's hardware sprite
collision groups (the mask nibble set via `sprite_flags`): collisions
accumulate in a variable the IRQ latches, and `sprite_collisions` is a
read-and-clear. Pass a null handler to poll instead of being called back.

`pcm_stream_start` plays samples larger than the 4 KB FIFO the way the
hardware intends: it primes the FIFO, then the AFLOW interrupt (FIFO fell
under 1/4) refills it from your buffer. AFLOW has no ISR acknowledge — it
clears only by refilling, so when the data runs out the streamer disables it
in `IEN`; forget that in hand-rolled code and the interrupt storms. Set the
format with `pcm_ctrl` first; the rate is passed to `pcm_stream_start` and
playback starts only after the FIFO is primed, so it cannot underrun at t=0.

**An IRQ callback that calls the library must save the zero page it
borrows.** The KERNAL's virtual registers `r0`–`r15` and the library's
`X16_P0..T7` block belong to whatever code the interrupt cut off —
`mem_copy` runs on `r0`–`r2` with interrupts enabled, and a raster callback
that calls another `mem_*` (or `mouse_get`) corrupts the interrupted copy's
pointers on resume. Bracket such callbacks with `irq_save_regs` /
`irq_restore_regs` (one 48-byte buffer, no nesting — interrupts don't nest
here either). A callback that only touches A/X/Y and its own variables
needs nothing.

`psg_set_freq` writes the frequency **high byte first**, stepping the port
downward: low-first leaves the voice at new-low/old-high for a few cycles,
an audible click on every pitch change. `psg_env_start` +
`psg_env_tick` (once per frame) run attack/sustain/release envelopes on all
16 voices — the decay everybody hand-rolls in the frame loop, done once,
with each voice's pan bits preserved.

`clip_line` (Cohen–Sutherland) removes the drawers' documented "does not
clip" sharp edge: give it a segment in 16-bit signed coordinates (±4095)
and it rejects it (carry set) or loads the visible part straight into
`gfx_line`/`fx_line`'s parameter block. `gfx_circle`/`gfx_disc` clip on
their own; `gfx_char`/`gfx_text` draw the VRAM charset's glyphs into the
bitmap, transparent background, ASCII conversion included.

`util/math.asm` is the game-math kit: a 16-bit xorshift PRNG, 256-entry
sine/cosine tables computed by the assembler, an octant-reduced `atan2`
(byte angles: 256 = full circle, 0 = east, 64 = down-screen — the sine
tables use the same convention, so `atan2` output feeds `sin8`/`cos8`
directly), and `lerp8`.

`adpcm_block` decodes IMA ADPCM — 16-bit samples stored as 4-bit deltas,
low nibble first as in WAV blocks. Four-to-one compression is what makes
`pcm_stream_start` practical from an SD card: decode a bank's worth, stream
it, decode the next. `adpcm_pred`/`adpcm_index` are exposed because WAV
block headers carry the initial decoder state.

`gfx_flood` is a scanline flood fill over a bounded span stack (170
pending spans): carry set on return means the stack overflowed and the
fill is incomplete — pathological shapes only; a game's closed regions
never get near it. Re-filling a region with its own colour is a no-op.

The compression picture, complete: the ROM's LZSA2 (`mem_decompress`) is
free and can stream into VRAM; `zx0_decompress` (the modern ZX0 v2 that
`salvador`/`zx0` emit — not their `-classic` mode) packs tightest;
`tsc_decompress` (TSCrunch) unpacks fastest. On the shared 96-byte test
phrase they pack to 31, 30 and 33 bytes respectively. The TSCrunch port
replaces the reference decruncher's NMOS undocumented opcodes (`LAX`,
`ALR`) with legal 65C02 pairs — the original leans on them, and the X16's
CPU treats them as NOPs. Both are RAM-to-RAM (their match copiers read
the output back), and neither decompresses in place.

`fx_affine_on`/`fx_affine_ray`/`fx_affine_span` drive the last FX mode:
VERA samples an 8×8-tile texture map along a fixed-point ray, one texel
per `DATA1` read. A rotated, zoomed scanline — the mode-7 floor, the
rotozoom — is `fx_affine_ray` (start position, dx/dy from `sin8`/`cos8`)
followed by `fx_affine_span` into the framebuffer. The map wraps by
default or clips to tile 0 (`fx_affine_on`'s flag); increments use the
same 1/512-texel encoding as the line and polygon helpers.

`bmx_load`/`bmx_save` speak BMX version 1 — the platform's image format,
the one the community tools and Prog8 write. Loading restores the palette
(at the file's own start index) and streams the pixels into VRAM; rows land
`bmx_stride` bytes apart (default 320), so a full-screen image is a plain
contiguous load and a smaller one is a stamp that leaves its surroundings
alone. Saving mirrors it exactly; note the saved palette comes from VRAM's
host-write shadow, so it is only meaningful for entries this program set
itself. Compressed BMX files are refused with `BMX_ERR_PACKED`.

The `dos_*` routines finally answer *why* a file operation failed: every
command sent to channel 15 is answered with a status line (`dos_msg`), and
each wrapper returns the numeric code with carry set on the ≥20 error
classes. `dos_status` also clears a pending error. Note the first read
after power-on is code 73 — the DOS version banner — by design.

`fx_line` draws the same endpoints as `gfx_line`, but VERA tracks the
Bresenham internally and the CPU just strobes `DATA1` once per pixel.
`fx_triangle` uses the FX polygon filler: VERA walks two edges at once and
reports each row's span width, and the CPU fills exactly that many pixels.
Vertices in any order; the bottom row is half-open so adjacent triangles
never double-paint a shared edge. Both assume `gfx_init`'s 320×240@8bpp
framebuffer and do not clip. Two hardware facts cost real debugging to
learn: program the FX **addresses before the slope registers** (ADDRx writes
prefetch, and a prefetch in line mode steps the helper with whatever slope is
lingering), and **zero the FX position registers after setting the slope** —
the documented "the increment write clears the position's overflow bit" is
not what the hardware does, and a leftover carry bit eats the line's first
minor-step.

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

## Integers

`util/int16.asm` and `util/int32.asm` are the `ARITHMETIC.TXT` and `DOUBLE.TXT`
surfaces. Both have the same shape: values live in named registers the caller
writes directly (`i16_a`/`i16_b`/`i16_r`, `i32_a`/`i32_b`/`i32_r`) rather than in
the parameter block, because a binary 32-bit operation needs eight bytes of input
and the block only holds eight in total.

```asm
+i16_const i16_a, 1000
+i16_const i16_b, 7
jsr i16_divmod              ; i16_a = 142, i16_r = 6, carry clear
jsr i16_to_dec              ; A/X -> "142", Y = length

+i32_const i32_a, 1000000
+i32_const i32_b, 7
jsr i32_divmod              ; i32_a = 142857, i32_r = 1
```

Add, subtract, negate, multiply and the left shift are shared between signed and
unsigned — two's complement makes them identical. Only comparison (`i16_cmps` vs
`i16_cmpu`), division, the right shift (`asr` vs `shr`) and decimal output need
to know which you meant, and those come in pairs. Both `divmod`s return carry set
on divide-by-zero and leave the operands untouched.

`i16_divmod_s` truncates toward zero and gives the remainder the sign of the
**dividend**, matching C and Forth's `SM/REM`: `-7 / 2` is `-3` remainder `-1`,
not `-4` remainder `1`. Get that wrong and the quotient still looks plausible.

`i16_sqrt` is `FLOAT.TXT`'s `ISQRT` — an exact integer floor square root, no FP
involved. `i16_mul` and `i32_mul` keep only the low word; for the full 32-bit
product of two 16-bit values use `umul16` in `util/fixed.asm`.

## Floating point

`util/float.asm` is a *binding*, not a reimplementation. The
ROM already carries a complete C128/C65-compatible FP library in `BANK_BASIC`,
reached through a stable jump table at `$FE00`. Everything works on `FAC`, the
floating accumulator in zero page; a float in memory is 5 bytes (`FP_SIZE`).

```asm
lda #<10 : ldx #>10 : jsr f_from_s16
lda #<fvar : ldy #>fvar : jsr f_div     ; FAC = 10.0 / fvar
jsr f_to_str_trim                        ; A/X -> "2.5"
```

Every call crosses a ROM bank through `jsrfar`, which is not free — for
per-frame maths prefer `util/fixed.asm` (8.8) or `util/int32.asm`.

`f_to_s16` **floors** (it goes through the ROM's `qint`). So `0.04 * 100` comes
out a hair under 4.0 in binary floating point and `f_to_s16` gives 3. That is the
float being a float; use `f_to_str` when you want the printed value.

## Examples

| | |
|---|---|
| `examples/hello.asm` | Smallest thing that proves the toolchain: assemble, autorun, print, touch VRAM. |
| `examples/bounce.asm` | A sprite bouncing over the full 640×480 display on fixed-point velocity, frame-locked to VSYNC. A PSG blip with a per-frame decay envelope on every wall bounce; a YM2151 FM note while it overlaps the outlined target box, released when it leaves. Exercises VSYNC, sprites, palette, fixed point, 16-bit collision, tilemap drawing, PSG, FM, and number formatting together. |
| `examples/numbers.asm` | A tour of the number libraries: 16-bit and 32-bit integers, 8.8 fixed point, and floating point. Each line prints an expression and its result, so it doubles as a check. Needs no VSYNC, so it also runs headless. |

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

`bounce` needs real VSYNC, so run it windowed: `run-bounce.bat`. `numbers` does
not, so it also runs under `-testbench` if you want its output on stdout.

`numbers.asm` prints, among others:

```
1000 / 7            = 142 REM 6          SQRT(65535)         = 255
-7 / 2 (SIGNED)     = -3 REM -1          $FFFF UNSIGNED      = 65535   SIGNED = -1
300 * 300           = 24464  (WRAPS)     CMP $FFFF,1 UNSIGNED: >   SIGNED: <
1000000 / 7         = 142857 REM 1       LARGEST UNSIGNED    = 4294967295
384 * 512 >> 8      = 768                10 / 4              = 2.5
SQRT(2)             = 1.41421356         2 ^ 10              = 1024
SIN(1)              = .841470985         LN(10)              = 2.30258509
VAL("3.14159") * 2  = 6.28318001         INT(-2.5)  (FLOOR)  = -3
```

The trailing digits of `6.28318001` are the float's own rounding at nine
significant figures, not an error.

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

**Three of the ROM's FP routines are documented backwards.** `math/jumptab.s`
claims `fsub` computes `FAC -= mem` and `fdiv` computes `FAC /= mem`. Both
actually do `jsr conupk` (load ARG from memory) and then fall into the ARG-first
form, so what you get is `mem - FAC` and `mem / FAC`. And `val_1` (string to
float) is written `.X:.Y`, which everywhere else in that file means high:low —
but the code is `stx index / sty index+1`, so X holds the **low** byte.

Nothing crashes when you get these wrong: `10 - 3` quietly returns `-7`, and a
misordered pointer parses some other string. `util/float.asm` wraps them back to
the intuitive direction, and `F_SUB_ORDER` / `F_DIV_ORDER` / `F_STR` pin it.
`f_rsub` and `f_rdiv` expose the raw order, which is what you want for `1/x`.

**ACME remembers how wide a literal was written.** `$FFFFFFFE` is a four-byte
value, and `& $FF` does not narrow it, so `lda #(x & $FF)` is rejected as out of
range even when the result provably fits in a byte. Narrow with `<` instead:
`lda #<(x >>> 24)`. This bites any macro that decomposes a 32-bit constant.

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
units-digit rule; swapping the FM channel and payload registers; letting `f_sub`
use the ROM's reversed operand order; dropping `i32_divmod`'s divide-by-zero
guard; making `i32_cmps` ignore sign; giving `i16_divmod_s`'s remainder the
divisor's sign; turning `i16_asr` into a logical shift; nudging `i16_sqrt` off by
one; and corrupting an expected value.

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
  util/          fixed, collide, bits, number, int16, int32, float
examples/    hello.asm, bounce.asm
test/        runner.asm, testlib.asm
build.ps1
```

ROM entry points in `core/const_rom.asm` carry a `rom_` prefix (`rom_ym_init`,
`rom_psg_init`), leaving the unprefixed names free for the library's own
routines.
