#!/usr/bin/env python3
"""Validate NeuroGolf ONNX models on fresh examples from public ARC-GEN."""

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
DEFAULT_GENERATOR_ROOT = (
    WORKSPACE / "references" / "public-generators" / "google-ARC-GEN"
)
DEFAULT_OUT_DIR = WORKSPACE / "submissions" / "public-variant-audits"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=pathlib.Path, required=True)
    parser.add_argument("--label", required=True)
    task_source = parser.add_mutually_exclusive_group(required=True)
    task_source.add_argument("--tasks", type=int, nargs="+")
    task_source.add_argument(
        "--manifest",
        type=pathlib.Path,
        help="Read task names from a graft manifest's selection or tasks field.",
    )
    parser.add_argument("--examples", type=int, default=128)
    parser.add_argument("--seed", type=int, default=20_260_713)
    parser.add_argument("--generator-root", type=pathlib.Path, default=DEFAULT_GENERATOR_ROOT)
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    return parser.parse_args()


def selected_tasks(args: argparse.Namespace) -> list[int]:
    if args.tasks:
        return args.tasks
    manifest = json.loads(args.manifest.read_text())
    items = manifest.get("selection") or manifest.get("tasks")
    if not items:
        raise ValueError(f"manifest has no selected tasks: {args.manifest}")
    tasks = []
    for item in items:
        value = item["task"] if isinstance(item, dict) else item
        tasks.append(int(str(value).removeprefix("task").removesuffix(".onnx")))
    return tasks


def load_generators(generator_root: pathlib.Path):
    if not (generator_root / "task_list.py").is_file():
        raise FileNotFoundError(f"ARC-GEN not found at {generator_root}")
    sys.path.insert(0, str(generator_root))
    task_list = importlib.import_module("task_list")
    common = importlib.import_module("common")
    generators = task_list.task_list()
    task_ids = list(generators)[:400]
    if len(task_ids) != 400 or task_ids[0] != "007bbfb7" or task_ids[5] != "0520fde7":
        raise ValueError("ARC-GEN v1 task order does not match NeuroGolf numbering")
    return generators, task_ids, common


def validate_task(
    bundle: pathlib.Path,
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
    model = sanitize_model(load_task_model(bundle, task))
    if model is None:
        return {
            "task": task_name,
            "arc_id": arc_id,
            "requested": examples,
            "generated": 0,
            "correct": 0,
            "runtime_failures": 0,
            "oversize_skipped": 0,
            "classification": "model-invalid",
            "first_failure": "sanitize_model failed",
        }
    session = make_session(model)

    generated = 0
    correct = 0
    runtime_failures = 0
    generator_failures = 0
    oversize_skipped = 0
    first_failure = ""
    failure_indices: list[int] = []
    for index in range(examples):
        common.set_colors(list(range(10)))
        random.seed(seed + task * 100_000 + index)
        try:
            example = generator()
        except Exception as exc:
            generator_failures += 1
            if not first_failure:
                first_failure = f"generator example {index}: {type(exc).__name__}: {exc}"
            continue
        converted = convert_to_numpy(example)
        if converted is None:
            oversize_skipped += 1
            continue
        generated += 1
        actual, error = run_one(session, converted["input"])
        if error:
            runtime_failures += 1
            failure_indices.append(index)
            if not first_failure:
                first_failure = f"example {index}: {error}"
            continue
        assert actual is not None
        prediction = actual > 0
        expected = converted["output"] > 0
        if np.array_equal(prediction, expected):
            correct += 1
        elif not first_failure:
            failure_indices.append(index)
            differences = int(np.count_nonzero(prediction != expected))
            first_failure = f"example {index}: {differences} thresholded cells differ"
        else:
            failure_indices.append(index)

    classification = (
        "fresh-gen-pass"
        if generated > 0 and correct == generated and runtime_failures == 0
        else "fresh-gen-fail"
    )
    return {
        "task": task_name,
        "arc_id": arc_id,
        "requested": examples,
        "generated": generated,
        "correct": correct,
        "runtime_failures": runtime_failures,
        "generator_failures": generator_failures,
        "oversize_skipped": oversize_skipped,
        "classification": classification,
        "first_failure": first_failure,
        "failure_indices": json.dumps(failure_indices),
    }


def main() -> None:
    args = parse_args()
    tasks = selected_tasks(args)
    generators, task_ids, common = load_generators(args.generator_root.resolve())
    rows = [
        validate_task(
            bundle=args.bundle,
            task=task,
            examples=args.examples,
            seed=args.seed,
            generators=generators,
            task_ids=task_ids,
            common=common,
        )
        for task in tasks
    ]

    args.out_dir.mkdir(parents=True, exist_ok=True)
    task_label = "-".join(f"{task:03d}" for task in tasks)
    if len(task_label) > 80:
        task_label = f"{len(tasks)}tasks"
    stem = f"{args.label}-fresh-arc-gen-{args.examples}x-{task_label}"
    csv_path = args.out_dir / f"{stem}.csv"
    json_path = args.out_dir / f"{stem}.json"
    with csv_path.open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    with json_path.open("w") as file:
        json.dump(rows, file, indent=2)

    summary = {
        "csv": str(csv_path),
        "json": str(json_path),
        "tasks": len(rows),
        "passing": sum(row["classification"] == "fresh-gen-pass" for row in rows),
        "rows": rows,
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
