#!/usr/bin/env python3
"""Patch the compact lockbox task188 model with a safer square orientation test."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import tempfile
import zipfile

import numpy as np
import onnx
from onnx import TensorProto, helper, numpy_helper

from audit_public_variants import load_task_model
from exact_rewrite_toolchain import examples_for_task, score_model


TASK_NAMES = {f"task{task:03d}.onnx" for task in range(1, 401)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=pathlib.Path, required=True)
    parser.add_argument("--donor", type=pathlib.Path, required=True)
    parser.add_argument("--out-dir", type=pathlib.Path, required=True)
    return parser.parse_args()


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_bundle(path: pathlib.Path) -> dict[str, bytes]:
    with zipfile.ZipFile(path) as archive:
        bad = archive.testzip()
        if bad:
            raise ValueError(f"CRC failure in {path}: {bad}")
        payloads = {
            name: archive.read(name)
            for name in archive.namelist()
            if name in TASK_NAMES and "/" not in name
        }
    if set(payloads) != TASK_NAMES:
        raise ValueError(f"expected 400 root task files in {path}")
    return payloads


def patch_model(model: onnx.ModelProto) -> onnx.ModelProto:
    patched = onnx.ModelProto()
    patched.CopyFrom(model)

    def add_init(name: str, value: np.ndarray) -> None:
        existing = {init.name for init in patched.graph.initializer}
        if name in existing:
            return
        patched.graph.initializer.append(numpy_helper.from_array(value, name=name))

    add_init("patch_colorweight", np.arange(10, dtype=np.float32))
    rowbase4 = np.zeros(30, dtype=np.float32)
    rowbase4[:4] = np.array([1.0, 10.0, 100.0, 1000.0], dtype=np.float32)
    add_init("patch_rowbase4", rowbase4)
    colmask_02 = np.zeros(30, dtype=np.float32)
    colmask_02[0] = 1.0
    colmask_02[2] = -1.0
    add_init("patch_colmask_02", colmask_02)
    colmask_13 = np.zeros(30, dtype=np.float32)
    colmask_13[1] = 1.0
    colmask_13[3] = -1.0
    add_init("patch_colmask_13", colmask_13)
    add_init("patch_zero", np.array(0.0, dtype=np.float32))

    patch_nodes = [
        helper.make_node(
            "Einsum",
            ["input", "patch_colorweight", "patch_rowbase4", "patch_colmask_02"],
            ["patch_diff0"],
            equation="bchw,c,h,w->b",
        ),
        helper.make_node(
            "Einsum",
            ["input", "patch_colorweight", "patch_rowbase4", "patch_colmask_13"],
            ["patch_diff1"],
            equation="bchw,c,h,w->b",
        ),
        helper.make_node("Equal", ["patch_diff0", "patch_zero"], ["patch_eq0"]),
        helper.make_node("Equal", ["patch_diff1", "patch_zero"], ["patch_eq1"]),
        helper.make_node("And", ["patch_eq0", "patch_eq1"], ["patch_square_horizontal"]),
    ]

    nodes = list(patched.graph.node)
    square_node_index = next(
        index
        for index, node in enumerate(nodes)
        if node.op_type == "And" and list(node.output) == ["square_h"]
    )
    nodes[square_node_index].input[1] = "patch_square_horizontal"
    patched.graph.ClearField("node")
    patched.graph.node.extend(nodes[:square_node_index])
    patched.graph.node.extend(patch_nodes)
    patched.graph.node.extend(nodes[square_node_index:])
    onnx.checker.check_model(patched)
    return patched


def deterministic_zip_write(zip_path: pathlib.Path, payloads: dict[str, bytes]) -> None:
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in sorted(payloads):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, payloads[name])


def main() -> None:
    args = parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    donor_model = load_task_model(args.donor, 188)
    patched_model = patch_model(donor_model)
    base_model = load_task_model(args.base, 188)
    examples = examples_for_task(188)
    with tempfile.TemporaryDirectory(prefix="task188-patch-score-") as tmp:
        tmp_dir = pathlib.Path(tmp)
        base_score = score_model(base_model, examples[:1], tmp_dir, "base")
        patched_score = score_model(patched_model, examples[:1], tmp_dir, "patched")

    payloads = read_bundle(args.base)
    payloads["task188.onnx"] = patched_model.SerializeToString()
    zip_path = args.out_dir / "submission.zip"
    deterministic_zip_write(zip_path, payloads)

    manifest = {
        "base": str(args.base),
        "base_sha256": sha256(args.base),
        "donor": str(args.donor),
        "task": "task188",
        "base_cost": base_score.cost,
        "patched_cost": patched_score.cost,
        "cost_delta": patched_score.cost - base_score.cost,
        "point_delta": patched_score.points - base_score.points,
        "submission_zip": str(zip_path),
        "submission_sha256": sha256(zip_path),
    }
    (args.out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (args.out_dir / "task188.onnx").write_bytes(patched_model.SerializeToString())
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
