#!/usr/bin/env python3
"""Parameterised production kernel: arm F + a chosen density arm + a gap value.

Generalises `build_sep21_gap45.py`, which hard-coded one configuration. The
production path is fixed - KD-tree relink, density-adaptive gate, wall-clock
deadline guard, validator off, ~10 min on the 4 public test videos - and two
knobs vary:

    PROD_DENSITY_ARM   a key of build_sep18_density_adaptive.ARMS
    PROD_GAP_CLOSE_UM  the gap-close base radius
    PROD_MOTION_BONUS  the learned motion-relink bonus
    PROD_TAG           short slug suffix, so each config gets its own kernel

Usage:

    PROD_TAG=gap45-dlow800 PROD_DENSITY_ARM=biohub-sep19-dlow800 \
        PROD_GAP_CLOSE_UM=4.5 python3 scripts/build_sep21_production.py

## Two lessons this builder encodes

**Declare a constant change everywhere the notebook pins it.** Cell 1 is a
configuration-drift guard listing the constants the pipeline may run with,
and `BIOHUB_GAP_CLOSE_UM` is on it. The first gap45 kernel changed only the
config cell and died three minutes into the Kaggle run. This builder edits
both and then reads the value back out of each to assert they agree, so the
failure happens locally in a second.

**Pair "did it change" with "did it take effect".** The guard being satisfied
does not mean the constant reached the gap stage. The check after the run is
that the output sha DIFFERS from the arm it derives from, with the gap-edge
counts moving in the expected direction - a byte-identical output means the
knob never landed.
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

TAG = os.environ.get("PROD_TAG", "gap45")
DENSITY_ARM = os.environ.get("PROD_DENSITY_ARM", "biohub-sep18-density-full")
GAP_CLOSE_UM = os.environ.get("PROD_GAP_CLOSE_UM", "4.5")
BASE_GAP_UM = "5.0"
MOTION_BONUS = os.environ.get("PROD_MOTION_BONUS", "1.0")
BASE_MOTION_BONUS = "1.0"
MIN_TRACK_LEN = os.environ.get("PROD_MIN_TRACK_LEN", "6")
BASE_MIN_TRACK_LEN = "6"

OUT_DIR = WORKSPACE / "notebooks" / f"sep21-prod-{TAG}"
TITLE = f"Biohub Sep21 Prod {TAG.replace('-', ' ').title()}"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

ARM_F_SHA = "fe6f0a6fe5c996b876cd40f85b9cef75421be5e959a5cd859c33fa339888a8d9"


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


kdtree = _load("build_sep15_relink_kdtree")
density = _load("build_sep18_density_adaptive")
guard = _load("build_sep19_deadline_guard")

if DENSITY_ARM not in density.ARMS:
    raise SystemExit(f"unknown density arm {DENSITY_ARM!r}; have {sorted(density.ARMS)}")

ARM_ENV = density.ARMS[DENSITY_ARM]["env"]
CONFIG_BLOCK = (
    f'# Production path: KD-tree relink, density arm {DENSITY_ARM}, deadline\n'
    f'# guard, validator off. GAP_CLOSE_UM {BASE_GAP_UM} -> {GAP_CLOSE_UM}.\n'
    '# Every knob here was carried by a candidate the restricted paired test\n'
    '# supports on the 24 held-out videos - not by the aggregate sweep table,\n'
    '# which over-credits changes that move only a few samples.\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
    'os.environ["BIOHUB_MOTION_RELINK_TIGHT_UM"] = "5.5"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"' for k, v in ARM_ENV)
)

GAP_ANCHOR = f'os.environ["BIOHUB_GAP_CLOSE_UM"] = "{BASE_GAP_UM}"'
GAP_NEW = f'os.environ["BIOHUB_GAP_CLOSE_UM"] = "{GAP_CLOSE_UM}"'
GUARD_EXPECT_ANCHOR = f'    "BIOHUB_GAP_CLOSE_UM": {BASE_GAP_UM},'
GUARD_EXPECT_NEW = f'    "BIOHUB_GAP_CLOSE_UM": {GAP_CLOSE_UM},'

# Note the single quotes: this is how the source cell writes it. The drift
# guard does NOT pin this key, so unlike GAP_CLOSE_UM there is no second
# place to update - which is exactly why the builder checks rather than
# assuming the same shape for every constant.
BONUS_ANCHOR = f'os.environ["BIOHUB_MOTION_RELINK_LEARNED_BONUS"] = {BASE_MOTION_BONUS!r}'
BONUS_NEW = f'os.environ["BIOHUB_MOTION_RELINK_LEARNED_BONUS"] = {MOTION_BONUS!r}'

# The drift guard DOES pin this one (as a float), so both places need it.
MTL_ANCHOR = f'os.environ["BIOHUB_OUTPUT_MIN_TRACK_LEN"] = "{BASE_MIN_TRACK_LEN}"'
MTL_NEW = f'os.environ["BIOHUB_OUTPUT_MIN_TRACK_LEN"] = "{MIN_TRACK_LEN}"'
MTL_GUARD_ANCHOR = f'    "BIOHUB_OUTPUT_MIN_TRACK_LEN": {float(BASE_MIN_TRACK_LEN)},'
MTL_GUARD_NEW = f'    "BIOHUB_OUTPUT_MIN_TRACK_LEN": {float(MIN_TRACK_LEN)},'


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    for name in ("OUTPUT_MOTION_RELINK", "OUTPUT_GAP_CLOSE", "OUTPUT_GAP2_RECOVERY"):
        if f"{name} = " not in before[2]:
            raise RuntimeError(f"{name} is not a module-level constant")
    if 'GAP_CLOSE_UM = float(os.environ.get("BIOHUB_GAP_CLOSE_UM"' not in before[2]:
        raise RuntimeError("GAP_CLOSE_UM is not read from BIOHUB_GAP_CLOSE_UM")

    pipeline = before[5]
    at = pipeline.find(guard.HOOK_ANCHOR)
    marker_at = pipeline.find(guard.HOOK_MARKER, at) if at >= 0 else -1
    if at < 0 or marker_at < 0:
        raise RuntimeError("could not locate the filter_output_graph stats hook")
    hook_target = pipeline[marker_at:marker_at + len(guard.HOOK_MARKER)]

    edits = {
        "config": (density.ANCHOR, CONFIG_BLOCK),
        "flags": (density.FLAG_ANCHOR, density.FLAG_NEW),
        "guard": (guard.GUARD_ANCHOR, guard.GUARD_NEW),
        "gate": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        "kdtree": (kdtree.OLD_LOOP, kdtree.NEW_LOOP),
        "hook": (hook_target, guard.DEGRADE_CHECK + hook_target + guard.STATS_EXTRA),
    }
    gap_changes = GAP_CLOSE_UM != BASE_GAP_UM
    if gap_changes:
        edits["gap"] = (GAP_ANCHOR, GAP_NEW)
        edits["guard_expect"] = (GUARD_EXPECT_ANCHOR, GUARD_EXPECT_NEW)
    bonus_changes = MOTION_BONUS != BASE_MOTION_BONUS
    if bonus_changes:
        if BONUS_ANCHOR not in before[0]:
            raise RuntimeError(f"motion-bonus anchor not found: {BONUS_ANCHOR}")
        if '"BIOHUB_MOTION_RELINK_LEARNED_BONUS"' in before[1]:
            raise RuntimeError("the drift guard pins the motion bonus too; update it as well")
        edits["bonus"] = (BONUS_ANCHOR, BONUS_NEW)
    mtl_changes = MIN_TRACK_LEN != BASE_MIN_TRACK_LEN
    if mtl_changes:
        if MTL_ANCHOR not in before[0]:
            raise RuntimeError(f"min-track-len anchor not found: {MTL_ANCHOR}")
        if MTL_GUARD_ANCHOR not in before[1]:
            raise RuntimeError(f"drift guard pin not found: {MTL_GUARD_ANCHOR}")
        edits["mtl"] = (MTL_ANCHOR, MTL_NEW)
        edits["mtl_guard"] = (MTL_GUARD_ANCHOR, MTL_GUARD_NEW)

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
    want = [0, 1, 2, 5] if (gap_changes or mtl_changes) else [0, 2, 5]
    if changed != want:
        raise RuntimeError(f"unexpected cells changed: {changed}, wanted {want}")
    if "_deadline_degrade()" not in after[5]:
        raise RuntimeError("the guard is declared but never called")
    if "query_ball_point" not in after[5] or density.PASS_ANCHOR in after[5]:
        raise RuntimeError("KD-tree or density patch inert")
    if after[0].count('os.environ["BIOHUB_GAP_CLOSE_UM"]') != 1:
        raise RuntimeError("GAP_CLOSE_UM set more than once; the later value would win")

    # The config cell and the drift guard must agree, or the kernel dies three
    # minutes in. Read both back rather than trusting that both edits landed.
    set_to = re.search(r'os\.environ\["BIOHUB_GAP_CLOSE_UM"\] = "([\d.]+)"', after[0])
    expects = re.search(r'"BIOHUB_GAP_CLOSE_UM": ([\d.]+),', after[1])
    if not set_to or not expects:
        raise RuntimeError("could not read GAP_CLOSE_UM back from the config cell or the guard")
    if not (float(set_to.group(1)) == float(expects.group(1)) == float(GAP_CLOSE_UM)):
        raise RuntimeError(
            f"config sets {set_to.group(1)}, drift guard expects {expects.group(1)}, "
            f"intended {GAP_CLOSE_UM}")

    if bonus_changes:
        got = re.search(r'os\.environ\["BIOHUB_MOTION_RELINK_LEARNED_BONUS"\] = .([\d.]+).', after[0])
        if not got or float(got.group(1)) != float(MOTION_BONUS):
            raise RuntimeError(f"motion bonus did not land: {got.group(1) if got else None}")

    if mtl_changes:
        g0 = re.search(r'os\.environ\["BIOHUB_OUTPUT_MIN_TRACK_LEN"\] = "([\d.]+)"', after[0])
        g1 = re.search(r'"BIOHUB_OUTPUT_MIN_TRACK_LEN": ([\d.]+),', after[1])
        if not g0 or not g1 or float(g0.group(1)) != float(g1.group(1)) != float(MIN_TRACK_LEN):
            raise RuntimeError("min track len disagrees between config and drift guard")

    # Every density constant the arm names must actually appear in the cell.
    for key, value in ARM_ENV:
        if f'os.environ["{key}"] = "{value}"' not in after[0]:
            raise RuntimeError(f"{key}={value} from {DENSITY_ARM} did not land")

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
    print(f"  kernel      dalloliogm/{SLUG}")
    print(f"  density arm {DENSITY_ARM}")
    print(f"  gap close   {GAP_CLOSE_UM} (base {BASE_GAP_UM})")
    print(f"  relink bonus {MOTION_BONUS} (base {BASE_MOTION_BONUS})")
    print(f"  min track len {MIN_TRACK_LEN} (base {BASE_MIN_TRACK_LEN})")
    print(f"  PASS: sha must DIFFER from arm F {ARM_F_SHA[:16]}...")


if __name__ == "__main__":
    main()
