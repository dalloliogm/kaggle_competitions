"""Execute one allowlisted JSON plan and gate its actual final candidate."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np
from sklearn.metrics import roc_auc_score

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import encoded_frames, load_task, native_frames, runtime_workdir, write_submission
from feature_planner import apply_plan, validate_plan
from run_portfolio import (
    cv_catboost,
    cv_extra_trees,
    cv_lightgbm,
    cv_logistic,
    folds_for,
)

MIN_MEAN_GAIN = 0.0015
MAX_FOLD_REGRESSION = 0.002


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", default="/work/plan.json")
    parser.add_argument("--output", default="/work/planner_submission.csv")
    arguments = parser.parse_args()

    workdir = runtime_workdir()
    train, test, sample, id_col, target_col, features, y = load_task(workdir)
    raw_plan = json.loads(Path(arguments.plan).read_text(encoding="utf-8"))
    plan = validate_plan(raw_plan, features, train)
    planned_train, planned_test, planned_features, generated = apply_plan(
        train, test, features, plan
    )
    if not generated:
        raise ValueError("validated plan generated no features")

    splitter = folds_for(y, len(train))
    model = plan["model"]
    if model == "catboost":
        x_train, x_test, cat_cols = native_frames(planned_train, planned_test, planned_features)
        candidate_oof, candidate_test = cv_catboost(x_train, y, x_test, cat_cols, splitter)
    elif model == "lightgbm":
        x_train, x_test, cat_cols = encoded_frames(planned_train, planned_test, planned_features)
        candidate_oof, candidate_test = cv_lightgbm(x_train, y, x_test, cat_cols, splitter)
    elif model == "extra_trees":
        x_train, x_test, _ = encoded_frames(planned_train, planned_test, planned_features)
        candidate_oof, candidate_test = cv_extra_trees(x_train, y, x_test, splitter)
    else:
        candidate_oof, candidate_test = cv_logistic(
            planned_train, y, planned_test, planned_features, splitter
        )

    metadata = json.loads((workdir / "planner_baseline.json").read_text(encoding="utf-8"))
    arrays = np.load(workdir / "planner_baseline.npz")
    best_kind = metadata["best_kind"]
    baseline_oof = arrays[f"{best_kind}__oof"]
    baseline_auc = float(roc_auc_score(y, baseline_oof))
    candidate_auc = float(roc_auc_score(y, candidate_oof))
    fold_deltas: list[float] = []
    for _, valid_index in splitter.split(train, y):
        baseline_fold = float(roc_auc_score(y[valid_index], baseline_oof[valid_index]))
        candidate_fold = float(roc_auc_score(y[valid_index], candidate_oof[valid_index]))
        fold_deltas.append(candidate_fold - baseline_fold)

    required_wins = max(1, math.ceil(0.8 * splitter.n_splits))
    wins = sum(delta > 0 for delta in fold_deltas)
    mean_gain = candidate_auc - baseline_auc
    accepted = (
        mean_gain >= MIN_MEAN_GAIN
        and wins >= required_wins
        and min(fold_deltas) >= -MAX_FOLD_REGRESSION
    )
    output_path = None
    if accepted:
        output_path = write_submission(
            arguments.output,
            candidate_test,
            test,
            sample,
            id_col,
            target_col,
        )

    result = {
        "accepted": accepted,
        "baseline_kind": best_kind,
        "baseline_oof_auc": baseline_auc,
        "candidate_oof_auc": candidate_auc,
        "mean_gain": mean_gain,
        "fold_deltas": fold_deltas,
        "fold_wins": wins,
        "required_fold_wins": required_wins,
        "generated_features": generated,
        "output_path": output_path,
        "validated_plan": plan,
    }
    result_path = workdir / "planner_result.json"
    result_path.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
    print("PLANNER_RESULT=" + json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
