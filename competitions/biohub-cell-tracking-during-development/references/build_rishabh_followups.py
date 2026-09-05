#!/usr/bin/env python3
"""Build isolated follow-ups from the scored Rishabh .65 geometry candidate."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "notebooks" / "public-reproductions" / "rishabh-division-geometry-065" / "biohub-rishabh-division-geometry-065-v1.ipynb"


def build(name: str, replacements: dict[str, str], description: str) -> None:
    notebook = json.loads(SOURCE.read_text())
    source_text = "\n".join(
        "".join(cell.get("source", [])) for cell in notebook.get("cells", [])
    )
    for old, new in replacements.items():
        if old not in source_text:
            raise RuntimeError(f"{name}: expected source text not found: {old}")
        source_text = source_text.replace(old, new)

    # Re-split the concatenated source is unsafe for cell boundaries, so apply
    # replacements independently to preserve all notebook structure.
    for cell in notebook["cells"]:
        cell_source = "".join(cell.get("source", []))
        for old, new in replacements.items():
            cell_source = cell_source.replace(old, new)
        cell["source"] = cell_source.splitlines(keepends=True)

    out_dir = ROOT / "notebooks" / "public-reproductions" / name
    out_dir.mkdir(parents=True, exist_ok=True)
    code_name = f"{name}.ipynb"
    (out_dir / code_name).write_text(json.dumps(notebook, ensure_ascii=False, separators=(",", ":")))
    metadata = {
        "id": f"dalloliogm/{name}",
        "title": name,
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
    (out_dir / "kernel-metadata.json").write_text(metadata_text)
    (out_dir / f"{Path(code_name).stem}.kernel-metadata.json").write_text(metadata_text)
    print(f"built {name}: {description}")


def main() -> None:
    build(
        "rishabh-division-geometry-075",
        {
            'BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.65"':
                'BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.75"',
            "secondary weight `0.65`": "secondary weight `0.75`",
        },
        "same scored geometry, detector-fusion weight .75",
    )
    build(
        "rishabh-division-geometry-080",
        {
            'BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.65"':
                'BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.80"',
            "secondary weight `0.65`": "secondary weight `0.80`",
        },
        "same scored geometry, detector-fusion weight .80",
    )
    build(
        "rishabh-division-geometry-085",
        {
            'BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.65"':
                'BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.85"',
            "secondary weight `0.65`": "secondary weight `0.85`",
        },
        "same scored geometry, detector-fusion weight .85",
    )
    build(
        "rishabh-public-0941-repro",
        {
            'BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.65"':
                'BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.80"',
            'BIOHUB_GAP_CLOSE_UM"] = "5.8"':
                'BIOHUB_GAP_CLOSE_UM"] = "5.0"',
            '"BIOHUB_GAP_CLOSE_UM": 5.8':
                '"BIOHUB_GAP_CLOSE_UM": 5.0',
            'os.environ.get("BIOHUB_DEEPCENTER_SAFE_DIV_THRESHOLD", "0.12")':
                'os.environ.get("BIOHUB_DEEPCENTER_SAFE_DIV_THRESHOLD", "0.25")',
            "secondary weight `0.65`": "secondary weight `0.80`",
        },
        "public 0.941 reproduction: .80 fusion, gap 5.0um, DeepCenter threshold .25",
    )
    build(
        "rishabh-division-geometry-sdec12",
        {
            'BIOHUB_SAFE_DIV_EXISTING_CHILD_MAX_UM"] = "10.0"':
                'BIOHUB_SAFE_DIV_EXISTING_CHILD_MAX_UM"] = "12.0"',
        },
        "same scored geometry and .65 detector mix, existing-child cap 12um",
    )


if __name__ == "__main__":
    main()
