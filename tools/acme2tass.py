#!/usr/bin/env python3
"""acme2tass.py -- mechanical ACME -> 64tass dialect conversion for x16lib.

src_acme/ stays the reference implementation. Hand-maintained files
(SKIP below) carry the pieces 64tass expresses differently: the root
include (cpu + a raw byte encoding), the macro layer, the math tables,
and x16_code.asm (definedness gates become value gates over .weak
defaults).

Assemble the result CASE-SENSITIVE (-C) and with -a: both are part of
the dialect here.

Rules beyond the ca65 converter's:
  @cheap      -> _cheap      (64tass local labels)
  +macro      -> #macro
  ^expr       -> `expr       (bank byte; ^ means decimal-string in 64tass)
  !ifdef X16_USE_N { -> .if xuse_n   (values computed in x16_code.asm)
  !ifndef N { N = v } -> .weak / N = v / .endweak
  guard headers        -> dropped (include each file once)
  !macro n .a { ... }  -> n .macro a ... .endm   (.a -> \a)
"""
import re
import sys
from pathlib import Path

SKIP = {
    "x16.asm",
    "core/macros.asm",
    "util/math.asm",
    "x16_code.asm",
}

DOT_IDENT = re.compile(r'(?<![\w!$.])\.([A-Za-z_][A-Za-z0-9_]*)')

# Same scope problem as ca65: a (renamed) zone-local label definition
# inside a routine ends the _local scope, so the crossing locals are
# promoted to uniquely named globals first.
CHEAP_PROMOTE = {
    "audio/pcm.asm":     [("pcm_stream_fill", None, "psf_")],
    "util/tscrunch.asm": [("tsc_decompress", None, "tsc2_")],
    "gfx/bitmap.asm":    [("gfx_text", "gt_code", "gtx_")],
}


def split_statements(line):
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


def bank_op(s):
    """^ is 64tass's decimal-string operator; the bank byte is a backtick."""
    return re.sub(r'\^(?=[\w($])', '`', s)


