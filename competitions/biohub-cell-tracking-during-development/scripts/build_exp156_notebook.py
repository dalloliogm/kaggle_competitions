"""Build the Exp156 notebook from the proven Exp121 diagnostic scaffold.

Exp121 already carries everything the head-to-head needs: the offline
dependency bootstrap, the TemporalUNet3D + node-transformer inference, the ILP
solve, the incumbent post-processing stack, and the official metric on
labelled train movies. Exp156 keeps all of that and replaces only the ablation
stage with a linker comparison, so the detections are provably identical
across arms and the only thing that varies is how they are linked.
"""

from __future__ import annotations

import json
from pathlib import Path

WORKSPACE = Path(
    "/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development"
)
BASE = WORKSPACE / "notebooks" / "biohub-exp121-postprocessing-ablation.ipynb"
OUT = WORKSPACE / "notebooks" / "biohub-exp156-trackastra-linker-headtohead.ipynb"
MODULE = WORKSPACE / "scripts" / "biohub_trackastra_link.py"

TRACKASTRA_MIRROR = "subinium/biohub-trackastra-public-weights-mirror"


def code(src: str) -> dict:
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": src.splitlines(keepends=True),
    }


def markdown(src: str) -> dict:
    return {"cell_type": "markdown", "metadata": {}, "source": src.splitlines(keepends=True)}


HEADER = """# Exp156 - does the Trackastra transformer link our detections better than our own linker?

Alternate-architecture probe. **Writes no submission.**

Trackastra (Gallusser & Weigert 2024) is a transformer that links
already-detected objects across frames. This kernel swaps it in for our
association stage - the learned node transformer plus the ILP - while keeping
our TemporalUNet3D detections byte-identical across every arm, and scores all
arms with the official metric on the labelled train movies.

Three things were resolved before this kernel was written.

**The pretrained weights are natively 3D.** The workspace previously recorded
the Trackastra mirror as "2D/CTC ... poor architectural fit". That is wrong for
the `ctc` checkpoint: its `config.yaml` reports `coord_dim: 3` and
`feat_dim: 12`, and its `train_config.yaml` reports `ndim: 3` with
`Fluo-N3DH-CE` - a 3D+time developing embryo - among the training sets. Only
`general_2d` is 2D. So no per-slice stitching or maximum projection is needed.

**Offline packaging is already solved by the mirror**, which ships
`trackastra-0.5.3-py3-none-any.whl`. A pure-python wheel does not need
installing: it is unpacked onto `sys.path`. Its two native module-scope
imports, `edt` and `lz4.frame`, are stubbed because neither is reachable from
this code path.

**Masks are not needed.** Trackastra's public `track()` API wants dense
instance masks, which we do not have. Its `WRFeatures` container is just
coordinates plus a region-property table, so it is built directly from our
centroids, with the region properties measured on a nearest-seed segmentation
grown from those centroids and clipped to foreground intensity.

The remaining unknown, and the thing this kernel measures, is the domain gap:
Trackastra reasons in the pixel units it was trained on, so our physical
coordinates have to be rescaled before its positional bias means anything.
`COORD_SCALES` sweeps that one knob.
"""

ARMS_NOTE = """## Arms

Every arm starts from the same cached detections, so any difference is
attributable to linking alone.

| arm | linker |
| --- | --- |
| `ilp_only` | our ILP graph exported verbatim |
| `incumbent_full` | our ILP graph plus the full post-processing stack |
| `trackastra_s<scale>` | Trackastra association + greedy lineage, at one coordinate scale |

`incumbent_full` is the Exp110-family recipe carried by this scaffold
(single-seed detector, public LB `0.909`), not the Exp148 two-seed blend that
holds our `0.913`. That is deliberate: every arm has to consume the *same*
detections, and the point of the comparison is the linker. Read the incumbent
column as "our linking stack", and remember the live bar is `0.913`, a little
above it.

A local caveat that `LEARNINGS.md` establishes and that applies here: this
harness inverts leaderboard ranking for *post-processing* choices, and the
labelled split holds only three annotated divisions, so its division numbers
carry no signal. It is a usable ranking signal for **edge quality**, which is
exactly what a linker swap changes.
"""


