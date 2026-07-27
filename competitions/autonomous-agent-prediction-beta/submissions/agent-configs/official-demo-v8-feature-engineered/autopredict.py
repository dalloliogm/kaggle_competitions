#!/usr/bin/env python3
"""Schema-safe feature portfolio for autonomous tabular binary tasks."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd


FORBIDDEN_PARTS = ("solution", "answer", "truth", "ground")
ALLOWED_NUMERIC_TRANSFORMS = {
    "signed_log1p",
    "log1p_nonnegative",
    "quantile_rank",
    "logit_unit_interval",
}


def adaptive_feature_policy(
    row_count: int,
    feature_count: int,
) -> tuple[str, dict[str, bool]]:
    settings = {
        "frequency_encode": False,
        "row_robust_statistics": False,
        "pairwise_interactions": False,
    }
    if row_count < 800 and feature_count < 20:
        bucket = "ultra_small_narrow_baseline"
    elif row_count < 800:
        bucket = "ultra_small_wide_row_statistics"
        settings["row_robust_statistics"] = True
    elif row_count < 2_000 and feature_count < 15:
        bucket = "small_narrow_frequency"
        settings["frequency_encode"] = True
    elif row_count < 2_000:
        bucket = "small_wide_pairwise"
        settings["pairwise_interactions"] = True
    else:
        bucket = "large_conservative_baseline"
    return bucket, settings


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
    feature_mode: str = "none",
    transform_plan: dict | None = None,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.Series, list[str], dict]:
    feature_columns = [
        column
        for column in test.columns
        if column in train.columns and column not in id_columns
    ]
    x_train = train[feature_columns].copy()
    x_test = test[feature_columns].copy()
    raw_train = x_train.copy()
    raw_test = x_test.copy()
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

    metadata = {
        "feature_mode": feature_mode,
        "base_features": len(feature_columns),
        "engineered_features": [],
        "numeric_transformations": {},
        "adaptive_bucket": None,
    }
    if feature_mode == "none":
        return x_train, x_test, y, categorical, metadata

    numeric = [column for column in feature_columns if column not in categorical]
    settings = {
        "frequency_encode": True,
        "row_robust_statistics": True,
        "pairwise_interactions": True,
    }
    requested_transforms: dict[str, list[str]] = {}
    if feature_mode == "numeric":
        settings = {
            "frequency_encode": False,
            "row_robust_statistics": False,
            "pairwise_interactions": False,
        }
    elif feature_mode == "adaptive":
        metadata["adaptive_bucket"], settings = adaptive_feature_policy(
            len(train),
            len(feature_columns),
        )
    elif feature_mode == "plan":
        if not isinstance(transform_plan, dict):
            raise ValueError("feature_mode=plan requires a JSON object")
        for key in settings:
            if key in transform_plan:
                settings[key] = bool(transform_plan[key])
        raw_requests = transform_plan.get("numeric_transforms", {})
        if not isinstance(raw_requests, dict):
            raise ValueError("numeric_transforms must be an object")
        for column, operations in raw_requests.items():
            if column not in numeric or not isinstance(operations, list):
                continue
            requested_transforms[column] = [
                operation
                for operation in operations
                if operation in ALLOWED_NUMERIC_TRANSFORMS
            ]

    def add_numeric(name: str, train_values, test_values) -> None:
        if name in x_train.columns or name in x_test.columns:
            return
        x_train[name] = np.nan_to_num(
            np.asarray(train_values, dtype=float),
            nan=0.0,
            posinf=1e6,
            neginf=-1e6,
        )
        x_test[name] = np.nan_to_num(
            np.asarray(test_values, dtype=float),
            nan=0.0,
            posinf=1e6,
            neginf=-1e6,
        )
        metadata["engineered_features"].append(name)

    if settings["frequency_encode"]:
        for column in categorical:
            train_key = raw_train[column].astype("string").fillna("__MISSING__")
            test_key = raw_test[column].astype("string").fillna("__MISSING__")
            frequencies = train_key.value_counts(dropna=False) / max(len(train_key), 1)
            add_numeric(
                f"__freq__{column}",
                train_key.map(frequencies).fillna(0.0),
                test_key.map(frequencies).fillna(0.0),
            )

    numeric_cache: dict[str, tuple[np.ndarray, np.ndarray, float, float]] = {}
    for column in numeric:
        train_values = pd.to_numeric(raw_train[column], errors="coerce").replace(
            [np.inf, -np.inf], np.nan
        )
        test_values = pd.to_numeric(raw_test[column], errors="coerce").replace(
            [np.inf, -np.inf], np.nan
        )
        median = float(train_values.median()) if train_values.notna().any() else 0.0
        train_filled = train_values.fillna(median).to_numpy(dtype=float)
        test_filled = test_values.fillna(median).to_numpy(dtype=float)
        q25, q75 = np.nanpercentile(train_filled, [25, 75])
        scale = float(q75 - q25)
        if not np.isfinite(scale) or scale <= 1e-9:
            scale = float(np.nanstd(train_filled))
        if not np.isfinite(scale) or scale <= 1e-9:
            scale = 1.0
        numeric_cache[column] = (train_filled, test_filled, median, scale)

        if feature_mode in {"plan", "adaptive"}:
            operations = requested_transforms.get(column, [])
        else:
            unique_count = int(pd.Series(train_filled).nunique())
            skew = float(pd.Series(train_filled).skew()) if unique_count > 2 else 0.0
            minimum = float(np.nanmin(train_filled))
            maximum = float(np.nanmax(train_filled))
            operations = []
            if unique_count >= 20 and abs(skew) >= 1.0:
                operations.append(
                    "log1p_nonnegative" if minimum >= 0 else "signed_log1p"
                )
            if unique_count >= 30 and abs(skew) >= 2.0:
                operations.append("quantile_rank")
            if (
                unique_count >= 20
                and minimum >= 0.0
                and maximum <= 1.0
                and maximum > minimum
            ):
                operations.append("logit_unit_interval")

        applied = []
        for operation in operations:
            if operation == "signed_log1p":
                add_numeric(
                    f"__signed_log1p__{column}",
                    np.sign(train_filled) * np.log1p(np.abs(train_filled)),
                    np.sign(test_filled) * np.log1p(np.abs(test_filled)),
                )
            elif operation == "log1p_nonnegative":
                if np.nanmin(train_filled) < 0:
                    continue
                add_numeric(
                    f"__log1p__{column}",
                    np.log1p(np.clip(train_filled, 0.0, None)),
                    np.log1p(np.clip(test_filled, 0.0, None)),
                )
            elif operation == "quantile_rank":
                ordered = np.sort(train_filled[np.isfinite(train_filled)])
                if len(ordered) < 2:
                    continue
                denominator = len(ordered) + 1.0
                add_numeric(
                    f"__rank__{column}",
                    np.searchsorted(ordered, train_filled, side="right")
                    / denominator,
                    np.searchsorted(ordered, test_filled, side="right")
                    / denominator,
                )
            elif operation == "logit_unit_interval":
                if np.nanmin(train_filled) < 0 or np.nanmax(train_filled) > 1:
                    continue
                epsilon = 1e-5
                add_numeric(
                    f"__logit__{column}",
                    np.log(
                        np.clip(train_filled, epsilon, 1 - epsilon)
                        / np.clip(1 - train_filled, epsilon, 1 - epsilon)
                    ),
                    np.log(
                        np.clip(test_filled, epsilon, 1 - epsilon)
                        / np.clip(1 - test_filled, epsilon, 1 - epsilon)
                    ),
                )
            else:
                continue
            applied.append(operation)
        if applied:
            metadata["numeric_transformations"][column] = applied

    if numeric and settings["row_robust_statistics"]:
        missing_train = raw_train[numeric].isna().sum(axis=1).to_numpy(dtype=float)
        missing_test = raw_test[numeric].isna().sum(axis=1).to_numpy(dtype=float)
        add_numeric("__row_missing_count", missing_train, missing_test)
        if len(numeric) >= 3:
            train_robust = np.column_stack(
                [
                    (numeric_cache[column][0] - numeric_cache[column][2])
                    / numeric_cache[column][3]
                    for column in numeric
                ]
            )
            test_robust = np.column_stack(
                [
                    (numeric_cache[column][1] - numeric_cache[column][2])
                    / numeric_cache[column][3]
                    for column in numeric
                ]
            )
            row_statistics = {
                "__row_robust_mean": np.mean,
                "__row_robust_std": np.std,
                "__row_robust_min": np.min,
                "__row_robust_max": np.max,
            }
            for name, function in row_statistics.items():
                add_numeric(
                    name,
                    function(train_robust, axis=1),
                    function(test_robust, axis=1),
                )
            add_numeric(
                "__row_robust_range",
                np.max(train_robust, axis=1) - np.min(train_robust, axis=1),
                np.max(test_robust, axis=1) - np.min(test_robust, axis=1),
            )

    if len(numeric) >= 2 and settings["pairwise_interactions"]:
        correlation_frame = pd.DataFrame(
            {
                column: numeric_cache[column][0]
                for column in numeric[:32]
            }
        )
        correlations = correlation_frame.corr(method="spearman").abs()
        pairs = []
        columns = list(correlations.columns)
        for left_index, left in enumerate(columns):
            for right in columns[left_index + 1 :]:
                correlation = float(correlations.loc[left, right])
                if np.isfinite(correlation) and 0.15 <= correlation < 0.995:
                    pairs.append((correlation, left, right))
        for _, left, right in sorted(pairs, reverse=True)[:4]:
            left_train = (
                numeric_cache[left][0] - numeric_cache[left][2]
            ) / numeric_cache[left][3]
            left_test = (
                numeric_cache[left][1] - numeric_cache[left][2]
            ) / numeric_cache[left][3]
            right_train = (
                numeric_cache[right][0] - numeric_cache[right][2]
            ) / numeric_cache[right][3]
            right_test = (
                numeric_cache[right][1] - numeric_cache[right][2]
            ) / numeric_cache[right][3]
            add_numeric(
                f"__product__{left}__{right}",
                np.clip(left_train * right_train, -100, 100),
                np.clip(left_test * right_test, -100, 100),
            )
            add_numeric(
                f"__absdiff__{left}__{right}",
                np.abs(left_train - right_train),
                np.abs(left_test - right_test),
            )

    metadata["total_features"] = len(x_train.columns)
    metadata["settings"] = settings
    return x_train, x_test, y, categorical, metadata


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
    parser.add_argument(
        "--feature-mode",
        choices=["none", "numeric", "auto", "adaptive", "plan"],
        default="none",
    )
    parser.add_argument("--plan", default=None)
    arguments = parser.parse_args()

    root = Path(arguments.data_dir).resolve()
    train_path, test_path, sample_path = discover_files(root)
    train = pd.read_csv(train_path)
    test = pd.read_csv(test_path)
    sample = pd.read_csv(sample_path)
    target = infer_target(train, test, sample, train_path.parent)
    id_columns = infer_id_columns(train, test, sample, target)
    transform_plan = None
    if arguments.feature_mode == "plan":
        if not arguments.plan:
            raise ValueError("--plan is required with --feature-mode plan")
        transform_plan = json.loads(
            Path(arguments.plan).read_text(encoding="utf-8")
        )
    x_train, x_test, y, categorical, feature_metadata = prepare_features(
        train,
        test,
        target,
        id_columns,
        feature_mode=arguments.feature_mode,
        transform_plan=transform_plan,
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
                "feature_metadata": feature_metadata,
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
