#!/usr/bin/env python3
"""Arm F + GAP_CLOSE_UM 5.0 -> 4.5, the one legacy candidate the restricted
paired test supports.

## Why this, and why it went unnoticed for so long

`gap45` has sat in the post-process sweep's candidate list since the beginning.
It never topped the aggregate table - `bonus125` always did - so the
auto-selector never picked it and I never looked at it. When the restricted
paired test was built on 2026-09-19 it was applied to the density arms and
never retro-applied to the seven baseline candidates that had been in every
sweep all along. Reading them back today, `gap45` is supported in every run
where it was measured:

    run                     weighted   n_aff   W/L    95% CI                verdict
    sep19 density sweep     +0.00020     16   16/0   [+0.00003, +0.00089]  SUPPORTED
    densval                 +0.00020     16   16/0   [+0.00003, +0.00089]  SUPPORTED
    autopsy2 / trace        +0.00014     17   15/2   [+0.00003, +0.00058]  SUPPORTED
    sep21 targeted steal    +0.00014     17   15/2   [+0.00003, +0.00058]  SUPPORTED

Four independent kernel runs, 16-17 affected videos each, the confidence
interval excluding zero every time. By contrast `bonus125`, which tops the
aggregate at +0.00062, is 7/12 on the videos it moves - the same pattern that
predicted `dmid700`'s leaderboard loss.

## Honest size

+0.00014 weighted is well below the public leaderboard's 0.001 quantisation, so
the public score will almost certainly still read 0.947. The gain is for the
private rerun, which is what actually ranks. This is banked evidence, not a
visible jump, and it should not be reported as one.

## What this kernel is

The production path, identical to the submitted SEP20-1 kernel - KD-tree relink,
density-adaptive gate (arm F), wall-clock deadline guard - with one constant
changed. The validator is off, so this runs on the 4 public test videos in ~25
min rather than re-deriving held-out evidence we already have four times over.

## Expected difference from arm F

`GAP_CLOSE_UM` is the base radius for two-frame gap closure, which
`GAP_DENSITY_ADAPTIVE` then scales per video. Tightening it admits fewer
synthetic bridges, so the output should carry **fewer** gap-closed edges than
arm F's sha fe6f0a6f. A byte-identical output would mean the constant is not
reaching the gap stage and the build is wrong - that is the check.
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
OUT_DIR = WORKSPACE / "notebooks" / "sep21-gap45"
TITLE = "Biohub Sep21 Gap45 Density Full"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

ARM_F_SHA = "fe6f0a6fe5c996b876cd40f85b9cef75421be5e959a5cd859c33fa339888a8d9"
GAP_CLOSE_UM = "4.5"


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


kdtree = _load("build_sep15_relink_kdtree")
density = _load("build_sep18_density_adaptive")
guard = _load("build_sep19_deadline_guard")

ARM_ENV = density.ARMS["biohub-sep18-density-full"]["env"]
CONFIG_BLOCK = (
    '# Arm F production path (KD-tree relink, density-adaptive gate, deadline\n'
    '# guard) with GAP_CLOSE_UM tightened 5.0 -> 4.5. That is the only legacy\n'
    '# sweep candidate the restricted paired test supports, and it is supported\n'
    '# in all four runs that measured it (16/0, 16/0, 15/2, 15/2 on 16-17\n'
    '# affected videos, CI excluding zero each time). The effect is below the\n'
    '# public leaderboard quantisation; it is banked for the private rerun.\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
    'os.environ["BIOHUB_MOTION_RELINK_TIGHT_UM"] = "5.5"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"' for k, v in ARM_ENV)
)

# Cell 0 already sets this key. Append a second assignment and the later one
# silently wins - correct by accident, and unreadable. Replace it in place so
# the cell states one value for one constant.
GAP_ANCHOR = 'os.environ["BIOHUB_GAP_CLOSE_UM"] = "5.0"'
GAP_NEW = f'os.environ["BIOHUB_GAP_CLOSE_UM"] = "{GAP_CLOSE_UM}"'

# Cell 1 is a configuration-drift guard that pins the constants this pipeline
# is allowed to run with, and it lists this one. Changing the config without
# it raises at import - which is the guard working, not a bug in it. The
# intended change has to be declared in both places.
GUARD_EXPECT_ANCHOR = '    "BIOHUB_GAP_CLOSE_UM": 5.0,'
GUARD_EXPECT_NEW = f'    "BIOHUB_GAP_CLOSE_UM": {GAP_CLOSE_UM},'


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    for name in ("OUTPUT_MOTION_RELINK", "OUTPUT_GAP_CLOSE", "OUTPUT_GAP2_RECOVERY"):
        if f"{name} = " not in before[2]:
            raise RuntimeError(f"{name} is not a module-level constant")
    # The knob must actually be read from the environment, or the config block
    # sets a variable nothing consumes.
    if 'GAP_CLOSE_UM = float(os.environ.get("BIOHUB_GAP_CLOSE_UM"' not in before[2]:
        raise RuntimeError("GAP_CLOSE_UM is not read from BIOHUB_GAP_CLOSE_UM")

    pipeline = before[5]
    at = pipeline.find(guard.HOOK_ANCHOR)
    if at < 0:
        raise RuntimeError("filter_output_graph not found")
    marker_at = pipeline.find(guard.HOOK_MARKER, at)
    if marker_at < 0:
        raise RuntimeError("could not find the stats dict opening")
    hook_target = pipeline[marker_at:marker_at + len(guard.HOOK_MARKER)]

    edits = {
        "config": (density.ANCHOR, CONFIG_BLOCK),
        "flags": (density.FLAG_ANCHOR, density.FLAG_NEW),
        "guard": (guard.GUARD_ANCHOR, guard.GUARD_NEW),
        "gate": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        "kdtree": (kdtree.OLD_LOOP, kdtree.NEW_LOOP),
        "hook": (hook_target, guard.DEGRADE_CHECK + hook_target + guard.STATS_EXTRA),
        "gap": (GAP_ANCHOR, GAP_NEW),
        "guard_expect": (GUARD_EXPECT_ANCHOR, GUARD_EXPECT_NEW),
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
    if changed != [0, 1, 2, 5]:
        raise RuntimeError(f"unexpected cells changed: {changed}")

    # The config cell and the drift guard must state the same value, or the
    # kernel dies three minutes in. Read both back out of the built notebook
    # rather than trusting that both edits landed.
    set_to = re.search(r'os\.environ\["BIOHUB_GAP_CLOSE_UM"\] = "([\d.]+)"', after[0])
    expects = re.search(r'"BIOHUB_GAP_CLOSE_UM": ([\d.]+),', after[1])
    if not set_to or not expects:
        raise RuntimeError("could not read GAP_CLOSE_UM back from the config cell or the guard")
    if float(set_to.group(1)) != float(expects.group(1)) != float(GAP_CLOSE_UM):
        raise RuntimeError(
            f"config sets {set_to.group(1)} but the drift guard expects "
            f"{expects.group(1)} (intended {GAP_CLOSE_UM})")
    if "_deadline_degrade()" not in after[5]:
        raise RuntimeError("the guard is declared but never called")
    if "query_ball_point" not in after[5] or density.PASS_ANCHOR in after[5]:
        raise RuntimeError("KD-tree or density patch inert")
    if after[0].count('os.environ["BIOHUB_GAP_CLOSE_UM"]') != 1:
        raise RuntimeError("GAP_CLOSE_UM set more than once; the later value would win")
    if GAP_NEW not in after[0] or GAP_ANCHOR in after[0]:
        raise RuntimeError("the gap override did not take")
    # Exactly one constant may differ from the submitted arm F production
    # kernel (SEP20-1). Compare against that kernel's config cell, not the
    # unpatched source - the arm F block is common to both.
    arm_f_cell = before[0].replace(density.ANCHOR, guard.CONFIG_BLOCK, 1)
    arm_f_cell = arm_f_cell.replace(GAP_ANCHOR, GAP_ANCHOR, 1)
    only_here = [l for l in after[0].splitlines() if l not in arm_f_cell.splitlines()
                 and l.startswith("os.environ[")]
    only_there = [l for l in arm_f_cell.splitlines() if l not in after[0].splitlines()
                  and l.startswith("os.environ[")]
    if only_here != [GAP_NEW] or only_there != [GAP_ANCHOR]:
        raise RuntimeError(
            f"expected only the gap override to differ from arm F; "
            f"added={only_here} removed={only_there}")

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
    print(f"  GAP_CLOSE_UM = {GAP_CLOSE_UM} (arm F baseline 5.0)")
    print(f"  validator off; ~25 min on the 4 public test videos")
    print(f"  PASS: sha must DIFFER from arm F {ARM_F_SHA[:16]}... with fewer gap edges")
    print(f"        (identical output would mean the constant never reached the gap stage)")


if __name__ == "__main__":
    main()
