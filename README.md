# x16lib

An assembly library for the Commander X16. Write programs directly in 6502,
without re-deriving the machine's hardware surface every time.

| Topic | Detail |
|---|---|
| Target | Commander X16 programs written directly in 6502 assembly. |
| Source material | Capability list from the ForthX16 help pages in [`doc/`](doc/); hardware facts from the official VERA references and r49 ROM sources. |
| Implementation | Fresh assembly implementation with an assembly-shaped API. No Forth code is reused. |

## Prerequisites

| Tooling rule | Detail |
|---|---|
| Repo-local tools | Third-party toolchains are expected in the working tree. |
| Not committed | Toolchain folders are gitignored because they are not ours to redistribute. |
| Lookup path | Each assembler lives in its own repo-local folder; build scripts look only there. |

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

| Requirement | Detail |
|---|---|
| Reference build | Only `acme\` and `emulator\` are required to build the ACME tree and run tests. |
| Support ports | The other six toolchain folders are needed only to recompile their ports. |
| Emulator/ROM | Use r49; constants in `src_acme/core/` come from r49 ROM sources and tests assert r49 behaviour. |
| External docs | Official X16 and VERA references live upstream at <https://github.com/X16Community/x16-docs>. |
| Committed docs | Only the ForthX16 help pages (`doc/*.TXT`) are committed here. |

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

| Rule | Detail |
|---|---|
| Source order | `x16.asm` must come before any code, because ACME macros have to be defined before they are called. |
| Library placement | `x16_code.asm` goes wherever you want the library machine code to sit, and must be sourced exactly once. |
| Module selection | ACME has no linker, so unused routines cannot be stripped automatically. Use `X16_USE_*` gates to choose what is emitted. |

### Friendly macros (optional): `core/sugar.asm`

| Topic | Detail |
|---|---|
| Purpose | Avoid hand-loading the register-and-P-block ABI for common public routines. |
| Status | Optional and opt-in; programs can ignore it completely. |
| Shape | One macro per public routine, named `xm_<routine>`, with arguments in call order. |

For example:

```asm
+xm_shape_frrect 40, 40, 200, 110, 28, FILL   ; rounded rect, filled
+xm_pal_set 1, $0F00                           ; palette entry 1 = red
+xm_sprite_pos 0, 100, 50                       ; sprite 0 to (100,50)
```

replaces the setup blocks entirely.

| Rule | Detail |
|---|---|
| Naming | One macro per public routine, named `xm_<routine>`. |
| Generation | Written for ACME; the six support assembler versions are generated by `tools/acme2*.py`. |
| Gating | Set your `X16_USE_*` gates first, then source `core/sugar.asm`. Each module's macros are wrapped in that module's gate. |

```asm
!source "x16.asm"
X16_USE_SHAPES_RRECT = 1
X16_USE_PALETTE      = 1
!source "core/sugar.asm"     ; <- optional, AFTER the gates
```

| Constraint | Detail |
|---|---|
| Additive only | A program that does not source it, or does not invoke a macro, is byte-for-byte unchanged. |
| Runtime cost | Each macro expands to the hand-written setup plus `jsr`, so it costs nothing extra at run time. |
| Arguments | Macro arguments are immediates (`lda #arg`). For variables, set the parameter block by hand and `jsr` the routine. |
| Direct calls | Argument-free routines such as `i16_add`, `f_sqrt`, and `sprites_on` are called directly. |
| Examples | `examples/m_*.asm` are macro editions of the plain examples; `m_bounce.asm` shows constant setup through macros and per-frame values by hand. |

## Other assemblers: ca65, 64tass, KickAssembler, dasm, MADS, vasm

Two ways in, pick per project:

### Native sources (full `X16_USE_*` gating)

| Topic | Detail |
|---|---|
| Reference tree | ACME in `src_acme/`. |
| Generated trees | ca65 `src_ca65/`, 64tass `src_64tass/`, KickAssembler `src_kick/`, dasm `src_dasm/`, MADS `src_mads/`, vasm `src_vasm/`. |
| Contract | Same file layout, module gates, macros, and routine contracts in every tree. |
| Converters | `tools/acme2ca65.py`, `tools/acme2tass.py`, `tools/acme2kick.py`, `tools/acme2dasm.py`, `tools/acme2mads.py`, `tools/acme2vasm.py`. |
| Hand-maintained files | A few dialect-specific files remain manual; each support tree README lists them. |
| Release check | Each port's test runner must assemble to the same SHA-256 PRG as ACME and pass the same 152-test suite, or 154 tests windowed. |

### Tutorial documentation

| Topic | Detail |
|---|---|
| Convention | Tutorial docs follow the same reference/generated model as assembler sources. |
| Source of truth | ACME docs live in `src_acme/tutorial/`. |
| Files | `userguide.md`, `macroguide.md`, and detailed `macro_*.md` files are written in ACME syntax. |
| Generated copies | Do not edit support-tree tutorial folders by hand. |

After changing the ACME tutorial docs, regenerate the dialect copies:

```powershell
python tools\acme_doc2ca65.py
python tools\acme_doc2tass.py
python tools\acme_doc2dasm.py
python tools\acme_doc2kick.py
python tools\acme_doc2mads.py
python tools\acme_doc2vasm.py
```

Those commands write:

```
src_ca65\tutorial\
src_64tass\tutorial\
src_dasm\tutorial\
src_kick\tutorial\
src_mads\tutorial\
src_vasm\tutorial\
```

| Converter | Detail |
|---|---|
| Shared engine | `tools/acme_doc_convert.py`. |
| Entry points | `tools/acme_doc2*.py` scripts set default source and destination folders. |
| Converted syntax | Includes, gates, origins, comments, bank-byte operators, and macro calls. |
| Macro forms | ACME-style `xm_*`, hash-prefixed `#xm_*`, or KickAssembler `xm_*(...)`. |

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

#### Dialect syntax quick reference

| Dialect | Main differences from ACME |
|---|---|
| ca65 | Use `.include` instead of `!source`; omit `+` on macro calls; `.ifdef X16_USE_*` gates work the same way. |
| 64tass | Keeps `X16_USE_VERA = 1`; gates default to 0 via `.weak`. |
| KickAssembler | Use `#define X16_USE_*`; import with `#import`; zero-page overrides go before the `x16.asm` import. |
| dasm | Use `processor 65c02`, `include`, `IFCONST X16_USE_*`, and no `+`; converter emits `SUBROUTINE` scopes for `.name` locals. |
| MADS | Use `icl`, `.if .def X16_USE_*`, `org`, and no `+`; converter promotes cheap locals to `<routine>__name`; build script prepends the `$0801` load address. |
| vasm | Use `include`, `org`, `ifdef X16_USE_*`, no `+`; select 65C02 with `-c02`; `-Fbin -cbm-prg` writes the PRG directly. |
| Linkers | ACME, 64tass, dasm, MADS, and vasm write images directly; ca65 uses `ld65`. |

### Prebuilt binary + bindings (no gating, any assembler)

| Topic | Detail |
|---|---|
| Purpose | `dist.ps1` builds the whole library as one fixed-address binary. |
| Bindings | Generated from that build's symbol list, so routine addresses cannot drift from the blob. |
| Assemblers | Includes bindings for the main blob workflow assemblers. |

```
.\dist.ps1
```

produces

```
dist\x16lib.bin          the whole library at $5800 (raw, currently 12,553 bytes / ~12.3 KB)
dist\X16LIB.PRG          the same with a load header, for a runtime LOAD
dist\ca65\x16lib.inc     constants + addresses + the macro layer, per dialect
dist\64tass\x16lib.inc
dist\kickass\x16lib.inc
dist\ca65\x16lib.cfg     ld65 linker config that embeds the blob
dist\examples\           a working hello for each assembler
```

| Topic | Detail |
|---|---|
| Status | The prebuilt binary and generated bindings are committed. |
| Required tools | Your own assembler only; run `dist.ps1` only when regenerating after a library change. |
| ACME binding | `dist\acme\x16lib.inc` lets ACME use the blob too. |
| Program space | Your program owns `$0801` up to `X16LIB_ORG`. |
| Library org | `X16LIB_ORG = $5800` since 0.4.0; it was `$6000` through 0.3.0. |
| Zero page | The blob claims `$22-$31`, exactly as the ACME source build does. |
| Usage | Include the binding, embed `x16lib.bin` at `X16LIB_ORG`, and call the same routines with the same registers. |
| Macros | `vera_addr`, `jsrfar`, `basic_stub`, and the macro layer are ported inside each generated include. |

```
ca65 --cpu 65C02 -I dist\ca65 --bin-include-dir dist -o hello.o dist\examples\hello-ca65.s
ld65 -C dist\ca65\x16lib.cfg -o HELLO.PRG hello.o

64tass -C -a --cbm-prg -I dist -o HELLO.PRG dist\examples\hello-64tass.asm

java -jar KickAss.jar dist\examples\hello-kickass.asm -o HELLO.PRG
```

#### Blob notes

| Dialect | Detail |
|---|---|
| 64tass | Needs `-C` because `jsrfar` and KERNAL `JSRFAR` differ only by case; examples define identity text encoding for byte-exact strings. |
| ca65 | Needs `--cpu 65C02` and `--bin-include-dir`; supplied linker config embeds the blob as one self-contained PRG. |
| KickAssembler | Needs `.cpu _65c02` and `.encoding "ascii"`; embeds the blob with `LoadBinary`/`.fill`. |

| Rule | Detail |
|---|---|
| Keep files together | A blob and its includes are one unit. Regenerate both with `dist.ps1`; never mix files from different builds. |
| Verification | `test\blobsmoke.asm` drives the blob through generated bindings; examples assemble with ca65 V2.19, 64tass V1.60, and KickAssembler 5. |
| Re-run checks | Pass `-Ca65`, `-Tass`, or `-KickJar` to `dist.ps1`. |
| Not included | No `X16_USE_*` module gating and no movable `X16_ZP`; the blob always contains everything, currently 12,553 bytes / ~12.3 KB. |
| Need gating? | Use the native source tree when you need module selection, a movable zero page, or routines inlined into your own PRG. |

## Conventions

| | |
|---|---|
| Constants | `UPPER_SNAKE` — `VERA_ADDR_L`, `BANK_AUDIO` |
| Routines | `module_action` — `vera_fill`, `screen_border`, `pal_set` |
| Macros | same, invoked with ACME's `+` — `+vera_addr`, `+jsrfar` |
| Arguments | `A`/`X`/`Y`; more than three go in `X16_P0..P7` |
| Clobbers | `A`, `X`, `Y` and flags, unless a routine's header says otherwise |
| Errors | carry set, or a status byte in `A` |

**Zero Page**

| Topic | Detail |
|---|---|
| Library block | The library claims 16 bytes at `X16_ZP`. |
| Default | `X16_ZP = $22`, the start of the free user window. |
| Override | Define `X16_ZP` before `!source "x16.asm"` to move it. |
| KERNAL registers | `r0`-`r15` (`$02`-$21`) are caller-save scratch. |

## Modules

| Gate | Provides |
|---|---|
| `X16_USE_VERA` | `vera_set_addr0/1`, `vera_fill`, `vera_copy`, `vera_has_fx` |
| `X16_USE_SCREEN` | `screen_set_mode`/`get_mode`/`reset`/`cls`/`chrout`/`color`/`border`, `screen_locate`, `screen_get_cursor`, `screen_charset`, `screen_puts` |
| `X16_USE_PALETTE` | `pal_set`, `pal_load` |
| `X16_USE_TILE` | `layer_on`/`off`, `layer_set_config`/`mapbase`/`tilebase`, `layer_scroll_x`/`y`, `tile_setptr`, `tile_put`, `tile_get` |
| `X16_USE_SPRITE` | `sprites_on`/`off`, `sprite_pos`, `sprite_get_pos`, `sprite_image`, `sprite_flags`, `sprite_z`, `sprite_size`, `sprite_init_all` |
| `X16_USE_BITMAP8L` | 320x240 @ 8bpp in VERA VRAM: `gfx8l_init`, `gfx8l_clear`, `gfx8l_read`, `gfx8l_pset`, `gfx8l_hline`, `gfx8l_vline`, `gfx8l_rect`, `gfx8l_frame`, `gfx8l_line`, `gfx8l_pattern_set`/`gfx8l_pattern_rect`, `gfx8l_blit`, `gfx8l_blitm`, `gfx8l_char`, `gfx8l_text` |
| `X16_USE_BITMAP4L` | 320x240 @ 4bpp in VERA VRAM: `gfx4l_init`, `gfx4l_clear`, `gfx4l_read`, `gfx4l_pset`, `gfx4l_hline`, `gfx4l_vline`, `gfx4l_rect`, `gfx4l_frame`, `gfx4l_line`, `gfx4l_pattern_set`/`gfx4l_pattern_rect`, `gfx4l_char`, `gfx4l_text` |
| `X16_USE_BITMAP2L` | 320x240 @ 2bpp in VERA VRAM: `gfx2l_init`, `gfx2l_clear`, `gfx2l_setptr`, `gfx2l_pset`, `gfx2l_read`, `gfx2l_hline`, `gfx2l_vline`, `gfx2l_rect`, `gfx2l_frame`, `gfx2l_line`, `gfx2l_pattern_set`/`gfx2l_pattern_rect` |
| `X16_USE_BITMAP2H` | 640x480 @ 2bpp using MiSTer VERA_2 SDRAM auto-increment: `gfx2h_init`, `gfx2h_clear`, `gfx2h_setptr`, `gfx2h_pset`, `gfx2h_read`, `gfx2h_hline`, `gfx2h_vline`, `gfx2h_rect`, `gfx2h_frame`, `gfx2h_line`, `gfx2h_pattern_set`/`gfx2h_pattern_rect`, `gfx2h_blit`, `gfx2h_blitm` |
| `X16_USE_BITMAP4H` | 640x480 @ 4bpp using MiSTer VERA_2 SDRAM: `gfx4h_has`, `gfx4h_init`/`off`, passthru, palette, clear, pset/read, drawing, pattern, blit/blitm, copy |
| `X16_USE_BITMAP8H` | 640x480 @ 8bpp using MiSTer VERA_2 SDRAM: `gfx8h_has`, `gfx8h_init`/`off`, passthru, palette, clear, pset/read, drawing, pattern, copy |
| `X16_USE_SHAPES` | `shape_circle`, `shape_disc`, `shape_ellipse`, `shape_fellipse`, `shape_flood` - engine-agnostic, in `gfx/shapes.asm`. They draw through overridable `SHP_PSET`/`SHP_HLINE`/`SHP_READ` (bounds `SHP_W`/`SHP_H`). The default binds them to `gfx2h` (640x480 2bpp); bind `SHP_*` to `gfx8l_*`, `gfx4l_*`, `gfx2l_*`, `gfx4h_*`, or `gfx8h_*` for another bitmap target. Pulls in `X16_USE_BITMAP2H` by default. (kick/mads overrides set `SHP_PSET_SET = 1`, etc., next to the binding.) |
| `X16_USE_SHAPES_POLY` | Adds `shape_polygon` (outline) and `shape_fpolygon` (filled) — regular convex N-gons through the same `SHP_*` bindings. Pulls in `X16_USE_SHAPES` and `X16_USE_MATH` (the vertices come from `sin8`/`cos8`), so it is a pay-per-use extra: a program that only draws circles keeps a math-free `SHAPES` build. |
| `X16_USE_SHAPES_RRECT` | Adds `shape_rrect` (outline) and `shape_frrect` (filled) — rounded rectangles. Caller sets `rr_x`/`rr_y` (top-left), `rr_w`/`rr_h`, `rr_r` (corner radius, clamped to `min(w,h)/2`); colour in `A`. Self-contained (the corners come from a midpoint circle walk, no trig), so it only pulls in `X16_USE_SHAPES`. |
| `X16_USE_SHAPES_ARC` | Adds `shape_arc` — a portion of a circle outline from a start to an end byte-angle (`0` = east, `64` = south, the `sin8`/`cos8` convention; `start == end` draws the whole circle). Args in the P block: `P0/P1` = cx, `P2/P3` = cy, `P4` = r, `P5` = start, `P6` = end, colour in `A`. Sampled every ~4 byte-angle units and joined with the shared line helper, so the chord error stays under a third of a pixel. Pulls in `X16_USE_MATH` and `X16_USE_SHP_LINE`. |
| `X16_USE_SHAPES_PIE` | Adds `shape_pie` — a filled wedge from the centre to the arc, same arguments as `shape_arc`. Built as a fan of triangles, so any span works (including the reflex &gt; 180° case, and `start == end` for a whole disc); draws with `SHP_HLINE`. Pulls in `X16_USE_SHAPES_ARC` (it reuses the arc's sample placement). |
| `X16_USE_SHAPES_BEZIER` | Adds `shape_bezier` — a cubic Bézier through four control points. Caller sets `bez_x0`/`bez_y0` … `bez_x3`/`bez_y3` (signed words); colour in `A`. Evaluated by de Casteljau at a size-adaptive number of samples (control-polygon perimeter / 8, clamped to 4..64) and joined with the shared line helper; the P0/P3 anchors are emitted exactly. Pulls in `X16_USE_SHP_LINE`. |
| `X16_USE_SHP_LINE` | Internal: the shared 16-bit Bresenham (`shp_line`, `shl_x0`/`shl_y0` → `shl_x1`/`shl_y1`, `shl_col`) that `SHAPES_ARC` and `SHAPES_BEZIER` join their samples with. Pulled automatically; you would not normally set it yourself. |
| `X16_USE_VERAFX` | All of the parts below, as it always has been. The parts exist because the whole is 2.5 KB and a program that wants one fast fill should not carry a rotozoom sampler to get it — `X16_USE_BITMAP2H` asks for `_FILL` alone and is 2,162 bytes lighter for it. `fx_off` comes with any part. |
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
| `X16_USE_CLIP` | `clip_set`, `clip_line` (Cohen–Sutherland; feeds `gfx8l_line`/`fx_line`'s parameter block) |
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

## Module Notes

**Gates**

| Topic | Detail |
|---|---|
| Dependencies | Gates pull in their dependencies, such as `X16_USE_SPRITE` implying `X16_USE_VERA`. |
| Repeated gates | Asking for a module twice is not an error. |
| `X16_USE_ALL` | Optional hardware- or size-heavy gates stay pay-per-use when noted in the module table. |

**Tile And Screen**

| Topic | Detail |
|---|---|
| Tile dimensions | `tile_*` reads `L1_CONFIG` and `L1_MAPBASE` at run time instead of assuming a fixed screen width. |
| Mode changes | Tile helpers keep working across `screen_set_mode`. |
| KERNAL calls | `screen_*` routines protect the VERA address-port state before entering KERNAL screen routines. |

**IRQ**

| Topic | Detail |
|---|---|
| Chaining | `irq_install` chains onto the KERNAL `CINV` vector so keyboard, mouse, cursor, and VSYNC acknowledge continue to run. |
| Idempotency | Reinstalling does not make `irq_handler` chain to itself. |
| Raster IRQ | `irq_line_install` runs a handler at a scanline each frame; useful for raster splits. |
| Sprite collision IRQ | `irq_sprcol_install` and `sprite_collisions` expose VERA collision groups; the latched mask is read-and-clear. |
| Callback safety | Callbacks that call library routines must bracket themselves with `irq_save_regs` / `irq_restore_regs`. |

**VERA FX**

| Topic | Detail |
|---|---|
| Probe | `fx_*` requires VERA firmware v0.3.1+ / emulator R44+; call `vera_has_fx` first. |
| Exit state | FX routines leave `FX_CTRL = 0` and `DCSEL = 0` on exit. |
| Affine mode | `fx_affine_on` / `fx_affine_ray` / `fx_affine_span` sample an 8x8-tile texture map for rotozoom or mode-7-style spans. |
| Hardware line | `fx_line` uses VERA's Bresenham engine and strobes `DATA1` once per pixel. |
| Hardware triangle | `fx_triangle` uses the FX polygon filler; vertices may be in any order and the bottom row is half-open. |
| Register order | Program FX addresses before slope registers, then clear FX position registers after setting the slope. |

**Banked RAM**

| Topic | Detail |
|---|---|
| Bulk copies | `bank_*` copies auto-advance across 8 KB bank boundaries and save/restore `RAM_BANK`. |
| KERNAL copy | Copies use `MEMORY_COPY` one bank segment at a time instead of byte loops. |
| Far copy | `bank_copy_far` bounces through a low-RAM buffer because only one bank fits in the HIRAM window at once. |
| Allocation | `bank_alloc` / `bank_free` hand out whole banks from a bitmap pool. |

**KERNAL Block Routines**

| Topic | Detail |
|---|---|
| VERA streaming | KERNAL block routines treat `$9F00-$9FFF` as non-incrementing, letting VERA data-port increments walk VRAM. |
| Decompression | `mem_decompress` unpacks raw LZSA2 blocks into RAM or straight into video memory. |
| Limits | Decompression cannot run in place; banked input is limited to 8 KB. |

**PCM Stream**

| Topic | Detail |
|---|---|
| Large samples | `pcm_stream_start` primes the 4 KB FIFO, then refills through the AFLOW interrupt. |
| AFLOW | AFLOW clears only by refilling; the streamer disables it when playback ends. |
| Banked samples | `pcm_stream_start_bank` streams from banked RAM with a 24-bit byte count and restores `RAM_BANK`. |
| Looping | Set caller-owned `pcm_str_loop` before starting to loop until `pcm_stream_stop`. |
| FIFO detail | The FIFO full flag asserts at 4095 bytes, not 4096. |

**Audio**

| Topic | Detail |
|---|---|
| PSG frequency | `psg_set_freq` writes the high byte first to avoid short pitch glitches. |
| PSG envelope | `psg_env_start` plus per-frame `psg_env_tick` runs ASR envelopes for all 16 voices while preserving pan bits. |
| YM raw writes | `ym_write` is fast and reaches raw chip registers, but it bypasses ROM audio shadows. |
| YM note API | Use `ym_poke` when mixing register writes with `ym_note` / `ym_vol`. |
| YM register order | Note-API routines take channel in `A` and payload in `X`; raw `ym_write` uses `A` = value, `X` = register. |
| YM patch setup | Run `ym_init` before `ym_patch` so the default patch set exists. |

**Graphics Utilities**

| Topic | Detail |
|---|---|
| Clipping | `clip_line` clips 16-bit signed segments and loads the visible result for `gfx8l_line` / `fx_line`. |
| Bitmap text | `gfx8l_char` / `gfx8l_text` draw VRAM charset glyphs into the bitmap with transparent background and ASCII conversion. |
| Game math | `util/math.asm` provides xorshift random, byte-angle sine/cosine, `atan2`, and `lerp8`. |
| ADPCM | `adpcm_block` decodes IMA ADPCM, low nibble first; `adpcm_pred` and `adpcm_index` expose WAV block state. |

**Shapes**

| Topic | Detail |
|---|---|
| Base shapes | `X16_USE_SHAPES` provides circles, discs, ellipses, filled ellipses, and flood fill. |
| Engine binding | Shapes plot through overridable `SHP_PSET`, `SHP_HLINE`, and `SHP_READ`, so one implementation can target different bitmap engines. |
| Polygon gate | `X16_USE_SHAPES_POLY` adds regular outlines and filled convex polygons; vertices use `sin8` / `cos8`, so it pulls in math. |
| Rounded rectangles | `X16_USE_SHAPES_RRECT` adds `shape_rrect` / `shape_frrect` without trig. |
| Arcs and pies | `X16_USE_SHAPES_ARC` adds sampled circle arcs; `X16_USE_SHAPES_PIE` fills matching wedges. |
| Bezier | `X16_USE_SHAPES_BEZIER` draws cubic curves through four control points with adaptive sampling. |
| Clipping rule | Arc and Bezier plot through `SHP_PSET`; pie and filled shapes use `SHP_HLINE`, so keep those on screen. |

**Serial**

| Topic | Detail |
|---|---|
| Hardware | `comms/serial.asm` drives 16C550 UARTs, usually at `$9F60` and `$9F68`. |
| Detection | `ser_detect` fingerprints candidate bases using IER, MCR, and scratch-register behaviour. |
| Init | `ser_init` configures 8N1, FIFOs, auto-flow control, baud divisor, and stores the active UART base. |
| Receive | `ser_get` is non-blocking and returns carry set when the FIFO is empty; `ser_get_wait` blocks. |
| Transmit | Byte writes avoid indexed stores so a dummy read cannot pop receive data. |
| Testing | Emulator tests cover detection, init, empty RX, TX liveness, and byte-identical assembly; hardware is needed for real byte round-trip. |

**ZiModem**

| Topic | Detail |
|---|---|
| Layer | `comms/zimodem.asm` is an AT-command skin over `ser_*`, not a replacement serial driver. |
| Setup | `zi_init` settles the ESP32 modem and applies the standard config. |
| Commands | `zi_cmd`, `zi_wait_ok`, `zi_reset`, and `zi_get_ip` cover common modem control. |
| Hex download | `zi_hex_open` / `zi_hex_chunk` / `zi_hex_close` fetch files through ZiModem hex-transfer mode. |
| Testing | Headless tests pin `zi_hexdecode`, transmit framing, and 7-way byte parity; interactive modem replies need hardware. |

**BCD**

| Topic | Detail |
|---|---|
| Registers | Values live in `bcd_a` and `bcd_b`, with two decimal digits per byte, low-first. |
| Widths | `bcd_add8` / `16` / `32` and `bcd_sub8` / `16` / `32` use decimal-mode `ADC` / `SBC`. |
| In-place math | `bcd_addto` / `bcd_subfrom` update a 32-bit value through a pointer. |
| Purpose | Scores and clocks can stay print-ready by printing the hex digits as decimal digits. |
| IRQ note | KERNAL IRQ is decimal-safe; custom IRQ code using `ADC` / `SBC` should `cld` first. |

**HIRAM Storage**

| Topic | Detail |
|---|---|
| Stack | `X16_USE_STACK` keeps an 8 KB LIFO in one HIRAM bank. |
| Ring buffer | `X16_USE_RINGBUFFER` keeps an 8 KB FIFO in one HIRAM bank. |
| Bank safety | Both save and restore `RAM_BANK`; pointers and counters stay in low RAM. |
| Data width | Byte and word operations are available: `stack_pushw` / `popw`, `ring_putw` / `getw`. |
| Capacity | There are no over/underflow guards; check `*_isfull`, `*_isempty`, `*_free`, and `*_size`. |

**Strings**

| Topic | Detail |
|---|---|
| Split gates | `STRING`, `STRING_CTYPE`, `STRING_CASE`, `STRING_FIND`, and `STRING_SLICE` are independent pay-per-use gates. |
| Calling convention | String pointer in `A`/`X`; second string or target pointer in `X16_P0/P1`; maximum length is 255 bytes. |
| Encodings | Case and classification include PETSCII and `_iso` forms because letter ranges differ. |
| Number conversion | Number-to-string routines live with number modules: `NUMBER`, `INT16`, `INT32`, `FLOAT`, and `DOUBLE`. |

**Compression**

| Topic | Detail |
|---|---|
| ROM LZSA2 | `mem_decompress` is free and can stream into VRAM. |
| ZX0 | `zx0_decompress` handles modern ZX0 v2 output and packs tightest in the shared phrase test. |
| TSCrunch | `tsc_decompress` unpacks fastest; the port replaces NMOS-only undocumented opcodes with legal 65C02 pairs. |
| Limits | ZX0 and TSC are RAM-to-RAM and cannot decompress in place. |

**BMX And DOS**

| Topic | Detail |
|---|---|
| BMX format | `bmx_load` / `bmx_save` support BMX version 1 image files. |
| Loading | Loads palette and pixels into VRAM; `bmx_stride` defaults to 320 for full-screen contiguous rows. |
| Saving | Palette data comes from the host-write shadow, so it only reflects entries the program set. |
| Compression | Packed BMX files are refused with `BMX_ERR_PACKED`. |
| DOS status | `dos_*` wrappers return numeric status codes with carry set for error classes `>= 20`. |
| First status | The first DOS status read after power-on is code 73, the DOS version banner. |

**Input**

| Topic | Detail |
|---|---|
| Joystick polarity | Joystick bits are active low: a pressed button reads 0. |
| Example | `and #JOY_LEFT : beq moving_left` tests for a pressed left direction. |

## Integers

| Topic | Detail |
|---|---|
| Modules | `util/int16.asm` and `util/int32.asm` mirror the documented `ARITHMETIC.TXT` and `DOUBLE.TXT` surfaces. |
| Storage | Values live in named registers the caller writes directly: `i16_a` / `i16_b` / `i16_r`, and `i32_a` / `i32_b` / `i32_r`. |
| Shared operations | Add, subtract, negate, multiply, and left shift are the same for signed and unsigned two's-complement values. |
| Signed-specific operations | Comparison, division, right shift, and decimal output have signed/unsigned pairs where needed. |
| Divide by zero | Both `divmod` routines return carry set and leave operands untouched. |
| Signed division | `i16_divmod_s` truncates toward zero and gives the remainder the sign of the dividend. |
| Square root | `i16_sqrt` is an exact integer floor square root. |
| Full product | `i16_mul` and `i32_mul` keep the low word; use `umul16` in `util/fixed.asm` for a full 16x16 -> 32 product. |

```asm
+i16_const i16_a, 1000
+i16_const i16_b, 7
jsr i16_divmod              ; i16_a = 142, i16_r = 6, carry clear
jsr i16_to_dec              ; A/X -> "142", Y = length

+i32_const i32_a, 1000000
+i32_const i32_b, 7
jsr i32_divmod              ; i32_a = 142857, i32_r = 1
```

## Floating Point

| Topic | Detail |
|---|---|
| Module | `util/float.asm` is a binding to the ROM floating-point library, not a reimplementation. |
| ROM bank | Calls reach the C128/C65-compatible FP jump table in `BANK_BASIC` at `$FE00`. |
| Accumulator | Operations work on `FAC`, the floating accumulator in zero page. |
| Size | A float in memory is 5 bytes (`FP_SIZE`), about nine significant digits. |
| Cost | Every call crosses a ROM bank through `jsrfar`; use fixed point or integers for per-frame math. |
| Integer conversion | `f_to_s16` floors through the ROM `qint`; use `f_to_str` when the printed value matters. |

```asm
lda #<10 : ldx #>10 : jsr f_from_s16
lda #<fvar : ldy #>fvar : jsr f_div     ; FAC = 10.0 / fvar
jsr f_to_str_trim                        ; A/X -> "2.5"
```

## Examples

| Example | Shows |
|---|---|
| `examples/hello.asm` | Smallest toolchain proof: assemble, autorun, print, touch VRAM. |
| `examples/bounce.asm` | VSYNC, sprites, palette, fixed point, 16-bit collision, tilemap drawing, PSG, FM, and number formatting together. |
| `examples/numbers.asm` | 16-bit integers, 32-bit integers, 8.8 fixed point, and floating point; also runs headless. |
| `examples/polygons.asm` | Filled and outlined regular polygons on the 2bpp bitmap engine with a custom palette. |
| `examples/polyspin.asm` | Per-frame polygon redraw with a changing byte-angle rotation. |
| `examples/curves.asm` | Rounded rectangles, arcs, pies, and cubic Bezier curves through the optional `xm_*` macro layer. |
| `examples/m_*.asm` | Macro editions of the plain examples using `core/sugar.asm`. |

**Example Notes**

| Topic | Detail |
|---|---|
| Audio edge trigger | `bounce.asm` triggers the FM note on the overlap transition, not every overlapping frame. |
| Envelopes | `bounce.asm` updates PSG volume once per frame for a simple decay. |
| 640x480 movement | Positions use an 8-bit fraction under a 16-bit pixel coordinate; velocity is sign-extended into the high byte. |
| Bounds | Bounces clamp to the edge before reversing to avoid wrapped negative coordinates. |
| Headless runs | `bounce` needs real VSYNC and should run windowed; `numbers` also runs under `-testbench`. |

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

| Note | Detail |
|---|---|
| Float rounding | The trailing digits of `6.28318001` are the ROM float's nine-digit rounding, not an error. |

## Hardware Pitfalls

Each entry is enforced by a macro or covered by a test.

| Pitfall | Rule |
|---|---|
| VERA data ports | `DATA0` always uses port 0 and `DATA1` always uses port 1; `ADDRSEL` only chooses which address registers are visible. |
| `VERA_CTRL` packing | `RESET`, `DCSEL`, and `ADDRSEL` share one byte; use `+vera_dcsel` and `+vera_addrsel` instead of plain stores. |
| Increment field | VERA increments are encoded indexes, not byte counts; use `VERA_INC_*` constants, including row strides 40, 80, 160, 320, and 640. |
| KERNAL screen calls | KERNAL screen routines require `ADDRSEL = 0`; use `screen_*` wrappers or emit `+vera_addrsel 0` before direct KERNAL calls. |
| `DCSEL` after KERNAL | KERNAL calls leave `DCSEL = 0`; do not expect a previous `DCSEL` selection to survive. |
| Sprite coordinates | Default display-space coordinates are 640x480; screen modes 2, 3, and `$80` shift to 320x240. |
| Collision width | Use `collide16` for display-space sprites because byte coordinates cannot reach past x=255. |
| YM address | The YM2151 lives at `$9F40` / `$9F41`, not `$9FE0`. |
| ROM audio/graphics | Audio and graphics APIs live inside `BANK_AUDIO` and `BANK_GRAPH`; use `+jsrfar` instead of hand-rolled bank switches. |
| Write-only VRAM region | `$1F9C0-$1FFFF` reads return the host-write shadow, not current hardware state after reset. |
| FX multiplier | Clear the accumulator first by reading `FX_ACCUM_RESET` when driving FX multiplier registers directly. |
| ROM FP order | Some ROM FP docs describe `fsub`, `fdiv`, and `val_1` backwards; `util/float.asm` wraps them into intuitive order. |
| ACME literal width | ACME remembers literal width; narrow 32-bit constants with `<`, such as `lda #<(x >>> 24)`. |
| Carry results | `collide8`, `fs_load`, `fs_save`, and `ym_write` answer in carry; capture it immediately with a pattern such as `lda #0 : rol`. |

## Tests

| Topic | Detail |
|---|---|
| Main runner | `test_acme/runner.asm` runs on the emulated machine and checks behaviour through independent readback paths. |
| Result parsing | `build_acme.ps1 -Test` fails on any `FAIL`, mismatched pass count, or missing `DONE`. |
| Filesystem round-trip | `FS_ROUNDTRIP` saves and loads through `test/fsroot` as device 8 scratch storage. |
| Intentional no-guard | `screen_locate` has no VERA guard because `PLOT` does not touch VERA; the tests proved the guard was unnecessary. |
| Headless skips | `x16emu -testbench` has no video IRQ, so VSYNC tests report `SKIP` when both frame count and jiffy clock are stuck. |
| Windowed VSYNC | Run the suite windowed (`-run -warp -echo`, no `-testbench`) when VSYNC behaviour must pass. |
| Serial runner | `test_<tree>/serial.asm` runs under `-midicard -sf2 <placeholder>` to model two 16C550 UARTs. |
| Serial limits | Headless tests verify detection, init, empty RX, and TX liveness; real byte loopback requires hardware. |
| ZiModem tests | Headless tests pin `zi_hexdecode` and `zi_cmd` transmit framing; interactive AT flows are hardware-verified. |

**Mutation Coverage**

| Area | Mutations Caught |
|---|---|
| VERA and screen | Naive `+vera_dcsel`, missing `vera_fill` zero-count guard, missing `ADDRSEL` guards, wrong `gfx8l_vline` stride. |
| IRQ and memory | Broken `irq_install` idempotency, missing `mem_to_bank` bank roll, skipped `fx_fill` tail, missing `fx_mult` accumulator reset. |
| Graphics | Removed `gfx8l_pset` clipping and corrupted expected pixel values. |
| Numbers | Broken `u16_to_dec` units digit, divide-by-zero guards, signed compare, signed remainder, arithmetic shift, and `i16_sqrt` edge cases. |
| Audio and float | Swapped FM channel/payload registers and raw ROM reversed float operand order. |

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
  tutorial/      ACME-syntax user guide and macro reference source
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
src_ca65/    native ca65 port        } generated + a few hand files
src_64tass/  native 64tass port      } plus generated tutorial/ docs;
src_kick/    native KickAssembler    } byte-identical output, same
src_dasm/    native dasm port        } suite -- see each tree's README
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
tools/       acme2*.py source/test converters and acme_doc2*.py
             tutorial converters
dist/        the prebuilt-binary + bindings pipeline (dist.ps1)
build_acme.ps1
build_ca65.ps1
build_64tass.ps1
build_kick.ps1
build_dasm.ps1
build_mads.ps1
build_vasm.ps1
```

| Naming rule | Detail |
|---|---|
| ROM entry points | Names in `core/const_rom.asm` carry a `rom_` prefix, such as `rom_ym_init` and `rom_psg_init`. |
| Library names | Unprefixed names stay available for this library's own routines. |
