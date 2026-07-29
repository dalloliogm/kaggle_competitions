"""Is Trackastra's shortfall the model, or the greedy acceptance threshold?

track_greedy stops accepting edges below `threshold` on a parental-softmax
weight. In a dense scene the correct parent can be confidently ranked first
yet still carry a probability below 0.5, in which case the link is dropped for
a reason that has nothing to do with the association being wrong.
"""
import contextlib, io, sys
from pathlib import Path
import numpy as np

HERE = Path(__file__).parent
sys.path.insert(0, "/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development/scripts")
import biohub_trackastra_link as btl
from coherent_linker import make_movie, nearest_neighbour_baseline, score

btl.bootstrap_trackastra(HERE / "trackastra-0.5.3-py3-none-any.whl", HERE / "tk_unpacked")
model = btl.load_trackastra_transformer(HERE / "ctc_model", device="cpu")

regimes = [
    ("coherent 5um/2.0um", dict(spacing_um=5.0, motion_um=2.0, incoherence=0.15)),
    ("coherent 5um/3.5um", dict(spacing_um=5.0, motion_um=3.5, incoherence=0.15)),
    ("half-coh 5um/3.5um", dict(spacing_um=5.0, motion_um=3.5, incoherence=0.50)),
]
thresholds = [0.5, 0.3, 0.15, 0.05, 0.01]
print(f"{'regime':<20}{'hungarian':>10}" + "".join(f"{f'thr={t}':>12}" for t in thresholds))
for name, params in regimes:
    volumes, points, gt = make_movie(n_frames=10, n_cells=125, divisions=6, seed=11, **params)
    base = nearest_neighbour_baseline(points, gt)
    row = []
    for thr in thresholds:
        with contextlib.redirect_stderr(io.StringIO()):
            sol, _ = btl.link_movie(
                points_by_frame=points, transformer=model,
                frame_provider=lambda t: volumes[t], feature_mode="image",
                coord_scale=3.0, greedy_threshold=thr, edge_threshold=0.005,
                batch_size=2, progress=lambda x, **k: x,
            )
        j, r = score(sol, gt)
        row.append(f"{j:>7.3f}({r:.2f})")
    print(f"{name:<20}{base:>10.3f}" + "".join(f"{v:>12}" for v in row))
print("\ncells = Trackastra edge Jaccard (recall) at coord_scale=3.0")
