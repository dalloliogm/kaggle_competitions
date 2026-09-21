"""Decisive local probe: dense nuclei moving under a spatially SMOOTH flow.

The incoherent-motion stress test is close to worst case for an attention
model, because neighbouring cells carry no mutual information. A developing
embryo moves as a deforming tissue, so neighbours move together and the
transformer's spatial attention has something to exploit. This regime is the
fair proxy for our data, and it is where the scale hyperparameter has to be
chosen.
"""

from __future__ import annotations

import contextlib
import io
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).parent
REPO = Path("/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development")
sys.path.insert(0, str(REPO / "scripts"))

import biohub_trackastra_link as btl  # noqa: E402

ISO_UM = btl.VOXEL_UM[0]


def make_movie(n_frames, n_cells, spacing_um, motion_um, incoherence, divisions, seed):
    """Nuclei on a jittered lattice advected by a smooth, time-varying flow."""
    rng = np.random.default_rng(seed)
    side = int(np.ceil(n_cells ** (1 / 3)))
    grid = np.stack(
        np.meshgrid(*[np.arange(side)] * 3, indexing="ij"), axis=-1
    ).reshape(-1, 3)[:n_cells]
    pos = (grid * spacing_um + rng.normal(0, spacing_um * 0.12, (n_cells, 3))) / ISO_UM
    pos += 6.0
    extent = pos.max(axis=0) - pos.min(axis=0) + 1e-6
    centre = pos.mean(axis=0)

    def flow(points, t):
        """Rotation about z plus a breathing radial term - smooth in space."""
        rel = (points - centre) / extent
        angle = 0.6 * np.sin(0.5 * t)
        rot = np.stack([np.zeros(len(rel)), -rel[:, 2], rel[:, 1]], axis=1)
        radial = rel * np.cos(0.4 * t)
        return (angle * rot + 0.7 * radial) * (motion_um / ISO_UM) * 2.0

    tracks = [pos.copy()]
    lineage: list[list[int]] = [[-1] * n_cells]
    current = pos.copy()
    n_div = 0
    for t in range(1, n_frames):
        moved = current + flow(current, t) + rng.normal(
            0, incoherence * motion_um / ISO_UM, current.shape
        )
        parents = list(range(len(current)))
        if divisions and t % 3 == 0 and n_div < divisions:
            extra, extra_parents = [], []
            for i in range(min(3, divisions - n_div)):
                offset = rng.normal(0, 1.0, 3)
                offset = offset / np.linalg.norm(offset) * (spacing_um * 0.35 / ISO_UM)
                moved[i] = moved[i] + offset
                extra.append(moved[i] - 2 * offset)
                extra_parents.append(i)
                n_div += 1
            moved = np.concatenate([moved, np.stack(extra)], axis=0)
            parents = parents + extra_parents
        current = moved
        tracks.append(current.copy())
        lineage.append(parents)

    lo = np.min([t.min(axis=0) for t in tracks], axis=0)
    tracks = [t - lo + 6.0 for t in tracks]
    shape_iso = tuple(
        int(np.ceil(max(t[:, a].max() for t in tracks))) + 8 for a in range(3)
    )

    volumes, points_by_frame = [], []
    zz, yy, xx = np.indices(shape_iso)
    sigma = max(1.2, spacing_um * 0.28 / ISO_UM)
    for iso_points in tracks:
        volume = np.zeros(shape_iso, dtype=np.float32)
        for p in iso_points:
            d2 = (zz - p[0]) ** 2 + (yy - p[1]) ** 2 + (xx - p[2]) ** 2
            volume += np.exp(-d2 / (2 * sigma**2))
        volume += rng.normal(0, 0.02, shape_iso)
        volumes.append(
            (np.repeat(volume, 4, axis=1).repeat(4, axis=2) * 1000).astype(np.float32)
        )
        points_by_frame.append(iso_points * np.array([1.0, 4.0, 4.0]))

    gt = {
        ((t - 1, parent), (t, i))
        for t in range(1, n_frames)
        for i, parent in enumerate(lineage[t])
        if parent >= 0
    }
    return volumes, points_by_frame, gt


def nearest_neighbour_baseline(points_by_frame, gt):
    """What a plain greedy nearest-neighbour linker gets, for reference."""
    from scipy.optimize import linear_sum_assignment
    from scipy.spatial.distance import cdist

    pred = set()
    for t in range(1, len(points_by_frame)):
        a, b = points_by_frame[t - 1], points_by_frame[t]
        if len(a) == 0 or len(b) == 0:
            continue
        cost = cdist(a * np.array([1.625, 0.40625, 0.40625]), b * np.array([1.625, 0.40625, 0.40625]))
        rows, cols = linear_sum_assignment(cost)
        for r, c in zip(rows, cols):
            pred.add(((t - 1, int(r)), (t, int(c))))
    tp = len(pred & gt)
    return tp / max(1, len(pred | gt))


def score(solution, gt):
    pred = {
        (
            (solution.nodes[s]["time"], solution.nodes[s]["label"] - 1),
            (solution.nodes[t]["time"], solution.nodes[t]["label"] - 1),
        )
        for s, t in solution.edges()
    }
    tp = len(pred & gt)
    return tp / max(1, len(pred | gt)), tp / max(1, len(gt))


def main() -> int:
    btl.bootstrap_trackastra(
        HERE / "trackastra-0.5.3-py3-none-any.whl", HERE / "tk_unpacked"
    )
    transformer = btl.load_trackastra_transformer(HERE / "ctc_model", device="cpu")

    regimes = [
        ("coherent  5um/2.0um", dict(spacing_um=5.0, motion_um=2.0, incoherence=0.15)),
        ("coherent  5um/3.5um", dict(spacing_um=5.0, motion_um=3.5, incoherence=0.15)),
        ("coherent  7um/3.0um", dict(spacing_um=7.0, motion_um=3.0, incoherence=0.15)),
        ("half-cohr 5um/3.5um", dict(spacing_um=5.0, motion_um=3.5, incoherence=0.50)),
    ]
    scales = [3.0, 4.0, 6.0, 9.0]

    header = f"{'regime':<20}{'hungarian':>10}" + "".join(f"{f'sc={s}':>12}" for s in scales)
    print(header)
    for name, params in regimes:
        volumes, points, gt = make_movie(
            n_frames=10, n_cells=125, divisions=6, seed=11, **params
        )
        baseline = nearest_neighbour_baseline(points, gt)
        row = []
        for scale in scales:
            with contextlib.redirect_stderr(io.StringIO()):
                solution, _ = btl.link_movie(
                    points_by_frame=points,
                    transformer=transformer,
                    frame_provider=lambda t: volumes[t],
                    feature_mode="image",
                    coord_scale=scale,
                    batch_size=2,
                    progress=lambda x, **k: x,
                )
            jaccard, recall = score(solution, gt)
            row.append(f"{jaccard:>7.3f}({recall:.2f})")
        print(f"{name:<20}{baseline:>10.3f}" + "".join(f"{v:>12}" for v in row))
    print("\ncells = Trackastra edge Jaccard (recall); hungarian = physical-distance baseline")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
