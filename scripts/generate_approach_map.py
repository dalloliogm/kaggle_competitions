#!/usr/bin/env python3
"""Render a competition approach map to standalone HTML from its JSON registry.

The `competition-approach-map` skill names this script as the renderer, but it
did not exist - the pages under `docs/` were hand-maintained alongside their
`-data.json`, which is exactly how `docs/biohub-approach-map.html` drifted three
days and two leaderboard tiers behind its own registry.

With this in place the JSON is the single input and the HTML is a build product:

    python3 scripts/generate_approach_map.py \\
        docs/biohub-approach-map-data.json docs/biohub-approach-map.html

No network access and no build tooling. The output is byte-stable for unchanged
input, so regenerating a current page produces an empty diff.

Registry schema
---------------
    title       page title
    as_of       ISO date the record is current to
    competition dict of context fields rendered into the overview panel
    lanes       [{id, title}] in display order
    nodes       [{id, lane, title, summary, score, status, parents}]

`status` must be one of STATUSES; anything else is rejected rather than
rendered with default styling, so a typo cannot silently become an unfiltered
node.
"""

from __future__ import annotations

import html
import json
import sys
from pathlib import Path

STATUSES = ("submitted", "best", "rejected", "not-submitted", "pending", "untried")

STATUS_LABELS = {
    "submitted": "submitted",
    "best": "best",
    "rejected": "rejected",
    "not-submitted": "not submitted",
    "pending": "pending",
    "untried": "untried",
}

# Overview panels, in render order: (registry key, heading, is_link).
OVERVIEW_FIELDS = (
    ("description", "Competition", False),
    ("prediction_target", "What to predict", False),
    ("models", "Models / approach", False),
    (None, "Dates", False),
    ("standing", "Standing", False),
    ("url", "Competition link", True),
    ("lesson", "Lesson", False),
)

STYLE = (
    "body{margin:0;background:#f6f8fa;color:#17212b;font:15px/1.42 system-ui,sans-serif}"
    "main{max-width:1440px;margin:0 auto;padding:24px}h1{margin:0;font-size:1.8rem}"
    ".subhead,.relation{color:#52616e}"
    ".overview{display:grid;grid-template-columns:minmax(240px,1.35fr) repeat(2,minmax(165px,1fr));gap:12px;margin:0 0 18px}"
    ".overview section{border:1px solid #c6d1db;border-radius:7px;background:#fff;padding:12px}"
    ".overview h2{font-size:.82rem;letter-spacing:.04em;text-transform:uppercase;color:#52616e;margin:0 0 5px}"
    ".overview p{margin:0;font-size:.9rem}.overview a{color:#075db3}"
    ".legend{display:flex;flex-wrap:wrap;gap:8px 14px;margin:18px 0}"
    "label{display:inline-flex;gap:6px;align-items:center;cursor:pointer}input{accent-color:#216e39}"
    ".map{display:grid;gap:18px}.lane{border-left:3px solid #c6d1db;padding-left:14px}"
    "h2{font-size:1rem;margin:0 0 10px}"
    ".flow{display:flex;align-items:stretch;gap:10px;overflow-x:auto;padding-bottom:8px}"
    ".node{min-width:230px;max-width:280px;border:1px solid #9dacba;border-left:6px solid #58708a;"
    "border-radius:7px;padding:10px 12px;background:#fff}"
    ".node h3{font-size:.96rem;margin:0 0 5px}.node p{margin:0;color:#3c4b58;font-size:.88rem}"
    ".score{font-weight:700;margin-top:7px!important}"
    ".relation{margin-top:7px!important;font-size:.78rem!important}"
    ".submitted{border-left-color:#2d7d46}"
    ".best{border-color:#26834a;border-left-color:#126b2c;background:#e9f8ec}"
    ".rejected{border-left-color:#b54242;background:#fff7f7}"
    ".not-submitted{border-left-color:#b36a00;background:#fff9eb}"
    ".pending{border-left-color:#3979b7;background:#f4f9ff}"
    ".untried{border-left-color:#716a80;border-style:dashed;background:#faf9fc}"
    ".hidden{display:none}"
    "@media(max-width:760px){main{padding:14px}.overview{grid-template-columns:1fr}.node{min-width:240px}}"
)

SCRIPT = (
    "const boxes=[...document.querySelectorAll('.legend input')];"
    "function apply(){const on=new Set(boxes.filter(b=>b.checked).map(b=>b.dataset.status));"
    "document.querySelectorAll('.node').forEach(n=>"
    "n.classList.toggle('hidden',!on.has(n.dataset.status)));"
    "document.querySelectorAll('.lane').forEach(l=>"
    "l.classList.toggle('hidden',![...l.querySelectorAll('.node')].some(n=>!n.classList.contains('hidden'))));}"
    "boxes.forEach(b=>b.addEventListener('change',apply));apply();"
)


