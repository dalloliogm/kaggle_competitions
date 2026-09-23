#!/usr/bin/env python3
"""Can we predict which cells the annotators labelled?

The node-count oracle (2026-09-23) put the ceiling at **+0.1228** for keeping
only the 3.18% of predicted nodes that match a GT node, at zero cost in true
positives. The obstacle is selectivity: break-even is **422 nodes removed per
TP edge lost**, and track-length pruning tops out at 281.

A filter needs to beat 422. That is 1.5x better than the best handle we have,
not 10x. Whether it exists depends entirely on whether "this cell is annotated"
is predictable from things visible at inference time.

This run answers that, and nothing else. For every predicted node on the 24
held-out videos it dumps inference-time features plus the GT-matched label, so
separability can be tested offline without further GPU time:

    t, t_frac          frame index, and position through the video
    z, y, x            physical position
    deg_in, deg_out    graph degree
    track_len          length of the weakly-connected component
    pos_in_track       0 at the start of a track, 1 at the end
    mean_edge_prob     mean learned probability over incident edges
    n_within_10um      local crowding in the same frame
    dist_nn_um         distance to the nearest node in the same frame
    synthetic          node introduced by gap-close/gap2 rather than detected
    matched            1 if it matched a GT node (the LABEL)

The label is used for evaluation only - every feature is computable at
inference. If matched nodes are separable, the remaining days build the filter;
if they are not, the direction closes and we stop, having spent one kernel
instead of five days.

Reading the result: the number that matters is not accuracy or AUC, it is the
**exchange rate at a given threshold** - nodes dropped per matched node dropped,
converted to nodes per TP edge. Anything below 422 does not pay, however good
the ROC curve looks.

This costs GPU time and no submission slot.
"""

from __future__ import annotations

import importlib.util
import json
import re
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
WORKSPACE = SCRIPTS.parent
SOURCE = Path(
    "/tmp/claude-0/-home-user-kaggle-competitions/"
    "079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad/audit946"
)
OUT_DIR = WORKSPACE / "notebooks" / "sep23-nodefeatures"
TITLE = "Biohub Sep23 Nodefeatures Held Out"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


density = _load("build_sep18_density_adaptive")
divrule = _load("build_sep18_validator_local_division")
kdtree = _load("build_sep15_relink_kdtree")

CONFIG = (
    '# Arm F on 24 held-out videos. The post-process sweep is disabled: this\n'
    '# run dumps node features once at the base configuration, nothing else.\n'
    'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"'
                for k, v in density.ARMS["biohub-sep18-density-full"]["env"])
)

