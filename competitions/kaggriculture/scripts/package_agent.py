#!/usr/bin/env python3
"""Create a deterministic one-file Kaggriculture submission archive."""

from __future__ import annotations

import argparse
import ast
import gzip
import hashlib
import io
import json
from pathlib import Path
import tarfile


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--source-url", required=True)
    parser.add_argument("--source-version", required=True)
    parser.add_argument("--verified-score", type=float, required=True)
    args = parser.parse_args()

    source = args.source.read_bytes()
    source_text = source.decode("utf-8")
    compile(source_text, "main.py", "exec")
    tree = ast.parse(source_text)
    if not any(isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == "agent" for node in tree.body):
        raise SystemExit("source does not define a top-level agent function")

    raw_tar = io.BytesIO()
    with tarfile.open(fileobj=raw_tar, mode="w") as archive:
        info = tarfile.TarInfo("main.py")
        info.size = len(source)
        info.mode = 0o644
        info.mtime = 0
        info.uid = info.gid = 0
        info.uname = info.gname = ""
        archive.addfile(info, io.BytesIO(source))

    args.output.mkdir(parents=True, exist_ok=True)
    copied_main = args.output / "main.py"
    copied_main.write_bytes(source)
    archive_path = args.output / "submission.tar.gz"
    with archive_path.open("wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as compressed:
            compressed.write(raw_tar.getvalue())

    with tarfile.open(archive_path, "r:gz") as archive:
        if archive.getnames() != ["main.py"]:
            raise SystemExit(f"invalid archive members: {archive.getnames()}")
        if archive.extractfile("main.py").read() != source:
            raise SystemExit("archived main.py differs from source")

    manifest = {
        "artifact": "submission.tar.gz",
        "archive_members": ["main.py"],
        "archive_sha256": hashlib.sha256(archive_path.read_bytes()).hexdigest(),
        "main_py_sha256": hashlib.sha256(source).hexdigest(),
        "source_url": args.source_url,
        "source_version": args.source_version,
        "verified_public_score": args.verified_score,
        "score_checked_on": "2026-09-07",
        "environment": "kaggle-environments==1.32.7",
        "submission_status": "prepared locally; not uploaded",
    }
    (args.output / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
