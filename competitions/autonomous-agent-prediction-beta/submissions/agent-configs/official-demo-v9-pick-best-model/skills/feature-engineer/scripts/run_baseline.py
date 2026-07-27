#!/usr/bin/env python3
"""Schema-agnostic binary-classification baseline for tabular mini-competitions.

Discovers ID/target columns, engineers leakage-safe features (including
pairwise interactions among the top target-correlated numeric columns),
cross-validates LogisticRegression + HistGradientBoostingClassifier +
RandomForestClassifier + ExtraTreesClassifier (all in-process, n_jobs=1),
and uses whichever single model has the best out-of-fold AUC rather than
blending all of them (blending diluted the strongest model's signal in
testing). Always writes a valid submission file (falls back to a
constant-prior prediction if every modeling step fails).
"""

import argparse
import os
import sys
import time

import numpy as np
import pandas as pd
from sklearn.ensemble import (
    ExtraTreesClassifier,
    HistGradientBoostingClassifier,
    RandomForestClassifier,
)
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import StandardScaler

BLOCKED_NAME_TOKENS = ("solution", "answer", "truth", "ground")
TOP_K_INTERACTIONS = 5


def build_model_specs():
    """(name, zero-arg model factory, feature set) for every model to try.

    feature set is "scaled" (standardized encoded features, for the linear
    model) or "enc" (raw encoded features, for tree models). All models run
    in-process with n_jobs=1 — a prior attempt at n_jobs=-1 plus fork-based
    subprocess timeouts both caused severe hangs in local testing (see
    LEARNINGS.md); staying in-process and single-threaded avoided both.
    """
    return [
        ("lr", lambda: LogisticRegression(max_iter=300, C=1.0), "scaled"),
        (
            "hgb",
            lambda: HistGradientBoostingClassifier(
                max_iter=250, learning_rate=0.08, max_depth=6, random_state=42
            ),
            "enc",
        ),
        (
            "rf",
            lambda: RandomForestClassifier(
                n_estimators=200, max_depth=10, min_samples_leaf=2,
                random_state=42, n_jobs=1,
            ),
            "enc",
        ),
        (
            "et",
            lambda: ExtraTreesClassifier(
                n_estimators=200, max_depth=10, min_samples_leaf=2,
                random_state=42, n_jobs=1,
            ),
            "enc",
        ),
    ]


def parse_args():
    ap = argparse.ArgumentParser(description="Leakage-safe tabular baseline")
    ap.add_argument("--train", default="train.csv")
    ap.add_argument("--test", default="test.csv")
    ap.add_argument("--sample_sub", default="sample_submission.csv")
    ap.add_argument("--target_hint", default="target_col.txt")
    ap.add_argument("--output", default="submission.csv")
    ap.add_argument("--folds", type=int, default=5)
    ap.add_argument("--time_budget", type=float, default=240.0)
    return ap.parse_args()


def find_target_col(train_cols, test_cols, hint_path):
    if os.path.exists(hint_path):
        hinted = open(hint_path).read().strip()
        if hinted and hinted in train_cols:
            return hinted
    candidates = [c for c in train_cols if c not in test_cols]
    if len(candidates) == 1:
        return candidates[0]
    if "target" in train_cols:
        return "target"
    if candidates:
        return candidates[0]
    raise ValueError("Could not infer target column")


def find_id_col(sample_sub_cols, test_cols):
    if sample_sub_cols:
        return sample_sub_cols[0]
    return test_cols[0]


def write_fallback(test, id_col, target_col, prior, output):
    preds = np.full(len(test), prior if prior is not None else 0.5)
    pd.DataFrame({id_col: test[id_col], target_col: preds}).to_csv(output, index=False)
    print(f"Wrote constant-prior fallback submission ({prior}) to {output}")


