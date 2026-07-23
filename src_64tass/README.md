# x16lib -- 64tass edition

A native 64tass port of the library: same layout, same X16_USE_* gates,
same macros and routine contracts as src_acme/, assembled as one
translation unit. Assemble CASE-SENSITIVE and in ASCII mode -- both are
part of the dialect:

    64tass -C -a --cbm-prg -I src_64tass -o PROG.PRG prog.asm

(the repo carries the assembler at `64tass\64tass.exe`)

Module gates default to 0 through a `.weak` block in x16_code.asm, so
`X16_USE_VERA = 1` anywhere in your program enables a module -- 64tass
is multi-pass, before or after the include both work.

MAINTENANCE: src_acme/ is the reference implementation. Do not edit
the generated files here -- fix src_acme/, then regenerate:

    python tools\acme2tass.py src_acme src_64tass
    python tools\acme2tass.py test_acme test_64tass
    python tools\acme_doc2tass.py

Four files are HAND-MAINTAINED (64tass expresses their ACME features
differently) and are skipped by the converter:

    x16.asm            root include (.cpu, raw byte encoding, includes)
    x16_code.asm       .weak gate defaults + the xuse_* closure
    core/macros.asm    the macro layer (.segment, not .macro: ACME
                       macros are textual, so no new scope)
    util/math.asm      trig tables inlined as literals

PROOF: test_64tass/runner.asm assembles to a byte-identical PRG (same
SHA-256) as the ACME build and passes the same 132-test suite (134
windowed) on the emulator:

    .\build_64tass.ps1 -Test
