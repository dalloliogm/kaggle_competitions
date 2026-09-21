from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.metrics import roc_auc_score


DATA_ROOT = Path("/tmp/autonomous-agent-replay/extracted/data")
REPLAY_ROOT = Path("/tmp/aap-v12-replay-20260731")


def read_manifest(task_dir: Path) -> dict:
    prefix = "PORTFOLIO_MANIFEST="
    if not (task_dir / "portfolio.log").exists() and task_dir.name == "train_13":
        # The pilot printed to the terminal before logging was enabled.
        return {}
    for line in reversed((task_dir / "portfolio.log").read_text().splitlines()):
        if line.startswith(prefix):
            return json.loads(line[len(prefix) :])
    raise RuntimeError(f"manifest missing for {task_dir.name}")


def safe_auc(y_true: pd.Series, y_score: pd.Series) -> float:
    if y_true.nunique() != 2:
        return float("nan")
    return float(roc_auc_score(y_true, y_score))


rows: list[dict] = []
for source_dir in sorted(DATA_ROOT.glob("train_*")):
    task = source_dir.name
    task_dir = REPLAY_ROOT / task
    solution = pd.read_csv(source_dir / "solution.csv")
    sample = pd.read_csv(source_dir / "sample_submission.csv")
    id_col, target_col = sample.columns[:2]

    manifest = read_manifest(task_dir)
    cv_by_kind = {
        item["kind"]: float(item["cv_auc"])
        for item in manifest.get("candidate_metrics", [])
    }
    runtime = manifest.get("total_seconds", np.nan)

    candidates = [task_dir / "quick_baseline.csv"]
    candidates.extend(sorted(task_dir.glob("portfolio_*.csv")))
    for candidate_path in candidates:
        prediction = pd.read_csv(candidate_path)
        if list(prediction.columns) != list(sample.columns):
            raise ValueError(
                f"{task}/{candidate_path.name}: columns {prediction.columns.tolist()} "
                f"!= sample {sample.columns.tolist()}"
            )
        if len(prediction) != len(sample):
            raise ValueError(f"{task}/{candidate_path.name}: wrong row count")
        if not prediction[id_col].equals(sample[id_col]):
            raise ValueError(f"{task}/{candidate_path.name}: IDs differ from sample order")
        values = prediction[target_col].to_numpy(dtype=float)
        if not np.isfinite(values).all():
            raise ValueError(f"{task}/{candidate_path.name}: non-finite predictions")

        joined = solution[[id_col, target_col, "Usage"]].merge(
            prediction[[id_col, target_col]],
            on=id_col,
            how="inner",
            validate="one_to_one",
            suffixes=("_truth", "_prediction"),
        )
        if len(joined) != len(solution):
            raise ValueError(f"{task}/{candidate_path.name}: incomplete ID join")

        stem = candidate_path.stem
        kind = "quick" if stem == "quick_baseline" else stem.removeprefix("portfolio_")
        public = joined["Usage"].eq("Public")
        private = joined["Usage"].eq("Private")
        rows.append(
            {
                "task": task,
                "candidate": kind,
                "cv_auc": cv_by_kind.get(kind, np.nan),
                "full_auc": safe_auc(joined[f"{target_col}_truth"], joined[f"{target_col}_prediction"]),
                "public_auc": safe_auc(
                    joined.loc[public, f"{target_col}_truth"],
                    joined.loc[public, f"{target_col}_prediction"],
                ),
                "private_auc": safe_auc(
                    joined.loc[private, f"{target_col}_truth"],
                    joined.loc[private, f"{target_col}_prediction"],
                ),
                "portfolio_seconds": runtime,
                "rows": len(solution),
            }
        )

long = pd.DataFrame(rows).sort_values(["task", "candidate"])
long.to_csv(REPLAY_ROOT / "candidate_scores.csv", index=False)

selected_rows: list[dict] = []
for task, group in long.groupby("task", sort=True):
    public_order = group.sort_values(
        ["public_auc", "candidate"], ascending=[False, True]
    ).reset_index(drop=True)
    public_top1 = public_order.iloc[0]
    public_top2 = public_order.iloc[:2]
    oracle = group.loc[group["full_auc"].idxmax()]
    robust = group.loc[group["candidate"].eq("rank_all")].iloc[0]
    top2_private_best = public_top2.loc[public_top2["private_auc"].idxmax()]
    selected_rows.append(
        {
            "task": task,
            "public_selected_candidate": public_top1["candidate"],
            "selected_public_auc": public_top1["public_auc"],
            "selected_private_auc": public_top1["private_auc"],
            "selected_full_auc": public_top1["full_auc"],
            "public_top2_candidates": "|".join(public_top2["candidate"]),
            "top2_best_private_candidate": top2_private_best["candidate"],
            "top2_best_private_auc": top2_private_best["private_auc"],
            "top2_mean_private_auc": public_top2["private_auc"].mean(),
            "rank_all_full_auc": robust["full_auc"],
            "rank_all_private_auc": robust["private_auc"],
            "oracle_full_candidate": oracle["candidate"],
            "oracle_full_auc": oracle["full_auc"],
            "portfolio_seconds": group["portfolio_seconds"].dropna().max()
            if group["portfolio_seconds"].notna().any()
            else np.nan,
        }
    )

selected = pd.DataFrame(selected_rows)
selected.to_csv(REPLAY_ROOT / "selection_summary.csv", index=False)

candidate_means = (
    long.groupby("candidate")[["full_auc", "public_auc", "private_auc"]]
    .agg(["mean", "std"])
    .sort_values(("full_auc", "mean"), ascending=False)
)
candidate_means.to_csv(REPLAY_ROOT / "candidate_means.csv")

print("CANDIDATE MEANS")
print(candidate_means.to_string(float_format=lambda value: f"{value:.6f}"))
print("\nPUBLIC-SELECTION SUMMARY")
print(
    selected[
        [
            "task",
            "public_selected_candidate",
            "selected_public_auc",
            "selected_private_auc",
            "selected_full_auc",
            "rank_all_full_auc",
            "oracle_full_auc",
            "portfolio_seconds",
        ]
    ].to_string(index=False, float_format=lambda value: f"{value:.6f}")
)
print("\nAGGREGATES")
for column in [
    "selected_public_auc",
    "selected_private_auc",
    "selected_full_auc",
    "top2_best_private_auc",
    "top2_mean_private_auc",
    "rank_all_full_auc",
    "rank_all_private_auc",
    "oracle_full_auc",
]:
    print(f"{column}={selected[column].mean():.9f}")
print(f"portfolio_seconds_total={selected['portfolio_seconds'].sum():.3f}")
print(f"portfolio_seconds_max={selected['portfolio_seconds'].max():.3f}")
