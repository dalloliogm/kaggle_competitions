#!/usr/bin/env python3
"""Wait for a Kaggle kernel, validate its submission.csv, then submit it.

Exists so candidates can be submitted unattended without ever spending a daily
slot on a malformed graph. Validation is the same set of invariants the
in-kernel harness checks, re-run here against the downloaded file:

  * exact Biohub column order
  * globally unique row ids, no nulls
  * node_id unique per (dataset, node_id) - ids REPEAT across datasets, so a
    global key produces false errors
  * every edge endpoint exists in the same dataset
  * every edge spans exactly one frame
  * max in-degree 1, max out-degree 2
  * no negative coordinates

Refuses to submit if anything fails, and refuses to submit a file byte-identical
to one already submitted (that wastes a slot on a duplicate).

Usage:
  await_validate_submit.py OWNER/KERNEL-SLUG VERSION "message" [--dry-run]
"""
from __future__ import annotations

import csv
import hashlib
import subprocess
import sys
import tempfile
import time
from collections import defaultdict
from pathlib import Path

COMP = "biohub-cell-tracking-during-development"
KG = ["uvx", "--index-url", "https://pypi.org/simple", "kaggle"]
COLUMNS = ["id", "dataset", "row_type", "node_id", "t", "z", "y", "x", "source_id", "target_id"]
POLL_SECONDS = 180
MAX_WAIT_HOURS = 10


def run(args: list[str], timeout: int = 600) -> str:
    p = subprocess.run(KG + args, capture_output=True, text=True, timeout=timeout)
    return (p.stdout or "") + (p.stderr or "")


def wait_for_kernel(slug: str) -> str:
    deadline = time.time() + MAX_WAIT_HOURS * 3600
    while time.time() < deadline:
        out = run(["kernels", "status", slug], timeout=300).strip().splitlines()
        status = out[-1] if out else ""
        print(f"[{time.strftime('%H:%M:%S')}] {status[:120]}", flush=True)
        if "RUNNING" in status or "QUEUED" in status:
            time.sleep(POLL_SECONDS)
            continue
        # A kernel that has not been created yet (still pushing, or queued behind
        # the 2-session GPU cap) reports "Cannot access"/404. That is NOT a
        # failure - keep waiting rather than aborting, which is what happened
        # the first time this ran against three not-yet-pushed kernels.
        if any(k in status for k in ("Cannot access", "404", "not found", "Not Found")):
            time.sleep(POLL_SECONDS)
            continue
        return status
    return "TIMEOUT"


def validate(path: Path) -> tuple[bool, list[str], dict]:
    problems: list[str] = []
    nodes: dict[tuple[str, int], int] = {}
    indeg: dict[tuple[str, int], int] = defaultdict(int)
    outdeg: dict[tuple[str, int], int] = defaultdict(int)
    ids: set[str] = set()
    n_nodes = n_edges = dup = dangling = nonconsec = negative = 0

    with path.open() as fh:
        reader = csv.DictReader(fh)
        if reader.fieldnames != COLUMNS:
            return False, [f"column mismatch: {reader.fieldnames}"], {}
        for row in reader:
            if any(v is None or v == "" for v in row.values()):
                problems.append("null/empty field")
                break
            if row["id"] in ids:
                dup += 1
            ids.add(row["id"])
            if row["row_type"] == "node":
                n_nodes += 1
                key = (row["dataset"], int(row["node_id"]))
                if key in nodes:
                    problems.append(f"duplicate (dataset,node_id) {key}")
                nodes[key] = int(row["t"])
                if min(int(row["z"]), int(row["y"]), int(row["x"])) < 0:
                    negative += 1
            else:
                n_edges += 1
                d = row["dataset"]
                src = (d, int(row["source_id"]))
                tgt = (d, int(row["target_id"]))
                if src not in nodes or tgt not in nodes:
                    dangling += 1
                    continue
                if nodes[tgt] != nodes[src] + 1:
                    nonconsec += 1
                outdeg[src] += 1
                indeg[tgt] += 1

    max_in = max(indeg.values()) if indeg else 0
    max_out = max(outdeg.values()) if outdeg else 0
    divisions = sum(1 for v in outdeg.values() if v == 2)
    for label, count in (("duplicate ids", dup), ("dangling edges", dangling),
                         ("non-consecutive edges", nonconsec), ("negative coords", negative)):
        if count:
            problems.append(f"{count} {label}")
    if max_in > 1:
        problems.append(f"max in-degree {max_in} > 1")
    if max_out > 2:
        problems.append(f"max out-degree {max_out} > 2")

    stats = {"nodes": n_nodes, "edges": n_edges, "rows": n_nodes + n_edges,
             "max_indeg": max_in, "max_outdeg": max_out, "divisions": divisions}
    return not problems, problems, stats


def already_submitted(sha: str, store: Path) -> str | None:
    if not store.exists():
        return None
    for line in store.read_text().splitlines():
        if line.startswith(sha):
            return line
    return None


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    slug, version, message = sys.argv[1], sys.argv[2], sys.argv[3]
    dry = "--dry-run" in sys.argv

    status = wait_for_kernel(slug)
    if "COMPLETE" not in status:
        print(f"ABORT: kernel did not complete -> {status}")
        return 1

    tmp = Path(tempfile.mkdtemp(prefix="subm_"))
    print(run(["kernels", "output", slug, "-p", str(tmp)], timeout=900).strip().splitlines()[-1:])
    sub = tmp / "submission.csv"
    if not sub.exists():
        print("ABORT: kernel produced no submission.csv")
        return 1

    ok, problems, stats = validate(sub)
    print(f"validation: {stats}")
    if not ok:
        print("ABORT: validation FAILED -> " + "; ".join(problems))
        return 1

    sha = hashlib.sha256(sub.read_bytes()).hexdigest()
    store = Path(__file__).resolve().parent.parent / "references" / "submitted_shas.txt"
    dupe = already_submitted(sha, store)
    if dupe:
        print(f"ABORT: byte-identical output already submitted -> {dupe}")
        return 1

    print(f"validation PASSED; sha {sha[:16]}")
    if dry:
        print("dry-run: not submitting")
        return 0

    out = run(["competitions", "submit", COMP, "-k", slug, "-v", str(version),
               "-f", "submission.csv", "-m", message], timeout=900)
    print(out.strip()[-400:])
    store.parent.mkdir(parents=True, exist_ok=True)
    with store.open("a") as fh:
        fh.write(f"{sha}  {slug} v{version}  {message[:80]}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
