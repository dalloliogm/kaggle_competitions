"""Execute the deadline guard's DEGRADED path locally, no GPU.

The guard disables OUTPUT_MOTION_RELINK, OUTPUT_GAP_CLOSE and
OUTPUT_GAP2_RECOVERY once wall-clock passes the deadline. That path has never
run. If it produces a malformed graph on the private rerun the score is zero,
not merely lower. This runs it against the 4 public test prediction graphs
already on disk and checks the output is a valid submission.

DeepCenter is disabled: it needs image data we do not have locally, and it is
a veto on *adding* repairs, so it cannot make a degraded graph invalid.
"""
import json, sys, types, os
from pathlib import Path
import numpy as np, zarr

S = Path("/tmp/claude-0/-home-user-kaggle-competitions/079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad")
PRED = S / "nodecount/tracking_repo/predictions/unknown/unet_transformer/split_0"
NB = Path("/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development"
          "/notebooks/sep19-deadline-guard")

# torch is imported at module scope but only used by DeepCenter, which is off.
if "torch" not in sys.modules:
    t = types.ModuleType("torch"); t.cuda = types.SimpleNamespace(
        is_available=lambda: False, device_count=lambda: 0)
    t.no_grad = lambda: types.SimpleNamespace(__enter__=lambda s: None, __exit__=lambda s,*a: None)
    t.load = lambda *a, **k: {}
    t.nn = types.ModuleType("torch.nn"); t.nn.Module = object
    t.from_numpy = lambda a: a; t.Tensor = object
    sys.modules["torch"] = t; sys.modules["torch.nn"] = t.nn

def load_pred(root: Path):
    g = lambda p: np.asarray(zarr.open(str(root / p), mode="r")[:])
    ids = g("nodes/ids")
    t, z, y, x = (g(f"nodes/props/{k}/values") for k in ("t", "z", "y", "x"))
    nodes = {int(i): {"t": int(a), "z": float(b), "y": float(c), "x": float(d)}
             for i, a, b, c, d in zip(ids, t, z, y, x)}
    e = g("edges/ids") if (root / "edges/ids").exists() else np.zeros((0, 2), int)
    props = root / "edges/props/edge_prob/values"
    ep = g("edges/props/edge_prob/values") if props.exists() else None
    edges = []
    for k, (s, d) in enumerate(e):
        edges.append({"source_id": int(s), "target_id": int(d),
                      "edge_prob": (float(ep[k]) if ep is not None else None)})
    return nodes, edges

cells = [ "".join(c["source"]) for c in
          json.loads(next(NB.glob("*.ipynb")).read_text())["cells"]
          if c["cell_type"] == "code" ]

env = {
    "BIOHUB_USE_DEEPCENTER_VETO": "0", "BIOHUB_DEEPCENTER_GAP_VETO": "0",
    "BIOHUB_DEEPCENTER_SAFE_DIV_VETO": "0", "BIOHUB_VALIDATOR_ENABLE": "0",
}
os.environ.update(env)
G = {"__name__": "nbmod"}
exec(compile(cells[0], "<cell0>", "exec"), G)     # config: sets BIOHUB_* env
os.environ.update(env)                            # keep DeepCenter off
exec(compile(cells[2], "<cell2>", "exec"), G)     # constants
# Cell 5 ends with a module-level write_test_submission('base') that needs
# globals from later cells. Execute only the definitions.
import ast as _ast
_tree = _ast.parse(cells[5])
_tree.body = [n for n in _tree.body if not (isinstance(n, _ast.Expr)
              and isinstance(n.value, _ast.Call))]
exec(compile(_tree, "<cell5>", "exec"), G)        # pipeline definitions only
G["DEEPCENTER_SAFE_DIV_VETO"] = False
G["DEEPCENTER_GAP_VETO"] = False

def run(stem, degraded):
    nodes, edges = load_pred(PRED / f"{stem}.geff")
    for k, v in (("OUTPUT_MOTION_RELINK", not degraded),
                 ("OUTPUT_GAP_CLOSE", not degraded),
                 ("OUTPUT_GAP2_RECOVERY", not degraded)):
        G[k] = v
    nb_, eb_, st_ = G["filter_output_graph"](
        {k: dict(v) for k, v in nodes.items()}, [dict(e) for e in edges],
        dataset=stem, deepcenter_bundle=None)
    return nb_, eb_, st_

print(f"{'stem':<18}{'mode':<10}{'nodes':>9}{'edges':>9}{'div':>6}{'indeg<=1':>10}{'outdeg<=2':>11}{'time ok':>9}")
ok = True
for stem in sorted(p.stem for p in PRED.glob("*.geff")):
    for degraded in (False, True):
        n, e, st = run(stem, degraded)
        ind, outd = {}, {}
        for x in e:
            ind[int(x["target_id"])] = ind.get(int(x["target_id"]), 0) + 1
            outd[int(x["source_id"])] = outd.get(int(x["source_id"]), 0) + 1
        t = {i: int(v["t"]) for i, v in n.items()}
        tok = all(t[int(x["source_id"])] + 1 == t[int(x["target_id"])] for x in e)
        i_ok = (max(ind.values()) if ind else 0) <= 1
        o_ok = (max(outd.values()) if outd else 0) <= 2
        div = sum(1 for v in outd.values() if v == 2)
        ok &= i_ok and o_ok and tok and len(n) > 0 and len(e) > 0
        print(f"{stem:<18}{'DEGRADED' if degraded else 'normal':<10}{len(n):>9,}{len(e):>9,}"
              f"{div:>6}{str(i_ok):>10}{str(o_ok):>11}{str(tok):>9}")
print("\nDEGRADED PATH:", "VALID on all 4 test videos" if ok else "*** PRODUCED AN INVALID GRAPH ***")
