"""Trackastra linking stage for the Biohub cell-tracking competition.

This module replaces the learned node-transformer + ILP association stage with
the pretrained Trackastra association transformer, while keeping our own
TemporalUNet3D detections.  It is written so the exact same source can be

* unit tested locally on synthetic volumes, and
* pasted verbatim into a Kaggle kernel that has no internet access.

Three frictions are solved here.

1. OFFLINE PACKAGING.  ``bootstrap_trackastra`` puts an unpacked pure-python
   wheel on ``sys.path`` instead of pip-installing it, and installs import
   stubs for the two optional native dependencies (``edt``, ``lz4``) that the
   package imports at module scope but that our code path never calls.

2. 2D vs 3D.  We use the ``ctc`` checkpoint, not ``general_2d``.  Its
   ``config.yaml`` reports ``coord_dim: 3`` / ``feat_dim: 12`` and its
   ``train_config.yaml`` reports ``ndim: 3`` with ``Fluo-N3DH-CE`` (a 3D+time
   developing embryo) in the training set, so no slice-and-stitch or maximum
   projection is needed.  What does have to be handled is the *scale* gap:
   Trackastra was trained on raw pixel coordinates, and its
   ``spatial_pos_cutoff`` and rotary positional bias are expressed in those
   units.  ``calibrate_coord_scale`` therefore rescales our physical
   coordinates so that the median nearest-neighbour spacing lands on a
   CTC-like value.

3. FORMAT CONVERSION.  Trackastra's public API wants dense instance masks.
   We only have centroids, so ``frame_features`` builds ``WRFeatures``
   directly, deriving genuine region properties from a nearest-seed
   segmentation of the detection centroids (``feature_mode="image"``) or from
   an analytic sphere when the images are too expensive to read
   (``feature_mode="synthetic"``).  ``lineage_to_rows`` converts the resulting
   ``networkx`` lineage back into competition node/edge rows.
"""

from __future__ import annotations

import logging
import sys
import types
import zipfile
from collections import OrderedDict
from pathlib import Path
from typing import Callable, Iterable, Sequence

import numpy as np

logger = logging.getLogger(__name__)

# Physical voxel size of the competition movies, (z, y, x) micrometres.
VOXEL_UM: tuple[float, float, float] = (1.625, 0.40625, 0.40625)

# Trackastra's ``regionprops2`` feature block for 3D data, in the order that
# ``WRFeatures.from_mask_img`` stacks it: 1 + 1 + 9 + 1 = 12 = the ``ctc``
# checkpoint's ``feat_dim``.
FEATURE_ORDER: tuple[str, ...] = (
    "equivalent_diameter_area",
    "intensity_mean",
    "inertia_tensor",
    "border_dist",
)
FEATURE_WIDTHS: dict[str, int] = {
    "equivalent_diameter_area": 1,
    "intensity_mean": 1,
    "inertia_tensor": 9,
    "border_dist": 1,
}


# --------------------------------------------------------------------------
# 1. offline packaging
# --------------------------------------------------------------------------


def _install_import_stub(name: str) -> bool:
    """Register a stub module if ``name`` cannot be imported.

    Trackastra imports ``edt`` and ``lz4.frame`` at module scope but only uses
    them for the slow border-distance variant and for compressed CTC dataset
    caches.  Neither is on our code path, so a stub is safer offline than
    pip-installing a wheel built for another Python ABI.

    The stub resolves *any* attribute to a placeholder callable rather than a
    fixed list, because unrelated libraries probe these modules at import time
    (``fsspec`` reads ``lz4.frame.open`` while registering codecs). Attribute
    access has to succeed; only an actual call raises.
    """
    try:
        __import__(name)
        return False
    except ImportError:
        pass

    parts = name.split(".")
    module = types.ModuleType(name)

    def _unavailable(*_args, **_kwargs):
        raise RuntimeError(
            f"{name} is a stub in this environment; "
            "the Trackastra linker does not use it."
        )

    def _getattr(attribute: str):
        if attribute.startswith("__"):
            raise AttributeError(attribute)
        return _unavailable

    module.__getattr__ = _getattr  # type: ignore[attr-defined]
    module.__all__ = []  # type: ignore[attr-defined]
    sys.modules[name] = module

    # Materialise any missing parent packages so ``import a.b`` resolves.
    for depth in range(1, len(parts)):
        parent_name = ".".join(parts[:depth])
        if parent_name not in sys.modules:
            parent = types.ModuleType(parent_name)
            parent.__path__ = []  # type: ignore[attr-defined]
            parent.__getattr__ = _getattr  # type: ignore[attr-defined]
            sys.modules[parent_name] = parent
        setattr(sys.modules[parent_name], parts[depth], sys.modules[".".join(parts[: depth + 1])])
    return True


