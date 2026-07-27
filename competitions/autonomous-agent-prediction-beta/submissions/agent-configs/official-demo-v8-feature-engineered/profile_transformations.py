#!/usr/bin/env python3
"""Write a compact, solution-blind transformation profile for an LLM analyst."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd

from autopredict import (
    adaptive_feature_policy,
    discover_files,
    infer_id_columns,
    infer_target,
)


def numeric_profile(series: pd.Series, target: pd.Series) -> dict:
    values = pd.to_numeric(series, errors="coerce").replace(
        [np.inf, -np.inf], np.nan
    )
    non_null = values.dropna()
    if non_null.empty:
        return {
            "kind": "numeric",
            "missing_fraction": 1.0,
            "unique": 0,
        }
    minimum = float(non_null.min())
    maximum = float(non_null.max())
    skew = float(non_null.skew()) if non_null.nunique() > 2 else 0.0
    correlation = values.corr(target, method="spearman")
    candidates = []
    if non_null.nunique() >= 20 and abs(skew) >= 1.0:
        candidates.append(
            "log1p_nonnegative" if minimum >= 0 else "signed_log1p"
        )
    if non_null.nunique() >= 30 and abs(skew) >= 2.0:
        candidates.append("quantile_rank")
    if (
        non_null.nunique() >= 20
        and minimum >= 0.0
        and maximum <= 1.0
        and maximum > minimum
    ):
        candidates.append("logit_unit_interval")
    return {
        "kind": "numeric",
        "missing_fraction": float(values.isna().mean()),
        "unique": int(non_null.nunique()),
        "minimum": minimum,
        "maximum": maximum,
        "median": float(non_null.median()),
        "skew": skew if np.isfinite(skew) else None,
        "spearman_with_target": (
            float(correlation) if pd.notna(correlation) else None
        ),
        "candidate_transforms": candidates,
    }


def categorical_profile(series: pd.Series) -> dict:
    values = series.astype("string")
    counts = values.value_counts(dropna=False)
    return {
        "kind": "categorical",
        "missing_fraction": float(values.isna().mean()),
        "unique": int(values.nunique(dropna=True)),
        "largest_level_fraction": (
            float(counts.iloc[0] / len(values)) if len(values) else None
        ),
        "candidate_transforms": ["frequency_encode"],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", default=".")
    parser.add_argument("--output", default="feature_profile.json")
    arguments = parser.parse_args()

    root = Path(arguments.data_dir).resolve()
    train_path, test_path, sample_path = discover_files(root)
    train = pd.read_csv(train_path)
    test = pd.read_csv(test_path)
    sample = pd.read_csv(sample_path)
    target = infer_target(train, test, sample, train_path.parent)
    identifiers = infer_id_columns(train, test, sample, target)
    y = pd.to_numeric(train[target], errors="raise")
    features = [
        column
        for column in test.columns
        if column in train.columns and column not in identifiers
    ]
    adaptive_bucket, adaptive_settings = adaptive_feature_policy(
        len(train),
        len(features),
    )
    cardinality_cutoff = max(16, min(64, int(0.01 * max(len(train), 1))))

    profiles = {}
    for column in features:
        series = train[column]
        is_native_categorical = (
            not pd.api.types.is_numeric_dtype(series)
            or pd.api.types.is_bool_dtype(series)
        )
        is_small_integer = (
            pd.api.types.is_integer_dtype(series)
            and series.nunique(dropna=True) <= cardinality_cutoff
        )
        if is_native_categorical or is_small_integer:
            profiles[column] = categorical_profile(train[column])
        else:
            profiles[column] = numeric_profile(train[column], y)

    output = {
        "task": {
            "train_rows": len(train),
            "test_rows": len(test),
            "features": len(features),
            "target": target,
            "target_type": "binary",
            "positive_fraction": float(y.mean()),
            "important_note": (
                "Do not transform the binary target for normality. "
                "Recommend predictor transformations only."
            ),
            "tree_model_note": (
                "CatBoost does not require normally distributed predictors. "
                "Any transformation needs a skew, tail, bound, or scale rationale."
            ),
            "adaptive_bucket": adaptive_bucket,
            "replay_tested_live_settings": adaptive_settings,
        },
        "advice_policy": (
            "The LLM plan is advisory. The live predictor uses the replay-tested "
            "adaptive settings and does not execute arbitrary plan changes."
        ),
        "allowed_plan_schema": {
            "frequency_encode": "boolean",
            "row_robust_statistics": "boolean",
            "pairwise_interactions": "boolean",
            "numeric_transforms": {
                "<existing numeric column>": sorted(
                    [
                        "signed_log1p",
                        "log1p_nonnegative",
                        "quantile_rank",
                        "logit_unit_interval",
                    ]
                )
            },
        },
        "features": profiles,
    }
    output_path = Path(arguments.output)
    output_path.write_text(
        json.dumps(output, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    print(str(output_path.resolve()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
