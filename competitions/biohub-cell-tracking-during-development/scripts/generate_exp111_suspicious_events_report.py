#!/usr/bin/env python3
"""Generate a static visual-review report for Exp111 suspicious tracking events.

The report is useful without microscopy volumes: it reconstructs synthetic gap
nodes by comparing the final submission with the raw GEFF graph, calculates all
edge geometry in physical units, and embeds manual-label radio controls. If raw
test Zarr images are supplied, it also embeds local XY max-projection crops.
"""

from __future__ import annotations

import argparse
import base64
import html
import io
import json
import os
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd


VOXEL_SCALE_UM = np.array([1.625, 0.40625, 0.40625], dtype=float)
SAFE_DIV_MAX_UM = 4.66
SAFE_DIV_SISTER_MAX_UM = 8.5
SAFE_DIV_EXISTING_CHILD_MAX_UM = 7.65
TIGHT_MOTION_GATE_UM = 6.0
LABELS = [
    "real_division",
    "false_division",
    "real_gap",
    "false_gap",
    "good_link",
    "bad_link",
    "ambiguous",
    "cannot_judge",
]


def parse_args() -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parents[3]
    workspace = Path(__file__).resolve().parents[1]
    output_dir = repo_root / "kaggle_outputs" / "biohub-exp111-original-branch-exploration"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exp111-dir", type=Path, default=output_dir)
    parser.add_argument(
        "--output",
        type=Path,
        default=workspace / "reports" / "exp111_suspicious_events.html",
    )
    parser.add_argument(
        "--image-root",
        type=Path,
        default=None,
        help="Directory containing <dataset>.zarr test volumes (optional).",
    )
    parser.add_argument("--crop-radius-yx", type=int, default=48)
    parser.add_argument("--crop-radius-z", type=int, default=3)
    return parser.parse_args()


def zarr_v3_array(path: Path) -> np.ndarray:
    """Read the single-chunk byte+zstd Zarr v3 arrays used by downloaded GEFF."""
    meta = json.loads((path / "zarr.json").read_text())
    codecs = [codec["name"] for codec in meta.get("codecs", [])]
    if codecs != ["bytes", "zstd"]:
        raise ValueError(f"Unsupported codecs at {path}: {codecs}")
    chunk_shape = tuple(meta["chunk_grid"]["configuration"]["chunk_shape"])
    if chunk_shape != tuple(meta["shape"]):
        raise ValueError(f"Expected one chunk at {path}, got {chunk_shape}")
    chunk_key = Path("c").joinpath(*("0" for _ in meta["shape"]))
    compressed = (path / chunk_key).read_bytes()
    try:
        from compression import zstd

        raw = zstd.decompress(compressed)
    except ImportError:  # pragma: no cover - for Python <3.14 environments
        import zstandard

        raw = zstandard.ZstdDecompressor().decompress(compressed)
    dtype = np.dtype(meta["data_type"]).newbyteorder("<")
    return np.frombuffer(raw, dtype=dtype).reshape(meta["shape"]).copy()


def load_raw_geff_metadata(exp111_dir: Path) -> dict[str, dict[str, Any]]:
    geff_root = (
        exp111_dir
        / "tracking_repo"
        / "predictions"
        / "unknown"
        / "unet_transformer"
        / "split_0"
    )
    result: dict[str, dict[str, Any]] = {}
    for geff in sorted(geff_root.glob("*.geff")):
        node_ids = zarr_v3_array(geff / "nodes" / "ids").astype(np.int64)
        edge_ids = zarr_v3_array(geff / "edges" / "ids").astype(np.int64)
        edge_probs_path = geff / "edges" / "props" / "edge_prob" / "values"
        edge_probs = zarr_v3_array(edge_probs_path).astype(float)
        result[geff.stem] = {
            "node_ids": set(node_ids.tolist()),
            "edges": set(map(tuple, edge_ids.tolist())),
            "edge_prob": {
                (int(source), int(target)): float(prob)
                for (source, target), prob in zip(edge_ids, edge_probs)
            },
            "raw_node_max": int(node_ids.max()),
        }
    if not result:
        raise FileNotFoundError(f"No downloaded GEFF graphs found under {geff_root}")
    return result


