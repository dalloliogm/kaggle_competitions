#!/usr/bin/env python3
"""Build a NeuroGolf bundle by replacing selected base tasks from a donor."""

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
    parser.add_argument("--donor", type=pathlib.Path, required=True)
    parser.add_argument("--tasks", type=int, nargs="+", required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    return parser.parse_args()


def read_bundle(path: pathlib.Path) -> dict[str, bytes]:
    with zipfile.ZipFile(path) as archive:
        bad = archive.testzip()
        if bad:
            raise ValueError(f"CRC failure in {path}: {bad}")
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError(f"duplicate archive names in {path}")
        payloads = {
            name: archive.read(name)
            for name in names
            if name in TASK_NAMES and "/" not in name
        }
    if set(payloads) != TASK_NAMES:
        missing = sorted(TASK_NAMES - set(payloads))
        raise ValueError(f"expected 400 root task files in {path}; missing {missing[:5]}")
    return payloads


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    args = parse_args()
    base = read_bundle(args.base)
    donor = read_bundle(args.donor)
    task_names = [f"task{task:03d}.onnx" for task in args.tasks]
    if len(task_names) != len(set(task_names)):
        raise ValueError("tasks must be unique")
    for task_name in task_names:
        base[task_name] = donor[task_name]

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
        "donor": str(args.donor),
        "donor_sha256": sha256(args.donor),
        "tasks": task_names,
        "output": str(args.output),
        "output_sha256": sha256(args.output),
    }
    manifest_path = args.output.with_name("manifest.json")
    with manifest_path.open("w") as file:
        json.dump(manifest, file, indent=2)
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
