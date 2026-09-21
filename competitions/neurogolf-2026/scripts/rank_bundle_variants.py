#!/usr/bin/env python3
"""Rank donor NeuroGolf task models by scorer delta against a base bundle."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import pathlib
import tempfile
import zipfile

import onnx

from exact_rewrite_toolchain import examples_for_task, score_model


WORKSPACE = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_OUT_DIR = WORKSPACE / "references" / "analysis" / "bundle-variant-rankings"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=pathlib.Path, required=True)
    parser.add_argument("--donor", type=pathlib.Path, required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    parser.add_argument(
        "--allow-partial-donor",
        action="store_true",
        help="Rank only canonical task models present in a partial donor archive.",
    )
    return parser.parse_args()


def read_bundle(path: pathlib.Path, require_all: bool = True) -> dict[str, bytes]:
    if path.is_dir():
        payloads = {
            model_path.name: model_path.read_bytes()
            for model_path in path.glob("task*.onnx")
        }
    else:
        with zipfile.ZipFile(path) as archive:
            bad = archive.testzip()
            if bad:
                raise ValueError(f"CRC failure in {path}: {bad}")
            payloads = {
                pathlib.PurePosixPath(member).name: archive.read(member)
                for member in archive.namelist()
                if pathlib.PurePosixPath(member).name.startswith("task")
                and pathlib.PurePosixPath(member).name.endswith(".onnx")
            }
    expected = {f"task{task:03d}.onnx" for task in range(1, 401)}
    if require_all and set(payloads) != expected:
        raise ValueError(f"expected 400 canonical task models in {path}")
    if not payloads or not set(payloads).issubset(expected):
        raise ValueError(f"donor contains noncanonical or no task models: {path}")
    return payloads


def try_score(raw: bytes, task: int, tmp_dir: pathlib.Path, prefix: str):
    try:
        model = onnx.load_model_from_string(raw)
        score = score_model(model, examples_for_task(task)[:1], tmp_dir, prefix)
        return score, ""
    except Exception as exc:
        return None, f"{type(exc).__name__}: {exc}"


def main() -> None:
    args = parse_args()
    base = read_bundle(args.base)
    donor = read_bundle(args.donor, require_all=not args.allow_partial_donor)
    rows = []
    with tempfile.TemporaryDirectory(prefix="neurogolf-rank-") as tmp:
        tmp_dir = pathlib.Path(tmp)
        for task in range(1, 401):
            name = f"task{task:03d}.onnx"
            if name not in donor:
                continue
            base_raw = base[name]
            donor_raw = donor[name]
            row: dict[str, object] = {
                "task": f"task{task:03d}",
                "different": base_raw != donor_raw,
                "base_bytes": len(base_raw),
                "donor_bytes": len(donor_raw),
                "byte_delta": len(donor_raw) - len(base_raw),
                "base_sha256": hashlib.sha256(base_raw).hexdigest(),
                "donor_sha256": hashlib.sha256(donor_raw).hexdigest(),
            }
            if base_raw == donor_raw:
                row["classification"] = "identical"
                rows.append(row)
                continue

            base_score, base_error = try_score(base_raw, task, tmp_dir, f"{name}_base")
            donor_score, donor_error = try_score(donor_raw, task, tmp_dir, f"{name}_donor")
            row["base_error"] = base_error
            row["donor_error"] = donor_error
            if base_score is not None:
                row.update(
                    {
                        "base_memory": base_score.memory,
                        "base_params": base_score.params,
                        "base_cost": base_score.cost,
                        "base_points": base_score.points,
                    }
                )
            if donor_score is not None:
                row.update(
                    {
                        "donor_memory": donor_score.memory,
                        "donor_params": donor_score.params,
                        "donor_cost": donor_score.cost,
                        "donor_points": donor_score.points,
                    }
                )

            if base_score is not None and donor_score is not None:
                row["cost_delta"] = donor_score.cost - base_score.cost
                row["point_delta"] = donor_score.points - base_score.points
                if donor_score.cost < base_score.cost:
                    row["classification"] = "cost-positive"
                elif donor_score.cost == base_score.cost:
                    row["classification"] = "cost-neutral"
                else:
                    row["classification"] = "cost-negative"
            elif base_score is None and donor_score is not None:
                row["classification"] = "base-unscorable"
            elif base_score is not None and donor_score is None:
                row["classification"] = "donor-unscorable"
            else:
                row["classification"] = "both-unscorable"
            rows.append(row)
            print(f"[{task:03d}] {row['classification']}", flush=True)

    rows.sort(key=lambda row: float(row.get("point_delta", float("-inf"))), reverse=True)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    stem = f"{args.label}-vs-base"
    csv_path = args.out_dir / f"{stem}.csv"
    json_path = args.out_dir / f"{stem}.json"
    fieldnames = sorted({key for row in rows for key in row})
    with csv_path.open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    with json_path.open("w") as file:
        json.dump(rows, file, indent=2)

    counts: dict[str, int] = {}
    for row in rows:
        key = str(row["classification"])
        counts[key] = counts.get(key, 0) + 1
    summary = {
        "csv": str(csv_path),
        "json": str(json_path),
        "counts": counts,
        "positive_tasks": [row["task"] for row in rows if row["classification"] == "cost-positive"],
        "base_unscorable_tasks": [
            row["task"] for row in rows if row["classification"] == "base-unscorable"
        ],
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