def esc(value: str) -> str:
    return html.escape(str(value), quote=True)


def validate(data: dict) -> None:
    for key in ("title", "as_of", "competition", "lanes", "nodes"):
        if key not in data:
            raise SystemExit(f"registry is missing required key: {key}")

    lane_ids = {lane["id"] for lane in data["lanes"]}
    node_ids = {node["id"] for node in data["nodes"]}
    if len(node_ids) != len(data["nodes"]):
        raise SystemExit("duplicate node ids in registry")

    for node in data["nodes"]:
        if node["status"] not in STATUSES:
            raise SystemExit(
                f"node {node['id']}: unknown status {node['status']!r}; "
                f"expected one of {', '.join(STATUSES)}"
            )
        if node["lane"] not in lane_ids:
            raise SystemExit(f"node {node['id']}: unknown lane {node['lane']!r}")
        for parent in node.get("parents", []):
            if parent not in node_ids:
                raise SystemExit(f"node {node['id']}: unknown parent {parent!r}")

    best = [node["id"] for node in data["nodes"] if node["status"] == "best"]
    if len(best) > 1:
        # Two "best" nodes is the specific drift that made the stale page
        # claim 0.915 while a 0.917 node sat next to it.
        raise SystemExit(f"more than one node marked best: {', '.join(best)}")


def render_overview(competition: dict) -> str:
    parts = []
    for key, heading, is_link in OVERVIEW_FIELDS:
        if heading == "Dates":
            body = "<br>".join(
                f"{label}: {esc(competition.get(field, 'Not recorded'))}"
                for label, field in (
                    ("Started", "started"),
                    ("Entered", "entered"),
                    ("Finished", "finished"),
                )
            )
        elif key not in competition:
            continue
        elif is_link:
            body = f'<a href="{esc(competition[key])}">Kaggle overview</a>'
        else:
            body = esc(competition[key])
        parts.append(f"  <section><h2>{esc(heading)}</h2><p>{body}</p></section>")
    return "\n".join(parts)


def render_nodes(data: dict) -> str:
    titles = {node["id"]: node["title"] for node in data["nodes"]}
    lanes = []
    for lane in data["lanes"]:
        nodes = [node for node in data["nodes"] if node["lane"] == lane["id"]]
        if not nodes:
            continue
        cards = []
        for node in nodes:
            parents = node.get("parents", [])
            relation = (
                "Derived from: " + ", ".join(esc(titles[p]) for p in parents)
                if parents else "Root approach"
            )
            score = (
                f'\n  <p class="score">{esc(node["score"])}</p>'
                if node.get("score") else ""
            )
            cards.append(
                f'<article class="node {esc(node["status"])}" '
                f'data-status="{esc(node["status"])}">\n'
                f'  <h3>{esc(node["title"])}</h3>'
                f'<p>{esc(node["summary"])}</p>{score}'
                f'<p class="relation">{relation}</p>\n</article>'
            )
        lanes.append(
            f'<section class="lane"><h2>{esc(lane["title"])}</h2>'
            f'<div class="flow">{chr(10).join(cards)}</div></section>'
        )
    return "".join(lanes)


def render(data: dict) -> str:
    legend = "\n".join(
        f'<label><input type="checkbox" data-status="{status}" checked> '
        f"{STATUS_LABELS[status]}</label>"
        for status in STATUSES
    )
    return (
        "<!doctype html>\n"
        '<html lang="en"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        f"<title>{esc(data['title'])}</title><style>\n{STYLE}</style></head>\n"
        f'<body><main id="approach-map"><h1>{esc(data["title"])}</h1>'
        f'<p class="subhead">As of {esc(data["as_of"])}. '
        "Filter by decision status.</p><section class=\"overview\">\n"
        f"{render_overview(data['competition'])}\n"
        '</section><div class="legend" aria-label="Filter experiments by status">'
        f"{legend}</div><section class=\"map\">{render_nodes(data)}</section>"
        f"</main>\n<script>{SCRIPT}</script>\n</body></html>\n"
    )


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__)
        return 2
    data = json.loads(Path(argv[1]).read_text())
    validate(data)
    Path(argv[2]).write_text(render(data))
    counts: dict[str, int] = {}
    for node in data["nodes"]:
        counts[node["status"]] = counts.get(node["status"], 0) + 1
    summary = ", ".join(f"{n} {s}" for s, n in sorted(counts.items()))
    print(f"wrote {argv[2]}: {len(data['nodes'])} nodes ({summary}), as of {data['as_of']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
