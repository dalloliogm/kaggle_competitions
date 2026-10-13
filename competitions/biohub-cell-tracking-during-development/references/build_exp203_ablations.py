"""Build controlled Exp203 ablation notebooks from the verified T4 recipe."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path("competitions/biohub-cell-tracking-during-development")
BASE = ROOT / "notebooks/biohub-exp203-classical-ensemble.ipynb"
OUT_DIR = ROOT / "notebooks/ablations"


VARIANTS = {
    "exp205-two-model-full": {
        "title": "Exp205 — Two-Model Detector Ablation",
        "tag": "exp205_two_model_full_downstream",
        "description": "Two original U-Net checkpoints, with Exp203 TTA, linker, and graph patches retained. Isolates the third checkpoint.",
        "branches": "two",
        "patches": "full",
    },
    "exp206-three-model-no-patches": {
        "title": "Exp206 — Three-Model Detector Without Graph Patches",
        "tag": "exp206_three_model_no_graph_patches",
        "description": "Three U-Net checkpoints and flip-quartet TTA, with graph patches disabled. Isolates the detector/TTA contribution.",
        "branches": "three",
        "patches": "none",
    },
    "exp207-three-model-gap-only": {
        "title": "Exp207 — Three-Model Ensemble With Gap Snap Only",
        "tag": "exp207_three_model_gap_only",
        "description": "Three U-Net checkpoints and TTA, with snap-only gap repair but no safe-division patch. Separates the graph patches.",
        "branches": "three",
        "patches": "gap",
    },
    "exp208-third-model-only": {
        "title": "Exp208 — Third U-Net Diagnostic",
        "tag": "exp208_third_model_only",
        "description": "The v2 top-hat checkpoint alone, using the Exp203 TTA/linker/repair stack. Diagnostic only; tests whether the new checkpoint has standalone signal.",
        "branches": "third",
        "patches": "full",
    },
    "exp209-three-model-divisions-only": {
        "title": "Exp209 — Three-Model Ensemble With Safe Divisions Only",
        "tag": "exp209_three_model_divisions_only",
        "description": "Three U-Net checkpoints and TTA with safe-division recovery retained but snap-only gap repair disabled. Isolates the missing graph-patch control.",
        "branches": "three",
        "patches": "div",
    },
    "exp210-three-model-no-tta": {
        "title": "Exp210 — Three-Model Ensemble Without Detection TTA",
        "tag": "exp210_three_model_no_detection_tta",
        "description": "Full Exp203 recipe with flip-quartet detection TTA disabled. Isolates the detector-time augmentation contribution.",
        "branches": "three",
        "patches": "full",
        "tta": "none",
    },
    "exp211-three-model-no-appearance-link": {
        "title": "Exp211 — Three-Model Ensemble Without Appearance Link Cost",
        "tag": "exp211_three_model_no_appearance_link",
        "description": "Full Exp203 recipe with the logit-score appearance term removed from Hungarian linking. Isolates the linker contribution.",
        "branches": "three",
        "patches": "full",
        "linker": "no_appearance",
    },
    "exp212-three-model-division-precision": {
        "title": "Exp212 — Three-Model Safe-Division Precision Probe",
        "tag": "exp212_three_model_division_precision",
        "description": "Full Exp203 recipe with stricter safe-division geometry gates and the same global/frame budgets. Tests precision, not division quantity.",
        "branches": "three",
        "patches": "full",
        "division": "precision",
    },
}


def lines(text: str) -> list[str]:
    return text.splitlines(keepends=True)


def markdown(text: str) -> dict:
    return {"cell_type": "markdown", "metadata": {}, "source": lines(text)}


def patch_cell(source: str, mode: str) -> str:
    if mode == "full":
        return source
    source = source.replace(
        'nid,n_gaps=_gap_close_1f_snap(nodes, edges, cand, cand_sc, cand_trees, nid)   # PATCH 2 (pre short-filter)',
        'nid,n_gaps=_gap_close_1f_snap(nodes, edges, cand, cand_sc, cand_trees, nid)   # PATCH 2 (pre short-filter)'
        if mode == "gap" else 'n_gaps=0  # gap-snap patch disabled',
    )
    source = source.replace(
        'n_div=_add_safe_divisions(nodes, edges)                                       # PATCH 1 (post linefit)',
        'n_div=0  # safe-division patch disabled'
        if mode in {"none", "gap"}
        else 'n_div=_add_safe_divisions(nodes, edges)                                       # PATCH 1 (post linefit)',
    )
    return source


def detection_cell(source: str, branches: str, tta: str = "full") -> str:
    start = source.index("_BRANCHES = []")
    end = source.index("def _flip", start)
    if branches == "two":
        branch_code = """_BRANCHES = []
_BRANCHES.append(([MODELS[0]], [1.0], ''))
_BRANCHES.append(([MODELS[1]], [1.0], 'tophat'))
_FLIP_VIEWS = (0, 1, 2, 3)
"""
    elif branches == "three":
        branch_code = """_BRANCHES = []
