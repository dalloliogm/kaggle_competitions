#!/usr/bin/env python3
"""Fallback-safe schema-agnostic tabular binary classifier.

The script is intentionally dependency-light. It uses sklearn when available and
falls back to a small NumPy logistic model if needed. It never opens files whose
names look like solution or ground-truth files.
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd


BAD_NAME_PARTS = ("solution", "answer", "truth", "ground")
MAX_TRAIN_ROWS = 120_000
MAX_CATEGORY_LEVELS = 80
TIME_BUDGET_SECONDS = 210


def is_bad_path(path: Path) -> bool:
    return any(part in path.name.lower() for part in BAD_NAME_PARTS)


def discover_files(task_dir: Path) -> tuple[Path, Path, Path | None]:
    csvs = [p for p in task_dir.rglob("*.csv") if not is_bad_path(p)]
    if not csvs:
        raise FileNotFoundError(f"no safe CSV files found under {task_dir}")

    def pick(names: tuple[str, ...], exclude: tuple[str, ...] = ()) -> Path | None:
        for path in sorted(csvs, key=lambda p: (len(str(p)), str(p))):
            name = path.name.lower()
            if any(token in name for token in names) and not any(token in name for token in exclude):
                return path
        return None

    train = pick(("train",), ("sample", "submission"))
    test = pick(("test",), ("sample", "submission"))
    sample = pick(("sample_submission", "samplesubmission", "sample-submission", "sample_sub"))

    if train is None or test is None:
        remaining = [
            p
            for p in csvs
            if p not in (train, test, sample)
            and not any(token in p.name.lower() for token in ("sample", "submission"))
        ]
        remaining.sort(key=lambda p: p.stat().st_size, reverse=True)
        if train is None and remaining:
            train = remaining.pop(0)
        if test is None and remaining:
            test = remaining.pop(0)

    if train is None or test is None:
        raise FileNotFoundError(f"could not infer train/test CSVs from {[str(p) for p in csvs[:20]]}")
    return train, test, sample


def infer_id_column(train: pd.DataFrame, test: pd.DataFrame, sample: pd.DataFrame | None) -> str | None:
    if sample is not None and len(sample.columns) >= 1 and sample.columns[0] in test.columns:
        return str(sample.columns[0])
    preferred = {"row_id", "id", "sample_id", "uid", "index"}
    for col in test.columns:
        lower = str(col).lower()
        if lower in preferred or lower.endswith("_id"):
            return str(col)
    for col in test.columns:
        if col in train.columns and test[col].is_unique and train[col].is_unique:
            return str(col)
    return None


def read_target_hint(train_path: Path) -> str | None:
    for candidate in (train_path.parent / "target_col.txt", train_path.parent.parent / "target_col.txt"):
        if candidate.is_file() and not is_bad_path(candidate):
            text = candidate.read_text(encoding="utf-8").strip()
            if text:
                return text
    return None


def infer_target_column(
    train: pd.DataFrame,
    test: pd.DataFrame,
    sample: pd.DataFrame | None,
    id_col: str | None,
    hint: str | None,
) -> str:
    if hint and hint in train.columns:
        return hint
    likely = {"target", "label", "class", "y", "outcome"}
    train_only = [c for c in train.columns if c not in test.columns and c != id_col]
    for col in train_only:
        if str(col).lower() in likely:
            return str(col)
    if len(train_only) == 1:
        return str(train_only[0])
    if sample is not None and len(sample.columns) >= 2:
        for col in sample.columns[1:]:
            if col in train.columns:
                return str(col)
    binary = [c for c in train_only if train[c].nunique(dropna=True) == 2]
    if binary:
        return str(binary[0])
    raise ValueError("could not infer target column")


def normalize_binary_target(y: pd.Series) -> pd.Series:
    if pd.api.types.is_numeric_dtype(y):
        values = set(pd.unique(y.dropna()))
        if values <= {0, 1}:
            return y.astype(int)
    uniques = list(pd.unique(y.dropna()))
    if len(uniques) != 2:
        return y
    try:
        positive = max(uniques)
    except TypeError:
        positive = sorted(uniques, key=str)[-1]
    return (y == positive).astype(int)


def build_design(train: pd.DataFrame, test: pd.DataFrame, feature_cols: list[str]) -> tuple[pd.DataFrame, pd.DataFrame]:
    train_x = pd.DataFrame(index=train.index)
    test_x = pd.DataFrame(index=test.index)

    numeric_cols = train[feature_cols].select_dtypes(include=[np.number]).columns.tolist()
    categorical_cols = [c for c in feature_cols if c not in numeric_cols]

    for col in numeric_cols:
        median = train[col].median()
        if pd.isna(median):
            median = 0.0
        train_x[col] = train[col].fillna(median).astype(float)
        test_x[col] = test[col].fillna(median).astype(float)

    if numeric_cols:
        train_x["_row_mean"] = train_x[numeric_cols].mean(axis=1)
        test_x["_row_mean"] = test_x[numeric_cols].mean(axis=1)
        train_x["_row_std"] = train_x[numeric_cols].std(axis=1).fillna(0)
        test_x["_row_std"] = test_x[numeric_cols].std(axis=1).fillna(0)
        train_x["_row_null_count"] = train[numeric_cols].isna().sum(axis=1)
        test_x["_row_null_count"] = test[numeric_cols].isna().sum(axis=1)

    for col in categorical_cols:
        train_s = train[col].fillna("__missing__").astype(str)
        test_s = test[col].fillna("__missing__").astype(str)
        freq = train_s.value_counts(normalize=True)
        train_x[f"{col}_freq"] = train_s.map(freq).fillna(0).astype(float)
        test_x[f"{col}_freq"] = test_s.map(freq).fillna(0).astype(float)

        top = freq.head(MAX_CATEGORY_LEVELS).index.tolist()
        for level in top:
            safe = str(level).replace(" ", "_")[:40]
            train_x[f"{col}__{safe}"] = (train_s == level).astype(float)
            test_x[f"{col}__{safe}"] = (test_s == level).astype(float)

    train_x = train_x.replace([np.inf, -np.inf], np.nan).fillna(0.0)
    test_x = test_x.reindex(columns=train_x.columns, fill_value=0.0).replace([np.inf, -np.inf], np.nan).fillna(0.0)
    return train_x, test_x


def standardize(train_x: pd.DataFrame, test_x: pd.DataFrame) -> tuple[np.ndarray, np.ndarray]:
    means = train_x.mean(axis=0)
    stds = train_x.std(axis=0).replace(0, 1).fillna(1)
    return ((train_x - means) / stds).to_numpy(float), ((test_x - means) / stds).to_numpy(float)


def logistic_fallback(train_x: np.ndarray, y: np.ndarray, test_x: np.ndarray) -> np.ndarray:
    x = np.c_[np.ones(len(train_x)), train_x]
    xt = np.c_[np.ones(len(test_x)), test_x]
    w = np.zeros(x.shape[1], dtype=float)
    lr = 0.05
    l2 = 0.02
    steps = 650
    for _ in range(steps):
        logits = np.clip(x @ w, -30, 30)
        p = 1 / (1 + np.exp(-logits))
        grad = (x.T @ (p - y)) / len(y)
        grad[1:] += l2 * w[1:]
        w -= lr * grad
    return 1 / (1 + np.exp(-np.clip(xt @ w, -30, 30)))


def fit_predict(train_x: pd.DataFrame, y: pd.Series, test_x: pd.DataFrame) -> np.ndarray:
    y_arr = y.astype(int).to_numpy()
    try:
        from sklearn.ensemble import HistGradientBoostingClassifier, RandomForestClassifier
        from sklearn.linear_model import LogisticRegression
        from sklearn.model_selection import StratifiedKFold
        from sklearn.metrics import roc_auc_score

        x_np, test_np = standardize(train_x, test_x)
        min_class = int(pd.Series(y_arr).value_counts().min())
        n_splits = max(2, min(5, min_class))
        candidates = [
            ("hgb", HistGradientBoostingClassifier(max_iter=180, learning_rate=0.055, l2_regularization=0.03, random_state=1)),
            ("rf", RandomForestClassifier(n_estimators=220, min_samples_leaf=3, random_state=2, n_jobs=-1)),
            ("logreg", LogisticRegression(max_iter=1500, C=0.7, solver="lbfgs")),
        ]
        scores: list[tuple[float, str, object]] = []
        if len(y_arr) >= 80 and min_class >= 2:
            cv = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=3)
            for name, model in candidates:
                oof = np.zeros(len(y_arr), dtype=float)
                for tr_idx, va_idx in cv.split(x_np, y_arr):
                    model.fit(x_np[tr_idx], y_arr[tr_idx])
                    oof[va_idx] = model.predict_proba(x_np[va_idx])[:, 1]
                score = float(roc_auc_score(y_arr, oof))
                print(f"cv_auc {name} {score:.5f}", flush=True)
                scores.append((score, name, model))
            scores.sort(reverse=True, key=lambda item: item[0])
            best_name = scores[0][1]
        else:
            best_name = "hgb"
        best = {name: model for name, model in candidates}[best_name]
        best.fit(x_np, y_arr)
        print(f"selected_model {best_name}", flush=True)
        return best.predict_proba(test_np)[:, 1]
    except Exception as exc:
        print(f"sklearn path failed: {type(exc).__name__}: {exc}; using numpy logistic fallback", flush=True)
        x_np, test_np = standardize(train_x, test_x)
        return logistic_fallback(x_np, y_arr, test_np)


def write_prior_submission(task_dir: Path, out_path: Path, error: Exception | None = None) -> None:
    if error is not None:
        print(f"fallback after {type(error).__name__}: {error}", flush=True)
    train_path, test_path, sample_path = discover_files(task_dir)
    train = pd.read_csv(train_path)
    test = pd.read_csv(test_path)
    sample = pd.read_csv(sample_path) if sample_path is not None else None
    id_col = infer_id_column(train, test, sample)
    target_col = infer_target_column(train, test, sample, id_col, read_target_hint(train_path))
    y = normalize_binary_target(train[target_col])
    prior = float(np.clip(pd.Series(y).mean(), 1e-6, 1 - 1e-6))
    if sample is not None:
        out = sample.copy()
        out[out.columns[-1]] = prior
    else:
        ids = test[id_col] if id_col and id_col in test.columns else np.arange(len(test))
        out = pd.DataFrame({id_col or "row_id": ids, target_col: prior})
    out.to_csv(out_path, index=False)
    print(f"wrote prior fallback {prior:.6f} -> {out_path}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("task_dir", nargs="?", default=".")
    parser.add_argument("out_path", nargs="?", default="submission.csv")
    args = parser.parse_args()

    start = time.time()
    task_dir = Path(args.task_dir).resolve()
    out_path = Path(args.out_path).resolve()
    try:
        train_path, test_path, sample_path = discover_files(task_dir)
        print(f"train_path={train_path}", flush=True)
        print(f"test_path={test_path}", flush=True)
        print(f"sample_path={sample_path}", flush=True)
        train = pd.read_csv(train_path)
        test = pd.read_csv(test_path)
        sample = pd.read_csv(sample_path) if sample_path is not None else None

        id_col = infer_id_column(train, test, sample)
        target_col = infer_target_column(train, test, sample, id_col, read_target_hint(train_path))
        train[target_col] = normalize_binary_target(train[target_col])
        print(f"id_col={id_col!r} target_col={target_col!r} train={train.shape} test={test.shape}", flush=True)

        if len(train) > MAX_TRAIN_ROWS:
            train = train.sample(MAX_TRAIN_ROWS, random_state=11).reset_index(drop=True)
            print(f"sampled_train_rows={len(train)}", flush=True)

        feature_cols = [c for c in train.columns if c != target_col and c in test.columns and c != id_col]
        if not feature_cols:
            raise ValueError("no usable feature columns")
        train_x, test_x = build_design(train, test, feature_cols)
        print(f"feature_matrix train={train_x.shape} test={test_x.shape}", flush=True)
        preds = fit_predict(train_x, train[target_col], test_x)
        preds = np.clip(np.asarray(preds, dtype=float), 1e-6, 1 - 1e-6)

        if sample is not None:
            out = sample.copy()
            out[out.columns[-1]] = preds
        else:
            ids = test[id_col] if id_col and id_col in test.columns else np.arange(len(test))
            out = pd.DataFrame({id_col or "row_id": ids, target_col: preds})
        out.to_csv(out_path, index=False)
        print(f"wrote {out.shape} predictions -> {out_path}", flush=True)
        print(f"elapsed_seconds={time.time() - start:.1f}", flush=True)
    except Exception as exc:
        write_prior_submission(task_dir, out_path, exc)


if __name__ == "__main__":
    main()
