# x16lib -- vasm edition

A native [vasm](http://sun.hasenbraten.de/vasm/) port of the library
(vasm6502_oldstyle, the oldstyle syntax module): same layout, same
X16_USE_* gates, same macros and routine contracts as src_acme/,
assembled as one translation unit (like ACME, vasm's binary output
writes the .prg directly):

    vasm6502_oldstyle -c02 -Fbin -cbm-prg -I src_vasm -o PROG.PRG prog.asm

A program is the ACME skeleton with a few vasm spellings:

    include "x16.asm"        (not !source; 65C02 comes from -c02)
    org $0801                (not * = $0801)
    basic_stub               (not +basic_stub -- no + on macro calls)
    ifdef X16_USE_VERA       (not !ifdef; gating is otherwise identical)

vasm is the friendliest port so far: its `.name` local labels are
scoped between two global labels -- exactly ACME's `@name` cheap-local
tier -- so `@name` maps to `.name` one for one, with no scaffolding.
ACME's other tier (`.name` zone locals, file-scoped) is promoted to
unique `stem_name` globals by the converter, and bare accumulator
`inc`/`dec`, `'X'` char literals and `#<(...)`/`#>(...)` all assemble
unchanged.

MAINTENANCE: src_acme/ is the reference implementation. Do not edit
the generated files here -- fix src_acme/, then regenerate:

    python tools\acme2vasm.py src_acme src_vasm
    python tools\acme_doc2vasm.py
    (test_vasm/runner.asm + testlib.asm and the examples are converted
    the same way; see build_vasm.ps1 / tools/acme2vasm.py's header)

Three files are HAND-MAINTAINED (vasm cannot express their ACME
features) and are skipped by the converter:

    x16.asm            the root include (includes only; -c02 on the
                       command line replaces !cpu 65c02)
    core/macros.asm    the macro layer (vasm macro/endm, \1/\2 params)
    util/math.asm      the sin/atan tables (ACME computes them with
                       !for + float(); here they are pre-computed bytes)

Every generated PRG is byte-for-byte identical to the ACME, ca65,
64tass, KickAssembler, dasm and MADS builds, and the test runner passes
the same 132-test on-target suite (2 skipped headless).
