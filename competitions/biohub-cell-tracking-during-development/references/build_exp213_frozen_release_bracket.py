"""Build Exp213 from Exp202 with one frozen-transition release-gate change."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).parents[1]
SOURCE_DIR = ROOT / "notebooks" / "exp202-bounded-count-calibration"
SOURCE_NOTEBOOK = SOURCE_DIR / "biohub-exp196-deepcenter-gap-confirmed.ipynb"
OUT_DIR = ROOT / "notebooks" / "exp213-frozen-release-bracket"
OUT_NOTEBOOK = OUT_DIR / "biohub-exp213-frozen-release-10p5.ipynb"
OUT_META = OUT_DIR / "kernel-metadata.json"


def main() -> None:
    notebook = json.loads(SOURCE_NOTEBOOK.read_text())
    replaced = 0
    for cell in notebook["cells"]:
        source = "".join(cell.get("source", []))
        if "BIOHUB_FROZEN_RELEASE_RELAXED_UM" in source:
            source = source.replace("BIOHUB_FROZEN_RELEASE_RELAXED_UM\"] = \"11.5\"", "BIOHUB_FROZEN_RELEASE_RELAXED_UM\"] = \"10.5\"")
            source = source.replace("exp202_bounded_count_calibration", "exp213_frozen_release_10p5")
            source = source.replace("Exp202", "Exp213")
            source = source.replace("exp202", "exp213")
            cell["source"] = source.splitlines(keepends=True)
            replaced += 1
        elif "exp202_bounded_count_calibration" in source:
            source = source.replace("exp202_bounded_count_calibration", "exp213_frozen_release_10p5")
            source = source.replace("Exp202", "Exp213")
            source = source.replace("exp202", "exp213")
            cell["source"] = source.splitlines(keepends=True)
    if replaced != 2:
        raise RuntimeError(f"Expected two frozen-release configuration occurrences, found {replaced}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_NOTEBOOK.write_text(json.dumps(notebook, indent=1) + "\n")
    metadata = {
        "id": "dalloliogm/biohub-exp213-frozen-release-10p5",
        "title": "biohub-exp213-frozen-release-10p5",
        "code_file": OUT_NOTEBOOK.name,
        "language": "python",
        "kernel_type": "notebook",
        "is_private": True,
        "enable_gpu": True,
        "enable_tpu": False,
        "enable_internet": False,
        "keywords": ["gpu", "frozen-transition", "ablation"],
        "dataset_sources": [
            "pilkwang/biohub-deepcenter-unet3d-center-prior-v1",
            "pilkwang/biohub-temporal-unet3d-seed314159-v1",
            "pilkwang/biohub-tracking-support-pack-50ep-v1",
            "pilkwang/biohub-local-association-ranker-unet300-v1",
        ],
        "competition_sources": ["biohub-cell-tracking-during-development"],
        "docker_image": "gcr.io/kaggle-private-byod/python@sha256:37c64f7dd9c54116ecd1bcc88817c5469b88387388fade02bfa8bf3fc647d461",
        "machine_shape": "NvidiaTeslaT4",
    }
    OUT_META.write_text(json.dumps(metadata, indent=2) + "\n")
    print(OUT_NOTEBOOK)
    print(OUT_META)


if __name__ == "__main__":
    main()
