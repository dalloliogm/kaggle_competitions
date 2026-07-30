"""Run the Trackastra linker on REAL cached detections from Exp121.

No images are available locally, so features fall back to the analytic sphere
mode. That removes the intensity/shape channel and is a handicap, but the
coordinates - which drive the association - are the real ones, so the
agreement with our ILP edges is a meaningful preview.
"""
import contextlib, io, sys, time
from pathlib import Path
import numpy as np

HERE = Path(__file__).parent
sys.path.insert(0, "/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development/scripts")
import biohub_trackastra_link as btl

btl.bootstrap_trackastra(HERE / "trackastra-0.5.3-py3-none-any.whl", HERE / "tk_unpacked")
model = btl.load_trackastra_transformer(HERE / "ctc_model", device="cpu")

MOVIE = sys.argv[1] if len(sys.argv) > 1 else "6bba_05b6850b"
d = np.load(f"outprobe/ilp_cache/{MOVIE}.npz")
node, edge = d["node"], d["edge"]
t = node[:, 1].astype(int)
T = int(t.max()) + 1

points, ids = [], []
for tt in range(T):
    sel = np.where(t == tt)[0]
    sel = sel[np.argsort(node[sel, 0])]
    points.append(node[sel, 2:5])
    ids.append(node[sel, 0].astype(np.int64))

ilp = {(int(a), int(b)) for a, b, _ in edge}
print(f"{MOVIE}: {len(node):,} detections over {T} frames, {len(ilp):,} ILP edges")
print(f"{'scale':>7}{'edges':>9}{'agree_J':>10}{'ilp_recall':>12}{'forks':>8}{'sec':>7}")

for scale in [1.5, 2.0, 3.0, 4.0]:
    t0 = time.time()
    with contextlib.redirect_stderr(io.StringIO()):
        sol, stats = btl.link_movie(
            points_by_frame=points, transformer=model, feature_mode="synthetic",
            coord_scale=scale, max_distance_um=12.0, batch_size=1,
            progress=lambda x, **k: x,
        )
    pred = set()
    outdeg = {}
    for s, tt2 in sol.edges():
        sn, tn = sol.nodes[s], sol.nodes[tt2]
        a = int(ids[int(sn["time"])][int(sn["label"]) - 1])
        b = int(ids[int(tn["time"])][int(tn["label"]) - 1])
        pred.add((a, b))
        outdeg[a] = outdeg.get(a, 0) + 1
    inter = len(pred & ilp)
    print(f"{scale:>7.1f}{len(pred):>9,}{inter/max(1,len(pred|ilp)):>10.3f}"
          f"{inter/max(1,len(ilp)):>12.3f}{sum(1 for v in outdeg.values() if v>=2):>8,}"
          f"{time.time()-t0:>7.0f}")
print(f"median NN {stats['median_nn_um']:.2f} um")
