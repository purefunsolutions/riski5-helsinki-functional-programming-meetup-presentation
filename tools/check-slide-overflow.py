#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Mika Tammi
# SPDX-License-Identifier: MIT
"""
Heuristic slide-overflow detector.

DZSlides slides are ~600px tall in this deck; with the corner-brand
reservation (height: calc(100% - 4.5rem) ≈ 99px) the visible content
area is roughly 500px.

This script parses docs/index.html, walks every <section> slide, and
estimates rendered height by counting headings, paragraphs, list
items, code-block lines, and table rows — adjusting for the
.code-dense class which shrinks font sizes.

Run from the repo root:

    python3 tools/check-slide-overflow.py
"""

import re
import sys
from pathlib import Path

HTML = Path(__file__).resolve().parent.parent / "docs" / "index.html"

# Default and code-dense per-element rendered heights, in CSS px.
# Values calibrated against actual DZSlides rendering at 22px root
# font-size (see assets/css/overrides.css `html { font-size: 22px; }`).
NORMAL = {
    "h": 56,         # h1, h2 — title + bottom margin
    "p": 36,         # paragraph average
    "li": 32,        # bullet
    "pre_line": 30,  # one line of <pre>
    "tr": 32,        # table row
    "img": 280,      # rough image height for two-col slides
}
CODE_DENSE = {
    "h": 38,         # smaller h2 in .code-dense
    "p": 26,         # 0.8em prose
    "li": 24,
    "pre_line": 18,  # 0.6em code, line-height 1.25
    "tr": 24,
    "img": 280,
}

THRESHOLD_PX = 560  # full slide height ~600px minus a small safety margin


def estimate(body: str, dense: bool) -> tuple[float, dict]:
    h = NORMAL if not dense else CODE_DENSE
    counts = {
        "h": len(re.findall(r"<h[1-3][\s>]", body)),
        "p": len(re.findall(r"<p[\s>]", body)),
        "li": len(re.findall(r"<li[\s>]", body)),
        "pre_line": sum(
            block.count("\n") + 1
            for block in re.findall(r"<pre[^>]*>(.*?)</pre>", body, re.DOTALL)
        ),
        "tr": len(re.findall(r"<tr[\s>]", body)),
        "img": len(re.findall(r"<img[\s>]", body)),
    }
    px = sum(counts[k] * h[k] for k in counts)
    return px, counts


def main() -> int:
    if not HTML.exists():
        print(f"error: {HTML} not found — run `cabal run site -- build` first", file=sys.stderr)
        return 1
    html = HTML.read_text()

    # Single pass: pull the entire opening tag, then extract id and class
    # attributes regardless of their order.
    section_re = re.compile(
        r"<section\s+(?P<attrs>[^>]*)>(?P<body>.*?)</section>",
        re.DOTALL,
    )
    id_re = re.compile(r'id="([^"]+)"')
    cls_re = re.compile(r'class="([^"]+)"')

    matches = []
    for m in section_re.finditer(html):
        attrs = m.group("attrs")
        sid_match = id_re.search(attrs)
        cls_match = cls_re.search(attrs)
        sid = sid_match.group(1) if sid_match else "(no-id)"
        cls = cls_match.group(1) if cls_match else ""
        matches.append((sid, cls, m.group("body"), m.start()))

    print(f"Total slides: {len(matches)}")
    print(f"Threshold: {THRESHOLD_PX}px (slide height ~600 - corner-brand 99)\n")
    print(f"{'#':>3}  {'~px':>5}  cls           id")
    print("-" * 78)

    overflows = []
    tight = []
    for i, (sid, cls, body, _) in enumerate(matches, 1):
        dense = "code-dense" in cls
        two_col = "two-col" in cls
        px, counts = estimate(body, dense)
        # Two-column slides distribute content horizontally; the
        # rendered slide height is ~max of the two columns rather
        # than their sum. Halve the heuristic estimate.
        if two_col:
            px *= 0.5
        cls_short = "code-dense" if dense else "default"
        if two_col:
            cls_short += "+2col"
        if "title-deck" in cls:
            cls_short = "title-deck"

        flag = ""
        if "title-deck" not in cls and px > THRESHOLD_PX:
            flag = "  OVERFLOW"
            overflows.append((i, sid, px))
        elif px > THRESHOLD_PX * 0.9:
            flag = "  tight"
            tight.append((i, sid, px))

        if px > 320 or flag:
            print(f"{i:>3}  {px:>5.0f}  {cls_short:13}  {sid}{flag}")

    print()
    if overflows:
        print(f"OVERFLOWING ({len(overflows)} slide(s)):")
        for i, sid, px in overflows:
            print(f"  {i:>3}: {sid}  (~{px:.0f}px)")
    if tight:
        print(f"TIGHT ({len(tight)} slide(s)):")
        for i, sid, px in tight:
            print(f"  {i:>3}: {sid}  (~{px:.0f}px)")
    if not overflows and not tight:
        print("No overflows or tight slides by heuristic. ✓")

    return 1 if overflows else 0


if __name__ == "__main__":
    sys.exit(main())