FEATURE_CELL = r'''
# ============================================================
# NODE FEATURE DUMP -- is "annotated" predictable at inference time?
# ============================================================
# Every feature below is computable without GT. `matched` is the label and is
# used for evaluation only. Break-even for any filter built on this is 422
# nodes removed per TP edge lost.
import csv as _csv
import collections as _collections

FEAT_PATH = WORKING_DIR / "node_features.csv"
_FIELDS = ["stem", "node_id", "t", "t_frac", "z", "y", "x", "deg_in", "deg_out",
           "track_len", "pos_in_track", "mean_edge_prob", "n_within_10um",
           "dist_nn_um", "synthetic", "matched"]
_written = 0
_matched_total = 0

if VALIDATOR_ENABLE and val_stems and VAL_RAW_GRAPHS:
    _fh = FEAT_PATH.open("w", newline="")
    _writer = _csv.DictWriter(_fh, fieldnames=_FIELDS)
    _writer.writeheader()

    for _stem in val_stems:
        if _stem not in VAL_RAW_GRAPHS or _stem not in VAL_GT:
            continue
        _nodes_raw, _edges_raw = VAL_RAW_GRAPHS[_stem]
        _gt_nodes, _gt_edges, _t_true = VAL_GT[_stem]

        _real = TEST_DIR
        globals()["TEST_DIR"] = TRAIN_DIR
        try:
            _nb, _eb, _st = filter_output_graph(
                {k: dict(v) for k, v in _nodes_raw.items()},
                [dict(e) for e in _edges_raw],
                dataset=_stem, deepcenter_bundle=DEEPCENTER_VETO_DETECTOR,
            )
        finally:
            globals()["TEST_DIR"] = _real

        _pred_nodes = nodes_by_id_to_plain(_nb)
        _p2g, _g2p = match_nodes_bipartite(_pred_nodes, _gt_nodes, VALIDATOR_MATCH_RADIUS_UM)

        _deg_in = _collections.Counter()
        _deg_out = _collections.Counter()
        _probs = _collections.defaultdict(list)
        _adj = _collections.defaultdict(set)
        for _e in _eb:
            _s, _t = int(_e["source_id"]), int(_e["target_id"])
            _deg_out[_s] += 1
            _deg_in[_t] += 1
            _adj[_s].add(_t)
            _adj[_t].add(_s)
            _p = _e.get("edge_prob")
            if _p is not None:
                _probs[_s].append(float(_p))
                _probs[_t].append(float(_p))

        # Weakly-connected components give track length and position in track.
        _comp = {}
        _cid = 0
        for _n in _nb:
            if _n in _comp:
                continue
            _stack = [_n]
            _comp[_n] = _cid
            _members = [_n]
            while _stack:
                _c = _stack.pop()
                for _o in _adj.get(_c, ()):
                    if _o not in _comp:
                        _comp[_o] = _cid
                        _members.append(_o)
                        _stack.append(_o)
            _cid += 1
        _comp_members = _collections.defaultdict(list)
        for _n, _c in _comp.items():
            _comp_members[_c].append(_n)
        _comp_len = {_c: len(_m) for _c, _m in _comp_members.items()}
        _comp_t0 = {_c: min(int(_nb[_n]["t"]) for _n in _m) for _c, _m in _comp_members.items()}
        _comp_t1 = {_c: max(int(_nb[_n]["t"]) for _n in _m) for _c, _m in _comp_members.items()}

        _by_t = _collections.defaultdict(list)
        for _n, _node in _nb.items():
            _by_t[int(_node["t"])].append(_n)
        _tmax = max(_by_t) if _by_t else 1

        for _t, _ids in _by_t.items():
            _pos = np.stack([_position_um(_nb[_i]) for _i in _ids])
            _tree = cKDTree(_pos)
            _counts = _tree.query_ball_point(_pos, 10.0, return_length=True)
            # k=2 because the nearest neighbour of a point is itself.
            _nnd, _ = _tree.query(_pos, k=min(2, len(_ids)))
            for _j, _i in enumerate(_ids):
                _node = _nb[_i]
                _c = _comp[_i]
                _span = max(1, _comp_t1[_c] - _comp_t0[_c])
                _pl = _probs.get(_i, [])
                _nn = float(_nnd[_j][1]) if len(_ids) > 1 and _nnd.ndim == 2 else float("nan")
                _writer.writerow({
                    "stem": _stem, "node_id": _i, "t": _t,
                    "t_frac": round(_t / _tmax, 4) if _tmax else 0.0,
                    "z": round(float(_node["z"]), 2), "y": round(float(_node["y"]), 2),
                    "x": round(float(_node["x"]), 2),
                    "deg_in": _deg_in.get(_i, 0), "deg_out": _deg_out.get(_i, 0),
                    "track_len": _comp_len[_c],
                    "pos_in_track": round((_t - _comp_t0[_c]) / _span, 4),
                    "mean_edge_prob": round(sum(_pl) / len(_pl), 4) if _pl else "",
                    "n_within_10um": int(_counts[_j]) - 1,
                    "dist_nn_um": round(_nn, 3) if _nn == _nn else "",
                    "synthetic": int(bool(_node.get("gap_added") or _node.get("synthetic"))),
                    "matched": int(_p2g.get(_i) is not None),
                })
                _written += 1
                _matched_total += int(_p2g.get(_i) is not None)
        print(f"  {_stem}: {len(_pred_nodes):,} nodes dumped")

    _fh.close()
    print("=" * 72)
    print(f"NODE FEATURES: {_written:,} rows, {_matched_total:,} matched "
          f"({_matched_total / max(1, _written) * 100:.2f}%)")
    print(f"  wrote {FEAT_PATH}")
    print("  Break-even for any filter on these: 422 nodes removed per TP edge lost.")
else:
    print("NODE FEATURES: validator disabled -- skipping.")
'''


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    div_cell = [i for i, s in enumerate(before) if "def compute_division_confusion" in s][0]
    oc = before[div_cell]
    old_fn = oc[oc.find("def compute_division_confusion"):oc.find("def decompose_errors")]

    edits = {
        "config": (density.ANCHOR, CONFIG),
        "flags": (density.FLAG_ANCHOR, density.FLAG_NEW),
        "gate": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        "kdtree": (kdtree.OLD_LOOP, kdtree.NEW_LOOP),
        "division": (old_fn, divrule.NEW_FUNCTION),
    }
    counts = {k: 0 for k in edits}
    for cell in nb["cells"]:
        if cell["cell_type"] != "code":
            continue
        text = "".join(cell["source"])
        touched = False
        for name, (old, new) in edits.items():
            if old in text:
                counts[name] += text.count(old)
                text = text.replace(old, new, 1)
                touched = True
        if touched:
            cell["source"] = text.splitlines(keepends=True)
    for name, hits in counts.items():
        if hits != 1:
            raise RuntimeError(f"{name}: expected one match, found {hits}")

    after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    changed = [i for i, (a, b) in enumerate(zip(before, after)) if a != b]
    if changed != [0, 2, 5, 8]:
        raise RuntimeError(f"unexpected cells changed: {changed}")

    joined = "\n".join(after)
    for fn in ("nodes_by_id_to_plain", "match_nodes_bipartite", "filter_output_graph",
               "_position_um"):
        if f"def {fn}" not in joined:
            raise RuntimeError(f"feature cell calls {fn}() but it is not defined")
    for var in ("VAL_RAW_GRAPHS", "VAL_GT", "VALIDATOR_MATCH_RADIUS_UM",
                "DEEPCENTER_VETO_DETECTOR", "cKDTree"):
        if var not in joined:
            raise RuntimeError(f"feature cell uses {var} but it is never defined")

    nb["cells"].append({"cell_type": "code", "execution_count": None, "metadata": {},
                        "outputs": [], "source": FEATURE_CELL.splitlines(keepends=True)})

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"{SLUG}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")
    metadata = json.loads((SOURCE / "kernel-metadata.json").read_text())
    metadata.update({"id": f"dalloliogm/{SLUG}", "title": TITLE,
                     "code_file": out.name, "is_private": True})
    for key in ("id_no", "docker_image"):
        metadata.pop(key, None)
    (OUT_DIR / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"wrote {out.relative_to(WORKSPACE)}")
    print("  dumps per-node inference features + the GT-matched label")


if __name__ == "__main__":
    main()
