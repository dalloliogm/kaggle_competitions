#!/usr/bin/env python3
"""Build a small NeuroGolf submission from validated color-map tasks."""

from __future__ import annotations

import json
import math
import pathlib
import shutil
import sys
import zipfile

import numpy as np
import onnx
import onnxruntime


WORKSPACE = pathlib.Path(__file__).resolve().parents[1]
DATA_DIR = WORKSPACE / "data"
UTILS_DIR = DATA_DIR / "neurogolf_utils"
OUT_DIR = WORKSPACE / "submissions" / "color-map-baseline"
NETWORK_DIR = OUT_DIR / "networks"
ZIP_PATH = OUT_DIR / "submission.zip"

sys.path.insert(0, str(UTILS_DIR))
import neurogolf_utils as ng  # noqa: E402


TASK_COLOR_MAPS: dict[int, dict[int, int]] = {
    # All four mappings were inferred from train + test + arc-gen examples and
    # validated below before inclusion in the zip.
    16: {0: 0, 1: 5, 2: 6, 3: 4, 4: 3, 5: 1, 6: 2, 7: 7, 8: 9, 9: 8},
    276: {0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 2, 7: 7, 8: 8, 9: 9},
    309: {0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 5, 8: 8, 9: 9},
    337: {0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 8, 6: 6, 7: 7, 8: 5, 9: 9},
}


def make_color_map_network(color_map: dict[int, int]) -> onnx.ModelProto:
    def weight(channel_out: int, channel_in: int, kernel_coord: tuple[int, int]) -> float:
        if kernel_coord != (0, 0):
            return 0.0
        return 1.0 if color_map.get(channel_in, channel_in) == channel_out else 0.0

    return ng.single_layer_conv2d_network(weight, kernel_size=1)


def load_examples(task_num: int) -> dict[str, list[dict[str, list[list[int]]]]]:
    with (DATA_DIR / f"task{task_num:03d}.json").open() as f:
        return json.load(f)


def run_model(model: onnx.ModelProto, benchmark_input: np.ndarray) -> np.ndarray:
    options = onnxruntime.SessionOptions()
    options.graph_optimization_level = onnxruntime.GraphOptimizationLevel.ORT_DISABLE_ALL
    session = onnxruntime.InferenceSession(model.SerializeToString(), options)
    return ng.run_network(session, benchmark_input)


def validate_model(model: onnx.ModelProto, task_num: int) -> tuple[int, int]:
    examples = load_examples(task_num)
    right = 0
    wrong = 0
    for subset_name in ("train", "test", "arc-gen"):
        for example in examples[subset_name]:
            benchmark = ng.convert_to_numpy(example)
            if benchmark is None:
                continue
            actual = run_model(model, benchmark["input"])
            if np.array_equal(actual, benchmark["output"]):
                right += 1
            else:
                wrong += 1
    return right, wrong


def validate_schema(zip_path: pathlib.Path, expected_tasks: set[int]) -> None:
    with zipfile.ZipFile(zip_path) as zf:
        names = sorted(zf.namelist())
    expected_names = [f"task{task_num:03d}.onnx" for task_num in sorted(expected_tasks)]
    if names != expected_names:
        raise RuntimeError(f"Unexpected zip entries: {names}")
    for name in names:
        if "/" in name:
            raise RuntimeError(f"Zip entry must be at archive root: {name}")


def main() -> int:
    if OUT_DIR.exists():
        shutil.rmtree(OUT_DIR)
    NETWORK_DIR.mkdir(parents=True, exist_ok=True)

    included: list[tuple[int, int]] = []
    for task_num, color_map in sorted(TASK_COLOR_MAPS.items()):
        model = make_color_map_network(color_map)
        right, wrong = validate_model(model, task_num)
        if wrong:
            print(f"task{task_num:03d}: skipped, {right} pass / {wrong} fail")
            continue
        path = NETWORK_DIR / f"task{task_num:03d}.onnx"
        onnx.save(model, path)
        if not ng.check_network(path):
            raise RuntimeError(f"Generated network failed file checks: {path}")
        file_size = path.stat().st_size
        included.append((task_num, right))
        print(f"task{task_num:03d}: included, {right} examples pass, {file_size} bytes")

    if not included:
        raise RuntimeError("No validated networks were generated.")

    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for task_num, _ in included:
            onnx_path = NETWORK_DIR / f"task{task_num:03d}.onnx"
            zf.write(onnx_path, arcname=onnx_path.name)

    validate_schema(ZIP_PATH, {task_num for task_num, _ in included})
    manifest = {
        "zip": str(ZIP_PATH.relative_to(WORKSPACE)),
        "tasks": [
            {"task": f"task{task_num:03d}", "validated_examples": examples}
            for task_num, examples in included
        ],
        "note": "Manual Kaggle upload only; not submitted by this script.",
    }
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

    task_names = ", ".join(f"task{task_num:03d}" for task_num, _ in included)
    print()
    print(f"Created {ZIP_PATH}")
    print(f"Included {len(included)} validated ONNX networks: {task_names}")
    print(f"Approximate zip size: {math.ceil(ZIP_PATH.stat().st_size / 1024)} KiB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