#: Native dependencies Trackastra imports at module scope but never needs on
#: our code path. Call ``bootstrap_trackastra`` *after* the notebook's own
#: dependency setup so that genuinely used packages (zarr, geff) are real.
OPTIONAL_NATIVE_DEPS: tuple[str, ...] = ("edt", "lz4.frame")

#: Libraries that probe optional compression backends while they initialise.
#: ``joblib.register_compressor`` and ``fsspec.register_compression`` both look
#: up ``lz4.frame`` and reject a placeholder, so they are imported for real
#: before any stub is registered.
STUB_PROBING_LIBRARIES: tuple[str, ...] = ("joblib", "fsspec")


def bootstrap_trackastra(
    wheel_or_dir: str | Path,
    unpack_dir: str | Path,
    optional_deps: Sequence[str] = OPTIONAL_NATIVE_DEPS,
    probing_libraries: Sequence[str] = STUB_PROBING_LIBRARIES,
) -> Path:
    """Make ``import trackastra`` work offline and return the import root.

    ``wheel_or_dir`` may be the ``trackastra-*.whl`` shipped in
    ``subinium/biohub-trackastra-public-weights-mirror`` or an already
    unpacked directory.  Kaggle input is read-only, so the wheel is unpacked
    into ``unpack_dir`` (somewhere under ``/kaggle/working``).
    """
    source = Path(wheel_or_dir)
    if source.is_dir():
        root = source
    else:
        root = Path(unpack_dir)
        if not (root / "trackastra" / "__init__.py").exists():
            root.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(source) as archive:
                archive.extractall(root)
        if not (root / "trackastra" / "__init__.py").exists():
            raise RuntimeError(f"No trackastra package found after unpacking {source}")

    for library in probing_libraries:
        try:
            __import__(library)
        except ImportError:
            pass

    stubbed = [name for name in optional_deps if _install_import_stub(name)]
    if stubbed:
        logger.info("Installed import stubs for %s", ", ".join(stubbed))

    root_text = str(root)
    if root_text not in sys.path:
        sys.path.insert(0, root_text)
    return root


def load_trackastra_transformer(model_dir: str | Path, device: str):
    """Load the pretrained association transformer from a local folder."""
    from trackastra.model import TrackingTransformer

    model_dir = Path(model_dir)
    transformer = TrackingTransformer.from_folder(model_dir, map_location="cpu")
    transformer = transformer.to(device)
    transformer.eval()

    config = transformer.config
    if int(config["coord_dim"]) != 3:
        raise ValueError(
            f"{model_dir} is a {config['coord_dim']}D checkpoint. The biohub movies "
            "are 3D+time; load the 'ctc' checkpoint, not 'general_2d'."
        )
    expected = sum(FEATURE_WIDTHS[name] for name in FEATURE_ORDER)
    if int(config["feat_dim"]) != expected:
        raise ValueError(
            f"Checkpoint expects feat_dim={config['feat_dim']} but this module builds "
            f"{expected} features ({', '.join(FEATURE_ORDER)})."
        )
    return transformer


# --------------------------------------------------------------------------
# 2. coordinate calibration
# --------------------------------------------------------------------------


def points_to_um(points_voxel: np.ndarray, voxel_um: Sequence[float] = VOXEL_UM) -> np.ndarray:
    """Convert (z, y, x) voxel centroids to physical micrometres."""
    points = np.asarray(points_voxel, dtype=np.float64)
    if points.ndim != 2 or points.shape[1] != 3:
        raise ValueError(f"Expected an (N, 3) array of zyx points, got {points.shape}")
    return points * np.asarray(voxel_um, dtype=np.float64)


