"""Is Trackastra's loss driven by its DIVISION gating rather than its associations?

Exp156 shows Trackastra emitting 892-1495 forks on the dense movie against the
incumbent's 203 and the ILP's 0. track_greedy accepts a second child whenever
the weight clears the threshold, and at our nucleus density many neighbours do.
This isolates that: same model, same detections, allow_divisions off.
"""
import contextlib, io, sys, time
from pathlib import Path
import numpy as np

HERE = Path(__file__).parent
sys.path.insert(0, "/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development/scripts")
import biohub_trackastra_link as btl

btl.bootstrap_trackastra(HERE / "trackastra-0.5.3-py3-none-any.whl", HERE / "tk_unpacked")
model = btl.load_trackastra_transformer(HERE / "ctc_model", device="cpu")

MOVIE, NFRAMES = "6bba_05db0fb1", 12
d = np.load(f"out156/ilp_cache/{MOVIE}.npz")
node, edge = d["node"], d["edge"]
t = node[:, 1].astype(int)

points, ids = [], []
for tt in range(NFRAMES):
    sel = np.where(t == tt)[0]
    sel = sel[np.argsort(node[sel, 0])]
    points.append(node[sel, 2:5]); ids.append(node[sel, 0].astype(np.int64))
keep = {int(v) for lst in ids for v in lst}
ilp = {(int(a), int(b)) for a, b, _ in edge if int(a) in keep and int(b) in keep}

print(f"{MOVIE} first {NFRAMES} frames: {sum(len(p) for p in points):,} detections, {len(ilp):,} ILP edges")
print(f"{'divisions':>10}{'scale':>7}{'edges':>9}{'agree_J':>10}{'ilp_recall':>12}{'forks':>8}")
for allow in (True, False):
    for scale in (3.0, 4.0):
        with contextlib.redirect_stderr(io.StringIO()):
            sol, _ = btl.link_movie(
                points_by_frame=points, transformer=model, feature_mode="synthetic",
                coord_scale=scale, max_distance_um=12.0, batch_size=1,
                allow_divisions=allow, progress=lambda x, **k: x,
            )
        pred, outdeg = set(), {}
        for s, t2 in sol.edges():
            sn, tn = sol.nodes[s], sol.nodes[t2]
            a = int(ids[int(sn["time"])][int(sn["label"]) - 1])
            b = int(ids[int(tn["time"])][int(tn["label"]) - 1])
            pred.add((a, b)); outdeg[a] = outdeg.get(a, 0) + 1
        inter = len(pred & ilp)
        print(f"{str(allow):>10}{scale:>7.1f}{len(pred):>9,}{inter/max(1,len(pred|ilp)):>10.3f}"
              f"{inter/max(1,len(ilp)):>12.3f}{sum(1 for v in outdeg.values() if v>=2):>8,}", flush=True)
