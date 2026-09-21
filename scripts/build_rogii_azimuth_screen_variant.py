#!/usr/bin/env python3
"""Build a reduced-cost, explicitly non-deployable azimuth screening notebook."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "competitions/rogii-wellbore-geology-prediction/notebooks/rogii-azimuth-artifact-builder.ipynb"
TARGET = ROOT / "competitions/rogii-wellbore-geology-prediction/notebooks/rogii-azimuth-artifact-builder-screen.ipynb"


def replace_once(text: str, old: str, new: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one occurrence, found {count}: {old!r}")
    return text.replace(old, new, 1)


notebook = json.loads(SOURCE.read_text())

notebook["cells"][0]["source"] = [
    "# ROGII GS1.30 azimuth reduced-cost screen\n",
    "\n",
    "**Objective.** Test whether the direction-conditioned model has enough paired signal to justify the full artifact build when the production-scale builder cannot finish within the Kaggle runtime budget.\n",
    "\n",
    "This notebook is deliberately **non-deployable**. It uses fewer wells, PF seeds, particles, bootstrap draws, and masked-prefix wells. Its outputs may only select between stopping azimuth work and rerunning the frozen full builder; they must never be attached to an inference submission.\n",
]

replacements = {
    'ARTIFACT_BUILDER_CODE_VERSION = "azimuth-builder-v1-2026-08-01"':
        'ARTIFACT_BUILDER_CODE_VERSION = "azimuth-builder-screen-v1-2026-08-01"',
    'ARTIFACT_ROOT = Path("/kaggle/working/rogii-gs130-azimuth-artifacts-v1") if Path("/kaggle/working").exists() else Path("./rogii-gs130-azimuth-artifacts-v1")':
        'ARTIFACT_ROOT = Path("/kaggle/working/rogii-gs130-azimuth-screen-v1") if Path("/kaggle/working").exists() else Path("./rogii-gs130-azimuth-screen-v1")',
    'MASKED_PREFIX_MAX_WELLS = int(os.environ.get("MASKED_PREFIX_MAX_WELLS", "60"))  # 0 = all eligible':
        'MASKED_PREFIX_MAX_WELLS = int(os.environ.get("MASKED_PREFIX_MAX_WELLS", "24"))  # screening only',
    'WELL_BOOTSTRAP_DRAWS = 2000': 'WELL_BOOTSTRAP_DRAWS = 500',
    'PF_SEEDS = 128': 'PF_SEEDS = 32',
    'PF_PARTICLES = 500': 'PF_PARTICLES = 300',
    'N_TRAIN_WELLS = int(os.environ.get("N_TRAIN_WELLS", "0"))  # 0 = all':
        'N_TRAIN_WELLS = int(os.environ.get("N_TRAIN_WELLS", "320"))  # deterministic UUID-sorted screen',
    '"all_oof_rows_covered_once": bool(np.all(fold_ids >= 0)),':
        '"all_oof_rows_covered_once": bool(np.all(fold_ids >= 0)),\n        "reduced_cost_screen_only": False,',
    '"the clean standalone spatial imputers are initialized once on all training wells; paired deltas remain isolated, but absolute OOF estimates may be optimistic because spatial priors are not refit inside each fold",':
        '"the clean standalone spatial imputers are initialized once on all training wells; paired deltas remain isolated, but absolute OOF estimates may be optimistic because spatial priors are not refit inside each fold",\n            "reduced-cost screen uses only 320 UUID-sorted wells, 32 PF seeds, 300 particles, 500 bootstrap draws, and 24 masked-prefix wells; it is never deployable",',
}

for cell in notebook["cells"]:
    if cell.get("cell_type") != "code":
        continue
    source = "".join(cell.get("source", []))
    for old, new in list(replacements.items()):
        if old in source:
            source = replace_once(source, old, new)
            del replacements[old]
    cell["source"] = source.splitlines(keepends=True)
    cell["execution_count"] = None
    cell["outputs"] = []

if replacements:
    raise RuntimeError(f"Unapplied replacements: {sorted(replacements)}")

TARGET.write_text(json.dumps(notebook, indent=1, ensure_ascii=False) + "\n")
print(TARGET)
