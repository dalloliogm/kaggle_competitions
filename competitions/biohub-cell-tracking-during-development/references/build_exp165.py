import json
from pathlib import Path


ROOT = Path("competitions/biohub-cell-tracking-during-development")
SOURCE = ROOT / "notebooks/biohub-exp148-adaptive-edge-fusion.ipynb"
TARGET = ROOT / "notebooks/biohub-exp165-tiled-dense-relink.ipynb"


def text(cell):
    source = cell.get("source", "")
    return "".join(source) if isinstance(source, list) else source


def replace_source(cell, source):
    cell["source"] = source
    if cell.get("cell_type") == "code":
        cell["execution_count"] = None
        cell["outputs"] = []


notebook = json.loads(SOURCE.read_text())

tiled_function = r'''

def tiled_motion_relink_edges(
    nodes_by_id: dict[int, dict[str, object]],
    stats: dict[str, int],
    learned_edge_probs: dict[tuple[int, int], float] | None = None,
) -> list[dict[str, object]]:
    """Run local Hungarian assignments in overlapping physical XY tiles."""
    learned_edge_probs = learned_edge_probs or {}

    def learned_prob(source_id: int, target_id: int) -> float:
        value = learned_edge_probs.get((source_id, target_id), 0.0)
        try:
            value = float(value)
        except (TypeError, ValueError):
            return 0.0
        if not np.isfinite(value):
            return 0.0
        if value < 0.0 or value > 1.0:
            value = 1.0 / (1.0 + math.exp(-max(-20.0, min(20.0, value))))
        return float(np.clip(value, 0.0, 1.0))

    ids_by_t: dict[int, list[int]] = {}
    for node_id, node in nodes_by_id.items():
        ids_by_t.setdefault(int(node["t"]), []).append(node_id)
    for ids in ids_by_t.values():
        ids.sort()
    position_um = {node_id: _position_um(node) for node_id, node in nodes_by_id.items()}
    predecessor_position_um: dict[int, np.ndarray] = {}
    selected_edges: list[dict[str, object]] = []
    tile_size = float(TILED_RELINK_TILE_UM)
    tile_overlap = float(np.clip(TILED_RELINK_OVERLAP_UM, 0.0, tile_size - 1e-3))
    tile_stride = max(tile_size - tile_overlap, 1.0)

    def tile_starts(low: float, high: float) -> list[float]:
        if high - low <= tile_size:
            return [low]
        starts: list[float] = []
        current = low
        while current + tile_size < high:
            starts.append(current)
            current += tile_stride
        starts.append(max(low, high - tile_size))
        return sorted(set(round(value, 6) for value in starts))

    def local_candidates(source_ids: list[int], target_ids: list[int], gate_um: float):
        if not source_ids or not target_ids:
            return []
        big = gate_um * 1000.0 + 1.0
        cost = np.full((len(source_ids), len(target_ids)), big, dtype=np.float64)
        raw_dist = np.full_like(cost, np.inf)
        motion_dist = np.full_like(cost, np.inf)
        prob_matrix = np.zeros_like(cost)
        for row, source_id in enumerate(source_ids):
            source_pos = position_um[source_id]
            previous = predecessor_position_um.get(source_id)
            predicted = source_pos if previous is None else source_pos + MOTION_RELINK_VELOCITY_WEIGHT * (source_pos - previous)
            for col, target_id in enumerate(target_ids):
                target_pos = position_um[target_id]
                raw = float(np.linalg.norm(target_pos - source_pos))
                if raw > gate_um:
                    continue
                motion = float(np.linalg.norm(target_pos - predicted))
                probability = learned_prob(source_id, target_id)
                raw_dist[row, col] = raw
                motion_dist[row, col] = motion
                prob_matrix[row, col] = probability
                cost[row, col] = motion + 0.05 * raw - MOTION_RELINK_LEARNED_BONUS * probability
        rows, cols = linear_sum_assignment(cost)
        result = []
        for row, col in zip(rows, cols):
            if cost[row, col] >= big:
                continue
            result.append((
                float(cost[row, col]),
                source_ids[int(row)],
                target_ids[int(col)],
                float(raw_dist[row, col]),
                float(motion_dist[row, col]),
                float(prob_matrix[row, col]),
            ))
        return result

    times = sorted(ids_by_t)
    for t in times:
        source_ids = ids_by_t.get(t, [])
        target_ids = ids_by_t.get(t + 1, [])
        if not source_ids or not target_ids:
            continue
        y_values = [position_um[node_id][1] for node_id in source_ids + target_ids]
        x_values = [position_um[node_id][2] for node_id in source_ids + target_ids]
        starts_y = tile_starts(min(y_values), max(y_values))
        starts_x = tile_starts(min(x_values), max(x_values))
        unmatched_sources = set(source_ids)
        unmatched_targets = set(target_ids)
        frame_matches: list[tuple[int, int, float, float, str, float]] = []
        for pass_name, gate_um in (("tight", MOTION_RELINK_TIGHT_UM), ("relaxed", MOTION_RELINK_RELAXED_UM)):
            candidates = []
            for y0 in starts_y:
                for x0 in starts_x:
                    y1 = y0 + tile_size
                    x1 = x0 + tile_size
                    tile_sources = [
                        node_id for node_id in source_ids
                        if node_id in unmatched_sources and y0 <= position_um[node_id][1] <= y1 and x0 <= position_um[node_id][2] <= x1
                    ]
                    tile_targets = [
                        node_id for node_id in target_ids
                        if node_id in unmatched_targets and y0 <= position_um[node_id][1] <= y1 and x0 <= position_um[node_id][2] <= x1
                    ]
                    local = local_candidates(tile_sources, tile_targets, gate_um)
                    candidates.extend((item[0], item[1], item[2], item[3], item[4], item[5], pass_name) for item in local)
            stats["tiled_relink_candidate_edges"] += len(candidates)
            candidates.sort(key=lambda item: (item[0], item[1], item[2]))
            for _, source_id, target_id, raw, motion, probability, candidate_pass in candidates:
                if source_id not in unmatched_sources or target_id not in unmatched_targets:
                    continue
                unmatched_sources.remove(source_id)
                unmatched_targets.remove(target_id)
                frame_matches.append((source_id, target_id, raw, motion, candidate_pass, probability))
                if candidate_pass == "tight":
                    stats["motion_relink_tight_edges"] += 1
                else:
                    stats["motion_relink_relaxed_edges"] += 1
        for source_id, target_id, raw, motion, pass_name, probability in frame_matches:
            selected_edges.append({
                "source_id": source_id,
                "target_id": target_id,
                "edge_prob": probability,
                "distance_um": raw,
                "motion_distance_um": motion,
                "motion_relinked": 1,
                "motion_pass": pass_name,
            })
            predecessor_position_um[target_id] = position_um[source_id]
        stats["tiled_relink_frames"] += 1

    stats["tiled_relink_selected_edges"] = len(selected_edges)
    stats["motion_relink_edges"] = len(selected_edges)
    stats["motion_relink_frames"] = stats["tiled_relink_frames"]
    return selected_edges
'''

