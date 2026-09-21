#!/usr/bin/env python3
"""Rank unique NeuroGolf task variants across canonical public archives."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import pathlib
import tempfile
import zipfile
from collections import defaultdict

import onnx

from exact_rewrite_toolchain import examples_for_task, score_model


WORKSPACE = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_SOURCES_ROOT = WORKSPACE / "references" / "public-kernels"
DEFAULT_OUT_DIR = WORKSPACE / "references" / "analysis" / "cross-source-rankings"
EXPECTED_NAMES = {f"task{task:03d}.onnx" for task in range(1, 401)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=pathlib.Path, required=True)
    parser.add_argument("--sources-root", type=pathlib.Path, default=DEFAULT_SOURCES_ROOT)
    parser.add_argument("--label", required=True)
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    return parser.parse_args()


def read_bundle(path: pathlib.Path) -> dict[str, bytes]:
    payloads: dict[str, bytes] = {}
    with zipfile.ZipFile(path) as archive:
        bad = archive.testzip()
        if bad:
            raise ValueError(f"CRC failure in {path}: {bad}")
        for member in archive.namelist():
            name = pathlib.PurePosixPath(member).name
            if name not in EXPECTED_NAMES:
                continue
            if name in payloads:
                raise ValueError(f"duplicate canonical task name in {path}: {name}")
            payloads[name] = archive.read(member)
    if set(payloads) != EXPECTED_NAMES:
        raise ValueError(f"expected 400 canonical task models in {path}")
    return payloads


def try_score(raw: bytes, task: int, tmp_dir: pathlib.Path, prefix: str):
    try:
        model = onnx.load_model_from_string(raw)
        score = score_model(model, examples_for_task(task)[:1], tmp_dir, prefix)
        return score, ""
    except Exception as exc:
        return None, f"{type(exc).__name__}: {exc}"


def main() -> None:
    args = parse_args()
    base_path = args.base.resolve()
    sources_root = args.sources_root.resolve()
    base = read_bundle(base_path)
    source_paths = sorted(sources_root.rglob("*.zip"))
    if not source_paths:
        raise ValueError(f"no source archives under {sources_root}")

    variants: dict[tuple[int, str], bytes] = {}
    variant_sources: dict[tuple[int, str], list[pathlib.Path]] = defaultdict(list)
    archive_errors: list[dict[str, str]] = []
    usable_archives = 0
    for source_path in source_paths:
        try:
            source = read_bundle(source_path)
        except Exception as exc:
            archive_errors.append({"path": str(source_path), "error": str(exc)})
            continue
        usable_archives += 1
        for task in range(1, 401):
            name = f"task{task:03d}.onnx"
            raw = source[name]
            if raw == base[name]:
                continue
            digest = hashlib.sha256(raw).hexdigest()
            key = (task, digest)
            variants.setdefault(key, raw)
            variant_sources[key].append(source_path)

    by_task: dict[int, list[tuple[str, bytes]]] = defaultdict(list)
    for (task, digest), raw in variants.items():
        by_task[task].append((digest, raw))

    rows: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="neurogolf-cross-source-") as tmp:
        tmp_dir = pathlib.Path(tmp)
        for task in sorted(by_task):
            name = f"task{task:03d}.onnx"
            base_raw = base[name]
            base_score, base_error = try_score(base_raw, task, tmp_dir, f"{name}_base")
            for digest, raw in by_task[task]:
                sources = variant_sources[(task, digest)]
                source_labels = [str(path.relative_to(sources_root)) for path in sources]
                row: dict[str, object] = {
                    "task": f"task{task:03d}",
                    "task_number": task,
                    "variant_sha256": digest,
                    "base_sha256": hashlib.sha256(base_raw).hexdigest(),
                    "base_bytes": len(base_raw),
                    "variant_bytes": len(raw),
                    "byte_delta": len(raw) - len(base_raw),
                    "source_count": len(sources),
                    "source_path": str(sources[0]),
                    "source_paths": json.dumps([str(path) for path in sources]),
                    "source_labels": json.dumps(source_labels),
                    "base_error": base_error,
                }
                if base_score is not None:
                    row.update(
                        {
                            "base_memory": base_score.memory,
                            "base_params": base_score.params,
                            "base_cost": base_score.cost,
                            "base_points": base_score.points,
                        }
                    )

                variant_score, variant_error = try_score(
                    raw, task, tmp_dir, f"{name}_{digest[:12]}"
                )
                row["variant_error"] = variant_error
                if variant_score is not None:
                    row.update(
                        {
                            "variant_memory": variant_score.memory,
                            "variant_params": variant_score.params,
                            "variant_cost": variant_score.cost,
                            "variant_points": variant_score.points,
                        }
                    )

                if base_score is not None and variant_score is not None:
                    row["cost_delta"] = variant_score.cost - base_score.cost
                    row["point_delta"] = variant_score.points - base_score.points
                    if variant_score.cost < base_score.cost:
                        row["classification"] = "cost-positive"
                    elif variant_score.cost == base_score.cost:
                        row["classification"] = "cost-neutral"
                    else:
                        row["classification"] = "cost-negative"
                elif base_score is None and variant_score is not None:
                    row["classification"] = "base-unscorable"
                elif base_score is not None and variant_score is None:
                    row["classification"] = "variant-unscorable"
                else:
                    row["classification"] = "both-unscorable"
                rows.append(row)

            print(
                f"[{task:03d}] ranked {len(by_task[task])} unique variants",
                flush=True,
            )

    rows.sort(
        key=lambda row: (
            float(row.get("point_delta", float("-inf"))),
            -int(row["variant_bytes"]),
        ),
        reverse=True,
    )
    args.out_dir.mkdir(parents=True, exist_ok=True)
    stem = f"{args.label}-cross-source-vs-base"
    csv_path = args.out_dir / f"{stem}.csv"
    json_path = args.out_dir / f"{stem}.json"
    fieldnames = sorted({key for row in rows for key in row})
    with csv_path.open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    with json_path.open("w") as file:
        json.dump(rows, file, indent=2)

    counts: dict[str, int] = {}
    for row in rows:
        classification = str(row["classification"])
        counts[classification] = counts.get(classification, 0) + 1
    summary = {
        "base": str(base_path),
        "sources_root": str(sources_root),
        "archives_discovered": len(source_paths),
        "archives_usable": usable_archives,
        "archive_errors": archive_errors,
        "unique_variants": len(rows),
        "tasks_with_variants": len(by_task),
        "counts": counts,
        "csv": str(csv_path),
        "json": str(json_path),
        "positive_tasks": sorted(
            {row["task"] for row in rows if row["classification"] == "cost-positive"}
        ),
        "base_unscorable_tasks": sorted(
            {row["task"] for row in rows if row["classification"] == "base-unscorable"}
        ),
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
