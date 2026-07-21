# x16lib

An assembly library for the Commander X16. Write programs directly in 6502,
without re-deriving the machine's hardware surface every time.

The capability list comes from the ForthX16 help pages in [`doc/`](doc/); the
hardware facts come from the official VERA references in the same folder and
from the r49 ROM sources. No Forth code is used — this is a fresh assembly
implementation with an assembly-shaped API.

## Prerequisites

The third-party toolchains are expected in the working tree but are **not**
committed (see `.gitignore` — they are not ours to redistribute). Each
assembler lives in its own repo-local folder, and the build scripts look
only there:

| Path | What | Where from |
|---|---|---|
| `acme\acme.exe` | ACME 0.97 assembler | <https://sourceforge.net/projects/acme-crossass/> |
| `cc65\ca65.exe` + `ld65.exe` | ca65/ld65 V2.19 (from the cc65 suite) | <https://cc65.github.io/> — copy the two exes out of its `bin\` |
| `64tass\64tass.exe` | 64tass V1.60 | <https://sourceforge.net/projects/tass64/> |
| `kickass\KickAss.jar` | KickAssembler 5.25 (needs Java) | <http://theweb.dk/KickAssembler/> |
| `dasm\dasm.exe` | dasm v2.20.17 release (binary reports 2.20.16) | <https://github.com/dasm-assembler/dasm/releases> |
| `mads\mads.exe` | MADS 2.1.7 (Mad Assembler) | <https://github.com/tebe6502/Mad-Assembler> — `bin\windows_x86_64\mads.exe` |
| `vasm\vasm6502_oldstyle.exe` | vasm 2.0f, 6502 CPU + oldstyle syntax | <http://sun.hasenbraten.de/vasm/> — binary releases, `vasm6502_oldstyle_Win64.zip` |
| `emulator\x16emu.exe` + `rom.bin` | X16 emulator r49 | <https://github.com/X16Community/x16-emulator>, ROM from <https://github.com/X16Community/x16-rom> |

Only `acme\` and `emulator\` are required to build the reference tree and run
the tests; the other six folders are needed only to recompile their
respective ports.

Use the **r49** emulator and ROM: the constants in `src_acme/core/` are transcribed
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
.\build_acme.ps1                 # assemble examples\hello.asm -> build\HELLO.PRG
.\build_acme.ps1 -Run            # ...and run it in the emulator
.\build_acme.ps1 -Test           # headless regression suite
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

Assemble with `src_acme\` on the include path:

```
acme -I src_acme -f cbm -o OUT.PRG myprog.asm
```

`x16.asm` must come **before** any code, because ACME macros have to be defined
before they are called. `x16_code.asm` goes wherever you want the library's
machine code to sit, and must be sourced exactly once. ACME has no linker, so
unused routines cannot be stripped automatically — that is what the `X16_USE_*`
gates are for.

### Friendly macros (optional): `core/sugar.asm`

Loading an argument block by hand — a dozen `lda`/`sta` lines per call — is the
tax of a register-and-P-block ABI. `core/sugar.asm` is an **optional, opt-in**
layer that pays it for you: one macro per public routine, named `xm_<routine>`,
that takes the arguments in order and calls it. So

```asm
+xm_shape_frrect 40, 40, 200, 110, 28, FILL   ; rounded rect, filled
+xm_pal_set 1, $0F00                           ; palette entry 1 = red
+xm_sprite_pos 0, 100, 50                       ; sprite 0 to (100,50)
```

replaces the setup blocks entirely. It is the same idea as the CXGEOS `asmsdk`
`cxm_*` layer, adapted to this repo and generated the same way as everything
else (written for ACME; the six ports come out of `tools/acme2*.py`). Set your
gates, then source it — each module's macros are wrapped in that module's
`X16_USE_*`, so `xm_pal_set` only exists when `X16_USE_PALETTE` is set:

```asm
!source "x16.asm"
X16_USE_SHAPES_RRECT = 1
X16_USE_PALETTE      = 1
!source "core/sugar.asm"     ; <- optional, AFTER the gates
```

Two things to know. **It is purely additive**: a program that does not source it,
or does not invoke a macro, is byte-for-byte unchanged, and each macro expands to
exactly the hand-written setup + `jsr`, so it costs nothing at run time.
**Arguments are immediates** (`lda #arg`), so pass constants; to call with a value
held in a variable, set the block by hand and `jsr` the routine (see
`examples/m_bounce.asm`, which macros the constant setup and hand-writes the
per-frame position/collision). Argument-free routines (`i16_add`, `f_sqrt`,
`sprites_on`) are called directly — a wrapper would add nothing. The
`examples/m_*.asm` files are macro editions of the plain examples.

## Other assemblers: ca65, 64tass, KickAssembler, dasm, MADS, vasm

Two ways in, pick per project:

### Native sources (full `X16_USE_*` gating)

