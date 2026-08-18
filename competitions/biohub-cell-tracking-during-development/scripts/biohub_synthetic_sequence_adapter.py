#!/usr/bin/env python3
"""Validate and adapt José Freitas's public Biohub synthetic sequences.

The source images are pooled `(T, 64, 64, 64)`, while node coordinates are
stored in the native `(z, y, x)` scale.  This diagnostic-only utility makes that
conversion explicit and emits provenance-preserving second-child examples.  It
does not train a model or create a competition submission.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import tempfile

import numpy as np


NATIVE_TO_POOLED = np.asarray([1.0, 4.0, 4.0], dtype=np.float32)
POOLED_VOXEL_UM = np.asarray([1.625, 1.625, 1.625], dtype=np.float32)


@dataclass(frozen=True)
class SyntheticSequence:
    volumes: np.ndarray
    nodes_native: np.ndarray
    nodes_pooled: np.ndarray
    edges: np.ndarray
    divisions: np.ndarray


def _as_2d(array: np.ndarray, columns: int, name: str, dtype: np.dtype) -> np.ndarray:
    array = np.asarray(array, dtype=dtype)
    if array.size == 0:
        return np.empty((0, columns), dtype=dtype)
    if array.ndim != 2 or array.shape[1] != columns:
        raise ValueError(f"{name} must have shape (N, {columns}); got {array.shape}")
    return array


def _validate(volumes: np.ndarray, nodes: np.ndarray, edges: np.ndarray, divisions: np.ndarray) -> None:
    if volumes.ndim != 4 or tuple(volumes.shape[1:]) != (64, 64, 64):
        raise ValueError(f"expected pooled volumes (T, 64, 64, 64); got {volumes.shape}")
    if not np.isfinite(nodes).all():
        raise ValueError("nodes contain non-finite values")
    times = nodes[:, 0]
    if not np.allclose(times, np.round(times)) or (times < 0).any() or (times >= volumes.shape[0]).any():
        raise ValueError("node times must be integer-valued and within the image sequence")
    if edges.size:
        if edges.min() < 0 or edges.max() >= len(nodes):
            raise ValueError("an edge endpoint is outside the node table")
        if not np.all(times[edges[:, 1]] == times[edges[:, 0]] + 1):
            raise ValueError("all edges must advance exactly one frame")
        indegree = np.bincount(edges[:, 1], minlength=len(nodes))
        outdegree = np.bincount(edges[:, 0], minlength=len(nodes))
        if indegree.max(initial=0) > 1 or outdegree.max(initial=0) > 2:
            raise ValueError("lineage degree invariant violated")
        expected = np.flatnonzero(outdegree == 2)
    else:
        expected = np.empty(0, dtype=np.int64)
    if not np.array_equal(np.sort(np.unique(divisions)), expected):
        raise ValueError("divisions must match source nodes with exactly two children")


def load_sequence(path: Path) -> SyntheticSequence:
    """Load a source NPZ and convert nodes from native to pooled coordinates."""

    with np.load(path, allow_pickle=False) as source:
        missing = {"volumes", "nodes", "edges", "divisions"}.difference(source.files)
        if missing:
            raise ValueError(f"missing required arrays: {', '.join(sorted(missing))}")
        volumes = np.asarray(source["volumes"])
        nodes_native = _as_2d(source["nodes"], 5, "nodes", np.float32)
        edges = _as_2d(source["edges"], 2, "edges", np.int64)
        divisions = np.asarray(source["divisions"], dtype=np.int64).reshape(-1)
    _validate(volumes, nodes_native, edges, divisions)
    nodes_pooled = nodes_native.copy()
    nodes_pooled[:, 1:4] /= NATIVE_TO_POOLED
    if ((nodes_pooled[:, 1:4] < 0) | (nodes_pooled[:, 1:4] >= 64)).any():
        raise ValueError("native-to-pooled conversion puts a node outside the image")
    return SyntheticSequence(volumes, nodes_native, nodes_pooled, edges, divisions)


def build_second_child_examples(
    sequence: SyntheticSequence, max_negative_distance_um: float
) -> dict[str, np.ndarray]:
    """Emit one second-child positive/negative candidate per usable source node."""

    if max_negative_distance_um <= 0:
        raise ValueError("max_negative_distance_um must be positive")
    nodes = sequence.nodes_pooled
    times = nodes[:, 0].astype(np.int64)
    children: list[list[int]] = [[] for _ in range(len(nodes))]
    for source, target in sequence.edges:
        children[int(source)].append(int(target))

    rows: list[tuple[int, int, int, int, int, float]] = []
    for source, source_children in enumerate(children):
        if not source_children:
            continue
        next_frame = times[source] + 1
        if len(source_children) == 2:
            primary, candidate = sorted(source_children)
            rows.append((source, primary, candidate, int(next_frame), 1, 0.0))
            continue
        primary = source_children[0]
        alternatives = np.flatnonzero(times == next_frame)
        alternatives = alternatives[~np.isin(alternatives, source_children)]
        if not len(alternatives):
            continue
        distance_um = np.linalg.norm(
            (nodes[alternatives, 1:4] - nodes[source, 1:4]) * POOLED_VOXEL_UM,
            axis=1,
        )
        best = int(np.argmin(distance_um))
        if distance_um[best] <= max_negative_distance_um:
            rows.append((source, primary, int(alternatives[best]), int(next_frame), 0, float(distance_um[best])))

    dtype = np.dtype([
        ("source_node", np.int64), ("primary_child_node", np.int64),
        ("candidate_node", np.int64), ("target_time", np.int64),
        ("label_is_second_child", np.int8), ("negative_distance_um", np.float32),
    ])
    return {
        "examples": np.asarray(rows, dtype=dtype),
        "nodes_pooled": nodes.astype(np.float32),
        "native_to_pooled": NATIVE_TO_POOLED,
        "pooled_voxel_um": POOLED_VOXEL_UM,
    }


def write_examples(path: Path, adapted: dict[str, np.ndarray], source: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(
        path, **adapted, source_file=np.asarray(str(source)),
        format_version=np.asarray("biohub_synthetic_second_child_examples_v1"),
    )


def _self_test() -> None:
    volumes = np.zeros((3, 64, 64, 64), dtype=np.uint16)
    nodes = np.asarray([
        [0, 10, 40, 80, 0], [1, 11, 44, 84, 0], [1, 11, 36, 76, 0],
        [0, 20, 80, 80, 1], [1, 20, 84, 80, 1], [1, 20, 92, 80, 2],
    ], dtype=np.float32)
    edges = np.asarray([[0, 1], [0, 2], [3, 4]], dtype=np.int32)
    with tempfile.TemporaryDirectory() as temporary_directory:
        source = Path(temporary_directory) / "sequence.npz"
        np.savez(source, volumes=volumes, nodes=nodes, edges=edges, divisions=np.asarray([0]))
        sequence = load_sequence(source)
        assert np.allclose(sequence.nodes_pooled[0, 1:4], [10, 10, 20])
        adapted = build_second_child_examples(sequence, max_negative_distance_um=10.0)
        examples = adapted["examples"]
        assert len(examples) == 2 and int(examples["label_is_second_child"].sum()) == 1
        destination = Path(temporary_directory) / "examples.npz"
        write_examples(destination, adapted, source)
        with np.load(destination, allow_pickle=False) as written:
            assert written["format_version"].item().endswith("_v1")
    print("self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="one synthetic sequence NPZ")
    parser.add_argument("--output", type=Path, help="adapted examples NPZ")
    parser.add_argument("--max-negative-distance-um", type=float, default=12.0)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        _self_test()
    if args.input is None and args.output is None:
        if args.self_test:
            return
        parser.error("--input and --output are required unless using --self-test")
    if args.input is None or args.output is None:
        parser.error("--input and --output must be supplied together")
    sequence = load_sequence(args.input)
    adapted = build_second_child_examples(sequence, args.max_negative_distance_um)
    write_examples(args.output, adapted, args.input)
    examples = adapted["examples"]
    print(f"wrote {args.output}: {len(examples)} examples ({int(examples['label_is_second_child'].sum())} positive)")


if __name__ == "__main__":
    main()
