#!/usr/bin/env python3
# =====================================================================
# doc_fill.py -- write the tutorial entries that doc_coverage.py misses.
#
# Every routine in the library carries its own header:
#
#       ; dir_next -- read the next entry
#       ;   in:  X16_P0/P1 = a buffer for the name, X16_P2 = its size
#       ;   out: carry SET if an entry was read, CLEAR at the end
#
# which is the same thing a tutorial table row says. So rather than
# inventing prose for a hundred routines, take what the source already
# states and put it where a reader looks. Anything with more to say than
# its header can be written up by hand afterwards -- this guarantees the
# floor, not the ceiling.
#
#   python tools/doc_fill.py            # append the missing entries
#   python tools/doc_fill.py --dry      # say what would be written
# =====================================================================
import re, sys, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC  = ROOT / "src_acme"
DOCS = SRC / "tutorial"

def modules():
    """gate -> (source path, [routine])"""
    code = (SRC / "x16_code.asm").read_text(encoding="utf-8", errors="replace")
    out = {}
    for gate, rel in re.findall(r'!ifdef (X16_USE_[A-Z0-9_]+)\s*\{\s*!source "([^"]+)"', code):
        f = SRC / rel
        if not f.exists():
            continue
        names = [m.group(1) for m in
                 (re.match(r'^([a-z][a-z0-9_]*)\s*$', l)
                  for l in f.read_text(encoding="utf-8", errors="replace").splitlines())
                 if m]
        out.setdefault(gate, (f, []))[1].extend(names)
    return out

def header_of(path, routine):
    """The ; --- block above a label: purpose, in:, out:, and the rest."""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    try:
        at = next(i for i, l in enumerate(lines) if l.strip() == routine)
    except StopIteration:
        return None
    # Walk up through the comment block. The line directly above a label
    # is the closing rule of its own header, so skip that one and stop at
    # the opening rule -- breaking on the first rule seen collects
    # nothing at all, which is how a routine ends up documented as "--".
    block, i, seen_rule = [], at - 1, False
    while i >= 0 and (lines[i].startswith(";") or not lines[i].strip()):
        if lines[i].startswith("; ---"):
            if seen_rule:
                break
            seen_rule = True
            i -= 1
            continue
        block.append(lines[i])
        i -= 1
    block.reverse()
    text = "\n".join(block)
    purpose = ""
    m = re.search(r';\s*' + re.escape(routine) + r'\s*(?:/[^-]*)?--\s*(.+)', text)
    if m:
        purpose = m.group(1).strip()
    def field(tag):
        m = re.search(r';\s*' + tag + r':\s*(.+?)(?=\n;\s*(?:in|out|note):|\Z)',
                      text, re.S)
        if not m:
            return ""
        v = " ".join(x.strip("; ").strip() for x in m.group(1).splitlines())
        return re.sub(r'\s+', ' ', v).strip()
    return purpose, field("in"), field("out"), field("note")

def page_for(gate, pages, by_page):
    """The page already documenting most of this gate, if any."""
    best, score = None, 0
    for p, names in by_page.items():
        n = len(names & set(gate_routines[gate]))
        if n > score:
            best, score = p, n
    return best

if __name__ == "__main__":
    dry = "--dry" in sys.argv
    mods = modules()
    gate_routines = {g: rs for g, (f, rs) in mods.items()}
    pages = list(DOCS.glob("*.md"))
    text_of = {p: p.read_text(encoding="utf-8", errors="replace") for p in pages}
    by_page = {p: set(re.findall(r'\b(?:xm_)?([a-z][a-z0-9_]{2,})\b', t))
               for p, t in text_of.items()}
    alltext = "\n".join(text_of.values())

    add = collections.defaultdict(list)
    for gate, (path, rs) in sorted(mods.items()):
        for r in rs:
            if re.search(r'(?<![A-Za-z0-9])(?:xm_)?' + re.escape(r) + r'\b', alltext):
                continue
            h = header_of(path, r)
            if not h:
                continue
            target = page_for(gate, pages, by_page)
            if target is None:
                continue
            add[target].append((r, h))

    for page, rows in sorted(add.items(), key=lambda kv: kv[0].name):
        print(f"{page.name}: +{len(rows)}")
        if dry:
            continue
        out = ["", "## Reference: routines not covered above", "",
               "Taken from each routine's own header in the source, so this",
               "stays true as the module changes.", "",
               "| Routine | Purpose | In | Out |", "|---|---|---|---|"]
        for r, (purpose, i, o, note) in rows:
            purpose = (purpose or "--").replace("|", "\\|")
            i = (i or "--").replace("|", "\\|")
            o = (o or "--").replace("|", "\\|")
            out.append(f"| `{r}` | {purpose} | {i} | {o} |")
        page.write_text(text_of[page].rstrip() + "\n" + "\n".join(out) + "\n",
                        encoding="utf-8", newline="\n")
    print(f"{sum(len(v) for v in add.values())} entries written to {len(add)} pages")
