#!/usr/bin/env python3
"""acme2ca65.py -- mechanical ACME -> ca65 dialect conversion for x16lib.

The ACME tree stays the reference implementation; this converts the
regular subset it uses. Files with ACME-only features (the macro layer,
the assembler-computed math tables, the root include) are maintained by
hand in src_ca65/ and listed in SKIP.

Rules:
  !byte/!word/!text  -> .byte/.word/.byte
  !fill n, v         -> .res n, v
  !source "x"        -> .include "x"
  !zone n { ... }    -> dropped (zone-local .name -> <stem>_name)
  !ifdef/!ifndef X { -> .ifdef/.ifndef X   (closing } -> .endif)
  one-line !ifndef X { X = 1 }             -> three lines
  !if c { !error "m" }                     -> .if c / .error "m" / .endif
  !addr { ... }      -> dropped
  guard header  !ifdef N !eof / N = 1      -> .ifndef N / N = 1 ... .endif
  !macro name .a, .b { ... }               -> .macro name p_a, p_b ... .endmacro
  +macro args        -> macro args
  ' : '-separated statements               -> split lines
  bare inc/dec (accumulator)               -> inc a / dec a
  >>>                                      -> >>
"""
import re
import sys
from pathlib import Path

SKIP = {
    "x16.asm",            # hand-written root include
    "core/macros.asm",    # hand-ported macro layer (dist template)
    "util/math.asm",      # !for-computed tables: hand-generated
}

DOT_IDENT = re.compile(r'(?<![\w!$.])\.([A-Za-z_][A-Za-z0-9_]*)')

# ACME's only anonymous-label form in this tree: a single forward '+',
# defined as "+<tab><insn>" and referenced by one branch above it. ca65
# has a native equivalent -- the unnamed ':' label, referenced ':+' --
# which, unlike a named label, does not end the @cheap scope around it.
ANON_DEF = re.compile(r'^\+[ \t]+(.*)$')
ANON_REF = re.compile(
    r'^([ \t]*(?:bne|beq|bcc|bcs|bmi|bpl|bra|bvc|bvs|jmp)[ \t]+)\+[ \t]*$')

def anon_labels(text):
    out = []
    for ln in text.split("\n"):
        d = ANON_DEF.match(ln)
        if d:
            out.append(":\t" + d.group(1))
            continue
        r = ANON_REF.match(ln)
        if r:
            out.append(r.group(1) + ":+")
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
            # keep the indentation of the first fragment
            continue
        cur += c
        i += 1
    out.append(cur)
    if len(out) == 1:
        return [line]
    indent = re.match(r'\s*', out[0]).group(0)
    return [out[0]] + [indent + frag.strip() for frag in out[1:]]


def fix_negative_bytes(s):
    """ca65's .byte refuses negatives; ACME allowed -128..-1 in tables."""
    if not re.match(r'\s*(@?\w+\s+)?\.byte\b', s):
        return s
    code = s.split(';', 1)[0]
    cmt = s[len(code):]
    code = re.sub(r'(?<=[\s,e])-(\d+)\b',
                  lambda mm: '$%02X' % ((256 - int(mm.group(1))) & 0xFF),
                  code)
    return code + cmt


