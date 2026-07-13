# x16lib -- dasm edition

A native [dasm](https://github.com/dasm-assembler/dasm) port of the
library: same layout, same X16_USE_* gates, same macros and routine
contracts as src_acme/, assembled as one translation unit (dasm has no
linker -- it writes the .prg directly):

    dasm prog.asm -I src_dasm -f1 -o PROG.PRG

A program is the ACME skeleton with a few dasm spellings:

    processor 65c02          (not !cpu 65c02)
    include "x16.asm"        (not !source)
    org $0801                (not * = $0801)
    basic_stub               (not +basic_stub -- no + on macro calls)
    IFCONST X16_USE_VERA     (not !ifdef; gating is otherwise identical)

dasm has only one local-label tier (`.name`, scoped by the SUBROUTINE
directive), where ACME has two (`@name` cheap locals + `.name` zone
locals). The converter bridges this by emitting a bare `SUBROUTINE`
before every global label -- so `.name` locals reset exactly at ACME's
cheap-local boundaries -- and by promoting zone-locals to unique
globals. dasm spells the 65C02 accumulator inc/dec as `ina` / `dea`.

MAINTENANCE: src_acme/ is the reference implementation. Do not edit
the generated files here -- fix src_acme/, then regenerate:

    python tools\acme2dasm.py src_acme src_dasm
    (test_dasm/runner.asm + testlib.asm and the examples are converted
    the same way; see build_dasm.ps1 / tools/acme2dasm.py's header)

Three files are HAND-MAINTAINED (dasm cannot express their ACME
features) and are skipped by the converter:

    x16.asm            the root include (processor, includes)
    core/macros.asm    the macro layer (dasm MAC/ENDM, {1}/{2} params)
    util/math.asm      the sin/atan tables (ACME computes them with
                       !for + float(); here they are pre-computed bytes)

Every generated PRG is byte-for-byte identical to the ACME, ca65,
64tass and KickAssembler builds, and the test runner passes the same
132-test on-target suite (2 skipped headless).
