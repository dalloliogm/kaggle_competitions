"""Build Exp157: the Exp148 backbone with Trackastra swapped in as the linker.

Exp149 carries our best pipeline (two-seed detection logit blend, adaptive
edge fusion - the family holding public LB 0.913). Exp157 keeps its detection
stage untouched and replaces only the association stage: instead of
`filter_output_graph` rebuilding the lineage from the ILP graph, the detected
centroids are handed to the pretrained Trackastra transformer.

Everything else - the offline dependency bootstrap, the GEFF export, the CSV
serialisation, the dataset coverage assertions - is inherited verbatim so the
only variable is the linker.
"""

from __future__ import annotations

import json
from pathlib import Path

WORKSPACE = Path(
    "/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development"
)
BASE = WORKSPACE / "notebooks" / "biohub-exp149-adaptive-edge-w025.ipynb"
OUT = WORKSPACE / "notebooks" / "biohub-exp157-trackastra-linker-candidate.ipynb"
MODULE = WORKSPACE / "scripts" / "biohub_trackastra_link.py"

TRACKASTRA_MIRROR = "subinium/biohub-trackastra-public-weights-mirror"

HEADER = """# Exp157 - Trackastra association transformer as our linker

Keeps the Exp148 detection stage exactly as it is - two independently seeded
TemporalUNet3D detectors, blended detection logits at weight `0.475`, eight-way
planar TTA - and replaces only the **association** stage. Instead of rebuilding
the lineage from the ILP graph with our motion-relink / gap-repair /
safe-division stack, the detected centroids are linked by
[Trackastra](https://github.com/weigertlab/trackastra) (Gallusser & Weigert,
2024), a transformer trained to associate already-detected objects across
frames.

This is a model-diversity probe on the one stage we have never varied. The
detector has been swept to exhaustion; the linker has always been the same
learned-edge-plus-ILP family.

Three implementation notes.

**The checkpoint is natively 3D.** The `ctc` weights report `coord_dim: 3` and
`feat_dim: 12`, and were trained with `ndim: 3` on sets including
`Fluo-N3DH-CE`, a 3D+time developing embryo. Only the `general_2d` checkpoint is
two-dimensional. No projection or per-slice stitching is involved.

**No segmentation masks are needed.** Trackastra's convenience API asks for
dense instance masks, but its underlying feature container is coordinates plus
a region-property table. Those properties are measured here on a nearest-seed
segmentation grown from our own detections and clipped to foreground intensity,
so the linker consumes exactly the detections our detector produced.

**Coordinates are rescaled.** The model reasons in the pixel units it was
trained on - its spatial cutoff is 256 of them - so physical micrometres are
converted at `TRACKASTRA_COORD_SCALE` units/um before they reach the
positional bias.
"""


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


BOOTSTRAP = f"""# Trackastra: unpack the mirrored pure-python wheel and load the 3D ctc model.
import shutil
import types as _types
import sys as _sys
from pathlib import Path as _Path

TRACKASTRA_ROOTS = [
    _Path("/kaggle/input/datasets/{TRACKASTRA_MIRROR}"),
    _Path("/kaggle/input/{TRACKASTRA_MIRROR.split("/")[-1]}"),
]
TRACKASTRA_DIR = next((p for p in TRACKASTRA_ROOTS if p.exists()), None)
if TRACKASTRA_DIR is None:
    raise FileNotFoundError(
        "Attach {TRACKASTRA_MIRROR}; looked in "
        + ", ".join(str(p) for p in TRACKASTRA_ROOTS)
    )

WHEELS = sorted(TRACKASTRA_DIR.glob("trackastra-*.whl"))
if not WHEELS:
    raise FileNotFoundError(f"No trackastra wheel under {{TRACKASTRA_DIR}}")

CTC_DIR = _Path("/kaggle/working/trackastra_ctc")
CTC_DIR.mkdir(parents=True, exist_ok=True)
for _name in ("config.yaml", "train_config.yaml", "model.pt"):
    _target = CTC_DIR / _name
    if not _target.exists():
        shutil.copy2(TRACKASTRA_DIR / "ctc" / _name, _target)

btl = _types.ModuleType("biohub_trackastra_link")
_BTL_SOURCE = r'''
__MODULE_SOURCE__
'''
exec(compile(_BTL_SOURCE, "biohub_trackastra_link.py", "exec"), btl.__dict__)
_sys.modules["biohub_trackastra_link"] = btl

# Runs after the notebook's own dependency setup, so zarr and geff are real and
# only the genuinely unused native imports get stubbed.
TRACKASTRA_PKG_ROOT = btl.bootstrap_trackastra(WHEELS[0], "/kaggle/working/trackastra_pkg")
import trackastra  # noqa: E402

TRACKASTRA_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
TRACKASTRA_MODEL = btl.load_trackastra_transformer(CTC_DIR, device=TRACKASTRA_DEVICE)
print(
    f"trackastra {{trackastra.__version__}} | ctc coord_dim="
    f"{{TRACKASTRA_MODEL.config['coord_dim']}} feat_dim={{TRACKASTRA_MODEL.config['feat_dim']}} "
    f"window={{TRACKASTRA_MODEL.config['window']}} device={{TRACKASTRA_DEVICE}}"
)
"""

