#!/usr/bin/env python3
"""Find where the gap-close gradient turns, and whether gap45 composes.

`gap45` (`GAP_CLOSE_UM` 5.0 -> 4.5) is the one legacy sweep candidate the
restricted paired test supports, in all four runs that measured it. Two
questions follow, and both are answerable on the held-out harness without a
submission slot:

1. **Where does the gradient turn?** Tightening 5.0 -> 4.5 helped. The density
   work established the shape of this kind of search: 6.5 -> 7.25 -> 8.0
   improved monotonically and then 9.0 flattened. Sample 4.75, 4.25, 4.0 and
   3.5 around the known-good point rather than guessing a direction.
2. **Does it compose?** `gap45` moves the gap stage; `dlow800` moves the
   density-adaptive relink gate and is independently supported (+0.00070, 5/2,
   CI excluding zero). Two supported changes in different stages *should*
   stack, but "should" is how the density combo was justified and it did not.
   Measure it.

`gap45_bonus125` is included as a deliberate negative control. `bonus125` tops
the aggregate table in every run (+0.00062 here) while going 7/12 on the
videos it moves - the exact signature that predicted `dmid700`'s leaderboard
loss. If the restricted test is doing its job it should refuse this arm even
though the aggregate will like it.

Every key used here is already in `PP_SWEEP_KEYS` and is read from module
globals at call time, so the sweep re-runs post-processing on cached graphs
per candidate. Detection, linking and the ILP run once.

This costs GPU time and no submission slot.
"""

from __future__ import annotations

import importlib.util
import json
import re
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
WORKSPACE = SCRIPTS.parent
SOURCE = Path(
    "/tmp/claude-0/-home-user-kaggle-competitions/"
    "079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad/audit946"
)
OUT_DIR = WORKSPACE / "notebooks" / "sep21-gap-gradient"
TITLE = "Biohub Sep21 Gap Gradient Held Out"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


density = _load("build_sep18_density_adaptive")
divrule = _load("build_sep18_validator_local_division")
kdtree = _load("build_sep15_relink_kdtree")
dval = _load("build_sep18_density_validation")

CONFIG = (
    '# Arm F on 24 held-out videos with the official division rule, so the gap\n'
    '# gradient is measured against the configuration we actually submit.\n'
    'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"'
                for k, v in density.ARMS["biohub-sep18-density-full"]["env"])
)

# Sampled around the supported point, not extrapolated past it.
ARMS = [
    # gap45 itself is NOT listed: it is already a legacy candidate in the
    # cell and re-adding it would put a duplicate key in the dict literal,
    # where the later one silently wins. It is measured either way.
    ("gap475", {"GAP_CLOSE_UM": 4.75}),
    ("gap425", {"GAP_CLOSE_UM": 4.25}),
    ("gap40", {"GAP_CLOSE_UM": 4.0}),
    ("gap35", {"GAP_CLOSE_UM": 3.5}),
    # Composition: gap stage + density relink gate, both independently
    # supported by the restricted paired test.
    ("gap45_dlow800", {"GAP_CLOSE_UM": 4.5, "DENSITY_LOW_TIGHT_UM": 8.0}),
    # Negative control: bonus125 tops the aggregate and is 7/12 on affected
    # videos. The restricted test should refuse this.
    ("gap45_bonus125", {"GAP_CLOSE_UM": 4.5, "MOTION_RELINK_LEARNED_BONUS": 1.25}),
]

CANDIDATES_NEW = '    "dcgap035": {"DEEPCENTER_GAP_THRESHOLD": 0.35},\n' + "\n".join(
    f'    "{name}": {json.dumps(cfg, sort_keys=True)},' for name, cfg in ARMS) + "\n}"


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    div_cell = [i for i, s in enumerate(before) if "def compute_division_confusion" in s][0]
    oc = before[div_cell]
    old_fn = oc[oc.find("def compute_division_confusion"):oc.find("def decompose_errors")]

    edits = {
        "config": (density.ANCHOR, CONFIG),
        "flags": (density.FLAG_ANCHOR, density.FLAG_NEW),
        "gate": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        "kdtree": (kdtree.OLD_LOOP, kdtree.NEW_LOOP),
        "division": (old_fn, divrule.NEW_FUNCTION),
        # The density keys are not sweepable in the base notebook; this
        # patch declares them. gap45_dlow800 needs DENSITY_LOW_TIGHT_UM.
        "sweepkeys": (dval.SWEEP_KEYS_ANCHOR, dval.SWEEP_KEYS_NEW),
        "candidates": (dval.CANDIDATES_ANCHOR, CANDIDATES_NEW),
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
    # 0 config, 2 constants, 5 pipeline, 8 division rule, 9 sweep keys,
    # 10 candidates.
    if changed != [0, 2, 5, 8, 9, 10]:
        raise RuntimeError(f"unexpected cells changed: {changed}")

    # Every key an arm overrides must be declared sweepable, or pp_apply raises
    # mid-run and the whole sweep is lost hours in.
    declared = set(re.findall(r'"([A-Z][A-Z0-9_]+)"', after[9]))
    used = {k for _, cfg in ARMS for k in cfg}
    if used - declared:
        raise RuntimeError(f"not sweepable: {sorted(used - declared)}")
    # The base value must differ from every arm, or an arm is a silent no-op.
    for name, cfg in ARMS:
        for key, value in cfg.items():
            if f'{key} = float(os.environ.get("BIOHUB_{key}", "{value}")' in after[2]:
                raise RuntimeError(f"{name}: {key}={value} is already the default")
    # A duplicate key in the candidate dict is silently overwritten, so
    # check our names against the ones already in the cell, not just
    # against each other.
    names = [n for n, _ in ARMS]
    if len(set(names)) != len(names):
        raise RuntimeError("duplicate arm name")
    existing = set(re.findall(r'^    "([\w()+]+)":', dval.CANDIDATES_ANCHOR, re.M))
    all_in_cell = re.findall(r'^    "([\w()+]+)":', after[10], re.M)
    if len(set(all_in_cell)) != len(all_in_cell):
        dupes = sorted({n for n in all_in_cell if all_in_cell.count(n) > 1})
        raise RuntimeError(f"duplicate candidate keys in the dict: {dupes}")
    if existing & set(names):
        raise RuntimeError(f"arm name collides with a legacy candidate: {sorted(existing & set(names))}")

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
    print(f"  {len(ARMS)} arms: " + ", ".join(n for n, _ in ARMS))
    print("  READ with paired_sweep_analysis.py against 'base', restricted to affected videos")


if __name__ == "__main__":
    main()
