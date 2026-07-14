#!/usr/bin/env python3
"""Audit public NeuroGolf task variants against the current best bundle."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import pathlib
import tempfile
import zipfile
from collections import Counter

import numpy as np
import onnx

from exact_rewrite_toolchain import (
    DEFAULT_BASE_ZIP,
    examples_for_task,
    make_session,
    random_inputs_for_task,
    sanitize_model,
    score_model,
)


WORKSPACE = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_OUT_DIR = WORKSPACE / "submissions" / "public-variant-audits"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-zip", type=pathlib.Path, default=DEFAULT_BASE_ZIP)
    parser.add_argument("--donor-zip", type=pathlib.Path, required=True)
    parser.add_argument("--donor-label", required=True)
    parser.add_argument("--tasks", type=int, nargs="+", required=True)
    parser.add_argument("--random-trials", type=int, default=32)
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    return parser.parse_args()


def load_task_model(bundle: pathlib.Path, task: int) -> onnx.ModelProto:
    suffix = f"task{task:03d}.onnx"
    with zipfile.ZipFile(bundle) as archive:
        matches = [name for name in archive.namelist() if name == suffix or name.endswith(f"/{suffix}")]
        if not matches:
            raise FileNotFoundError(f"{suffix} not found in {bundle}")
        if len(matches) > 1:
            raise ValueError(f"multiple copies of {suffix} found in {bundle}: {matches}")
        return onnx.load_model_from_string(archive.read(matches[0]))


def model_summary(model: onnx.ModelProto) -> dict[str, object]:
    serialized = model.SerializeToString()
    op_counts = Counter(node.op_type for node in model.graph.node)
    return {
        "bytes": len(serialized),
        "nodes": len(model.graph.node),
        "initializers": len(model.graph.initializer),
        "top_ops": ";".join(f"{op}:{count}" for op, count in op_counts.most_common(8)),
    }


def run_one(session, item: np.ndarray) -> tuple[np.ndarray | None, str | None]:
    try:
        return session.run(["output"], {"input": item})[0], None
    except Exception as exc:  # ONNX variants can encode task-specific shape assumptions.
        return None, f"{type(exc).__name__}: {exc}"


def audit_task(
    base_zip: pathlib.Path,
    donor_zip: pathlib.Path,
    donor_label: str,
    task: int,
    random_trials: int,
) -> dict[str, object]:
    task_name = f"task{task:03d}"
    base = load_task_model(base_zip, task)
    donor = load_task_model(donor_zip, task)
    base_info = model_summary(base)
    donor_info = model_summary(donor)
    examples = examples_for_task(task)

    row: dict[str, object] = {
        "task": task_name,
        "donor": donor_label,
        "base_zip": str(base_zip),
        "donor_zip": str(donor_zip),
        "example_count": len(examples),
        "random_trials": random_trials,
        **{f"base_{key}": value for key, value in base_info.items()},
        **{f"donor_{key}": value for key, value in donor_info.items()},
    }

    sanitized_base = sanitize_model(base)
    sanitized_donor = sanitize_model(donor)
    if sanitized_base is None or sanitized_donor is None:
        row.update({"classification": "sanitize-failed", "message": "model sanitization failed"})
        return row

    try:
        with tempfile.TemporaryDirectory(prefix=f"neurogolf-{task_name}-") as tmp:
            tmp_dir = pathlib.Path(tmp)
            base_score = score_model(base, examples[:1], tmp_dir, f"{task_name}_base")
            donor_score = score_model(donor, examples[:1], tmp_dir, f"{task_name}_donor")
        row.update(
            {
                "base_memory": base_score.memory,
                "base_params": base_score.params,
                "base_cost": base_score.cost,
                "donor_memory": donor_score.memory,
                "donor_params": donor_score.params,
                "donor_cost": donor_score.cost,
                "cost_delta": donor_score.cost - base_score.cost,
                "point_delta": donor_score.points - base_score.points,
            }
        )
    except Exception as exc:
        row.update(
            {
                "base_cost": "",
                "donor_cost": "",
                "cost_delta": "",
                "point_delta": "",
                "scoring_error": f"{type(exc).__name__}: {exc}",
            }
        )

    try:
        base_session = make_session(sanitized_base)
        donor_session = make_session(sanitized_donor)
    except Exception as exc:
        row.update({"classification": "runtime-failed", "message": f"session creation failed: {exc}"})
        return row

    example_raw_equal = 0
    example_threshold_equal = 0
    base_correct = 0
    donor_correct = 0
    example_asymmetric_failures = 0
    example_symmetric_failures = 0
    first_example_mismatch = ""
    for index, example in enumerate(examples):
        base_output, base_error = run_one(base_session, example["input"])
        donor_output, donor_error = run_one(donor_session, example["input"])
        if base_error or donor_error:
            if bool(base_error) == bool(donor_error):
                example_symmetric_failures += 1
            else:
                example_asymmetric_failures += 1
            if not first_example_mismatch:
                first_example_mismatch = f"example {index}: base={base_error}; donor={donor_error}"
            continue
        assert base_output is not None and donor_output is not None
        expected = example["output"] > 0
        base_prediction = base_output > 0
        donor_prediction = donor_output > 0
        raw_equal = np.array_equal(base_output, donor_output)
        threshold_equal = np.array_equal(base_prediction, donor_prediction)
        example_raw_equal += int(raw_equal)
        example_threshold_equal += int(threshold_equal)
        base_correct += int(np.array_equal(base_prediction, expected))
        donor_correct += int(np.array_equal(donor_prediction, expected))
        if not threshold_equal and not first_example_mismatch:
            disagreement = int(np.count_nonzero(base_prediction != donor_prediction))
            first_example_mismatch = f"example {index}: {disagreement} thresholded cells differ"

    random_raw_equal = 0
    random_threshold_equal = 0
    random_asymmetric_failures = 0
    random_symmetric_failures = 0
    first_random_mismatch = ""
    for index, item in enumerate(random_inputs_for_task(task, random_trials)):
        base_output, base_error = run_one(base_session, item)
        donor_output, donor_error = run_one(donor_session, item)
        if base_error or donor_error:
            if bool(base_error) == bool(donor_error):
                random_symmetric_failures += 1
            else:
                random_asymmetric_failures += 1
            if not first_random_mismatch:
                first_random_mismatch = f"random {index}: base={base_error}; donor={donor_error}"
            continue
        assert base_output is not None and donor_output is not None
        raw_equal = np.array_equal(base_output, donor_output)
        threshold_equal = np.array_equal(base_output > 0, donor_output > 0)
        random_raw_equal += int(raw_equal)
        random_threshold_equal += int(threshold_equal)
        if not threshold_equal and not first_random_mismatch:
            disagreement = int(np.count_nonzero((base_output > 0) != (donor_output > 0)))
            first_random_mismatch = f"random {index}: {disagreement} thresholded cells differ"

    row.update(
        {
            "example_raw_equal": example_raw_equal,
            "example_threshold_equal": example_threshold_equal,
            "base_correct": base_correct,
            "donor_correct": donor_correct,
            "example_asymmetric_failures": example_asymmetric_failures,
            "example_symmetric_failures": example_symmetric_failures,
            "random_raw_equal": random_raw_equal,
            "random_threshold_equal": random_threshold_equal,
            "random_asymmetric_failures": random_asymmetric_failures,
            "random_symmetric_failures": random_symmetric_failures,
            "first_example_mismatch": first_example_mismatch,
            "first_random_mismatch": first_random_mismatch,
        }
    )

    all_examples_run = example_asymmetric_failures == 0 and example_symmetric_failures == 0
    all_random_run = random_asymmetric_failures == 0 and random_symmetric_failures == 0
    if donor_correct != len(examples) or not all_examples_run:
        classification = "wrong-visible"
    elif example_raw_equal == len(examples) and random_raw_equal == random_trials and all_random_run:
        classification = "exact"
    elif (
        example_threshold_equal == len(examples)
        and random_threshold_equal == random_trials
        and all_random_run
    ):
        classification = "threshold-equivalent"
    else:
        classification = "example-only"
    row["classification"] = classification
    cost_delta = row.get("cost_delta")
    if classification not in {"exact", "threshold-equivalent"}:
        recommendation = "reject: functional evidence is insufficient"
    elif not isinstance(cost_delta, (int, float)):
        recommendation = "hold: scorer comparison unavailable"
    elif cost_delta < 0:
        recommendation = "stack: functionally validated and scorer improves"
    else:
        recommendation = "reject: functionally valid but scorer does not improve"
    row["message"] = recommendation
    return row


def main() -> None:
    args = parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    rows = [
        audit_task(
            base_zip=args.base_zip,
            donor_zip=args.donor_zip,
            donor_label=args.donor_label,
            task=task,
            random_trials=args.random_trials,
        )
        for task in args.tasks
    ]
    task_stem = "-".join(f"task{task:03d}" for task in args.tasks)
    stem = f"{args.donor_label}-{task_stem}"
    if len(stem) > 120:
        task_digest = hashlib.sha256(task_stem.encode("ascii")).hexdigest()[:12]
        stem = f"{args.donor_label}-{len(args.tasks)}tasks-{task_digest}"
    csv_path = args.out_dir / f"{stem}.csv"
    json_path = args.out_dir / f"{stem}.json"
    fieldnames = sorted({key for row in rows for key in row})
    with csv_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    with json_path.open("w") as f:
        json.dump(rows, f, indent=2)
    print(json.dumps({"csv": str(csv_path), "json": str(json_path), "rows": rows}, indent=2))


if __name__ == "__main__":
    main()
