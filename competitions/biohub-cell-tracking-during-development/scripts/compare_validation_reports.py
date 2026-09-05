#!/usr/bin/env python3
"""Compare Biohub per-dataset validation reports against an incumbent.

The reports may be JSON files emitted by ``biohub_validation_harness.py`` or
CSV files containing one row per dataset with an ``adjusted_edge_jaccard``
column. The script deliberately reports regressions, spread, and worst-case
performance rather than ranking candidates by pooled mean alone.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import pandas as pd


SCORE_COLUMNS = ("adjusted_edge_jaccard", "proxy_score", "score")


def load_rows(path: Path) -> pd.DataFrame:
    if path.suffix.lower() == ".csv":
        frame = pd.read_csv(path)
    else:
        payload = json.loads(path.read_text())
        if "metric_summary" in payload and payload["metric_summary"]:
            metric = payload["metric_summary"]
            rows = metric.get("rows", [])
        elif "rows" in payload:
            rows = payload["rows"]
        else:
            rows = payload if isinstance(payload, list) else []
        frame = pd.DataFrame(rows)
    if "dataset" not in frame.columns:
        for candidate in ("stem", "sample", "movie"):
            if candidate in frame.columns:
                frame = frame.rename(columns={candidate: "dataset"})
                break
    score = next((column for column in SCORE_COLUMNS if column in frame.columns), None)
    if score is None:
        raise ValueError(f"{path}: no score column found among {SCORE_COLUMNS}")
    if "dataset" not in frame.columns:
        raise ValueError(f"{path}: no dataset column")
    return frame[["dataset", score]].rename(columns={score: "score"}).assign(source=str(path))


def compare(incumbent: Path, candidates: list[Path]) -> dict:
    base = load_rows(incumbent).rename(columns={"score": "incumbent_score"})
    results = []
    for candidate in candidates:
        current = load_rows(candidate).rename(columns={"score": "candidate_score"})
        merged = base.merge(current, on="dataset", how="outer", indicator=True)
        missing = merged.loc[merged["_merge"] != "both", "dataset"].dropna().tolist()
        paired = merged[merged["_merge"] == "both"].copy()
        paired["delta"] = paired["candidate_score"] - paired["incumbent_score"]
        deltas = paired["delta"]
        results.append({
            "candidate": str(candidate),
            "datasets_compared": int(len(paired)),
            "datasets_missing_from_either_report": missing,
            "mean_delta": float(deltas.mean()) if len(deltas) else None,
            "median_delta": float(deltas.median()) if len(deltas) else None,
            "std_delta": float(deltas.std(ddof=0)) if len(deltas) else None,
            "worst_delta": float(deltas.min()) if len(deltas) else None,
            "best_delta": float(deltas.max()) if len(deltas) else None,
            "regressions": int((deltas < 0).sum()),
            "improvements": int((deltas > 0).sum()),
            "ties": int((deltas == 0).sum()),
            "candidate_mean": float(paired["candidate_score"].mean()) if len(paired) else None,
            "incumbent_mean": float(paired["incumbent_score"].mean()) if len(paired) else None,
        })
    return {"incumbent": str(incumbent), "results": results}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--incumbent", required=True, type=Path)
    parser.add_argument("candidates", nargs="+", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = compare(args.incumbent, args.candidates)
    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(text)
    print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