The library exists as **seven native source trees** — ACME (`src_acme/`, the
reference), ca65 (`src_ca65/`), 64tass (`src_64tass/`), KickAssembler
(`src_kick/`), dasm (`src_dasm/`), MADS (`src_mads/`) and vasm
(`src_vasm/`) — same file layout, same module gates, same macros, same
routine contracts. The six ports are not reimplementations: converters in
`tools/` (`acme2ca65.py`, `acme2tass.py`, `acme2kick.py`, `acme2dasm.py`,
`acme2mads.py`, `acme2vasm.py`) produce them from the ACME tree, a few
dialect-specific files are maintained by hand (each tree's README lists
them), and every port is held to the hardest possible bar — **its test
runner assembles to a byte-identical PRG** (same SHA-256) as the ACME build
and passes the same 152-test suite (154 windowed) on the emulator.

Each port pairs a source tree with its repo-local toolchain folder:

```
port            sources       toolchain (gitignored)   build script
--------------  ------------  -----------------------  ------------------
ACME            src_acme\     acme\acme.exe            build_acme.ps1
ca65            src_ca65\     cc65\ca65.exe + ld65.exe build_ca65.ps1
64tass          src_64tass\   64tass\64tass.exe        build_64tass.ps1
KickAssembler   src_kick\     kickass\KickAss.jar      build_kick.ps1
dasm            src_dasm\     dasm\dasm.exe            build_dasm.ps1
MADS            src_mads\     mads\mads.exe            build_mads.ps1
vasm            src_vasm\     vasm\vasm6502_oldstyle.exe  build_vasm.ps1
```

```
cc65\ca65 --cpu 65C02 -I src_ca65 -o prog.o prog.s
cc65\ld65 -C test_ca65\runner.cfg -o PROG.PRG prog.o   (or your own cfg)

64tass\64tass -C -a --cbm-prg -I src_64tass -o PROG.PRG prog.asm

java -jar kickass\KickAss.jar prog.asm -libdir src_kick -o PROG.PRG

dasm\dasm prog.asm -I src_dasm -f1 -o PROG.PRG

mads\mads prog.asm -c -i:src_mads -o:PROG.bin   (flat image; prepend the
                                                 two-byte $0801 load addr)

vasm\vasm6502_oldstyle -c02 -Fbin -cbm-prg -I src_vasm -o PROG.PRG prog.asm

.\build_ca65.ps1 -Test      the suite through each port's toolchain
.\build_64tass.ps1 -Test    (each uses its repo-local folder above;
.\build_kick.ps1 -Test       see Prerequisites for where to get them.
.\build_dasm.ps1 -Test       -Ca65 overrides the cc65\ default.)
.\build_mads.ps1 -Test
.\build_vasm.ps1 -Test
```

A ca65 program is the ACME skeleton with `.include` in place of `!source`
and no `+` on macro calls; `.ifdef`-based `X16_USE_*` gating works
identically. 64tass keeps ACME's `X16_USE_VERA = 1` spelling (gates default
to 0 via `.weak`). KickAssembler selects modules with `#define X16_USE_*`
before the `#import "x16_code.asm"` — see `src_kick/README.md` for the
one ordering rule (zero-page overrides go before the `x16.asm` import).
A dasm program is the ACME skeleton with `processor 65c02`, `include` in
place of `!source`, `IFCONST X16_USE_*` gating, and no `+` on macro calls;
because dasm has no cheap-local tier the converter emits a `SUBROUTINE`
before each label so `.name` locals scope as ACME's `@name` did. dasm has
**no linker** — like ACME and 64tass it writes the `.prg` directly (`-f1`).
A MADS program is the ACME skeleton with `icl` for `!source`, `.if .def
X16_USE_*` gating, `org` for `*=`, and no `+` on macro calls; MADS's
`?`-locals resolve to the nearest definition rather than the enclosing
label, so the converter renames each `@cheap` to a `<routine>__name`
global instead. MADS also has **no linker** and emits a flat image (x16.asm
sets `opt h-`), so `build_mads.ps1` prepends the two-byte $0801 load
address — the same PRG the others produce. Macro arguments must be
space-free (MADS splits them on whitespace), which the converter handles.
A vasm program is the ACME skeleton with `include` in place of `!source`,
`org` for `*=`, `ifdef X16_USE_*` gating, no `+` on macro calls, and 65C02
mode selected by `-c02` on the command line rather than in the source.
vasm is the friendliest port: its `.name` locals are scoped between two
global labels — exactly ACME's `@name` cheap-local tier — so the converter
maps them one for one with no scaffolding (zone-locals are promoted to
globals, as in the ca65/dasm ports). Like ACME, vasm has **no linker**;
`-Fbin -cbm-prg` writes the `.prg` (load address + image) directly.

### Prebuilt binary + bindings (no gating, any assembler)

Alternatively, `dist.ps1` assembles the whole library into a binary at a
fixed address and generates bindings for the three other major 6502
assemblers straight from that build's symbol list, so the addresses can
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

The prebuilt binary and the generated bindings are **committed**, so this
route needs no toolchain beyond your own assembler — running `dist.ps1`
is only for regenerating them after a library change (there's also a
`dist\acme\x16lib.inc` for using the blob from ACME itself).

