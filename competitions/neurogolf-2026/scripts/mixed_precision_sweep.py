#!/usr/bin/env python3
"""Find competition-compatible float16 rewrites and build cumulative bundles."""

from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import json
import math
import pathlib
import tempfile
import zipfile

import numpy as np
import onnx
import onnxruntime
from onnxruntime.transformers.float16 import DEFAULT_OP_BLOCK_LIST, convert_float_to_float16

from exact_rewrite_toolchain import (
    calculate_memory,
    calculate_params,
    deterministic_zip_write,
    examples_for_task,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True, type=pathlib.Path)
    parser.add_argument("--inventory", required=True, type=pathlib.Path)
    parser.add_argument("--out-dir", required=True, type=pathlib.Path)
    return parser.parse_args()


def topological_sort(model: onnx.ModelProto) -> None:
    available = {item.name for item in model.graph.input}
    available.update(item.name for item in model.graph.initializer)
    remaining = list(model.graph.node)
    ordered = []
    while remaining:
        progressed = False
        for node in list(remaining):
            if all(not name or name in available for name in node.input):
                ordered.append(node)
                available.update(name for name in node.output if name)
                remaining.remove(node)
                progressed = True
        if not progressed:
            missing = sorted({name for node in remaining for name in node.input if name and name not in available})
            raise ValueError(f"cannot topologically sort; missing={missing[:5]}")
    del model.graph.node[:]
    model.graph.node.extend(ordered)


def session(model: onnx.ModelProto, profile: pathlib.Path | None = None) -> onnxruntime.InferenceSession:
    options = onnxruntime.SessionOptions()
    options.graph_optimization_level = onnxruntime.GraphOptimizationLevel.ORT_DISABLE_ALL
    if profile is not None:
        options.enable_profiling = True
        options.profile_file_prefix = str(profile)
    return onnxruntime.InferenceSession(model.SerializeToString(), options)


def score(model: onnx.ModelProto, profile: pathlib.Path, example: dict[str, np.ndarray]) -> tuple[int, float]:
    sess = session(model, profile)
    sess.run(["output"], {"input": example["input"]})
    trace = sess.end_profiling()
    memory = calculate_memory(model, trace)
    params = calculate_params(model)
    if memory is None or params is None:
        raise ValueError("candidate could not be scored")
    cost = memory + params
    return cost, max(1.0, 25.0 - math.log(cost))


def outputs_match(base: onnx.ModelProto, candidate: onnx.ModelProto, examples: list[dict[str, np.ndarray]]) -> bool:
    base_session = session(base)
    candidate_session = session(candidate)
    for example in examples:
        base_output = base_session.run(["output"], {"input": example["input"]})[0]
        candidate_output = candidate_session.run(["output"], {"input": example["input"]})[0]
        if not np.array_equal(base_output, candidate_output):
            return False
    return True


def convert(base: onnx.ModelProto, mode: str) -> onnx.ModelProto:
    candidate = copy.deepcopy(base)
    del candidate.graph.value_info[:]
    block_list = ["QLinearConv"]
    if mode == "conservative":
        block_list = list(DEFAULT_OP_BLOCK_LIST) + block_list
    candidate = convert_float_to_float16(
        candidate,
        keep_io_types=True,
        disable_shape_infer=True,
        op_block_list=block_list,
    )
    topological_sort(candidate)
    del candidate.graph.value_info[:]
    onnx.checker.check_model(candidate, full_check=True)
    return candidate


def load_costs(path: pathlib.Path) -> dict[str, int]:
    with path.open(newline="") as handle:
        return {row["task"]: int(row["estimated_cost"]) for row in csv.DictReader(handle)}


def main() -> None:
    args = parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    base_costs = load_costs(args.inventory)
    rows = []
    accepted: dict[str, bytes] = {}
    with zipfile.ZipFile(args.base) as archive, tempfile.TemporaryDirectory() as tmp:
        base_payloads = {name: archive.read(name) for name in archive.namelist() if name.endswith(".onnx")}
        tmp_dir = pathlib.Path(tmp)
        for index, name in enumerate(sorted(base_payloads), 1):
            task = name.removesuffix(".onnx")
            number = int(task.removeprefix("task"))
            examples = examples_for_task(number)
            base = onnx.load_from_string(base_payloads[name])
            best = None
            messages = []
            for mode in ("conservative", "aggressive"):
                try:
                    candidate = convert(base, mode)
                    candidate_cost, candidate_points = score(
                        candidate, tmp_dir / f"{task}_{mode}", examples[0]
                    )
                    base_cost = base_costs[task]
                    if candidate_cost >= base_cost:
                        messages.append(f"{mode}:cost={candidate_cost}")
                        continue
                    if not outputs_match(base, candidate, examples):
                        messages.append(f"{mode}:output-diff")
                        continue
                    base_points = max(1.0, 25.0 - math.log(base_cost))
                    result = {
                        "task": task,
                        "mode": mode,
                        "base_cost": base_cost,
                        "candidate_cost": candidate_cost,
                        "point_delta": candidate_points - base_points,
                        "examples": len(examples),
                        "bytes": len(candidate.SerializeToString()),
                    }
                    if best is None or result["point_delta"] > best[0]["point_delta"]:
                        best = (result, candidate.SerializeToString())
                except Exception as exc:
                    messages.append(f"{mode}:error={type(exc).__name__}:{exc}")
            if best is not None:
                rows.append(best[0])
                accepted[name] = best[1]
                print(f"[{index:03d}/400] ACCEPT {task} {best[0]['mode']} +{best[0]['point_delta']:.6f}", flush=True)
            elif index % 20 == 0:
                print(f"[{index:03d}/400] scanned; accepted={len(accepted)}", flush=True)

        rows.sort(key=lambda row: float(row["point_delta"]), reverse=True)
        cutoffs = {
            "precision-top10": rows[:10],
            "precision-positive": rows,
            "precision-tophalf": rows[: max(1, len(rows) // 2)],
        }
        outputs = []
        for label, selected in cutoffs.items():
            if not selected:
                continue
            payloads = dict(base_payloads)
            for row in selected:
                payloads[f"{row['task']}.onnx"] = accepted[f"{row['task']}.onnx"]
            out = args.out_dir / label / "submission.zip"
            out.parent.mkdir(parents=True, exist_ok=True)
            deterministic_zip_write(out, payloads)
            outputs.append(
                {
                    "label": label,
                    "zip": str(out),
                    "tasks": [row["task"] for row in selected],
                    "projected_delta": sum(float(row["point_delta"]) for row in selected),
                    "sha256": hashlib.sha256(out.read_bytes()).hexdigest(),
                }
            )

    report = {"base": str(args.base), "accepted": rows, "outputs": outputs}
    (args.out_dir / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
