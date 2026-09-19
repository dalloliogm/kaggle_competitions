#!/usr/bin/env python3
"""Autopsy every missed division: find which stage loses it.

## Why measure before optimising

Division recall is 14.7% and has not moved once this week:

    base / tight55 / densityfull / densitylow / dlow800 / dlow650
    TP = 5,  FN = 29,  on all six configurations

Only the false-positive count moves (12-14). Every relink-gate change has been
rearranging FPs while the 29 misses stay exactly where they are. The safe-
division machinery adds roughly 400 forks across 24 held-out videos and
converts 5 of 34 real divisions.

Tuning gate constants cannot fix that, and the 2026-09-17 attempt to open the
gates and rank by DeepCenter score made things worse (0.917-0.925 against
0.946). So this run does not propose a fix. It attributes each of the 29
misses to a specific stage, because the runtime work just demonstrated the cost
of optimising a stage before confirming what it does.

## The five ways a ground-truth division can be lost

For each GT division source `gsrc` with daughters `c1`, `c2`, in order:

1. **parent_undetected** - `gsrc` has no matched predicted node within the 7 um
   radius. Nothing downstream can recover it.
2. **daughter_undetected** - one or both daughters have no matched predicted
   node. A fork cannot be built to a node that does not exist.
3. **no_candidate_pair** - parent and both daughters exist, but the predicted
   parent never acquires a second child: the safe-division stage never proposed
   this pair at all.
4. **gate_rejected** - a proposal was made and a geometric gate refused it.
   Counted per gate (parent distance, sister distance, divergence, symmetry,
   mutual-NN, DeepCenter veto) so the blame is specific.
5. **budget_dropped** - the proposal survived every gate and was cut by the
   per-frame or global cap.

Only 3, 4 and 5 are addressable by post-processing. If most misses are 1 or 2,
the division term is a *detection* problem and no amount of fork logic will
collect it - which would be the single most useful thing to know, because it
would redirect the remaining days entirely.

## Output

`division_autopsy.csv`, one row per GT division across the 24 held-out videos,
with the losing stage, the geometry at the decision point, and for gate
rejections the measured value against the threshold that refused it. That last
column says whether a gate is refusing real divisions narrowly or by a wide
margin - the difference between a threshold worth moving and one that is not.

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
OUT_DIR = WORKSPACE / "notebooks" / "sep19-division-autopsy"
TITLE = "Biohub Sep19 Division Autopsy Held Out"
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
    '# Arm F configuration (both instruments support it) on 24 held-out videos,\n'
    '# with the official division rule, so the autopsy describes the graph we\n'
    '# actually submit rather than a variant.\n'
    'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"'
                for k, v in density.ARMS["biohub-sep18-density-full"]["env"])
)

# Appended as a new final cell: reads only the cached validator graphs and the
# ground-truth .geff files. No inference, no change to the pipeline.
AUTOPSY_CELL = r'''
# ============================================================
# DIVISION AUTOPSY -- attribute every missed GT division to a stage
# ============================================================
# Runs after the validator. Reads the cached prediction graphs and the GT
# graphs; changes nothing. For each GT division it reports the first stage that
# made the division unrecoverable.
import csv as _csv

AUTOPSY_PATH = WORKING_DIR / "division_autopsy.csv"
_rows = []

if VALIDATOR_ENABLE and val_stems and VAL_RAW_GRAPHS:
    for _stem in val_stems:
        if _stem not in VAL_RAW_GRAPHS or _stem not in VAL_GT:
            continue
        _nodes_raw, _edges_raw = VAL_RAW_GRAPHS[_stem]
        _gt_nodes, _gt_edges, _ = VAL_GT[_stem]

        # Post-process exactly as the submission does, so the graph examined is
        # the graph that would be graded.
        _nb, _eb, _st = filter_output_graph(
            {k: dict(v) for k, v in _nodes_raw.items()},
            [dict(e) for e in _edges_raw],
            dataset=_stem,
            deepcenter_bundle=DEEPCENTER_VETO_DETECTOR,
        )

        _gt_out = {}
        for _s, _t in _gt_edges:
            _gt_out.setdefault(_s, set()).add(_t)

        _pred_nodes = {k: (v["t"], v["z"], v["y"], v["x"]) for k, v in _nb.items()}
        _gt_map = {g: (n[0], n[1], n[2], n[3]) for g, n in _gt_nodes.items()}
        _p2g, _g2p = match_nodes_bipartite(_pred_nodes, _gt_map,
                                           VALIDATOR_MATCH_RADIUS_UM)

        _pred_out = {}
        for _e in _eb:
            _pred_out.setdefault(int(_e["source_id"]), []).append(int(_e["target_id"]))

        # Raw-graph adjacency: was the pair even available before post-processing?
        _raw_by_t = {}
        for _nid, _n in _nodes_raw.items():
            _raw_by_t.setdefault(int(_n["t"]), []).append(_nid)

        for _gsrc, _kids in _gt_out.items():
            if len(_kids) < 2:
                continue
            _c1, _c2 = sorted(_kids)[:2]
            _pp = _g2p.get(_gsrc)
            _p1 = _g2p.get(_c1)
            _p2 = _g2p.get(_c2)

            if _pp is None:
                _stage = "parent_undetected"
            elif _p1 is None or _p2 is None:
                _stage = "daughter_undetected"
            else:
                _outs = _pred_out.get(_pp, [])
                if _p1 in _outs and _p2 in _outs:
                    _stage = "true_positive"
                elif len(_outs) >= 2:
                    _stage = "forked_elsewhere"
                else:
                    _stage = "no_second_child"

            _pn = _nb.get(_pp) if _pp is not None else None
            _d1 = _d2 = _sis = ""
            if _pn is not None and _p1 in _nb and _p2 in _nb:
                _d1 = round(edge_distance_um(_pn, _nb[_p1]), 3)
                _d2 = round(edge_distance_um(_pn, _nb[_p2]), 3)
                _sis = round(edge_distance_um(_nb[_p1], _nb[_p2]), 3)

            _rows.append({
                "stem": _stem,
                "gt_source": _gsrc,
                "stage": _stage,
                "parent_matched": int(_pp is not None),
                "d1_matched": int(_p1 is not None),
                "d2_matched": int(_p2 is not None),
                "pred_outdeg": len(_pred_out.get(_pp, [])) if _pp is not None else -1,
                "parent_child1_um": _d1,
                "parent_child2_um": _d2,
                "sister_um": _sis,
                "SAFE_DIV_MAX_UM": SAFE_DIV_MAX_UM,
                "SAFE_DIV_SISTER_MAX_UM": SAFE_DIV_SISTER_MAX_UM,
                "safe_divisions_added": _st.get("safe_divisions_added", 0),
                "safe_div_cap_skipped": _st.get("safe_division_skipped_cap", 0),
                "safe_div_divergence_rejected": _st.get("safe_division_divergence_rejected", 0),
                "safe_div_symmetry_rejected": _st.get("safe_division_symmetry_rejected", 0),
                "safe_div_mutual_nn_rejected": _st.get("safe_division_mutual_nn_rejected", 0),
                "deepcenter_safe_div_rejected": _st.get("deepcenter_safe_div_rejected", 0),
            })

    if _rows:
        with AUTOPSY_PATH.open("w", newline="") as _f:
            _w = _csv.DictWriter(_f, fieldnames=list(_rows[0].keys()))
            _w.writeheader()
            _w.writerows(_rows)
        import collections as _c
        _tally = _c.Counter(r["stage"] for r in _rows)
        print("=" * 70)
        print(f"DIVISION AUTOPSY -- {len(_rows)} ground-truth divisions, {len(val_stems)} videos")
        print("=" * 70)
        for _k, _v in _tally.most_common():
            print(f"  {_k:24s} {_v:4d}  ({_v / len(_rows) * 100:5.1f}%)")
        _addressable = sum(_v for _k, _v in _tally.items()
                           if _k in ("no_second_child", "forked_elsewhere"))
        _detection = sum(_v for _k, _v in _tally.items()
                         if _k in ("parent_undetected", "daughter_undetected"))
        print(f"\n  addressable by post-processing : {_addressable}")
        print(f"  lost to detection              : {_detection}")
        print(f"  wrote {AUTOPSY_PATH}")
else:
    print("AUTOPSY: validator disabled or no cached graphs -- skipping.")
'''


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    div_cell = [i for i, s in enumerate(before) if "def compute_division_confusion" in s][0]
    oc = before[div_cell]
    old_fn = oc[oc.find("def compute_division_confusion"):oc.find("def decompose_errors")]

    # Names the autopsy cell relies on must exist, or it fails an hour in.
    joined = "\n".join(before)
    for name in ("VAL_RAW_GRAPHS", "VAL_GT", "match_nodes_bipartite",
                 "filter_output_graph", "edge_distance_um", "WORKING_DIR",
                 "VALIDATOR_MATCH_RADIUS_UM", "DEEPCENTER_VETO_DETECTOR"):
        if name not in joined:
            raise RuntimeError(f"{name} not found; the autopsy cell would NameError")

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

    nb["cells"].append({"cell_type": "code", "execution_count": None,
                        "metadata": {}, "outputs": [],
                        "source": AUTOPSY_CELL.splitlines(keepends=True)})

    after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    changed = [i for i, (a, b) in enumerate(zip(before, after)) if a != b]
    if changed != [0, 2, 5, 8]:
        raise RuntimeError(f"unexpected cells changed: {changed}")
    if len(after) != len(before) + 1:
        raise RuntimeError("autopsy cell not appended")

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
    print("  appended the autopsy cell; pipeline cells unchanged except the usual patches")
    print("  READ: how many of the 29 misses are detection vs post-processing")


if __name__ == "__main__":
    main()
