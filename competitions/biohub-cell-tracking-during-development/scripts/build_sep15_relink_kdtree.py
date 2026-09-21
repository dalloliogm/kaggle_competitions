#!/usr/bin/env python3
"""Remove the quadratic term from the motion-relink assignment pass.

## Why this and not another config variant

The private score comes from re-executing the kernel on a hidden test set of
roughly 199 samples. The pinned fast base takes 22.7 min on 4 test videos, and
the per-video cost extrapolates to about 15 h against a 12 h limit - a kernel
that does not finish scores nothing, so runtime, not accuracy, is the binding
constraint.

## Where the time actually goes

Timestamps from the 2026-09-14 `biohub-sep14-motion-relink-tight-50` log
(total 1362 s), by phase:

    setup + model artifacts            258 s   fixed
    detection inference (2 GPU shards) 579 s   per video
    association                        253 s   per video
    graph construction                 254 s   per video

Within graph construction, the per-video split is not uniform - it is
super-linear in the number of cells:

      6 303 raw nodes ->   1.7 s
     22 507 raw nodes ->  16.6 s
     25 821 raw nodes ->  20.7 s
     70 697 raw nodes -> 150.7 s

A 2.74x increase in nodes costs 7.28x the time: a log-log slope of 1.97, i.e.
**quadratic**. That matters far more than the 19% share suggests, because a
linear per-video extrapolation to the hidden test understates the cost of any
sample larger than the four we can see.

## The quadratic term

`assign_pass` inside `motion_relink_edges` allocates four dense
`len(sources) x len(targets)` float64 matrices per frame per pass and fills them
with a pure-Python double loop, calling `np.linalg.norm` on a 3-vector for every
pair. On the largest video that is ~714 cells per frame over 99 frames, so about
50 M inner iterations - and the `raw > gate_um` test then discards nearly all of
them. The tight pass carries ~91% of matches, so this full matrix is the cost;
the relaxed pass runs on the ~9% left unmatched and is negligible.

## Why a KD-tree and not vectorisation

The obvious fix - compute the pair distances with one vectorised
`np.linalg.norm(..., axis=-1)` - is 4.2x faster but **not bit-exact**. A 1-D
`np.linalg.norm` goes through BLAS `ddot`, which may fuse multiply-add, while an
axis reduction does not; the two disagree in the last bit on a few cells per
frame. Those matrices feed `linear_sum_assignment`, so a last-bit difference can
flip a match, change an edge and change the submission. Measured on 120- to
2000-cell frames: differences up to 3.6e-15 on ~200 of 1.4 M cells. Fast, and
unusable.

This instead keeps **every arithmetic operation of the original untouched** -
the same scalar `np.linalg.norm` call, the same `raw > gate_um` test, the same
cost expression - and uses a KD-tree purely as a *superset* filter so the loop
never visits pairs the gate would reject. The tree radius is padded by 1e-9
relative, far beyond the ~1e-16 slack between two float64 distance evaluations,
so no pair the exact test would accept can be dropped; the exact test still
makes every accept/reject decision. The matrices are identical by construction.

Verified locally against a verbatim transcription of the original, on frames of
120-2600 cells and at densities from 1 to 370 in-gate neighbours per cell
(real frames hold 73-848 cells; the pipeline skips frames above
MOTION_RELINK_MAX_FRAME_NODES = 2600):

    bit-identical on all four matrices at every point tested
    20-50x faster in the real density regime
    1.1x - never slower - in the degenerate all-pairs-inside-gate case

## Pass criterion

This changes an implementation, not a configuration, so the submission must come
out **byte-identical to the scored 0.946 artifact** (sha a852d1d0...795b3e). The
sha check is the experiment: if it matches, the rewrite is proven equivalent and
the measured wall-clock drop is a free saving. If it does not match, the rewrite
is wrong and nothing gets submitted.

This costs GPU time and no submission slot.
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
OUT_DIR = WORKSPACE / "notebooks" / "sep15-relink-kdtree"
TITLE = "Biohub Sep15 Motion Relink KDTree Exact"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

EXPECTED_SHA = "a852d1d07ff8c9307d9b10db7f9b4b12e8b1882f14c5dbeb1316d099f0795b3e"

# Pin the sweep's stable selection and skip the validator, so this run is
# directly comparable to the verified pinned base and the expected sha is known.
VALIDATOR_LINE = 'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "4"'
PINNED = (
    '# Same pinned fast base as the verified byte-identical 0.946 run, so the\n'
    '# only difference in this kernel is how assign_pass finds candidate pairs.\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
    'os.environ["BIOHUB_MOTION_RELINK_TIGHT_UM"] = "5.5"'
)

# The exact original inner loop, matched verbatim so a drifted source fails loudly.
OLD_LOOP = '''        for i, source_id in enumerate(source_ids):
            source_pos = position_um[source_id]
            prev_pos = predecessor_position_um.get(source_id)
            if prev_pos is None:
                predicted = source_pos
            else:
                predicted = source_pos + MOTION_RELINK_VELOCITY_WEIGHT * (source_pos - prev_pos)
            for j, target_id in enumerate(target_ids):
                target_pos = position_um[target_id]
                raw = float(np.linalg.norm(target_pos - source_pos))
                if raw > gate_um:
                    continue
                motion = float(np.linalg.norm(target_pos - predicted))
                prob = learned_prob(source_id, target_id)
                raw_dist[i, j] = raw
                motion_dist[i, j] = motion
                prob_matrix[i, j] = prob
                cost[i, j] = motion + 0.05 * raw - MOTION_RELINK_LEARNED_BONUS * prob
'''

NEW_LOOP = '''        # The gate rejects nearly every pair, so visiting all of them is the
        # quadratic term that dominates graph construction on large videos. The
        # KD-tree is a superset filter only: its radius is padded far beyond the
        # float64 slack between two distance evaluations, and the original exact
        # `raw > gate_um` test below still makes every accept/reject decision,
        # so the matrices are bit-identical to the all-pairs version.
        _relink_tree = cKDTree(np.stack([position_um[t] for t in target_ids], axis=0))
        _relink_radius = gate_um * (1.0 + 1e-9) + 1e-9
        for i, source_id in enumerate(source_ids):
            source_pos = position_um[source_id]
            prev_pos = predecessor_position_um.get(source_id)
            if prev_pos is None:
                predicted = source_pos
            else:
                predicted = source_pos + MOTION_RELINK_VELOCITY_WEIGHT * (source_pos - prev_pos)
            for j in _relink_tree.query_ball_point(source_pos, _relink_radius):
                target_id = target_ids[j]
                target_pos = position_um[target_id]
                raw = float(np.linalg.norm(target_pos - source_pos))
                if raw > gate_um:
                    continue
                motion = float(np.linalg.norm(target_pos - predicted))
                prob = learned_prob(source_id, target_id)
                raw_dist[i, j] = raw
                motion_dist[i, j] = motion
                prob_matrix[i, j] = prob
                cost[i, j] = motion + 0.05 * raw - MOTION_RELINK_LEARNED_BONUS * prob
'''


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    # cKDTree must already be in scope in the cell that defines assign_pass,
    # or the rewrite would raise NameError at run time rather than here.
    pipeline = [s for s in before if "def motion_relink_edges(" in s]
    if len(pipeline) != 1:
        raise RuntimeError(f"expected one cell defining motion_relink_edges, found {len(pipeline)}")
    if "from scipy.spatial import cKDTree" not in pipeline[0]:
        raise RuntimeError("cKDTree is not imported in the pipeline cell")

    edits = {"loop": (OLD_LOOP, NEW_LOOP), "pin": (VALIDATOR_LINE, PINNED)}
    counts = {name: 0 for name in edits}
    for cell in nb["cells"]:
        if cell["cell_type"] != "code":
            continue
        text = "".join(cell["source"])
        changed = False
        for name, (old, new) in edits.items():
            if old in text:
                counts[name] += text.count(old)
                text = text.replace(old, new, 1)
                changed = True
        if changed:
            cell["source"] = text.splitlines(keepends=True)
    for name, hits in counts.items():
        if hits != 1:
            raise RuntimeError(f"{name}: expected exactly one match, found {hits}")

    after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    changed = [i for i, (a, b) in enumerate(zip(before, after)) if a != b]
    if changed != [0, 5]:
        raise RuntimeError(f"only the config and pipeline cells may change, got {changed}")

    # Nothing that shapes the tracking result may move: this is an
    # implementation change, so every tuned constant must be untouched.
    for guard in ("BIOHUB_SAFE_DIV", "BIOHUB_DET_THRESHOLD", "BIOHUB_OUTPUT_LINEFIT",
                  "MOTION_RELINK_VELOCITY_WEIGHT", "MOTION_RELINK_LEARNED_BONUS",
                  "MOTION_RELINK_RELAXED_UM", "linear_sum_assignment"):
        if sum(s.count(guard) for s in before) != sum(s.count(guard) for s in after):
            raise RuntimeError(f"{guard} occurrences changed; the pipeline must stay fixed")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"{SLUG}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")

    metadata = json.loads((SOURCE / "kernel-metadata.json").read_text())
    metadata["id"] = f"dalloliogm/{SLUG}"
    metadata["title"] = TITLE
    metadata["code_file"] = out.name
    metadata["is_private"] = True
    for key in ("id_no", "docker_image"):
        metadata.pop(key, None)
    (OUT_DIR / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")

    print(f"wrote {out.relative_to(WORKSPACE)}")
    print("  assign_pass now gates candidates through cKDTree; arithmetic untouched")
    print(f"  PASS criterion: submission sha == {EXPECTED_SHA[:16]}...")


if __name__ == "__main__":
    main()
