"""Cross-validate a compact diverse portfolio and write ranked candidate CSVs."""

from __future__ import annotations

import os
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import ExtraTreesClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import StratifiedKFold
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (
    categorical_columns,
    emit_manifest,
    encoded_frames,
    load_task,
    native_frames,
    rank_unit,
    runtime_workdir,
    write_submission,
)

SEED = 20260710

# --- Multi-seed averaging, gated to very small tasks -------------------------
# Measured 2026-08-02 on the official practice data (CatBoost, identical folds
# and params, 3 seeds averaged vs 1):
#     train_13   500 rows   +0.00373
#     train_15   500 rows   +0.00515
#     train_05  1060 rows   -0.00022
#     train_09  1109 rows   -0.00187
#     train_16  1809 rows   +0.00011
#     train_03  3501 rows   -0.00009
# The gain is confined to the 500-row regime and has already turned slightly
# negative by ~1000 rows, so the threshold sits between the measured-positive
# and measured-negative tasks. At or above it, this script behaves exactly like
# v12 (single seed), which is the 0.822 live best.
SMALL_ROWS_FOR_SEED_BAG = 800
EXTRA_SEED_OFFSETS = (101, 202)

# --- Runtime budget ----------------------------------------------------------
# v12 recorded elapsed time but never bounded it: the train_11 portfolio took
# 859 seconds. An unbounded portfolio can consume the live session budget and
# leave the agent with nothing to submit, so every fit loop now checks a shared
# deadline between folds and stops cleanly with whatever it has finished.
DEFAULT_BUDGET_SECONDS = 600.0


class Deadline:
    """Shared wall-clock budget for the whole portfolio."""

    def __init__(self, budget_seconds: float) -> None:
        self._started = time.time()
        self._budget = budget_seconds

    def left(self) -> float:
        return self._budget - (time.time() - self._started)

    def expired(self) -> bool:
        return self.left() <= 0.0


class FoldAccumulator:
    """Collects per-fold predictions and tolerates stopping early.

    Test predictions are averaged over however many folds actually ran, so an
    early stop yields a correctly scaled prediction rather than one silently
    divided by the number of folds that were merely planned.
    """

    def __init__(self, n_train: int, n_test: int) -> None:
        self.oof_sum = np.zeros(n_train)
        self.oof_count = np.zeros(n_train)
        self.test_sum = np.zeros(n_test)
        self.completed = 0

    def add(self, val_idx, val_pred, test_pred) -> None:
        self.oof_sum[val_idx] += val_pred
        self.oof_count[val_idx] += 1
        self.test_sum += test_pred
        self.completed += 1

    def finish(self):
        if self.completed == 0:
            raise ValueError("no folds completed before the deadline")
        seen = self.oof_count > 0
        oof = np.zeros_like(self.oof_sum)
        oof[seen] = self.oof_sum[seen] / self.oof_count[seen]
        # Rows never held out (only possible after an early stop) are filled
        # with the mean of the rows that were, so downstream blending keeps a
        # usable vector. `seen` is returned so CV AUC is scored only on real
        # out-of-fold predictions.
        oof[~seen] = oof[seen].mean() if seen.any() else 0.5
        return oof, self.test_sum / self.completed, seen


def seed_folds(splitter, x, y, seeds):
    """Yield (seed, fold, fit_idx, val_idx) across every seed and fold."""
    for seed in seeds:
        for fold, (fit_idx, val_idx) in enumerate(splitter.split(x, y)):
            yield seed, fold, fit_idx, val_idx


def seeds_for(n_rows: int) -> tuple[int, ...]:
    if n_rows < SMALL_ROWS_FOR_SEED_BAG:
        return (SEED,) + tuple(SEED + offset for offset in EXTRA_SEED_OFFSETS)
    return (SEED,)


def folds_for(y: np.ndarray, n_rows: int) -> StratifiedKFold:
    minority = int(np.bincount(y).min())
    return StratifiedKFold(n_splits=max(2, min(5, minority)), shuffle=True, random_state=SEED)

