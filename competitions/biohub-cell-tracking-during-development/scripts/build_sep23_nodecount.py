#!/usr/bin/env python3
"""The node-count factor is the biggest untouched term in the metric.

## What the metric actually rewards

    score = adjusted_edge_jaccard + 0.1 * division_jaccard
    adjusted_edge_jaccard = J * (1 - 0.1 * (t_pred - t_true) / t_true)

`compute_edge_confusion` counts a predicted edge as FP only when at least one
endpoint matches a GT node that participates in GT edges. An edge between two
**unmatched** nodes is neither TP nor FP - it is invisible to `J`. But every
predicted node counts in `t_pred`, which scales the whole edge term.

On the 24 held-out videos at arm F:

    GT edges (tp + fn)        14,651      -> order 15k labelled GT nodes
    predicted nodes          468,572
    estimated true nodes     589,730      ratio 0.795, factor 1.0205

So roughly **97% of our predicted nodes match nothing in the ground truth**.
They contribute nothing to `J` and they move `t_pred`. The competition's own
note that "it is possible for scores to exceed 1.0" is the same observation
from the other side: the factor exceeds 1 exactly when you under-predict.

Per-video the factor ranges **0.9527 to 1.0573**. Seven of 24 videos
over-predict and are actively penalised - `6bba_207c6aaf` loses 0.032 and
`6bba_07e24132` loses 0.031. For comparison, every post-processing change
measured in the past week moved the score by 0.0001 to 0.0015.

## Why the naive version does not work

Raising the detector threshold globally removes nodes, and it was tried:
`det099` scored **0.943** against arm F's 0.947. Removing nodes indiscriminately
takes matched nodes with it, and each matched node lost turns its TP edges into
FN. The trade-off rate is what decides this, and nobody has measured it.

## What this run measures

Two things, in one kernel, on the cached validator graphs.

1. **The response curve.** `OUTPUT_MIN_TRACK_LEN` (base 6) and the short-track
   rescue probability are already sweepable and both prune whole tracks. Arms
   walk them well past their tuned values, so we see `adjusted_edge_jaccard`
   as a function of `t_pred` rather than guessing its sign.

2. **The oracle ceiling.** An appended cell recomputes, per video, what the
   score would be if we kept only the predicted nodes that match a GT node -
   unreachable at inference, but it bounds the direction. If the ceiling is
   small, this closes today for the price of one kernel. If it is large, the
   remaining days go to finding an inference-time proxy for "will match".
   The cell also reports the exchange rate: scored edges lost per 1,000 nodes
   pruned, which is the number that decides whether any proxy can pay.

The oracle uses GT only to *evaluate*, never to prune - the arms are all
inference-time rules.

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
OUT_DIR = WORKSPACE / "notebooks" / "sep23-nodecount"
TITLE = "Biohub Sep23 Nodecount Held Out"
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
    '# node-count response is measured against what we would actually submit.\n'
    'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"\n'
    + "\n".join(f'os.environ["{k}"] = "{v}"'
                for k, v in density.ARMS["biohub-sep18-density-full"]["env"])
)

# Base is OUTPUT_MIN_TRACK_LEN=6, rescue prob 0.82. Walk both well past their
# tuned values: the point is the shape of the curve, not a nearby optimum.
ARMS = [
    ("mtl8", {"OUTPUT_MIN_TRACK_LEN": 8}),
    ("mtl10", {"OUTPUT_MIN_TRACK_LEN": 10}),
    ("mtl14", {"OUTPUT_MIN_TRACK_LEN": 14}),
    ("mtl20", {"OUTPUT_MIN_TRACK_LEN": 20}),
    ("mtl30", {"OUTPUT_MIN_TRACK_LEN": 30}),
    # Rescue keeps short tracks whose mean edge probability is high. Raising
    # it prunes more; 0.0 would keep everything, 0.95 keeps only the confident.
    ("rescue95", {"SHORT_TRACK_RESCUE_MIN_MEAN_EDGE_PROB": 0.95}),
    ("mtl14_rescue95", {"OUTPUT_MIN_TRACK_LEN": 14,
                        "SHORT_TRACK_RESCUE_MIN_MEAN_EDGE_PROB": 0.95}),
]

CANDIDATES_NEW = '    "dcgap035": {"DEEPCENTER_GAP_THRESHOLD": 0.35},\n' + "\n".join(
    f'    "{name}": {json.dumps(cfg, sort_keys=True)},' for name, cfg in ARMS) + "\n}"

ORACLE_CELL = r'''
# ============================================================
# NODE-COUNT ORACLE -- how much of the edge term is the t_pred factor?
# ============================================================
# adjusted = J * (1 - a*(t_pred - t_true)/t_true). An edge between two nodes
# that match nothing in the GT is neither TP nor FP, so it never touches J -
# but both nodes count in t_pred. This cell measures how much score is sitting
# in that factor, and what it would cost to go after it.
#
# GT is used ONLY to evaluate. Nothing here is a proposed inference rule.
import csv as _csv
import collections as _collections

ORACLE_PATH = WORKING_DIR / "nodecount_oracle.csv"
_orc = []

if VALIDATOR_ENABLE and val_stems and VAL_RAW_GRAPHS:
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
        _pred_edges = [(int(e["source_id"]), int(e["target_id"])) for e in _eb]
        _p2g, _g2p = match_nodes_bipartite(_pred_nodes, _gt_nodes, VALIDATOR_MATCH_RADIUS_UM)

        _tp, _fp, _fn = compute_edge_confusion(_pred_edges, _gt_edges, _p2g, _g2p)
        _J = edge_jaccard(_tp, _fp, _fn)
        _adj = adjusted_jaccard(_J, len(_pred_nodes), _t_true, a=VALIDATOR_NODE_COUNT_PENALTY_A)

        # ORACLE: keep only predicted nodes that matched a GT node.
        _keep = {n for n in _pred_nodes if _p2g.get(n) is not None}
        _oe = [(s, t) for s, t in _pred_edges if s in _keep and t in _keep]
        _otp, _ofp, _ofn = compute_edge_confusion(_oe, _gt_edges, _p2g, _g2p)
        _oJ = edge_jaccard(_otp, _ofp, _ofn)
        _oadj = adjusted_jaccard(_oJ, len(_keep), _t_true, a=VALIDATOR_NODE_COUNT_PENALTY_A)

        _orc.append({
            "stem": _stem,
            "t_true": int(_t_true),
            "t_pred": len(_pred_nodes),
            "matched_nodes": len(_keep),
            "unmatched_nodes": len(_pred_nodes) - len(_keep),
            "ratio": round(len(_pred_nodes) / _t_true, 4),
            "factor": round(1 - VALIDATOR_NODE_COUNT_PENALTY_A * (len(_pred_nodes) - _t_true) / _t_true, 4),
            "J": round(_J, 5), "adj": round(_adj, 5),
            "tp": _tp, "fp": _fp, "fn": _fn,
            "oracle_ratio": round(len(_keep) / _t_true, 4),
            "oracle_J": round(_oJ, 5), "oracle_adj": round(_oadj, 5),
            "oracle_tp": _otp, "oracle_fp": _ofp, "oracle_fn": _ofn,
            "weight": _tp + _fp + _fn,
        })

    if _orc:
        _keys = sorted({k for r in _orc for k in r})
        with ORACLE_PATH.open("w", newline="") as _f:
            _w = _csv.DictWriter(_f, fieldnames=_keys)
            _w.writeheader()
            for _r in _orc:
                _w.writerow(_r)

        _W = sum(r["weight"] for r in _orc) or 1
        _now = sum(r["adj"] * r["weight"] for r in _orc) / _W
        _orc_adj = sum(r["oracle_adj"] * r["weight"] for r in _orc) / _W
        _tot_pred = sum(r["t_pred"] for r in _orc)
        _tot_match = sum(r["matched_nodes"] for r in _orc)
        print("=" * 72)
        print("NODE-COUNT ORACLE")
        print("=" * 72)
        print(f"  predicted nodes        {_tot_pred:>12,}")
        print(f"  matched to a GT node   {_tot_match:>12,}  ({_tot_match / _tot_pred * 100:.1f}%)")
        print(f"  unmatched (invisible to J, but counted in t_pred)"
              f" {_tot_pred - _tot_match:>12,}")
        print()
        print(f"  weighted adjusted NOW     {_now:.5f}")
        print(f"  weighted adjusted ORACLE  {_orc_adj:.5f}   ceiling {_orc_adj - _now:+.5f}")
        print()
        print("  The oracle is NOT reachable - it uses GT to decide what to keep.")
        print("  It bounds the direction. What decides feasibility is the")
        print("  exchange rate below: how many SCORED edges a pruning rule")
        print("  destroys per 1,000 nodes it removes.")
        print()
        print(f"  oracle removes {_tot_pred - _tot_match:,} nodes and changes scored edges by "
              f"tp {sum(r['tp'] for r in _orc)}->{sum(r['oracle_tp'] for r in _orc)}, "
              f"fp {sum(r['fp'] for r in _orc)}->{sum(r['oracle_fp'] for r in _orc)}, "
              f"fn {sum(r['fn'] for r in _orc)}->{sum(r['oracle_fn'] for r in _orc)}")
        print()
        print("  per-video, worst-penalised first:")
        print(f"    {'stem':<18}{'ratio':>7}{'factor':>8}{'adj':>9}{'oracle':>9}{'gain':>9}{'wt':>7}")
        for _r in sorted(_orc, key=lambda r: r["factor"])[:10]:
            print(f"    {_r['stem']:<18}{_r['ratio']:>7.3f}{_r['factor']:>8.4f}"
                  f"{_r['adj']:>9.4f}{_r['oracle_adj']:>9.4f}"
                  f"{_r['oracle_adj'] - _r['adj']:>+9.4f}{_r['weight']:>7}")
        print(f"  wrote {ORACLE_PATH}")
else:
    print("ORACLE: validator disabled -- skipping.")
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
        "sweepkeys": (dval.SWEEP_KEYS_ANCHOR, dval.SWEEP_KEYS_NEW),
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

    declared = set(re.findall(r'"([A-Z][A-Z0-9_]+)"', after[9]))
    used = {k for _, cfg in ARMS for k in cfg}
    if used - declared:
        raise RuntimeError(f"not sweepable: {sorted(used - declared)}")
    names = [n for n, _ in ARMS]
    if len(set(names)) != len(names):
        raise RuntimeError("duplicate arm name")
    in_cell = re.findall(r'^    "([\w()+]+)":', after[10], re.M)
    if len(set(in_cell)) != len(in_cell):
        dupes = sorted({n for n in in_cell if in_cell.count(n) > 1})
        raise RuntimeError(f"duplicate candidate keys: {dupes}")
    # Every helper the oracle cell calls must exist, or it fails 3h in.
    pipeline_and_helpers = "\n".join(after)
    for fn in ("nodes_by_id_to_plain", "match_nodes_bipartite", "compute_edge_confusion",
               "edge_jaccard", "adjusted_jaccard", "filter_output_graph"):
        if f"def {fn}" not in pipeline_and_helpers:
            raise RuntimeError(f"oracle cell calls {fn}() but it is not defined")
    for var in ("VAL_RAW_GRAPHS", "VAL_GT", "VALIDATOR_MATCH_RADIUS_UM",
                "VALIDATOR_NODE_COUNT_PENALTY_A", "DEEPCENTER_VETO_DETECTOR"):
        if var not in pipeline_and_helpers:
            raise RuntimeError(f"oracle cell uses {var} but it is never defined")

    nb["cells"].append({"cell_type": "code", "execution_count": None, "metadata": {},
                        "outputs": [], "source": ORACLE_CELL.splitlines(keepends=True)})

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
    print(f"  {len(ARMS)} pruning arms: " + ", ".join(names))
    print("  plus the node-count oracle cell (ceiling + exchange rate)")


if __name__ == "__main__":
    main()
