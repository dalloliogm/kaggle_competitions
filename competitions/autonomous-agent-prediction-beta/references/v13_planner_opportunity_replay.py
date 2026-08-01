#!/usr/bin/env python3
"""Measure whether target-blind feature-family selection has an oracle ceiling."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import StratifiedKFold

PACKAGE_SCRIPTS = Path(__file__).resolve().parents[1] / "submissions" / "agent-configs" / "official-demo-v13-profile-planner" / "skills" / "robust-tabular" / "scripts"
sys.path.insert(0, str(PACKAGE_SCRIPTS))
from common import encoded_frames, load_task
from feature_planner import apply_plan, build_profile, validate_plan

SEED = 20260801


def automatic_plans(profile: dict, features: list[str]) -> list[dict]:
    columns = profile["columns"]
    numeric = [column for column in features if columns[column]["kind"] == "numeric"]
    categorical = [column for column in features if columns[column]["kind"] == "categorical"]
    plans: list[dict] = []
    if categorical:
        plans.append({"model": "extra_trees", "family": {"name": "frequency", "columns": categorical}, "rationale": "categorical frequencies"})
    skewed = [column for column in numeric if abs(columns[column].get("skew") or 0) >= 1]
    if skewed:
        plans.append({"model": "extra_trees", "family": {"name": "signed_log", "columns": skewed[:12]}, "rationale": "absolute skew >= 1"})
    if any(columns[column].get("missing_fraction", 0) > 0 for column in features):
        plans.append({"model": "extra_trees", "family": {"name": "missingness"}, "rationale": "observed missing values"})
    if len(numeric) >= 3:
        plans.append({"model": "extra_trees", "family": {"name": "row_stats"}, "rationale": "at least three numeric predictors"})
    if numeric:
        polynomial_columns = sorted(numeric, key=lambda column: abs(columns[column].get("skew") or 0), reverse=True)[:6]
        plans.append({"model": "extra_trees", "family": {"name": "polynomial", "columns": polynomial_columns}, "rationale": "bounded squares of most asymmetric numeric predictors"})
    pairs = [
        [item["left"], item["right"]]
        for item in profile["top_absolute_predictor_correlations"]
        if 0.15 <= item["absolute_spearman"] < 0.995
    ][:6]
    if pairs:
        plans.append({"model": "extra_trees", "family": {"name": "interactions", "pairs": pairs, "operations": ["product", "difference", "ratio"]}, "rationale": "bounded interactions among correlated predictors"})
    return plans


def heuristic_family(profile: dict, available: list[str]) -> str:
    columns = profile["columns"]
    missing = max((item.get("missing_fraction", 0) for item in columns.values()), default=0)
    max_skew = max((abs(item.get("skew") or 0) for item in columns.values() if item["kind"] == "numeric"), default=0)
    if max_skew >= 2 and "signed_log" in available:
        return "signed_log"
    if missing >= 0.1 and "missingness" in available:
        return "missingness"
    if profile["task"]["categorical_features"] and "frequency" in available:
        return "frequency"
    if profile["task"]["numeric_features"] >= 8 and "row_stats" in available:
        return "row_stats"
    if "interactions" in available:
        return "interactions"
    return available[0] if available else "baseline"


def cv_hgb(train: pd.DataFrame, test: pd.DataFrame, features: list[str], y: np.ndarray):
    x_train, x_test, _ = encoded_frames(train, test, features)
    splitter = StratifiedKFold(n_splits=3, shuffle=True, random_state=SEED)
    oof = np.zeros(len(train), dtype=float)
    test_predictions = np.zeros(len(test), dtype=float)
    fold_auc: list[float] = []
    for fold, (fit_index, valid_index) in enumerate(splitter.split(x_train, y)):
        model = HistGradientBoostingClassifier(
            learning_rate=0.055,
            max_iter=160,
            max_leaf_nodes=31,
            l2_regularization=2.0,
            early_stopping=True,
            random_state=SEED + fold,
        )
        model.fit(x_train.iloc[fit_index], y[fit_index])
        oof[valid_index] = model.predict_proba(x_train.iloc[valid_index])[:, 1]
        test_predictions += model.predict_proba(x_test)[:, 1] / splitter.n_splits
        fold_auc.append(float(roc_auc_score(y[valid_index], oof[valid_index])))
    return oof, test_predictions, fold_auc


def score_solution(task: str, prediction: np.ndarray, test: pd.DataFrame, sample: pd.DataFrame, solution_root: Path) -> float:
    solution = pd.read_csv(solution_root / task / "solution.csv")
    id_col, target_col = sample.columns[:2]
    predicted = pd.DataFrame({id_col: test[id_col], "__prediction": prediction})
    joined = solution[[id_col, target_col]].merge(predicted, on=id_col, validate="one_to_one")
    if len(joined) != len(solution):
        raise ValueError(f"{task}: solution/prediction ID mismatch")
    return float(roc_auc_score(joined[target_col], joined["__prediction"]))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-root", default="/private/tmp/aap-v12-replay-20260731")
    parser.add_argument("--solution-root", default="/private/tmp/aap-v13-solutions")
    parser.add_argument("--output", required=True)
    parser.add_argument("--task", action="append", help="Optional task folder, repeatable")
    arguments = parser.parse_args()
    data_root = Path(arguments.data_root)
    solution_root = Path(arguments.solution_root)
    task_dirs = [data_root / task for task in arguments.task] if arguments.task else sorted(data_root.glob("train_*"))
    rows: list[dict] = []
    for task_dir in task_dirs:
        started = time.time()
        train, test, sample, _, _, features, y = load_task(task_dir)
        profile = build_profile(train, test, features)
        baseline_oof, baseline_test, baseline_folds = cv_hgb(train, test, features, y)
        baseline_test_auc = score_solution(task_dir.name, baseline_test, test, sample, solution_root)
        rows.append({
            "task": task_dir.name,
            "family": "baseline",
            "oof_auc": roc_auc_score(y, baseline_oof),
            "test_auc": baseline_test_auc,
            "oof_gain": 0.0,
            "test_gain": 0.0,
            "fold_wins": 0,
            "min_fold_delta": 0.0,
            "generated_features": 0,
            "profile_heuristic": False,
            "seconds": time.time() - started,
        })
        plans = automatic_plans(profile, features)
        heuristic = heuristic_family(profile, [plan["family"]["name"] for plan in plans])
        for raw_plan in plans:
            plan_started = time.time()
            plan = validate_plan(raw_plan, features, train)
            planned_train, planned_test, planned_features, generated = apply_plan(train, test, features, plan)
            candidate_oof, candidate_test, candidate_folds = cv_hgb(planned_train, planned_test, planned_features, y)
            candidate_oof_auc = float(roc_auc_score(y, candidate_oof))
            candidate_test_auc = score_solution(task_dir.name, candidate_test, test, sample, solution_root)
            fold_deltas = np.asarray(candidate_folds) - np.asarray(baseline_folds)
            rows.append({
                "task": task_dir.name,
                "family": plan["family"]["name"],
                "oof_auc": candidate_oof_auc,
                "test_auc": candidate_test_auc,
                "oof_gain": candidate_oof_auc - float(roc_auc_score(y, baseline_oof)),
                "test_gain": candidate_test_auc - baseline_test_auc,
                "fold_wins": int((fold_deltas > 0).sum()),
                "min_fold_delta": float(fold_deltas.min()),
                "generated_features": len(generated),
                "profile_heuristic": plan["family"]["name"] == heuristic,
                "seconds": time.time() - plan_started,
            })
        print(json.dumps({"task": task_dir.name, "families": len(plans), "seconds": round(time.time() - started, 2)}), flush=True)
    output = Path(arguments.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(rows).to_csv(output, index=False)
    print(str(output.resolve()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