def convert(text, stem, include_map):
    lines = text.split("\n")
    out = []
    macro_params = None
    blocks = []

    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1

        # guard headers: include-once discipline instead
        m = re.match(r'\s*!ifdef\s+(\w+)\s+!eof\s*$', line)
        if m:
            out.append("; (ACME include guard dropped: include this file once)")
            if i < len(lines) and re.match(r'\s*%s\s*=\s*1' % m.group(1), lines[i]):
                i += 1
            continue

        # !cpu: the root include sets it
        if re.match(r'\s*!cpu\b', line):
            continue

        # one-line !ifndef N { N = v }  ->  .weak default
        m = re.match(r'(\s*)!ifndef\s+(\w+)\s*\{\s*\2\s*=\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, name, val, cmt = m.groups()
            out.append(f"{ind}.weak{' ' + cmt if cmt else ''}")
            out.append(f"{ind}{name} = {val}")
            out.append(f"{ind}.endweak")
            continue

        # other one-line conditionals: reprocess the body
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, kind, name, body, cmt = m.groups()
            neg = "!" if kind == "ifndef" else ""
            cond = gate_expr(name)
            out.append(f"{ind}.if {neg}{cond}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            lines[i:i] = [f"{ind}{body}", f"{ind}}}"]
            continue

        m = re.match(r'(\s*)!if\s+(.*?)\s*\{\s*!error\s+(".*?")\s*\}\s*$', line)
        if m:
            ind, cond, msg = m.groups()
            out.append(f"{ind}.cerror {cond}, {msg}")
            continue

        m = re.match(r'(\s*)!addr\s+(\w+\s*=.*)$', line)
        if m:
            out.append(m.group(1) + m.group(2))
            continue

        # zone-local label definitions -> renamed plain labels
        m = re.match(r'^\.([A-Za-z_]\w*)\b[ \t]*(.*)$', line)
        if m and macro_params is None:
            name, rest = m.groups()
            out.append(f"{stem}_{name}")
            if rest and not rest.startswith(';'):
                lines.insert(i, "    " + rest)
            continue

        # block openers
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(;.*)?$', line)
        if m:
            ind, kind, name, cmt = m.groups()
            neg = "!" if kind == "ifndef" else ""
            out.append(f"{ind}.if {neg}{gate_expr(name)}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            continue
        m = re.match(r'(\s*)!if\s+(.*?)\s*\{\s*(;.*)?$', line)
        if m:
            ind, cond, cmt = m.groups()
            out.append(f"{ind}.if {cond}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            continue
        if re.match(r'\s*!addr\s*\{\s*(;.*)?$', line):
            out.append("; (!addr block: plain assignments in 64tass)")
            blocks.append('addr')
            continue
        if re.match(r'\s*!zone\s+\w+\s*\{\s*(;.*)?$', line):
            out.append("; (zone: file scope in 64tass)")
            blocks.append('zone')
            continue

        # macro definitions
        # .segment, not .macro: identical, but expands WITHOUT opening a
        # new scope -- so _local labels passed as arguments still resolve
        # in the caller, exactly like ACME's textual macro expansion.
        m = re.match(r'(\s*)!macro\s+(\w+)\s*(.*?)\s*\{\s*$', line)
        if m:
            ind, name, params = m.groups()
            plist = [p.strip().lstrip('.') for p in params.split(',') if p.strip()]
            macro_params = plist
            blocks.append('macro')
            out.append(f"{name} .segment {', '.join(plist)}")
            continue

        # closing braces
        if re.match(r'\s*\}\s*(;.*)?$', line):
            kind = blocks.pop() if blocks else 'if'
            if kind == 'macro':
                out.append("    .endm")
                macro_params = None
            elif kind == 'if':
                out.append(".endif")
            else:
                out.append("; (end " + kind + ")")
            continue

        for part in split_statements(line):
            s = part

            if macro_params is not None:
                for p in macro_params:
                    s = re.sub(r'\.(%s)\b' % re.escape(p), r'\\\1', s)
                # #(\p) with an already-parenthesized argument would give
                # #((x)), which 64tass parses as indirect immediate
                s = re.sub(r'#\((\\\w+)\)', r'#\1', s)
            s = DOT_IDENT.sub(lambda mm: f"{stem}_{mm.group(1)}", s)

            s = re.sub(r'!byte\b', '.byte', s)
            s = re.sub(r'!word\b', '.word', s)
            s = re.sub(r'!text\b', '.text', s)
            s = re.sub(r'!fill\b', '.fill', s)
            s = re.sub(r'!source\s+"([^"]+)"',
                       lambda mm: '.include "%s"' % include_map(mm.group(1)), s)
            s = s.replace('>>>', '>>')
            s = bank_op(s)

            # macro invocation: +name -> #name
            s = re.sub(r'^(\s*)\+(\w+)', r'\1#\2', s)

            # bare accumulator inc/dec
            s = re.sub(r'^(\s*)(inc|dec)\s*(;.*)?$',
                       lambda mm: f"{mm.group(1)}{mm.group(2)} a" +
                                  (('  ' + mm.group(3)) if mm.group(3) else ''), s)

            # cheap locals: @x -> _x (64tass local labels)
            s = re.sub(r'@([A-Za-z_]\w*)', r'_\1', s)

            # .byte refuses negatives in 64tass
            if re.match(r'\s*(_?\w+\s+)?\.byte\b', s):
                code = s.split(';', 1)[0]
                cmt = s[len(code):]
                code = re.sub(r'(?<=[\s,e])-(\d+)\b',
                              lambda mm: '$%02X' % ((256 - int(mm.group(1))) & 0xFF),
                              code)
                s = code + cmt

            out.append(s)

    return "\n".join(out)


def gate_expr(name):
    """Definedness tests on X16_USE_* become value tests on xuse_*."""
    m = re.match(r'X16_USE_(\w+)$', name)
    if m:
        return "xuse_" + m.group(1).lower()
    return name + " != 0"       # T_ZP-style guards never reach here


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
        # 64tass resolves .include relative to the including file, so the
        # runner reaches its testlib.asm by bare name, not tree path.
        return name.replace("test_acme/", "")

    for f in sorted(src.rglob("*.asm")):
        rel = f.relative_to(src).as_posix()
        if rel in SKIP:
            print(f"skip  {rel} (hand-maintained)")
            continue
        text = f.read_text(encoding="ascii", errors="replace")
        if rel in CHEAP_PROMOTE:
            text = promote_cheap(text, CHEAP_PROMOTE[rel])
        converted = convert(text, f.stem, include_map)
        outp = dst / rel
        outp.parent.mkdir(parents=True, exist_ok=True)
        outp.write_text(converted, encoding="ascii")
        print(f"conv  {rel}")


if __name__ == "__main__":
    main()