def median_neighbour_distance_um(points_by_frame: Sequence[np.ndarray]) -> float:
    """Median within-frame nearest-neighbour distance, in micrometres."""
    from scipy.spatial import cKDTree

    samples: list[np.ndarray] = []
    for points in points_by_frame:
        if len(points) < 2:
            continue
        tree = cKDTree(points)
        distances, _ = tree.query(points, k=2)
        samples.append(distances[:, 1])
    if not samples:
        raise ValueError("Need at least one frame with two detections to calibrate scale")
    return float(np.median(np.concatenate(samples)))


def calibrate_coord_scale(
    points_by_frame: Sequence[np.ndarray],
    target_neighbour_units: float = 30.0,
    clamp: tuple[float, float] = (0.5, 40.0),
) -> tuple[float, float]:
    """Return ``(units_per_um, median_nn_um)`` for the Trackastra coordinate frame.

    Trackastra's ``spatial_pos_cutoff`` (256 for the ``ctc`` checkpoint) and its
    rotary spatial bias are expressed in the pixel units the model was trained
    on, where neighbouring nuclei sit roughly ``target_neighbour_units`` apart.
    Feeding raw micrometres would put every cell in the movie inside the
    cutoff and squash the positional bias into its smallest bucket, so we
    rescale to match the training geometry instead.
    """
    median_nn = median_neighbour_distance_um(points_by_frame)
    if median_nn <= 0:
        raise ValueError("Median nearest-neighbour distance must be positive")
    scale = target_neighbour_units / median_nn
    return float(np.clip(scale, *clamp)), median_nn


# --------------------------------------------------------------------------
# 3. detections -> WRFeatures
# --------------------------------------------------------------------------


