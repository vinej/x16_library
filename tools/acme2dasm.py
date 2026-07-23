#!/usr/bin/env python3
"""acme2dasm.py -- mechanical ACME -> dasm dialect conversion for x16lib.

The ACME tree stays the reference implementation; this converts the
regular subset it uses. Files with ACME-only features (the macro layer,
the assembler-computed math tables, the root include) are maintained by
hand in src_dasm/ and listed in SKIP.

dasm (2.20.x) differs from ACME/ca65 in two ways that shape this port:

  * dasm has no "cheap" local-label tier. ACME's @name locals (scoped
    between two global labels) become dasm .name locals, and a bare
    SUBROUTINE directive is emitted before every global label so dasm
    scopes those .name locals exactly the way ACME scoped the @names.
    Zone-locals (.name, scoped to a !zone) are promoted to unique
    globals stem_name, same as the ca65 port. The three files whose
    @locals cross a zone-local (CHEAP_PROMOTE) get those @locals
    promoted to globals too, region by region.

  * dasm spells the 65C02 accumulator inc/dec as `ina` / `dea` (same
    opcodes $1A/$3A), so ACME's bare `inc` / `dec` map to those.

Directive mapping:
  !byte/!word/!text  -> dc.b / dc.w / dc.b
  !fill n[, v]       -> ds n[, v]
  !source "x"        -> include "x"
  !zone n { ... }    -> dropped
  !addr { ... }      -> dropped
  !ifdef/!ifndef X { -> IFCONST/IFNCONST X   (closing } -> ENDIF)
  one-line !ifndef X { X = 1 }               -> three lines
  !if c { !error m } -> dropped (compile-time assert; config is fixed)
  !if c { ... }      -> IF c ... ENDIF
  guard  !ifdef N !eof / N = 1  -> IFNCONST N / N = 1 ... ENDIF
  ' : '-separated statements                 -> split lines
  >>>                -> >>
  bare inc/dec (accumulator)                 -> ina / dea
"""
import re
import sys
from pathlib import Path

SKIP = {
    "x16.asm",            # hand-written root include
    "core/macros.asm",    # hand-ported macro layer
    "util/math.asm",      # !for-computed float tables: hand-generated
}

DOT_IDENT = re.compile(r'(?<![\w!$.])\.([A-Za-z_][A-Za-z0-9_]*)')

# ACME's only anonymous-label form in this tree: a single forward '+',
# defined as "+<tab><insn>" and referenced by one branch above it. This
# dialect has no equivalent tier that survives the conversion, so the
# pre-pass turns each into a zone-local .k<N>; the normal zone-local
# promotion then makes it a unique per-file global, as the ports always
# spelled it (shp_k1 and friends).
ANON_DEF = re.compile(r'^\+[ \t]+(.*)$')
ANON_REF = re.compile(
    r'^([ \t]*(?:bne|beq|bcc|bcs|bmi|bpl|bra|bvc|bvs|jmp)[ \t]+)\+[ \t]*$')

def anon_labels(text):
    lines = text.split("\n")
    defs = [i for i, ln in enumerate(lines) if ANON_DEF.match(ln)]
    names = {i: ".k%d" % (n + 1) for n, i in enumerate(defs)}
    out = []
    for i, ln in enumerate(lines):
        d = ANON_DEF.match(ln)
        if d:
            out.append(names[i])
            out.append("\t" + d.group(1))
            continue
        r = ANON_REF.match(ln)
        if r:
            nxt = next((j for j in defs if j > i), None)
            if nxt is None:
                raise SystemExit("anon '+' reference without a '+' label")
            out.append(r.group(1) + names[nxt])
            continue
        out.append(ln)
    return "\n".join(out)


# col0 tokens that are dasm directives, never labels (for SUBROUTINE pass)
DIRECTIVES = {
    'IF', 'IFCONST', 'IFNCONST', 'ELSE', 'ENDIF', 'EIF', 'MAC', 'ENDM',
    'INCLUDE', 'INCDIR', 'SUBROUTINE', 'SEG', 'ORG', 'RORG', 'PROCESSOR',
    'ECHO', 'ERR', 'DC', 'DS', 'DV', 'HEX', 'ALIGN', 'EQU', 'SET',
    'REPEAT', 'REPEND', 'EQM', 'BYTE', 'WORD', 'LONG',
}