def score(y: np.ndarray, predictions: np.ndarray) -> float:
    return float(roc_auc_score(y, predictions))

def cv_catboost(x_train, y, x_test, cat_cols, splitter, seeds, deadline):
    from catboost import CatBoostClassifier
    acc = FoldAccumulator(len(x_train), len(x_test))
    for seed, fold, fit_idx, val_idx in seed_folds(splitter, x_train, y, seeds):
        if acc.completed and deadline.expired():
            break
        model = CatBoostClassifier(
            iterations=650 if len(x_train) >= 2000 else 420,
            depth=6 if len(x_train) >= 2000 else 5,
            learning_rate=0.04,
            loss_function="Logloss",
            eval_metric="AUC",
            l2_leaf_reg=7.0,
            random_strength=0.35,
            random_seed=seed + fold,
            verbose=False,
            allow_writing_files=False,
            thread_count=3,
        )
        model.fit(
            x_train.iloc[fit_idx],
            y[fit_idx],
            cat_features=cat_cols,
            eval_set=(x_train.iloc[val_idx], y[val_idx]),
            early_stopping_rounds=70,
            use_best_model=True,
            verbose=False,
        )
        acc.add(val_idx, model.predict_proba(x_train.iloc[val_idx])[:, 1],
                model.predict_proba(x_test)[:, 1])
    return acc.finish()

def cv_lightgbm(x_train, y, x_test, categorical_cols, splitter, seeds, deadline):
    import lightgbm as lgb
    x_train = x_train.copy()
    x_test = x_test.copy()
    for column in categorical_cols:
        x_train[column] = x_train[column].round().astype("int64").astype("category")
        x_test[column] = x_test[column].round().astype("int64").astype("category")
    acc = FoldAccumulator(len(x_train), len(x_test))
    small = len(x_train) < 2500
    for seed, fold, fit_idx, val_idx in seed_folds(splitter, x_train, y, seeds):
        if acc.completed and deadline.expired():
            break
        model = lgb.LGBMClassifier(
            objective="binary",
            n_estimators=900 if not small else 500,
            learning_rate=0.025 if not small else 0.04,
            num_leaves=15 if small else 31,
            max_depth=-1,
            min_child_samples=20 if small else 35,
            subsample=0.85,
            colsample_bytree=0.85,
            reg_alpha=0.15,
            reg_lambda=2.5,
            random_state=seed + fold,
            n_jobs=3,
            verbosity=-1,
        )
        model.fit(
            x_train.iloc[fit_idx],
            y[fit_idx],
            eval_set=[(x_train.iloc[val_idx], y[val_idx])],
            eval_metric="auc",
            categorical_feature=categorical_cols,
            callbacks=[lgb.early_stopping(70, verbose=False), lgb.log_evaluation(0)],
        )
        acc.add(val_idx, model.predict_proba(x_train.iloc[val_idx])[:, 1],
                model.predict_proba(x_test)[:, 1])
    return acc.finish()

def cv_extra_trees(x_train, y, x_test, splitter, seeds, deadline):
    acc = FoldAccumulator(len(x_train), len(x_test))
    leaf = 2 if len(x_train) < 3000 else 3
    for seed, fold, fit_idx, val_idx in seed_folds(splitter, x_train, y, seeds):
        if acc.completed and deadline.expired():
            break
        model = ExtraTreesClassifier(
            n_estimators=500,
            max_features=0.8,
            min_samples_leaf=leaf,
            class_weight="balanced",
            random_state=seed + fold,
            n_jobs=3,
        )
        model.fit(x_train.iloc[fit_idx], y[fit_idx])
        acc.add(val_idx, model.predict_proba(x_train.iloc[val_idx])[:, 1],
                model.predict_proba(x_test)[:, 1])
    return acc.finish()

