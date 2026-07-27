#!/usr/bin/env python3
"""Schema-safe CatBoost specialist for autonomous tabular binary tasks."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd


FORBIDDEN_PARTS = ("solution", "answer", "truth", "ground")


def safe_candidates(root: Path, filename: str) -> list[Path]:
    candidates = []
    for path in root.rglob(filename):
        lowered = "/".join(path.parts).lower()
        if not any(token in lowered for token in FORBIDDEN_PARTS):
            candidates.append(path)
    return sorted(candidates, key=lambda path: (len(path.parts), str(path)))


def discover_files(root: Path) -> tuple[Path, Path, Path]:
    train_paths = safe_candidates(root, "train.csv")
    test_paths = safe_candidates(root, "test.csv")
    sample_paths = safe_candidates(root, "sample_submission.csv")
    if not train_paths or not test_paths or not sample_paths:
        raise FileNotFoundError("train.csv, test.csv, and sample_submission.csv are required")

    for train_path in train_paths:
        parent = train_path.parent
        test_path = parent / "test.csv"
        sample_path = parent / "sample_submission.csv"
        if test_path in test_paths and sample_path in sample_paths:
            return train_path, test_path, sample_path
    return train_paths[0], test_paths[0], sample_paths[0]


def infer_target(
    train: pd.DataFrame,
    test: pd.DataFrame,
    sample: pd.DataFrame,
    task_dir: Path,
) -> str:
    target_file = task_dir / "target_col.txt"
    if target_file.exists():
        candidate = target_file.read_text(encoding="utf-8").strip()
        if candidate in train.columns and candidate not in test.columns:
            return candidate

    train_only = [column for column in train.columns if column not in test.columns]
    if len(train_only) == 1:
        return train_only[0]

    sample_outputs = [column for column in sample.columns if column not in test.columns]
    for column in sample_outputs:
        if column in train.columns:
            return column
    if "target" in train.columns:
        return "target"
    raise ValueError(f"Unable to infer target; train-only columns={train_only}")


def infer_id_columns(
    train: pd.DataFrame,
    test: pd.DataFrame,
    sample: pd.DataFrame,
    target: str,
) -> list[str]:
    identifiers = []
    for column in sample.columns:
        if column == target or column not in test.columns:
            continue
        if column in train.columns and test[column].reset_index(drop=True).equals(
            sample[column].reset_index(drop=True)
        ):
            identifiers.append(column)
    return identifiers


def prepare_features(
    train: pd.DataFrame,
    test: pd.DataFrame,
    target: str,
    id_columns: list[str],
) -> tuple[pd.DataFrame, pd.DataFrame, pd.Series, list[str]]:
    feature_columns = [
        column
        for column in test.columns
        if column in train.columns and column not in id_columns
    ]
    x_train = train[feature_columns].copy()
    x_test = test[feature_columns].copy()
    y = pd.to_numeric(train[target], errors="raise").astype(int)

    categorical = []
    cardinality_cutoff = max(16, min(64, int(0.01 * max(len(train), 1))))
    for column in feature_columns:
        series = x_train[column]
        is_native_cat = (
            not pd.api.types.is_numeric_dtype(series)
            or pd.api.types.is_bool_dtype(series)
        )
        is_small_integer = (
            pd.api.types.is_integer_dtype(series)
            and series.nunique(dropna=True) <= cardinality_cutoff
        )
        if is_native_cat or is_small_integer:
            categorical.append(column)

    for column in feature_columns:
        if column in categorical:
            x_train[column] = x_train[column].astype("string").fillna("__MISSING__")
            x_test[column] = x_test[column].astype("string").fillna("__MISSING__")
        else:
            train_values = pd.to_numeric(x_train[column], errors="coerce").replace(
                [np.inf, -np.inf], np.nan
            )
            test_values = pd.to_numeric(x_test[column], errors="coerce").replace(
                [np.inf, -np.inf], np.nan
            )
            median = float(train_values.median()) if train_values.notna().any() else 0.0
            x_train[column] = train_values.fillna(median).astype(float)
            x_test[column] = test_values.fillna(median).astype(float)

    return x_train, x_test, y, categorical


def catboost_predictions(
    x_train: pd.DataFrame,
    x_test: pd.DataFrame,
    y: pd.Series,
    categorical: list[str],
) -> tuple[np.ndarray, float]:
    from catboost import CatBoostClassifier
    from sklearn.metrics import roc_auc_score
    from sklearn.model_selection import StratifiedKFold

    class_counts = y.value_counts()
    folds = max(2, min(3, int(class_counts.min())))
    splitter = StratifiedKFold(n_splits=folds, shuffle=True, random_state=20260727)
    oof = np.zeros(len(x_train), dtype=float)
    test_predictions = np.zeros(len(x_test), dtype=float)

    for fold, (fit_index, valid_index) in enumerate(splitter.split(x_train, y)):
        model = CatBoostClassifier(
            iterations=450,
            depth=6,
            learning_rate=0.04,
            loss_function="Logloss",
            eval_metric="AUC",
            l2_leaf_reg=5.0,
            random_strength=0.5,
            random_seed=20260727 + fold,
            verbose=False,
            allow_writing_files=False,
            thread_count=4,
        )
        model.fit(
            x_train.iloc[fit_index],
            y.iloc[fit_index],
            cat_features=categorical,
            eval_set=(x_train.iloc[valid_index], y.iloc[valid_index]),
            early_stopping_rounds=60,
            verbose=False,
        )
        oof[valid_index] = model.predict_proba(x_train.iloc[valid_index])[:, 1]
        test_predictions += model.predict_proba(x_test)[:, 1] / folds

    return test_predictions, float(roc_auc_score(y, oof))


def sklearn_predictions(
    x_train: pd.DataFrame,
    x_test: pd.DataFrame,
    y: pd.Series,
    categorical: list[str],
) -> tuple[np.ndarray, float]:
    from sklearn.compose import ColumnTransformer
    from sklearn.ensemble import HistGradientBoostingClassifier
    from sklearn.impute import SimpleImputer
    from sklearn.metrics import roc_auc_score
    from sklearn.model_selection import StratifiedKFold
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import OrdinalEncoder

    numeric = [column for column in x_train.columns if column not in categorical]
    preprocessor = ColumnTransformer(
        transformers=[
            ("numeric", SimpleImputer(strategy="median"), numeric),
            (
                "categorical",
                Pipeline(
                    steps=[
                        ("imputer", SimpleImputer(strategy="most_frequent")),
                        (
                            "encoder",
                            OrdinalEncoder(
                                handle_unknown="use_encoded_value",
                                unknown_value=-1,
                            ),
                        ),
                    ]
                ),
                categorical,
            ),
        ],
        remainder="drop",
    )
    class_counts = y.value_counts()
    folds = max(2, min(3, int(class_counts.min())))
    splitter = StratifiedKFold(n_splits=folds, shuffle=True, random_state=20260727)
    oof = np.zeros(len(x_train), dtype=float)
    test_predictions = np.zeros(len(x_test), dtype=float)

    for fold, (fit_index, valid_index) in enumerate(splitter.split(x_train, y)):
        model = Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "model",
                    HistGradientBoostingClassifier(
                        learning_rate=0.06,
                        max_iter=350,
                        max_leaf_nodes=31,
                        l2_regularization=2.0,
                        random_state=20260727 + fold,
                    ),
                ),
            ]
        )
        model.fit(x_train.iloc[fit_index], y.iloc[fit_index])
        oof[valid_index] = model.predict_proba(x_train.iloc[valid_index])[:, 1]
        test_predictions += model.predict_proba(x_test)[:, 1] / folds

    return test_predictions, float(roc_auc_score(y, oof))


def write_submission(
    sample: pd.DataFrame,
    test: pd.DataFrame,
    target: str,
    predictions: np.ndarray,
    output: Path,
) -> None:
    submission = sample.copy()
    output_columns = [column for column in submission.columns if column not in test.columns]
    prediction_column = target if target in submission.columns else output_columns[-1]
    submission[prediction_column] = np.clip(predictions, 1e-6, 1.0 - 1e-6)
    if len(submission) != len(test):
        raise ValueError("Sample submission and test row counts differ")
    output.parent.mkdir(parents=True, exist_ok=True)
    submission.to_csv(output, index=False)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", default=".")
    parser.add_argument("--output", default="submission.csv")
    arguments = parser.parse_args()

    root = Path(arguments.data_dir).resolve()
    train_path, test_path, sample_path = discover_files(root)
    train = pd.read_csv(train_path)
    test = pd.read_csv(test_path)
    sample = pd.read_csv(sample_path)
    target = infer_target(train, test, sample, train_path.parent)
    id_columns = infer_id_columns(train, test, sample, target)
    x_train, x_test, y, categorical = prepare_features(
        train, test, target, id_columns
    )

    method = "constant_prior"
    cv_auc = None
    errors = []
    predictions = np.full(len(test), float(y.mean()), dtype=float)
    try:
        predictions, cv_auc = catboost_predictions(
            x_train, x_test, y, categorical
        )
        method = "catboost"
    except Exception as error:
        errors.append(f"catboost: {error}")
        try:
            predictions, cv_auc = sklearn_predictions(
                x_train, x_test, y, categorical
            )
            method = "hist_gradient_boosting"
        except Exception as fallback_error:
            errors.append(f"sklearn: {fallback_error}")

    output = Path(arguments.output).resolve()
    write_submission(sample, test, target, predictions, output)
    print(
        json.dumps(
            {
                "method": method,
                "cv_auc": cv_auc,
                "train_rows": len(train),
                "test_rows": len(test),
                "features": len(x_train.columns),
                "categorical_features": len(categorical),
                "target": target,
                "output": str(output),
                "errors": errors,
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
