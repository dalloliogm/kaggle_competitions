#!/usr/bin/env python3
"""Compare base and donor NeuroGolf models on matched fresh ARC-GEN examples."""

from __future__ import annotations

import argparse
import csv
import importlib
import json
import pathlib
import random
import sys

import numpy as np

from audit_public_variants import load_task_model, run_one
from exact_rewrite_toolchain import convert_to_numpy, make_session, sanitize_model


WORKSPACE = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_GENERATOR_ROOT = WORKSPACE / "references" / "public-generators" / "google-ARC-GEN"
DEFAULT_OUT_DIR = WORKSPACE / "references" / "analysis" / "repair-diagnostics"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=pathlib.Path, required=True)
    parser.add_argument("--donor", type=pathlib.Path, required=True)
    parser.add_argument("--tasks", type=int, nargs="+", required=True)
    parser.add_argument("--examples", type=int, default=256)
    parser.add_argument("--seed", type=int, default=20_260_715)
    parser.add_argument("--label", required=True)
    parser.add_argument("--generator-root", type=pathlib.Path, default=DEFAULT_GENERATOR_ROOT)
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    return parser.parse_args()


def load_generators(generator_root: pathlib.Path):
    if not (generator_root / "task_list.py").is_file():
        raise FileNotFoundError(f"ARC-GEN not found at {generator_root}")
    sys.path.insert(0, str(generator_root.resolve()))
    task_list = importlib.import_module("task_list")
    common = importlib.import_module("common")
    generators = task_list.task_list()
    task_ids = list(generators)[:400]
    if len(task_ids) != 400 or task_ids[0] != "007bbfb7" or task_ids[5] != "0520fde7":
        raise ValueError("ARC-GEN v1 task order does not match NeuroGolf numbering")
    return generators, task_ids, common


