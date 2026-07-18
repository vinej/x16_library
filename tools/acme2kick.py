#!/usr/bin/env python3
"""acme2kick.py -- mechanical ACME -> KickAssembler conversion for x16lib.

src_acme/ stays the reference implementation. KickAssembler is the most
distant dialect of the four:

  ; comments            -> //
  labels                -> name:            (colon required)
  @cheap                -> <routine>__cheap (unique globals; KickAss has
                           no ACME-style scoped locals at file level)
  .zonelocal            -> <stem>_name
  NAME = expr           -> .label NAME = expr (.label, not .const:
                           it resolves like a label, so forward
                           references keep working as they do in ACME)
  X16_USE_N = 1         -> #define X16_USE_N        (preprocessor gates)
  !ifdef X16_USE_N {    -> #if X16_USE_N ... #endif
  !ifndef N { N = v }   -> #if !N_SET / .const N = v / #endif
  guard headers         -> #importonce
  !text "S", 0          -> .text "S" / .byte 0      (no mixed args)
  !fill n, v            -> .fill n, v
  !source               -> #import
  +macro a, b           -> macro(a, b)
  !macro n .a { }       -> .macro n(a) { }
  ^expr                 -> ((expr) >> 16)           (bank byte)
  * = $0801             -> .pc = $0801 "code"

Hand-maintained (SKIP): x16.asm, core/macros.asm, util/math.asm.
"""
import re
import sys
from pathlib import Path

