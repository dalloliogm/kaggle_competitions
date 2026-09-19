#!/usr/bin/env python3
"""Density-adaptive motion-relink gates, computed per video from the graph.

## The idea, and where it came from

`haideptry/biohub-sota-0-948-density-adaptive-2xt4-22m` (2026-09-17) claims
0.948 by assigning different `tight_um` / `relaxed_um` / `learned_bonus` per
video according to measured cell density. The reasoning is sound on its face:
density varies more than 11x across the test videos (73 to 763 cells per frame,
measured from our own detector manifests), so a single global constant is a
compromise across regimes rather than an optimum in any of them.

## What is worth copying, and what is not

The mechanism is honest - `determine_density_group(nodes_by_id)` computes the
group from the graph, with no dataset names anywhere in the source, so it runs
unchanged on hidden data.

The **constants** are a different matter. The buckets are `<120`, `<400`,
`else`, and our four test videos average 73 / 265 / 333 / 763 cells per frame.
So the three buckets hold {one video} / {two videos} / {one video}, and both
boundaries fall in empty gaps between them. That is three hand-tuned
parameter-sets fitted against four movies, reached through a density proxy
rather than a lookup table. On ~199 hidden samples with a continuous density
distribution, many land near a boundary and inherit constants tuned for a
neighbouring regime.

It also contradicts our own held-out evidence: our sweep selected
`MOTION_RELINK_TIGHT_UM = 5.5` on both 8 and 24 held-out videos, and on the
leaderboard 6.0 scored 0.939 against 5.5 at 0.946. Their middle bucket uses 6.5
and their low bucket 7.25.

So this builds two arms that separate the mechanism from their constants:

- **E `density-low-only`** - the conservative test. Only the low-density group
  moves (7.25); middle and high keep our validated 5.5. This isolates the one
  sub-claim with a physical mechanism: where cells are sparse, a cell can move
  further between frames without the wider gate creating ambiguity, because
  there is no near neighbour to confuse it with. Everything our held-out sweep
  actually validated is left alone.
- **F `density-full`** - their three-bucket table replicated exactly, as a
  direct test of the 0.948 claim. If E moves and F does not, the mechanism is
  real and their constants are the overfit part. If F moves and E does not,
  the gain is in the middle bucket, where their constants disagree most with
  our sweep - which would be worth understanding before trusting.

## Implementation

`motion_relink_edges` already receives `nodes_by_id`, which is all the density
estimate needs, so the group is computed inside it with no new plumbing and no
dataset argument. With `BIOHUB_DENSITY_ADAPTIVE_RELINK=0` (the default) the
notebook is unchanged.

This spends submission slots, not just GPU.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
SOURCE = Path(
    "/tmp/claude-0/-home-user-kaggle-competitions/"
    "079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad/audit946"
)
ANCHOR = 'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "4"'

PINNED_HEADER = (
    '# Pinned fast base (verified byte-identical to the scored 0.946), so each\n'
    '# arm differs only in how the relink gate varies with density.\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
    'os.environ["BIOHUB_MOTION_RELINK_TIGHT_UM"] = "5.5"\n'
)

FLAG_ANCHOR = 'MOTION_RELINK_RELAXED_UM = float(os.environ.get("BIOHUB_MOTION_RELINK_RELAXED_UM", "10.0"))'
FLAG_NEW = FLAG_ANCHOR + '''
DENSITY_ADAPTIVE_RELINK = os.environ.get("BIOHUB_DENSITY_ADAPTIVE_RELINK", "0") != "0"
# Bucket boundaries in cells per frame. Our four test videos average
# 73 / 265 / 333 / 763, so these thresholds sit in the gaps between them.
DENSITY_LOW_MAX = float(os.environ.get("BIOHUB_DENSITY_LOW_MAX", "120"))
DENSITY_MIDDLE_MAX = float(os.environ.get("BIOHUB_DENSITY_MIDDLE_MAX", "400"))
DENSITY_LOW_TIGHT_UM = float(os.environ.get("BIOHUB_DENSITY_LOW_TIGHT_UM", "7.25"))
DENSITY_LOW_RELAXED_UM = float(os.environ.get("BIOHUB_DENSITY_LOW_RELAXED_UM", "11.0"))
DENSITY_MIDDLE_TIGHT_UM = float(os.environ.get("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "5.5"))
DENSITY_MIDDLE_RELAXED_UM = float(os.environ.get("BIOHUB_DENSITY_MIDDLE_RELAXED_UM", "10.0"))
DENSITY_HIGH_TIGHT_UM = float(os.environ.get("BIOHUB_DENSITY_HIGH_TIGHT_UM", "5.5"))
DENSITY_HIGH_RELAXED_UM = float(os.environ.get("BIOHUB_DENSITY_HIGH_RELAXED_UM", "10.0"))'''

RELINK_ANCHOR = '''    position_um = {node_id: _position_um(node) for node_id, node in nodes_by_id.items()}
    predecessor_position_um: dict[int, np.ndarray] = {}'''

RELINK_NEW = '''    # Density-adaptive gate. Cell density varies more than 11x across videos
    # (73 to 763 cells per frame in the four test videos), so one global
    # tight_um is a compromise across regimes. Where cells are sparse a cell
    # can move further between frames without the wider gate creating
    # ambiguity, because there is no near neighbour to confuse it with. The
    # group is computed from the graph, so nothing here is keyed to a dataset.
    tight_gate_um = MOTION_RELINK_TIGHT_UM
    relaxed_gate_um = MOTION_RELINK_RELAXED_UM
    if DENSITY_ADAPTIVE_RELINK and ids_by_t:
        _avg_per_frame = len(nodes_by_id) / max(len(ids_by_t), 1)
        if _avg_per_frame < DENSITY_LOW_MAX:
            tight_gate_um, relaxed_gate_um = DENSITY_LOW_TIGHT_UM, DENSITY_LOW_RELAXED_UM
            _group = "low"
        elif _avg_per_frame < DENSITY_MIDDLE_MAX:
            tight_gate_um, relaxed_gate_um = DENSITY_MIDDLE_TIGHT_UM, DENSITY_MIDDLE_RELAXED_UM
            _group = "middle"
        else:
            tight_gate_um, relaxed_gate_um = DENSITY_HIGH_TIGHT_UM, DENSITY_HIGH_RELAXED_UM
            _group = "high"
        stats["density_group_low"] = int(_group == "low")
        stats["density_group_middle"] = int(_group == "middle")
        stats["density_group_high"] = int(_group == "high")
        stats["density_avg_per_frame_milli"] = int(round(_avg_per_frame * 1000))
        print(f"    DENSITY_RELINK group={_group} avg_per_frame={_avg_per_frame:.1f} "
              f"tight={tight_gate_um} relaxed={relaxed_gate_um}")

    position_um = {node_id: _position_um(node) for node_id, node in nodes_by_id.items()}
    predecessor_position_um: dict[int, np.ndarray] = {}'''

PASS_ANCHOR = '        for pass_name, gate_um in (("tight", MOTION_RELINK_TIGHT_UM), ("relaxed", MOTION_RELINK_RELAXED_UM)):'
PASS_NEW = '        for pass_name, gate_um in (("tight", tight_gate_um), ("relaxed", relaxed_gate_um)):'

ARMS = {
    "biohub-sep18-density-low-only": {
        "title": "Biohub Sep18 Density Adaptive Low Only",
        "env": [
            ("BIOHUB_DENSITY_ADAPTIVE_RELINK", "1"),
            ("BIOHUB_DENSITY_LOW_TIGHT_UM", "7.25"),
            ("BIOHUB_DENSITY_LOW_RELAXED_UM", "11.0"),
            ("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "5.5"),
            ("BIOHUB_DENSITY_HIGH_TIGHT_UM", "5.5"),
        ],
        "note": "E: only the low-density group widens; middle and high keep our validated 5.5.",
    },
    "biohub-sep18-density-full": {
        "title": "Biohub Sep18 Density Adaptive Full Table",
        "env": [
            ("BIOHUB_DENSITY_ADAPTIVE_RELINK", "1"),
            ("BIOHUB_DENSITY_LOW_TIGHT_UM", "7.25"),
            ("BIOHUB_DENSITY_LOW_RELAXED_UM", "11.0"),
            ("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "6.5"),
            ("BIOHUB_DENSITY_MIDDLE_RELAXED_UM", "9.0"),
            ("BIOHUB_DENSITY_HIGH_TIGHT_UM", "5.5"),
            ("BIOHUB_DENSITY_HIGH_RELAXED_UM", "10.0"),
        ],
        "note": "F: their three-bucket table replicated exactly, as a direct test of the 0.948 claim.",
    },
    # 2026-09-19 held-out sweep (24 videos, official division rule): these two
    # outrank arm F's table, +0.0024 and +0.0023 against tight55 versus F's
    # +0.0016. Both widen a gate FURTHER than the public notebook's hand-set
    # value, which is the direction our own data keeps pointing.
    "biohub-sep19-dmid700": {
        "title": "Biohub Sep19 Density Middle 700",
        "env": [
            ("BIOHUB_DENSITY_ADAPTIVE_RELINK", "1"),
            ("BIOHUB_DENSITY_LOW_TIGHT_UM", "7.25"),
            ("BIOHUB_DENSITY_LOW_RELAXED_UM", "11.0"),
            ("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "7.0"),
            ("BIOHUB_DENSITY_MIDDLE_RELAXED_UM", "9.0"),
            ("BIOHUB_DENSITY_HIGH_TIGHT_UM", "5.5"),
            ("BIOHUB_DENSITY_HIGH_RELAXED_UM", "10.0"),
        ],
        "note": "middle bucket 6.5 -> 7.0; top of the held-out sweep",
    },
    "biohub-sep19-dlow800": {
        "title": "Biohub Sep19 Density Low 800",
        "env": [
            ("BIOHUB_DENSITY_ADAPTIVE_RELINK", "1"),
            ("BIOHUB_DENSITY_LOW_TIGHT_UM", "8.0"),
            ("BIOHUB_DENSITY_LOW_RELAXED_UM", "11.0"),
            ("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "6.5"),
            ("BIOHUB_DENSITY_MIDDLE_RELAXED_UM", "9.0"),
            ("BIOHUB_DENSITY_HIGH_TIGHT_UM", "5.5"),
            ("BIOHUB_DENSITY_HIGH_RELAXED_UM", "10.0"),
        ],
        "note": "low bucket 7.25 -> 8.0; second in the held-out sweep",
    },
    "biohub-sep19-dlow650": {
        "title": "Biohub Sep19 Density Low 650",
        "env": [
            ("BIOHUB_DENSITY_ADAPTIVE_RELINK", "1"),
            ("BIOHUB_DENSITY_LOW_TIGHT_UM", "6.5"),
            ("BIOHUB_DENSITY_LOW_RELAXED_UM", "11.0"),
            ("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "6.5"),
            ("BIOHUB_DENSITY_MIDDLE_RELAXED_UM", "9.0"),
            ("BIOHUB_DENSITY_HIGH_TIGHT_UM", "5.5"),
            ("BIOHUB_DENSITY_HIGH_RELAXED_UM", "10.0"),
        ],
        "note": "low bucket 7.25 -> 6.5; brackets the low optimum from below (+0.0018)",
    },
    "biohub-sep19-dhigh600": {
        "title": "Biohub Sep19 Density High 600",
        "env": [
            ("BIOHUB_DENSITY_ADAPTIVE_RELINK", "1"),
            ("BIOHUB_DENSITY_LOW_TIGHT_UM", "7.25"),
            ("BIOHUB_DENSITY_LOW_RELAXED_UM", "11.0"),
            ("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "6.5"),
            ("BIOHUB_DENSITY_MIDDLE_RELAXED_UM", "9.0"),
            ("BIOHUB_DENSITY_HIGH_TIGHT_UM", "6.0"),
            ("BIOHUB_DENSITY_HIGH_RELAXED_UM", "10.0"),
        ],
        "note": "high bucket 5.5 -> 6.0; the densest videos carry the most public weight",
    },
    # Both sweep winners together. The sweep's own greedy combo scored the same
    # as dmid700 alone, which suggests the two are not additive - this tests
    # that directly rather than assuming it.
    "biohub-sep19-dboth": {
        "title": "Biohub Sep19 Density Middle 700 Low 800",
        "env": [
            ("BIOHUB_DENSITY_ADAPTIVE_RELINK", "1"),
            ("BIOHUB_DENSITY_LOW_TIGHT_UM", "8.0"),
            ("BIOHUB_DENSITY_LOW_RELAXED_UM", "11.0"),
            ("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "7.0"),
            ("BIOHUB_DENSITY_MIDDLE_RELAXED_UM", "9.0"),
            ("BIOHUB_DENSITY_HIGH_TIGHT_UM", "5.5"),
            ("BIOHUB_DENSITY_HIGH_RELAXED_UM", "10.0"),
        ],
        "note": "both sweep winners; tests whether they are additive",
    },
    # The low bucket keeps improving as it widens: 6.5 -> 7.25 -> 8.0, with 8.0
    # the only candidate the restricted paired test supports over arm F
    # (+0.00070, 5/2, CI excludes zero). This extends the gradient to find where
    # it turns, the same way MOTION_RELINK_TIGHT_UM 6.0/5.5/5.0 located that peak.
    "biohub-sep19-dlow900": {
        "title": "Biohub Sep19 Density Low 900",
        "env": [
            ("BIOHUB_DENSITY_ADAPTIVE_RELINK", "1"),
            ("BIOHUB_DENSITY_LOW_TIGHT_UM", "9.0"),
            ("BIOHUB_DENSITY_LOW_RELAXED_UM", "12.0"),
            ("BIOHUB_DENSITY_MIDDLE_TIGHT_UM", "6.5"),
            ("BIOHUB_DENSITY_MIDDLE_RELAXED_UM", "9.0"),
            ("BIOHUB_DENSITY_HIGH_TIGHT_UM", "5.5"),
            ("BIOHUB_DENSITY_HIGH_RELAXED_UM", "10.0"),
        ],
        "note": "low bucket 8.0 -> 9.0; extends the only supported gradient",
    },
}


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    base = json.loads(notebook_path.read_text())
    base_metadata = json.loads((SOURCE / "kernel-metadata.json").read_text())

    for slug, spec in ARMS.items():
        nb = json.loads(notebook_path.read_text())
        before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

        block = PINNED_HEADER + "\n".join(
            f'os.environ["{k}"] = "{v}"' for k, v in spec["env"])
        edits = {
            "pin": (ANCHOR, block),
            "flags": (FLAG_ANCHOR, FLAG_NEW),
            "relink": (RELINK_ANCHOR, RELINK_NEW),
            "pass": (PASS_ANCHOR, PASS_NEW),
        }
        counts = {k: 0 for k in edits}
        for cell in nb["cells"]:
            if cell["cell_type"] != "code":
                continue
            text = "".join(cell["source"])
            touched = False
            for name, (old, new) in edits.items():
                if old in text:
                    counts[name] += text.count(old)
                    text = text.replace(old, new, 1)
                    touched = True
            if touched:
                cell["source"] = text.splitlines(keepends=True)
        for name, hits in counts.items():
            if hits != 1:
                raise RuntimeError(f"{slug}/{name}: expected one match, found {hits}")

        after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
        changed = [i for i, (a, b) in enumerate(zip(before, after)) if a != b]
        if changed != [0, 2, 5]:
            raise RuntimeError(f"{slug}: unexpected cells changed: {changed}")

        # The old global must no longer be read inside the assignment loop, or
        # the density gate would be computed and then silently ignored.
        pipeline_after = after[5]
        if PASS_ANCHOR in pipeline_after:
            raise RuntimeError(f"{slug}: the pass loop still reads the global gate")
        for guard in ("linear_sum_assignment", "def add_safe_divisions_postlink",
                      "MOTION_RELINK_VELOCITY_WEIGHT", "MOTION_RELINK_MAX_FRAME_NODES"):
            if sum(s.count(guard) for s in before) != sum(s.count(guard) for s in after):
                raise RuntimeError(f"{slug}: {guard} occurrences changed")

        out_dir = WORKSPACE / "notebooks" / slug
        out_dir.mkdir(parents=True, exist_ok=True)
        out = out_dir / f"{slug}.ipynb"
        out.write_text(json.dumps(nb, indent=1) + "\n")

        metadata = dict(base_metadata)
        metadata["id"] = f"dalloliogm/{re.sub(r'[^a-z0-9]+', '-', spec['title'].lower()).strip('-')}"
        metadata["title"] = spec["title"]
        metadata["code_file"] = out.name
        metadata["is_private"] = True
        for key in ("id_no", "docker_image"):
            metadata.pop(key, None)
        (out_dir / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
        print(f"wrote {slug}\n    {spec['note']}\n    id={metadata['id']}")


if __name__ == "__main__":
    main()
