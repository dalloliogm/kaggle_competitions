#!/usr/bin/env python3
"""Build the minimal Kaggle input-mount diagnostic for Biohub Exp204."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK = ROOT / "notebooks" / "diagnostics" / "biohub-exp204-input-mount-diagnostic.ipynb"
METADATA = NOTEBOOK.with_suffix(".kernel-metadata.json")


def cell(source: str) -> dict:
    return {"cell_type": "code", "execution_count": None, "metadata": {}, "outputs": [],
            "source": source.splitlines(keepends=True)}


def main() -> None:
    nb = json.loads(NOTEBOOK.read_text())
    nb["cells"] = [
        {"cell_type": "markdown", "metadata": {}, "source": [
            "# Biohub Exp204 — input-mount diagnostic\\n",
            "\\n",
            "This private notebook does not train or submit. It records which competition inputs "
            "Kaggle mounted, to explain why the public generator cannot find `train/`.\\n",
        ]},
        cell("""from pathlib import Path
import json

INPUT = Path('/kaggle/input')
expected = [
    Path('/kaggle/input/competitions/biohub-cell-tracking-during-development/train'),
    Path('/kaggle/input/biohub-cell-tracking-during-development/train'),
]

def entries(root, limit=250):
    if not root.exists():
        return []
    return [str(p.relative_to(root)) for p in sorted(root.rglob('*'))[:limit]]

zarr_paths = [str(p) for p in sorted(INPUT.rglob('*.zarr'))[:50]] if INPUT.exists() else []
report = {
    'input_exists': INPUT.exists(),
    'input_top_level': [p.name for p in sorted(INPUT.iterdir())] if INPUT.exists() else [],
    'input_entries_sample': entries(INPUT),
    'expected_train_paths': {str(p): p.exists() for p in expected},
    'zarr_paths_sample': zarr_paths,
}
print(json.dumps(report, indent=2))
Path('/kaggle/working/input_mount_diagnostic.json').write_text(json.dumps(report, indent=2))
assert zarr_paths, 'No .zarr training stores are mounted; inspect input_mount_diagnostic.json.'
"""),
    ]
    NOTEBOOK.write_text(json.dumps(nb, indent=1) + "\n")
    METADATA.write_text(json.dumps({
        "id": "dalloliogm/biohub-exp204-input-mount-diagnostic",
        "title": "Biohub Exp204: Input Mount Diagnostic",
        "code_file": NOTEBOOK.name,
        "language": "python",
        "kernel_type": "notebook",
        "is_private": True,
        "enable_gpu": False,
        "enable_internet": False,
        "competition_sources": ["biohub-cell-tracking-during-development"],
        "dataset_sources": [],
        "kernel_sources": [],
        "model_sources": [],
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
