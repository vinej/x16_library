#!/usr/bin/env python3
"""acme2mads.py -- mechanical ACME -> MADS (Mad Assembler) conversion for x16lib.

src_acme/ stays the reference implementation. Four dialect files are
maintained by hand (SKIP below): the root include (x16.asm -- sets the
CPU/output options MADS needs), the macro layer (core/macros.asm), the
math tables (util/math.asm -- ACME builds them with compile-time float
functions MADS lacks, so they are baked as literal bytes), and
x16_code.asm (the module gate/dependency block).

Every generated file is held to the same bar as the other ports: the
test runner assembles to a byte-identical PRG (same SHA-256) as the ACME
build and passes the same suite on the emulator.

MADS specifics this converter relies on (all probed against mads 2.1.7):
  !source "f"            -> icl "f"              (MADS include; -i: path)
  !zone n { ... }        -> dropped              (? locals auto-scope)
  @cheap                 -> ?cheap               (MADS local labels)
  .zonelocal             -> stem_zonelocal       (file-unique globals)
  !ifdef X {  ... }      -> .if .def X ... .endif
  !ifndef X { ... }      -> .if !.def X ... .endif
  !if expr { ... }       -> .if expr ... .endif
  !ifndef N { N = v }    -> .if !.def N / N = v / .endif
  !addr X = v            -> X = v
  !byte / !word          -> .byte / .word        (negatives are native)
  !text "s", $b          -> dta c's', $b         (raw ASCII, no PETSCII)
  !fill n, v             -> :(n) dta v            (emits real bytes)
  !error "m"             -> .error "m"
  +macro args            -> macro args
  a : b (inline stmts)   -> split onto two lines  (MADS has no ' : ')
  >>>                    -> >>
"""
import re
import sys
from pathlib import Path

SKIP = {
    "x16.asm",
    "core/macros.asm",
    "util/math.asm",
}

DOT_IDENT = re.compile(r'(?<![\w!$.:])\.([A-Za-z_][A-Za-z0-9_]*)')

# MADS ?-prefixed locals resolve to the last/next definition, not to the
# enclosing label, so they cannot stand in for ACME's @cheap labels once
# a forward branch is involved. Instead each @name is renamed to a global
# unique to the routine it lives in: <last real label>__<name>. That is
# exactly ACME's rule (a cheap label belongs to the preceding non-local
# symbol), so a @loop under two routines becomes two distinct globals and
# a zone-local .label in between -- rendered as its own global -- does not
# capture the following @cheap labels (it is not a "real" owner here).
CHEAP_SEP = "__"


def split_statements(line):
    """ACME allows `lda #0 : sta X`; MADS does not, so break them up."""
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


def convert_text(part):
    """ACME !text "s", $b, ... -> MADS dta c's', $b, ... (raw ASCII)."""
    m = re.match(r'(\s*(?:[A-Za-z_]\w*\s+)?)!text\s+(.*)$', part)
    if not m:
        return part
    lead, rest = m.groups()
    # peel off a trailing comment (a ';' outside quotes) so it does not
    # get glued onto the last item and defeat the string test below
    code, comment, inq = "", "", False
    for idx, ch in enumerate(rest):
        if ch == '"':
            inq = not inq
        if ch == ';' and not inq:
            code, comment = rest[:idx], rest[idx:]
            break
    else:
        code = rest
    # split on commas not inside quotes
    items, cur, inq = [], "", False
    for ch in code:
        if ch == '"':
            inq = not inq
        if ch == ',' and not inq:
            items.append(cur.strip())
            cur = ""
            continue
        cur += ch
    if cur.strip():
        items.append(cur.strip())
    conv = []
    for it in items:
        if it.startswith('"') and it.endswith('"'):
            conv.append("c'" + it[1:-1] + "'")   # ASCII string, no PETSCII
        else:
            conv.append(it)
    tail = ('  ' + comment) if comment else ''
    return f"{lead}dta " + ", ".join(conv) + tail


