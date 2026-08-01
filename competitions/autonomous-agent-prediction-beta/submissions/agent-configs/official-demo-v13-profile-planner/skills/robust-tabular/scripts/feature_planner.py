"""Target-blind profiling and a strict declarative feature-plan executor."""

from __future__ import annotations

import json
from typing import Any

import numpy as np
import pandas as pd

ALLOWED_MODELS = {"catboost", "lightgbm", "extra_trees", "logistic"}
ALLOWED_FAMILIES = {
    "frequency",
    "signed_log",
    "row_stats",
    "missingness",
    "interactions",
    "polynomial",
}
ALLOWED_INTERACTIONS = {"product", "difference", "ratio"}
MAX_GENERATED_FEATURES = 40


def _is_categorical(series: pd.Series) -> bool:
    return (
        not pd.api.types.is_numeric_dtype(series)
        or pd.api.types.is_string_dtype(series)
        or pd.api.types.is_bool_dtype(series)
    )


def build_profile(
    train: pd.DataFrame,
    test: pd.DataFrame,
    features: list[str],
    baseline_metrics: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Describe predictors without reading or deriving anything from the target."""
    columns: dict[str, dict[str, Any]] = {}
    numeric: list[str] = []
    categorical: list[str] = []
    for column in features:
        series = train[column]
        missing = float(series.isna().mean())
        if _is_categorical(series):
            categorical.append(column)
            counts = series.astype("string").value_counts(dropna=False)
            columns[column] = {
                "kind": "categorical",
                "missing_fraction": missing,
                "unique": int(series.nunique(dropna=True)),
                "largest_level_fraction": float(counts.iloc[0] / len(series)) if len(counts) else None,
            }
            continue
        numeric.append(column)
        values = pd.to_numeric(series, errors="coerce").replace([np.inf, -np.inf], np.nan)
        non_null = values.dropna()
        if non_null.empty:
            columns[column] = {"kind": "numeric", "missing_fraction": 1.0, "unique": 0}
            continue
        q01, q25, q50, q75, q99 = np.nanpercentile(non_null, [1, 25, 50, 75, 99])
        skew = float(non_null.skew()) if non_null.nunique() > 2 else 0.0
        columns[column] = {
            "kind": "numeric",
            "missing_fraction": missing,
            "unique": int(non_null.nunique()),
            "minimum": float(non_null.min()),
            "q01": float(q01),
            "q25": float(q25),
            "median": float(q50),
            "q75": float(q75),
            "q99": float(q99),
            "maximum": float(non_null.max()),
            "skew": skew if np.isfinite(skew) else None,
            "zero_fraction": float((non_null == 0).mean()),
        }

    correlation_pairs: list[dict[str, Any]] = []
    usable_numeric = numeric[:32]
    if len(usable_numeric) >= 2:
        matrix = train[usable_numeric].apply(pd.to_numeric, errors="coerce").corr(method="spearman")
        pairs: list[tuple[float, str, str]] = []
        for left_index, left in enumerate(usable_numeric):
            for right in usable_numeric[left_index + 1 :]:
                value = matrix.loc[left, right]
                if pd.notna(value):
                    pairs.append((abs(float(value)), left, right))
        correlation_pairs = [
            {"left": left, "right": right, "absolute_spearman": value}
            for value, left, right in sorted(pairs, reverse=True)[:12]
        ]

    return {
        "profile_version": 1,
        "task": {
            "train_rows": int(len(train)),
            "test_rows": int(len(test)),
            "features": int(len(features)),
            "numeric_features": int(len(numeric)),
            "categorical_features": int(len(categorical)),
            "target_type": "binary",
        },
        "safety": {
            "solution_blind": True,
            "target_profiled": False,
            "target_transform_allowed": False,
            "max_generated_features": MAX_GENERATED_FEATURES,
            "exactly_one_family_per_plan": True,
        },
        "baseline_oof_auc": baseline_metrics or {},
        "allowed_schema": {
            "model": sorted(ALLOWED_MODELS),
            "family_names": sorted(ALLOWED_FAMILIES),
            "interaction_operations": sorted(ALLOWED_INTERACTIONS),
            "plan_shape": {
                "model": "one allowed model name",
                "family": {"name": "one allowed family", "columns": [], "pairs": [], "operations": []},
                "rationale": "short text ignored by executor",
            },
        },
        "columns": columns,
        "top_absolute_predictor_correlations": correlation_pairs,
    }


def validate_plan(plan: Any, features: list[str], train: pd.DataFrame) -> dict[str, Any]:
    if not isinstance(plan, dict):
        raise ValueError("plan must be a JSON object")
    model = plan.get("model")
    if model not in ALLOWED_MODELS:
        raise ValueError("unknown model")
    family = plan.get("family")
    if not isinstance(family, dict) or family.get("name") not in ALLOWED_FAMILIES:
        raise ValueError("exactly one allowed family object is required")
    name = str(family["name"])
    numeric = [column for column in features if not _is_categorical(train[column])]
    categorical = [column for column in features if _is_categorical(train[column])]

    requested_columns = family.get("columns", [])
    if not isinstance(requested_columns, list):
        raise ValueError("family.columns must be a list")
    allowed_columns = categorical if name == "frequency" else numeric
    columns = [str(column) for column in requested_columns if column in allowed_columns]
    columns = list(dict.fromkeys(columns))[:20]

    pairs: list[list[str]] = []
    raw_pairs = family.get("pairs", [])
    if name == "interactions":
        if not isinstance(raw_pairs, list):
            raise ValueError("family.pairs must be a list")
        for pair in raw_pairs:
            if isinstance(pair, list) and len(pair) == 2 and pair[0] in numeric and pair[1] in numeric and pair[0] != pair[1]:
                pairs.append([str(pair[0]), str(pair[1])])
        pairs = pairs[:8]
    raw_operations = family.get("operations", [])
    operations = (
        [str(value) for value in raw_operations if value in ALLOWED_INTERACTIONS]
        if isinstance(raw_operations, list)
        else []
    )[:3]

    if name in {"frequency", "signed_log", "polynomial"} and not columns:
        raise ValueError(f"{name} requires at least one valid column")
    if name == "interactions" and (not pairs or not operations):
        raise ValueError("interactions requires valid pairs and operations")
    return {
        "model": model,
        "family": {"name": name, "columns": columns, "pairs": pairs, "operations": operations},
        "rationale": str(plan.get("rationale", ""))[:500],
    }


def apply_plan(
    train: pd.DataFrame,
    test: pd.DataFrame,
    features: list[str],
    plan: dict[str, Any],
) -> tuple[pd.DataFrame, pd.DataFrame, list[str], list[str]]:
    """Apply a validated plan using train-fitted, target-independent statistics."""
    output_train = train.copy()
    output_test = test.copy()
    generated: list[str] = []
    family = plan["family"]
    name = family["name"]

    def add(column: str, train_values: Any, test_values: Any) -> None:
        if len(generated) >= MAX_GENERATED_FEATURES or column in output_train.columns:
            return
        output_train[column] = np.nan_to_num(np.asarray(train_values, dtype=float), nan=0.0, posinf=1e6, neginf=-1e6)
        output_test[column] = np.nan_to_num(np.asarray(test_values, dtype=float), nan=0.0, posinf=1e6, neginf=-1e6)
        generated.append(column)

    if name == "frequency":
        for column in family["columns"]:
            train_key = output_train[column].astype("string").fillna("__MISSING__")
            test_key = output_test[column].astype("string").fillna("__MISSING__")
            mapping = train_key.value_counts(dropna=False) / max(len(train_key), 1)
            add(f"__freq__{column}", train_key.map(mapping).fillna(0), test_key.map(mapping).fillna(0))

    elif name == "signed_log":
        for column in family["columns"]:
            train_values = pd.to_numeric(output_train[column], errors="coerce").fillna(0).to_numpy(float)
            test_values = pd.to_numeric(output_test[column], errors="coerce").fillna(0).to_numpy(float)
            add(f"__signed_log__{column}", np.sign(train_values) * np.log1p(np.abs(train_values)), np.sign(test_values) * np.log1p(np.abs(test_values)))

    elif name == "polynomial":
        for column in family["columns"]:
            train_values, test_values = _robust_values(output_train[column], output_test[column])
            add(f"__square__{column}", np.clip(train_values**2, 0, 100), np.clip(test_values**2, 0, 100))

    elif name == "missingness":
        add("__missing_count", output_train[features].isna().sum(axis=1), output_test[features].isna().sum(axis=1))

    elif name == "row_stats":
        numeric = [column for column in features if not _is_categorical(output_train[column])]
        if numeric:
            train_matrix, test_matrix = zip(*[_robust_values(output_train[column], output_test[column]) for column in numeric[:32]])
            train_matrix = np.column_stack(train_matrix)
            test_matrix = np.column_stack(test_matrix)
            for suffix, function in (("mean", np.mean), ("std", np.std), ("min", np.min), ("max", np.max)):
                add(f"__row_{suffix}", function(train_matrix, axis=1), function(test_matrix, axis=1))
            add("__row_range", np.ptp(train_matrix, axis=1), np.ptp(test_matrix, axis=1))

    elif name == "interactions":
        cache: dict[str, tuple[np.ndarray, np.ndarray]] = {}
        for left, right in family["pairs"]:
            cache.setdefault(left, _robust_values(output_train[left], output_test[left]))
            cache.setdefault(right, _robust_values(output_train[right], output_test[right]))
            left_train, left_test = cache[left]
            right_train, right_test = cache[right]
            for operation in family["operations"]:
                if operation == "product":
                    tr, te = left_train * right_train, left_test * right_test
                elif operation == "difference":
                    tr, te = left_train - right_train, left_test - right_test
                else:
                    tr = left_train / np.where(np.abs(right_train) < 0.1, np.sign(right_train) * 0.1 + (right_train == 0) * 0.1, right_train)
                    te = left_test / np.where(np.abs(right_test) < 0.1, np.sign(right_test) * 0.1 + (right_test == 0) * 0.1, right_test)
                add(f"__{operation}__{left}__{right}", np.clip(tr, -100, 100), np.clip(te, -100, 100))

    return output_train, output_test, features + generated, generated


def _robust_values(train: pd.Series, test: pd.Series) -> tuple[np.ndarray, np.ndarray]:
    train_values = pd.to_numeric(train, errors="coerce").replace([np.inf, -np.inf], np.nan)
    test_values = pd.to_numeric(test, errors="coerce").replace([np.inf, -np.inf], np.nan)
    median = float(train_values.median()) if train_values.notna().any() else 0.0
    train_array = train_values.fillna(median).to_numpy(float)
    test_array = test_values.fillna(median).to_numpy(float)
    q25, q75 = np.percentile(train_array, [25, 75])
    scale = float(q75 - q25)
    if not np.isfinite(scale) or scale < 1e-9:
        scale = float(np.std(train_array))
    if not np.isfinite(scale) or scale < 1e-9:
        scale = 1.0
    return (train_array - median) / scale, (test_array - median) / scale


def profile_json(*args: Any, **kwargs: Any) -> str:
    return json.dumps(build_profile(*args, **kwargs), indent=2, sort_keys=True)
