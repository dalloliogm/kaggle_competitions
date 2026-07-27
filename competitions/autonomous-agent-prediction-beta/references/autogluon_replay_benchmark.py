"""Bounded local replay for AutoGluon on the 16 official practice tasks.

This script is for offline evaluation only. It never exposes solution.csv to
AutoGluon: solutions are loaded only after predictions have been generated.
"""

from __future__ import annotations

import argparse
import json
import tempfile
import time
from pathlib import Path

import pandas as pd
from autogluon.tabular import TabularPredictor
from sklearn.metrics import roc_auc_score


DEFAULT_DATA_ROOT = Path("/tmp/autonomous-agent-replay/extracted/data")
DEFAULT_OUTPUT = Path(__file__).with_name("autogluon-classical-replay.csv")


def infer_schema(train: pd.DataFrame, test: pd.DataFrame, sample: pd.DataFrame):
    target_candidates = [column for column in train if column not in test]
    if len(target_candidates) != 1:
        raise ValueError(f"Expected one target column, found {target_candidates}")
    target = target_candidates[0]
    id_columns = [
        column
        for column in sample
        if column in test and column != target
    ]
    features = [column for column in test if column not in id_columns]
    return target, id_columns, features


def predict_positive_class(predictor: TabularPredictor, test: pd.DataFrame):
    probabilities = predictor.predict_proba(test, as_multiclass=True)
    positive_label = predictor.positive_class
    return probabilities[positive_label].to_numpy(dtype=float)


def run_task(
    task_dir: Path,
    time_limit: int,
    run_root: Path,
    model: str,
    test_sample: int | None,
):
    train = pd.read_csv(task_dir / "train.csv")
    test = pd.read_csv(task_dir / "test.csv")
    sample = pd.read_csv(task_dir / "sample_submission.csv")
    target, id_columns, features = infer_schema(train, test, sample)

    model_path = run_root / task_dir.name
    started = time.monotonic()
    if model == "classical":
        hyperparameters = {
            "GBM": {},
            "CAT": {},
            "XGB": {},
            "RF": {},
            "XT": {},
            "LR": {},
        }
    elif model == "mitra":
        hyperparameters = {"MITRA": {"fine_tune": False}}
    else:
        raise ValueError(f"Unknown model family: {model}")

    predictor = TabularPredictor(
        label=target,
        problem_type="binary",
        eval_metric="roc_auc",
        path=model_path,
        verbosity=0,
    ).fit(
        train_data=train[features + [target]],
        time_limit=time_limit,
        presets="medium_quality",
        hyperparameters=hyperparameters,
        fit_weighted_ensemble=model == "classical",
        num_cpus=3,
        num_gpus=0,
        ag_args_fit=(
            {"ag.max_memory_usage_ratio": 1.6}
            if model == "mitra"
            else None
        ),
    )
    if test_sample and test_sample < len(test):
        sampled_index = (
            test.sample(n=test_sample, random_state=20260727).index.sort_values()
        )
    else:
        sampled_index = test.index
    prediction = predict_positive_class(
        predictor,
        test.loc[sampled_index, features],
    )
    elapsed = time.monotonic() - started

    # The held-out solution is loaded only after model fitting and prediction.
    solution = pd.read_csv(task_dir / "solution.csv")
    score = roc_auc_score(solution.loc[sampled_index, target], prediction)
    leaderboard = predictor.leaderboard(silent=True)
    return {
        "task": task_dir.name,
        "rows": len(train),
        "features": len(features),
        "test_rows_scored": len(sampled_index),
        "id_columns": ",".join(id_columns),
        "auc": score,
        "seconds": elapsed,
        "best_model": predictor.model_best,
        "models_fit": len(leaderboard),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-root", type=Path, default=DEFAULT_DATA_ROOT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--time-limit", type=int, default=45)
    parser.add_argument("--tasks", nargs="*", default=None)
    parser.add_argument(
        "--model",
        choices=["classical", "mitra"],
        default="classical",
    )
    parser.add_argument(
        "--test-sample",
        type=int,
        default=None,
        help="Score a deterministic test-row sample; useful for slow TFMs.",
    )
    args = parser.parse_args()

    task_dirs = sorted(args.data_root.glob("train_*"))
    if args.tasks:
        selected = set(args.tasks)
        task_dirs = [path for path in task_dirs if path.name in selected]
    if not task_dirs:
        raise SystemExit(f"No tasks found under {args.data_root}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="autogluon-replay-") as temp_dir:
        run_root = Path(temp_dir)
        results = []
        for task_dir in task_dirs:
            try:
                result = run_task(
                    task_dir,
                    args.time_limit,
                    run_root,
                    args.model,
                    args.test_sample,
                )
            except Exception as error:  # Keep the replay ledger complete.
                result = {
                    "task": task_dir.name,
                    "rows": None,
                    "features": None,
                    "id_columns": None,
                    "auc": None,
                    "seconds": None,
                    "best_model": None,
                    "models_fit": 0,
                    "error": f"{type(error).__name__}: {error}",
                }
            results.append(result)
            pd.DataFrame(results).to_csv(args.output, index=False)
            print(json.dumps(result, default=str), flush=True)

    frame = pd.DataFrame(results)
    scored = frame.dropna(subset=["auc"])
    summary = {
        "tasks_requested": len(task_dirs),
        "tasks_scored": len(scored),
        "model": args.model,
        "mean_auc": scored["auc"].mean(),
        "median_auc": scored["auc"].median(),
        "mean_seconds": scored["seconds"].mean(),
        "output": str(args.output),
    }
    print("SUMMARY " + json.dumps(summary, default=str), flush=True)


if __name__ == "__main__":
    main()
