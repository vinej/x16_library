# x16lib -- MADS edition

A native [MADS](https://github.com/tebe6502/Mad-Assembler) port of the
library: same layout, same X16_USE_* gates, same macros and routine
contracts as src_acme/. MADS has no linker, so -- like ACME, 64tass and
dasm -- it assembles as one translation unit and writes a flat image
(the build script prepends the two-byte CBM load address):

    mads prog.asm -c -i:src_mads -o:PROG.bin
    (build_mads.ps1 wraps that into a $0801 PRG for you)

MADS specifics vs the ACME reference:

  - `opt c+` (set by x16.asm) turns on the 65C02 opcodes the VERA macros
    need; `opt h-` drops MADS's Atari segment header.
  - modules are pulled in with `icl`, gates tested with `.if .def`.
  - a macro is called by name with no leading `+`, and its arguments
    carry NO spaces (MADS splits macro arguments on whitespace).
  - ACME's `@cheap` labels become `<routine>__name` globals; its
    `.zonelocal` labels become `<file>_name` globals.

MAINTENANCE: src_acme/ is the reference implementation. Do not edit the
generated files here -- fix src_acme/, then regenerate:

    python tools\acme2mads.py src_acme src_mads
    python tools\acme_doc2mads.py
    python tools\acme2mads.py test_acme test_mads   (then delete
    test_mads/blobsmoke.asm -- that one is dist-only)

Three files are HAND-MAINTAINED (MADS cannot express their ACME
features) and are skipped by the converter:

    x16.asm            the root include (opt c+/h-, the icl chain)
    core/macros.asm    the macro layer (named :params, no + on calls)
    util/math.asm      trig tables baked as literals (MADS has no
                       compile-time sin/arctan)

PROOF: test_mads/runner.asm assembles to a byte-identical PRG (same
SHA-256) as the ACME build and passes the same 132-test suite on the
emulator:

    .\build_mads.ps1 -Test
