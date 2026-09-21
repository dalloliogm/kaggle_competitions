"""Preview on the DENSE movie - 6bba_05db0fb1 carries ~56% of the local metric weight.

~700 detections/frame means ~2800 tokens per 4-frame window, which is well past
the 1024-token budget Trackastra was trained with. That out-of-distribution
sequence length is the thing most likely to break the transfer on real data,
so it is worth measuring on its own. Restricted to a slice of frames because
this runs on CPU.
"""
import contextlib, io, sys, time
from pathlib import Path
import numpy as np

HERE = Path(__file__).parent
sys.path.insert(0, "/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development/scripts")
import biohub_trackastra_link as btl

btl.bootstrap_trackastra(HERE / "trackastra-0.5.3-py3-none-any.whl", HERE / "tk_unpacked")
model = btl.load_trackastra_transformer(HERE / "ctc_model", device="cpu")

d = np.load("outprobe/ilp_cache/6bba_05db0fb1.npz")
node, edge = d["node"], d["edge"]
t = node[:, 1].astype(int)
NFRAMES = int(sys.argv[1]) if len(sys.argv) > 1 else 12

points, ids = [], []
for tt in range(NFRAMES):
    sel = np.where(t == tt)[0]
    sel = sel[np.argsort(node[sel, 0])]
    points.append(node[sel, 2:5])
    ids.append(node[sel, 0].astype(np.int64))

keep = set()
for lst in ids:
    keep.update(int(v) for v in lst)
ilp = {(int(a), int(b)) for a, b, _ in edge if int(a) in keep and int(b) in keep}
print(f"6bba_05db0fb1 first {NFRAMES} frames: {sum(len(p) for p in points):,} detections, "
      f"{len(ilp):,} ILP edges, {sum(len(points[i]) for i in range(4)):,} tokens/window")
print(f"{'scale':>7}{'edges':>9}{'agree_J':>10}{'ilp_recall':>12}{'forks':>8}{'sec':>7}")

for scale in [2.0, 3.0, 4.0]:
    t0 = time.time()
    with contextlib.redirect_stderr(io.StringIO()):
        sol, stats = btl.link_movie(
            points_by_frame=points, transformer=model, feature_mode="synthetic",
            coord_scale=scale, max_distance_um=12.0, batch_size=1,
            progress=lambda x, **k: x,
        )
    pred, outdeg = set(), {}
    for s, tt2 in sol.edges():
        sn, tn = sol.nodes[s], sol.nodes[tt2]
        a = int(ids[int(sn["time"])][int(sn["label"]) - 1])
        b = int(ids[int(tn["time"])][int(tn["label"]) - 1])
        pred.add((a, b)); outdeg[a] = outdeg.get(a, 0) + 1
    inter = len(pred & ilp)
    print(f"{scale:>7.1f}{len(pred):>9,}{inter/max(1,len(pred|ilp)):>10.3f}"
          f"{inter/max(1,len(ilp)):>12.3f}{sum(1 for v in outdeg.values() if v>=2):>8,}"
          f"{time.time()-t0:>7.0f}", flush=True)
print(f"median NN {stats['median_nn_um']:.2f} um")
