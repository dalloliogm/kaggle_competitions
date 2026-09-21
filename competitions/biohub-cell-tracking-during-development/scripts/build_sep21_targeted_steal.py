#!/usr/bin/env python3
"""Let a division reclaim a daughter that a weak link already took.

## The finding this acts on

The 2026-09-20 trace attributed every ground-truth division to the first test
that refuses it:

    P2_daughter_already_claimed   15      NOT a threshold
    detection                      9
    true_positive                  5
    G4 / G6 / G7 / G9              5      tunable

`add_safe_divisions_postlink` builds its candidate list as

    candidate_ids = [n for n in child_frame_ids
                     if n not in incoming and n not in used_targets]

so a node that already has an incoming edge is excluded **by construction**. In
15 of 34 divisions - three quarters of everything reachable - the second
daughter was linked to some other parent before the division stage ran. No gate
value reaches them, which is why recall sat at exactly 5 through six different
configurations.

Ceiling if all 15 were converted: TP 5 -> 20 of 34, division Jaccard 0.104 ->
0.417, **+0.031** at the 0.1 metric weight.

## Why stealing is worth considering at all

The edge term is weighted 1.0 against the division term's 0.1, so any change
that trades edges for divisions must be checked against that ratio. Here the
trade is favourable by a wide margin: reclaiming 15 daughters breaks 15 edges
out of roughly 118,000, about **0.0001** on edge Jaccard, against **+0.031** on
divisions. Two orders of magnitude.

The risk is not the arithmetic, it is the selection. At inference time we cannot
tell which claimed nodes are real daughters, so the rule fires on everything
that looks like one. An untargeted version of exactly this idea is what sank
2026-09-17: opening the gates took the candidate pool from 730 to 4,887 and the
score fell 0.946 -> 0.917.

## What makes this targeted

A claim is only stealable when both hold:

1. **the claiming edge is weak** - `edge_prob <= SAFE_DIV_STEAL_MAX_PROB`.
   Edges from the prediction graph and from motion-relink carry a learned
   probability; gap-close and safe-division edges carry `None`, which is
   treated as 0.0 because those are repair-stage guesses rather than model
   evidence.
2. **the division explains the node better** - the dividing parent is at least
   `SAFE_DIV_STEAL_MIN_GAIN_UM` closer than the current claimant.

Everything else is unchanged: the same distance gates, mutual-NN, divergence,
symmetry, DeepCenter veto and the same per-frame and global caps still apply,
so the candidate pool grows only by nodes that are both weakly held and
geometrically better explained. A stolen daughter's old edge is removed, so the
graph stays valid - one parent per node.

## Also measured in this run

Before any steal fires, the run characterises the 15 blocked claims: the
probability on the claiming edge, its distance, and whether it came from the
prediction graph, motion-relink, or a repair stage. If those claims turn out to
be strong and close, the steal cannot be targeted and the direction closes -
which is worth knowing in one run rather than three.

## Arms

    steal_off        control, identical to arm F
    steal_p20_g1     prob <= 0.20, gain >= 1.0 um    most conservative
    steal_p50_g1     prob <= 0.50, gain >= 1.0 um
    steal_p50_g0     prob <= 0.50, gain >= 0.0 um    geometry-only
    steal_none_g1    prob <= 0.00, gain >= 1.0 um    synthetic claims only

`steal_none_g1` is the interesting floor: it reclaims only daughters held by an
edge with no learned probability at all - a repair-stage guess - which is the
least defensible claim in the graph.

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
OUT_DIR = WORKSPACE / "notebooks" / "sep21-targeted-steal"
TITLE = "Biohub Sep21 Targeted Steal Held Out"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


density = _load("build_sep18_density_adaptive")
divrule = _load("build_sep18_validator_local_division")
kdtree = _load("build_sep15_relink_kdtree")
dval = _load("build_sep18_density_validation")

CONFIG = (
    '# Arm F on 24 held-out videos with the official division rule, so the\n'
    '# steal is measured against the configuration we would actually submit.\n'
    'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"'
                for k, v in density.ARMS["biohub-sep18-density-full"]["env"])
)

FLAG_ANCHOR = density.FLAG_NEW
FLAG_WITH_STEAL = density.FLAG_NEW + '''
# Targeted steal: allow a division to reclaim a daughter whose existing link is
# weak AND which the division explains better. The edge term outweighs the
# division term 10:1, but reclaiming ~15 daughters breaks ~15 edges of 118,000
# (about 0.0001) against a +0.031 division ceiling, so the trade is favourable
# by two orders of magnitude. The risk is selection, not arithmetic - hence two
# independent conditions rather than a single loosened threshold.
SAFE_DIV_ALLOW_STEAL = os.environ.get("BIOHUB_SAFE_DIV_ALLOW_STEAL", "0") != "0"
SAFE_DIV_STEAL_MAX_PROB = float(os.environ.get("BIOHUB_SAFE_DIV_STEAL_MAX_PROB", "0.5"))
SAFE_DIV_STEAL_MIN_GAIN_UM = float(os.environ.get("BIOHUB_SAFE_DIV_STEAL_MIN_GAIN_UM", "1.0"))'''

CAND_ANCHOR = '        candidate_ids = [node_id for node_id in child_frame_ids if node_id not in incoming and node_id not in used_targets]'
CAND_NEW = '''        # Claims that a division may reclaim: the holding edge is weak and the
        # dividing parent explains the node better. `claimed_by` keeps the edge
        # so it can be removed if the steal is admitted - one parent per node.
        claimed_by = {}
        if SAFE_DIV_ALLOW_STEAL:
            for _e in edges:
                _tgt = int(_e["target_id"])
                if _tgt in child_frame_ids_set:
                    claimed_by[_tgt] = _e
        candidate_ids = [node_id for node_id in child_frame_ids if node_id not in incoming and node_id not in used_targets]
        if SAFE_DIV_ALLOW_STEAL:
            _stealable = []
            for node_id in child_frame_ids:
                if node_id in used_targets or node_id not in claimed_by:
                    continue
                _ce = claimed_by[node_id]
                _cp = _ce.get("edge_prob")
                _cp = 0.0 if _cp is None else float(_cp)
                if _cp > SAFE_DIV_STEAL_MAX_PROB:
                    stats["safe_div_steal_rejected_prob"] = stats.get("safe_div_steal_rejected_prob", 0) + 1
                    continue
                _stealable.append(node_id)
            candidate_ids = candidate_ids + _stealable
            stats["safe_div_steal_candidates"] = stats.get("safe_div_steal_candidates", 0) + len(_stealable)'''

# child_frame_ids_set must exist before the candidate block uses it.
SET_ANCHOR = '''        child_frame_ids = ids_by_t.get(t + 1, [])
        if not child_frame_ids:
            continue'''
SET_NEW = '''        child_frame_ids = ids_by_t.get(t + 1, [])
        if not child_frame_ids:
            continue
        child_frame_ids_set = set(child_frame_ids)'''

ADMIT_ANCHOR = '''            if candidate_id in used_targets or candidate_id in incoming:
                continue
            if source_id in used_sources:
                continue'''
ADMIT_NEW = '''            if candidate_id in used_targets:
                continue
            _stolen_edge = None
            if candidate_id in incoming:
                if not SAFE_DIV_ALLOW_STEAL:
                    continue
                _stolen_edge = claimed_by.get(candidate_id)
                if _stolen_edge is None:
                    continue
                # The division must explain the node better than its claimant.
                _claim_src = nodes_by_id.get(int(_stolen_edge["source_id"]))
                if _claim_src is None:
                    continue
                _claim_dist = edge_distance_um(_claim_src, nodes_by_id[candidate_id])
                if parent_dist + SAFE_DIV_STEAL_MIN_GAIN_UM > _claim_dist:
                    stats["safe_div_steal_rejected_gain"] = stats.get("safe_div_steal_rejected_gain", 0) + 1
                    continue
            if source_id in used_sources:
                continue
            if _stolen_edge is not None:
                stolen_edges.append(id(_stolen_edge))
                stats["safe_div_steals"] = stats.get("safe_div_steals", 0) + 1'''

RETURN_ANCHOR = '''    if added:
        stats["safe_divisions_added"] = len(added)
        return [*edges, *added]
    return edges'''
RETURN_NEW = '''    if added:
        stats["safe_divisions_added"] = len(added)
        if stolen_edges:
            _drop = set(stolen_edges)
            kept = [e for e in edges if id(e) not in _drop]
            return [*kept, *added]
        return [*edges, *added]
    return edges'''

INIT_ANCHOR = '''    added: list[dict[str, object]] = []
    used_targets: set[int] = set()'''
INIT_NEW = '''    added: list[dict[str, object]] = []
    stolen_edges: list[int] = []
    used_targets: set[int] = set()'''

SWEEP_KEYS_NEW = dval.SWEEP_KEYS_NEW.replace(
    ']',
    '    "SAFE_DIV_ALLOW_STEAL",\n'
    '    "SAFE_DIV_STEAL_MAX_PROB", "SAFE_DIV_STEAL_MIN_GAIN_UM",\n]')


def _arm(prob, gain):
    return ('{"SAFE_DIV_ALLOW_STEAL": True, '
            f'"SAFE_DIV_STEAL_MAX_PROB": {prob}, "SAFE_DIV_STEAL_MIN_GAIN_UM": {gain}}}')


CANDIDATES_NEW = '    "dcgap035": {"DEEPCENTER_GAP_THRESHOLD": 0.35},\n' + "\n".join(
    f'    "{n}": {c},' for n, c in [
        ("steal_p20_g1", _arm(0.20, 1.0)),
        ("steal_p50_g1", _arm(0.50, 1.0)),
        ("steal_p50_g0", _arm(0.50, 0.0)),
        ("steal_none_g1", _arm(0.00, 1.0)),
    ]) + "\n}"


CLAIM_CELL = r'''
# ============================================================
# BLOCKED-CLAIM CHARACTERISATION -- is a targeted steal even possible?
# ============================================================
# Runs at the BASE configuration (the sweep restores globals), so this
# describes the graph the steal would have to act on, independent of whether
# any arm above won. For every ground-truth division whose second daughter is
# refused because something already claimed it, record the claiming edge:
# which stage produced it, its learned probability, its length, and whether
# the dividing parent is closer. If those claims are strong and short, the
# direction is closed and no threshold rescues it.
import csv as _csv
import collections as _collections

CLAIM_PATH = WORKING_DIR / "blocked_claims.csv"
_claims = []


def _edge_stage(_e):
    for _k, _name in (("safe_division", "safe_div"), ("gap2_recovered", "gap2"),
                      ("gap_closed", "gap_close"), ("motion_relinked", "relink")):
        if _e.get(_k):
            return _name
    return "prediction"


if VALIDATOR_ENABLE and val_stems and VAL_RAW_GRAPHS:
    for _stem in val_stems:
        if _stem not in VAL_RAW_GRAPHS or _stem not in VAL_GT:
            continue
        _nodes_raw, _edges_raw = VAL_RAW_GRAPHS[_stem]
        _gt_nodes, _gt_edges, _ = VAL_GT[_stem]

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
        _claim_edge = {}
        for _e in _eb:
            _out_by_source[int(_e["source_id"])].append(int(_e["target_id"]))
            _claim_edge[int(_e["target_id"])] = _e

        for _gsrc, _kids in _gt_out.items():
            if len(_kids) < 2:
                continue
            _gk = sorted(_kids)[:2]
            _pp, _pa, _pb = _g2p.get(_gsrc), _g2p.get(_gk[0]), _g2p.get(_gk[1])
            if _pp is None or _pa is None or _pb is None:
                continue
            _outs = list(_out_by_source.get(_pp, []))
            if _pa in _outs and _pb in _outs:
                continue
            _have = _pa if _pa in _outs else (_pb if _pb in _outs else None)
            if _have is None or len(_outs) != 1:
                continue
            _want = _pb if _have == _pa else _pa
            _ce = _claim_edge.get(_want)
            if _ce is None:
                continue  # not a P2 case; a gate refused it, not a claim.

            _prob = _ce.get("edge_prob")
            _claim_src = _nb.get(int(_ce["source_id"]))
            _claim_um = edge_distance_um(_claim_src, _nb[_want]) if _claim_src else float("nan")
            _parent_um = edge_distance_um(_nb[_pp], _nb[_want])
            _claims.append({
                "stem": _stem,
                "gt_source": _gsrc,
                "stage": _edge_stage(_ce),
                "claim_prob": "" if _prob is None else round(float(_prob), 4),
                "claim_prob_is_none": int(_prob is None),
                "claim_um": round(_claim_um, 3),
                "parent_um": round(_parent_um, 3),
                "gain_um": round(_claim_um - _parent_um, 3),
                "steal_p20_g1": int((0.0 if _prob is None else float(_prob)) <= 0.20
                                    and _claim_um - _parent_um >= 1.0),
                "steal_p50_g1": int((0.0 if _prob is None else float(_prob)) <= 0.50
                                    and _claim_um - _parent_um >= 1.0),
                "steal_p50_g0": int((0.0 if _prob is None else float(_prob)) <= 0.50
                                    and _claim_um - _parent_um >= 0.0),
                "steal_none_g1": int(_prob is None and _claim_um - _parent_um >= 1.0),
            })

    if _claims:
        _keys = sorted({k for r in _claims for k in r})
        with CLAIM_PATH.open("w", newline="") as _f:
            _w = _csv.DictWriter(_f, fieldnames=_keys)
            _w.writeheader()
            for _r in _claims:
                _w.writerow({k: _r.get(k, "") for k in _keys})
        print("=" * 72)
        print(f"BLOCKED CLAIMS -- {len(_claims)} divisions whose daughter is already taken")
        print("=" * 72)
        print("  by stage that produced the claiming edge:")
        for _k, _v in _collections.Counter(r["stage"] for r in _claims).most_common():
            print(f"    {_k:14s} {_v:4d}")
        print("  reachable per arm (upper bound: ignores caps, mutual-NN and the vetoes):")
        for _arm_name in ("steal_none_g1", "steal_p20_g1", "steal_p50_g1", "steal_p50_g0"):
            _n = sum(r[_arm_name] for r in _claims)
            print(f"    {_arm_name:14s} {_n:4d} / {len(_claims)}")
        _g = sorted(r["gain_um"] for r in _claims)
        print(f"  gain_um (claim_dist - parent_dist): min={_g[0]:.2f} "
              f"median={_g[len(_g) // 2]:.2f} max={_g[-1]:.2f}")
        print(f"  wrote {CLAIM_PATH}")
    else:
        print("BLOCKED CLAIMS: none found -- P2 is not the binding constraint here.")
else:
    print("BLOCKED CLAIMS: validator disabled -- skipping.")
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
        "flags": (density.FLAG_ANCHOR, FLAG_WITH_STEAL),
        "gate": (density.RELINK_ANCHOR, density.RELINK_NEW),
        "pass": (density.PASS_ANCHOR, density.PASS_NEW),
        "kdtree": (kdtree.OLD_LOOP, kdtree.NEW_LOOP),
        "division": (old_fn, divrule.NEW_FUNCTION),
        "init": (INIT_ANCHOR, INIT_NEW),
        "set": (SET_ANCHOR, SET_NEW),
        "cand": (CAND_ANCHOR, CAND_NEW),
        "admit": (ADMIT_ANCHOR, ADMIT_NEW),
        "return": (RETURN_ANCHOR, RETURN_NEW),
        "sweepkeys": (dval.SWEEP_KEYS_ANCHOR, SWEEP_KEYS_NEW),
        "candidates": (dval.CANDIDATES_ANCHOR, CANDIDATES_NEW),
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
    if changed != [0, 2, 5, 8, 9, 10]:
        raise RuntimeError(f"unexpected cells changed: {changed}")

    pipe = after[5]
    # With the flag off the steal must be unreachable, or the control arm is
    # not a control.
    for guard in ("SAFE_DIV_ALLOW_STEAL", "stolen_edges", "claimed_by"):
        if guard not in pipe:
            raise RuntimeError(f"{guard} missing from the pipeline cell")
    if pipe.count("if not SAFE_DIV_ALLOW_STEAL:") != 1:
        raise RuntimeError("the admission guard against stealing is missing")
    declared = set(re.findall(r'"(SAFE_DIV_STEAL[A-Z_]*|SAFE_DIV_ALLOW_STEAL)"', after[9]))
    used = set(re.findall(r'"(SAFE_DIV_STEAL[A-Z_]*|SAFE_DIV_ALLOW_STEAL)":', after[10]))
    if used - declared:
        raise RuntimeError(f"non-sweepable keys used: {sorted(used - declared)}")
    for key in sorted(declared):
        if f"{key} = " not in after[2]:
            raise RuntimeError(f"{key} not defined in the constants cell")

    nb["cells"].append({"cell_type": "code", "execution_count": None, "metadata": {},
                        "outputs": [], "source": CLAIM_CELL.splitlines(keepends=True)})

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
    print("  4 steal arms + the untouched base as control")
    print("  READ with paired_sweep_analysis.py against 'base', restricted to affected videos")


if __name__ == "__main__":
    main()
