#!/usr/bin/env python3
"""acme2vasm.py -- mechanical ACME -> vasm dialect conversion for x16lib.

The ACME tree stays the reference implementation; this converts the
regular subset it uses. Files with ACME-only features (the macro layer,
the assembler-computed math tables, the root include) are maintained by
hand in src_vasm/ and listed in SKIP.

Target: vasm6502_oldstyle (vasm 2.0+, oldstyle syntax module). vasm is
the friendliest port so far because its `.name` local labels are scoped
between two global labels -- exactly ACME's `@name` cheap-local tier --
and they may even be passed as macro arguments. So @name maps to .name
one for one, with no SUBROUTINE-style scaffolding.

ACME's OTHER local tier (`.name` zone locals, file-scoped here because
every file is one !zone) has no vasm equivalent, so those are promoted
to unique `stem_name` globals, same as the ca65/dasm ports. A promoted
zone-local is a global label and therefore ENDS a vasm local scope; the
three files whose @locals cross a zone-local (CHEAP_PROMOTE) get those
@locals promoted to globals too, region by region.

Directive mapping:
  !byte/!word/!text  -> byte / word / byte     (vasm strings are raw ASCII)
  !fill n[, v]       -> blk n[, v]
  !source "x"        -> include "x"
  !zone n { ... }    -> dropped
  !addr { ... }      -> dropped (plain assignments)
  !ifdef/!ifndef X { -> ifdef/ifndef X         (closing } -> endif)
  one-line !ifndef X { X = 1 }                 -> three lines
  !if c { !error m } -> dropped (compile-time assert; config is fixed)
  guard  !ifdef N !eof / N = 1  -> ifndef N / N = 1 ... endif
  !macro name .a, .b {  -> macro name          (.a/.b -> \\1/\\2, } -> endm)
  !cpu 65c02         -> dropped (vasm selects 65C02 with -c02)
  ' : '-separated statements                   -> split lines
  ^expr (bank byte)  -> (expr) >> 16
  >>>                -> >>
  \\" inside strings  -> ", $22, "
Bare accumulator inc/dec, 'X' char literals and #<(...)/#>(...) all
assemble unchanged.
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
    blocks = []                 # stack of 'if' | 'addr' | 'zone' | 'macro'

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
            out.append(f"    macro {name}")
            continue

        # ---- guard header: !ifdef NAME !eof ----------------------------
        m = re.match(r'\s*!ifdef\s+(\w+)\s+!eof\s*$', line)
        if m:
            guard = m.group(1)
            out.append(f"    ifndef {guard}")
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
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, kind, name, body, cmt = m.groups()
            dirn = 'ifdef' if kind == 'ifdef' else 'ifndef'
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
            dirn = 'ifdef' if kind == 'ifdef' else 'ifndef'
            out.append(f"    {dirn} {name}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            continue
        if re.match(r'\s*!addr\s*\{\s*(;.*)?$', line):
            out.append("; (!addr block: plain assignments in vasm)")
            blocks.append('addr')
            continue
        m = re.match(r'\s*!zone\s+\w+\s*\{\s*(;.*)?$', line)
        if m:
            out.append("; (zone: locals promoted to globals in vasm)")
            blocks.append('zone')
            continue

        # ---- closing braces --------------------------------------------
        if re.match(r'\s*\}\s*(;.*)?$', line):
            kind = blocks.pop() if blocks else 'if'
            if kind == 'macro':
                out.append("    endm")
                macro_params = None
            elif kind == 'if':
                out.append("    endif")
            else:
                out.append("; (end " + kind + ")")
            continue

        # ---- statement splitting + line-level conversions --------------
        for part in split_statements(line):
            s = part

            # macro parameter refs .name -> \n  (before zone-local promo)
            if macro_params is not None:
                for idx, p in enumerate(macro_params, start=1):
                    s = re.sub(r'\.(%s)\b' % re.escape(p), '\\\\%d' % idx, s)

            # zone-local .name -> stem_name (comments too: harmless)
            s = DOT_IDENT.sub(lambda mm: f"{stem}_{mm.group(1)}", s)

            # !error inside a converted !if block: drop to a comment
            m = re.match(r'(\s*)!error\s+(.*)$', s)
            if m:
                out.append(f"{m.group(1)}; x16lib error: {m.group(2)}")
                continue

            # cpu (vasm: -c02 on the command line) / program counter / ^
            s = re.sub(r'^(\s*)!cpu\s+(\S+)',
                       r'\1; (cpu \2: vasm needs -c02 on the command line)', s)
            s = re.sub(r'^(\s*)\*\s*=\s*(.+?)(\s*;.*)?$',
                       lambda mm: f"{mm.group(1)}    org {mm.group(2)}" +
                                  (mm.group(3) or ''), s)
            s = re.sub(r'\^\s*\(([^()]*)\)', r'((\1) >> 16)', s)
            s = re.sub(r'\^([A-Za-z_]\w*)', r'(\1 >> 16)', s)

            # data / include directives
            s = re.sub(r'!byte\b', 'byte', s)
            s = re.sub(r'!word\b', 'word', s)
            s = re.sub(r'!text\b', 'byte', s)
            s = re.sub(r'!fill\s+', 'blk ', s)
            # vasm strings have no escapes: emit an embedded " as a byte
            s = s.replace('\\"', '", $22, "')
            s = re.sub(r'^\s*!source\s+"([^"]+)"',
                       lambda mm: '    include "%s"' % include_map(mm.group(1)), s)
            s = s.replace('>>>', '>>')

            # macro invocation: +name -> name
            s = re.sub(r'^(\s*)\+(\w+)', r'\1\2', s)

            # ACME cheap local @name -> vasm local .name (1:1 semantics)
            s = re.sub(r'@([A-Za-z_]\w*)', r'.\1', s)

            out.append(s)

    if guard:
        out.append("    endif")
    return "\n".join(out)


# A promoted zone-local is a global label in vasm and ends the local
# scope. Routines whose cheap @labels cross a converted zone-local
# therefore get those @labels promoted to unique globals, region by
# region (renamed BEFORE the @ -> . conversion).
#   file: [(start_label, end_label_or_None, prefix)]
CHEAP_PROMOTE = {
    "audio/pcm.asm":     [("pcm_stream_fill", None, "psf_")],
    "util/tscrunch.asm": [("tsc_decompress", None, "tsc2_")],
    "gfx/bitmap.asm":    [("gfx_text", "gt_code", "gtx_")],
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
        return name.replace("test_acme/", "test_vasm/")

    # single-file mode: translate one .asm (an example or the runner)
    if src.is_file():
        text = src.read_text(encoding="ascii", errors="replace")
        if src.name in CHEAP_PROMOTE:
            text = promote_cheap(text, CHEAP_PROMOTE[src.name])
        converted = convert(text, src.stem, include_map)
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
        outp = dst / rel
        outp.parent.mkdir(parents=True, exist_ok=True)
        outp.write_text(converted, encoding="ascii")
        print(f"conv  {rel}")


if __name__ == "__main__":
    main()