Your program owns `$0801` up to the library's org (the generated includes
export it as `X16LIB_ORG`, `$5800` since 0.4.0 — it was `$6000` through
0.3.0, and gfx2 no longer fits under `$9EFF` from there); the library claims
zero page `$22`–`$31`, exactly as under ACME. Include the binding file, embed
`x16lib.bin` at `X16LIB_ORG` (each example shows the dialect's way), and call the
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
always contains everything — currently ~17.1 KB) and a movable `X16_ZP`. If
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
| `X16_USE_BITMAP` | 320×240 @ 8bpp (256 colours): `gfx_init`, `gfx_clear`, `gfx_read`, `gfx_pset`, `gfx_hline`, `gfx_vline`, `gfx_rect`, `gfx_frame`, `gfx_line`, `gfx_pattern_set`/`gfx_pattern_rect`, `gfx_blit`, `gfx_blitm` (colour-key), `gfx_char`, `gfx_text` |
| `X16_USE_BITMAP2` | 640×480 @ 2bpp (4 colours, 160-byte rows, MSB-first pixels): `gfx2_init`, `gfx2_clear` (FX cache fill), `gfx2_setptr`, `gfx2_pset`, `gfx2_read`, `gfx2_hline`, `gfx2_vline`, `gfx2_rect`, `gfx2_frame`, `gfx2_line`, `gfx2_pattern_set`/`gfx2_pattern_rect` (screen-anchored 8×8 patterns), `gfx2_blit` (byte-aligned raster ops copy/OR/AND/XOR), `gfx2_blitm` (masked pre-shifted column blit — proportional-text speed). Pulls in VERA and VERAFX. Spans clip like the 8bpp module: `gfx2_pset`/`gfx2_read` clip, the rest assume on-screen arguments |
| `X16_USE_SHAPES` | `shape_circle`, `shape_disc`, `shape_ellipse`, `shape_fellipse`, `shape_flood` — engine-agnostic, in `gfx/shapes.asm`. They draw through overridable `SHP_PSET`/`SHP_HLINE`/`SHP_READ` (bounds `SHP_W`/`SHP_H`), so ONE copy serves both bitmap modules: the default binds them to `gfx2` (2bpp); bind `SHP_*` to `gfx_*` for 8bpp. Pulls in `X16_USE_BITMAP2` by default. (kick/mads can't test definedness of an already-referenced symbol, so overriding a binding there sets a sentinel alongside it: `SHP_PSET_SET = 1` next to your `SHP_PSET`, and likewise per symbol.) |
| `X16_USE_SHAPES_POLY` | Adds `shape_polygon` (outline) and `shape_fpolygon` (filled) — regular convex N-gons through the same `SHP_*` bindings. Pulls in `X16_USE_SHAPES` and `X16_USE_MATH` (the vertices come from `sin8`/`cos8`), so it is a pay-per-use extra: a program that only draws circles keeps a math-free `SHAPES` build. |
| `X16_USE_SHAPES_RRECT` | Adds `shape_rrect` (outline) and `shape_frrect` (filled) — rounded rectangles. Caller sets `rr_x`/`rr_y` (top-left), `rr_w`/`rr_h`, `rr_r` (corner radius, clamped to `min(w,h)/2`); colour in `A`. Self-contained (the corners come from a midpoint circle walk, no trig), so it only pulls in `X16_USE_SHAPES`. |
| `X16_USE_SHAPES_ARC` | Adds `shape_arc` — a portion of a circle outline from a start to an end byte-angle (`0` = east, `64` = south, the `sin8`/`cos8` convention; `start == end` draws the whole circle). Args in the P block: `P0/P1` = cx, `P2/P3` = cy, `P4` = r, `P5` = start, `P6` = end, colour in `A`. Sampled every ~4 byte-angle units and joined with the shared line helper, so the chord error stays under a third of a pixel. Pulls in `X16_USE_MATH` and `X16_USE_SHP_LINE`. |
| `X16_USE_SHAPES_PIE` | Adds `shape_pie` — a filled wedge from the centre to the arc, same arguments as `shape_arc`. Built as a fan of triangles, so any span works (including the reflex &gt; 180° case, and `start == end` for a whole disc); draws with `SHP_HLINE`. Pulls in `X16_USE_SHAPES_ARC` (it reuses the arc's sample placement). |
| `X16_USE_SHAPES_BEZIER` | Adds `shape_bezier` — a cubic Bézier through four control points. Caller sets `bez_x0`/`bez_y0` … `bez_x3`/`bez_y3` (signed words); colour in `A`. Evaluated by de Casteljau at a size-adaptive number of samples (control-polygon perimeter / 8, clamped to 4..64) and joined with the shared line helper; the P0/P3 anchors are emitted exactly. Pulls in `X16_USE_SHP_LINE`. |
| `X16_USE_SHP_LINE` | Internal: the shared 16-bit Bresenham (`shp_line`, `shl_x0`/`shl_y0` → `shl_x1`/`shl_y1`, `shl_col`) that `SHAPES_ARC` and `SHAPES_BEZIER` join their samples with. Pulled automatically; you would not normally set it yourself. |
| `X16_USE_VERAFX` | All of the parts below, as it always has been. The parts exist because the whole is 2.5 KB and a program that wants one fast fill should not carry a rotozoom sampler to get it — `X16_USE_BITMAP2` asks for `_FILL` alone and is 2,162 bytes lighter for it. `fx_off` comes with any part. |
|   `X16_USE_VERAFX_MULT` | `fx_mult` (signed 16×16→32 in hardware) |
|   `X16_USE_VERAFX_FILL` | `fx_fill`, `fx_clear` |
|   `X16_USE_VERAFX_COPY` | `fx_copy` (cached VRAM→VRAM) |
|   `X16_USE_VERAFX_TRANSP` | `fx_transp_on`/`off` |
|   `X16_USE_VERAFX_AFFINE` | `fx_affine_on`/`ray`/`span` (the rotozoom/mode-7 sampler) |
|   `X16_USE_VERAFX_LINE` | `fx_line` (hardware Bresenham) |
|   `X16_USE_VERAFX_TRI` | `fx_triangle` (polygon-filler triangles) |
| `X16_USE_IRQ` | `irq_install`, `irq_remove`, `irq_frames`, `vsync_wait`, `irq_line_install`/`remove` (raster interrupts), `irq_sprcol_install`/`remove`, `sprite_collisions`, `irq_save_regs`/`irq_restore_regs` |
| `X16_USE_PSG` | `psg_init`, `psg_set_freq`/`vol`/`wave`, `psg_note_off`, `psg_env_start`/`release`/`stop`/`tick` (per-voice ASR envelopes) |
| `X16_USE_YM` | `ym_write` (raw), `ym_busy`, `ym_init`, `ym_poke`, `ym_patch`, `ym_note`, `ym_note_bas`, `ym_release_note`, `ym_vol`, `ym_pan`, `ym_drum`, `ym_get_pan`, `ym_get_vol` |
| `X16_USE_PCM` | `pcm_ctrl`, `pcm_rate`, `pcm_reset`, `pcm_full`/`empty`, `pcm_put`, `pcm_write` |
| `X16_USE_PCM_STREAM` | `pcm_stream_start`/`start_bank`/`stop`/`active`, `pcm_str_loop` — AFLOW-interrupt streaming beyond the 4 KB FIFO, from low or banked RAM, looping (pulls in PCM and IRQ) |
| `X16_USE_INPUT` | `joy_scan`, `joy_get`, `mouse_show`/`hide`/`get`, `key_get`, `key_wait`, `key_peek` |
| `X16_USE_SERIAL` | The serial / WiFi card's 16C550 UARTs (up to two, at `$9F60`/`$9F68`): `ser_detect` (scan the expansion window, `ser_u0`/`ser_u1` = the bases found), `ser_init` (8N1, FIFOs, auto-flow, no IRQ; takes the base in `A`/`X` and a `SER_BAUD_*` divisor in `P0`/`P1`), `ser_avail`, `ser_get` (non-blocking, carry set = nothing waiting), `ser_get_wait`, `ser_put`, `ser_puts`, `ser_write` (counted, binary-safe), `ser_read_until`/`ser_discard_until` (blocking, match a needle). Self-contained (no other module). It drives a specific add-on card, so — like `DOUBLE` — it is pay-per-use: **not** in `X16_USE_ALL` or the prebuilt blob; set the gate to pull it in. |
| `X16_USE_SERIAL_ZIMODEM` | The WiFi half — an ESP32 running ZiModem, driven as an AT-command modem over UART 0: `zi_init` (reset the board to a known state), `zi_cmd` (send an `AT…` line + CR/LF), `zi_wait_ok`, `zi_reset`, `zi_get_ip` (IPv4 via ATI2), hex-mode file download (`zi_hex_open` → `zi_hex_chunk` → `zi_hex_close`), and `zi_hexdecode` (the payload decoder). A thin AT-framing skin over the `ser_*` primitives. Pulls in `X16_USE_SERIAL`; pay-per-use (not in `X16_USE_ALL`). |
| `X16_USE_BANK` | `bank_set`/`get`, `bank_peek`/`poke`, `mem_to_bank`, `bank_to_mem`, `bank_copy_far` |
| `X16_USE_BANKALLOC` | `bank_alloc_init`, `bank_alloc`, `bank_free`, `bank_reserve` |
| `X16_USE_STACK` | An 8 KB LIFO stack living in one HIRAM bank: `stack_init` (takes the bank in `A`), `stack_push`/`stack_pushw`, `stack_pop`/`stack_popw` (byte and word), `stack_size`/`stack_free`, `stack_isempty`/`stack_isfull`. Saves/restores `RAM_BANK`. The 256-byte version that needs no bank is `stk_*` in `X16_USE_BUFFERS`. Pay-per-use (not in `X16_USE_ALL`). |
| `X16_USE_RINGBUFFER` | An 8 KB FIFO ring living in one HIRAM bank: `ring_init` (bank in `A`), `ring_put`/`ring_putw`, `ring_get`/`ring_getw`, `ring_size`/`ring_free`, `ring_isempty`/`ring_isfull`. Saves/restores `RAM_BANK`. The 256-byte version is `rb_*` in `X16_USE_BUFFERS`. Pay-per-use. |
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
| `X16_USE_BCD` | Packed-BCD (decimal-mode) arithmetic on `bcd_a`/`bcd_b` registers: `bcd_add8`/`16`/`32`, `bcd_sub8`/`16`/`32` (carry out = overflow/borrow), and `bcd_addto`/`bcd_subfrom` (32-bit, in place through a pointer). `$0987 + $1111 = $2098` — the hex digits *are* the decimal digits, so a score or clock stays print-ready without binary→decimal conversion. Pay-per-use (not in `X16_USE_ALL`). |
| `X16_USE_COLLIDE` | `collide8`, `collide16` (AABB overlap) |
| `X16_USE_BITS` | `catnib`, `hinib`, `lonib`, `bit_set`/`clr`/`put`/`test` |
| `X16_USE_NUMBER` | `u16_to_dec`, `u16_to_hex`, `dec_to_u16` |
| `X16_USE_INT16` | 16-bit integers: `i16_add`/`sub`/`neg`/`abs`/`mul`/`divmod`/`divmod_s`, `i16_cmps`/`cmpu`, `i16_shl`/`shr`/`asr`, `i16_sqrt`, `i16_from_u8`/`s8`, `i16_to_dec`/`dec_s`, `+i16_const` |
| `X16_USE_INT32` | 32-bit integers: `i32_add`/`sub`/`neg`/`abs`/`mul`/`divmod`, `i32_cmps`/`cmpu`, `i32_shl`/`shr`/`asr`, `i32_from_u16`/`s16`, `i32_to_s16`, `i32_to_dec`, `+i32_const` |
| `X16_USE_FLOAT` | `f_load`/`store`, `f_add`/`sub`/`mul`/`div`, `f_rsub`/`rdiv`, `f_pow`, `f_cmp`, `f_sqrt`, `f_ln`, `f_exp`, `f_sin`/`cos`/`tan`/`atan`, `f_abs`/`neg`/`sgn`/`int`, `f_from_s16`/`u8`/`str`, `f_to_s16`/`str`/`str_trim` — the ROM's 5-byte float (~9 digits) |
| `X16_USE_DOUBLE` | Software IEEE-754 **binary64** (~15-16 digits) where the ROM float is too coarse — a `d_ac` accumulator like FLOAT's `FAC`: `d_load`/`store`, `d_from_s16`/`s32`, `d_to_s32`, `d_neg`/`abs`, `d_cmp`, `d_add`/`sub`/`mul`/`div`, `d_sqrt`, `d_exp`, `d_ln`, `d_pow`, `d_sin`/`cos`/`tan`/`atan`, `d_sinh`/`cosh`/`tanh`, `d_from_str`/`d_to_str` (decimal I/O). A full scientific-calculator core in software. Self-contained (no ROM), so it is not in `X16_USE_ALL` / the prebuilt blob — enable the gate to use it. |
| `X16_USE_STRING` | NUL-terminated string fundamentals (`string/string.asm`): `str_length`, `str_copy`, `str_ncopy`, `str_append`, `str_nappend`, `str_compare`, `str_hash`. Strings passed by pointer in `A`/`X`, a second string in `X16_P0/P1`; lengths are bytes (≤ 255). |
| `X16_USE_STRING_CTYPE` | Character predicates (`string/ctype.asm`), char in `A` → carry: `str_isdigit`, `str_isxdigit`, `str_islower`, `str_isspace` (encoding-agnostic) and `str_isupper`/`str_isletter`/`str_isprint` with `_iso` variants for the letters PETSCII and ISO place differently. |
| `X16_USE_STRING_CASE` | Case folding (`string/case.asm`): `str_lower`/`str_upper` (whole string, in place) and `str_lowerchar`/`str_upperchar` (one char), each with an `_iso` variant, plus `str_compare_nocase`/`_iso`. |
| `X16_USE_STRING_FIND` | Searching (`string/find.asm`): `str_find`, `str_rfind`, `str_find_eol`, `str_contains` (character in `Y`), and `str_pattern_match` (`?`/`*` wildcards, self-modifying + recursive). |
| `X16_USE_STRING_SLICE` | Substrings (`string/slice.asm`): `str_left`, `str_right`, `str_slice` (into a target in `X16_P0/P1`), and in-place `str_ltrim`/`str_rtrim`/`str_trim`. |

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
`pcm_stream_start_bank` streams from banked RAM instead — a 24-bit byte
count and a starting bank; the refiller maps banks in as it crosses `$C000`
and always hands the interrupted code's `RAM_BANK` back. Set `pcm_str_loop`
(caller-owned, survives a stop) before starting and the sample wraps
endlessly until `pcm_stream_stop`. One hardware detail the tests pin: the
FIFO's full flag asserts at 4095 bytes, not 4096 — the ring keeps one slot
back.

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
`gfx_line`/`fx_line`'s parameter block. `gfx_char`/`gfx_text` draw the
VRAM charset's glyphs into the bitmap, transparent background, ASCII
conversion included.

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

`gfx/shapes.asm` (`X16_USE_SHAPES`) holds the drawing that is not
engine-specific: `shape_circle` (midpoint outline), `shape_disc` (filled
spans), `shape_ellipse`/`shape_fellipse` (axis-aligned outline and fill,
radii 0–255 each way, by the error-form midpoint walk) and `shape_flood`
(a scanline flood fill over a bounded 96-seed
stack — carry set means the stack overflowed and the fill is incomplete,
pathological shapes only). They plot through `SHP_PSET`/`SHP_HLINE` and
read through `SHP_READ`, all overridable, so one copy serves the 2bpp
`gfx2` and 8bpp `gfx` modules alike (rather than a hand-written circle in
each). Left alone they bind to `gfx2`.

`X16_USE_SHAPES_POLY` adds regular convex polygons on top: `shape_polygon`
(cx, cy, radius, sides, rotation, colour) walks `sides` vertices evenly
around the circle — `3` is a triangle, `4` a square/diamond, `6` a
hexagon, `12` a dodecagon (3–24) — and connects them with an engine-agnostic
Bresenham through `SHP_PSET`, so the outline clips exactly like
`shape_circle`. `shape_fpolygon` is the filled twin: a per-scanline convex
span fill through `SHP_HLINE` (so it does not clip — keep it on screen,
like `shape_disc`), half-open at the bottom edge so tiled polygons never
double-paint a shared side. `rotation` is a byte angle (0 = the first
vertex points east, 64 = south, matching `sin8`/`cos8`) — it turns a
point-up triangle into a flat-bottom one, or a pointy-top hexagon into a
flat-top one. The vertices come from `sin8`/`cos8`, so the gate pulls in
`X16_USE_MATH`; it is a one-shot drawing primitive (cost scales with
sides × height), not a per-frame filler.

Four more curve shapes sit behind their own pay-per-use gates.
`X16_USE_SHAPES_RRECT` adds `shape_rrect`/`shape_frrect` (rounded
rectangles: `rr_x`/`rr_y`/`rr_w`/`rr_h`/`rr_r`, colour in `A`) — the
corners come from a midpoint circle walk, so it needs no trig and pulls in
nothing but `SHAPES`. `X16_USE_SHAPES_ARC` adds `shape_arc`, a slice of a
circle outline from a start to an end byte-angle, sampled every ~4 units
and joined with a shared 16-bit Bresenham (`X16_USE_SHP_LINE`) so the chord
error stays sub-pixel; `X16_USE_SHAPES_PIE` fills the matching wedge
(`shape_pie`) as a fan of triangles, which handles any span up to a full
disc. `X16_USE_SHAPES_BEZIER` adds `shape_bezier`, a cubic curve through
four control points (`bez_x0`/`bez_y0` … `bez_x3`/`bez_y3`), evaluated by
de Casteljau at a size-adaptive sample count and joined with the same
line helper — the P0/P3 anchors land exactly on the curve. Arc and bézier
clip like `shape_circle` (they draw through `SHP_PSET`); the pie draws
with `SHP_HLINE`, so keep it on screen like `shape_disc`.

`comms/serial.asm` (`X16_USE_SERIAL`) drives the serial / WiFi card's
16C550 UARTs — up to two, on 8-byte boundaries in the expansion window,
the standard card at `$9F60` and `$9F68`. The WiFi half is an ESP32
running ZiModem, an AT-command modem you talk to as bytes over UART 0;
this module is that byte layer, not the modem protocol. `ser_detect`
fingerprints each candidate base by the three registers a bare bus does
not fake — the top nibble of IER always reads 0, the top two bits of MCR
always read 0, and the scratch register holds two different patterns you
write it — with interrupts held off across the probe. `ser_init` sets
8N1, turns on the FIFOs and auto-flow control, programs the baud divisor
(a `SER_BAUD_*` constant: `14745600 / (16 × baud)`) and remembers the
UART, so `ser_put`/`ser_get`/… need no address after it. Receiving is
non-blocking by default: `ser_get` returns carry-set when the FIFO is
empty rather than spinning (`ser_get_wait` is the blocking twin, for when
a device is known to be there). Byte writes go to THR through `sta (ptr)`
with no index, because an indexed store's dummy read would land on RHR
and pop a byte off the receive FIFO.

Its test story differs from the rest of the library, and the header says
so. The bundled emulator models these UARTs under `-midicard` (with an
`-sf2` placeholder — the registers answer whether or not the soundfont
loads), so **detection and the whole of `ser_init` are checked against a
real register-readback oracle**, exactly like the VERA tests read the
data port back. What the emulator cannot do is feed the receive FIFO or
route transmitted bytes back (its MCR-loopback only wires the modem
status bits), so a genuine byte round-trip is a real-hardware test: the
suite covers the RX path only for its empty / non-blocking behaviour and
TX for liveness. The serial runner builds and passes byte-identically on
all seven assemblers, like everything else.

`comms/zimodem.asm` (`X16_USE_SERIAL_ZIMODEM`) puts the WiFi half to
work. The card's ESP32 runs ZiModem firmware, a Hayes-style modem you
drive with `AT` commands over UART 0 — `zi_init` settles the board and
applies the standard config (echo off, stream mode), `zi_cmd` frames a
command line, `zi_wait_ok` reads back the `OK`, `zi_get_ip` returns the
IPv4 address, and `zi_hex_open`/`zi_hex_chunk`/`zi_hex_close` pull a file
down in ZiModem's hex-transfer mode. It is a thin AT-framing skin over
the `ser_*` primitives, nothing more. Its testing is necessarily thinner
than the base module's: ZiModem is *interactive*, and almost every
routine blocks reading the ESP32's reply — which the emulator, with no
board attached, never sends. So those flows are hardware-verified, and
the suite pins only what it can run headless: `zi_hexdecode` (the
hex-payload decoder — pure computation, checked against a known vector),
`zi_cmd`'s transmit path, and 7-way byte parity. The code says as much
in its header.

`util/bcd.asm` (`X16_USE_BCD`) does decimal add and subtract through the
65C02's BCD mode. Values sit in `bcd_a` (accumulator) and `bcd_b` (operand),
the same shape as the integer modules, and each byte holds two decimal digits
low-first — so `$0987 + $1111` really is `$2098`, not the binary `$1A98`.
There is one routine per width (`bcd_add8`/`16`/`32`, `bcd_sub8`/`16`/`32`):
decimal `ADC`/`SBC` does not distinguish signed from unsigned, exactly as
two's-complement add/sub does not in `int16`/`int32`. `bcd_addto`/`bcd_subfrom`
add or subtract `bcd_b` into a 32-bit value in place through a pointer, to skip
copying it through the accumulator. The point is a score or clock that stays
print-ready: keep it in BCD and print the hex form, which already reads as
decimal, instead of paying a binary→decimal conversion every frame. These run
in decimal mode across the operation; the KERNAL IRQ is decimal-safe, but a
custom IRQ handler that does its own `ADC`/`SBC` must `cld` first.

`storage/stack.asm` (`X16_USE_STACK`) and `storage/ringbuffer.asm`
(`X16_USE_RINGBUFFER`) are the big siblings of the 256-byte `stk_*`/`rb_*` in
`X16_USE_BUFFERS`: each keeps up to 8 KB of data in one whole HIRAM bank
(`$A000-$BFFF`) instead of low RAM. Hand the bank number to `stack_init` /
`ring_init`; the pointers and counters stay in low RAM, so only the data
lives in the bank, and every call saves and restores `RAM_BANK` — a stack in
bank 5 and your own use of bank 7 in between never collide. Both take and
return bytes or words (`stack_pushw`/`popw`, `ring_putw`/`getw`), and the
ring wraps at the 8 KB boundary. There are no over/underflow guards (like the
small ones): the cap is 8191 bytes, so consult `*_isfull`/`*_isempty` and
`*_free`/`*_size` yourself.

The `string/` modules are the NUL-terminated string toolkit, split five ways
so you pay only for what you use — the gates are independent, set whichever
ones you want. `X16_USE_STRING` is the core (measure, copy, append, compare,
hash); `X16_USE_STRING_CTYPE` classifies single characters; `X16_USE_STRING_CASE`
folds case; `X16_USE_STRING_FIND` searches (including `?`/`*` pattern matching);
`X16_USE_STRING_SLICE` copies `left`/`right`/`slice` pieces and trims whitespace
off either end. Strings are passed by pointer in `A`/`X` with a second string
in `X16_P0/P1`, the same convention as `screen_puts`, and are at most 255 bytes.
The case and classification routines come in a PETSCII form and an `_iso` form
because the two encodings place the letters at different codes — PETSCII
"lower" is numerically ISO "upper", which is the charset, not a bug.
**Number ↔ string conversion is deliberately *not* here**: it already lives
where the numbers do — `u16_to_dec`/`hex` and `dec_to_u16` in `NUMBER`,
`i16_to_dec`/`i32_to_dec` in the integer modules, `f_to_str`/`from_str` in
`FLOAT`, `d_to_str`/`from_str` in `DOUBLE`. All five string gates are
pay-per-use (out of `X16_USE_ALL`).

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
itself. Compressed BMX files are refused with `BMX_ERR_PACKED`. Loading
moves the palette and pixel data with `MACPTR` block reads streamed
straight into the VERA data port (the input-carry-set fixed-destination
mode), falling back to a `CHRIN` byte loop on devices that cannot — a
full-screen load is KERNAL-block-copy fast, not byte-banging fast.

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
| `examples/polygons.asm` | A gallery of the regular polygons — triangle, square, pentagon, hexagon, heptagon, octagon, nonagon, decagon, dodecagon — each filled with `shape_fpolygon` and outlined with `shape_polygon`, on the 2bpp bitmap engine with a custom four-colour palette. Windowed (waits for a key). |
| `examples/polyspin.asm` | A filled polygon spinning in place, redrawn each frame with a growing `rotation`, frame-locked to VSYNC. Shows the rotation argument in motion. Windowed. |
| `examples/curves.asm` | A gallery of the curve shapes: rounded rectangles (`shape_frrect`/`shape_rrect`, including a fully-rounded stadium), concentric arcs and a Pac-Man `shape_pie` with its rim outlined by `shape_arc`, and three cubic `shape_bezier` curves. Uses the optional `xm_*` macro layer throughout, so every draw is one line. Windowed (waits for a key). |
| `examples/m_hello.asm`, `m_polygons.asm`, `m_polyspin.asm`, `m_bounce.asm`, `m_numbers.asm` | Macro editions of the examples above, calling the library through the optional friendly macro layer `core/sugar.asm` (the `+xm_*` macros). `m_polygons` spells the 3×3 gallery out as literal one-line calls; `m_numbers` produces byte-identical output to `numbers.asm`; `m_bounce` shows the honest split — constant setup through macros, per-frame run-time values (position, envelope, collision) still hand-written. Run any with `run.bat m_bounce` etc. |

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

`test_acme/runner.asm` runs on the real emulated machine. Each test drives the
library one way and verifies through an independent path (write via port 0, read
back via port 1), so a bug in the address plumbing cannot hide behind itself.
Results are printed over `CHROUT`; `build_acme.ps1 -Test` greps them and fails the
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

`FS_ROUNDTRIP` really saves and loads: `build_acme.ps1 -Test` points `-fsroot` at
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

**The serial runner** (`test_<tree>/serial.asm`) needs a UART to answer, so
`build_*.ps1 -Test` runs it under the emulator's serial-MIDI card
(`-midicard -sf2 <placeholder>`), which models two 16C550s at `$9F60`/`$9F68`.
The card's registers respond whether or not the soundfont loads, so the
harness writes a throwaway `build/dummy.sf2` — no binary asset in the repo,
and the "Could not load MIDI synth library" line the emulator prints is
expected. The same independent-oracle rule holds: the tests drive `ser_detect`
and `ser_init`, then read the raw UART registers straight back through absolute
addresses. Detection and register programming are verified this way; the
receive path is checked only for its empty / non-blocking behaviour (nothing
feeds the RX FIFO headless) and transmit for liveness (sent bytes leave for the
synth and cannot be read back). A real byte round-trip is a hardware test. The
same runner also pins the ZiModem layer's one headless-testable piece —
`zi_hexdecode`, the hex-payload decoder — against a known vector, and `zi_cmd`'s
transmit path; the interactive AT-command flows are hardware-verified.

## Layout

```
acme/        ACME 0.97 assembler          (repo-local, .gitignored)
cc65/        ca65.exe + ld65.exe V2.19    (repo-local, .gitignored)
64tass/      64tass V1.60                 (repo-local, .gitignored)
kickass/     KickAssembler 5.25           (repo-local, .gitignored; needs Java)
dasm/        dasm v2.20.17                (repo-local, .gitignored)
mads/        MADS 2.1.7                   (repo-local, .gitignored)
vasm/        vasm 2.0f (6502/oldstyle)    (repo-local, .gitignored)
emulator/    x16emu r49 + rom.bin         (repo-local, .gitignored)
doc/         ForthX16 help pages + official X16/VERA references
src_acme/    THE REFERENCE IMPLEMENTATION
  x16.asm        constants + macros (source first, emits nothing)
  x16_code.asm   routine modules, gated by X16_USE_*
  core/          const_zp, const_vera, const_kernal, const_rom, macros
  video/         vera, screen, palette, tile
  sprite/        sprite
  gfx/           bitmap, verafx
  audio/         psg, ym, pcm, adpcm
  input/         input
  comms/         serial, zimodem
  system/        irq
  storage/       bank, bankalloc, stack, ringbuffer, mem, load, dos, bmx
  string/        string, ctype, case, find, slice
  util/          fixed, bcd, collide, bits, number, int16, int32, float,
                 math, clip, buffers, zx0, tscrunch
src_ca65/    native ca65 port        } generated + a few hand files;
src_64tass/  native 64tass port      } byte-identical output, same
src_kick/    native KickAssembler    } suite -- see each tree's README
src_dasm/    native dasm port        }
src_mads/    native MADS port        }
src_vasm/    native vasm port        }
examples/    hello.asm, bounce.asm, numbers.asm, hello-mads.asm,
             hello-vasm.asm
test_acme/   runner.asm, runner2.asm, serial.asm, testlib.asm,
             blobsmoke.asm (189 tests; runner2 covers BCD, the banked
             buffers and the string library; serial.asm covers SERIAL +
             ZIMODEM and runs under the emulator's -midicard UART card)
test_ca65/   the converted runners + runner.cfg (same suite)
test_64tass/ the converted runners (same suite)
test_kick/   the converted runners (same suite)
test_dasm/   the converted runners (same suite)
test_mads/   the converted runners (same suite)
test_vasm/   the converted runners (same suite)
tools/       acme2ca65.py, acme2tass.py, acme2kick.py, acme2dasm.py,
             acme2mads.py, acme2vasm.py -- the converters
dist/        the prebuilt-binary + bindings pipeline (dist.ps1)
build_acme.ps1
build_ca65.ps1
build_64tass.ps1
build_kick.ps1
build_dasm.ps1
build_mads.ps1
build_vasm.ps1
```

ROM entry points in `core/const_rom.asm` carry a `rom_` prefix (`rom_ym_init`,
`rom_psg_init`), leaving the unprefixed names free for the library's own
routines.