LINKER_CELL = '''# The Trackastra linking stage, in the shape filter_output_graph is called with.
import numpy as np

# Set by Exp156's head-to-head on the labelled train movies.
TRACKASTRA_COORD_SCALE = float(os.environ.get("BIOHUB_TRACKASTRA_COORD_SCALE", "3.0"))
TRACKASTRA_FEATURE_MODE = os.environ.get("BIOHUB_TRACKASTRA_FEATURE_MODE", "image")
TRACKASTRA_MAX_DISTANCE_UM = float(os.environ.get("BIOHUB_TRACKASTRA_MAX_DISTANCE_UM", "12.0"))
TRACKASTRA_GREEDY_THRESHOLD = float(os.environ.get("BIOHUB_TRACKASTRA_GREEDY_THRESHOLD", "0.5"))
TRACKASTRA_MIN_TRACK_LEN = int(os.environ.get("BIOHUB_TRACKASTRA_MIN_TRACK_LEN", "6"))
TRACKASTRA_VOXEL_UM = (1.625, 0.40625, 0.40625)

print(
    f"Trackastra linker: scale={TRACKASTRA_COORD_SCALE} features={TRACKASTRA_FEATURE_MODE} "
    f"max_dist={TRACKASTRA_MAX_DISTANCE_UM}um greedy={TRACKASTRA_GREEDY_THRESHOLD} "
    f"min_track_len={TRACKASTRA_MIN_TRACK_LEN}"
)


def trackastra_link_graph(nodes_by_id, raw_edges, dataset):
    """Relink our detections with Trackastra, dropping the ILP edges.

    Returns the same ``(nodes_by_id, edges, stats)`` triple that
    ``filter_output_graph`` returns, so the CSV serialisation below is
    unchanged. Short-track filtering is kept because the metric penalises
    node overprediction and our node budget is otherwise unchanged.
    """
    by_t = {}
    for node_id, node in nodes_by_id.items():
        by_t.setdefault(int(node["t"]), []).append(node_id)

    t_max = max(by_t) if by_t else -1
    points_by_frame, ids_by_frame = [], []
    for t in range(t_max + 1):
        ordered = sorted(by_t.get(t, []))
        ids_by_frame.append(ordered)
        points_by_frame.append(
            np.array(
                [
                    [nodes_by_id[i]["z"], nodes_by_id[i]["y"], nodes_by_id[i]["x"]]
                    for i in ordered
                ],
                dtype=np.float64,
            ).reshape(-1, 3)
        )

    frame_cache: dict[int, np.ndarray] = {}

    def frame_provider(t):
        # Bound the cache: a whole movie of raw frames does not fit comfortably.
        if len(frame_cache) > 6:
            for key in sorted(frame_cache)[:-3]:
                frame_cache.pop(key, None)
        return read_test_frame(dataset, t, frame_cache)

    window = int(TRACKASTRA_MODEL.config["window"])
    tokens = max(
        (
            sum(len(points_by_frame[t + k]) for k in range(window))
            for t in range(max(1, len(points_by_frame) - window + 1))
        ),
        default=0,
    )
    batch_size = 1 if tokens > 1500 else (2 if tokens > 700 else 4)
    if TRACKASTRA_DEVICE != "cuda":
        batch_size = 1

    solution, link_stats = btl.link_movie(
        points_by_frame=points_by_frame,
        transformer=TRACKASTRA_MODEL,
        frame_provider=frame_provider if TRACKASTRA_FEATURE_MODE == "image" else None,
        feature_mode=TRACKASTRA_FEATURE_MODE,
        coord_scale=TRACKASTRA_COORD_SCALE,
        greedy_threshold=TRACKASTRA_GREEDY_THRESHOLD,
        max_distance_um=TRACKASTRA_MAX_DISTANCE_UM,
        voxel_um=TRACKASTRA_VOXEL_UM,
        batch_size=batch_size,
        progress=lambda x, **k: x,
    )
    frame_cache.clear()

    edges = []
    for s, t in solution.edges():
        sn, tn = solution.nodes[s], solution.nodes[t]
        source_id = ids_by_frame[int(sn["time"])][int(sn["label"]) - 1]
        target_id = ids_by_frame[int(tn["time"])][int(tn["label"]) - 1]
        if int(nodes_by_id[target_id]["t"]) - int(nodes_by_id[source_id]["t"]) != 1:
            raise AssertionError(f"{dataset}: Trackastra edge does not span one frame")
        edges.append(
            {
                "source_id": source_id,
                "target_id": target_id,
                "edge_prob": float(solution.edges[s, t].get("weight", 1.0)),
            }
        )

    stats = dict(link_stats)
    stats["raw_edges"] = len(raw_edges)
    stats["trackastra_edges"] = len(edges)
    stats["max_window_tokens"] = int(tokens)
    stats["batch_size"] = int(batch_size)

    if TRACKASTRA_MIN_TRACK_LEN > 1:
        keep_nodes, edges = _keep_long_tracks(nodes_by_id, edges, TRACKASTRA_MIN_TRACK_LEN)
        stats["removed_short_track_nodes"] = len(nodes_by_id) - len(keep_nodes)
        nodes_by_id = keep_nodes

    ilp_pairs = {(int(e["source_id"]), int(e["target_id"])) for e in raw_edges}
    tk_pairs = {(int(e["source_id"]), int(e["target_id"])) for e in edges}
    stats["agreement_with_ilp"] = len(tk_pairs & ilp_pairs) / max(1, len(tk_pairs | ilp_pairs))
    stats["gap_added_nodes"] = 0
    return nodes_by_id, edges, stats


def _keep_long_tracks(nodes_by_id, edges, min_frames):
    """Drop lineage components that span fewer than ``min_frames`` timepoints."""
    parent = {node_id: node_id for node_id in nodes_by_id}

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for e in edges:
        ra, rb = find(int(e["source_id"])), find(int(e["target_id"]))
        if ra != rb:
            parent[ra] = rb

    spans: dict[int, set] = {}
    for node_id, node in nodes_by_id.items():
        spans.setdefault(find(node_id), set()).add(int(node["t"]))

    keep_roots = {root for root, ts in spans.items() if len(ts) >= min_frames}
    keep_nodes = {
        node_id: node for node_id, node in nodes_by_id.items() if find(node_id) in keep_roots
    }
    kept_edges = [
        e
        for e in edges
        if int(e["source_id"]) in keep_nodes and int(e["target_id"]) in keep_nodes
    ]
    return keep_nodes, kept_edges


print("Trackastra linking stage ready")
'''

