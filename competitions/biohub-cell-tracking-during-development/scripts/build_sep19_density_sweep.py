#!/usr/bin/env python3
"""Find our own density constants, and repair the evidence base behind them.

## What went wrong with the 2026-09-18 conclusion

Arm E (low bucket only) was called validated on a paired bootstrap over 24
held-out videos: +0.00167 adjusted edge Jaccard, CI [+0.00032, +0.00354]
excluding zero. It then scored **0.944** publicly against a 0.946 baseline.

The per-video breakdown explains the overconfidence. Only **9 of the 24**
videos are affected by the low bucket at all - every one of them low-density
(46.9-99.8 cells per frame); the other 15 are exact ties. A bootstrap over all
24 stems is therefore diluted by 15 structural zeros, which tightens the
interval without adding information. The honest evidence base is 9 videos,
7 better and 2 worse, and the public board adds a single low-density video
(63.0 cells/frame) that got worse. Ten samples, 7-3.

Meanwhile arm F (the full three-bucket table) agrees across both instruments:
+0.00213 held out, 0.947 public against 0.946. The 2026-09-18 instruction to
"carry densitylow, not densityfull" was backwards and is superseded here.

## What this sweep does

The constants in use are inherited from a public notebook that fitted three
parameter-sets against four movies. Rather than keep arguing about them, this
sweeps them on held-out data, with every candidate scored on identical stems
under the official division rule:

* **low bucket** 6.5 / 7.25 / 8.0, holding middle and high at arm F's values -
  the low bucket is the disputed one, so it gets the finest grid.
* **middle bucket** 6.0 / 6.5 / 7.0 - arm F's 6.5 beat arm E's 5.5 publicly by
  0.003, which contradicts our own global sweep preferring 5.5. Worth resolving
  on held-out data rather than on two leaderboard points.
* **relaxed gate** - arm F changes middle relaxed 10.0 -> 9.0 at the same time
  as tight 5.5 -> 6.5. `dfull_relax10` isolates the tight change so the two are
  not confounded.

## How the results must be read

Report per-bucket, restricted to the videos each bucket actually touches.
Aggregate deltas over all 24 stems understate variance for a change that only
moves a subset, which is the error this sweep exists to correct. The companion
analysis script enforces that.

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
OUT_DIR = WORKSPACE / "notebooks" / "sep19-density-sweep"
TITLE = "Biohub Sep19 Density Constant Sweep Held Out"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


density = _load("build_sep18_density_adaptive")
divrule = _load("build_sep18_validator_local_division")
dval = _load("build_sep18_density_validation")
kdtree = _load("build_sep15_relink_kdtree")


def _cfg(low_t, low_r, mid_t, mid_r, high_t=5.5, high_r=10.0):
    return (f'{{"DENSITY_ADAPTIVE_RELINK": True, '
            f'"DENSITY_LOW_TIGHT_UM": {low_t}, "DENSITY_LOW_RELAXED_UM": {low_r}, '
            f'"DENSITY_MIDDLE_TIGHT_UM": {mid_t}, "DENSITY_MIDDLE_RELAXED_UM": {mid_r}, '
            f'"DENSITY_HIGH_TIGHT_UM": {high_t}, "DENSITY_HIGH_RELAXED_UM": {high_r}}}')


CANDIDATES_NEW = '    "dcgap035": {"DEEPCENTER_GAP_THRESHOLD": 0.35},\n' + "\n".join(
    f'    "{name}": {cfg},' for name, cfg in [
        # arm E and arm F as submitted, so this run re-derives both in place
        ("densitylow", _cfg(7.25, 11.0, 5.5, 10.0)),
        ("densityfull", _cfg(7.25, 11.0, 6.5, 9.0)),
        # low bucket grid, middle/high held at arm F
        ("dlow650", _cfg(6.5, 11.0, 6.5, 9.0)),
        ("dlow800", _cfg(8.0, 11.0, 6.5, 9.0)),
        # middle bucket grid, low/high held at arm F
        ("dmid600", _cfg(7.25, 11.0, 6.0, 9.0)),
        ("dmid700", _cfg(7.25, 11.0, 7.0, 9.0)),
        # isolates arm F's tight change from its simultaneous relaxed change
        ("dfull_relax10", _cfg(7.25, 11.0, 6.5, 10.0)),
        # does the high bucket want to move at all?
        ("dhigh600", _cfg(7.25, 11.0, 6.5, 9.0, 6.0, 10.0)),
    ]) + "\n}"


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    div_cell = [i for i, s in enumerate(before) if "def compute_division_confusion" in s][0]
    oc = before[div_cell]
    old_division_fn = oc[oc.find("def compute_division_confusion"):oc.find("def decompose_errors")]
    if "weakly_connected_components" not in old_division_fn:
        raise RuntimeError("division function is not the loose implementation")

    edits = {
        "config": (density.ANCHOR, 'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"'),
        "flags": (density.FLAG_ANCHOR, density.FLAG_NEW),
        "gate": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        # KD-tree too: the sweep re-runs post-processing per candidate, and the
        # density gate reintroduces the quadratic cost without it.
        "kdtree": (kdtree.OLD_LOOP, kdtree.NEW_LOOP),
        "division": (old_division_fn, divrule.NEW_FUNCTION),
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
    if changed != [0, 2, 5, 8, 9, 10]:
        raise RuntimeError(f"unexpected cells changed: {changed}")
    if density.PASS_ANCHOR in after[5]:
        raise RuntimeError("density gate inert")
    if "query_ball_point" not in after[5]:
        raise RuntimeError("KD-tree patch missing")
    declared = set(re.findall(r'"(DENSITY_[A-Z_]+)"', after[9]))
    used = set(re.findall(r'"(DENSITY_[A-Z_]+)":', after[10]))
    if used - declared:
        raise RuntimeError(f"non-sweepable keys used: {sorted(used - declared)}")
    for key in sorted(declared):
        if f"{key} = " not in after[2]:
            raise RuntimeError(f"{key} not defined in constants cell")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"{SLUG}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")
    metadata = json.loads((SOURCE / "kernel-metadata.json").read_text())
    metadata.update({"id": f"dalloliogm/{SLUG}", "title": TITLE,
                     "code_file": out.name, "is_private": True})
    for key in ("id_no", "docker_image"):
        metadata.pop(key, None)
    (OUT_DIR / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")

    n = len(re.findall(r'^\s{4}"[\w()+]+": \{', after[10], re.M))
    print(f"wrote {out.relative_to(WORKSPACE)}")
    print(f"  {n} sweep candidates, KD-tree active, official division rule")
    print("  READ per-bucket, restricted to the videos each bucket touches")


if __name__ == "__main__":
    main()