def build_graph_tables(submission_path: Path) -> tuple[pd.DataFrame, pd.DataFrame]:
    submission = pd.read_csv(submission_path)
    required = {
        "dataset", "row_type", "node_id", "t", "z", "y", "x", "source_id", "target_id"
    }
    missing = required - set(submission.columns)
    if missing:
        raise ValueError(f"submission.csv missing columns: {sorted(missing)}")
    nodes = submission.loc[
        submission["row_type"].eq("node"), ["dataset", "node_id", "t", "z", "y", "x"]
    ].copy()
    nodes[["node_id", "t"]] = nodes[["node_id", "t"]].astype(int)
    edges = submission.loc[
        submission["row_type"].eq("edge"), ["dataset", "source_id", "target_id"]
    ].copy()
    edges[["source_id", "target_id"]] = edges[["source_id", "target_id"]].astype(int)

    lookup = nodes.set_index(["dataset", "node_id"])
    source_index = pd.MultiIndex.from_frame(edges[["dataset", "source_id"]], names=["dataset", "node_id"])
    target_index = pd.MultiIndex.from_frame(edges[["dataset", "target_id"]], names=["dataset", "node_id"])
    source = lookup.loc[source_index].reset_index(drop=True)
    target = lookup.loc[target_index].reset_index(drop=True)
    for axis in ["t", "z", "y", "x"]:
        edges[f"source_{axis}"] = source[axis].to_numpy()
        edges[f"target_{axis}"] = target[axis].to_numpy()
    delta_vox = edges[["target_z", "target_y", "target_x"]].to_numpy() - edges[
        ["source_z", "source_y", "source_x"]
    ].to_numpy()
    edges["distance_um"] = np.linalg.norm(delta_vox * VOXEL_SCALE_UM, axis=1)
    edges["dt"] = edges["target_t"] - edges["source_t"]
    return nodes, edges


def event_base(event_id: str, dataset: str, event_type: str) -> dict[str, Any]:
    return {
        "event_id": event_id,
        "dataset": dataset,
        "event_type": event_type,
        "source_id": None,
        "target_ids": [],
        "t": None,
        "z": None,
        "y": None,
        "x": None,
        "distances_um": [],
        "features": {},
    }


