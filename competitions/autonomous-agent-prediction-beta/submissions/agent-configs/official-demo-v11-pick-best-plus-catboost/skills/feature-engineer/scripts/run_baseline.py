#!/usr/bin/env python3
"""Schema-agnostic binary-classification baseline for tabular mini-competitions.

Discovers ID/target columns, engineers leakage-safe features (including
pairwise interactions among the top target-correlated numeric columns),
cross-validates LogisticRegression + HistGradientBoostingClassifier +
RandomForestClassifier + ExtraTreesClassifier + (when importable) a
single-threaded CatBoostClassifier, and uses whichever single model has the
best out-of-fold AUC rather than blending all of them (blending diluted the
strongest model's signal in testing).

CatBoost is added strictly as a *gated candidate*: the sklearn models are
always evaluated, and the pick-best-OOF selector adopts CatBoost only when it
genuinely wins. This matters because a standalone CatBoost specialist measured
0.7990 mean over the 16 official replay tasks (0.8247 on tasks with >=2,000
rows, but only 0.7424 on smaller ones, three below 0.70) -- it is a strong
large-task model and a poor universal default. Letting the selector arbitrate
captures the former without exposing the latter.

Always writes a valid submission file (falls back to a constant-prior
prediction if every modeling step fails).
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

# CatBoost ships in Kaggle's official Python image, but it is imported behind a
# guard so this script still runs anywhere only pandas/numpy/sklearn exist. If
# the import fails, the CatBoost candidate is silently omitted and the four
# sklearn models proceed exactly as in the 0.819 v9 package.
try:
    from catboost import CatBoostClassifier

    _HAS_CATBOOST = True
except Exception:  # pragma: no cover - depends on sandbox package set
    _HAS_CATBOOST = False

BLOCKED_NAME_TOKENS = ("solution", "answer", "truth", "ground")
TOP_K_INTERACTIONS = 5

# CatBoost must beat the best sklearn model by at least this much out-of-fold
# before it is allowed to displace it. Rationale, measured 2026-07-30 on a
# 900-row synthetic task: CatBoost won out-of-fold by 0.00044 and then lost on
# the held-out test set by 0.0028 -- a textbook winner's-curse pick, and the
# same small-table fragility recorded in LEARNINGS.md (0.7424 mean on the small
# replay tasks). The out-of-fold noise floor here is ~0.0004, so a bare
# argmax over five models can promote a fragile model on noise alone.
# CatBoost's genuine large-table advantage is far larger than this margin
# (0.8247 vs ~0.80 in replay), so 0.003 preserves real wins while rejecting
# noise wins. The four sklearn models keep their original bare-argmax
# selection, so when CatBoost does not clear the bar this script behaves
# exactly like the 0.819 v9 package.
CATBOOST_MARGIN = 0.003


def build_model_specs(cat_feature_idx=None):
    """(name, zero-arg model factory, feature set) for every model to try.

    feature set is "scaled" (standardized encoded features, for the linear
    model), "enc" (target/frequency-encoded features, for the sklearn tree
    models), or "cat_native" (numeric features plus the *raw* categorical
    columns, for CatBoost only -- it applies its own ordered target statistics,
    so handing it the pre-computed encodings would waste the one thing it does
    better than the sklearn models). All models run
    in-process, single-threaded — a prior attempt at n_jobs=-1/thread_count=-1
    plus fork-based subprocess timeouts both caused severe hangs in local
    testing (see LEARNINGS.md); staying in-process and single-threaded avoided
    both. CatBoost is appended only when importable, and runs with
    thread_count=1 and a capped iteration count for the same reason.
    """
    specs = [
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
    if _HAS_CATBOOST:
        cat_idx = list(cat_feature_idx or [])
        specs.append(
            (
                "cat",
                lambda: CatBoostClassifier(
                    iterations=400, learning_rate=0.05, depth=6,
                    l2_leaf_reg=3.0, random_seed=42, thread_count=1,
                    allow_writing_files=False, verbose=0,
                    cat_features=cat_idx,
                ),
                "cat_native",
            )
        )
    return specs


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

        # CatBoost-only view: engineered numerics plus the raw categorical
        # columns, so CatBoost can apply its own ordered target statistics
        # instead of re-consuming the target/frequency encodings above.
        cat_native_cols = num_cols_ext + cat_cols
        X_cat_native = X[cat_native_cols].copy()
        X_test_cat_native = X_test[cat_native_cols].copy()
        for c in num_cols_ext:
            X_cat_native[c] = X_cat_native[c].fillna(0.0)
            X_test_cat_native[c] = X_test_cat_native[c].fillna(0.0)
        cat_feature_idx = [cat_native_cols.index(c) for c in cat_cols]

        feature_sets = {
            "scaled": (X_scaled, X_test_scaled),
            "enc": (X_enc, X_test_enc),
            "cat_native": (X_cat_native, X_test_cat_native),
        }
        oof, test_pred = {}, {}

        for name, factory, feat in build_model_specs(cat_feature_idx):
            # CatBoost is the slowest candidate; only start it with ample
            # headroom so it cannot begin and then be cut off mid-folds, which
            # would register a partial (artificially low) OOF score and make the
            # selector discard a model that would actually have won.
            min_time = 60 if name == "cat" else 15
            if time_left() < min_time:
                print(f"time budget low, skipping remaining models (stopped before {name})")
                if name == "cat":
                    continue
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
        # Select among the sklearn models exactly as the proven v9 package did
        # (bare argmax), then let CatBoost displace the winner only if it clears
        # CATBOOST_MARGIN. This keeps the new candidate strictly opt-in.
        sklearn_aucs = {k: v for k, v in aucs.items() if k != "cat"}
        if sklearn_aucs:
            best_name = max(sklearn_aucs, key=sklearn_aucs.get)
            if "cat" in aucs:
                gap = aucs["cat"] - sklearn_aucs[best_name]
                if gap >= CATBOOST_MARGIN:
                    print(
                        f"catboost clears margin (+{gap:.5f} >= {CATBOOST_MARGIN}); "
                        f"promoting it over {best_name}"
                    )
                    best_name = "cat"
                else:
                    print(
                        f"catboost gap +{gap:.5f} < margin {CATBOOST_MARGIN}; "
                        f"keeping sklearn winner {best_name} "
                        "(guards against a noise-driven out-of-fold win)"
                    )
        else:
            # Only CatBoost survived; use it rather than failing outright.
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