for cell in notebook["cells"]:
    source = text(cell)
    cell_id = cell.get("id")
    if cell_id == "76ebb5db":
        replace_source(cell, """# Biohub Exp165: Tiled Dense-Frame Relinking

Exp165 keeps Exp148 fixed everywhere except the densest test movie,
`6bba_05db0fb1`. Its motion relinker performs Hungarian assignments inside
overlapping physical XY tiles, then reconciles the local candidates globally
with one-to-one greedy selection. The goal is to reduce assignment steals in
crowded frames while preserving the incumbent graph on sparse movies.

This is a diagnostic candidate. It is eligible for submission only if the
dense movie changes meaningfully, all other movies remain unchanged, and the
exact output validator passes.
""")
    elif cell_id == "ff65b520":
        source = source.replace(
            "BIOHUB_PRESET = 'dual_seed_near_balanced_center_confirmed_synthetic_gap'",
            "BIOHUB_PRESET = 'dual_seed_tiled_dense_relink'",
        )
        source = source.replace(
            "BIOHUB_SCORE_AXIS = 'fixed 0.475 shared detections with confidence-adaptive two-seed edge fusion'",
            "BIOHUB_SCORE_AXIS = 'overlapping local Hungarian relinking on dense movie only'",
        )
        source = source.replace(
            'os.environ["BIOHUB_MOTION_RELINK_LEARNED_BONUS"] = \'1.0\'',
            '''os.environ["BIOHUB_MOTION_RELINK_LEARNED_BONUS"] = '1.0'
os.environ["BIOHUB_TILED_RELINK_DATASET"] = "6bba_05db0fb1"
os.environ["BIOHUB_TILED_RELINK_TILE_UM"] = "48.0"
os.environ["BIOHUB_TILED_RELINK_OVERLAP_UM"] = "12.0"''',
        )
        replace_source(cell, source)
    elif cell_id == "22d9fcd5":
        source = source.replace(
            'EXPERIMENT_TAG = "exp148_adaptive_edge_fusion"',
            'EXPERIMENT_TAG = "exp165_tiled_dense_relink"',
        )
        source = source.replace(
            'MOTION_RELINK_MAX_FRAME_NODES = int(os.environ.get("BIOHUB_MOTION_RELINK_MAX_FRAME_NODES", "2600"))',
            '''MOTION_RELINK_MAX_FRAME_NODES = int(os.environ.get("BIOHUB_MOTION_RELINK_MAX_FRAME_NODES", "2600"))
TILED_RELINK_DATASET = os.environ.get("BIOHUB_TILED_RELINK_DATASET", "").strip()
TILED_RELINK_TILE_UM = float(os.environ.get("BIOHUB_TILED_RELINK_TILE_UM", "48.0"))
TILED_RELINK_OVERLAP_UM = float(os.environ.get("BIOHUB_TILED_RELINK_OVERLAP_UM", "12.0"))''',
        )
        source = source.replace(
            '    "motion_relink_max_frame_nodes": MOTION_RELINK_MAX_FRAME_NODES,',
            '''    "motion_relink_max_frame_nodes": MOTION_RELINK_MAX_FRAME_NODES,
    "tiled_relink_dataset": TILED_RELINK_DATASET,
    "tiled_relink_tile_um": TILED_RELINK_TILE_UM,
    "tiled_relink_overlap_um": TILED_RELINK_OVERLAP_UM,''',
        )
        replace_source(cell, source)
    elif cell_id == "57bca15b":
        source = source.replace(
            'def motion_relink_edges(\n    nodes_by_id: dict[int, dict[str, object]],\n    stats: dict[str, int],\n    learned_edge_probs: dict[tuple[int, int], float] | None = None,\n)',
            'def motion_relink_edges(\n    nodes_by_id: dict[int, dict[str, object]],\n    stats: dict[str, int],\n    learned_edge_probs: dict[tuple[int, int], float] | None = None,\n    dataset: str | None = None,\n)',
        )
        source = source.replace(
            'def motion_relink_edges(\n',
            tiled_function + '\n\ndef motion_relink_edges(\n',
            1,
        )
        motion_marker = 'def motion_relink_edges(\n'
        motion_head, motion_tail = source.split(motion_marker, 1)
        motion_tail = motion_tail.replace(
            '    learned_edge_probs = learned_edge_probs or {}\n\n    def learned_prob(source_id: int, target_id: int) -> float:',
            '''    learned_edge_probs = learned_edge_probs or {}
    if TILED_RELINK_DATASET and dataset == TILED_RELINK_DATASET:
        return tiled_motion_relink_edges(nodes_by_id, stats, learned_edge_probs)

    def learned_prob(source_id: int, target_id: int) -> float:''',
            1,
        )
        source = motion_head + motion_marker + motion_tail
        source = source.replace(
            '        "motion_relink_skipped_large_frame": 0,',
            '''        "motion_relink_skipped_large_frame": 0,
        "tiled_relink_frames": 0,
        "tiled_relink_candidate_edges": 0,
        "tiled_relink_selected_edges": 0,''',
        )
        source = source.replace(
            'motion_edges = motion_relink_edges(nodes_by_id, stats, learned_edge_probs)',
            'motion_edges = motion_relink_edges(nodes_by_id, stats, learned_edge_probs, dataset=dataset)',
        )
        replace_source(cell, source)

for cell in notebook["cells"]:
    if cell.get("cell_type") == "code":
        cell["execution_count"] = None
        cell["outputs"] = []

TARGET.write_text(json.dumps(notebook, indent=1, ensure_ascii=False) + "\n")
print(TARGET)
