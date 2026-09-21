#!/usr/bin/env python3
"""Build a NeuroGolf bundle from selected rows in a variant ranking."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import zipfile


TASK_NAMES = {f"task{task:03d}.onnx" for task in range(1, 401)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=pathlib.Path, required=True)
    parser.add_argument("--ranking", type=pathlib.Path, required=True)
    parser.add_argument(
        "--donor",
        type=pathlib.Path,
        help="Fallback donor archive for single-donor ranking rows.",
    )
    parser.add_argument("--tasks", type=int, nargs="+")
    parser.add_argument("--classification", default="cost-positive")
    parser.add_argument("--output", type=pathlib.Path, required=True)
    return parser.parse_args()


def read_bundle(path: pathlib.Path, require_all: bool = True) -> dict[str, bytes]:
    payloads: dict[str, bytes] = {}
    if path.is_dir():
        payloads = {
            model_path.name: model_path.read_bytes()
            for model_path in path.glob("task*.onnx")
            if model_path.name in TASK_NAMES
        }
    else:
        with zipfile.ZipFile(path) as archive:
            bad = archive.testzip()
            if bad:
                raise ValueError(f"CRC failure in {path}: {bad}")
            for member in archive.namelist():
                name = pathlib.PurePosixPath(member).name
                if name not in TASK_NAMES:
                    continue
                if name in payloads:
                    raise ValueError(f"duplicate canonical task name in {path}: {name}")
                payloads[name] = archive.read(member)
    if require_all and set(payloads) != TASK_NAMES:
        raise ValueError(f"expected 400 canonical task models in {path}")
    if not payloads or not set(payloads).issubset(TASK_NAMES):
        raise ValueError(f"archive contains noncanonical or no task models: {path}")
    return payloads


def task_number(row: dict[str, object]) -> int:
    if "task_number" in row:
        return int(row["task_number"])
    return int(str(row["task"]).removeprefix("task").removesuffix(".onnx"))


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    paths = sorted(path.glob("task*.onnx")) if path.is_dir() else [path]
    for item in paths:
        if path.is_dir():
            digest.update(item.name.encode())
        with item.open("rb") as file:
            for chunk in iter(lambda: file.read(1024 * 1024), b""):
                digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    args = parse_args()
    base = read_bundle(args.base)
    rows = json.loads(args.ranking.read_text())
    selected_tasks = set(args.tasks or [])
    eligible = [
        row
        for row in rows
        if row["classification"] == args.classification
        and (not selected_tasks or task_number(row) in selected_tasks)
    ]
    if not eligible:
        raise ValueError("no ranking rows matched the requested selection")

    best_by_task: dict[int, dict[str, object]] = {}
    for row in eligible:
        task = task_number(row)
        if task not in best_by_task or float(row.get("point_delta", float("-inf"))) > float(
            best_by_task[task].get("point_delta", float("-inf"))
        ):
            best_by_task[task] = row
    if selected_tasks and set(best_by_task) != selected_tasks:
        missing = sorted(selected_tasks - set(best_by_task))
        raise ValueError(f"no eligible ranking row for tasks: {missing}")

    manifest_rows = []
    source_cache: dict[pathlib.Path, dict[str, bytes]] = {}
    for task, row in sorted(best_by_task.items()):
        task_name = f"task{task:03d}.onnx"
        source_value = row.get("source_path") or args.donor
        if source_value is None:
            raise ValueError(f"no donor source for {task_name}")
        source_path = pathlib.Path(str(source_value))
        if source_path not in source_cache:
            source_cache[source_path] = read_bundle(source_path, require_all=False)
        source = source_cache[source_path]
        if task_name not in source:
            raise ValueError(f"{task_name} missing from donor {source_path}")
        raw = source[task_name]
        digest = hashlib.sha256(raw).hexdigest()
        expected_digest = row.get("variant_sha256") or row.get("donor_sha256")
        if digest != expected_digest:
            raise ValueError(f"ranking/source digest mismatch for {task_name}")
        base[task_name] = raw
        manifest_rows.append(
            {
                "task": task_name,
                "source": str(source_path),
                "source_sha256": sha256(source_path),
                "variant_sha256": digest,
                "classification": row["classification"],
                "cost_delta": row.get("cost_delta"),
                "point_delta": row.get("point_delta"),
            }
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(
        args.output,
        "w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as archive:
        for name in sorted(base):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, base[name])

    read_bundle(args.output)
    manifest = {
        "base": str(args.base),
        "base_sha256": sha256(args.base),
        "ranking": str(args.ranking),
        "selection": manifest_rows,
        "projected_point_delta": sum(float(row.get("point_delta") or 0) for row in manifest_rows),
        "output": str(args.output),
        "output_sha256": sha256(args.output),
    }
    manifest_path = args.output.with_name("manifest.json")
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
