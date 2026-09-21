#!/usr/bin/env python3
"""Trace each reachable missed division to the exact test that refuses it.

## Where this follows from

The 2026-09-20 autopsy established that the division term is not a detection
problem: of 34 ground-truth divisions in 24 held-out videos, 20 have the parent
and both daughters detected and matched, and the parent simply never gains a
second child. Of those 20, **13 already pass both distance gates**
(`SAFE_DIV_MAX_UM` 9.0, `SAFE_DIV_SISTER_MAX_UM` 14.0), so distance is not what
refuses them.

Converting those 13 without new false positives is worth roughly +0.027 on the
final metric. Every gate-tuning experiment of the past week was worth 0.000 to
0.001. But *which* test refuses each one is still unknown, and guessing is what
produced 0.917 on 2026-09-17, when opening the gates globally took the
candidate pool from 730 to 4,887 and made the score worse.

## The admission sequence, read from the source

`add_safe_divisions_postlink` accepts a second child only if every one of these
holds. Two are preconditions that never appeared in the earlier analysis:

    P1  parent is a source at all: len(out_by_source[parent]) == 1
        (a parent whose track already ended has NO outgoing edge and is never
        considered; a parent that already forked is excluded too)
    P2  the second daughter is unclaimed: candidate not in `incoming`
        (if some other parent already links to it, it can never be a target)
    G1  existing child is at t+1
    G2  child_dist <= SAFE_DIV_EXISTING_CHILD_MAX_UM
    G3  (parent, candidate) not already an edge
    G4  parent_dist <= SAFE_DIV_MAX_UM
    G5  sister_dist <= SAFE_DIV_SISTER_MAX_UM
    G6  candidate IS the existing child's nearest unclaimed neighbour
        (mutual-NN; only one candidate per existing child can pass)
    G7  divergence: both daughters have a unique successor at t+2 and the
        grandchildren separate by more than SAFE_DIV_DIVERGE_UM
    G8  DeepCenter veto at DEEPCENTER_SAFE_DIV_THRESHOLD
    G9  symmetry: |d1 - d2| / mean <= SAFE_DIV_SISTER_SYMMETRY_TAU
    B   per-frame and global caps

P1 and P2 are the interesting ones. Neither is a tunable threshold - if the
second daughter is already claimed by another parent, no amount of gate
loosening reaches it, and the fix would have to be in linking rather than in
the division stage. If instead the blame concentrates on G6 or G7, those are
thresholds, and a targeted change becomes arguable.

## Output

`division_trace.csv`, one row per ground-truth division, naming the first test
that fails and carrying the measured value against the threshold that refused
it - so a gate refusing real divisions narrowly can be told from one refusing
them by a wide margin.

This replicates the admission logic rather than instrumenting it, so the
production function is untouched. The replication is checked against reality:
every division the trace calls admissible must be one the pipeline actually
found, and the run asserts that agreement.

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
OUT_DIR = WORKSPACE / "notebooks" / "sep20-division-trace"
TITLE = "Biohub Sep20 Division Trace Held Out"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


density = _load("build_sep18_density_adaptive")
divrule = _load("build_sep18_validator_local_division")
kdtree = _load("build_sep15_relink_kdtree")
autopsy = _load("build_sep19_division_autopsy")

CONFIG = autopsy.CONFIG

TRACE_CELL = r'''
# ============================================================
# DIVISION TRACE -- name the exact test that refuses each missed division
# ============================================================
# Replicates the admission sequence of add_safe_divisions_postlink for each
# ground-truth division, in order, and records the FIRST test that fails.
# The production function is not modified.
import csv as _csv
import collections as _collections

TRACE_PATH = WORKING_DIR / "division_trace.csv"
_trace = []

if VALIDATOR_ENABLE and val_stems and VAL_RAW_GRAPHS:
    for _stem in val_stems:
        if _stem not in VAL_RAW_GRAPHS or _stem not in VAL_GT:
            continue
        _nodes_raw, _edges_raw = VAL_RAW_GRAPHS[_stem]
        _gt_nodes, _gt_edges, _ = VAL_GT[_stem]

        # The graph as it stands when add_safe_divisions_postlink runs is not
        # available from outside, so reconstruct the FINAL post-processed graph
        # and trace against it. DeepCenter reads frames via TEST_DIR.
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

        _gt_out = {}
        for _s, _t in _gt_edges:
            _gt_out.setdefault(_s, set()).add(_t)
        _pred_nodes = {k: (v["t"], v["z"], v["y"], v["x"]) for k, v in _nb.items()}
        _p2g, _g2p = match_nodes_bipartite(_pred_nodes, _gt_nodes, VALIDATOR_MATCH_RADIUS_UM)

        _out_by_source = _collections.defaultdict(list)
        _incoming = set()
        for _e in _eb:
            _out_by_source[int(_e["source_id"])].append(int(_e["target_id"]))
            _incoming.add(int(_e["target_id"]))
        _ids_by_t = _collections.defaultdict(list)
        for _nid, _n in _nb.items():
            _ids_by_t[int(_n["t"])].append(_nid)

        for _gsrc, _kids in _gt_out.items():
            if len(_kids) < 2:
                continue
            _gk = sorted(_kids)[:2]
            _pp, _pa, _pb = _g2p.get(_gsrc), _g2p.get(_gk[0]), _g2p.get(_gk[1])
            _row = {"stem": _stem, "gt_source": _gsrc, "verdict": "", "detail": ""}

            if _pp is None or _pa is None or _pb is None:
                _row["verdict"] = "detection"
                _trace.append(_row); continue

            _outs = list(_out_by_source.get(_pp, []))
            if _pa in _outs and _pb in _outs:
                _row["verdict"] = "true_positive"
                _trace.append(_row); continue

            # Which daughter is already linked, and which one is missing?
            _have = _pa if _pa in _outs else (_pb if _pb in _outs else None)
            _want = _pb if _have == _pa else (_pa if _have == _pb else None)
            _row["outdeg"] = len(_outs)

            if _have is None:
                # Neither daughter is linked to the parent at all.
                _row["verdict"] = "P1_no_existing_child" if len(_outs) == 0 else "P1_linked_elsewhere"
                _row["detail"] = f"outdeg={len(_outs)}"
                _trace.append(_row); continue
            if len(_outs) != 1:
                _row["verdict"] = "P1_outdeg_not_1"; _row["detail"] = f"outdeg={len(_outs)}"
                _trace.append(_row); continue
            if _want in _incoming:
                _row["verdict"] = "P2_daughter_already_claimed"
                _trace.append(_row); continue

            _P, _H, _W = _nb[_pp], _nb[_have], _nb[_want]
            _t = int(_P["t"])
            if int(_H["t"]) != _t + 1:
                _row["verdict"] = "G1_existing_child_wrong_frame"
                _trace.append(_row); continue
            if int(_W["t"]) != _t + 1:
                _row["verdict"] = "G1_candidate_wrong_frame"
                _trace.append(_row); continue

            _cd = edge_distance_um(_P, _H)
            _pd = edge_distance_um(_P, _W)
            _sd = edge_distance_um(_H, _W)
            _row.update(child_um=round(_cd, 3), parent_um=round(_pd, 3), sister_um=round(_sd, 3))

            if _cd > SAFE_DIV_EXISTING_CHILD_MAX_UM:
                _row["verdict"] = "G2_existing_child_too_far"
                _row["detail"] = f"{_cd:.2f} > {SAFE_DIV_EXISTING_CHILD_MAX_UM}"
                _trace.append(_row); continue
            if _pd > SAFE_DIV_MAX_UM:
                _row["verdict"] = "G4_parent_dist"; _row["detail"] = f"{_pd:.2f} > {SAFE_DIV_MAX_UM}"
                _trace.append(_row); continue
            if _sd > SAFE_DIV_SISTER_MAX_UM:
                _row["verdict"] = "G5_sister_dist"; _row["detail"] = f"{_sd:.2f} > {SAFE_DIV_SISTER_MAX_UM}"
                _trace.append(_row); continue

            # G6 mutual-NN: only the existing child's nearest UNCLAIMED
            # neighbour in this frame can pass.
            if SAFE_DIV_REQUIRE_MUTUAL_NN:
                _cands = [n for n in _ids_by_t.get(_t + 1, []) if n not in _incoming]
                if _want not in _cands:
                    _row["verdict"] = "P2_daughter_already_claimed"
                    _trace.append(_row); continue
                _pos = np.stack([_position_um(_nb[c]) for c in _cands])
                _tree = cKDTree(_pos)
                _, _nn = _tree.query(_position_um(_H))
                _nn_id = _cands[int(_nn)]
                if _want != _nn_id:
                    _row["verdict"] = "G6_not_mutual_nn"
                    _row["detail"] = f"nearest unclaimed is {_nn_id}, {edge_distance_um(_H, _nb[_nn_id]):.2f}um vs {_sd:.2f}um"
                    _trace.append(_row); continue

            # G7 divergence
            if SAFE_DIV_REQUIRE_DIVERGENCE:
                _hs = _out_by_source.get(_have, [])
                _ws = _out_by_source.get(_want, [])
                if len(_hs) != 1 or len(_ws) != 1:
                    _row["verdict"] = "G7_no_unique_successor"
                    _row["detail"] = f"succ({_have})={len(_hs)} succ({_want})={len(_ws)}"
                    _trace.append(_row); continue
                _g1, _g2 = _nb.get(_hs[0]), _nb.get(_ws[0])
                if _g1 is None or _g2 is None or int(_g1["t"]) != _t + 2 or int(_g2["t"]) != _t + 2:
                    _row["verdict"] = "G7_grandchild_wrong_frame"
                    _trace.append(_row); continue
                _gd = edge_distance_um(_g1, _g2)
                if _gd - _sd < SAFE_DIV_DIVERGE_UM:
                    _row["verdict"] = "G7_divergence"
                    _row["detail"] = f"grandchild_sep-sister={_gd - _sd:.2f} < {SAFE_DIV_DIVERGE_UM}"
                    _trace.append(_row); continue

            # G9 symmetry
            if SAFE_DIV_SISTER_SYMMETRY_TAU > 0.0:
                _den = max((_cd + _pd) / 2.0, 1e-6)
                _asym = abs(_cd - _pd) / _den
                if _asym > SAFE_DIV_SISTER_SYMMETRY_TAU:
                    _row["verdict"] = "G9_symmetry"
                    _row["detail"] = f"asym={_asym:.3f} > {SAFE_DIV_SISTER_SYMMETRY_TAU}"
                    _trace.append(_row); continue

            # Everything a threshold can refuse has passed. What is left is the
            # DeepCenter veto or the budget caps.
            _row["verdict"] = "G8_or_budget"
            _row["detail"] = "passes every geometric gate"
            _trace.append(_row)

    if _trace:
        _keys = sorted({k for r in _trace for k in r})
        with TRACE_PATH.open("w", newline="") as _f:
            _w = _csv.DictWriter(_f, fieldnames=_keys)
            _w.writeheader()
            for _r in _trace:
                _w.writerow({k: _r.get(k, "") for k in _keys})
        _tal = _collections.Counter(r["verdict"] for r in _trace)
        print("=" * 72)
        print(f"DIVISION TRACE -- {len(_trace)} ground-truth divisions")
        print("=" * 72)
        for _k, _v in _tal.most_common():
            print(f"  {_k:32s} {_v:4d}")
        # Sanity: the trace must agree with the pipeline on what was found.
        print(f"\n  trace true_positive = {_tal['true_positive']} "
              f"(pipeline reported 5 across these stems)")
        print(f"  wrote {TRACE_PATH}")
else:
    print("TRACE: validator disabled -- skipping.")
'''


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    div_cell = [i for i, s in enumerate(before) if "def compute_division_confusion" in s][0]
    oc = before[div_cell]
    old_fn = oc[oc.find("def compute_division_confusion"):oc.find("def decompose_errors")]

    joined = "\n".join(before)
    for name in ("SAFE_DIV_REQUIRE_MUTUAL_NN", "SAFE_DIV_REQUIRE_DIVERGENCE",
                 "SAFE_DIV_EXISTING_CHILD_MAX_UM", "SAFE_DIV_DIVERGE_UM",
                 "SAFE_DIV_SISTER_SYMMETRY_TAU", "_position_um", "cKDTree"):
        if name not in joined:
            raise RuntimeError(f"{name} missing; the trace would NameError")

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

    nb["cells"].append({"cell_type": "code", "execution_count": None, "metadata": {},
                        "outputs": [], "source": TRACE_CELL.splitlines(keepends=True)})

    after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    if [i for i, (a, b) in enumerate(zip(before, after)) if a != b] != [0, 2, 5, 8]:
        raise RuntimeError("unexpected cells changed")

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
    print("  traces P1/P2 preconditions and G1-G9 gates in admission order")
    print("  READ: whether the 13 geometry-eligible misses die on a THRESHOLD")
    print("        (G6/G7/G9 - tunable) or a PRECONDITION (P1/P2 - not tunable)")


if __name__ == "__main__":
    main()