def select_events(
    nodes: pd.DataFrame,
    edges: pd.DataFrame,
    raw: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    node_lookup = nodes.set_index(["dataset", "node_id"]).to_dict("index")
    out_degree = edges.groupby(["dataset", "source_id"]).size()
    division_keys = set(out_degree[out_degree >= 2].index)
    edges = edges.copy()
    edges["division_source"] = [
        (dataset, int(source_id)) in division_keys
        for dataset, source_id in zip(edges["dataset"], edges["source_id"])
    ]
    synthetic_by_dataset = {
        dataset: set(group.loc[~group["node_id"].isin(raw[dataset]["node_ids"]), "node_id"].astype(int))
        for dataset, group in nodes.groupby("dataset")
    }
    edges["gap_related"] = [
        int(source_id) in synthetic_by_dataset[dataset]
        or int(target_id) in synthetic_by_dataset[dataset]
        for dataset, source_id, target_id in zip(
            edges["dataset"], edges["source_id"], edges["target_id"]
        )
    ]

    division_events: list[dict[str, Any]] = []
    for dataset, source_id in sorted(division_keys):
        child_edges = edges[(edges["dataset"] == dataset) & (edges["source_id"] == source_id)]
        if len(child_edges) < 2:
            continue
        child_edges = child_edges.nlargest(2, "distance_um")
        child_ids = child_edges["target_id"].astype(int).tolist()
        source_node = node_lookup[(dataset, int(source_id))]
        child_nodes = [node_lookup[(dataset, child_id)] for child_id in child_ids]
        sister_delta = (
            np.array([child_nodes[0]["z"], child_nodes[0]["y"], child_nodes[0]["x"]])
            - np.array([child_nodes[1]["z"], child_nodes[1]["y"], child_nodes[1]["x"]])
        )
        sister_um = float(np.linalg.norm(sister_delta * VOXEL_SCALE_UM))
        parent_distances = child_edges["distance_um"].astype(float).tolist()
        # One daughter was pre-existing and one was added. The serialized output
        # does not retain which was which, so use the best possible assignment.
        assignment_slacks = [
            min(
                SAFE_DIV_MAX_UM - parent_distances[added_idx],
                SAFE_DIV_EXISTING_CHILD_MAX_UM - parent_distances[1 - added_idx],
                SAFE_DIV_SISTER_MAX_UM - sister_um,
            )
            for added_idx in (0, 1)
        ]
        boundary_slack = max(assignment_slacks)
        event = event_base(f"division-{dataset}-{source_id}", dataset, "division_boundary")
        event.update(
            source_id=int(source_id),
            target_ids=child_ids,
            t=int(source_node["t"]),
            z=float(source_node["z"]),
            y=float(source_node["y"]),
            x=float(source_node["x"]),
            distances_um=[*parent_distances, sister_um],
            features={
                "safe_division_added_in_run": True,
                "parent_to_child_um": [round(v, 4) for v in parent_distances],
                "sister_distance_um": round(sister_um, 4),
                "best_gate_assignment_slack_um": round(boundary_slack, 4),
                "near_decision_boundary": boundary_slack <= 0.75,
                "safe_div_max_um": SAFE_DIV_MAX_UM,
                "safe_div_existing_child_max_um": SAFE_DIV_EXISTING_CHILD_MAX_UM,
                "safe_div_sister_max_um": SAFE_DIV_SISTER_MAX_UM,
                "added_daughter_identity_retained": False,
            },
            rank_score=abs(boundary_slack),
        )
        division_events.append(event)
    division_events.sort(key=lambda event: event["rank_score"])
    division_events = division_events[:40]

    gap_events: list[dict[str, Any]] = []
    for dataset, synthetic_ids in synthetic_by_dataset.items():
        for node_id in synthetic_ids:
            incoming = edges[(edges["dataset"] == dataset) & (edges["target_id"] == node_id)]
            outgoing = edges[(edges["dataset"] == dataset) & (edges["source_id"] == node_id)]
            if incoming.empty or outgoing.empty:
                continue
            edge_in = incoming.iloc[0]
            edge_out = outgoing.iloc[0]
            source_id, target_id = int(edge_in["source_id"]), int(edge_out["target_id"])
            node = node_lookup[(dataset, node_id)]
            source_node, target_node = node_lookup[(dataset, source_id)], node_lookup[(dataset, target_id)]
            endpoint_delta = (
                np.array([source_node["z"], source_node["y"], source_node["x"]])
                - np.array([target_node["z"], target_node["y"], target_node["x"]])
            )
            endpoint_distance = float(np.linalg.norm(endpoint_delta * VOXEL_SCALE_UM))
            event = event_base(f"gap-{dataset}-{node_id}", dataset, "gap_insertion")
            event.update(
                source_id=source_id,
                target_ids=[node_id, target_id],
                t=int(node["t"]),
                z=float(node["z"]),
                y=float(node["y"]),
                x=float(node["x"]),
                distances_um=[float(edge_in["distance_um"]), float(edge_out["distance_um"]), endpoint_distance],
                features={
                    "synthetic_node_id": node_id,
                    "absent_from_raw_geff": True,
                    "incoming_step_um": round(float(edge_in["distance_um"]), 4),
                    "outgoing_step_um": round(float(edge_out["distance_um"]), 4),
                    "bridge_endpoint_distance_um": round(endpoint_distance, 4),
                    "frames": [int(source_node["t"]), int(node["t"]), int(target_node["t"])],
                    "priority_dataset": dataset == "44b6_0b24845f",
                },
                rank_score=endpoint_distance,
            )
            gap_events.append(event)
    gap_events.sort(
        key=lambda event: (event["dataset"] == "44b6_0b24845f", event["rank_score"]),
        reverse=True,
    )
    gap_events = gap_events[:30]

    # Reserve the ten longest edges as their own exact category. Exp111 did not
    # retain the tight-vs-relaxed pass per edge, so the next 20 geometrically
    # riskiest eligible edges are explicitly presented as proxies.
    longest_rows = edges.nlargest(10, "distance_um")
    longest_keys = set(
        zip(longest_rows["dataset"], longest_rows["source_id"], longest_rows["target_id"])
    )

    eligible_motion = edges[~edges["division_source"] & ~edges["gap_related"]].copy()
    eligible_motion["reserved_longest"] = [
        (dataset, source, target) in longest_keys
        for dataset, source, target in zip(
            eligible_motion["dataset"], eligible_motion["source_id"], eligible_motion["target_id"]
        )
    ]
    eligible_motion = eligible_motion[~eligible_motion["reserved_longest"]].nlargest(20, "distance_um")

    def edge_event(row: pd.Series, event_type: str, prefix: str) -> dict[str, Any]:
        dataset, source_id, target_id = str(row["dataset"]), int(row["source_id"]), int(row["target_id"])
        source_node = node_lookup[(dataset, source_id)]
        raw_prob = raw[dataset]["edge_prob"].get((source_id, target_id))
        event = event_base(f"{prefix}-{dataset}-{source_id}-{target_id}", dataset, event_type)
        event.update(
            source_id=source_id,
            target_ids=[target_id],
            t=int(source_node["t"]),
            z=float(source_node["z"]),
            y=float(source_node["y"]),
            x=float(source_node["x"]),
            distances_um=[float(row["distance_um"])],
            features={
                "distance_um": round(float(row["distance_um"]), 4),
                "dt": int(row["dt"]),
                "above_tight_6um_gate": bool(float(row["distance_um"]) > TIGHT_MOTION_GATE_UM),
                "present_in_raw_geff": (source_id, target_id) in raw[dataset]["edges"],
                "raw_edge_probability": None if raw_prob is None else round(float(raw_prob), 5),
                "per_edge_motion_pass_retained": False,
            },
            rank_score=float(row["distance_um"]),
        )
        return event

    motion_events = [edge_event(row, "relaxed_motion_proxy", "motion") for _, row in eligible_motion.iterrows()]
    for event in motion_events:
        event["features"]["selection_note"] = (
            "Highest-distance non-gap/non-division link after excluding the 10 longest; "
            "proxy only because Exp111 retained relaxed-pass counts per dataset, not per edge."
        )
    longest_events = [edge_event(row, "longest_final_edge", "long") for _, row in longest_rows.iterrows()]

    events = [*division_events, *gap_events, *motion_events, *longest_events]
    counts = pd.Series([event["event_type"] for event in events]).value_counts().to_dict()
    expected = {
        "division_boundary": 40,
        "gap_insertion": 30,
        "relaxed_motion_proxy": 20,
        "longest_final_edge": 10,
    }
    if counts != expected:
        raise AssertionError(f"Event quotas not met: got {counts}, expected {expected}")
    return events


def find_image_root(explicit: Path | None, workspace: Path) -> tuple[Path | None, list[Path]]:
    candidates = []
    if explicit is not None:
        candidates.append(explicit.expanduser())
    env_root = os.environ.get("BIOHUB_TEST_DIR", "").strip()
    if env_root:
        candidates.append(Path(env_root).expanduser())
    candidates.extend(
        [
            workspace / "data" / "test",
            workspace.parents[1] / "data" / "biohub-cell-tracking-during-development" / "test",
            Path("/kaggle/input/competitions/biohub-cell-tracking-during-development/test"),
            Path("/kaggle/input/biohub-cell-tracking-during-development/test"),
        ]
    )
    for candidate in candidates:
        if candidate.exists() and any(candidate.glob("*.zarr")):
            return candidate, candidates
    return None, candidates


def open_image_arrays(image_root: Path | None, datasets: list[str]) -> tuple[dict[str, Any], str | None]:
    if image_root is None:
        return {}, "No local raw test Zarr root was found."
    try:
        import zarr
    except ImportError:
        return {}, "A test-image root was found, but Python package 'zarr' is not installed."
    arrays: dict[str, Any] = {}
    errors = []
    for dataset in datasets:
        path = image_root / f"{dataset}.zarr"
        if not path.exists():
            errors.append(f"missing {path}")
            continue
        obj = zarr.open(str(path), mode="r")
        if hasattr(obj, "shape"):
            array = obj
        elif "0" in obj:
            array = obj["0"]
        else:
            errors.append(f"no image array or level '0' in {path}")
            continue
        if len(array.shape) != 4:
            errors.append(f"expected TZYX at {path}, got shape {array.shape}")
            continue
        arrays[dataset] = array
    return arrays, "; ".join(errors) if errors else None


def crop_data_uri(
    event: dict[str, Any],
    image_arrays: dict[str, Any],
    nodes: pd.DataFrame,
    edges: pd.DataFrame,
    radius_yx: int,
    radius_z: int,
) -> str | None:
    array = image_arrays.get(event["dataset"])
    if array is None:
        return None
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    center_t, center_z = int(event["t"]), int(round(event["z"]))
    center_y, center_x = int(round(event["y"])), int(round(event["x"]))
    y0, y1 = max(0, center_y - radius_yx), min(array.shape[2], center_y + radius_yx + 1)
    x0, x1 = max(0, center_x - radius_yx), min(array.shape[3], center_x + radius_yx + 1)
    z0, z1 = max(0, center_z - radius_z), min(array.shape[1], center_z + radius_z + 1)
    frames = [center_t - 1, center_t, center_t + 1, center_t + 2]
    fig, axes = plt.subplots(1, 4, figsize=(10.4, 2.8), constrained_layout=True)
    dataset_nodes = nodes[nodes["dataset"] == event["dataset"]]
    event_node_ids = {event["source_id"], *event["target_ids"]}
    for ax, frame_t in zip(axes, frames):
        ax.set_title(f"t={frame_t}", fontsize=9)
        if frame_t < 0 or frame_t >= array.shape[0]:
            ax.text(0.5, 0.5, "outside volume", ha="center", va="center")
            ax.axis("off")
            continue
        crop = np.asarray(array[frame_t, z0:z1, y0:y1, x0:x1]).max(axis=0)
        lo, hi = np.percentile(crop, [2, 99.7]) if crop.size else (0, 1)
        ax.imshow(crop, cmap="gray", vmin=lo, vmax=max(hi, lo + 1e-6), origin="upper")
        visible = dataset_nodes[
            (dataset_nodes["t"] == frame_t)
            & dataset_nodes["y"].between(y0, y1 - 1)
            & dataset_nodes["x"].between(x0, x1 - 1)
            & dataset_nodes["z"].between(z0, z1 - 1)
        ]
        for node in visible.itertuples(index=False):
            highlight = int(node.node_id) in event_node_ids
            ax.scatter(node.x - x0, node.y - y0, s=38 if highlight else 10, facecolors="none", edgecolors="#ff3b30" if highlight else "#00e5ff", linewidths=1.2 if highlight else 0.6)
        event_edges = edges[
            (edges["dataset"] == event["dataset"])
            & (edges["source_id"] == event["source_id"])
            & edges["target_id"].isin(event["target_ids"])
        ]
        for link in event_edges.itertuples(index=False):
            ax.plot([link.source_x - x0, link.target_x - x0], [link.source_y - y0, link.target_y - y0], color="#ffcc00", linewidth=1.2, alpha=0.9)
        ax.set_xlim(0, x1 - x0)
        ax.set_ylim(y1 - y0, 0)
        ax.axis("off")
    buffer = io.BytesIO()
    fig.savefig(buffer, format="png", dpi=125, facecolor="#111827")
    plt.close(fig)
    return "data:image/png;base64," + base64.b64encode(buffer.getvalue()).decode("ascii")


def fmt(value: Any) -> str:
    if value is None or (isinstance(value, float) and np.isnan(value)):
        return "—"
    if isinstance(value, float):
        return f"{value:.3f}"
    return html.escape(str(value))


def render_report(
    events: list[dict[str, Any]],
    nodes: pd.DataFrame,
    edges: pd.DataFrame,
    stats: pd.DataFrame,
    diagnostics: pd.DataFrame,
    image_arrays: dict[str, Any],
    image_root: Path | None,
    image_error: str | None,
    checked_paths: list[Path],
    crop_radius_yx: int,
    crop_radius_z: int,
) -> str:
    count_by_type = pd.Series([e["event_type"] for e in events]).value_counts()
    count_by_dataset = pd.Series([e["dataset"] for e in events]).value_counts()
    summary_cards = "".join(
        f'<div class="metric"><strong>{int(count)}</strong><span>{html.escape(label)}</span></div>'
        for label, count in count_by_type.items()
    )
    path_list = "".join(f"<li><code>{html.escape(str(path))}</code></li>" for path in checked_paths)
    if image_root is None:
        image_notice = (
            '<div class="notice warning"><strong>Microscopy crops unavailable.</strong> '
            "The report is using graph geometry and placeholders. Supply <code>--image-root PATH</code> "
            "where PATH contains <code>&lt;dataset&gt;.zarr</code> test volumes. Checked:<ul>"
            f"{path_list}</ul><span>{html.escape(image_error or '')}</span></div>"
        )
    else:
        image_notice = (
            f'<div class="notice"><strong>Image root:</strong> <code>{html.escape(str(image_root))}</code>'
            + (f"<br>{html.escape(image_error)}" if image_error else "")
            + "</div>"
        )

    diagnostic_cols = [
        "dataset", "division_like_sources", "gap_added_nodes", "motion_relink_relaxed_edges",
        "short_track_nodes_removed", "long_edges_gt_6um", "edge_dist_max_um",
    ]
    diagnostic_cols = [column for column in diagnostic_cols if column in diagnostics.columns]
    diagnostic_html = diagnostics[diagnostic_cols].to_html(index=False, classes="compact", border=0, float_format=lambda x: f"{x:.3f}")

    rows = []
    for idx, event in enumerate(events, start=1):
        crop = crop_data_uri(event, image_arrays, nodes, edges, crop_radius_yx, crop_radius_z)
        if crop:
            visual = f'<img class="crop" src="{crop}" alt="XY max projection for {html.escape(event["event_id"])}">'
        else:
            visual = (
                '<div class="placeholder">XY max projection unavailable<br>'
                '<small>Expected frames t−1, t, t+1, t+2</small></div>'
            )
        labels = "".join(
            f'<label><input type="radio" name="label-{idx}" value="{label}"> {label}</label>'
            for label in LABELS
        )
        features = html.escape(json.dumps(event["features"], sort_keys=True))
        rows.append(
            f"""
            <tr data-event-type="{event['event_type']}" data-dataset="{event['dataset']}">
              <td class="ordinal">{idx}</td>
              <td><strong>{html.escape(event['dataset'])}</strong><br><span class="tag">{html.escape(event['event_type'])}</span></td>
              <td><code>{fmt(event['source_id'])}</code><br>→ <code>{html.escape(', '.join(map(str, event['target_ids'])))}</code></td>
              <td>t={fmt(event['t'])}<br>z,y,x=({fmt(event['z'])}, {fmt(event['y'])}, {fmt(event['x'])})</td>
              <td>{html.escape(', '.join(f'{value:.3f}' for value in event['distances_um']))}</td>
              <td><details><summary>flags/features</summary><code class="feature-json">{features}</code></details></td>
              <td>{visual}</td>
              <td><fieldset><legend>Manual label (not saved)</legend>{labels}</fieldset></td>
            </tr>
            """
        )

    dataset_summary = ", ".join(f"{dataset}: {count}" for dataset, count in count_by_dataset.items())
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Exp111 suspicious tracking events</title>
<style>
:root {{ color-scheme: dark; --bg:#0b1020; --panel:#111827; --line:#334155; --text:#e5e7eb; --muted:#94a3b8; --accent:#22d3ee; }}
* {{ box-sizing:border-box; }} body {{ margin:0; background:var(--bg); color:var(--text); font:14px/1.45 system-ui,sans-serif; }}
header, main {{ max-width:1800px; margin:auto; padding:22px; }} h1 {{ margin:0 0 6px; }} h2 {{ margin-top:28px; }} p {{ max-width:1100px; }}
.metrics {{ display:flex; gap:12px; flex-wrap:wrap; margin:18px 0; }} .metric {{ min-width:150px; padding:12px 16px; background:var(--panel); border:1px solid var(--line); border-radius:9px; }}
.metric strong {{ display:block; font-size:24px; color:var(--accent); }} .metric span,.muted {{ color:var(--muted); }}
.notice {{ padding:13px 16px; border:1px solid #0e7490; background:#083344; border-radius:8px; margin:16px 0; }} .warning {{ border-color:#b45309; background:#451a03; }}
code {{ font-family:ui-monospace,SFMono-Regular,Menlo,monospace; }} table {{ border-collapse:collapse; width:100%; }} th {{ position:sticky; top:0; background:#172033; z-index:2; text-align:left; }} th,td {{ border:1px solid var(--line); padding:8px; vertical-align:top; }} tbody tr:nth-child(even) {{ background:#0f172a; }}
.compact {{ max-width:1000px; }} .tag {{ display:inline-block; margin-top:4px; padding:2px 6px; border-radius:10px; background:#164e63; color:#cffafe; font-size:12px; }}
.ordinal {{ color:var(--muted); text-align:right; }} .crop {{ width:520px; max-width:38vw; height:auto; }} .placeholder {{ width:420px; max-width:34vw; min-height:120px; display:grid; place-content:center; text-align:center; border:1px dashed #64748b; color:var(--muted); background:#111827; }}
.feature-json {{ white-space:pre-wrap; overflow-wrap:anywhere; display:block; max-width:360px; }} details summary {{ cursor:pointer; color:var(--accent); }} fieldset {{ min-width:190px; border:0; padding:0; }} legend {{ color:var(--muted); margin-bottom:5px; }} fieldset label {{ display:block; white-space:nowrap; }}
@media (max-width:900px) {{ .crop,.placeholder {{ max-width:none; width:300px; }} table {{ font-size:12px; }} }}
</style>
</head>
<body>
<header>
  <h1>Exp111 suspicious tracking events</h1>
  <p class="muted">Static first-pass review artifact. It does not modify or submit any competition output.</p>
  <div class="metrics">{summary_cards}</div>
  <p><strong>Dataset distribution:</strong> {html.escape(dataset_summary)}</p>
  {image_notice}
  <div class="notice warning"><strong>Interpretation limit:</strong> Exp111 records relaxed-motion counts only at dataset level. The 20 <code>relaxed_motion_proxy</code> rows are the highest-distance eligible final links after reserving the exact top 10 longest edges; they are not proven members of the relaxed assignment pass.</div>
</header>
<main>
  <h2>Run-level context</h2>
  {diagnostic_html}
  <p class="muted">Short-track removal is visible at dataset level, but removed components cannot be enumerated faithfully from the emitted final graph. Adaptive rescue was disabled in Exp111.</p>
  <h2>Review queue ({len(events)} events)</h2>
  <p>Radio choices are intentionally local browser state only and are not persisted when the page is closed or reloaded.</p>
  <table id="events">
    <thead><tr><th>#</th><th>Dataset / type</th><th>Source → targets</th><th>Frame / coordinates</th><th>Distances (µm)</th><th>Automatic flags</th><th>Visual crop</th><th>Manual label</th></tr></thead>
    <tbody>{''.join(rows)}</tbody>
  </table>
</main>
</body>
</html>
"""


def main() -> None:
    args = parse_args()
    exp111_dir = args.exp111_dir.resolve()
    output = args.output.resolve()
    submission_path = exp111_dir / "submission.csv"
    stats_path = exp111_dir / "run_stats.csv"
    diagnostics_path = exp111_dir / "exp111_original_branch_diagnostics.csv"
    for required in [submission_path, stats_path, diagnostics_path]:
        if not required.exists():
            raise FileNotFoundError(required)

    nodes, edges = build_graph_tables(submission_path)
    stats = pd.read_csv(stats_path)
    diagnostics = pd.read_csv(diagnostics_path)
    raw = load_raw_geff_metadata(exp111_dir)
    events = select_events(nodes, edges, raw)

    workspace = Path(__file__).resolve().parents[1]
    image_root, checked_paths = find_image_root(args.image_root, workspace)
    image_arrays, image_error = open_image_arrays(image_root, sorted(nodes["dataset"].unique()))
    report = render_report(
        events,
        nodes,
        edges,
        stats,
        diagnostics,
        image_arrays,
        image_root,
        image_error,
        checked_paths,
        args.crop_radius_yx,
        args.crop_radius_z,
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(report, encoding="utf-8")
    print(f"Wrote {output}")
    print(f"Events: {len(events)}")
    print(pd.Series([event["event_type"] for event in events]).value_counts().to_string())
    print(f"Image root: {image_root or 'not found'}")
    if image_error:
        print(f"Image note: {image_error}")


if __name__ == "__main__":
    main()
