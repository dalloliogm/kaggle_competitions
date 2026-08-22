#!/usr/bin/env python3
"""Separate the DeepCenter CHECKPOINT from the safe-division GATE.

The 08-22 scan found `yunusgmsoy/lb-0-920-biohub-cell-tracking-v17` (claimed LB
0.920) loading DeepCenter from `best.pt` - "best.pt is epoch 2, not
checkpoint_last.pt's epoch 500" - with the safe-division veto ON, on telemetry
showing safe-div accepting 81-100% of its own candidates.

We have NEVER loaded `best.pt`. Every DeepCenter run in this workspace pointed
at `checkpoint_last.pt`. That matters because of Exp158:

    Exp158   checkpoint_last.pt (epoch 500) + SAFE_DIV_VETO=1  ->  0.905
             filed as "the veto rejected all candidate divisions"

A center prior loaded from the wrong checkpoint vetoing everything is exactly
that symptom, so Exp158 may have measured a bad checkpoint rather than a bad
gate. The two have never been separated. These two runs separate them:

    exp220   best.pt (epoch 2) + SAFE_DIV_VETO=1   the claimed 0.920 pairing
    exp221   best.pt (epoch 2) + SAFE_DIV_VETO=0   isolates the checkpoint

With Exp158 already on the board that is three cells of the 2x2, which is enough
to attribute its loss to one factor or the other:

    | veto \\ checkpoint | last.pt (epoch 500) | best.pt (epoch 2) |
    | ON                 | Exp158  0.905       | exp220            |
    | OFF                | (= exp183 lineage)  | exp221            |

Both fork exp183 (public LB 0.915), whose DeepCenter block is fully OFF
(`CHECKPOINT=''`), so turning it on is a single coherent config change. Verified
that the inherited strategy guard freezes no DeepCenter key, so neither run
needs the guard repointed.

Numbering: exp203/exp204/exp209 are all in concurrent use by other sessions, so
these deliberately start well above the current maximum (exp212).
"""

from __future__ import annotations

import json
from pathlib import Path

NOTEBOOKS = Path(__file__).resolve().parent.parent / "notebooks"
BASE = NOTEBOOKS / "biohub-exp183-public-ranker-fork.ipynb"
BASE_METADATA = NOTEBOOKS / "biohub-exp183-public-ranker-fork.kernel-metadata.json"
CONFIG_CELL = 4

DEEPCENTER_DATASET = "pilkwang/biohub-deepcenter-unet3d-center-prior-v1"
BEST_PT = (
    "/kaggle/input/biohub-deepcenter-unet3d-center-prior-v1"
    "/weights/full_frame_center/best.pt"
)

# (env key, value exp183 currently sets, value we want). Every one of these is
# unguarded, checked against the strategy guard's key list before writing.
COMMON_DEEPCENTER = (
    ("BIOHUB_USE_DEEPCENTER_VETO", "'0'", '"1"'),
    ("BIOHUB_REQUIRE_DEEPCENTER_VETO", "'0'", '"1"'),
    ("BIOHUB_DEEPCENTER_EXPECTED_EPOCH", "'0'", '"2"'),
    ("BIOHUB_DEEPCENTER_CHECKPOINT", "''", f'"{BEST_PT}"'),
    ("BIOHUB_DEEPCENTER_GAP_VETO", "'0'", '"1"'),
    ("BIOHUB_DEEPCENTER_GAP_THRESHOLD", '"0.20"', '"0.25"'),
    ("BIOHUB_DEEPCENTER_GAP_CONFIRM_MIN_SPAN_UM", '"8.0"', '"8.5"'),
)


def cell_source(nb: dict, index: int) -> str:
    return "".join(nb["cells"][index]["source"])


def set_cell_source(nb: dict, index: int, text: str) -> None:
    nb["cells"][index]["source"] = text.splitlines(keepends=True)


def assert_unguarded(nb: dict, keys: list[str]) -> None:
    """Fail loudly if any key we touch is frozen by the inherited guard."""
    for cell in nb["cells"]:
        source = "".join(cell["source"])
        if "_expected_numeric" not in source:
            continue
        clashes = [key for key in keys if f'"{key}"' in source]
        if clashes:
            raise RuntimeError(f"strategy guard freezes {clashes}; repoint it first")
        return
    raise RuntimeError("strategy guard cell not found - base changed?")


