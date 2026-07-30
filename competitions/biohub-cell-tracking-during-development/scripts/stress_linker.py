"""Stress the Trackastra ctc checkpoint in the regime our real data lives in.

The first prototype used well-separated nuclei and small motion, which any
linker solves. What decides whether this is worth a submission slot is the
hard regime: nuclei packed at a few micrometres, moving an appreciable
fraction of that spacing per frame. This also sweeps the one hyperparameter
the 2D->3D / domain transfer really turns on - the coordinate scale fed to
the transformer's positional bias.
"""

from __future__ import annotations

import io
import contextlib
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).parent
REPO = Path("/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development")
sys.path.insert(0, str(REPO / "scripts"))

import biohub_trackastra_link as btl  # noqa: E402

VOXEL_UM = btl.VOXEL_UM
ISO_UM = VOXEL_UM[0]


def make_movie(n_frames, n_cells, spacing_um, motion_um, divisions, seed):
    """Nuclei on a jittered lattice at a target spacing, with known links."""
    rng = np.random.default_rng(seed)
    side = int(np.ceil(n_cells ** (1 / 3)))
    grid = np.stack(
        np.meshgrid(*[np.arange(side)] * 3, indexing="ij"), axis=-1
    ).reshape(-1, 3)[:n_cells]
    pos = (grid * spacing_um + rng.normal(0, spacing_um * 0.12, (n_cells, 3))) / ISO_UM
    pos += 6.0

    shape_iso = tuple(int(np.ceil(pos[:, a].max())) + 8 for a in range(3))
    velocity = rng.normal(0, motion_um / ISO_UM, size=(n_cells, 3))

    tracks = [pos.copy()]
    lineage: list[list[int]] = [[-1] * n_cells]
    current = pos.copy()
    n_div = 0
    for t in range(1, n_frames):
        moved = current + velocity + rng.normal(0, motion_um * 0.3 / ISO_UM, current.shape)
        parents = list(range(len(current)))
        if divisions and t % 4 == 0 and n_div < divisions:
            extra, extra_parents = [], []
            for i in range(min(3, divisions - n_div)):
                offset = rng.normal(0, 1.0, 3)
                offset = offset / np.linalg.norm(offset) * (spacing_um * 0.35 / ISO_UM)
                moved[i] = moved[i] + offset
                extra.append(moved[i] - 2 * offset)
                extra_parents.append(i)
                n_div += 1
            moved = np.concatenate([moved, np.stack(extra)], axis=0)
            velocity = np.concatenate([velocity, velocity[: len(extra)]], axis=0)
            parents = parents + extra_parents
        current = moved
        tracks.append(current.copy())
        lineage.append(parents)

    volumes, points_by_frame = [], []
    zz, yy, xx = np.indices(shape_iso)
    sigma = max(1.2, spacing_um * 0.28 / ISO_UM)
    for iso_points in tracks:
        volume = np.zeros(shape_iso, dtype=np.float32)
        for p in iso_points:
            d2 = (zz - p[0]) ** 2 + (yy - p[1]) ** 2 + (xx - p[2]) ** 2
            volume += np.exp(-d2 / (2 * sigma**2))
        volume += rng.normal(0, 0.02, shape_iso)
        volumes.append((np.repeat(volume, 4, axis=1).repeat(4, axis=2) * 1000).astype(np.float32))
        points_by_frame.append(iso_points * np.array([1.0, 4.0, 4.0]))

    gt = {
        ((t - 1, parent), (t, i))
        for t in range(1, n_frames)
        for i, parent in enumerate(lineage[t])
        if parent >= 0
    }
    return volumes, points_by_frame, gt


def score(solution, gt):
    pred = {
        (
            (solution.nodes[s]["time"], solution.nodes[s]["label"] - 1),
            (solution.nodes[t]["time"], solution.nodes[t]["label"] - 1),
        )
        for s, t in solution.edges()
    }
    tp = len(pred & gt)
    jaccard = tp / max(1, len(pred | gt))
    return jaccard, tp / max(1, len(gt)), tp / max(1, len(pred))


def main() -> int:
    btl.bootstrap_trackastra(
        HERE / "trackastra-0.5.3-py3-none-any.whl", HERE / "tk_unpacked"
    )
    transformer = btl.load_trackastra_transformer(HERE / "ctc_model", device="cpu")

    regimes = [
        ("easy      ", dict(spacing_um=14.0, motion_um=1.0)),
        ("packed    ", dict(spacing_um=7.0, motion_um=1.5)),
        ("packed+mot", dict(spacing_um=7.0, motion_um=3.0)),
        ("dense     ", dict(spacing_um=5.0, motion_um=2.0)),
        ("dense+fast", dict(spacing_um=5.0, motion_um=3.5)),
    ]
    scales = [2.0, 3.0, 4.0, 5.0, 6.0]

    print(f"{'regime':<11} {'target_nn':>9} " + "".join(f"{f'scale={s}':>14}" for s in scales))
    worst = 1.0
    for name, params in regimes:
        volumes, points, gt = make_movie(
            n_frames=10, n_cells=125, divisions=6, seed=7, **params
        )
        cells = {
            "spacing": params["spacing_um"],
            "motion": params["motion_um"],
        }
        row = []
        for scale in scales:
            with contextlib.redirect_stderr(io.StringIO()):
                solution, stats = btl.link_movie(
                    points_by_frame=points,
                    transformer=transformer,
                    frame_provider=lambda t: volumes[t],
                    feature_mode="image",
                    coord_scale=scale,
                    batch_size=2,
                    progress=lambda x, **k: x,
                )
            jaccard, recall, precision = score(solution, gt)
            row.append(f"{jaccard:>9.3f}({recall:.2f})")
            worst = min(worst, jaccard)
        auto = stats["coord_scale_units_per_um"]
        print(
            f"{name} sp={cells['spacing']:.0f}um mv={cells['motion']:.1f}um "
            + "".join(f"{v:>14}" for v in row)
        )
    print(f"\nauto-calibrated scale on the last regime: {auto:.2f} units/um")
    print("cell = edge Jaccard (recall)")
    return 0 if worst > 0.5 else 1


if __name__ == "__main__":
    raise SystemExit(main())
