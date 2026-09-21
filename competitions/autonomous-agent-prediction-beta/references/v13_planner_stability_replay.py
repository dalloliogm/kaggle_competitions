#!/usr/bin/env python3
"""Multi-seed, multi-model stability screen for the v13 feature planner."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import ExtraTreesClassifier, HistGradientBoostingClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import StratifiedKFold
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

PACKAGE_SCRIPTS = Path(__file__).resolve().parents[1] / "submissions" / "agent-configs" / "official-demo-v13-profile-planner" / "skills" / "robust-tabular" / "scripts"
sys.path.insert(0, str(PACKAGE_SCRIPTS))
from common import categorical_columns, encoded_frames, load_task
from feature_planner import apply_plan, build_profile, validate_plan
from v13_planner_opportunity_replay import automatic_plans, score_solution

DEFAULT_SEEDS = (20260801, 20260811, 20260821)
DEFAULT_MODELS = ("hgb", "extra_trees", "logistic")


def cv_predict(
    model_name: str,
    seed: int,
    train: pd.DataFrame,
    test: pd.DataFrame,
    features: list[str],
    y: np.ndarray,
) -> tuple[np.ndarray, np.ndarray, list[float]]:
    splitter = StratifiedKFold(n_splits=3, shuffle=True, random_state=seed)
    oof = np.zeros(len(train), dtype=float)
    test_predictions = np.zeros(len(test), dtype=float)
    fold_auc: list[float] = []

    if model_name in {"hgb", "extra_trees"}:
        x_train, x_test, _ = encoded_frames(train, test, features)
    elif model_name == "logistic":
        x_train, x_test = train[features], test[features]
        cat_cols = categorical_columns(train, features)
        num_cols = [column for column in features if column not in cat_cols]
    else:
        raise ValueError(f"unknown model {model_name}")

    for fold, (fit_index, valid_index) in enumerate(splitter.split(train, y)):
        if model_name == "hgb":
            model = HistGradientBoostingClassifier(
                learning_rate=0.055,
                max_iter=160,
                max_leaf_nodes=31,
                l2_regularization=2.0,
                early_stopping=True,
                random_state=seed + fold,
            )
        elif model_name == "extra_trees":
            model = ExtraTreesClassifier(
                n_estimators=300,
                max_features=0.8,
                min_samples_leaf=2 if len(train) < 3000 else 3,
                class_weight="balanced",
                random_state=seed + fold,
                n_jobs=3,
            )
        else:
            numeric = Pipeline([
                ("impute", SimpleImputer(strategy="median")),
                ("scale", StandardScaler()),
            ])
            categorical = Pipeline([
                ("impute", SimpleImputer(strategy="most_frequent")),
                ("onehot", OneHotEncoder(handle_unknown="ignore", min_frequency=2)),
            ])
            transformer = ColumnTransformer([
                ("numeric", numeric, num_cols),
                ("categorical", categorical, cat_cols),
            ])
            model = Pipeline([
                ("features", transformer),
                ("model", LogisticRegression(
                    C=0.25 if len(train) < 2000 else 0.7,
                    max_iter=1500,
                    solver="liblinear",
                    random_state=seed + fold,
                )),
            ])

        model.fit(x_train.iloc[fit_index], y[fit_index])
        fold_predictions = model.predict_proba(x_train.iloc[valid_index])[:, 1]
        oof[valid_index] = fold_predictions
        test_predictions += model.predict_proba(x_test)[:, 1] / splitter.n_splits
        fold_auc.append(float(roc_auc_score(y[valid_index], fold_predictions)))

    return oof, test_predictions, fold_auc


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-root", default="/private/tmp/aap-v12-replay-20260731")
    parser.add_argument("--solution-root", default="/private/tmp/aap-v13-solutions")
    parser.add_argument("--output", required=True)
    parser.add_argument("--task", action="append", help="Optional task folder, repeatable")
    parser.add_argument("--seed", action="append", type=int)
    parser.add_argument("--model", action="append", choices=DEFAULT_MODELS)
    arguments = parser.parse_args()

    seeds = tuple(arguments.seed or DEFAULT_SEEDS)
    models = tuple(arguments.model or DEFAULT_MODELS)
    data_root = Path(arguments.data_root)
    solution_root = Path(arguments.solution_root)
    task_dirs = [data_root / task for task in arguments.task] if arguments.task else sorted(data_root.glob("train_*"))
    rows: list[dict] = []

    for task_dir in task_dirs:
        task_started = time.time()
        train, test, sample, _, _, features, y = load_task(task_dir)
        profile = build_profile(train, test, features)
        raw_plans = automatic_plans(profile, features)
        variants: list[tuple[str, pd.DataFrame, pd.DataFrame, list[str], int]] = [
            ("baseline", train, test, features, 0)
        ]
        for raw_plan in raw_plans:
            plan = validate_plan(raw_plan, features, train)
            planned_train, planned_test, planned_features, generated = apply_plan(
                train, test, features, plan
            )
            variants.append((
                plan["family"]["name"],
                planned_train,
                planned_test,
                planned_features,
                len(generated),
            ))

        for model_name in models:
            for seed in seeds:
                model_started = time.time()
                baseline_oof, baseline_test, baseline_folds = cv_predict(
                    model_name, seed, train, test, features, y
                )
                baseline_oof_auc = float(roc_auc_score(y, baseline_oof))
                baseline_test_auc = score_solution(
                    task_dir.name, baseline_test, test, sample, solution_root
                )
                rows.append({
                    "task": task_dir.name,
                    "model": model_name,
                    "seed": seed,
                    "family": "baseline",
                    "oof_auc": baseline_oof_auc,
                    "test_auc": baseline_test_auc,
                    "oof_gain": 0.0,
                    "test_gain": 0.0,
                    "fold_wins": 0,
                    "min_fold_delta": 0.0,
                    "generated_features": 0,
                    "seconds": time.time() - model_started,
                })

                for family, planned_train, planned_test, planned_features, generated_count in variants[1:]:
                    variant_started = time.time()
                    candidate_oof, candidate_test, candidate_folds = cv_predict(
                        model_name,
                        seed,
                        planned_train,
                        planned_test,
                        planned_features,
                        y,
                    )
                    candidate_oof_auc = float(roc_auc_score(y, candidate_oof))
                    candidate_test_auc = score_solution(
                        task_dir.name, candidate_test, test, sample, solution_root
                    )
                    fold_deltas = np.asarray(candidate_folds) - np.asarray(baseline_folds)
                    rows.append({
                        "task": task_dir.name,
                        "model": model_name,
                        "seed": seed,
                        "family": family,
                        "oof_auc": candidate_oof_auc,
                        "test_auc": candidate_test_auc,
                        "oof_gain": candidate_oof_auc - baseline_oof_auc,
                        "test_gain": candidate_test_auc - baseline_test_auc,
                        "fold_wins": int((fold_deltas > 0).sum()),
                        "min_fold_delta": float(fold_deltas.min()),
                        "generated_features": generated_count,
                        "seconds": time.time() - variant_started,
                    })
        print(json.dumps({
            "task": task_dir.name,
            "variants": len(variants),
            "models": len(models),
            "seeds": len(seeds),
            "seconds": round(time.time() - task_started, 2),
        }), flush=True)

    output = Path(arguments.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    frame = pd.DataFrame(rows).sort_values(["task", "model", "seed", "family"])
    frame.to_csv(output, index=False)
    print(str(output.resolve()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
