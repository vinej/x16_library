# x16lib -- KickAssembler edition

A native KickAssembler port of the library: same layout, same module
selection, same macros and routine contracts as src_acme/, assembled as
one translation unit (needs Java):

    java -jar kickass\KickAss.jar prog.asm -libdir src_kick -o PROG.PRG

(the repo carries the assembler at `kickass\KickAss.jar`)

Module gates are PREPROCESSOR symbols here, mirroring ACME's
definedness semantics; define them before the x16_code.asm import:

    #import "x16.asm"
    #define X16_USE_ALL
    .pc = $0801 "code"
    ...
    #import "x16_code.asm"

Zero-page overrides (T_ZP, X16_ZP) go BEFORE the x16.asm import --
KickAssembler's preprocessor is sequential and .const/.label are
single-assignment:

    #define T_ZP_SET
    .label T_ZP = $70
    #import "x16.asm"

MAINTENANCE: src_acme/ is the reference implementation. Do not edit
the generated files here -- fix src_acme/, then regenerate:

    python tools\acme2kick.py src_acme src_kick
    python tools\acme2kick.py test_acme test_kick
    (then delete test_kick\blobsmoke.asm -- it tests the dist blob,
    which has its own pipeline)

Three files are HAND-MAINTAINED (KickAssembler expresses their ACME
features differently) and are skipped by the converter:

    x16.asm            root include (.cpu _65c02, ascii encoding)
    core/macros.asm    the macro layer (same as dist/templates/)
    util/math.asm      trig tables inlined as literals

PROOF: test_kick/runner.asm assembles to a byte-identical PRG (same
SHA-256) as the ACME build and passes the same 132-test suite (134
windowed) on the emulator:

    .\build_kick.ps1 -Test