def set_env(config: str, key: str, value: str) -> str:
    """Rewrite one os.environ assignment, whatever quoting the base used."""
    matches = [
        line for line in config.splitlines()
        if line.startswith(f'os.environ["{key}"]')
    ]
    if len(matches) != 1:
        raise RuntimeError(f"{key}: expected one assignment, found {len(matches)}")
    return config.replace(matches[0], f'os.environ["{key}"] = {value}', 1)


def build(slug: str, title: str, preset: str, axis: str,
          safe_div_veto: str, heading: str, body: str) -> None:
    nb = json.loads(BASE.read_text())
    keys = [key for key, _, _ in COMMON_DEEPCENTER] + ["BIOHUB_DEEPCENTER_SAFE_DIV_VETO"]
    assert_unguarded(nb, keys)

    config = cell_source(nb, CONFIG_CELL)
    for key, _old, new in COMMON_DEEPCENTER:
        config = set_env(config, key, new)
    config = set_env(config, "BIOHUB_DEEPCENTER_SAFE_DIV_VETO", safe_div_veto)

    for name, value in (("BIOHUB_PRESET", preset), ("BIOHUB_SCORE_AXIS", axis)):
        line = [l for l in config.splitlines() if l.startswith(name)]
        if len(line) != 1:
            raise RuntimeError(f"expected one {name} line")
        config = config.replace(line[0], f"{name} = {value!r}", 1)
    set_cell_source(nb, CONFIG_CELL, config)
    set_cell_source(nb, 1, heading + "\n\n" + body + "\n")

    out = NOTEBOOKS / f"{slug}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")

    metadata = json.loads(BASE_METADATA.read_text())
    metadata["id"] = f"dalloliogm/{slug}"
    metadata["title"] = title
    metadata["code_file"] = out.name
    if DEEPCENTER_DATASET not in metadata["dataset_sources"]:
        metadata["dataset_sources"].append(DEEPCENTER_DATASET)
    (NOTEBOOKS / f"{slug}.kernel-metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n"
    )
    print(f"wrote {out.name}")


SHARED = (
    "Forked from Exp183 (the public stack forked verbatim, public LB `0.915`), "
    "whose DeepCenter block is fully off. The 08-22 scan found the claimed "
    "`0.920` notebook loading DeepCenter from **`best.pt`** - *\"best.pt is "
    "epoch 2, not checkpoint_last.pt's epoch 500\"* - where every DeepCenter run "
    "in this workspace has used `checkpoint_last.pt`.\n\n"
    "Exp158 turned the safe-division veto on against the epoch-500 checkpoint, "
    "scored `0.905`, and was filed as *the veto rejected all candidate "
    "divisions*. A center prior loaded from the wrong checkpoint vetoing "
    "everything is exactly that symptom, so the checkpoint and the gate have "
    "never been separated."
)


def main() -> None:
    build(
        slug="biohub-exp220-deepcenter-best-safediv-veto",
        title="Biohub Exp220 Deepcenter Best Safediv Veto",
        preset="deepcenter_best_pt_with_safe_div_veto",
        axis=(
            "exp183 public fork with the DeepCenter block ON from best.pt "
            "(epoch 2) AND the safe-division veto enabled - the pairing the "
            "claimed 0.920 notebook reports as working"
        ),
        safe_div_veto='"1"',
        heading="# Biohub Exp220: DeepCenter from best.pt, Safe-Division Veto ON",
        body=(
            SHARED
            + "\n\nThis run is the claimed pairing: `best.pt` **with** the veto. "
            "Paired with Exp221, which keeps the checkpoint and drops the veto."
        ),
    )
    build(
        slug="biohub-exp221-deepcenter-best-no-safediv-veto",
        title="Biohub Exp221 Deepcenter Best No Safediv Veto",
        preset="deepcenter_best_pt_without_safe_div_veto",
        axis=(
            "exp183 public fork with the DeepCenter block ON from best.pt "
            "(epoch 2) and the safe-division veto OFF - isolates the checkpoint "
            "from the gate against Exp158"
        ),
        safe_div_veto="'0'",
        heading="# Biohub Exp221: DeepCenter from best.pt, Safe-Division Veto OFF",
        body=(
            SHARED
            + "\n\nThis run isolates the **checkpoint**. With Exp158 "
            "(`checkpoint_last.pt` + veto on, `0.905`) already on the board, "
            "Exp220 and Exp221 fill three cells of the 2x2 and attribute that "
            "loss to the checkpoint or to the gate."
        ),
    )


if __name__ == "__main__":
    main()
