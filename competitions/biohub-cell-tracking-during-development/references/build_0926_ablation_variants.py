from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE_DIR = ROOT / "notebooks" / "public-reproductions" / "rocker-0-926"
BASE_NOTEBOOK = BASE_DIR / "rocker-0-926-biohub-divsub.ipynb"
OUT_ROOT = ROOT / "notebooks" / "public-reproductions" / "0926-ablations"

VARIANTS = [
    {
        "slug": "exp231-deepcenter-safe-div-veto",
        "title": "Biohub 0.926 control: DeepCenter safe-division veto",
        "preset": "0926_control_deepcenter_safe_div_veto",
        "changes": {"BIOHUB_DEEPCENTER_SAFE_DIV_VETO": "1"},
    },
    {
        "slug": "exp232-retention-085",
        "title": "Biohub 0.926 control: retention guard 0.85",
        "preset": "0926_control_retention_085",
        "changes": {"BIOHUB_DUAL_SEED_MIN_CANDIDATE_RETENTION": "0.85"},
        "retention": "0.85",
    },
    {
        "slug": "exp233-retention-095",
        "title": "Biohub 0.926 control: retention guard 0.95",
        "preset": "0926_control_retention_095",
        "changes": {"BIOHUB_DUAL_SEED_MIN_CANDIDATE_RETENTION": "0.95"},
        "retention": "0.95",
    },
    {
        "slug": "exp234-secondary-edge-010",
        "title": "Biohub 0.926 control: secondary edge weight 0.10",
        "preset": "0926_control_secondary_edge_010",
        "changes": {"BIOHUB_SECONDARY_EDGE_WEIGHT": "0.10"},
    },
    {
        "slug": "exp235-secondary-edge-020",
        "title": "Biohub 0.926 control: secondary edge weight 0.20",
        "preset": "0926_control_secondary_edge_020",
        "changes": {"BIOHUB_SECONDARY_EDGE_WEIGHT": "0.20"},
    },
    {
        "slug": "exp236-safe-divergence-150",
        "title": "Biohub 0.926 control: safe-division divergence 1.50um",
        "preset": "0926_control_safe_divergence_150",
        "changes": {"BIOHUB_SAFE_DIV_DIVERGE_UM": "1.50"},
    },
]


def cell_source(cell: dict) -> str:
    source = cell.get("source", "")
    return "".join(source) if isinstance(source, list) else source


def set_cell_source(cell: dict, source: str) -> None:
    cell["source"] = source.splitlines(keepends=True)


def replace_once(text: str, old: str, new: str) -> str:
    if old not in text:
        raise RuntimeError(f"Expected text not found: {old!r}")
    return text.replace(old, new, 1)


def build_variant(variant: dict) -> None:
    notebook = json.loads(BASE_NOTEBOOK.read_text())
    for cell in notebook["cells"]:
        source = cell_source(cell)
        if cell.get("cell_type") == "markdown" and source.startswith("# Biohub Dual Seed"):
            source = replace_once(source, "# Biohub Dual Seed Frame Retention Guard V1", f"# {variant['title']}")
            source = source.replace("displayed `+0.001`", "displayed baseline gain")
            set_cell_source(cell, source)
        elif cell.get("cell_type") == "code" and "BIOHUB_PRESET =" in source:
            source = replace_once(source, "BIOHUB_PRESET = 'dual_seed_near_balanced_center_confirmed_synthetic_gap'", f"BIOHUB_PRESET = '{variant['preset']}'")
            for name, value in variant["changes"].items():
                marker = f'os.environ["{name}"] = '
                if marker in source:
                    lines = source.splitlines(keepends=True)
                    lines = [
                        (line[: line.index(marker) + len(marker)] + repr(value) + "\n")
                        if marker in line else line
                        for line in lines
                    ]
                    source = "".join(lines)
                else:
                    source += f'\nos.environ["{name}"] = {value!r}\n'
            set_cell_source(cell, source)
        elif cell.get("cell_type") == "code" and 'os.environ["BIOHUB_SECONDARY_EDGE_WEIGHT"] = "0.15"' in source:
            for name, value in variant["changes"].items():
                if name == "BIOHUB_SECONDARY_EDGE_WEIGHT":
                    source = replace_once(source, 'os.environ["BIOHUB_SECONDARY_EDGE_WEIGHT"] = "0.15"', f'os.environ["{name}"] = "{value}"')
            set_cell_source(cell, source)
        elif cell.get("cell_type") == "code" and "minimum_retention" in source and "Retention-guard submission schema" in source:
            retention = variant.get("retention")
            if retention:
                source = source.replace('float(_guard_record["minimum_retention"])\n        != 0.9', f'float(_guard_record["minimum_retention"])\n        != {retention}')
                source = source.replace('float(_guard_record["retention"])\n        < 0.9', f'float(_guard_record["retention"])\n        < {retention}')
                source = source.replace('"minimum_candidate_retention": 0.9', f'"minimum_candidate_retention": {retention}')
            set_cell_source(cell, source)
    out_dir = OUT_ROOT / variant["slug"]
    out_dir.mkdir(parents=True, exist_ok=True)
    code_file = f"{variant['slug']}.ipynb"
    (out_dir / code_file).write_text(json.dumps(notebook, indent=1) + "\n")
    metadata = {
        "id": f"dalloliogm/biohub-{variant['slug']}",
        # Kaggle resolves the title to the clean URL slug; keep it identical to
        # the requested id while retaining the human-readable title in the
        # notebook markdown and preset name.
        "title": f"biohub-{variant['slug']}",
        "code_file": code_file,
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
    (out_dir / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")


if __name__ == "__main__":
    for variant in VARIANTS:
        build_variant(variant)
        print(variant["slug"])
