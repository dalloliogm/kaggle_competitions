#!/usr/bin/env python3
"""Create a capped, private derivative of the public Biohub synthetic builder.

The public builder's advertised output was not mountable as a Kaggle kernel
source on 2026-08-19.  This preserves its code verbatim while changing only
the first configuration cell, yielding a small lineage-only feasibility set
that can be attached to Exp204's diagnostic notebook.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "notebooks" / "exp204-synthetic-mini-builder"

CONFIG = """import os
# The public notebook uses this flag as a guard against its earlier showcase
# pipeline.  The final public-dataset builder still executes in the last cell.
os.environ['SYNTH_GRIDSEARCH'] = '1'
os.environ['SYNTH_NATIVE_COMPARE'] = '0'
os.environ['SYNTH_NATIVE_LAYOUT'] = '0'
os.environ['SYNTH_NATIVE_SIM'] = '0'
os.environ['SYNTH_TEMPORAL'] = '0'
os.environ['SYNTH_SWEEP'] = '0'
os.environ['SYNTH_BLURSWEEP'] = '0'
os.environ['QR_NATGALLERY'] = '0'
os.environ['DSBUILD_RUN'] = '1'
# Keep the build small and sequence-heavy: Exp204 needs labelled lineages,
# not static pretraining volumes.  This is a feasibility set, not a model.
os.environ['DS_TARGET_GB'] = '0.25'
os.environ['DS_SEQ_LEN'] = '6'
os.environ['DS_SEQ_FRAC'] = '0.99'
os.environ['DS_BUDGET_H'] = '1.0'
os.environ['DS_DIV_RATE'] = '0.05'
os.environ['SYNTH_PLACE_MODE'] = 'shell'
print('EXP204 MINI SYNTHETIC DATASET: lineage feasibility build')
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True,
                        help="Downloaded public generator .ipynb")
    args = parser.parse_args()

    nb = json.loads(args.source.read_text())
    assert nb["cells"][0]["cell_type"] == "code"
    nb["cells"][0]["source"] = CONFIG.splitlines(keepends=True)
    nb["cells"].insert(1, {
        "cell_type": "markdown",
        "metadata": {},
        "source": [
            "# Biohub Exp204 — capped synthetic lineage builder\\n",
            "\\n",
            "Private derivative of `josefreitasalvesneto/biohub-synthetic-dataset`. "
            "The public output was not attachable on 2026-08-19, so this runs the "
            "public generator unchanged except for the bounded configuration in the "
            "first cell. It produces a small sequence-heavy output for Exp204 only.\\n",
        ],
    })
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "biohub-exp204-synthetic-mini-builder.ipynb").write_text(
        json.dumps(nb, indent=1) + "\n"
    )
    metadata = {
        "id": "dalloliogm/biohub-exp204-synthetic-mini-builder",
        "title": "Biohub Exp204: Capped Synthetic Lineage Builder",
        "code_file": "biohub-exp204-synthetic-mini-builder.ipynb",
        "language": "python",
        "kernel_type": "notebook",
        "is_private": True,
        "enable_gpu": False,
        # The source conditionally installs zarr/tracksdata in Kaggle's image.
        "enable_internet": True,
        "competition_sources": ["biohub-cell-tracking-during-development"],
        "dataset_sources": [],
        "kernel_sources": [],
        "model_sources": [],
    }
    (OUT / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")


if __name__ == "__main__":
    main()