HARNESS_CELL = '''# Structural harness - runs on the written submission, before it can be graded.
import pandas as pd

frame = pd.read_csv(SUBMISSION_PATH)
problems = []

if list(frame.columns) != CSV_COLUMNS:
    problems.append(f"column mismatch: {list(frame.columns)}")
if frame.isnull().to_numpy().any():
    problems.append("null values present")
if frame["id"].duplicated().any():
    problems.append("duplicate global ids")

nodes = frame[frame.row_type == "node"]
edges = frame[frame.row_type == "edge"]

if nodes.duplicated(subset=["dataset", "node_id"]).any():
    problems.append("node_id not unique within a dataset")
for column in ("t", "z", "y", "x"):
    if (nodes[column] < 0).any():
        problems.append(f"negative {column} on a node row")

missing = set(test_stems) - set(frame.dataset.unique())
if missing:
    problems.append(f"datasets missing from the submission: {sorted(missing)}")

max_in = max_out = divisions = 0
for dataset, group in edges.groupby("dataset"):
    known = set(nodes[nodes.dataset == dataset].node_id)
    dangling = (~group.source_id.isin(known)) | (~group.target_id.isin(known))
    if dangling.any():
        problems.append(f"{dataset}: {int(dangling.sum())} dangling edges")
    indeg = group.target_id.value_counts()
    outdeg = group.source_id.value_counts()
    if len(indeg):
        max_in = max(max_in, int(indeg.max()))
    if len(outdeg):
        max_out = max(max_out, int(outdeg.max()))
        divisions += int((outdeg >= 2).sum())

if max_in > 1:
    problems.append(f"max indegree {max_in} exceeds 1")
if max_out > 2:
    problems.append(f"max outdegree {max_out} exceeds 2")

print(
    f"rows={len(frame):,} nodes={len(nodes):,} edges={len(edges):,} "
    f"datasets={frame.dataset.nunique()} max_indegree={max_in} max_outdegree={max_out} "
    f"division_like_sources={divisions:,}"
)
import hashlib

print("sha256:", hashlib.sha256(SUBMISSION_PATH.read_bytes()).hexdigest())

if problems:
    raise AssertionError("STRUCTURAL HARNESS FAILED:\\n  " + "\\n  ".join(problems))
print("structural harness passed")
'''