_BRANCHES.append(([MODELS[0]], [1.0], ''))
_BRANCHES.append(([MODELS[1]], [1.0], 'tophat'))
_ck = torch.load(_find_weight('unet3d_v2_tophat_b32.pt'), map_location=DEVICE)
_m = UNet3D(base=_ck.get('base', 24)).to(DEVICE)
_m.load_state_dict(_ck['state_dict']); _m.eval()
print('loaded', 'unet3d_v2_tophat_b32.pt', '| val_recall', _ck.get('val_recall'))
_BRANCHES.append(([_m], [1.0], 'tophat'))
_FLIP_VIEWS = (0, 1, 2, 3)
"""
    elif branches == "third":
        branch_code = """_ck = torch.load(_find_weight('unet3d_v2_tophat_b32.pt'), map_location=DEVICE)
_m = UNet3D(base=_ck.get('base', 24)).to(DEVICE)
_m.load_state_dict(_ck['state_dict']); _m.eval()
print('loaded', 'unet3d_v2_tophat_b32.pt', '| val_recall', _ck.get('val_recall'))
_BRANCHES = [([_m], [1.0], 'tophat')]
_FLIP_VIEWS = (0, 1, 2, 3)
"""
    else:
        raise ValueError(branches)
    if tta == "none":
        branch_code = branch_code.replace("_FLIP_VIEWS = (0, 1, 2, 3)", "_FLIP_VIEWS = (0,)")
    return source[:start] + branch_code + source[end:]


def linker_cell(source: str, linker: str = "full", division: str = "full") -> str:
    if linker == "no_appearance":
        source = source.replace("LINK_SIM_W = 2.0", "LINK_SIM_W = 0.0")
    if division == "precision":
        source = source.replace(
            "DIV_PARENT_UM=12.0; DIV_SISTER_UM=15.0; DIV_CHILD_UM=10.0; DIV_DIVERGE_UM=2.25",
            "DIV_PARENT_UM=10.0; DIV_SISTER_UM=12.0; DIV_CHILD_UM=8.0; DIV_DIVERGE_UM=3.0",
        )
    return source


def build(slug: str, cfg: dict) -> None:
    notebook = json.loads(BASE.read_text())
    cells = notebook["cells"]
    intro = f"""# {cfg['title']}

This controlled ablation is derived from the verified Exp203 T4 recipe.

## Objective

{cfg['description']}

The experiment keeps the same competition data, public checkpoints, physical
units, output schema, and downstream audit. Compare its node/edge/division
counts and output hash with Exp203 before considering any submission.
"""
    cells[0] = markdown(intro)
    cells[2]["source"] = lines("".join(cells[2]["source"]).replace(
        "EXPERIMENT_TAG = 'exp203_classical_three_model_ensemble'",
        f"EXPERIMENT_TAG = '{cfg['tag']}'",
    ))
    cells[5]["source"] = lines(
        detection_cell("".join(cells[5]["source"]), cfg["branches"], cfg.get("tta", "full"))
    )
    cells[6]["source"] = lines(
        linker_cell(
            patch_cell("".join(cells[6]["source"]), cfg["patches"]),
            cfg.get("linker", "full"),
            cfg.get("division", "full"),
        )
    )
    notebook["cells"] = cells
    out = OUT_DIR / f"{slug}.ipynb"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(notebook, indent=1) + "\n")
    kernel_slug = {
        "exp205-two-model-full": "exp205-two-model-detector-ablation-v2",
        "exp206-three-model-no-patches": "exp206-nopatches-ablation-v3",
        "exp207-three-model-gap-only": "exp207-three-model-ensemble-with-gap-snap-only-v2",
        "exp208-third-model-only": "exp208-third-model-only-v2",
        "exp209-three-model-divisions-only": "exp209-three-model-divisions-only-v1",
        "exp210-three-model-no-tta": "exp210-three-model-no-tta-v1",
        "exp211-three-model-no-appearance-link": "exp211-three-model-no-appearance-link-v1",
        "exp212-three-model-division-precision": "exp212-three-model-division-precision-v1",
    }[slug]
    meta = {
        "id": f"dalloliogm/{kernel_slug}",
        "title": kernel_slug,
        "code_file": out.name,
        "language": "python",
        "kernel_type": "notebook",
        "is_private": True,
        "enable_gpu": True,
        "enable_internet": False,
        "competition_sources": ["biohub-cell-tracking-during-development"],
        "dataset_sources": [
            "xiaoleilian/biohub-unet3d-weights",
            "xiaoleilian/biohub-unet3d-weights-v2models",
        ],
        "machine_shape": "NvidiaTeslaT4",
    }
    (out.with_suffix(".kernel-metadata.json")).write_text(json.dumps(meta, indent=2) + "\n")


def main() -> None:
    for slug, cfg in VARIANTS.items():
        build(slug, cfg)
        print(slug)


if __name__ == "__main__":
    main()
