#!/usr/bin/env python3
"""Schema-agnostic binary-classification baseline for tabular mini-competitions.

Discovers ID/target columns, engineers leakage-safe features, blends a
LogisticRegression and a HistGradientBoostingClassifier by OOF AUC, and
always writes a valid submission file (falls back to a constant-prior
prediction if any modeling step fails).
"""

import argparse
import os
import sys
import time

import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import StandardScaler

BLOCKED_NAME_TOKENS = ("solution", "answer", "truth", "ground")


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

        oof, test_pred = {}, {}

        try:
            oof_lr = np.zeros(len(X))
            test_lr = np.zeros(len(X_test))
            for tr_idx, val_idx in skf.split(X_scaled, y):
                m = LogisticRegression(max_iter=300, C=1.0)
                m.fit(X_scaled[tr_idx], y.iloc[tr_idx])
                oof_lr[val_idx] = m.predict_proba(X_scaled[val_idx])[:, 1]
                test_lr += m.predict_proba(X_test_scaled)[:, 1] / n_splits
            oof["lr"] = oof_lr
            test_pred["lr"] = test_lr
        except Exception as exc:
            print(f"logreg failed: {exc}")

        if time_left() > 20:
            try:
                oof_hgb = np.zeros(len(X))
                test_hgb = np.zeros(len(X_test))
                for tr_idx, val_idx in skf.split(X_enc, y):
                    m = HistGradientBoostingClassifier(
                        max_iter=250, learning_rate=0.08, max_depth=6, random_state=42
                    )
                    m.fit(X_enc.iloc[tr_idx], y.iloc[tr_idx])
                    oof_hgb[val_idx] = m.predict_proba(X_enc.iloc[val_idx])[:, 1]
                    test_hgb += m.predict_proba(X_test_enc)[:, 1] / n_splits
                    if time_left() < 10:
                        print("time budget low, stopping HGB folds early")
                        break
                oof["hgb"] = oof_hgb
                test_pred["hgb"] = test_hgb
            except Exception as exc:
                print(f"hgb failed: {exc}")

        if not oof:
            raise RuntimeError("all models failed")

        weights = {}
        for k, v in oof.items():
            try:
                weights[k] = max(roc_auc_score(y, v) - 0.5, 1e-3)
            except Exception:
                weights[k] = 1e-3
        total_w = sum(weights.values())

        preds = np.zeros(len(X_test))
        blend_oof = np.zeros(len(X))
        for k in oof:
            w = weights[k] / total_w
            preds += test_pred[k] * w
            blend_oof += oof[k] * w
        preds = np.clip(preds, 1e-6, 1 - 1e-6)

        try:
            per_model = {k: round(roc_auc_score(y, v), 5) for k, v in oof.items()}
            print(f"per-model OOF AUC: {per_model}")
            print(f"blend OOF AUC: {roc_auc_score(y, blend_oof):.5f}")
        except Exception:
            pass

        out = pd.DataFrame({id_col: test[id_col], target_col: preds})
        out.to_csv(args.output, index=False)
        print(f"Saved {args.output} shape={out.shape} elapsed={time.time() - t0:.1f}s")

    except Exception as exc:
        print(f"Modeling pipeline failed ({exc}); writing fallback.")
        write_fallback(test, id_col, target_col, prior, args.output)


if __name__ == "__main__":
    main()
