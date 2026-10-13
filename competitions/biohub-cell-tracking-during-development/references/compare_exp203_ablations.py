"""Compare downloaded Biohub ablation outputs with the Exp203 control."""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path

import pandas as pd


COLS = ["id", "dataset", "row_type", "node_id", "t", "z", "y", "x", "source_id", "target_id"]


def load(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    if list(df.columns) != COLS:
        raise ValueError(f"{path}: unexpected columns {list(df.columns)}")
    return df


def stats(df: pd.DataFrame) -> dict[str, int]:
    nodes = df[df.row_type == "node"]
    edges = df[df.row_type == "edge"]
    outdeg = edges.groupby(["dataset", "source_id"]).size()
    return {
        "rows": len(df),
        "nodes": len(nodes),
        "edges": len(edges),
        "divisions": int((outdeg == 2).sum()),
    }


def edge_set(df: pd.DataFrame) -> set[tuple[str, int, int]]:
    e = df[df.row_type == "edge"]
    return set(zip(e.dataset, e.source_id.astype(int), e.target_id.astype(int)))


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit("usage: compare_exp203_ablations.py CONTROL.csv VARIANT.csv [...]")
    paths = [Path(p) for p in sys.argv[1:]]
    frames = {str(p): load(p) for p in paths}
    control_name = str(paths[0])
    control_edges = edge_set(frames[control_name])
    print("name,sha256,rows,nodes,edges,divisions,edge_overlap_with_control")
    for p in paths:
        df = frames[str(p)]
        sha = hashlib.sha256(p.read_bytes()).hexdigest()
        edges = edge_set(df)
        overlap = len(edges & control_edges) / len(edges | control_edges) if edges | control_edges else 1.0
        s = stats(df)
        print(f"{p},{sha},{s['rows']},{s['nodes']},{s['edges']},{s['divisions']},{overlap:.6f}")
        by_ds = df.groupby(["dataset", "row_type"]).size().unstack(fill_value=0)
        print(by_ds.to_string())


if __name__ == "__main__":
    main()
