#!/usr/bin/env python3
"""Inspect fresh ARC-GEN cases where donor NeuroGolf models fail."""

from __future__ import annotations

import argparse
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=pathlib.Path, required=True)
    parser.add_argument("--donor", type=pathlib.Path, required=True)
    parser.add_argument("--task", type=int, required=True)
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--indices", type=int, nargs="+", required=True)
    parser.add_argument("--generator-root", type=pathlib.Path, default=DEFAULT_GENERATOR_ROOT)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    return parser.parse_args()


def load_generators(generator_root: pathlib.Path):
    sys.path.insert(0, str(generator_root.resolve()))
    task_list = importlib.import_module("task_list")
    common = importlib.import_module("common")
    generators = task_list.task_list()
    task_ids = list(generators)[:400]
    return generators, task_ids, common


def active_bbox(mask: np.ndarray) -> list[int] | None:
    ys, xs = np.where(mask)
    if len(ys) == 0:
        return None
    return [int(ys.min()), int(xs.min()), int(ys.max()), int(xs.max())]


def grid_summary(grid: np.ndarray) -> dict[str, object]:
    values, counts = np.unique(grid, return_counts=True)
    return {
        "shape": list(map(int, grid.shape)),
        "colors": {str(int(v)): int(c) for v, c in zip(values, counts, strict=True)},
        "nonzero_bbox": active_bbox(grid != 0),
    }


def as_grid(array: np.ndarray) -> np.ndarray:
    if array.ndim == 4 and array.shape[1] == 10:
        return np.argmax(array[0], axis=0).astype(np.int64)
    if array.ndim == 2:
        return array.astype(np.int64)
    raise ValueError(f"unexpected array shape {array.shape}")


def main() -> None:
    args = parse_args()
    generators, task_ids, common = load_generators(args.generator_root)
    arc_id = task_ids[args.task - 1]
    generator, _ = generators[arc_id]

    base_model = sanitize_model(load_task_model(args.base, args.task))
    donor_model = sanitize_model(load_task_model(args.donor, args.task))
    if base_model is None or donor_model is None:
        raise RuntimeError("model sanitization failed")
    base_session = make_session(base_model)
    donor_session = make_session(donor_model)

    rows = []
    for index in args.indices:
        common.set_colors(list(range(10)))
        random.seed(args.seed + args.task * 100_000 + index)
        example = generator()
        converted = convert_to_numpy(example)
        if converted is None:
            rows.append({"index": index, "status": "oversize"})
            continue
        base_output, base_error = run_one(base_session, converted["input"])
        donor_output, donor_error = run_one(donor_session, converted["input"])
        expected = converted["output"] > 0
        base_prediction = None if base_output is None else base_output > 0
        donor_prediction = None if donor_output is None else donor_output > 0
        input_grid = as_grid(converted["input"])
        expected_grid = as_grid(converted["output"])
        base_grid = None if base_output is None else as_grid(base_output)
        donor_grid = None if donor_output is None else as_grid(donor_output)
        row = {
            "task": f"task{args.task:03d}",
            "arc_id": arc_id,
            "index": index,
            "input": input_grid.tolist(),
            "expected": expected_grid.tolist(),
            "base": None if base_grid is None else base_grid.tolist(),
            "donor": None if donor_grid is None else donor_grid.tolist(),
            "input_summary": grid_summary(input_grid),
            "expected_summary": grid_summary(expected_grid),
            "base_error": base_error,
            "donor_error": donor_error,
            "base_correct": bool(base_prediction is not None and np.array_equal(base_prediction, expected)),
            "donor_correct": bool(donor_prediction is not None and np.array_equal(donor_prediction, expected)),
            "base_diff_cells": None if base_prediction is None else int(np.count_nonzero(base_prediction != expected)),
            "donor_diff_cells": None if donor_prediction is None else int(np.count_nonzero(donor_prediction != expected)),
            "base_donor_diff_cells": None
            if base_prediction is None or donor_prediction is None
            else int(np.count_nonzero(base_prediction != donor_prediction)),
        }
        if donor_prediction is not None:
            row["donor_false_positive_bbox"] = active_bbox(np.logical_and(donor_grid != 0, expected_grid == 0))
            row["donor_false_negative_bbox"] = active_bbox(np.logical_and(donor_grid == 0, expected_grid != 0))
        rows.append(row)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(rows, indent=2) + "\n")
    print(json.dumps({"out": str(args.out), "rows": len(rows)}, indent=2))


if __name__ == "__main__":
    main()