SKIP = {
    "x16.asm",
    "core/macros.asm",
    "util/math.asm",
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

DEFAULTABLE = {"X16_ZP", "T_ZP", "VRAM_FX_SCRATCH"}


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


def conv_comment(s):
    """; -> // outside of double quotes."""
    out, inq = [], False
    i = 0
    while i < len(s):
        c = s[i]
        if c == '"':
            inq = not inq
        if c == ';' and not inq:
            return "".join(out) + "//" + s[i+1:]
        out.append(c)
        i += 1
    return s


def bank_byte(s):
    """^expr -> ((expr) >> 16), balanced for parenthesised operands."""
    while True:
        m = re.search(r'\^(?=[\w($])', s)
        if not m:
            return s
        j = m.end()
        if s[j] == '(':
            depth, k = 0, j
            while k < len(s):
                if s[k] == '(':
                    depth += 1
                elif s[k] == ')':
                    depth -= 1
                    if depth == 0:
                        break
                k += 1
            inner = s[j:k+1]
            s = s[:m.start()] + f"({inner} >> 16)" + s[k+1:]
        else:
            m2 = re.match(r'[\w$]+', s[j:])
            tok = m2.group(0)
            s = s[:m.start()] + f"(({tok}) >> 16)" + s[j+len(tok):]


def split_text_args(args):
    """!text arg list -> [('s', string), ('b', expr), ...] preserving order."""
    parts, cur, inq = [], "", False
    for c in args:
        if c == '"':
            inq = not inq
            cur += c
        elif c == ',' and not inq:
            parts.append(cur.strip())
            cur = ""
        else:
            cur += c
    if cur.strip():
        parts.append(cur.strip())
    out = []
    for p in parts:
        if p.startswith('"'):
            out.append(('s', p))
        else:
            out.append(('b', p))
    return out


def convert(text, stem, import_map):
    text = anon_labels(text)
    lines = text.split("\n")
    out = []
    macro_params = None
    blocks = []
    scope = stem                # for @cheap -> scope__cheap

    def emit(s):
        out.append(conv_comment(s))

    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1

        # guard header -> #importonce (drop the marker assignment)
        m = re.match(r'\s*!ifdef\s+(\w+)\s+!eof\s*$', line)
        if m:
            emit("#importonce")
            if i < len(lines) and re.match(r'\s*%s\s*=\s*1' % m.group(1), lines[i]):
                i += 1
            continue

        if re.match(r'\s*!cpu\b', line):
            continue

        # !ifndef NAME { NAME = v } -> overridable default. Module gates
        # (X16_USE_*) live at the preprocessor level; value symbols
        # (T_ZP, ...) become .const guarded by a NAME_SET define.
        m = re.match(r'(\s*)!ifndef\s+(\w+)\s*\{\s*\2\s*=\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, name, val, cmt = m.groups()
            if name.startswith("X16_USE_"):
                emit(f"{ind}#if !{name}" + ((' ' + cmt) if cmt else ''))
                emit(f"{ind}#define {name}")
                emit(f"{ind}#endif")
            else:
                emit(f"{ind}#if !{name}_SET" + ((' ' + cmt) if cmt else ''))
                emit(f"{ind}.label {name} = {val}")
                emit(f"{ind}#endif")
            continue

        # other one-line conditionals: reprocess the body
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(.*?)\s*\}\s*(;.*)?$', line)
        if m:
            ind, kind, name, body, cmt = m.groups()
            neg = "!" if kind == "ifndef" else ""
            emit(f"{ind}#if {neg}{name}" + ((' ' + cmt) if cmt else ''))
            blocks.append('pp')
            lines[i:i] = [f"{ind}{body}", f"{ind}}}"]
            continue

        m = re.match(r'(\s*)!if\s+(.*?)\s*\{\s*!error\s+(".*?")\s*\}\s*$', line)
        if m:
            ind, cond, msg = m.groups()
            emit(f"{ind}.errorif ({cond}), {msg}")
            continue

        m = re.match(r'(\s*)!addr\s+(\w+)\s*=\s*(.*)$', line)
        if m:
            emit(f"{m.group(1)}.label {m.group(2)} = {m.group(3)}")
            continue

        # zone-local label definitions
        m = re.match(r'^\.([A-Za-z_]\w*)\b[ \t]*(.*)$', line)
        if m and macro_params is None:
            name, rest = m.groups()
            emit(f"{stem}_{name}:")
            if rest and not rest.startswith(';'):
                lines.insert(i, "    " + rest)
            continue

        # block openers
        m = re.match(r'(\s*)!(ifdef|ifndef)\s+(\w+)\s*\{\s*(;.*)?$', line)
        if m:
            ind, kind, name, cmt = m.groups()
            neg = "!" if kind == "ifndef" else ""
            emit(f"{ind}#if {neg}{name}" + ((' ' + cmt) if cmt else ''))
            blocks.append('pp')
            continue
        m = re.match(r'(\s*)!if\s+(.*?)\s*\{\s*(;.*)?$', line)
        if m:
            ind, cond, cmt = m.groups()
            emit(f"{ind}.if ({cond}) {{" + ((' ' + cmt) if cmt else ''))
            blocks.append('brace')
            continue
        if re.match(r'\s*!addr\s*\{\s*(;.*)?$', line):
            emit("// (!addr block: .const assignments in KickAssembler)")
            blocks.append('addr')
            continue
        if re.match(r'\s*!zone\s+\w+\s*\{\s*(;.*)?$', line):
            emit("// (zone: file scope in KickAssembler)")
            blocks.append('zone')
            continue

        # macro definitions
        m = re.match(r'(\s*)!macro\s+(\w+)\s*(.*?)\s*\{\s*$', line)
        if m:
            ind, name, params = m.groups()
            plist = [p.strip().lstrip('.') for p in params.split(',') if p.strip()]
            macro_params = plist
            blocks.append('macro')
            emit(f"{ind}.macro {name}({', '.join(plist)}) {{")
            continue

        # closing braces
        if re.match(r'\s*\}\s*(;.*)?$', line):
            kind = blocks.pop() if blocks else 'pp'
            if kind == 'macro':
                emit("}")
                macro_params = None
            elif kind == 'pp':
                emit("#endif")
            elif kind == 'brace':
                emit("}")
            else:
                emit("// (end " + kind + ")")
            continue

        for part in split_statements(line):
            s = part

            # macro params first (dots are unambiguous pre-conversion)
            if macro_params is not None:
                for p in macro_params:
                    s = re.sub(r'\.(%s)\b' % re.escape(p), r'\1', s)
            s = DOT_IDENT.sub(lambda mm: f"{stem}_{mm.group(1)}", s)

            # track the current routine BEFORE renaming its @locals
            mlab = re.match(r'^([A-Za-z_]\w*)\b(?!\s*=)', s)
            if mlab and not s.lstrip().startswith(('.', '#', '/')):
                scope = mlab.group(1)

            # cheap locals -> per-routine globals
            s = re.sub(r'@([A-Za-z_]\w*)',
                       lambda mm: f"{scope}__{mm.group(1)}", s)

            # program counter
            m2 = re.match(r'^\*\s*=\s*(.*?)\s*(;.*)?$', s)
            if m2:
                emit(f'.pc = {m2.group(1)} "code"' +
                     (('  ' + m2.group(2)) if m2.group(2) else ''))
                continue

            # gates and assignments
            m2 = re.match(r'^(X16_USE_\w+)\s*=\s*1\s*(;.*)?$', s)
            if m2:
                emit(f"#define {m2.group(1)}" +
                     (('  ' + m2.group(2)) if m2.group(2) else ''))
                continue
            m2 = re.match(r'^(\s*)([A-Za-z_]\w*)\s*=\s*(.*)$', s)
            if m2 and not s.lstrip().startswith('.'):
                ind, name, val = m2.groups()
                if name in DEFAULTABLE:
                    emit(f"{ind}#define {name}_SET")
                emit(f"{ind}.label {name} = {val}")
                continue

            # !text: strings and bytes cannot mix in one directive
            m2 = re.match(r'^([A-Za-z_]\w*:?\s+|\s*)!text\s+(.*)$', s)
            if m2:
                prefix, args = m2.groups()
                argcode = args.split(';', 1)[0]
                label = prefix.strip()
                if label and not label.endswith(':'):
                    label += ':'
                first = True
                for kind, val in split_text_args(argcode):
                    d = '.text' if kind == 's' else '.byte'
                    lead = (label + ' ') if (first and label) else '    '
                    emit(f"{lead}{d} {val}")
                    first = False
                continue

            # data directives
            s = re.sub(r'!error\b', '.error', s)
            s = re.sub(r'!byte\b', '.byte', s)
            s = re.sub(r'!word\b', '.word', s)
            s = re.sub(r'!fill\b', '.fill', s)
            # KickAssembler's .fill has no implicit zero value
            m3 = re.match(r'^(.*\.fill\s+[^,;]+?)\s*(;.*)?$', s)
            if m3 and '.fill' in s:
                s = m3.group(1) + ", 0" + \
                    (('  ' + m3.group(2)) if m3.group(2) else '')
            s = re.sub(r'!source\s+"([^"]+)"',
                       lambda mm: '#import "%s"' % import_map(mm.group(1)), s)
            s = s.replace('>>>', '>>')
            s = bank_byte(s)

            # macro invocation: +name args -> name(args)
            m2 = re.match(r'^(\s*)\+(\w+)\s*(.*?)\s*(;.*)?$', s)
            if m2:
                ind, name, args, cmt = m2.groups()
                emit(f"{ind}{name}({args})" + (('  ' + cmt) if cmt else ''))
                continue

            # label lines need a colon
            m2 = re.match(r'^([A-Za-z_]\w*)\b\s*(.*)$', s)
            if m2 and not re.match(r'^[A-Za-z_]\w*\s*=', s) \
                    and not s.startswith(('.', '#', '/')):
                name, rest = m2.groups()
                if rest.startswith(':'):
                    emit(s)
                else:
                    emit(f"{name}:" + ((' ' + rest) if rest else ''))
                continue

            emit(s)

    # A user-level override of a defaultable (T_ZP = $70 ...) must be
    # seen BEFORE the library's #if !NAME_SET default: KickAssembler's
    # preprocessor is sequential and .const is single-assignment. Hoist
    # the override pair above the first #import.
    first_imp = next((k for k, l in enumerate(out)
                      if l.lstrip().startswith('#import')), None)
    if first_imp is not None:
        k = first_imp + 1
        while k < len(out):
            m = re.match(r'\s*#define (\w+)_SET\s*$', out[k])
            if m and m.group(1) in DEFAULTABLE and k + 1 < len(out):
                pair = out[k:k+2]
                del out[k:k+2]
                out[first_imp:first_imp] = pair
                first_imp += 2
                k += 2
            else:
                k += 1

    return "\n".join(out)


def main():
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])

    def import_map(name):
        return name.replace("test_acme/", "")

    for f in sorted(src.rglob("*.asm")):
        rel = f.relative_to(src).as_posix()
        if rel in SKIP:
            print(f"skip  {rel} (hand-maintained)")
            continue
        text = f.read_text(encoding="ascii", errors="replace")
        converted = convert(text, f.stem, import_map)
        outp = dst / rel
        outp.parent.mkdir(parents=True, exist_ok=True)
        outp.write_text(converted, encoding="ascii")
        print(f"conv  {rel}")


if __name__ == "__main__":
    main()
