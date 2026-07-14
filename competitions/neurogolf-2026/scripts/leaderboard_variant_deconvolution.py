#!/usr/bin/env python3
"""Estimate NeuroGolf task-variant value from additive leaderboard scores."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import pathlib
import zipfile
from dataclasses import dataclass

import numpy as np


WORKSPACE = pathlib.Path(__file__).resolve().parents[1]
REPO_ROOT = WORKSPACE.parents[1]
REFERENCE_NAME = "exact_rewrite_v1"
REFERENCE_SCORE = 7269.74
DEFAULT_OUT_DIR = WORKSPACE / "references" / "analysis"


@dataclass(frozen=True)
class ArchiveLabel:
    name: str
    path: pathlib.Path
    public_score: float
    evidence: str


LABELED_ARCHIVES = [
    ArchiveLabel(
        "account_baseline",
        WORKSPACE / "references" / "own-kernels" / "2026-neurogolf-baseline-output" / "submission.zip",
        7267.32,
        "Kaggle submission 54487100",
    ),
    ArchiveLabel(
        "account_plus_ryosuke_7",
        WORKSPACE / "submissions" / "own7267-plus-ryosuke-7" / "submission.zip",
        7267.19,
        "Kaggle submission 54529022",
    ),
    ArchiveLabel(
        "account_plus_ryosuke_5",
        WORKSPACE / "submissions" / "own7267-plus-ryosuke-lowrisk-5" / "submission.zip",
        7267.27,
        "Kaggle submission 54529420",
    ),
    ArchiveLabel(
        "account_plus_ryosuke_a3",
        WORKSPACE / "submissions" / "own7267-plus-ryosuke-lowrisk-a3" / "submission.zip",
        7267.29,
        "Kaggle submission 54529552",
    ),
    ArchiveLabel(
        "account_plus_ryosuke_b2",
        WORKSPACE / "submissions" / "own7267-plus-ryosuke-lowrisk-b2" / "submission.zip",
        7267.29,
        "Kaggle submission 54529559",
    ),
    ArchiveLabel(
        "account_plus_frank_task074",
        WORKSPACE / "submissions" / "own7267-plus-frank-task074" / "submission.zip",
        7267.24,
        "Kaggle submission 54619246",
    ),
    ArchiveLabel(
        "poby_7268",
        WORKSPACE / "references" / "public-kernels" / "poby-7268-best-score" / "submission.zip",
        7268.00,
        "Kaggle submission 54619344",
    ),
    ArchiveLabel(
        "poby_rollback_six",
        WORKSPACE / "submissions" / "poby7268-rollback-six-larger-tasks" / "submission.zip",
        7267.90,
        "Kaggle submission 54638892",
    ),
    ArchiveLabel(
        "lucifer_circuit_forge",
        WORKSPACE / "references" / "public-kernels" / "lucifer-agi-circuit-forge" / "submission.zip",
        7269.60,
        "Kaggle submission 54645666",
    ),
    ArchiveLabel(
        "lucifer_plus_kaiwalya_six",
        WORKSPACE / "submissions" / "lucifer-plus-kaiwalya-six-no205" / "submission.zip",
        7269.61,
        "Kaggle submission 54646591",
    ),
    ArchiveLabel(
        "current_plus_anas_054_101_396",
        WORKSPACE / "submissions" / "current-plus-anas-explicit-054-101-396" / "submission.zip",
        7269.59,
        "Kaggle submission 54647024",
    ),
    ArchiveLabel(
        "current_plus_anas_054",
        WORKSPACE / "submissions" / "current-plus-anas-task054" / "submission.zip",
        7269.59,
        "Kaggle submission 54647140",
    ),
    ArchiveLabel(
        "current_plus_jonathan_197_264",
        WORKSPACE / "submissions" / "current-plus-jonathan-explicit-197-264" / "submission.zip",
        7269.54,
        "Kaggle submission 54647351",
    ),
    ArchiveLabel(
        REFERENCE_NAME,
        WORKSPACE / "submissions" / "exact-rewrite-pass-v1" / "submission.zip",
        REFERENCE_SCORE,
        "Kaggle submission 54652438",
    ),
]


def archive_payloads(path: pathlib.Path) -> dict[str, bytes]:
    with zipfile.ZipFile(path) as zf:
        payloads = {
            pathlib.PurePosixPath(name).name.removesuffix(".onnx"): zf.read(name)
            for name in zf.namelist()
            if name.endswith(".onnx")
        }
    if len(payloads) != 400:
        raise ValueError(f"{path} has {len(payloads)} root ONNX files, expected 400")
    return payloads


def variant_hash(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()[:16]


def archive_variants(path: pathlib.Path) -> dict[str, tuple[str, int]]:
    return {task: (variant_hash(raw), len(raw)) for task, raw in archive_payloads(path).items()}


def public_archives() -> list[tuple[str, pathlib.Path]]:
    root = WORKSPACE / "references" / "public-kernels"
    return sorted((path.parent.name, path) for path in root.glob("*/submission.zip"))


def fit_ridge(x: np.ndarray, y: np.ndarray, ridge: float) -> np.ndarray:
    if x.shape[1] == 0:
        return np.zeros(0, dtype=float)
    return np.linalg.solve(x.T @ x + ridge * np.eye(x.shape[1]), x.T @ y)


def choose_ridge(x: np.ndarray, y: np.ndarray) -> tuple[float, float]:
    if len(y) < 3:
        return 1.0, float("nan")
    candidates = np.logspace(-4, 2, 13)
    scored = []
    for ridge in candidates:
        errors = []
        for holdout in range(len(y)):
            keep = np.arange(len(y)) != holdout
            beta = fit_ridge(x[keep], y[keep], float(ridge))
            errors.append(float(x[holdout] @ beta - y[holdout]))
        rmse = float(np.sqrt(np.mean(np.square(errors))))
        scored.append((rmse, float(ridge)))
    rmse, ridge = min(scored)
    return ridge, rmse


def write_csv(path: pathlib.Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--max-pair-differences", type=int, default=10)
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    missing = [str(item.path) for item in LABELED_ARCHIVES if not item.path.exists()]
    if missing:
        raise SystemExit("Missing labeled archives:\n" + "\n".join(missing))

    variants = {item.name: archive_variants(item.path) for item in LABELED_ARCHIVES}
    labels = {item.name: item for item in LABELED_ARCHIVES}
    reference = variants[REFERENCE_NAME]

    feature_keys = sorted(
        {
            (task, item_hash)
            for name, task_variants in variants.items()
            if name != REFERENCE_NAME
            for task, (item_hash, _) in task_variants.items()
            if item_hash != reference[task][0]
        }
    )
    feature_index = {key: index for index, key in enumerate(feature_keys)}
    fit_names = [item.name for item in LABELED_ARCHIVES if item.name != REFERENCE_NAME]
    x = np.zeros((len(fit_names), len(feature_keys)), dtype=float)
    y = np.zeros(len(fit_names), dtype=float)
    for row_index, name in enumerate(fit_names):
        y[row_index] = labels[name].public_score - REFERENCE_SCORE
        for task, (item_hash, _) in variants[name].items():
            feature = (task, item_hash)
            if feature in feature_index:
                x[row_index, feature_index[feature]] = 1.0

    ridge, loo_rmse = choose_ridge(x, y)
    beta = fit_ridge(x, y, ridge)
    fitted = x @ beta
    fit_rmse = float(np.sqrt(np.mean(np.square(fitted - y))))
    support = x.sum(axis=0).astype(int)

    pair_rows = []
    exact_pair_delta: dict[tuple[str, str], list[float]] = {}
    for left_index, left in enumerate(LABELED_ARCHIVES):
        for right in LABELED_ARCHIVES[left_index + 1 :]:
            differences = [
                task
                for task in sorted(reference)
                if variants[left.name][task][0] != variants[right.name][task][0]
            ]
            if not differences or len(differences) > args.max_pair_differences:
                continue
            score_delta = left.public_score - right.public_score
            for task in differences:
                left_hash = variants[left.name][task][0]
                right_hash = variants[right.name][task][0]
                pair_rows.append(
                    {
                        "left": left.name,
                        "right": right.name,
                        "task": task,
                        "left_hash": left_hash,
                        "right_hash": right_hash,
                        "pair_task_count": len(differences),
                        "score_delta_left_minus_right": f"{score_delta:.6f}",
                        "equal_share_delta": f"{score_delta / len(differences):.6f}",
                        "strength": "exact_single_task" if len(differences) == 1 else "group_constraint",
                    }
                )
                if len(differences) == 1:
                    if right_hash == reference[task][0]:
                        exact_pair_delta.setdefault((task, left_hash), []).append(score_delta)
                    if left_hash == reference[task][0]:
                        exact_pair_delta.setdefault((task, right_hash), []).append(-score_delta)

    candidate_sources: dict[tuple[str, str], list[str]] = {}
    candidate_sizes: dict[tuple[str, str], int] = {}
    for source_name, path in public_archives():
        for task, (item_hash, size) in archive_variants(path).items():
            if item_hash == reference[task][0]:
                continue
            key = (task, item_hash)
            candidate_sources.setdefault(key, []).append(source_name)
            candidate_sizes[key] = size

    candidate_rows = []
    for key, sources in candidate_sources.items():
        task, item_hash = key
        feature_id = feature_index.get(key)
        estimates = exact_pair_delta.get(key, [])
        exact_estimate = float(np.mean(estimates)) if estimates else None
        ridge_estimate = float(beta[feature_id]) if feature_id is not None else None
        labeled_support = int(support[feature_id]) if feature_id is not None else 0
        ranking_estimate = exact_estimate if exact_estimate is not None else ridge_estimate
        candidate_rows.append(
            {
                "task": task,
                "variant_hash": item_hash,
                "candidate_size": candidate_sizes[key],
                "reference_size": reference[task][1],
                "byte_delta": candidate_sizes[key] - reference[task][1],
                "public_source_count": len(sources),
                "public_sources": ";".join(sorted(sources)),
                "labeled_support": labeled_support,
                "ridge_estimated_delta": "" if ridge_estimate is None else f"{ridge_estimate:.6f}",
                "exact_single_task_delta": "" if exact_estimate is None else f"{exact_estimate:.6f}",
                "ranking_estimate": "" if ranking_estimate is None else f"{ranking_estimate:.6f}",
                "evidence": "exact_single_task" if exact_estimate is not None else "ridge_attribution",
            }
        )
    candidate_rows.sort(
        key=lambda row: (
            float(row["ranking_estimate"]) if row["ranking_estimate"] != "" else -1e9,
            int(row["labeled_support"]),
            -int(row["byte_delta"]),
        ),
        reverse=True,
    )

    fit_rows = []
    for index, name in enumerate(fit_names):
        fit_rows.append(
            {
                "archive": name,
                "public_score": f"{labels[name].public_score:.6f}",
                "delta_from_reference": f"{y[index]:.6f}",
                "fitted_delta": f"{fitted[index]:.6f}",
                "residual": f"{fitted[index] - y[index]:.6f}",
                "changed_tasks": int(x[index].sum()),
                "evidence": labels[name].evidence,
            }
        )

    candidate_path = args.out_dir / "leaderboard_deconvolution_candidates.csv"
    pair_path = args.out_dir / "leaderboard_deconvolution_pairs.csv"
    fit_path = args.out_dir / "leaderboard_deconvolution_fit.csv"
    manifest_path = args.out_dir / "leaderboard_deconvolution_manifest.json"
    write_csv(candidate_path, candidate_rows, list(candidate_rows[0].keys()))
    write_csv(pair_path, pair_rows, list(pair_rows[0].keys()))
    write_csv(fit_path, fit_rows, list(fit_rows[0].keys()))

    manifest = {
        "reference": REFERENCE_NAME,
        "reference_score": REFERENCE_SCORE,
        "labeled_archive_count": len(LABELED_ARCHIVES),
        "fit_archive_count": len(fit_names),
        "feature_count": len(feature_keys),
        "ridge": ridge,
        "fit_rmse": fit_rmse,
        "leave_one_out_rmse": loo_rmse,
        "pair_constraints": len(pair_rows),
        "exact_single_task_constraints": sum(row["strength"] == "exact_single_task" for row in pair_rows),
        "candidate_variant_count": len(candidate_rows),
        "outputs": {
            "candidates": str(candidate_path),
            "pairs": str(pair_path),
            "fit": str(fit_path),
        },
        "warning": "Ridge attribution is underdetermined and ranks audits; only exact single-task constraints identify a variant effect directly.",
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest, indent=2))
    print("\nTop candidate variants:")
    for row in candidate_rows[:20]:
        print(
            f"{row['task']} {row['variant_hash']} estimate={row['ranking_estimate']} "
            f"support={row['labeled_support']} bytes={row['byte_delta']} sources={row['public_sources']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
