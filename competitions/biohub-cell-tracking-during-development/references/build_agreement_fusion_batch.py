#!/usr/bin/env python3
"""Prepare private, offline Kaggle kernels for the agreement-gated fusion batch."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path("/tmp/biohub-public-flex-agreement/biohub-agreement-gated-dual-seed-fusion.ipynb")
OUT = ROOT / "notebooks" / "public-reproductions" / "agreement-fusion-batch-20260901"

VARIANTS = {
    "wm065-lm035": {"weight": "0.65", "margin": "0.35", "mode": "low_margin_consensus"},
    "wm080-lm035": {"weight": "0.80", "margin": "0.35", "mode": "low_margin_consensus"},
    "wm080-lm020": {"weight": "0.80", "margin": "0.20", "mode": "low_margin_consensus"},
    "wm085-lm035": {"weight": "0.85", "margin": "0.35", "mode": "low_margin_consensus"},
    "wm075-lm035": {"weight": "0.75", "margin": "0.35", "mode": "low_margin_consensus"},
    "wm090-lm035": {"weight": "0.90", "margin": "0.35", "mode": "low_margin_consensus"},
    "wm080-lm050": {"weight": "0.80", "margin": "0.50", "mode": "low_margin_consensus"},
    "adaptive080": {"weight": "0.80", "margin": "0.35", "mode": "adaptive"},
}

DATASETS = [
    "pilkwang/biohub-deepcenter-unet3d-center-prior-v1",
    "pilkwang/biohub-temporal-unet3d-seed314159-v1",
    "pilkwang/biohub-tracking-support-pack-50ep-v1",
    "pilkwang/pilkwang-public-dataset-for-notebooks-figures",
]


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"expected one occurrence of {old!r}, found {text.count(old)}")
    return text.replace(old, new, 1)


def main() -> None:
    source_nb = json.loads(SOURCE.read_text())
    for label, cfg in VARIANTS.items():
        slug = f"biohub-agreement-{label}-v1"
        folder = OUT / label
        folder.mkdir(parents=True, exist_ok=True)
        nb = json.loads(json.dumps(source_nb))
        changed = 0
        for cell in nb["cells"]:
            source = "".join(cell.get("source", []))
            replacements = [
                ('os.environ["BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "0.80"',
                 f'os.environ["BIOHUB_SECONDARY_DETECTION_WEIGHT"] = "{cfg["weight"]}"'),
                ('os.environ["BIOHUB_SECONDARY_LINK_MODE"] = "low_margin_consensus"',
                 f'os.environ["BIOHUB_SECONDARY_LINK_MODE"] = "{cfg["mode"]}"'),
                ('os.environ["BIOHUB_SECONDARY_LOW_MARGIN_MAX"] = "0.35"',
                 f'os.environ["BIOHUB_SECONDARY_LOW_MARGIN_MAX"] = "{cfg["margin"]}"'),
            ]
            for old, new in replacements:
                if old in source:
                    source = replace_once(source, old, new)
                    changed += 1
            cell["source"] = source.splitlines(keepends=True)
        if changed != 3:
            raise RuntimeError(f"{label}: expected three configuration replacements, got {changed}")

        code_name = f"{slug}.ipynb"
        (folder / code_name).write_text(json.dumps(nb, ensure_ascii=False, separators=(",", ":")))
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
            "dataset_sources": DATASETS,
            "kernel_sources": [],
            "competition_sources": ["biohub-cell-tracking-during-development"],
            "model_sources": [],
            "machine_shape": "NvidiaTeslaT4",
        }
        metadata_text = json.dumps(metadata, indent=2) + "\n"
        (folder / "kernel-metadata.json").write_text(metadata_text)
        (folder / f"{Path(code_name).stem}.kernel-metadata.json").write_text(metadata_text)
        print(f"{label}: {metadata['id']} -> {folder}")


if __name__ == "__main__":
    main()
