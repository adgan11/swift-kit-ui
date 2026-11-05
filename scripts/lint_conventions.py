#!/usr/bin/env python3
"""
Convention lint for Swift Kit UI.

Compiling proves the code is valid. It does not prove the code is *consistent*,
and consistency is the entire product here — forty components that each invent
their own spacing and easing is forty snippets, not a kit.

These are the same checks the agent test graded against, now pointed at our own
source. Findings are reported with context rather than auto-failed, because a
handful of hits are legitimate (a `.linear` repeatForever spinner, `.white` on a
coloured fill) and a linter that cries wolf gets ignored.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
COMPONENTS = sorted((ROOT / "Sources/SwiftKitUI/Components").glob("*.swift"))

# Rules that are never acceptable in a component.
HARD = [
    ("ad-hoc-easing", "ad-hoc easing (use SKMotion)",
     re.compile(r"\.animation\(\s*\.(easeInOut|easeIn|easeOut|linear)\(")),
    ("raw-color", "raw named Color",
     re.compile(r"Color\.(red|blue|green|orange|yellow|pink|purple|gray|teal|indigo|mint|brown)\b")),
    ("hard-coded-color", "hard-coded colour literal",
     re.compile(r"Color\(red:|#[0-9A-Fa-f]{6}\b")),
]

# A file may opt out of one rule with `// lint:allow <slug> — reason`.
# The reason is mandatory: an exemption nobody had to justify is a rule that
# quietly stops being enforced.
ALLOW = re.compile(r"//\s*lint:allow\s+([a-z-]+)\s+—\s*(\S.*)")

# Rules that need a human eye.
SOFT = [
    ("withAnimation not using SKMotion", re.compile(r"withAnimation\(\s*\.(spring|easeInOut|easeOut|linear)")),
    ("bare .system(size:) — prefer SK.Icon.symbol", re.compile(r"\.system\(size:")),
    ("repeatForever (verify Reduce Motion is handled)", re.compile(r"repeatForever")),
]

REQUIRED = [
    ("Requires: header", re.compile(r"//\s+Requires: SwiftKitUI\.swift")),
    ("#Preview", re.compile(r"#Preview")),
    ("public API", re.compile(r"public (struct|enum|extension|func)")),
]


def strip_comments(src: str) -> str:
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return "\n".join(l for l in src.splitlines() if not l.strip().startswith("//"))


def component_body(src: str) -> str:
    """Everything above the first #Preview.

    Previews legitimately use raw colours and demo data — a swatch picker has to
    show *some* palette. Linting them produces noise that trains you to ignore
    the linter."""
    idx = src.find("#Preview")
    return strip_comments(src if idx == -1 else src[:idx])


def main() -> int:
    hard_hits: list[str] = []
    soft_hits: list[str] = []
    missing: list[str] = []
    exempt: list[str] = []

    for path in COMPONENTS:
        raw = path.read_text()
        code = component_body(raw)
        name = path.stem

        for label, pattern in REQUIRED:
            if not pattern.search(raw):
                missing.append(f"  {name}: missing {label}")

        allowed = {m.group(1): m.group(2).strip() for m in ALLOW.finditer(raw)}
        for slug, label, pattern in HARD:
            if slug in allowed:
                if pattern.search(code):
                    exempt.append(f"  {name}: {slug} — {allowed[slug]}")
                continue
            for m in pattern.finditer(code):
                hard_hits.append(f"  {name}: {label}  ->  {m.group(0)[:48]}")

        for label, pattern in SOFT:
            hits = pattern.findall(code)
            if hits:
                soft_hits.append(f"  {name}: {label} x{len(hits)}")

    print(f"lint — {len(COMPONENTS)} components\n")

    if missing:
        print("MISSING REQUIRED:")
        print("\n".join(missing) + "\n")
    else:
        print("required header / #Preview / public API: all present\n")

    if hard_hits:
        print(f"VIOLATIONS ({len(hard_hits)}):")
        print("\n".join(hard_hits) + "\n")
    else:
        print("no hard violations\n")

    if exempt:
        print(f"EXEMPT ({len(exempt)}):")
        print("\n".join(exempt) + "\n")

    if soft_hits:
        print(f"REVIEW ({len(soft_hits)}):")
        print("\n".join(soft_hits))

    return 1 if (hard_hits or missing) else 0


if __name__ == "__main__":
    sys.exit(main())
