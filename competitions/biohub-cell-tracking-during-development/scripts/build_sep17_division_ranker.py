#!/usr/bin/env python3
"""Rank candidate divisions by learned evidence instead of by geometry.

## Where this came from

A public notebook (`megayak/the-0-966-notebooks-used-a-patched-metric-bug`,
2026-09-16) argues that the division term is a *ranking* problem, not a gating
problem. Two of its claims were checked against our own source before anything
here was built, and both hold:

1. **Our fork ranker is pure geometry, ascending.** In
   `add_safe_divisions_postlink`:

       score = parent_dist + 0.15 * sister_dist
       proposals.sort(key=lambda item: item[0])

   Tightest pair first. Tightest pairs are duplicate detections, not divisions,
   so the per-frame budget is spent on duplicates before a real division is
   reached. Opening the geometry gates alone therefore makes things *worse* -
   the notebook measured 0.9508 -> 0.9341 end to end - because a larger
   candidate pool ranked the same way just buries the real forks deeper.

2. **DeepCenter already computes the evidence and we throw it away.**
   `deepcenter_score_point` returns a float mitosis score;
   `deepcenter_accept_repair_point` calls it, compares to a threshold, and
   returns a *bool*. The number is discarded, and ranking falls back to
   geometry.

So the learned signal needed to rank forks on evidence is already being
computed in the pipeline, once per candidate, and then dropped.

## What this changes

`BIOHUB_SAFE_DIV_RANK_BY_DEEPCENTER=1` makes the ranking key the DeepCenter
score, negated so the existing ascending sort puts the most confident candidate
first. Everything else is untouched: the veto still runs exactly as before, with
the same threshold and the same stats counters, so with the flag off the
notebook is unchanged. The extra `deepcenter_score_point` call hits the same
`(dataset, t)` heatmap cache the veto just populated, so it costs a dictionary
lookup, not a forward pass.

## The three arms

Ranking and gating have to be tested together, because the argument is that
neither fixes anything alone:

- **A `rank`** - evidence ranking, gates exactly as shipped. Isolates the
  ranking change against the scored baseline. If ranking is the binding
  constraint, this alone should move.
- **B `rank-open`** - evidence ranking with the divergence and symmetry gates
  off. This is the combination the source argues for: gates open so real
  divisions are reachable, evidence ranking so the budget is not spent on
  duplicates.
- **C `rank-mid`** - evidence ranking with the gates half-open
  (`DIVERGE_UM=0.0`, `SYMMETRY_TAU=1.2`). A middle point, so a null result on B
  can be told apart from "opened too far".

## A caveat that matters for reading the results

Our offline division metric is **not** the official one. `metrics.md` was
patched on 2026-07-17 to require a *local* fork - the matched parent or its
immediate successor, with the daughters on two distinct direct-child branches -
but `compute_division_confusion` in our notebook still accepts any fork
anywhere in the anchor's weakly-connected component. It is strictly more
permissive, so it over-reports division Jaccard. Our local 0.2308 is inflated,
and every safe-division threshold tuned against it was steered by a loose
instrument. Read these three arms on the leaderboard, not on the local number,
until that metric is fixed separately.
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
    '# Pinned fast base (verified byte-identical to the scored 0.946 in 24.9 min\n'
    '# instead of 106.1), so each arm differs only in how forks are ranked/gated.\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
    'os.environ["BIOHUB_MOTION_RELINK_TIGHT_UM"] = "5.5"\n'
)

# Read the flag next to the other safe-division constants.
OLD_FLAG_ANCHOR = 'SAFE_DIV_SISTER_SYMMETRY_TAU = float(os.environ.get("BIOHUB_SAFE_DIV_SISTER_SYMMETRY_TAU", "0.0"))'
NEW_FLAG_ANCHOR = OLD_FLAG_ANCHOR + (
    '\nSAFE_DIV_RANK_BY_DEEPCENTER = os.environ.get("BIOHUB_SAFE_DIV_RANK_BY_DEEPCENTER", "0") != "0"'
)

OLD_SCORE = """                score = parent_dist + 0.15 * sister_dist
                proposals.append((score, source_id, candidate_id, parent_dist, sister_dist))"""

NEW_SCORE = """                # Geometry ranks the tightest pair first, and the tightest pairs are
                # duplicate detections rather than divisions, so the per-frame budget
                # is spent before a real fork is reached. DeepCenter already scored
                # this exact point for the veto above and the number was discarded;
                # reuse it as the ranking key, negated so the ascending sort below
                # puts the most confident candidate first. The heatmap for
                # (dataset, t) is already in the cache, so this is a lookup.
                if SAFE_DIV_RANK_BY_DEEPCENTER:
                    _dc_rank = deepcenter_score_point(
                        dataset,
                        int(candidate["t"]),
                        node_point(candidate),
                        deepcenter_bundle,
                        frame_cache,
                        deepcenter_cache,
                    )
                    score = -float(_dc_rank) if _dc_rank is not None else 0.0
                else:
                    score = parent_dist + 0.15 * sister_dist
                proposals.append((score, source_id, candidate_id, parent_dist, sister_dist))"""

ARMS = {
    "biohub-sep17-divrank": {
        "title": "Biohub Sep17 Division Rank Deepcenter",
        "env": [("BIOHUB_SAFE_DIV_RANK_BY_DEEPCENTER", "1")],
        "note": "A: evidence ranking, gates exactly as shipped. Isolates the ranking change.",
    },
    "biohub-sep17-divrank-open": {
        "title": "Biohub Sep17 Division Rank Gates Open",
        "env": [
            ("BIOHUB_SAFE_DIV_RANK_BY_DEEPCENTER", "1"),
            ("BIOHUB_SAFE_DIV_REQUIRE_DIVERGENCE", "0"),
            ("BIOHUB_SAFE_DIV_SISTER_SYMMETRY_TAU", "0.0"),
        ],
        "note": "B: evidence ranking with divergence and symmetry gates off.",
    },
    "biohub-sep17-divrank-mid": {
        "title": "Biohub Sep17 Division Rank Gates Mid",
        "env": [
            ("BIOHUB_SAFE_DIV_RANK_BY_DEEPCENTER", "1"),
            ("BIOHUB_SAFE_DIV_DIVERGE_UM", "0.0"),
            ("BIOHUB_SAFE_DIV_SISTER_SYMMETRY_TAU", "1.2"),
        ],
        "note": "C: evidence ranking with the gates half-open.",
    },
    # Arm B moves two things at once - ranking AND gating - so on its own it
    # cannot say which one mattered. This is the control: identical gates to B,
    # but the original geometry ranker. B minus D is the ranking effect at a
    # pool size where the cap actually binds (B skipped 57 candidates on the
    # cap; the shipped-gate arm skipped none, which is why ranking was inert
    # there).
    "biohub-sep17-geomrank-open": {
        "title": "Biohub Sep17 Geometry Rank Gates Open",
        "env": [
            ("BIOHUB_SAFE_DIV_REQUIRE_DIVERGENCE", "0"),
            ("BIOHUB_SAFE_DIV_SISTER_SYMMETRY_TAU", "0.0"),
        ],
        "note": "D: CONTROL - gates off exactly as in B, but the original geometry ranker.",
    },
}


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    base = json.loads(notebook_path.read_text())
    base_metadata = json.loads((SOURCE / "kernel-metadata.json").read_text())
    joined = "\n".join(
        "".join(c["source"]) for c in base["cells"] if c["cell_type"] == "code")

    # Every knob an arm sets must actually be read from the environment.
    for slug, spec in ARMS.items():
        for key, _v in spec["env"]:
            if key == "BIOHUB_SAFE_DIV_RANK_BY_DEEPCENTER":
                continue  # introduced by this patch
            if f'os.environ.get("{key}"' not in joined:
                raise RuntimeError(f"{slug}: {key} is not read from the environment")
    # The ranker must be able to see the names it calls.
    for name in ("def deepcenter_score_point", "def node_point", "deepcenter_cache", "frame_cache"):
        if name not in joined:
            raise RuntimeError(f"{name} not present; the ranking patch would NameError at run time")

    for slug, spec in ARMS.items():
        nb = json.loads(notebook_path.read_text())
        before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

        block = PINNED_HEADER + "\n".join(
            f'os.environ["{k}"] = "{v}"' for k, v in spec["env"])
        edits = {"pin": (ANCHOR, block), "flag": (OLD_FLAG_ANCHOR, NEW_FLAG_ANCHOR),
                 "score": (OLD_SCORE, NEW_SCORE)}
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
        # 0 = env block, 2 = post-process constants (where the new flag is read),
        # 5 = pipeline (where the ranking key is chosen). Nothing else may move.
        if changed != [0, 2, 5]:
            raise RuntimeError(f"{slug}: only config and pipeline cells may change, got {changed}")

        # The veto itself must stay exactly as it was: this experiment changes
        # ranking, not admission, so the accept/reject call must be untouched.
        for guard in ("deepcenter_accept_repair_point", "DEEPCENTER_SAFE_DIV_THRESHOLD",
                      "linear_sum_assignment", "MOTION_RELINK_VELOCITY_WEIGHT"):
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
