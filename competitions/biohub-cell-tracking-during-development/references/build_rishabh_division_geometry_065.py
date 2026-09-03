#!/usr/bin/env python3
"""Prepare the .65 control with Rishabh's division-geometry stack."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path("/tmp/biohub-rishabh-div45/biohub-div45-stack.ipynb")
OUT = ROOT / "notebooks" / "public-reproductions" / "rishabh-division-geometry-065"
SLUG = "biohub-rishabh-division-geometry-065-v1"


def main() -> None:
    notebook = json.loads(SOURCE.read_text())
    replacements = {
        'os.environ["BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.80"':
            'os.environ["BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.65"',
        'secondary weight `0.80`':
            'secondary weight `0.65`',
    }
    changed = 0
    for cell in notebook["cells"]:
        source = "".join(cell.get("source", []))
        for old, new in replacements.items():
            if old in source:
                source = source.replace(old, new)
                changed += 1
        cell["source"] = source.splitlines(keepends=True)
    if changed < 2:
        raise RuntimeError(f"expected configuration and description replacements, got {changed}")

    OUT.mkdir(parents=True, exist_ok=True)
    code_name = f"{SLUG}.ipynb"
    (OUT / code_name).write_text(json.dumps(notebook, ensure_ascii=False, separators=(",", ":")))
    metadata = {
        "id": f"dalloliogm/{SLUG}",
        "title": SLUG,
        "code_file": code_name,
        "language": "python",
        "kernel_type": "notebook",
        "is_private": True,
        "enable_gpu": True,
        "enable_tpu": False,
        "enable_internet": False,
        "keywords": ["gpu"],
        "dataset_sources": [
            "pilkwang/biohub-deepcenter-unet3d-center-prior-v1",
            "pilkwang/biohub-temporal-unet3d-seed314159-v1",
            "pilkwang/biohub-tracking-support-pack-50ep-v1",
            "pilkwang/pilkwang-public-dataset-for-notebooks-figures",
        ],
        "kernel_sources": [],
        "competition_sources": ["biohub-cell-tracking-during-development"],
        "model_sources": [],
        "machine_shape": "NvidiaTeslaT4",
    }
    metadata_text = json.dumps(metadata, indent=2) + "\n"
    (OUT / "kernel-metadata.json").write_text(metadata_text)
    (OUT / f"{Path(code_name).stem}.kernel-metadata.json").write_text(metadata_text)
    print(OUT)


if __name__ == "__main__":
    main()
