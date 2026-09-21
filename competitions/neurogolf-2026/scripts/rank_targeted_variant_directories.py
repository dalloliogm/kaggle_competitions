#!/usr/bin/env python3
"""Rank task-named NeuroGolf variant directories against a base bundle."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import pathlib
import tempfile

from rank_bundle_variants import read_bundle, try_score


WORKSPACE = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_OUT_DIR = WORKSPACE / "references" / "analysis" / "bundle-variant-rankings"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=pathlib.Path, required=True)
    parser.add_argument("--variants-root", type=pathlib.Path, required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    base = read_bundle(args.base)
    variant_dirs = sorted(
        path
        for path in args.variants_root.iterdir()
        if path.is_dir()
        and path.name.startswith("task")
        and path.name.removeprefix("task").isdigit()
    )
    if not variant_dirs:
        raise ValueError(f"no task-named directories under {args.variants_root}")

    rows: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="neurogolf-targeted-rank-") as tmp:
        tmp_dir = pathlib.Path(tmp)
        for source_path in variant_dirs:
            task = int(source_path.name.removeprefix("task"))
            task_name = f"task{task:03d}.onnx"
            source = read_bundle(source_path)
            base_raw = base[task_name]
            variant_raw = source[task_name]
            base_score, base_error = try_score(
                base_raw, task, tmp_dir, f"{task_name}_base"
            )
            variant_score, variant_error = try_score(
                variant_raw, task, tmp_dir, f"{task_name}_variant"
            )
            row: dict[str, object] = {
                "task": f"task{task:03d}",
                "task_number": task,
                "different": base_raw != variant_raw,
                "base_bytes": len(base_raw),
                "variant_bytes": len(variant_raw),
                "byte_delta": len(variant_raw) - len(base_raw),
                "base_sha256": hashlib.sha256(base_raw).hexdigest(),
                "variant_sha256": hashlib.sha256(variant_raw).hexdigest(),
                "source_path": str(source_path),
                "base_error": base_error,
                "variant_error": variant_error,
            }
            if base_raw == variant_raw:
                row["classification"] = "identical"
            elif base_score is not None and variant_score is not None:
                row.update(
                    {
                        "base_cost": base_score.cost,
                        "base_points": base_score.points,
                        "variant_cost": variant_score.cost,
                        "variant_points": variant_score.points,
                        "cost_delta": variant_score.cost - base_score.cost,
                        "point_delta": variant_score.points - base_score.points,
                    }
                )
                if variant_score.cost < base_score.cost:
                    row["classification"] = "cost-positive"
                elif variant_score.cost == base_score.cost:
                    row["classification"] = "cost-neutral"
                else:
                    row["classification"] = "cost-negative"
            elif base_score is None and variant_score is not None:
                row["classification"] = "base-unscorable"
            elif base_score is not None and variant_score is None:
                row["classification"] = "variant-unscorable"
            else:
                row["classification"] = "both-unscorable"
            rows.append(row)
            print(f"[{task:03d}] {row['classification']}", flush=True)

    rows.sort(
        key=lambda row: float(row.get("point_delta", float("-inf"))),
        reverse=True,
    )
    args.out_dir.mkdir(parents=True, exist_ok=True)
    stem = f"{args.label}-targeted-vs-base"
    csv_path = args.out_dir / f"{stem}.csv"
    json_path = args.out_dir / f"{stem}.json"
    fieldnames = sorted({key for row in rows for key in row})
    with csv_path.open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    json_path.write_text(json.dumps(rows, indent=2) + "\n")

    counts: dict[str, int] = {}
    for row in rows:
        classification = str(row["classification"])
        counts[classification] = counts.get(classification, 0) + 1
    summary = {
        "variant_directories": len(variant_dirs),
        "counts": counts,
        "projected_point_delta": sum(
            float(row.get("point_delta") or 0)
            for row in rows
            if row["classification"] == "cost-positive"
        ),
        "positive_tasks": [
            row["task"] for row in rows if row["classification"] == "cost-positive"
        ],
        "csv": str(csv_path),
        "json": str(json_path),
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