def compare_task(
    base: pathlib.Path,
    donor: pathlib.Path,
    task: int,
    examples: int,
    seed: int,
    generators,
    task_ids: list[str],
    common,
) -> dict[str, object]:
    task_name = f"task{task:03d}"
    arc_id = task_ids[task - 1]
    generator, _ = generators[arc_id]

    base_model = sanitize_model(load_task_model(base, task))
    donor_model = sanitize_model(load_task_model(donor, task))
    if base_model is None or donor_model is None:
        return {
            "task": task_name,
            "arc_id": arc_id,
            "requested": examples,
            "generated": 0,
            "classification": "sanitize-failed",
            "first_issue": "model sanitization failed",
        }

    base_session = make_session(base_model)
    donor_session = make_session(donor_model)

    counts = {
        "both_correct": 0,
        "base_only": 0,
        "donor_only": 0,
        "both_wrong_same": 0,
        "both_wrong_diff": 0,
        "base_runtime": 0,
        "donor_runtime": 0,
        "both_runtime": 0,
        "oversize_skipped": 0,
        "generator_failures": 0,
    }
    generated = 0
    first_issue = ""
    issue_indices: list[int] = []

    for index in range(examples):
        common.set_colors(list(range(10)))
        random.seed(seed + task * 100_000 + index)
        try:
            example = generator()
        except Exception as exc:
            counts["generator_failures"] += 1
            if not first_issue:
                first_issue = f"generator example {index}: {type(exc).__name__}: {exc}"
            continue
        converted = convert_to_numpy(example)
        if converted is None:
            counts["oversize_skipped"] += 1
            continue

        generated += 1
        expected = converted["output"] > 0
        base_output, base_error = run_one(base_session, converted["input"])
        donor_output, donor_error = run_one(donor_session, converted["input"])
        if base_error and donor_error:
            counts["both_runtime"] += 1
            issue_indices.append(index)
            if not first_issue:
                first_issue = f"example {index}: base={base_error}; donor={donor_error}"
            continue
        if base_error:
            counts["base_runtime"] += 1
            issue_indices.append(index)
            if not first_issue:
                first_issue = f"example {index}: base={base_error}"
            continue
        if donor_error:
            counts["donor_runtime"] += 1
            issue_indices.append(index)
            if not first_issue:
                first_issue = f"example {index}: donor={donor_error}"
            continue

        assert base_output is not None and donor_output is not None
        base_prediction = base_output > 0
        donor_prediction = donor_output > 0
        base_correct = bool(np.array_equal(base_prediction, expected))
        donor_correct = bool(np.array_equal(donor_prediction, expected))
        if base_correct and donor_correct:
            counts["both_correct"] += 1
        elif base_correct:
            counts["base_only"] += 1
            issue_indices.append(index)
            if not first_issue:
                diff = int(np.count_nonzero(donor_prediction != expected))
                first_issue = f"example {index}: base-only correct, donor differs by {diff} cells"
        elif donor_correct:
            counts["donor_only"] += 1
            issue_indices.append(index)
            if not first_issue:
                diff = int(np.count_nonzero(base_prediction != expected))
                first_issue = f"example {index}: donor-only correct, base differs by {diff} cells"
        elif np.array_equal(base_prediction, donor_prediction):
            counts["both_wrong_same"] += 1
            issue_indices.append(index)
            if not first_issue:
                diff = int(np.count_nonzero(base_prediction != expected))
                first_issue = f"example {index}: both wrong same, differ by {diff} cells"
        else:
            counts["both_wrong_diff"] += 1
            issue_indices.append(index)
            if not first_issue:
                base_diff = int(np.count_nonzero(base_prediction != expected))
                donor_diff = int(np.count_nonzero(donor_prediction != expected))
                first_issue = (
                    f"example {index}: both wrong diff, base={base_diff} donor={donor_diff}"
                )

    runtime_failures = counts["base_runtime"] + counts["donor_runtime"] + counts["both_runtime"]
    if generated == 0 or runtime_failures:
        classification = "runtime-or-empty"
    elif counts["base_only"] == 0 and counts["donor_only"] == 0 and counts["both_wrong_diff"] == 0:
        classification = "no-regression"
    elif counts["donor_only"] > counts["base_only"]:
        classification = "net-positive-risk"
    elif counts["donor_only"] == counts["base_only"] and counts["base_only"] > 0:
        classification = "mixed-neutral-risk"
    else:
        classification = "net-negative-risk"

    row: dict[str, object] = {
        "task": task_name,
        "arc_id": arc_id,
        "requested": examples,
        "generated": generated,
        **counts,
        "net_correct": counts["donor_only"] - counts["base_only"],
        "classification": classification,
        "first_issue": first_issue,
        "issue_indices": json.dumps(issue_indices[:50]),
    }
    return row


def main() -> None:
    args = parse_args()
    generators, task_ids, common = load_generators(args.generator_root)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    task_label = "-".join(f"{task:03d}" for task in args.tasks)
    if len(task_label) > 80:
        task_label = f"{len(args.tasks)}tasks"
    stem = f"{args.label}-fresh-compare-{args.examples}x-{task_label}"
    csv_path = args.out_dir / f"{stem}.csv"
    json_path = args.out_dir / f"{stem}.json"

    rows = []
    for task in args.tasks:
        row = compare_task(
            base=args.base,
            donor=args.donor,
            task=task,
            examples=args.examples,
            seed=args.seed,
            generators=generators,
            task_ids=task_ids,
            common=common,
        )
        rows.append(row)
        with csv_path.open("w", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
        json_path.write_text(json.dumps(rows, indent=2) + "\n")
        print(json.dumps(row), flush=True)

    summary = {
        "csv": str(csv_path),
        "json": str(json_path),
        "tasks": len(rows),
        "net_positive": [
            row["task"] for row in rows if row["classification"] == "net-positive-risk"
        ],
        "no_regression": [row["task"] for row in rows if row["classification"] == "no-regression"],
        "rows": rows,
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
