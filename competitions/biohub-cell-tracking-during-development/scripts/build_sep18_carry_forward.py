#!/usr/bin/env python3
"""The carry-forward configuration: KD-tree relink AND the density-adaptive low bucket.

## The gap this closes

Two changes have been validated independently and were never combined:

* **KD-tree relink** (2026-09-15) - removes the quadratic term from
  `assign_pass`. Verified byte-identical output (sha a852d1d0...795b3e) with
  relink falling 190.0 s -> 7.7 s over four videos, moving the ~199-sample
  projection from 15.09 h to 12.79 h against the 12 h limit.
* **Density-adaptive low bucket** (2026-09-18, arm E) - widens the relink gate
  only where cells are sparse. Paired over 24 held-out videos against
  `tight55`: +0.00167 adjusted edge Jaccard, 95% CI [+0.00032, +0.00354]
  excluding zero, losing on 2 of 24, leave-one-out stable at +0.00110.

Both edit `motion_relink_edges`, and both were built from the same unpatched
source, so **neither contains the other**. Measured on the arm E run:

    baseline (KD-tree)   total 1264.6 s   graph  74.3 s   relink   7.7 s
    arm E (density)      total 1399.6 s   graph 300.5 s   relink 219.3 s

Arm E's per-video relink profile - 24.2 / 19.3 / 1.9 / 174.0 s - is the
original quadratic signature. Carrying arm E forward as submitted would
therefore **discard the entire runtime fix**: its per-video cost rises to about
286 s, projecting ~15.8 h, which is worse than the 15.09 h we started from and
a guaranteed timeout on the private rerun. A configuration that times out
scores nothing, whatever its held-out Jaccard.

## Why they compose cleanly

The two patches touch disjoint regions of the same function:

* the density gate is computed *before* `position_um`, and consumed by the
  `for pass_name, gate_um in (...)` loop *after* `assign_pass`;
* the KD-tree change is entirely *inside* `assign_pass`, in the candidate loop.

`assign_pass` already receives `gate_um` as a parameter, so it needs no
knowledge of where the gate came from - the KD-tree radius derives from the
same `gate_um` the density logic now supplies. Nothing needs reconciling.

## Expected result

Density-adaptive output (not byte-identical to the 0.946 artifact - that is the
point, arm E changes 45 rows) at KD-tree speed. The check is that relink
returns to single-digit seconds while the per-video density groups still
resolve to low/middle/middle/high, and that the submission sha matches arm E's
`bbca0613...` exactly - proving the speedup changed timing and nothing else.
"""

from __future__ import annotations

import importlib.util
import json
import os
import re
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
WORKSPACE = SCRIPTS.parent
SOURCE = Path(
    "/tmp/claude-0/-home-user-kaggle-competitions/"
    "079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad/audit946"
)
OUT_DIR = WORKSPACE / "notebooks" / (
    "sep19-carry-forward-full" if os.environ.get("CARRY_ARM", "").endswith("full")
    else "sep18-carry-forward")
TITLE = ("Biohub Sep19 Carry Forward KDTree Density Full"
         if os.environ.get("CARRY_ARM", "").endswith("full")
         else "Biohub Sep18 Carry Forward KDTree Density Low")
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

ARM_E_SHA = "bbca0613a4a7a19ba7e18d23be9e66e9133bb4abeefafdedf13998160f14ff23"


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


kdtree = _load("build_sep15_relink_kdtree")
density = _load("build_sep18_density_adaptive")

# Which validated density arm to carry, plus the pinned fast base.
_ARM = os.environ.get("CARRY_ARM", "biohub-sep18-density-low-only")
ARM_E_ENV = density.ARMS[_ARM]["env"]
CONFIG_BLOCK = (
    '# Carry-forward: the KD-tree relink speedup (verified byte-identical) plus\n'
    '# the density-adaptive low bucket (paired CI excludes zero on 24 videos).\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
    'os.environ["BIOHUB_MOTION_RELINK_TIGHT_UM"] = "5.5"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"' for k, v in ARM_E_ENV)
)


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    # The two patches must not overlap, or applying both would corrupt one.
    pipeline = before[5]
    spans = {}
    for name, anchor in (("kdtree", kdtree.OLD_LOOP),
                         ("density_gate", density.RELINK_ANCHOR),
                         ("density_pass", density.PASS_ANCHOR)):
        at = pipeline.find(anchor)
        if at < 0:
            raise RuntimeError(f"{name} anchor not found in the pipeline cell")
        spans[name] = (at, at + len(anchor))
    ordered = sorted(spans.items(), key=lambda kv: kv[1][0])
    for (n1, (_s1, e1)), (n2, (s2, _e2)) in zip(ordered, ordered[1:]):
        if e1 > s2:
            raise RuntimeError(f"patch regions {n1} and {n2} overlap; cannot compose")
    print("  patch order in cell 5: " + " -> ".join(n for n, _ in ordered))

    edits = {
        "config": (density.ANCHOR, CONFIG_BLOCK),
        "flags": (density.FLAG_ANCHOR, density.FLAG_NEW),
        "gate": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        "kdtree": (kdtree.OLD_LOOP, kdtree.NEW_LOOP),
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
            raise RuntimeError(f"{name}: expected one match, found {hits}")

    after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    changed = [i for i, (a, b) in enumerate(zip(before, after)) if a != b]
    if changed != [0, 2, 5]:
        raise RuntimeError(f"unexpected cells changed: {changed}")

    pipeline_after = after[5]
    # Both changes must be live, not merely present.
    if density.PASS_ANCHOR in pipeline_after:
        raise RuntimeError("the pass loop still reads the global gate; density gate is inert")
    if "_relink_tree" not in pipeline_after or "query_ball_point" not in pipeline_after:
        raise RuntimeError("the KD-tree candidate filter is missing")
    if "for j, target_id in enumerate(target_ids):" in pipeline_after:
        raise RuntimeError("the original all-pairs loop survives; KD-tree patch is inert")
    # The KD-tree radius must derive from the parameter the density logic feeds in.
    if "gate_um * (1.0 + 1e-9)" not in pipeline_after:
        raise RuntimeError("KD-tree radius is not derived from gate_um")
    for guard in ("linear_sum_assignment", "MOTION_RELINK_VELOCITY_WEIGHT",
                  "def add_safe_divisions_postlink", "def write_test_submission"):
        if sum(s.count(guard) for s in before) != sum(s.count(guard) for s in after):
            raise RuntimeError(f"{guard} occurrences changed")

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
    print("  both patches applied and asserted live")
    print(f"  PASS criterion: submission sha == {ARM_E_SHA[:16]}... (arm E) with")
    print("  relink back to single-digit seconds")


if __name__ == "__main__":
    main()
