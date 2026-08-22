#!/usr/bin/env python3
"""Count near-duplicate detections in a submission, per the 08-17 scan.

`sleepymegacat/the-metric-decides-your-architecture-8-measured` measured a
single duplicate detection taking a perfect prediction from 1.000 to 0.500:
node matching is an optimal one-to-one assignment, so only one twin can win the
match, and the loser's edges still touch annotated evidence and are graded as
FALSE POSITIVES rather than merely inflating the node count. That is far worse
than the ~9% the 08-07 scan recorded from `nekkon`, which treated the cost as
the node-count term alone.

The check is cheap and needs no submission slot: for each (dataset, t), build a
KD-tree over the node centroids in PHYSICAL micrometres and count pairs closer
than a threshold. Anisotropy matters - the voxel is 4x taller than it is wide,
so a radius in voxels is wrong in z by 4x.

Usage:
  duplicate_node_audit.py SUBMISSION.CSV [--radius-um 2.0]
"""

from __future__ import annotations

import csv
import sys
from collections import defaultdict

import numpy as np
from scipy.spatial import cKDTree

# z, y, x micrometres per voxel, from the official metric.
VOXEL_SCALE_UM = (1.625, 0.40625, 0.40625)
# Radii to report. 2.0 um is the measured centroid cliff; the others bracket it
# so a near-miss cluster is visible rather than hidden by one threshold choice.
RADII_UM = (0.5, 1.0, 2.0, 3.0)


def load_nodes(path: str) -> dict[tuple[str, int], list[tuple[float, float, float]]]:
    by_frame: dict[tuple[str, int], list[tuple[float, float, float]]] = defaultdict(list)
    with open(path, newline="") as handle:
        for row in csv.DictReader(handle):
            if row["row_type"] != "node":
                continue
            by_frame[(row["dataset"], int(row["t"]))].append(
                (
                    float(row["z"]) * VOXEL_SCALE_UM[0],
                    float(row["y"]) * VOXEL_SCALE_UM[1],
                    float(row["x"]) * VOXEL_SCALE_UM[2],
                )
            )
    return by_frame


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]

    by_frame = load_nodes(path)
    total_nodes = sum(len(v) for v in by_frame.values())
    print(f"{path}")
    print(f"nodes: {total_nodes}  frames: {len(by_frame)}")

    per_dataset_worst: dict[str, float] = defaultdict(float)
    for radius in RADII_UM:
        pair_count = 0
        involved: set[tuple[str, int, int]] = set()
        for (dataset, t), points in by_frame.items():
            if len(points) < 2:
                continue
            array = np.asarray(points, dtype=np.float64)
            tree = cKDTree(array)
            for i, j in tree.query_pairs(r=radius):
                pair_count += 1
                involved.add((dataset, t, i))
                involved.add((dataset, t, j))
                per_dataset_worst[dataset] = max(per_dataset_worst[dataset], 1.0)
        share = 100.0 * len(involved) / total_nodes if total_nodes else 0.0
        print(
            f"  within {radius:>4} um: {pair_count:>6} pairs, "
            f"{len(involved):>6} nodes ({share:.4f}% of all nodes)"
        )

    # Nearest-neighbour distribution: the scan's claim rests on cells being
    # ~9-10 um apart, so confirm that on our own output rather than assuming it.
    samples: list[float] = []
    for (dataset, t), points in by_frame.items():
        if len(points) < 2:
            continue
        array = np.asarray(points, dtype=np.float64)
        distances, _ = cKDTree(array).query(array, k=2)
        samples.extend(distances[:, 1].tolist())
    if samples:
        arr = np.asarray(samples)
        print(
            "  same-frame nearest-neighbour um: "
            f"min {arr.min():.3f}  p1 {np.percentile(arr, 1):.3f}  "
            f"median {np.median(arr):.3f}  mean {arr.mean():.3f}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
