"""Local prototype: run the real pretrained Trackastra ctc checkpoint on a
synthetic 3D+time movie built to look like our data, and check that the
linker module produces a structurally valid submission frame.

This cannot tell us the leaderboard score, but it does answer the questions
that block everything else:
  * does the offline bootstrap import cleanly with stubbed native deps
  * does the 3D `ctc` checkpoint actually accept our feature layout
  * does it recover known ground-truth links at our physical scale
  * does the graph -> submission conversion preserve every invariant
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).parent
REPO = Path("/home/user/kaggle_competitions/competitions/biohub-cell-tracking-during-development")
sys.path.insert(0, str(REPO / "scripts"))

import biohub_trackastra_link as btl  # noqa: E402

VOXEL_UM = btl.VOXEL_UM


def make_movie(
    n_frames: int = 12,
    n_cells: int = 40,
    shape_iso=(24, 96, 96),
    drift_um: float = 1.2,
    divide_at: int = 6,
    seed: int = 0,
):
    """A packed cluster of nuclei that drift, jitter, and divide once.

    Returns raw (anisotropic) volumes plus per-frame centroids in raw voxel
    coordinates and the ground-truth (t, i) -> (t+1, j) links.
    """
    rng = np.random.default_rng(seed)
    iso_um = VOXEL_UM[0]

    # Seed positions in isotropic voxels, spaced like a packed embryo.
    pos = np.stack(
        [
            rng.uniform(4, shape_iso[0] - 4, n_cells),
            rng.uniform(6, shape_iso[1] - 6, n_cells),
            rng.uniform(6, shape_iso[2] - 6, n_cells),
        ],
        axis=1,
    )
    velocity = rng.normal(0, drift_um / iso_um, size=(n_cells, 3))

    tracks: list[np.ndarray] = []
    lineage: list[list[int]] = []  # lineage[t][i] = index in frame t-1, or -1
    divisions: dict[int, tuple[int, int]] = {}

    current = pos.copy()
    parents = list(range(n_cells))
    tracks.append(current.copy())
    lineage.append([-1] * len(current))

    for t in range(1, n_frames):
        moved = current + velocity + rng.normal(0, 0.35, current.shape)
        parents = list(range(len(current)))
        if t == divide_at:
            # Split the first three cells into two daughters each.
            extra, extra_parents = [], []
            for i in range(3):
                offset = rng.normal(0, 1.0, 3)
                offset = offset / np.linalg.norm(offset) * (2.5 / iso_um)
                moved[i] = moved[i] + offset
                extra.append(moved[i] - 2 * offset)
                extra_parents.append(i)
            moved = np.concatenate([moved, np.stack(extra)], axis=0)
            parents = parents + extra_parents
            velocity = np.concatenate([velocity, velocity[:3]], axis=0)
            divisions[t] = tuple(extra_parents)
        current = moved
        tracks.append(current.copy())
        lineage.append(parents)

    volumes = []
    points_by_frame = []
    for t, iso_points in enumerate(tracks):
        volume = np.zeros(shape_iso, dtype=np.float32)
        zz, yy, xx = np.indices(shape_iso)
        for p in iso_points:
            d2 = (zz - p[0]) ** 2 + (yy - p[1]) ** 2 + (xx - p[2]) ** 2
            volume += np.exp(-d2 / (2 * (2.0**2)))
        volume += rng.normal(0, 0.02, shape_iso)
        # Blow the isotropic volume back up into the raw anisotropic grid.
        raw = np.repeat(volume, 4, axis=1).repeat(4, axis=2)
        volumes.append((raw * 1000).astype(np.float32))
        points_by_frame.append(iso_points * np.array([1.0, 4.0, 4.0]))

    gt_links = set()
    for t in range(1, n_frames):
        for i, parent in enumerate(lineage[t]):
            if parent >= 0:
                gt_links.add(((t - 1, parent), (t, i)))
    return volumes, points_by_frame, gt_links, divisions


def main() -> int:
    wheel = HERE / "trackastra-0.5.3-py3-none-any.whl"
    model_dir = HERE / "tk"  # holds ctc config.yaml + train_config.yaml
    weights = HERE / "tkw" / "ctc" / "model.pt"

    root = btl.bootstrap_trackastra(wheel, HERE / "tk_unpacked")
    print(f"trackastra import root: {root}")
    import trackastra

    print(f"trackastra {trackastra.__version__}")

    # Assemble a self-contained ctc model folder.
    folder = HERE / "ctc_model"
    folder.mkdir(exist_ok=True)
    for name in ("config.yaml", "train_config.yaml"):
        (folder / name).write_bytes((model_dir / name).read_bytes())
    if not (folder / "model.pt").exists():
        (folder / "model.pt").write_bytes(weights.read_bytes())

    transformer = btl.load_trackastra_transformer(folder, device="cpu")
    print(
        f"loaded ctc: coord_dim={transformer.config['coord_dim']} "
        f"feat_dim={transformer.config['feat_dim']} "
        f"window={transformer.config['window']} "
        f"cutoff={transformer.config['spatial_pos_cutoff']}"
    )

    volumes, points_by_frame, gt_links, divisions = make_movie()
    print(
        f"synthetic movie: {len(volumes)} frames, "
        f"{sum(len(p) for p in points_by_frame)} detections, "
        f"{len(gt_links)} true links, divisions at {sorted(divisions)}"
    )

    failures = 0
    for feature_mode in ("image", "synthetic"):
        solution, stats = btl.link_movie(
            points_by_frame=points_by_frame,
            transformer=transformer,
            frame_provider=lambda t: volumes[t],
            feature_mode=feature_mode,
            batch_size=2,
        )
        pred_links = set()
        for s, t in solution.edges():
            pred_links.add(
                (
                    (solution.nodes[s]["time"], solution.nodes[s]["label"] - 1),
                    (solution.nodes[t]["time"], solution.nodes[t]["label"] - 1),
                )
            )
        tp = len(pred_links & gt_links)
        recall = tp / max(1, len(gt_links))
        precision = tp / max(1, len(pred_links))
        print(
            f"\n[{feature_mode}] scale={stats['coord_scale_units_per_um']:.2f} u/um "
            f"(median NN {stats['median_nn_um']:.2f} um, cutoff "
            f"{stats['spatial_pos_cutoff_um']:.1f} um)"
        )
        print(
            f"[{feature_mode}] candidate={stats['candidate_edges']} "
            f"solution={stats['solution_edges']} "
            f"recall={recall:.3f} precision={precision:.3f}"
        )

        node_rows, edge_rows = btl.lineage_to_rows(
            solution, points_by_frame, dataset="synthetic_movie"
        )
        frame = btl.rows_to_frame(node_rows + edge_rows)
        harness = btl.check_submission_frame(frame)
        print(f"[{feature_mode}] harness OK: {harness}")

        if recall < 0.90:
            print(f"[{feature_mode}] FAIL: recall {recall:.3f} below 0.90")
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
