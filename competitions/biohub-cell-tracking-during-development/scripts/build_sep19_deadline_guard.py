#!/usr/bin/env python3
"""A deadline guard: degrade the last samples instead of scoring nothing.

## The problem this solves

The private score comes from re-running the kernel on ~199 hidden samples inside
a 12 h limit. Our best measured projection, with the KD-tree relink and the
density-adaptive gate, is **12.69 h**. That is over the line. A kernel that does
not finish scores **zero**, so as things stand the most likely private outcome
is not a slightly lower score - it is no score at all.

Every runtime avenue left is either unexamined (association, 31% of per-video
cost) or changes the output and needs its own evidence (`EDGE_TTA views=8`,
61%). Neither is guaranteed to land in the days remaining.

## The idea, from a public notebook

`thtennant/biohub-frontier947-fast-det096-tight60-v1` carries a deadline
degradation guard:

    if not _deadline_degraded and _dataset_t0 - KERNEL_START_TS > REPAIR_DEADLINE_S:
        _deadline_degrade()   # disables motion relink, gap close, gap2 recovery

Instead of betting that the run fits, it measures elapsed wall time before each
dataset and, once past a deadline, switches off the expensive optional repairs
for everything remaining. The early samples get full quality; the late ones get
a cheaper pipeline; the run finishes.

This is insurance, not a gamble. If the hidden test turns out faster than
projected the guard never fires and the output is unchanged. If it turns out
slower, we return a complete submission at slightly reduced quality instead of
nothing.

## What is degraded, and why these three

`OUTPUT_MOTION_RELINK`, `OUTPUT_GAP_CLOSE` and `OUTPUT_GAP2_RECOVERY` are the
optional graph repairs. They are exactly the stages whose per-video cost we have
measured, and they are additive improvements over a graph that is already valid
without them - so switching them off degrades quality rather than producing a
malformed submission. Detection, association and the ILP are untouched, because
the graph cannot be built without them.

## Deadline choice

`BIOHUB_REPAIR_DEADLINE_S` defaults to 37800 s (10.5 h), leaving ~1.5 h of the
12 h limit for the remaining samples at the cheaper rate plus notebook
conversion. It is an environment variable so it can be tightened without a
rebuild.

## Verification on the public test

Four test videos take ~20 min, far inside any sane deadline, so the guard must
**never fire** there and the submission must come out byte-identical to the arm
it carries. That is the check: same sha, plus `deadline_degraded=0` in the
stats. A guard that changed the output when it was not supposed to fire would be
worse than no guard at all.

This costs GPU time and no submission slot.
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
OUT_DIR = WORKSPACE / "notebooks" / "sep19-deadline-guard"
TITLE = "Biohub Sep19 Deadline Guard Density Full"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

ARM_F_SHA = "fe6f0a6fe5c996b876cd40f85b9cef75421be5e959a5cd859c33fa339888a8d9"


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


kdtree = _load("build_sep15_relink_kdtree")
density = _load("build_sep18_density_adaptive")

ARM_ENV = density.ARMS["biohub-sep18-density-full"]["env"]
CONFIG_BLOCK = (
    '# Deadline-guarded carry-forward: KD-tree relink + density-adaptive gate\n'
    '# (arm F, the configuration both instruments support), plus a wall-clock\n'
    '# guard so an overrun degrades the tail instead of scoring zero.\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
    'os.environ["BIOHUB_MOTION_RELINK_TIGHT_UM"] = "5.5"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"' for k, v in ARM_ENV)
)

# Declared next to the other output-stage constants.
GUARD_ANCHOR = 'DENSITY_ADAPTIVE_RELINK = os.environ.get("BIOHUB_DENSITY_ADAPTIVE_RELINK", "0") != "0"'
GUARD_NEW = GUARD_ANCHOR + '''
# Wall-clock deadline guard. The private rerun processes ~199 samples inside a
# 12 h limit and our best projection is 12.69 h, so an overrun is the likeliest
# failure. Past the deadline the optional graph repairs are switched off for
# every remaining dataset: the tail degrades, the run still finishes, and a
# complete lower-quality submission beats no submission.
import time as _time
KERNEL_START_TS = _time.time()
REPAIR_DEADLINE_S = float(os.environ.get("BIOHUB_REPAIR_DEADLINE_S", "37800"))
_deadline_degraded = False


def _deadline_degrade() -> None:
    """Disable the optional repairs. Detection, association and the ILP are
    untouched - the graph cannot be built without them, and these three are
    additive repairs over a graph that is already valid."""
    global _deadline_degraded, OUTPUT_MOTION_RELINK, OUTPUT_GAP_CLOSE, OUTPUT_GAP2_RECOVERY
    _deadline_degraded = True
    OUTPUT_MOTION_RELINK = False
    OUTPUT_GAP_CLOSE = False
    OUTPUT_GAP2_RECOVERY = False
    print(f"DEADLINE GUARD: {_time.time() - KERNEL_START_TS:.0f}s elapsed exceeds "
          f"{REPAIR_DEADLINE_S:.0f}s -- optional repairs disabled for the remaining datasets")'''

# Fires once per dataset, at the top of post-processing.
HOOK_ANCHOR = '''def filter_output_graph('''
HOOK_MARKER = '    stats = {\n        "raw_edges": len(raw_edges),'

DEGRADE_CHECK = '''    global _deadline_degraded
    if not _deadline_degraded and _time.time() - KERNEL_START_TS > REPAIR_DEADLINE_S:
        _deadline_degrade()
'''
STATS_EXTRA = '''
        "deadline_degraded": int(_deadline_degraded),
        "kernel_elapsed_seconds": int(_time.time() - KERNEL_START_TS),'''


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    # The three constants the guard flips must exist and be read at call time
    # from module globals, or degrading them would be a silent no-op.
    for name in ("OUTPUT_MOTION_RELINK", "OUTPUT_GAP_CLOSE", "OUTPUT_GAP2_RECOVERY"):
        if f"{name} = " not in before[2]:
            raise RuntimeError(f"{name} is not a module-level constant; the guard could not flip it")

    pipeline = before[5]
    at = pipeline.find(HOOK_ANCHOR)
    if at < 0:
        raise RuntimeError("filter_output_graph not found")
    marker_at = pipeline.find(HOOK_MARKER, at)
    if marker_at < 0:
        raise RuntimeError("could not find the stats dict opening inside filter_output_graph")
    hook_target = pipeline[marker_at:marker_at + len(HOOK_MARKER)]

    edits = {
        "config": (density.ANCHOR, CONFIG_BLOCK),
        "flags": (density.FLAG_ANCHOR, density.FLAG_NEW),
        "guard": (GUARD_ANCHOR, GUARD_NEW),
        "gate": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        "kdtree": (kdtree.OLD_LOOP, kdtree.NEW_LOOP),
        "hook": (hook_target, DEGRADE_CHECK + hook_target + STATS_EXTRA),
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
    if "_deadline_degrade()" not in after[5]:
        raise RuntimeError("the guard is declared but never called")
    if "query_ball_point" not in after[5] or density.PASS_ANCHOR in after[5]:
        raise RuntimeError("KD-tree or density patch inert")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"{SLUG}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")
    metadata = json.loads((SOURCE / "kernel-metadata.json").read_text())
    metadata.update({"id": f"dalloliogm/{SLUG}", "title": TITLE,
                     "code_file": out.name, "is_private": True})
    for key in ("id_no", "docker_image"):
        metadata.pop(key, None)
    (OUT_DIR / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")

    print(f"wrote {out.relative_to(WORKSPACE)}")
    print(f"  deadline {float(os.environ.get('BIOHUB_REPAIR_DEADLINE_S', '37800')) / 3600:.1f} h")
    print(f"  PASS: guard must NOT fire on 4 videos -> sha == {ARM_F_SHA[:16]}... (arm F)")


if __name__ == "__main__":
    main()
