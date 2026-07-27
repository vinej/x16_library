#!/usr/bin/env python3
# =====================================================================
# doc_coverage.py -- which routines the tutorial never mentions.
#
# The library grows a module at a time and the tutorial is written by
# hand, so the two drift apart quietly: a routine that exists, is
# exported, is in the README table, and is documented nowhere anybody
# reads. This is the check that keeps that honest.
#
#   python tools/doc_coverage.py                 # summary + the gaps
#   python tools/doc_coverage.py --list          # every missing routine
#
# The routine list comes from the ACME sources themselves (every label
# at column 0 inside a module that emits code), so nothing has to be
# kept in step by hand.
# =====================================================================
import re, sys, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC  = ROOT / "src_acme"
DOCS = SRC / "tutorial"

def routines():
    """gate -> [routine], from the sources that x16_code.asm selects."""
    code = (SRC / "x16_code.asm").read_text(encoding="utf-8", errors="replace")
    out = collections.defaultdict(list)
    for gate, rel in re.findall(r'!ifdef (X16_USE_[A-Z0-9_]+)\s*\{\s*!source "([^"]+)"', code):
        f = SRC / rel
        if not f.exists():
            continue
        for line in f.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r'^([a-z][a-z0-9_]*)\s*$', line)
            if m:
                out[gate].append(m.group(1))
    return out

def main():
    text = "\n".join(p.read_text(encoding="utf-8", errors="replace")
                     for p in DOCS.glob("*.md"))
    by_gate = routines()
    missing = collections.defaultdict(list)
    total = 0
    for gate, rs in by_gate.items():
        for r in rs:
            total += 1
            # A page usually documents the MACRO (+xm_dir_next), which
            # carries the routine name but not at a word boundary --
            # "xm_" ends in an underscore. Accept either spelling.
            if not re.search(r'(?<![A-Za-z0-9])(?:xm_)?' + re.escape(r) + r'\b', text):
                missing[gate].append(r)
    gone = sum(len(v) for v in missing.values())
    print(f"routines {total}   documented {total - gone}   missing {gone}"
          f"   ({len(list(DOCS.glob('*.md')))} tutorial pages)")
    for gate, rs in sorted(missing.items(), key=lambda kv: -len(kv[1])):
        undocumented_module = len(rs) == len(by_gate[gate])
        mark = "  <- NO PAGE" if undocumented_module else ""
        print(f"  {gate:26} {len(rs):3} of {len(by_gate[gate]):3}{mark}")
        if "--list" in sys.argv:
            for r in rs:
                print(f"      {r}")
    return 1 if gone else 0

if __name__ == "__main__":
    raise SystemExit(main())