def main() -> int:
    notebook = json.loads(BASE.read_text())
    cells = notebook["cells"]
    module_source = MODULE.read_text()
    # The inlined source is wrapped in an r-string delimited by three single
    # quotes, so the module may contain docstrings but never that delimiter.
    if chr(39) * 3 in module_source:
        raise RuntimeError("module contains the r-string delimiter and cannot be inlined")

    # The serialisation cell is the one that calls the incumbent linker.
    target = None
    for index, cell in enumerate(cells):
        if cell["cell_type"] != "code":
            continue
        if "filter_output_graph(nodes_by_id, raw_edges" in "".join(cell["source"]):
            target = index
            break
    if target is None:
        raise RuntimeError("Could not find the cell that calls filter_output_graph")

    source = "".join(cells[target]["source"])
    old = (
        "        nodes_by_id, edges, filter_stats = filter_output_graph(nodes_by_id, "
        "raw_edges, dataset=dataset, deepcenter_bundle=DEEPCENTER_VETO_DETECTOR)"
    )
    if source.count(old) != 1:
        raise RuntimeError("Expected exactly one filter_output_graph call site")
    new = (
        "        # EXP157: the linker swap. Everything above this line - detection,\n"
        "        # TTA, two-seed blending, ILP node selection - is Exp148 unchanged.\n"
        "        if USE_TRACKASTRA_LINKER:\n"
        "            nodes_by_id, edges, filter_stats = trackastra_link_graph(\n"
        "                nodes_by_id, raw_edges, dataset=dataset\n"
        "            )\n"
        "        else:\n"
        "            nodes_by_id, edges, filter_stats = filter_output_graph(\n"
        "                nodes_by_id, raw_edges, dataset=dataset,\n"
        "                deepcenter_bundle=DEEPCENTER_VETO_DETECTOR,\n"
        "            )"
    )
    source = source.replace(old, new, 1)
    cells[target]["source"] = source.splitlines(keepends=True)

    bootstrap = BOOTSTRAP.replace("__MODULE_SOURCE__", module_source)

    # Insert the Trackastra cells immediately before the serialisation cell so
    # they run after the dependency bootstrap and the inference stage.
    inserted = [
        markdown(
            "## Trackastra linking stage\n\n"
            "`biohub_trackastra_link` is versioned at "
            "`competitions/biohub-cell-tracking-during-development/scripts/"
            "biohub_trackastra_link.py` and inlined here because Kaggle kernels cannot "
            "import from the repository. It is unit tested against the real `ctc` "
            "weights on synthetic 3D movies before every push."
        ),
        code(bootstrap),
        code(
            "USE_TRACKASTRA_LINKER = "
            'os.environ.get("BIOHUB_USE_TRACKASTRA_LINKER", "1") == "1"\n'
            'print("linker:", "trackastra" if USE_TRACKASTRA_LINKER else "incumbent")\n'
        ),
        code(LINKER_CELL),
    ]

    cells[target:target] = inserted
    cells.append(markdown("## Structural validation"))
    cells.append(code(HARNESS_CELL))

    notebook["cells"] = cells
    OUT.write_text(json.dumps(notebook, indent=1))

    # Replace the leading title markdown so the notebook describes Exp157.
    notebook = json.loads(OUT.read_text())
    for index, cell in enumerate(notebook["cells"]):
        if cell["cell_type"] == "markdown" and "Exp149" in "".join(cell["source"]):
            notebook["cells"][index] = markdown(HEADER)
            break
    OUT.write_text(json.dumps(notebook, indent=1))
    print(f"wrote {OUT} with {len(notebook['cells'])} cells")

    metadata = json.loads(
        (WORKSPACE / "notebooks" / "biohub-exp149-adaptive-edge-w025.kernel-metadata.json").read_text()
    )
    metadata["id"] = "dalloliogm/biohub-exp157-trackastra-linker-candidate"
    metadata["title"] = "Biohub Exp157 Trackastra Linker Candidate"
    metadata["code_file"] = OUT.name
    metadata["dataset_sources"] = sorted(set(metadata["dataset_sources"]) | {TRACKASTRA_MIRROR})
    meta_path = OUT.parent / (OUT.stem + ".kernel-metadata.json")
    meta_path.write_text(json.dumps(metadata, indent=2))
    print(f"wrote {meta_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