def main() -> int:
    notebook = json.loads(BASE.read_text())
    cells = notebook["cells"]

    # Keep Exp121 cells 1-9: dependency bootstrap, inference, config, the
    # incumbent post-processing stack, and the cached ILP solve.
    kept = cells[1:10]

    # Exp121 ships with MODE="submit"; this diagnostic scores labelled movies.
    mode_cell = kept[1]
    source = "".join(mode_cell["source"])
    if 'MODE ="submit"' not in source:
        raise RuntimeError("Exp121 cell 2 no longer declares MODE; refusing to guess")
    source = source.replace('MODE ="submit"', 'MODE ="local"')
    mode_cell["source"] = source.splitlines(keepends=True)

    module_source = MODULE.read_text()

    bootstrap = f'''# Trackastra: unpack the mirrored wheel and load the 3D ctc checkpoint.
import shutil
from pathlib import Path

TRACKASTRA_ROOTS = [
    Path("/kaggle/input/datasets/{TRACKASTRA_MIRROR}"),
    Path("/kaggle/input/{TRACKASTRA_MIRROR.split("/")[-1]}"),
]
TRACKASTRA_DIR = next((p for p in TRACKASTRA_ROOTS if p.exists()), None)
if TRACKASTRA_DIR is None:
    raise FileNotFoundError(
        "Attach the dataset {TRACKASTRA_MIRROR}; looked in "
        + ", ".join(str(p) for p in TRACKASTRA_ROOTS)
    )
print("trackastra mirror:", TRACKASTRA_DIR)

WHEELS = sorted(TRACKASTRA_DIR.glob("trackastra-*.whl"))
if not WHEELS:
    raise FileNotFoundError(f"No trackastra wheel under {{TRACKASTRA_DIR}}")

# The ctc folder is read-only under /kaggle/input, and from_folder writes
# nothing, but the weights and both yaml files must sit together.
CTC_SRC = TRACKASTRA_DIR / "ctc"
CTC_DIR = Path("/kaggle/working/trackastra_ctc")
CTC_DIR.mkdir(parents=True, exist_ok=True)
for name in ("config.yaml", "train_config.yaml", "model.pt"):
    target = CTC_DIR / name
    if not target.exists():
        shutil.copy2(CTC_SRC / name, target)
print("ctc model folder:", sorted(p.name for p in CTC_DIR.iterdir()))
'''

    comparison = '''# STAGE B - link the SAME detections three ways and score each officially.
import time
from collections import defaultdict

import numpy as np

TRACKASTRA_ROOT = btl.bootstrap_trackastra(WHEELS[0], "/kaggle/working/trackastra_pkg")
import trackastra  # noqa: E402

print("trackastra", trackastra.__version__, "from", TRACKASTRA_ROOT)

TRACKASTRA_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
transformer = btl.load_trackastra_transformer(CTC_DIR, device=TRACKASTRA_DEVICE)
print(
    "ctc checkpoint: coord_dim=%s feat_dim=%s window=%s cutoff=%s"
    % (
        transformer.config["coord_dim"],
        transformer.config["feat_dim"],
        transformer.config["window"],
        transformer.config["spatial_pos_cutoff"],
    )
)

# The one hyperparameter the 2D->3D domain transfer turns on. Local synthetic
# probes put the optimum near 2-3 units/um for our nucleus spacing; the
# bracket is swept here on real data because the synthetic proxy has no
# appearance variation and cannot settle it.
COORD_SCALES = [2.0, 3.0, 4.0]
TRACKASTRA_FEATURE_MODE = "image"
TRACKASTRA_MAX_DISTANCE_UM = 12.0
TRACKASTRA_GREEDY_THRESHOLD = 0.5

truth = {}
for sid in valid_id:
    ds = open_dataset(
        f"{KAGGLE_DIR}/train/{sid}.zarr",
        normalize=False,
        load_image=False,
        require_tracks=True,
    )
    md = GeffMetadata.read(f"{KAGGLE_DIR}/train/{sid}.geff")
    truth[sid] = {
        "graph": ds.tracks,
        "scale": ds.scale,
        "n_total": float(md.extra["estimated_number_of_nodes"]),
    }

VOXEL_UM = tuple(float(v) for v in truth[valid_id[0]]["scale"][-3:])
print("physical voxel size (z, y, x) um:", VOXEL_UM)


def graph_from_nodes_edges(nodes_by_id, edges):
    g = td.graph.InMemoryGraph()
    for k in ["z", "y", "x"]:
        g.add_node_attr_key(k, pl.Float64, -999999.0)
    ids = sorted(nodes_by_id)
    new = g.bulk_add_nodes(
        [
            {
                "t": int(nodes_by_id[i]["t"]),
                "z": float(nodes_by_id[i]["z"]),
                "y": float(nodes_by_id[i]["y"]),
                "x": float(nodes_by_id[i]["x"]),
            }
            for i in ids
        ]
    )
    remap = dict(zip(ids, new))
    if edges:
        g.add_edge_attr_key("edge_prob", pl.Float64, 0.0)
        g.bulk_add_edges(
            [
                {
                    "source_id": remap[int(e["source_id"])],
                    "target_id": remap[int(e["target_id"])],
                    "edge_prob": float(e.get("edge_prob") or 0.0),
                }
                for e in edges
            ]
        )
    return g


def load_cached(sid):
    d = np.load(f"{CACHE_DIR}/{sid}.npz")
    nodes_by_id = {
        int(r[0]): {
            "node_id": int(r[0]),
            "t": int(r[1]),
            "z": float(r[2]),
            "y": float(r[3]),
            "x": float(r[4]),
        }
        for r in d["node"]
    }
    edges = [
        {"source_id": int(r[0]), "target_id": int(r[1]), "edge_prob": float(r[2])}
        for r in d["edge"]
    ]
    return nodes_by_id, edges


def detections_by_frame(nodes_by_id):
    """Group our detections by timepoint, keeping a map back to node ids."""
    by_t = defaultdict(list)
    for node_id, node in nodes_by_id.items():
        by_t[int(node["t"])].append((node_id, node))
    t_max = max(by_t) if by_t else -1
    points, ids = [], []
    for t in range(t_max + 1):
        rows = sorted(by_t.get(t, []), key=lambda kv: kv[0])
        points.append(
            np.array([[r[1]["z"], r[1]["y"], r[1]["x"]] for r in rows], dtype=np.float64).reshape(
                -1, 3
            )
        )
        ids.append([r[0] for r in rows])
    return points, ids


def trackastra_edges(sid, nodes_by_id, coord_scale):
    """Link one movie with Trackastra, returning edges over OUR node ids."""
    points, ids = detections_by_frame(nodes_by_id)
    volume, _meta = load_volume(sid)  # already xy-subsampled by SUBSAMPLE

    # Attention is quadratic in the tokens per window (window_size frames of
    # detections at once), and the dense 6bba movie carries ~3k. Size the batch
    # from the actual token count so the big movie does not exhaust the T4.
    window = int(transformer.config["window"])
    tokens = max(
        (sum(len(points[t + k]) for k in range(window)) for t in range(max(1, len(points) - window + 1))),
        default=0,
    )
    batch_size = 1 if tokens > 1500 else (2 if tokens > 700 else 4)
    if TRACKASTRA_DEVICE != "cuda":
        batch_size = 1

    solution, stats = btl.link_movie(
        points_by_frame=points,
        transformer=transformer,
        frame_provider=lambda t: volume[t],
        feature_mode=TRACKASTRA_FEATURE_MODE,
        coord_scale=coord_scale,
        greedy_threshold=TRACKASTRA_GREEDY_THRESHOLD,
        max_distance_um=TRACKASTRA_MAX_DISTANCE_UM,
        # Points stay in original-resolution voxels; the volume is already
        # subsampled, so it must not be pooled a second time.
        pool_factor=1,
        point_downsample=int(SUBSAMPLE[1]),
        voxel_um=VOXEL_UM,
        batch_size=batch_size,
        progress=lambda x, **k: x,
    )
    stats["max_window_tokens"] = int(tokens)
    stats["batch_size"] = int(batch_size)

    edges = []
    for s, t in solution.edges():
        sn, tn = solution.nodes[s], solution.nodes[t]
        edges.append(
            {
                "source_id": ids[int(sn["time"])][int(sn["label"]) - 1],
                "target_id": ids[int(tn["time"])][int(tn["label"]) - 1],
                "edge_prob": float(solution.edges[s, t].get("weight", 1.0)),
            }
        )
    return edges, stats


def score_arm(sid, nodes_by_id, edges):
    g = graph_from_nodes_edges(nodes_by_id, edges)
    er = evaluate(g, truth[sid]["graph"], scale=truth[sid]["scale"], max_distance=7.0)
    rec = node_recall(g, truth[sid]["graph"])
    m = per_sample_metrics(er=er, n_total=truth[sid]["n_total"], node_recall=rec)
    outdeg = defaultdict(int)
    for e in edges:
        outdeg[int(e["source_id"])] += 1
    return {
        "dataset": sid,
        "nodes": len(nodes_by_id),
        "edges": len(edges),
        "forks": sum(1 for v in outdeg.values() if v >= 2),
        "edge_tp": er.edge_tp,
        "edge_fp": er.edge_fp,
        "edge_fn": er.edge_fn,
        "div_tp": er.division_tp,
        "div_fp": er.division_fp,
        "div_fn": er.division_fn,
        "adj_edge_jaccard": m["adj_edge_jaccard"],
    }


ARMS = ["ilp_only", "incumbent_full"] + [f"trackastra_s{s:g}" for s in COORD_SCALES]
rows, diagnostics = [], []

for sid in valid_id:
    nodes_by_id, ilp_edges = load_cached(sid)
    print(f"\\n{'=' * 72}\\n{sid}: {len(nodes_by_id):,} detections, {len(ilp_edges):,} ILP edges\\n{'=' * 72}", flush=True)

    arm_edges = {"ilp_only": (nodes_by_id, ilp_edges)}

    nb_full, ed_full, _st = filter_output_graph(
        dict(nodes_by_id), list(ilp_edges), dataset=sid,
        deepcenter_bundle=DEEPCENTER_VETO_DETECTOR,
    )
    arm_edges["incumbent_full"] = (nb_full, ed_full)

    for scale in COORD_SCALES:
        t0 = time.time()
        tk_edges, stats = trackastra_edges(sid, nodes_by_id, scale)
        stats.update(dataset=sid, coord_scale=scale, seconds=time.time() - t0)
        diagnostics.append(stats)
        print(
            f"  trackastra scale={scale:g}: {len(tk_edges):,} edges "
            f"(median NN {stats['median_nn_um']:.2f} um, cutoff "
            f"{stats['spatial_pos_cutoff_um']:.1f} um, {stats['seconds']:.0f}s)",
            flush=True,
        )
        arm_edges[f"trackastra_s{scale:g}"] = (nodes_by_id, tk_edges)

    ilp_set = {(int(e["source_id"]), int(e["target_id"])) for e in ilp_edges}
    for arm in ARMS:
        nb, ed = arm_edges[arm]
        r = score_arm(sid, nb, ed)
        r["arm"] = arm
        pred_set = {(int(e["source_id"]), int(e["target_id"])) for e in ed}
        r["agreement_with_ilp"] = (
            len(pred_set & ilp_set) / max(1, len(pred_set | ilp_set))
        )
        rows.append(r)
        print(
            f"  {arm:<20} nodes={r['nodes']:>7,} edges={r['edges']:>7,} "
            f"forks={r['forks']:>4,} eTP/FP/FN={r['edge_tp']}/{r['edge_fp']}/{r['edge_fn']} "
            f"adjJ={r['adj_edge_jaccard']:.5f} ilpJ={r['agreement_with_ilp']:.3f}",
            flush=True,
        )

pd.DataFrame(rows).to_csv("/kaggle/working/exp156_linker_headtohead.csv", index=False)
pd.DataFrame(diagnostics).to_csv("/kaggle/working/exp156_trackastra_diagnostics.csv", index=False)
print("\\nwrote exp156_linker_headtohead.csv and exp156_trackastra_diagnostics.csv")
'''

    summary = '''# SUMMARY - edge quality per arm, weighted the way the official metric weights it.
import pandas as pd

df = pd.DataFrame(rows)
SIXBBA = [s for s in valid_id if s.startswith("6bba")]


def aggregate(sub):
    denom = (sub["edge_tp"] + sub["edge_fp"] + sub["edge_fn"]).sum()
    if denom == 0:
        return float("nan")
    return float(
        (sub["adj_edge_jaccard"] * (sub["edge_tp"] + sub["edge_fp"] + sub["edge_fn"])).sum()
        / denom
    )


print(f"{'arm':<20}{'adjJ_all':>10}{'adjJ_6bba':>11}{'edges':>10}{'forks':>8}{'ilp_agree':>11}")
table = []
for arm in ARMS:
    sub = df[df.arm == arm]
    row = {
        "arm": arm,
        "adj_edge_jaccard_all": aggregate(sub),
        "adj_edge_jaccard_6bba": aggregate(sub[sub.dataset.isin(SIXBBA)]),
        "edges": int(sub["edges"].sum()),
        "forks": int(sub["forks"].sum()),
        "agreement_with_ilp": float(sub["agreement_with_ilp"].mean()),
    }
    table.append(row)
    print(
        f"{arm:<20}{row['adj_edge_jaccard_all']:>10.5f}{row['adj_edge_jaccard_6bba']:>11.5f}"
        f"{row['edges']:>10,}{row['forks']:>8,}{row['agreement_with_ilp']:>11.3f}"
    )

pd.DataFrame(table).to_csv("/kaggle/working/exp156_summary.csv", index=False)

best_tk = max(
    (r for r in table if r["arm"].startswith("trackastra")),
    key=lambda r: r["adj_edge_jaccard_all"],
)
incumbent = next(r for r in table if r["arm"] == "incumbent_full")
delta = best_tk["adj_edge_jaccard_all"] - incumbent["adj_edge_jaccard_all"]
print(
    f"\\nbest Trackastra arm {best_tk['arm']} is {delta:+.5f} against incumbent_full "
    f"on local adjusted edge Jaccard."
)
print(
    "DECISION RULE: only spend a submission slot if a Trackastra arm is within "
    "~0.01 of incumbent_full here. The local harness cannot rank post-processing, "
    "but a linker that loses badly on edge quality will not win on the leaderboard."
)
'''

    guard = '''# GUARD - this kernel is a diagnostic and must never emit a submission.
import os

for name in ("/kaggle/working/submission.csv", "submission.csv"):
    if os.path.exists(name):
        os.remove(name)
        print("removed stray", name)
print("no submission written - Exp156 is a diagnostic")
'''

    notebook["cells"] = (
        [markdown(HEADER)]
        + kept
        + [
            code(bootstrap),
            markdown(
                "## The linker module\n\nVersioned in the repository at "
                "`competitions/biohub-cell-tracking-during-development/scripts/"
                "biohub_trackastra_link.py` and inlined here because Kaggle kernels "
                "cannot import from the repo. It is unit tested locally against the "
                "real `ctc` weights on synthetic 3D movies."
            ),
            code(
                "# Inlined from scripts/biohub_trackastra_link.py - edit there, not here.\n"
                "import types as _types, sys as _sys\n"
                "btl = _types.ModuleType('biohub_trackastra_link')\n"
                "_BTL_SOURCE = r'''\n" + module_source + "\n'''\n"
                "exec(compile(_BTL_SOURCE, 'biohub_trackastra_link.py', 'exec'), btl.__dict__)\n"
                "_sys.modules['biohub_trackastra_link'] = btl\n"
                "print('linker module loaded:', [n for n in dir(btl) if not n.startswith('_')][:8])\n"
            ),
            markdown(ARMS_NOTE),
            code(comparison),
            code(summary),
            code(guard),
        ]
    )

    OUT.write_text(json.dumps(notebook, indent=1))
    print(f"wrote {OUT} with {len(notebook['cells'])} cells")

    metadata = {
        "id": "dalloliogm/biohub-exp156-trackastra-linker-headtohead",
        "title": "Biohub Exp156 Trackastra Linker Headtohead",
        "code_file": OUT.name,
        "language": "python",
        "kernel_type": "notebook",
        "is_private": True,
        "enable_gpu": True,
        "enable_tpu": False,
        "enable_internet": False,
        "keywords": ["gpu"],
        "dataset_sources": [
            "pilkwang/biohub-tracking-support-pack-50ep-v1",
            TRACKASTRA_MIRROR,
        ],
        "kernel_sources": [],
        "competition_sources": ["biohub-cell-tracking-during-development"],
        "model_sources": [],
        "machine_shape": "NvidiaTeslaT4",
    }
    meta_path = OUT.with_suffix("").with_suffix("")
    meta_path = OUT.parent / (OUT.stem + ".kernel-metadata.json")
    meta_path.write_text(json.dumps(metadata, indent=2))
    print(f"wrote {meta_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