def pool_frame_xy(volume: np.ndarray, factor: int) -> np.ndarray:
    """Mean-pool a (Z, Y, X) volume in xy, matching the detector's grid.

    The movies are anisotropic at (1.625, 0.40625, 0.40625) um/voxel, so
    pooling xy by 4 yields an approximately isotropic 1.625 um grid. Region
    properties are only comparable to Trackastra's training data when they are
    measured on an isotropic grid.
    """
    if factor <= 1:
        return np.asarray(volume, dtype=np.float32)
    z, y, x = volume.shape
    y2 = (y // factor) * factor
    x2 = (x // factor) * factor
    cropped = np.asarray(volume[:, :y2, :x2], dtype=np.float32)
    return cropped.reshape(z, y2 // factor, factor, x2 // factor, factor).mean(axis=(2, 4))


def percentile_normalize(volume: np.ndarray, subsample: int = 4) -> np.ndarray:
    """Trackastra's own image normalisation, applied per frame.

    ``Trackastra.track`` normalises the whole movie at once; we bypass that
    entry point, so the same 1/99.8 percentile normalisation is applied here.
    """
    x = np.asarray(volume, dtype=np.float32)
    if all(s > 64 * subsample for s in x.shape[-2:]):
        y = x[..., ::subsample, ::subsample]
    else:
        y = x
    lo, hi = np.percentile(y, (1.0, 99.8)).astype(np.float32)
    return (x - lo) / (hi - lo + 1e-8)


def seeded_instance_labels(
    volume: np.ndarray,
    seeds_voxel: np.ndarray,
    max_radius_vox: float,
    foreground_percentile: float = 80.0,
) -> np.ndarray:
    """Grow instance labels outward from detection centroids.

    Our detector emits points, but Trackastra's features are region
    properties. Rather than painting identical spheres - which would make
    every shape feature a constant - each detection claims the voxels that are
    nearer to it than to any other detection, capped at ``max_radius_vox`` and
    restricted to foreground intensity. The result is a real, non-overlapping,
    intensity-aware segmentation derived only from information we already have.
    """
    from scipy import ndimage as ndi

    shape = volume.shape
    seeds = np.zeros(shape, dtype=np.int32)
    if len(seeds_voxel) == 0:
        return seeds

    index = np.rint(np.asarray(seeds_voxel, dtype=np.float64)).astype(np.int64)
    for axis in range(3):
        np.clip(index[:, axis], 0, shape[axis] - 1, out=index[:, axis])
    # Later labels win where two detections round to the same voxel; every
    # label that survives here is recovered by regionprops, and any that does
    # not is backfilled by the caller.
    seeds[index[:, 0], index[:, 1], index[:, 2]] = np.arange(1, len(index) + 1)

    distance, nearest = ndi.distance_transform_edt(seeds == 0, return_indices=True)
    labels = seeds[tuple(nearest)]
    threshold = float(np.percentile(volume, foreground_percentile))
    labels[(distance > max_radius_vox) | (volume < threshold)] = 0
    return labels.astype(np.int32)


def _sphere_reference_features(radius_units: float) -> dict[str, np.ndarray]:
    """Region properties of an ideal solid sphere, in Trackastra units.

    Used by ``feature_mode="synthetic"``. ``equivalent_diameter_area`` is the
    diameter itself; skimage's ``inertia_tensor`` is the central second-moment
    matrix normalised by area, which for a solid ball of radius r is
    ``diag(r^2 / 5)``.
    """
    inertia = np.eye(3, dtype=np.float64) * (radius_units**2 / 5.0)
    return {
        "equivalent_diameter_area": np.array([2.0 * radius_units]),
        "inertia_tensor": inertia.reshape(-1),
    }


def frame_features(
    timepoint: int,
    points_voxel: np.ndarray,
    frame_provider: Callable[[int], np.ndarray] | None,
    coord_scale: float,
    feature_mode: str = "image",
    pool_factor: int = 4,
    point_downsample: int = 4,
    nucleus_radius_um: float = 3.0,
    voxel_um: Sequence[float] = VOXEL_UM,
):
    """Build one frame's ``WRFeatures`` straight from detection centroids.

    ``points_voxel`` is always in original-resolution voxels, because that is
    what the submission format and the official metric use. The volume handed
    back by ``frame_provider`` may already be xy-subsampled, so the two grids
    are decoupled: ``pool_factor`` is applied to the volume and
    ``point_downsample`` maps the points onto it. Pass ``pool_factor=1`` with
    ``point_downsample=4`` for a volume that was subsampled upstream.

    Returns ``(features, labels)`` where ``labels`` are 1-based indices into
    ``points_voxel``, so the caller can map Trackastra's output back onto our
    own detections without going through masks.
    """
    from trackastra.data import WRFeatures

    points_voxel = np.asarray(points_voxel, dtype=np.float64)
    count = len(points_voxel)
    labels = np.arange(1, count + 1, dtype=np.int32)
    timepoints = np.full(count, timepoint, dtype=np.int32)

    # Isotropic grid in units of the z voxel size, then into Trackastra units.
    iso_um = float(voxel_um[0])
    points_iso = points_voxel * (
        np.asarray(voxel_um, dtype=np.float64) / iso_um
    )
    units_per_iso_voxel = coord_scale * iso_um
    coords = (points_iso * units_per_iso_voxel).astype(np.float32)

    if count == 0:
        empty = OrderedDict(
            (name, np.zeros((0, FEATURE_WIDTHS[name]), dtype=np.float32))
            for name in FEATURE_ORDER
        )
        return (
            WRFeatures(
                coords=coords.reshape(0, 3),
                labels=labels,
                timepoints=timepoints,
                features=empty,
            ),
            labels,
        )

    if feature_mode == "image":
        if frame_provider is None:
            raise ValueError('feature_mode="image" needs a frame_provider')
        raw = frame_provider(timepoint)
        volume = pool_frame_xy(raw, pool_factor)
        # Map original-resolution points onto whatever grid the volume is on.
        seeds = points_voxel / np.array([1.0, point_downsample, point_downsample])
        normalized = percentile_normalize(volume)
        mask = seeded_instance_labels(
            volume, seeds, max_radius_vox=nucleus_radius_um / iso_um
        )
        measured = WRFeatures.from_mask_img(
            mask=mask[np.newaxis, ...],
            img=normalized[np.newaxis, ...],
            t_start=timepoint,
        )
        features = _align_measured_features(
            measured, labels, units_per_iso_voxel, nucleus_radius_um / iso_um
        )
    elif feature_mode == "synthetic":
        radius_units = (nucleus_radius_um / iso_um) * units_per_iso_voxel
        reference = _sphere_reference_features(radius_units)
        blocks = {
            "equivalent_diameter_area": np.tile(
                reference["equivalent_diameter_area"], (count, 1)
            ),
            "intensity_mean": np.full((count, 1), 0.5),
            "inertia_tensor": np.tile(reference["inertia_tensor"], (count, 1)),
            "border_dist": np.zeros((count, 1)),
        }
        features = OrderedDict(
            (name, blocks[name].astype(np.float32)) for name in FEATURE_ORDER
        )
    else:
        raise ValueError(f"Unknown feature_mode {feature_mode!r}")

    return (
        WRFeatures(
            coords=coords, labels=labels, timepoints=timepoints, features=features
        ),
        labels,
    )


def _align_measured_features(
    measured,
    labels: np.ndarray,
    units_per_iso_voxel: float,
    fallback_radius_vox: float,
) -> "OrderedDict[str, np.ndarray]":
    """Reindex measured region properties onto our detection order.

    ``regionprops`` skips labels with no voxels - a detection whose whole
    neighbourhood fell below the foreground threshold - so those rows are
    backfilled with the ideal-sphere values rather than dropped. Dropping them
    would silently delete detections from the submission.
    """
    count = len(labels)
    measured_index = {int(label): row for row, label in enumerate(measured.labels)}
    fallback = _sphere_reference_features(fallback_radius_vox * units_per_iso_voxel)

    aligned: "OrderedDict[str, np.ndarray]" = OrderedDict()
    for name in FEATURE_ORDER:
        width = FEATURE_WIDTHS[name]
        block = np.zeros((count, width), dtype=np.float32)
        if name == "equivalent_diameter_area":
            block[:] = fallback["equivalent_diameter_area"]
        elif name == "inertia_tensor":
            block[:] = fallback["inertia_tensor"]
        source = measured.features.get(name)
        if source is not None:
            source = np.asarray(source, dtype=np.float32).reshape(len(measured.labels), width)
            # Region properties are measured on the isotropic voxel grid;
            # lengths scale linearly and second moments quadratically into
            # Trackastra's coordinate units.
            if name == "equivalent_diameter_area":
                source = source * units_per_iso_voxel
            elif name == "inertia_tensor":
                source = source * (units_per_iso_voxel**2)
            for label, row in measured_index.items():
                if 1 <= label <= count:
                    block[label - 1] = source[row]
        aligned[name] = block
    return aligned


def build_features(
    points_by_frame: Sequence[np.ndarray],
    frame_provider: Callable[[int], np.ndarray] | None,
    coord_scale: float,
    feature_mode: str = "image",
    pool_factor: int = 4,
    point_downsample: int = 4,
    nucleus_radius_um: float = 3.0,
    voxel_um: Sequence[float] = VOXEL_UM,
    progress: Callable[[Iterable], Iterable] | None = None,
) -> list:
    """Build the per-frame ``WRFeatures`` list Trackastra windows over."""
    frames = range(len(points_by_frame))
    if progress is not None:
        frames = progress(frames)
    features = []
    for timepoint in frames:
        feature, _ = frame_features(
            timepoint=timepoint,
            points_voxel=points_by_frame[timepoint],
            frame_provider=frame_provider,
            coord_scale=coord_scale,
            feature_mode=feature_mode,
            pool_factor=pool_factor,
            point_downsample=point_downsample,
            nucleus_radius_um=nucleus_radius_um,
            voxel_um=voxel_um,
        )
        features.append(feature)
    return features


# --------------------------------------------------------------------------
# 4. association + lineage
# --------------------------------------------------------------------------


def link_movie(
    points_by_frame: Sequence[np.ndarray],
    transformer,
    frame_provider: Callable[[int], np.ndarray] | None = None,
    feature_mode: str = "image",
    coord_scale: float | None = None,
    target_neighbour_units: float = 30.0,
    edge_threshold: float = 0.05,
    greedy_threshold: float = 0.5,
    max_neighbors: int = 10,
    max_distance_um: float = 12.0,
    batch_size: int = 1,
    allow_divisions: bool = True,
    pool_factor: int = 4,
    point_downsample: int = 4,
    nucleus_radius_um: float = 3.0,
    voxel_um: Sequence[float] = VOXEL_UM,
    progress: Callable[[Iterable], Iterable] | None = None,
) -> tuple[object, dict]:
    """Link one movie's detections with Trackastra.

    Returns ``(solution_graph, stats)``. Nodes of the solution graph carry a
    ``time`` and a ``label``; ``(time, label - 1)`` indexes back into
    ``points_by_frame``.
    """
    from tqdm import tqdm

    from trackastra.data import build_windows
    from trackastra.model.predict import predict_windows
    from trackastra.tracking import build_graph, track_greedy

    progbar = tqdm if progress is None else progress

    points_um = [points_to_um(points, voxel_um) for points in points_by_frame]
    if coord_scale is None:
        coord_scale, median_nn_um = calibrate_coord_scale(
            points_um, target_neighbour_units=target_neighbour_units
        )
    else:
        median_nn_um = median_neighbour_distance_um(points_um)

    features = build_features(
        points_by_frame=points_by_frame,
        frame_provider=frame_provider,
        coord_scale=coord_scale,
        feature_mode=feature_mode,
        pool_factor=pool_factor,
        point_downsample=point_downsample,
        nucleus_radius_um=nucleus_radius_um,
        voxel_um=voxel_um,
        progress=None,
    )

    windows = build_windows(
        features,
        window_size=int(transformer.config["window"]),
        progbar_class=progbar,
        as_torch=True,
    )
    predictions = predict_windows(
        windows=windows,
        features=features,
        model=transformer,
        edge_threshold=edge_threshold,
        spatial_dim=3,
        batch_size=batch_size,
        progbar_class=progbar,
    )

    # ``build_graph`` measures distance in the same units as ``coords``.
    max_distance = max_distance_um * coord_scale
    candidate = build_graph(
        nodes=predictions["nodes"],
        weights=predictions["weights"],
        max_distance=max_distance,
        max_neighbors=max_neighbors,
        delta_t=1,
    )
    solution = track_greedy(
        candidate, allow_divisions=allow_divisions, threshold=greedy_threshold
    )

    stats = {
        "coord_scale_units_per_um": float(coord_scale),
        "median_nn_um": float(median_nn_um),
        "spatial_pos_cutoff_um": float(transformer.config["spatial_pos_cutoff"]) / coord_scale,
        "max_distance_um": float(max_distance_um),
        "detections": int(sum(len(p) for p in points_by_frame)),
        "predicted_weights": len(predictions["weights"]),
        "candidate_edges": int(candidate.number_of_edges()),
        "solution_nodes": int(solution.number_of_nodes()),
        "solution_edges": int(solution.number_of_edges()),
    }
    return solution, stats


# --------------------------------------------------------------------------
# 5. lineage -> submission rows
# --------------------------------------------------------------------------


def lineage_to_rows(
    solution,
    points_by_frame: Sequence[np.ndarray],
    dataset: str,
    min_track_length: int = 1,
    keep_isolated_nodes: bool = False,
) -> tuple[list[dict], list[dict]]:
    """Convert a Trackastra lineage into competition node and edge records.

    ``node_id`` is assigned per dataset and 1-based; the global ``id`` column
    is filled in by the caller once all datasets are known. Enforces the
    submission invariants locally: in-degree <= 1, out-degree <= 2,
    single-frame edge spans, integer non-negative coordinates.
    """
    import networkx as nx

    used: set[tuple[int, int]] = set()
    for node, data in solution.nodes(data=True):
        used.add((int(data["time"]), int(data["label"]) - 1))

    if keep_isolated_nodes:
        for t, points in enumerate(points_by_frame):
            for i in range(len(points)):
                used.add((t, i))

    edges: list[tuple[tuple[int, int], tuple[int, int]]] = []
    for source, target in solution.edges():
        s = (int(solution.nodes[source]["time"]), int(solution.nodes[source]["label"]) - 1)
        t = (int(solution.nodes[target]["time"]), int(solution.nodes[target]["label"]) - 1)
        if t[0] - s[0] != 1:
            raise ValueError(f"Edge {s} -> {t} does not span exactly one frame")
        edges.append((s, t))

    if min_track_length > 1:
        graph = nx.DiGraph()
        graph.add_nodes_from(used)
        graph.add_edges_from(edges)
        keep = set()
        for component in nx.weakly_connected_components(graph):
            span = {node[0] for node in component}
            if len(span) >= min_track_length:
                keep |= component
        used = keep
        edges = [(s, t) for s, t in edges if s in used and t in used]

    ordered = sorted(used)
    node_ids = {key: index + 1 for index, key in enumerate(ordered)}

    node_rows: list[dict] = []
    for (t, i) in ordered:
        z, y, x = points_by_frame[t][i]
        node_rows.append(
            {
                "dataset": dataset,
                "row_type": "node",
                "node_id": node_ids[(t, i)],
                "t": int(t),
                "z": max(0, int(round(float(z)))),
                "y": max(0, int(round(float(y)))),
                "x": max(0, int(round(float(x)))),
                "source_id": -1,
                "target_id": -1,
            }
        )

    indegree: dict[tuple[int, int], int] = {}
    outdegree: dict[tuple[int, int], int] = {}
    edge_rows: list[dict] = []
    for s, t in sorted(edges):
        if indegree.get(t, 0) >= 1 or outdegree.get(s, 0) >= 2:
            raise ValueError(f"Degree invariant violated at edge {s} -> {t}")
        indegree[t] = indegree.get(t, 0) + 1
        outdegree[s] = outdegree.get(s, 0) + 1
        edge_rows.append(
            {
                "dataset": dataset,
                "row_type": "edge",
                "node_id": -1,
                "t": -1,
                "z": -1,
                "y": -1,
                "x": -1,
                "source_id": node_ids[s],
                "target_id": node_ids[t],
            }
        )

    return node_rows, edge_rows


SUBMISSION_COLUMNS = [
    "id",
    "dataset",
    "row_type",
    "node_id",
    "t",
    "z",
    "y",
    "x",
    "source_id",
    "target_id",
]


def rows_to_frame(all_rows: Sequence[dict]):
    """Stack per-dataset records into the submission frame with global ids."""
    import pandas as pd

    frame = pd.DataFrame(list(all_rows), columns=[c for c in SUBMISSION_COLUMNS if c != "id"])
    frame.insert(0, "id", np.arange(len(frame), dtype=np.int64))
    for column in SUBMISSION_COLUMNS:
        if column not in ("dataset", "row_type"):
            frame[column] = frame[column].astype(np.int64)
    return frame


def check_submission_frame(frame) -> dict:
    """Structural harness. Raises on any violated submission invariant."""
    problems: list[str] = []

    if list(frame.columns) != SUBMISSION_COLUMNS:
        problems.append(f"Column mismatch: {list(frame.columns)}")
    if frame["id"].duplicated().any():
        problems.append("Duplicate global ids")
    if frame.isnull().to_numpy().any():
        problems.append("Null values present")

    nodes = frame[frame["row_type"] == "node"]
    edges = frame[frame["row_type"] == "edge"]

    if nodes.duplicated(subset=["dataset", "node_id"]).any():
        problems.append("node_id is not unique within a dataset")
    for column in ("t", "z", "y", "x"):
        if (nodes[column] < 0).any():
            problems.append(f"Negative {column} on a node row")

    stats: dict[str, object] = {
        "rows": int(len(frame)),
        "nodes": int(len(nodes)),
        "edges": int(len(edges)),
        "datasets": sorted(frame["dataset"].unique().tolist()),
    }

    max_indegree = 0
    max_outdegree = 0
    divisions = 0
    for dataset, group in edges.groupby("dataset"):
        known = set(nodes[nodes["dataset"] == dataset]["node_id"].tolist())
        dangling = (~group["source_id"].isin(known)) | (~group["target_id"].isin(known))
        if dangling.any():
            problems.append(f"{dataset}: {int(dangling.sum())} edges with a missing endpoint")
        indegree = group["target_id"].value_counts()
        outdegree = group["source_id"].value_counts()
        if len(indegree):
            max_indegree = max(max_indegree, int(indegree.max()))
        if len(outdegree):
            max_outdegree = max(max_outdegree, int(outdegree.max()))
            divisions += int((outdegree >= 2).sum())

    stats["max_indegree"] = max_indegree
    stats["max_outdegree"] = max_outdegree
    stats["division_like_sources"] = divisions
    if max_indegree > 1:
        problems.append(f"Max indegree {max_indegree} exceeds 1")
    if max_outdegree > 2:
        problems.append(f"Max outdegree {max_outdegree} exceeds 2")

    if problems:
        raise ValueError("Submission harness failed:\n  " + "\n  ".join(problems))
    return stats