def convert(text, stem, include_map):
    lines = text.split("\n")
    out = []
    macro_params = None
    blocks = []
    cur_global = stem       # owner of the current @cheap labels

    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1

        # include guard header: keep MADS to one inclusion per file instead
        m = re.match(r'\s*!ifdef\s+(\w+)\s+!eof\s*$', line)
        if m:
            out.append("; (ACME include guard dropped: icl this file once)")
            if i < len(lines) and re.match(r'\s*%s\s*=\s*1' % m.group(1), lines[i]):
                i += 1
            continue

        # !cpu: x16.asm sets `opt c+` instead
        if re.match(r'\s*!cpu\b', line):
            continue

        # * = $XXXX  ->  org $XXXX  (MADS's *= does not set the PC symbol)
        m = re.match(r'(\s*)\*\s*=\s*(.+?)(\s*;.*)?$', line)
        if m:
            ind, addr, cmt = m.groups()
            out.append(f"{ind or '    '}org {addr}" + (('  ' + cmt.lstrip()) if cmt else ''))
            continue

        # one-line !ifndef N { N = v }  ->  guarded default
        m = re.match(r'(\s*)!ifndef\s+(\w+)\s*\{\s*\2\s*=\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, name, val, cmt = m.groups()
            out.append(f"{ind}.if !.def {name}{' ' + cmt if cmt else ''}")
            out.append(f"{ind}{name} = {val}")
            out.append(f"{ind}.endif")
            continue

        # one-line !if cond { !error "m" }
        m = re.match(r'(\s*)!if\s+(.*?)\s*\{\s*!error\s+(".*?")\s*\}\s*$', line)
        if m:
            ind, cond, msg = m.groups()
            out.append(f"{ind}.if {cond}")
            out.append(f"{ind}    .error {msg}")
            out.append(f"{ind}.endif")
            continue

        # other one-line conditionals: reprocess the body on its own line
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, kind, name, body, cmt = m.groups()
            neg = "!" if kind == "ifndef" else ""
            out.append(f"{ind}.if {neg}.def {name}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            # MADS reads a bare word (icl, dta, ...) in column 1 as a label,
            # so the reprocessed body must be indented.
            lines[i:i] = [f"{ind}    {body}", f"{ind}}}"]
            continue

        # !addr X = expr  ->  plain assignment
        m = re.match(r'(\s*)!addr\s+(\w+\s*=.*)$', line)
        if m:
            out.append(m.group(1) + m.group(2))
            continue

        # !addr { ... }  ->  a plain group of assignments; drop the wrapper
        if re.match(r'\s*!addr\s*\{\s*(;.*)?$', line):
            blocks.append('addr')
            continue

        # zone-local label definition -> renamed file-unique global
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
            out.append(f"{ind}.if {neg}.def {name}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            continue
        m = re.match(r'(\s*)!if\s+(.*?)\s*\{\s*(;.*)?$', line)
        if m:
            ind, cond, cmt = m.groups()
            out.append(f"{ind}.if {cond}{' ' + cmt if cmt else ''}")
            blocks.append('if')
            continue
        if re.match(r'\s*!zone(\s+\w+)?\s*\{\s*(;.*)?$', line):
            blocks.append('zone')
            continue

        # macro definition (testlib may carry some; the library's own live
        # in the hand-written core/macros.asm)
        m = re.match(r'(\s*)!macro\s+(\w+)\s*(.*?)\s*\{\s*$', line)
        if m:
            ind, name, params = m.groups()
            plist = [p.strip().lstrip('.') for p in params.split(',') if p.strip()]
            macro_params = plist
            blocks.append('macro')
            out.append(f"{ind}.macro {name} {', '.join(plist)}".rstrip())
            continue

        # closing braces
        if re.match(r'\s*\}\s*(;.*)?$', line):
            kind = blocks.pop() if blocks else 'if'
            if kind == 'macro':
                out.append("    .endm")
                macro_params = None
            elif kind == 'if':
                out.append(".endif")
            # 'zone' opens/closes nothing in MADS
            continue

        # a real (column-1, non-cheap) label owns the @cheap labels that
        # follow it; zone-locals were already handled above and never reach
        # here, so they cannot become owners.
        lead = re.match(r'^([A-Za-z_]\w*)\b', line)
        if lead:
            cur_global = lead.group(1)

        for part in split_statements(line):
            s = part

            # cheap locals first (@x -> <owner>__x), so a @label sitting in
            # front of !text or data is already a normal identifier for the
            # checks below. No macro body in the tree uses @cheap labels, so
            # this never collides with a macro parameter.
            s = re.sub(r'@([A-Za-z_]\w*)',
                       lambda mm: f"{cur_global}{CHEAP_SEP}{mm.group(1)}", s)

            if s.lstrip().startswith('!text') or re.match(r'\s*[A-Za-z_]\w*\s+!text\b', s):
                out.append(convert_text(s))
                continue

            if macro_params is not None:
                for p in macro_params:
                    s = re.sub(r'\.(%s)\b' % re.escape(p), r':\1', s)
            s = DOT_IDENT.sub(lambda mm: f"{stem}_{mm.group(1)}", s)

            # !fill count, val  ->  :(count) dta val   (emits real bytes)
            m = re.match(r'(\s*)([A-Za-z_]\w*)?\s*!fill\s+(.*?)\s*(;.*)?$', s)
            if m:
                ind, label, args, cmt = m.groups()
                argl = [a.strip() for a in args.split(',')]
                count = argl[0]
                val = argl[1] if len(argl) > 1 else "0"
                if label:
                    out.append(f"{label}")
                tail = ('  ' + cmt) if cmt else ''
                out.append(f"    :({count}) dta {val}{tail}")
                continue

            s = re.sub(r'!byte\b', '.byte', s)
            s = re.sub(r'!word\b', '.word', s)
            # icl in column 1 reads as a label, so keep it indented.
            s = re.sub(r'^(\s*)!source\s+"([^"]+)"',
                       lambda mm: (mm.group(1) or '    ') + 'icl "%s"' % include_map(mm.group(2)),
                       s)
            s = re.sub(r'!error\b', '.error', s)
            s = s.replace('>>>', '>>')

            # macro invocation: +name a, b -> name a,b
            # ACME splits the argument list on commas; MADS splits on
            # whitespace first, so every space in the arguments has to go
            # (a comment is kept, its leading space restored).
            m = re.match(r'^(\s*)\+(\w+)\s+(.*?)(\s*;.*)?$', s)
            if m:
                ind, name, args, cmt = m.groups()
                args = re.sub(r'\s+', '', args)
                s = f"{ind}{name} {args}" + (('  ' + cmt.lstrip()) if cmt else '')
            else:
                s = re.sub(r'^(\s*)\+(\w+)\s*(;.*)?$',
                           lambda mm: f"{mm.group(1)}{mm.group(2)}" +
                                      (('  ' + mm.group(3)) if mm.group(3) else ''), s)

            out.append(s)

    return "\n".join(out)


def main():
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])

    def include_map(name):
        return name.replace("test_acme/", "test_mads/")

    for f in sorted(src.rglob("*.asm")):
        rel = f.relative_to(src).as_posix()
        if rel in SKIP:
            print(f"skip  {rel} (hand-maintained)")
            continue
        text = f.read_text(encoding="ascii", errors="replace")
        converted = convert(text, f.stem, include_map)
        outp = dst / rel
        outp.parent.mkdir(parents=True, exist_ok=True)
        outp.write_text(converted, encoding="ascii")
        print(f"conv  {rel}")


if __name__ == "__main__":
    main()