def convert(text, stem, include_map):
    text = anon_labels(text)
    lines = text.split("\n")
    out = []
    guard = None
    macro_params = None
    blocks = []                 # stack of 'if' | 'addr' | 'zone' | 'macro'

    i = 0
    while i < len(lines):
        raw = lines[i]
        i += 1
        line = raw

        # ---- guard header: !ifdef NAME !eof ----------------------------
        m = re.match(r'\s*!ifdef\s+(\w+)\s+!eof\s*$', line)
        if m:
            guard = m.group(1)
            out.append(f".ifndef {guard}")
            continue

        # ---- one-line conditionals -------------------------------------
        # The body is pushed back into the stream so nested one-liners
        # and !source bodies go through the full pipeline themselves.
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, kind, name, body, cmt = m.groups()
            out.append(f"{ind}.{kind} {name}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            lines[i:i] = [f"{ind}{body}", f"{ind}}}"]
            continue
        m = re.match(r'(\s*)!if\s+(.*?)\s*\{\s*!error\s+(".*?")\s*\}\s*$', line)
        if m:
            ind, cond, msg = m.groups()
            out.append(f"{ind}.if {cond}")
            out.append(f"{ind}.error {msg}")
            out.append(f"{ind}.endif")
            continue

        # ---- inline !addr ------------------------------------------------
        m = re.match(r'(\s*)!addr\s+(\w+\s*=.*)$', line)
        if m:
            out.append(m.group(1) + m.group(2))
            continue

        # ---- test/example skeleton lines ----------------------------------
        # !cpu: the root include sets it. * = addr: ca65 places code by
        # linker segment (see runner.cfg), the load address is data.
        if re.match(r'\s*!cpu\b', line):
            continue
        m = re.match(r'\s*\*\s*=\s*(\$?\w+)\s*(;.*)?$', line)
        if m:
            out.append('.segment "LOADADDR"')
            out.append(f"    .word {m.group(1)}")
            out.append('.segment "CODE"')
            continue

        # ---- zone-local label DEFINITIONS ---------------------------------
        # Become ordinary (renamed) labels. In ca65 every definition ends
        # the cheap-local scope, so routines whose @labels cross one of
        # these get their @labels promoted to globals (CHEAP_PROMOTE).
        m = re.match(r'^\.([A-Za-z_]\w*)\b[ \t]*(.*)$', line)
        if m and macro_params is None:
            name, rest = m.groups()
            out.append(f"{stem}_{name}")
            if rest and not rest.startswith(';'):
                lines.insert(i, "    " + rest)
            continue

        # ---- block openers ----------------------------------------------
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(;.*)?$', line)
        if m:
            ind, kind, name, cmt = m.groups()
            out.append(f"{ind}.{kind} {name}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            continue
        m = re.match(r'(\s*)!if\s+(.*?)\s*\{\s*(;.*)?$', line)
        if m:
            ind, cond, cmt = m.groups()
            out.append(f"{ind}.if {cond}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            continue
        if re.match(r'\s*!addr\s*\{\s*(;.*)?$', line):
            out.append("; (!addr block: plain assignments in ca65)")
            blocks.append('addr')
            continue
        m = re.match(r'\s*!zone\s+\w+\s*\{\s*(;.*)?$', line)
        if m:
            out.append("; (zone: file scope in ca65)")
            blocks.append('zone')
            continue

        # ---- macro definitions -------------------------------------------
        m = re.match(r'(\s*)!macro\s+(\w+)\s*(.*?)\s*\{\s*$', line)
        if m:
            ind, name, params = m.groups()
            plist = [p.strip().lstrip('.') for p in params.split(',') if p.strip()]
            macro_params = plist
            blocks.append('macro')
            rendered = ", ".join("p_" + p for p in plist)
            out.append(f"{ind}.macro {name}{' ' + rendered if rendered else ''}")
            continue

        # ---- closing braces ------------------------------------------------
        if re.match(r'\s*\}\s*(;.*)?$', line):
            kind = blocks.pop() if blocks else 'if'
            if kind == 'macro':
                out.append(".endmacro")
                macro_params = None
            elif kind == 'if':
                out.append(".endif")
            else:
                out.append("; (end " + kind + ")")
            continue

        # ---- statement splitting -----------------------------------------
        for part in split_statements(line):
            s = part

            # FIRST, while every '.ident' in the source can only be an
            # ACME zone-local (directives are still !-prefixed):
            # macro parameter references inside a definition...
            if macro_params is not None:
                for p in macro_params:
                    s = re.sub(r'\.(%s)\b' % re.escape(p), r'p_\1', s)
            # ...then zone-local .name -> stem_name (comments too: harmless)
            s = DOT_IDENT.sub(lambda mm: f"{stem}_{mm.group(1)}", s)

            # NOW the directive conversions
            s = re.sub(r'!byte\b', '.byte', s)
            s = re.sub(r'!word\b', '.word', s)
            s = re.sub(r'!text\b', '.byte', s)
            s = re.sub(r'!fill\s+', '.res ', s)
            s = re.sub(r'!source\s+"([^"]+)"',
                       lambda mm: '.include "%s"' % include_map(mm.group(1)), s)
            s = s.replace('>>>', '>>')

            # macro invocation: +name -> name
            s = re.sub(r'^(\s*)\+(\w+)', r'\1\2', s)

            # bare accumulator inc/dec
            s = re.sub(r'^(\s*)(inc|dec)\s*(;.*)?$',
                       lambda mm: f"{mm.group(1)}{mm.group(2)} a" +
                                  (('  ' + mm.group(3)) if mm.group(3) else ''), s)

            # negative table bytes
            s = fix_negative_bytes(s)

            out.append(s)

    if guard:
        out.append(".endif")
    return "\n".join(out)


# In ca65, ANY symbol definition ends the cheap-local scope -- there is
# no equivalent of ACME's scope-neutral zone-locals. Routines whose
# cheap @labels cross a converted zone-local label therefore get those
# @labels promoted to unique globals, region by region.
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
        # ca65 resolves .include relative to the including file (not the
        # cwd), so the runner reaches its testlib.asm by bare name.
        return name.replace("test_acme/", "")

    for f in sorted(src.rglob("*.asm")):
        rel = f.relative_to(src).as_posix()
        if rel in SKIP:
            print(f"skip  {rel} (hand-maintained)")
            continue
        stem = f.stem
        text = f.read_text(encoding="ascii", errors="replace")
        converted = convert(text, stem, include_map)
        if rel in CHEAP_PROMOTE:
            converted = promote_cheap(converted, CHEAP_PROMOTE[rel])
        outp = dst / rel
        outp.parent.mkdir(parents=True, exist_ok=True)
        outp.write_text(converted, encoding="ascii")
        print(f"conv  {rel}")


if __name__ == "__main__":
    main()
