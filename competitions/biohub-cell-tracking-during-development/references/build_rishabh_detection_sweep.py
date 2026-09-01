#!/usr/bin/env python3
"""Create isolated Kaggle kernels for the Rishabh detector-fusion sweep."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "notebooks" / "public-reproductions" / "rishabh-0-929"
SOURCE_NOTEBOOK = SOURCE_DIR / "biohub-938-sdw85.ipynb"
OUTPUT_ROOT = ROOT / "notebooks" / "public-reproductions" / "rishabh-detector-sweep"

VARIANTS = {
    "0475": ("biohub-rishabh-det-0475-v1", 0.475),
    "065": ("biohub-rishabh-det-065-v1", 0.65),
    "075": ("biohub-rishabh-det-075-v1", 0.75),
    "080": ("biohub-rishabh-det-080-v1", 0.80),
    "085": ("biohub-rishabh-det-085-v1", 0.85),
    "095": ("biohub-rishabh-det-095-v1", 0.95),
}


def main() -> None:
    notebook = json.loads(SOURCE_NOTEBOOK.read_text())
    source_assignment = 'os.environ["BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.85"'
    for label, (slug, weight) in VARIANTS.items():
        destination = OUTPUT_ROOT / f"weight-{label}"
        destination.mkdir(parents=True, exist_ok=True)
        code_name = f"biohub-rishabh-det-{label}.ipynb"
        variant = json.loads(json.dumps(notebook))
        replaced = 0
        for cell in variant["cells"]:
            source = "".join(cell.get("source", []))
            if source_assignment in source:
                source = source.replace(
                    source_assignment,
                    f'os.environ["BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "{weight:g}"',
                    1,
                )
                cell["source"] = source.splitlines(keepends=True)
                replaced += 1
        if replaced != 1:
            raise RuntimeError(f"expected one detector-weight assignment in {SOURCE_NOTEBOOK}, got {replaced}")
        (destination / code_name).write_text(json.dumps(variant, ensure_ascii=False, separators=(",", ":")))

        metadata = {
            "id": f"dalloliogm/{slug}",
            "title": slug,
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
            "docker_image": "gcr.io/kaggle-private-byod/python@sha256:37c64f7dd9c54116ecd1bcc88817c5469b88387388fade02bfa8bf3fc647d461",
            "machine_shape": "NvidiaTeslaT4",
        }
        metadata_text = json.dumps(metadata, indent=2) + "\n"
        (destination / "kernel-metadata.json").write_text(metadata_text)
        # The repository helper prefers a code-file sidecar over any stale
        # temporary push-folder metadata from an earlier failed version.
        (destination / f"{Path(code_name).stem}.kernel-metadata.json").write_text(metadata_text)
        print(f"{label}: {metadata['id']} -> {destination}")


if __name__ == "__main__":
    main()