def split_statements(line):
    """Split ACME's ' : ' statement separator outside quotes/comments."""
    out, cur, i, inq = [], "", 0, False
    while i < len(line):
        c = line[i]
        if c == '"':
            inq = not inq
        if c == ';' and not inq:
            cur += line[i:]
            break
        if not inq and line[i:i+3] == ' : ':
            out.append(cur)
            cur = ""
            i += 3
            continue
        cur += c
        i += 1
    out.append(cur)
    if len(out) == 1:
        return [line]
    indent = re.match(r'\s*', out[0]).group(0)
    return [out[0]] + [indent + frag.strip() for frag in out[1:]]


def convert(text, stem, include_map):
    text = anon_labels(text)
    lines = text.split("\n")
    out = []
    guard = None
    blocks = []                 # stack of 'if' | 'addr' | 'zone'

    i = 0
    suppress = 0                # inside a dropped !if ... {} assert block
    macro_params = None         # param names while inside a !macro body
    while i < len(lines):
        line = lines[i]
        i += 1

        if suppress:
            suppress += line.count('{') - line.count('}')
            continue

        # ---- macro definition opener -----------------------------------
        m = re.match(r'(\s*)!macro\s+(\w+)\s*(.*?)\s*\{\s*$', line)
        if m:
            name, params = m.group(2), m.group(3)
            macro_params = [p.strip().lstrip('.')
                            for p in params.split(',') if p.strip()]
            blocks.append('macro')
            out.append(f"    MAC {name}")
            continue

        # ---- guard header: !ifdef NAME !eof ----------------------------
        m = re.match(r'\s*!ifdef\s+(\w+)\s+!eof\s*$', line)
        if m:
            guard = m.group(1)
            out.append(f"    IFNCONST {guard}")
            continue

        # ---- !if asserts are dropped whole (config is fixed & valid) ---
        #   one-line  !if c { !error "m" }   and   multi-line  !if c {
        if re.match(r'\s*!if\s+.*\{\s*!error\b.*\}\s*$', line):
            continue
        m = re.match(r'\s*!if\s+.*\{\s*(;.*)?$', line)
        if m:
            suppress = 1
            continue

        # ---- one-line conditionals: push body back through pipeline -----
        # dasm assignments must sit in column 0, so the body is emitted
        # un-indented (these one-liners are always `SYM = value`).
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, kind, name, body, cmt = m.groups()
            dirn = 'IFCONST' if kind == 'ifdef' else 'IFNCONST'
            out.append(f"    {dirn} {name}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            lines[i:i] = [body, "}"]
            continue

        # ---- inline !addr:  !addr sym = expr ---------------------------
        m = re.match(r'(\s*)!addr\s+(\w+\s*=.*)$', line)
        if m:
            out.append(m.group(1) + m.group(2))
            continue

        # ---- zone-local label DEFINITIONS -> renamed globals -----------
        m = re.match(r'^\.([A-Za-z_]\w*)\b[ \t]*(.*)$', line)
        if m:
            name, rest = m.groups()
            out.append(f"{stem}_{name}")
            if rest and not rest.startswith(';'):
                lines.insert(i, "    " + rest)
            continue

        # ---- block openers ---------------------------------------------
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(;.*)?$', line)
        if m:
            ind, kind, name, cmt = m.groups()
            dirn = 'IFCONST' if kind == 'ifdef' else 'IFNCONST'
            out.append(f"    {dirn} {name}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            continue
        if re.match(r'\s*!addr\s*\{\s*(;.*)?$', line):
            out.append("; (!addr block: plain assignments in dasm)")
            blocks.append('addr')
            continue
        m = re.match(r'\s*!zone\s+\w+\s*\{\s*(;.*)?$', line)
        if m:
            out.append("; (zone: file scope in dasm)")
            blocks.append('zone')
            continue

        # ---- closing braces --------------------------------------------
        if re.match(r'\s*\}\s*(;.*)?$', line):
            kind = blocks.pop() if blocks else 'if'
            if kind == 'macro':
                out.append("    ENDM")
                macro_params = None
            elif kind == 'if':
                out.append("    ENDIF")
            else:
                out.append("; (end " + kind + ")")
            continue

        # ---- statement splitting + line-level conversions --------------
        for part in split_statements(line):
            s = part

            # macro parameter refs .name -> {n}  (before zone-local promo)
            if macro_params is not None:
                for idx, p in enumerate(macro_params, start=1):
                    s = re.sub(r'\.(%s)\b' % re.escape(p), '{%d}' % idx, s)

            # zone-local .name -> stem_name (comments too: harmless)
            s = DOT_IDENT.sub(lambda mm: f"{stem}_{mm.group(1)}", s)

            # !error inside a converted !if block: drop to a comment
            m = re.match(r'(\s*)!error\s+(.*)$', s)
            if m:
                out.append(f"{m.group(1)}; x16lib error: {m.group(2)}")
                continue

            # cpu / program-counter / bank-byte (examples & the runner)
            s = re.sub(r'^(\s*)!cpu\s+(\S+)', r'\1    processor \2', s)
            s = re.sub(r'^(\s*)\*\s*=\s*(.+?)(\s*;.*)?$',
                       lambda mm: f"{mm.group(1)}    org {mm.group(2)}" +
                                  (mm.group(3) or ''), s)
            s = re.sub(r'\^\s*\(([^()]*)\)', r'((\1) >> 16)', s)
            s = re.sub(r'\^([A-Za-z_]\w*)', r'(\1 >> 16)', s)

            # char literal:  'X'  ->  'X   (dasm has no closing quote)
            s = re.sub(r"'(.)'", r"'\1", s)

            # data / include directives
            s = re.sub(r'!byte\b', 'dc.b', s)
            s = re.sub(r'!word\b', 'dc.w', s)
            s = re.sub(r'!text\b', 'dc.b', s)
            s = re.sub(r'!fill\s+', 'ds ', s)
            # dasm strings have no escapes: emit an embedded " as a byte
            s = s.replace('\\"', '", $22, "')
            # dasm treats a col0 `include` as a label, so force an indent
            s = re.sub(r'^\s*!source\s+"([^"]+)"',
                       lambda mm: '    include "%s"' % include_map(mm.group(1)), s)
            s = s.replace('>>>', '>>')

            # macro invocation: +name -> name
            s = re.sub(r'^(\s*)\+(\w+)', r'\1\2', s)

            # ACME cheap local @name -> dasm local .name
            s = re.sub(r'@([A-Za-z_]\w*)', r'.\1', s)

            # bare accumulator inc/dec -> ina / dea
            s = re.sub(r'^(\s*)inc(\s*)(;.*)?$',
                       lambda mm: f"{mm.group(1)}ina" +
                                  (('  ' + mm.group(3)) if mm.group(3) else ''), s)
            s = re.sub(r'^(\s*)dec(\s*)(;.*)?$',
                       lambda mm: f"{mm.group(1)}dea" +
                                  (('  ' + mm.group(3)) if mm.group(3) else ''), s)

            out.append(s)

    if guard:
        out.append("    ENDIF")
    return "\n".join(out)


def is_global_label(line):
    """A col0 identifier that names a label (needs a SUBROUTINE before it)."""
    m = re.match(r'([A-Za-z_][\w]*)', line)
    if not m:
        return False
    tok = m.group(1)
    # skip data/directive lines that happen to start at col0
    head = re.match(r'[A-Za-z_][\w.]*', line).group(0)
    if head.upper() in DIRECTIVES or head.split('.')[0].upper() in DIRECTIVES:
        return False
    code = line.split(';', 1)[0]
    if '=' in code:
        return False
    return True


COL0_DIRECTIVE = re.compile(
    r'^(dc\.b|dc\.w|dc|ds|byte|word|include|org|processor|hex|echo|err|'
    r'seg|align|repeat|repend|IF|IFCONST|IFNCONST|ELSE|ENDIF|MAC|ENDM|'
    r'SUBROUTINE)\b', re.IGNORECASE)


def normalize(text):
    """dasm column rules: symbol assignments belong in column 0, every
    other directive must be indented (column 0 == a label)."""
    res = []
    for line in text.split("\n"):
        # indented `SYM = value` -> column 0 (single '=' assignment)
        if re.match(r'\s+[A-Za-z_]\w*\s*=(?![=<>])', line):
            res.append(line.lstrip())
            continue
        # a directive sitting in column 0 -> indent it
        if COL0_DIRECTIVE.match(line):
            res.append("    " + line)
            continue
        res.append(line)
    return "\n".join(res)


def add_subroutines(text):
    """dasm scopes .locals per SUBROUTINE; emit one before each global
    label so .name locals reset exactly at ACME's cheap-local boundaries."""
    res = []
    for line in text.split("\n"):
        if is_global_label(line):
            res.append("    SUBROUTINE")
        res.append(line)
    return "\n".join(res)


# In dasm (as in ca65) a SUBROUTINE/label ends the local scope; there is
# no scope-neutral zone-local. Routines whose cheap @labels cross a
# converted zone-local label therefore get those @labels promoted to
# unique globals, region by region (renamed BEFORE @->.  conversion).
#   file: [(start_label, end_label_or_None, prefix)]
CHEAP_PROMOTE = {
    "audio/pcm.asm":     [("pcm_stream_fill", None, "psf_")],
    "util/tscrunch.asm": [("tsc_decompress", None, "tsc2_")],
    "gfx/bitmap8l.asm":  [("gfx8l_text", "gt8l_code", "gtx8l_")],
    # dasm cannot take a .local as a macro argument (it binds the local to
    # the macro's own scope), and these two runner tests pass @file to the
    # cset16 macro -- so promote their cheap-locals to globals.
    "runner.asm":        [("test_bmx_truncated", "test_bmx_short_pal", "bmt_"),
                          ("test_bmx_short_pal", "test_zx0", "bsp_")],
}


def promote_cheap(text, regions):
    lines = text.split("\n")
    for start, end, prefix in regions:
        s_i = e_i = None
        for idx, ln in enumerate(lines):
            if re.match(r'^%s\b' % re.escape(start), ln) and s_i is None:
                s_i = idx
            elif s_i is not None and end and re.match(r'^%s\b' % re.escape(end), ln):
                e_i = idx
                break
        if s_i is None:
            raise SystemExit(f"promote_cheap: {start} not found")
        e_i = e_i if e_i is not None else len(lines)
        for idx in range(s_i, e_i):
            lines[idx] = re.sub(r'@([A-Za-z_]\w*)',
                                lambda mm: prefix + mm.group(1), lines[idx])
    return "\n".join(lines)


def main():
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])

    def include_map(name):
        return name.replace("test_acme/", "test_dasm/")

    # single-file mode: translate one .asm (an example or the runner)
    if src.is_file():
        text = src.read_text(encoding="ascii", errors="replace")
        if src.name in CHEAP_PROMOTE:
            text = promote_cheap(text, CHEAP_PROMOTE[src.name])
        converted = normalize(add_subroutines(convert(text, src.stem, include_map)))
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(converted, encoding="ascii")
        print(f"conv  {src.name} -> {dst}")
        return

    for f in sorted(src.rglob("*.asm")):
        rel = f.relative_to(src).as_posix()
        if rel in SKIP:
            print(f"skip  {rel} (hand-maintained)")
            continue
        stem = f.stem
        text = f.read_text(encoding="ascii", errors="replace")
        if rel in CHEAP_PROMOTE:                 # rename @locals BEFORE @->.
            text = promote_cheap(text, CHEAP_PROMOTE[rel])
        converted = convert(text, stem, include_map)
        converted = normalize(add_subroutines(converted))
        outp = dst / rel
        outp.parent.mkdir(parents=True, exist_ok=True)
        outp.write_text(converted, encoding="ascii")
        print(f"conv  {rel}")


if __name__ == "__main__":
    main()