def main():
    args = parse_args()
    t0 = time.time()

    for path in (args.train, args.test):
        for token in BLOCKED_NAME_TOKENS:
            assert token not in os.path.basename(path).lower(), f"refusing to read {path}"

    train = pd.read_csv(args.train)
    test = pd.read_csv(args.test)
    sample_sub = pd.read_csv(args.sample_sub) if os.path.exists(args.sample_sub) else None

    target_col = find_target_col(list(train.columns), list(test.columns), args.target_hint)
    id_col = find_id_col(list(sample_sub.columns) if sample_sub is not None else None, list(test.columns))

    y_raw = train[target_col]
    prior = None
    try:
        if y_raw.dtype == object or str(y_raw.dtype) == "category":
            classes = sorted(y_raw.dropna().unique().tolist())
            y = y_raw.map({c: i for i, c in enumerate(classes)}).astype(int)
        else:
            y = y_raw.astype(int)
        prior = float(y.mean())
    except Exception as exc:
        print(f"Target parsing failed ({exc}); writing fallback.")
        write_fallback(test, id_col, target_col, 0.5, args.output)
        return

    try:
        feature_cols = [c for c in train.columns if c not in (target_col, id_col) and c in test.columns]
        X = train[feature_cols].copy()
        X_test = test[feature_cols].copy()

        num_cols = [c for c in feature_cols if pd.api.types.is_numeric_dtype(X[c])]
        cat_cols = [c for c in feature_cols if c not in num_cols]

        for c in num_cols:
            med = X[c].median()
            X[c] = X[c].fillna(med)
            X_test[c] = X_test[c].fillna(med)

        for c in cat_cols:
            X[c] = X[c].fillna("__missing__").astype(str)
            X_test[c] = X_test[c].fillna("__missing__").astype(str)

        if num_cols:
            block, block_t = X[num_cols], X_test[num_cols]
            for df, blk in ((X, block), (X_test, block_t)):
                df["agg_mean"] = blk.mean(axis=1)
                df["agg_std"] = blk.std(axis=1)
                df["agg_min"] = blk.min(axis=1)
                df["agg_max"] = blk.max(axis=1)
                df["agg_sum"] = blk.sum(axis=1)
            num_cols_ext = num_cols + ["agg_mean", "agg_std", "agg_min", "agg_max", "agg_sum"]
        else:
            num_cols_ext = num_cols

        # Pairwise interactions among the top target-correlated numeric columns.
        if len(num_cols) >= 2:
            y_float = y.astype(float)
            corrs = X[num_cols].apply(lambda c: c.corr(y_float)).abs().fillna(0.0)
            top_cols = corrs.sort_values(ascending=False).head(TOP_K_INTERACTIONS).index.tolist()
            interaction_cols = []
            for i in range(len(top_cols)):
                for j in range(i + 1, len(top_cols)):
                    a, b = top_cols[i], top_cols[j]
                    prod_name, diff_name = f"{a}__x__{b}", f"{a}__minus__{b}"
                    for df in (X, X_test):
                        df[prod_name] = df[a] * df[b]
                        df[diff_name] = df[a] - df[b]
                    interaction_cols.extend([prod_name, diff_name])
            num_cols_ext = num_cols_ext + interaction_cols

        min_class = int(y.value_counts().min())
        n_splits = max(2, min(args.folds, min_class))
        skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=42)

        global_mean = y.mean()
        for c in cat_cols:
            freq = X[c].value_counts(normalize=True)
            X[f"{c}__freq"] = X[c].map(freq).fillna(0.0)
            X_test[f"{c}__freq"] = X_test[c].map(freq).fillna(0.0)

            oof_te = pd.Series(index=X.index, dtype=float)
            for tr_idx, val_idx in skf.split(X, y):
                means = y.iloc[tr_idx].groupby(X[c].iloc[tr_idx]).mean()
                oof_te.iloc[val_idx] = X[c].iloc[val_idx].map(means)
            X[f"{c}__te"] = oof_te.fillna(global_mean)
            full_means = y.groupby(X[c]).mean()
            X_test[f"{c}__te"] = X_test[c].map(full_means).fillna(global_mean)

        encoded_cols = num_cols_ext + [f"{c}__freq" for c in cat_cols] + [f"{c}__te" for c in cat_cols]
        X_enc = X[encoded_cols].fillna(0.0)
        X_test_enc = X_test[encoded_cols].fillna(0.0)

        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X_enc)
        X_test_scaled = scaler.transform(X_test_enc)

        def time_left():
            return args.time_budget - (time.time() - t0)

        feature_sets = {"scaled": (X_scaled, X_test_scaled), "enc": (X_enc, X_test_enc)}
        oof, test_pred = {}, {}

        for name, factory, feat in build_model_specs():
            if time_left() < 15:
                print(f"time budget low, skipping remaining models (stopped before {name})")
                break
            Xf, Xtf = feature_sets[feat]
            try:
                oof_i = np.zeros(len(X))
                test_i = np.zeros(len(X_test))
                for tr_idx, val_idx in skf.split(Xf, y):
                    m = factory()
                    if feat == "scaled":
                        Xtr, Xva = Xf[tr_idx], Xf[val_idx]
                    else:
                        Xtr, Xva = Xf.iloc[tr_idx], Xf.iloc[val_idx]
                    m.fit(Xtr, y.iloc[tr_idx])
                    oof_i[val_idx] = m.predict_proba(Xva)[:, 1]
                    test_i += m.predict_proba(Xtf)[:, 1] / n_splits
                    if time_left() < 10:
                        print(f"time budget low, stopping {name} folds early")
                        break
                oof[name] = oof_i
                test_pred[name] = test_i
            except Exception as exc:
                print(f"{name} failed: {exc}")

        if not oof:
            raise RuntimeError("all models failed")

        aucs = {}
        for k, v in oof.items():
            try:
                aucs[k] = roc_auc_score(y, v)
            except Exception:
                aucs[k] = 0.5
        best_name = max(aucs, key=aucs.get)
        preds = np.clip(test_pred[best_name], 1e-6, 1 - 1e-6)

        print(f"per-model OOF AUC: { {k: round(v, 5) for k, v in aucs.items()} }")
        print(f"selected best model: {best_name} (OOF AUC {aucs[best_name]:.5f})")

        out = pd.DataFrame({id_col: test[id_col], target_col: preds})
        out.to_csv(args.output, index=False)
        print(f"Saved {args.output} shape={out.shape} elapsed={time.time() - t0:.1f}s")

    except Exception as exc:
        print(f"Modeling pipeline failed ({exc}); writing fallback.")
        write_fallback(test, id_col, target_col, prior, args.output)


if __name__ == "__main__":
    main()
