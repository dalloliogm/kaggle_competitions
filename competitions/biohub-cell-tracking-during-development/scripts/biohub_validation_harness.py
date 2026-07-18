#!/usr/bin/env python3
"""Validation harness for Biohub Cell Tracking submissions.

This script is intentionally dependency-light for structural checks and
diagnostics. Exact metric scoring is optional and runs only when the Kaggle
competition data plus the Biohub tracking package are available.

Typical usage:

    python scripts/biohub_validation_harness.py \
      --submission /kaggle/working/submission.csv \
      --train-dir /kaggle/input/competitions/biohub-cell-tracking-during-development/train \
      --out-dir /kaggle/working/validation

For local output-only checks:

    python scripts/biohub_validation_harness.py \
      --submission kaggle_outputs/biohub-exp107-density-gain-0475/submission.csv \
      --out-dir /tmp/biohub-validation
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from collections import defaultdict, deque
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import pandas as pd


SUBMISSION_COLUMNS = [
    "id",
    "dataset",
    "row_type",
    "node_id",
    "t",
    "z",
    "y",
    "x",
    "source_id",
    "target_id",
]

NODE_SENTINELS = {
    "source_id": -1,
    "target_id": -1,
}

EDGE_SENTINELS = {
    "node_id": -1,
    "t": -1,
    "z": -1,
    "y": -1,
    "x": -1,
}


@dataclass
class DatasetDiagnostics:
    dataset: str
    nodes: int
    edges: int
    components: int
    largest_component: int
    p95_component: float
    max_indegree: int
    max_outdegree: int
    division_like_sources: int
    min_t: int | None
    max_t: int | None
    node_id_min: int | None
    node_id_max: int | None
    duplicate_frame_pairs_exact: int | None = None
    duplicate_frame_pair_indices: str | None = None


@dataclass
class ValidationReport:
    submission: str
    rows: int
    nodes: int
    edges: int
    datasets: int
    valid: bool
    errors: list[str]
    warnings: list[str]
    diagnostics: list[DatasetDiagnostics]
    metric_summary: dict[str, Any] | None = None


def _fail(errors: list[str], message: str) -> None:
    errors.append(message)


def load_submission(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(path)
    return pd.read_csv(path)


def validate_schema(df: pd.DataFrame, errors: list[str], warnings: list[str]) -> None:
    if list(df.columns) != SUBMISSION_COLUMNS:
        _fail(errors, f"columns mismatch: got {list(df.columns)!r}")
        return
    if df.empty:
        _fail(errors, "submission is empty")
    missing = int(df.isna().sum().sum())
    if missing:
        _fail(errors, f"submission contains {missing} missing values")
    if not df["id"].is_unique:
        _fail(errors, "global row id values are not unique")
    if len(df) and int(df["id"].min()) != 0:
        warnings.append(f"row id minimum is {int(df['id'].min())}, expected 0")
    if len(df) and int(df["id"].max()) != len(df) - 1:
        warnings.append(
            f"row id maximum is {int(df['id'].max())}, expected {len(df) - 1}"
        )
    bad_row_type = sorted(set(df["row_type"]) - {"node", "edge"})
    if bad_row_type:
        _fail(errors, f"unexpected row_type values: {bad_row_type!r}")


def _percentile(values: list[int], q: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    pos = (len(ordered) - 1) * q
    lo = int(math.floor(pos))
    hi = int(math.ceil(pos))
    if lo == hi:
        return float(ordered[lo])
    return float(ordered[lo] * (hi - pos) + ordered[hi] * (pos - lo))


def validate_dataset_group(
    dataset: str,
    group: pd.DataFrame,
    errors: list[str],
    warnings: list[str],
) -> DatasetDiagnostics:
    nodes = group[group["row_type"] == "node"].copy()
    edges = group[group["row_type"] == "edge"].copy()

    if nodes.empty:
        _fail(errors, f"{dataset}: no node rows")
    if edges.empty:
        warnings.append(f"{dataset}: no edge rows")

    for col, expected in NODE_SENTINELS.items():
        bad = int((nodes[col].astype(int) != expected).sum())
        if bad:
            _fail(errors, f"{dataset}: {bad} node rows have non-sentinel {col}")
    for col, expected in EDGE_SENTINELS.items():
        bad = int((edges[col].astype(int) != expected).sum())
        if bad:
            _fail(errors, f"{dataset}: {bad} edge rows have non-sentinel {col}")

    node_ids = nodes["node_id"].astype(int)
    node_keys = set(node_ids.tolist())
    if len(node_keys) != len(nodes):
        _fail(errors, f"{dataset}: node_id values are not unique within dataset")

    tmap = {
        int(row.node_id): int(row.t)
        for row in nodes[["node_id", "t"]].itertuples(index=False)
    }
    missing_source = 0
    missing_target = 0
    bad_dt = 0
    duplicate_edges = 0
    edge_keys: set[tuple[int, int]] = set()
    outdeg: dict[int, int] = defaultdict(int)
    indeg: dict[int, int] = defaultdict(int)
    adjacency: dict[int, list[int]] = defaultdict(list)

    for row in edges[["source_id", "target_id"]].itertuples(index=False):
        source = int(row.source_id)
        target = int(row.target_id)
        if source not in node_keys:
            missing_source += 1
            continue
        if target not in node_keys:
            missing_target += 1
            continue
        if (source, target) in edge_keys:
            duplicate_edges += 1
        edge_keys.add((source, target))
        if tmap[target] - tmap[source] != 1:
            bad_dt += 1
        outdeg[source] += 1
        indeg[target] += 1
        adjacency[source].append(target)
        adjacency[target].append(source)

    if missing_source:
        _fail(errors, f"{dataset}: {missing_source} edges have missing source nodes")
    if missing_target:
        _fail(errors, f"{dataset}: {missing_target} edges have missing target nodes")
    if bad_dt:
        _fail(errors, f"{dataset}: {bad_dt} edges do not connect consecutive frames")
    if duplicate_edges:
        _fail(errors, f"{dataset}: {duplicate_edges} duplicate directed edges")

    max_indegree = max(indeg.values()) if indeg else 0
    max_outdegree = max(outdeg.values()) if outdeg else 0
    if max_indegree > 1:
        _fail(errors, f"{dataset}: max indegree is {max_indegree}, expected <= 1")
    if max_outdegree > 2:
        _fail(errors, f"{dataset}: max outdegree is {max_outdegree}, expected <= 2")

    seen: set[int] = set()
    component_sizes: list[int] = []
    for node_id in node_keys:
        if node_id in seen:
            continue
        queue = deque([node_id])
        seen.add(node_id)
        size = 0
        while queue:
            current = queue.popleft()
            size += 1
            for nxt in adjacency.get(current, []):
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        component_sizes.append(size)

    largest_component = max(component_sizes) if component_sizes else 0
    if largest_component > 500:
        warnings.append(
            f"{dataset}: largest weak component has {largest_component} nodes; "
            "large components can slow scoring"
        )

    t_values = nodes["t"].astype(int) if not nodes.empty else pd.Series(dtype=int)
    return DatasetDiagnostics(
        dataset=dataset,
        nodes=int(len(nodes)),
        edges=int(len(edges)),
        components=int(len(component_sizes)),
        largest_component=int(largest_component),
        p95_component=_percentile(component_sizes, 0.95),
        max_indegree=int(max_indegree),
        max_outdegree=int(max_outdegree),
        division_like_sources=int(sum(1 for value in outdeg.values() if value >= 2)),
        min_t=int(t_values.min()) if not t_values.empty else None,
        max_t=int(t_values.max()) if not t_values.empty else None,
        node_id_min=int(node_ids.min()) if not nodes.empty else None,
        node_id_max=int(node_ids.max()) if not nodes.empty else None,
    )


def structural_report(df: pd.DataFrame, submission_path: Path) -> ValidationReport:
    errors: list[str] = []
    warnings: list[str] = []
    validate_schema(df, errors, warnings)
    diagnostics: list[DatasetDiagnostics] = []
    if list(df.columns) == SUBMISSION_COLUMNS:
        for dataset, group in df.groupby("dataset", sort=True):
            diagnostics.append(validate_dataset_group(str(dataset), group, errors, warnings))
    nodes = int((df["row_type"] == "node").sum()) if "row_type" in df else 0
    edges = int((df["row_type"] == "edge").sum()) if "row_type" in df else 0
    datasets = int(df["dataset"].nunique()) if "dataset" in df else 0
    return ValidationReport(
        submission=str(submission_path),
        rows=int(len(df)),
        nodes=nodes,
        edges=edges,
        datasets=datasets,
        valid=not errors,
        errors=errors,
        warnings=warnings,
        diagnostics=diagnostics,
    )


def add_duplicate_frame_diagnostics(
    report: ValidationReport,
    data_dir: Path | None,
    max_pairs: int = 25,
) -> None:
    """Add exact duplicated adjacent-frame counts when zarr arrays are readable.

    This is deliberately optional. It works on Kaggle with zarr installed and
    silently records a warning when the image data cannot be opened.
    """
    if data_dir is None:
        return
    try:
        import numpy as np
        import zarr
    except Exception as exc:  # pragma: no cover - environment dependent
        report.warnings.append(f"duplicate-frame diagnostics skipped: {exc}")
        return

    by_dataset = {diag.dataset: diag for diag in report.diagnostics}
    for dataset, diag in by_dataset.items():
        path = data_dir / f"{dataset}.zarr"
        if not path.exists():
            continue
        try:
            arr = zarr.open(path, mode="r")
            if hasattr(arr, "keys") and "0" in arr:
                arr = arr["0"]
            duplicate_indices: list[int] = []
            for t in range(int(arr.shape[0]) - 1):
                if np.array_equal(np.asarray(arr[t]), np.asarray(arr[t + 1])):
                    duplicate_indices.append(t)
            diag.duplicate_frame_pairs_exact = len(duplicate_indices)
            diag.duplicate_frame_pair_indices = ",".join(
                str(x) for x in duplicate_indices[:max_pairs]
            )
        except Exception as exc:  # pragma: no cover - environment dependent
            report.warnings.append(f"{dataset}: duplicate-frame diagnostics failed: {exc}")


def try_exact_metric(
    df: pd.DataFrame,
    train_dir: Path | None,
    tracking_repo: Path | None,
    max_datasets: int | None,
) -> dict[str, Any] | None:
    """Run official-style metric scoring when dependencies/data are available."""
    if train_dir is None:
        return None
    if tracking_repo is not None:
        sys.path.insert(0, str(tracking_repo / "src"))
    try:
        import polars as pl
        import traccuracy as td
        from biohub_tracking.io import graph_from_geff
        from biohub_tracking.metrics import evaluate, node_recall, per_sample_metrics, summarise
    except Exception as exc:  # pragma: no cover - environment dependent
        return {"skipped": True, "reason": f"metric dependencies unavailable: {exc}"}

    voxel_scale_um = (1.625, 0.40625, 0.40625)
    default_keys = td.DEFAULT_ATTR_KEYS

    def estimated_nodes_from_geff(path: Path) -> float:
        try:
            metadata = json.loads((path / "zarr.json").read_text())
        except Exception:
            return float("nan")

        def search(value: Any) -> Any:
            if isinstance(value, dict):
                if "estimated_number_of_nodes" in value:
                    return value["estimated_number_of_nodes"]
                for child in value.values():
                    result = search(child)
                    if result is not None:
                        return result
            return None

        result = search(metadata)
        return float(result) if result is not None else float("nan")

    def graph_from_submission_rows(dataset: str) -> Any:
        group = df[df["dataset"] == dataset]
        nodes = group[group["row_type"] == "node"].copy()
        edges = group[group["row_type"] == "edge"].copy()
        graph = td.graph.InMemoryGraph()
        for key in (default_keys.Z, default_keys.Y, default_keys.X):
            graph.add_node_attr_key(key, pl.Float64, 0.0)
        node_map = {}
        for row in nodes.itertuples(index=False):
            node_map[int(row.node_id)] = graph.add_node(
                {
                    default_keys.T: int(row.t),
                    default_keys.Z: float(row.z),
                    default_keys.Y: float(row.y),
                    default_keys.X: float(row.x),
                }
            )
        for row in edges.itertuples(index=False):
            source_id = int(row.source_id)
            target_id = int(row.target_id)
            if source_id in node_map and target_id in node_map:
                graph.add_edge(node_map[source_id], node_map[target_id], {})
        return graph

    rows: list[dict[str, Any]] = []
    datasets = sorted(str(x) for x in df["dataset"].unique())
    if max_datasets is not None:
        datasets = datasets[:max_datasets]
    for dataset in datasets:
        truth_path = train_dir / f"{dataset}.geff"
        if not truth_path.exists():
            continue
        pred_graph = graph_from_submission_rows(dataset)
        truth_graph = graph_from_geff(truth_path)
        result = evaluate(pred_graph, truth_graph, scale=voxel_scale_um, max_distance=7.0)
        recall = node_recall(pred_graph, truth_graph)
        row = {
            "dataset": dataset,
            "embryo": dataset.split("_")[0],
            **per_sample_metrics(result, estimated_nodes_from_geff(truth_path), recall),
            "num_pred_edges": int(
                (df["dataset"].eq(dataset) & df["row_type"].eq("edge")).sum()
            ),
        }
        rows.append(row)

    if not rows:
        return {"skipped": True, "reason": "no submission datasets had matching train GEFF"}
    return {"skipped": False, "rows": rows, "summary": summarise(rows)}


def write_outputs(report: ValidationReport, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    report_dict = asdict(report)
    (out_dir / "validation_report.json").write_text(
        json.dumps(report_dict, indent=2, sort_keys=True)
    )
    pd.DataFrame([asdict(x) for x in report.diagnostics]).to_csv(
        out_dir / "dataset_diagnostics.csv", index=False
    )
    if report.metric_summary and not report.metric_summary.get("skipped", False):
        pd.DataFrame(report.metric_summary["rows"]).to_csv(
            out_dir / "metric_rows.csv", index=False
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--submission", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--train-dir", type=Path)
    parser.add_argument("--image-dir", type=Path)
    parser.add_argument("--tracking-repo", type=Path)
    parser.add_argument("--metric-max-datasets", type=int)
    parser.add_argument(
        "--skip-metric",
        action="store_true",
        help="Run only schema/graph/image diagnostics.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    df = load_submission(args.submission)
    report = structural_report(df, args.submission)
    add_duplicate_frame_diagnostics(report, args.image_dir)
    if not args.skip_metric:
        report.metric_summary = try_exact_metric(
            df=df,
            train_dir=args.train_dir,
            tracking_repo=args.tracking_repo,
            max_datasets=args.metric_max_datasets,
        )
    write_outputs(report, args.out_dir)

    print(json.dumps(asdict(report), indent=2, sort_keys=True))
    return 0 if report.valid else 2


if __name__ == "__main__":
    raise SystemExit(main())
