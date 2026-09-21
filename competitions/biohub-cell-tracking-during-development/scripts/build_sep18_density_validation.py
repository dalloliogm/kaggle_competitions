#!/usr/bin/env python3
"""Score the density-adaptive relink arms on 24 held-out videos.

## Why this and not a submission

Arm E (low-density bucket only) changes 45 rows out of 241,400, all inside the
smallest test video - about 5% of nodes, and inside the ~6.5% of public weight
the two dominant movies do not hold. Its leaderboard score would read 0.946
within noise whether the change helps or hurts, so the public board cannot
measure it.

The asymmetry runs the other way for the private set: low-density samples may
be a far larger share of the ~199 hidden films than of the four public ones. So
the instrument has to be the held-out validator, which spans several density
regimes - and as of 2026-09-18 it scores divisions under the official
post-patch rule rather than the loose component rule, so its numbers are
trustworthy for the first time.

## Design

`pp_apply` overrides module globals for any key listed in `PP_SWEEP_KEYS`, and
the sweep re-runs post-processing per candidate on cached prediction graphs -
detection, linking and the ILP are not repeated. `motion_relink_edges` is part
of post-processing, so the density gate is sweepable. Adding the density
constants to `PP_SWEEP_KEYS` therefore scores density-on against density-off on
**identical stems, in one run, under one metric**, which a second separate run
could not do.

Candidates added:

- `densitylow` - arm E. Low bucket 7.25/11.0; middle and high pinned to
  5.5/10.0 so the only difference from `tight55` is the low-density bucket.
  The comparison to read is `densitylow` vs `tight55`, not vs `base`.
- `densityfull` - arm F, the public notebook's three-bucket table. It is
  already submitted, so this also cross-checks whether the local validator and
  the leaderboard agree about it - worth knowing independently of the result.

## What each outcome means

- `densitylow` > `tight55`: widening the gate where cells are sparse is a real
  effect, invisible publicly but worth carrying into the private run.
- `densitylow` ~= `tight55`: the low-density regime is already handled; drop it.
- `densitylow` < `tight55`: our single global 5.5 is right even where cells are
  sparse, and the public notebook's low bucket is fitted to its one small movie.

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
OUT_DIR = WORKSPACE / "notebooks" / "sep18-density-validation"
TITLE = "Biohub Sep18 Density Adaptive Held Out Validation"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# Reuse the exact patch text from the builders that produced the submitted
# arms, so the validated code and the submitted code cannot drift apart.
density = _load("build_sep18_density_adaptive")
divrule = _load("build_sep18_validator_local_division")

SWEEP_KEYS_ANCHOR = '    "GAP_CLOSE_REUSE_UM", "OUTPUT_EDGE_MAX_UM",\n]'
SWEEP_KEYS_NEW = (
    '    "GAP_CLOSE_REUSE_UM", "OUTPUT_EDGE_MAX_UM",\n'
    '    # Density-adaptive relink gate. motion_relink_edges runs inside\n'
    '    # post-processing, which the sweep re-runs per candidate on cached\n'
    '    # graphs, so these are legitimately sweepable.\n'
    '    "DENSITY_ADAPTIVE_RELINK",\n'
    '    "DENSITY_LOW_TIGHT_UM", "DENSITY_LOW_RELAXED_UM",\n'
    '    "DENSITY_MIDDLE_TIGHT_UM", "DENSITY_MIDDLE_RELAXED_UM",\n'
    '    "DENSITY_HIGH_TIGHT_UM", "DENSITY_HIGH_RELAXED_UM",\n'
    ']'
)

CANDIDATES_ANCHOR = '    "dcgap035": {"DEEPCENTER_GAP_THRESHOLD": 0.35},\n}'
CANDIDATES_NEW = '''    "dcgap035": {"DEEPCENTER_GAP_THRESHOLD": 0.35},
    # Arm E: only the low-density bucket widens. Middle and high are pinned to
    # the same 5.5/10.0 the tight55 candidate uses, so densitylow vs tight55
    # isolates the low-density change and nothing else.
    "densitylow": {
        "DENSITY_ADAPTIVE_RELINK": True,
        "DENSITY_LOW_TIGHT_UM": 7.25, "DENSITY_LOW_RELAXED_UM": 11.0,
        "DENSITY_MIDDLE_TIGHT_UM": 5.5, "DENSITY_MIDDLE_RELAXED_UM": 10.0,
        "DENSITY_HIGH_TIGHT_UM": 5.5, "DENSITY_HIGH_RELAXED_UM": 10.0,
    },
    # Arm F: the public notebook's full three-bucket table, already submitted.
    # Scoring it here cross-checks the validator against the leaderboard.
    "densityfull": {
        "DENSITY_ADAPTIVE_RELINK": True,
        "DENSITY_LOW_TIGHT_UM": 7.25, "DENSITY_LOW_RELAXED_UM": 11.0,
        "DENSITY_MIDDLE_TIGHT_UM": 6.5, "DENSITY_MIDDLE_RELAXED_UM": 9.0,
        "DENSITY_HIGH_TIGHT_UM": 5.5, "DENSITY_HIGH_RELAXED_UM": 10.0,
    },
}'''


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    div_cell = [i for i, s in enumerate(before) if "def compute_division_confusion" in s][0]
    old_cell = before[div_cell]
    a = old_cell.find("def compute_division_confusion")
    b = old_cell.find("def decompose_errors")
    old_division_fn = old_cell[a:b]
    if "weakly_connected_components" not in old_division_fn:
        raise RuntimeError("division function is not the loose implementation")

    edits = {
        # 24 held-out videos, validator ON (no pinning - the sweep is the point).
        "config": (density.ANCHOR, 'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"'),
        "flags": (density.FLAG_ANCHOR, density.FLAG_NEW),
        "relink": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        "division": (old_division_fn, divrule.NEW_FUNCTION),
        "sweepkeys": (SWEEP_KEYS_ANCHOR, SWEEP_KEYS_NEW),
        "candidates": (CANDIDATES_ANCHOR, CANDIDATES_NEW),
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
    changed = [i for i, (x, y) in enumerate(zip(before, after)) if x != y]
    if changed != [0, 2, 5, 8, 9, 10]:
        raise RuntimeError(f"unexpected cells changed: {changed}")

    # The density gate must actually reach the assignment loop.
    if density.PASS_ANCHOR in after[5]:
        raise RuntimeError("the pass loop still reads the global gate")
    # Every key the new candidates set must be declared sweepable, or pp_apply
    # raises KeyError mid-run after an hour of prediction.
    declared = set(re.findall(r'"(DENSITY_[A-Z_]+)"', after[9]))
    used = set(re.findall(r'"(DENSITY_[A-Z_]+)":', after[10]))
    missing = used - declared
    if missing:
        raise RuntimeError(f"candidates set non-sweepable keys: {sorted(missing)}")
    # pp_apply casts with type(PP_BASE_CONFIG[key]), so each key must exist as a
    # module global before the sweep cell builds PP_BASE_CONFIG.
    for key in sorted(declared):
        if f"{key} = " not in after[2]:
            raise RuntimeError(f"{key} is not defined in the constants cell")

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
    print(f"  sweepable density keys: {len(declared)}")
    print("  candidates added: densitylow (arm E), densityfull (arm F)")
    print("  division scoring: official post-patch local rule")
    print("  READ: densitylow vs tight55 - NOT densitylow vs base")


if __name__ == "__main__":
    main()