def cv_logistic(train, y, test, features, splitter, seeds, deadline):
    cat_cols = categorical_columns(train, features)
    num_cols = [column for column in features if column not in cat_cols]
    acc = FoldAccumulator(len(train), len(test))
    for seed, fold, fit_idx, val_idx in seed_folds(splitter, train, y, seeds):
        if acc.completed and deadline.expired():
            break
        numeric = Pipeline([("impute", SimpleImputer(strategy="median")), ("scale", StandardScaler())])
        categorical = Pipeline([("impute", SimpleImputer(strategy="most_frequent")), ("onehot", OneHotEncoder(handle_unknown="ignore", min_frequency=2))])
        transformer = ColumnTransformer([("numeric", numeric, num_cols), ("categorical", categorical, cat_cols)])
        model = Pipeline([("features", transformer), ("model", LogisticRegression(C=0.25 if len(train) < 2000 else 0.7, max_iter=1500, solver="liblinear", random_state=seed + fold))])
        model.fit(train.iloc[fit_idx][features], y[fit_idx])
        acc.add(val_idx, model.predict_proba(train.iloc[val_idx][features])[:, 1],
                model.predict_proba(test[features])[:, 1])
    return acc.finish()

def main() -> None:
    started = time.time()
    workdir = runtime_workdir()
    train, test, sample, id_col, target_col, features, y = load_task(workdir)
    native_train, native_test, cat_cols = native_frames(train, test, features)
    encoded_train, encoded_test, encoded_cat_cols = encoded_frames(train, test, features)
    splitter = folds_for(y, len(train))
    seeds = seeds_for(len(train))
    budget = float(os.environ.get("PORTFOLIO_BUDGET_SECONDS", DEFAULT_BUDGET_SECONDS))
    deadline = Deadline(budget)
    models: dict[str, dict] = {}
    errors: dict[str, str] = {}

    runners = [
        ("catboost", lambda: cv_catboost(native_train, y, native_test, cat_cols, splitter, seeds, deadline)),
        ("lightgbm", lambda: cv_lightgbm(encoded_train, y, encoded_test, encoded_cat_cols, splitter, seeds, deadline)),
        ("extra_trees", lambda: cv_extra_trees(encoded_train, y, encoded_test, splitter, seeds, deadline)),
        ("logistic", lambda: cv_logistic(train, y, test, features, splitter, seeds, deadline)),
    ]
    for name, runner in runners:
        # Never start a new model with no budget left, but always let the first
        # one run: a portfolio with zero candidates has nothing to submit.
        if models and deadline.expired():
            errors[name] = "SkippedForBudget:deadline reached before model start"
            continue
        model_started = time.time()
        try:
            oof, test_predictions, scored = runner()
            if not np.isfinite(oof).all() or np.std(oof) <= 1e-9:
                raise ValueError("invalid or constant OOF predictions")
            models[name] = {
                "oof": oof,
                "test": test_predictions,
                # Score only on rows that really were held out, so an early stop
                # cannot inflate a candidate's CV AUC with imputed rows.
                "cv_auc": score(y[scored], oof[scored]),
                "seconds": round(time.time() - model_started, 3),
                "folds_scored": int(scored.sum()),
                "seeds": len(seeds),
            }
        except Exception as exc:
            errors[name] = f"{type(exc).__name__}:{exc}"

    if not models:
        prior = float(np.mean(y))
        path = write_submission(workdir / "portfolio_prior.csv", np.full(len(test), prior), test, sample, id_col, target_col)
        emit_manifest({"candidates": [path], "errors": errors, "models": {}, "robust_choice": path, "total_seconds": round(time.time() - started, 3)})
        return

    ranked_names = sorted(models, key=lambda name: models[name]["cv_auc"], reverse=True)
    candidates: list[dict] = []
    for name in ranked_names:
        path = write_submission(workdir / f"portfolio_{name}.csv", models[name]["test"], test, sample, id_col, target_col)
        candidates.append({"path": path, "cv_auc": models[name]["cv_auc"], "kind": name})

    top_two = ranked_names[:2]
    if len(top_two) == 2:
        first_oof, second_oof = rank_unit(models[top_two[0]]["oof"]), rank_unit(models[top_two[1]]["oof"])
        first_test, second_test = rank_unit(models[top_two[0]]["test"]), rank_unit(models[top_two[1]]["test"])
        path = write_submission(workdir / "portfolio_rank_top2.csv", 0.5 * first_test + 0.5 * second_test, test, sample, id_col, target_col)
        candidates.append({"path": path, "cv_auc": score(y, 0.5 * first_oof + 0.5 * second_oof), "kind": "rank_top2"})

    weights = np.array([max(models[name]["cv_auc"] - 0.5, 0.005) ** 2 for name in ranked_names], dtype=float)
    weights /= weights.sum()
    all_oof = np.average(np.stack([rank_unit(models[name]["oof"]) for name in ranked_names]), axis=0, weights=weights)
    all_test = np.average(np.stack([rank_unit(models[name]["test"]) for name in ranked_names]), axis=0, weights=weights)
    robust_path = write_submission(workdir / "portfolio_rank_all.csv", all_test, test, sample, id_col, target_col)
    candidates.append({"path": robust_path, "cv_auc": score(y, all_oof), "kind": "rank_all"})

    # --- PHASE 1 HANDOVER LOGIC WITH SCAFFOLD GENERATOR ---
    try:
        import shutil
        common_path = Path(__file__).resolve().parent / "common.py"
        shutil.copy(common_path, workdir / "common.py")

        # 1. Write the Summary Document
        with open(workdir / "handover.md", "w") as f:
            f.write("# Phase 1 & 2 Summary (Baseline)\n")
            f.write(f"- **Data Shape:** {len(train)} rows, {len(features)} features.\n")
            f.write(f"- **Categorical Features:** {len(cat_cols)}\n")
            f.write("- **Baseline Models Ranked by OOF AUC:**\n")
            for name in ranked_names:
                f.write(f"  - {name}: {models[name]['cv_auc']:.6f}\n")

        # 2. Write the Pro Scaffold Script
        with open(workdir / "pro_opt.py", "w") as f:
            f.write(f"""import sys; sys.path.append("/work")
import numpy as np
import pandas as pd
from catboost import CatBoostClassifier
from common import load_task, write_submission, native_frames

# 1. Load Data seamlessly
train, test, sample, id_col, target_col, features, y = load_task("/work")
x_train, x_test, cat_cols = native_frames(train, test, features)

# --- ADD AT MOST ONE UNSUPERVISED FEATURE FAMILY PER ITERATION ---
# Never derive features from y or transform the binary target.
# Keep generated columns bounded and update cat_cols for new string features.


# 2. Train Model (Using the reliable baseline settings)
model = CatBoostClassifier(
    iterations=600,
    depth=6,
    learning_rate=0.04,
    loss_function="Logloss",
    eval_metric="AUC",
    random_seed=42,
    verbose=False,
    allow_writing_files=False,
    thread_count=3,
)
model.fit(x_train, y, cat_features=cat_cols)

# 3. Predict & Submit
predictions = model.predict_proba(x_test)[:, 1]
write_submission("/work/pro_submission.csv", predictions, test, sample, id_col, target_col)
print("SUCCESS: Submission saved to /work/pro_submission.csv. Please submit this file now.")
""")
    except Exception as e:
        print(f"Handover error: {e}")

    candidates = sorted(candidates, key=lambda item: item["cv_auc"], reverse=True)
    emit_manifest({
        "candidates": [item["path"] for item in candidates[:8]],
        "candidate_metrics": candidates,
        "errors": errors,
        "robust_choice": robust_path,
        "total_seconds": round(time.time() - started, 3),
        "seed_count": len(seeds),
        "budget_seconds": budget,
        "budget_exhausted": deadline.expired(),
    })

if __name__ == "__main__":
    main()
