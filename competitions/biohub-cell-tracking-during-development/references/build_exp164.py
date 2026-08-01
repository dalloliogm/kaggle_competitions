import json
from pathlib import Path


ROOT = Path("competitions/biohub-cell-tracking-during-development")
SOURCE = ROOT / "notebooks/biohub-exp148-adaptive-edge-fusion.ipynb"
TARGET = ROOT / "notebooks/biohub-exp164-bidirectional-crossing-repair.ipynb"


def cell_source(cell):
    source = cell.get("source", "")
    return "".join(source) if isinstance(source, list) else source


def set_source(cell, source):
    cell["source"] = source
    cell["execution_count"] = None if cell.get("cell_type") == "code" else cell.get("execution_count")
    if cell.get("cell_type") == "code":
        cell["outputs"] = []


notebook = json.loads(SOURCE.read_text())

for cell in notebook["cells"]:
    source = cell_source(cell)
    if cell.get("id") == "76ebb5db":
        set_source(
            cell,
            """# Biohub Exp164: Bidirectional Crossing Repair

This experiment keeps Exp148's detector, adaptive two-seed edge fusion, gap handling,
division policy, and coordinate smoothing fixed. It changes only a subset of ordinary
one-to-one links after motion relinking.

The frame-pair Hungarian tracker uses the past to predict where a cell should move.
Exp164 adds future evidence: when two tracks can exchange their next-frame assignments,
it accepts the exchange only if both resulting four-frame paths are substantially
smoother. This targets identity swaps at crossings without changing node detections or
division counts by design.

Calibration v2 deliberately widens the activation gate to `0.3 um` improvement and
`0.95` relative cost. The repair must still change at least 20 and at most 2,000 edges,
retain exact submission invariants, and produce an output distinct from Exp148. This is
still diagnostic; no leaderboard submission is implied by the run.
""",
        )
        continue

    if cell.get("id") == "ff65b520":
        source = source.replace(
            "BIOHUB_PRESET = 'dual_seed_near_balanced_center_confirmed_synthetic_gap'\nBIOHUB_SCORE_AXIS = 'fixed 0.475 shared detections with confidence-adaptive two-seed edge fusion'",
            "BIOHUB_PRESET = 'dual_seed_bidirectional_crossing_repair'\nBIOHUB_SCORE_AXIS = 'four-frame trajectory evidence for ambiguous identity crossings'",
        )
        source = source.replace(
            "os.environ[\"BIOHUB_MOTION_RELINK_LEARNED_BONUS\"] = '1.0'",
            '''os.environ["BIOHUB_MOTION_RELINK_LEARNED_BONUS"] = '1.0'
os.environ["BIOHUB_BIDIRECTIONAL_SWAP_REPAIR"] = "1"
os.environ["BIOHUB_BIDIRECTIONAL_SWAP_GATE_UM"] = "6.0"
os.environ["BIOHUB_BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM"] = "0.3"
os.environ["BIOHUB_BIDIRECTIONAL_SWAP_MAX_COST_RATIO"] = "0.95"
os.environ["BIOHUB_BIDIRECTIONAL_SWAP_LEARNED_BONUS"] = "0.50"''',
        )
        set_source(cell, source)
        continue

    if cell.get("id") == "22d9fcd5":
        source = source.replace(
            'EXPERIMENT_TAG = "exp148_adaptive_edge_fusion"',
            'EXPERIMENT_TAG = "exp164_bidirectional_crossing_repair_v2"',
        )
        source = source.replace(
            'MOTION_RELINK_MAX_FRAME_NODES = int(os.environ.get("BIOHUB_MOTION_RELINK_MAX_FRAME_NODES", "2600"))',
            '''MOTION_RELINK_MAX_FRAME_NODES = int(os.environ.get("BIOHUB_MOTION_RELINK_MAX_FRAME_NODES", "2600"))
BIDIRECTIONAL_SWAP_REPAIR = os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_REPAIR", "0") != "0"
BIDIRECTIONAL_SWAP_GATE_UM = float(os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_GATE_UM", "6.0"))
BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM = float(os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM", "1.0"))
BIDIRECTIONAL_SWAP_MAX_COST_RATIO = float(os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_MAX_COST_RATIO", "0.80"))
BIDIRECTIONAL_SWAP_LEARNED_BONUS = float(os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_LEARNED_BONUS", "0.50"))''',
        )
        source = source.replace(
            '    "motion_relink_max_frame_nodes": MOTION_RELINK_MAX_FRAME_NODES,',
            '''    "motion_relink_max_frame_nodes": MOTION_RELINK_MAX_FRAME_NODES,
    "bidirectional_swap_repair": BIDIRECTIONAL_SWAP_REPAIR,
    "bidirectional_swap_gate_um": BIDIRECTIONAL_SWAP_GATE_UM,
    "bidirectional_swap_min_improvement_um": BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM,
    "bidirectional_swap_max_cost_ratio": BIDIRECTIONAL_SWAP_MAX_COST_RATIO,
    "bidirectional_swap_learned_bonus": BIDIRECTIONAL_SWAP_LEARNED_BONUS,''',
        )
        set_source(cell, source)
        continue

    if cell.get("id") != "57bca15b":
        continue

    source = source.replace(
        'MOTION_RELINK_MAX_FRAME_NODES = int(os.environ.get("BIOHUB_MOTION_RELINK_MAX_FRAME_NODES", "2600"))',
        '''MOTION_RELINK_MAX_FRAME_NODES = int(os.environ.get("BIOHUB_MOTION_RELINK_MAX_FRAME_NODES", "2600"))
BIDIRECTIONAL_SWAP_REPAIR = os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_REPAIR", "0") != "0"
BIDIRECTIONAL_SWAP_GATE_UM = float(os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_GATE_UM", "6.0"))
BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM = float(os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM", "1.0"))
BIDIRECTIONAL_SWAP_MAX_COST_RATIO = float(os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_MAX_COST_RATIO", "0.80"))
BIDIRECTIONAL_SWAP_LEARNED_BONUS = float(os.environ.get("BIOHUB_BIDIRECTIONAL_SWAP_LEARNED_BONUS", "0.50"))''',
    )
    source = source.replace(
        '    "motion_relink_max_frame_nodes": MOTION_RELINK_MAX_FRAME_NODES,',
        '''    "motion_relink_max_frame_nodes": MOTION_RELINK_MAX_FRAME_NODES,
    "bidirectional_swap_repair": BIDIRECTIONAL_SWAP_REPAIR,
    "bidirectional_swap_gate_um": BIDIRECTIONAL_SWAP_GATE_UM,
    "bidirectional_swap_min_improvement_um": BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM,
    "bidirectional_swap_max_cost_ratio": BIDIRECTIONAL_SWAP_MAX_COST_RATIO,
    "bidirectional_swap_learned_bonus": BIDIRECTIONAL_SWAP_LEARNED_BONUS,''',
    )

    marker = "\ndef close_single_frame_gaps(\n"
    function = r'''

def bidirectional_crossing_repair(
    nodes_by_id: dict[int, dict[str, object]],
    edges: list[dict[str, object]],
    stats: dict[str, int],
    learned_edge_probs: dict[tuple[int, int], float] | None = None,
) -> list[dict[str, object]]:
    'Swap two assignments only when past and future motion jointly prefer it.'
    if not BIDIRECTIONAL_SWAP_REPAIR or len(edges) < 2:
        return edges

    learned_edge_probs = learned_edge_probs or {}
    position_um = {node_id: _position_um(node) for node_id, node in nodes_by_id.items()}
    incoming: dict[int, int] = {}
    outgoing: dict[int, int] = {}
    edge_indices_by_t: dict[int, list[int]] = {}
    for edge_index, edge in enumerate(edges):
        source_id = int(edge["source_id"])
        target_id = int(edge["target_id"])
        source = nodes_by_id.get(source_id)
        target = nodes_by_id.get(target_id)
        if source is None or target is None or int(target["t"]) != int(source["t"]) + 1:
            continue
        if source_id in outgoing or target_id in incoming:
            # The motion graph should already be one-to-one. Fail closed if it is not.
            return edges
        outgoing[source_id] = target_id
        incoming[target_id] = source_id
        edge_indices_by_t.setdefault(int(source["t"]), []).append(edge_index)

    def probability(source_id: int, target_id: int) -> float:
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

    def acceleration(previous_id: int, source_id: int, target_id: int, following_id: int) -> float:
        previous = position_um[previous_id]
        source = position_um[source_id]
        target = position_um[target_id]
        following = position_um[following_id]
        before = float(np.linalg.norm((target - source) - (source - previous)))
        after = float(np.linalg.norm((following - target) - (target - source)))
        return before + after

    proposals: list[tuple[float, float, int, int, tuple[int, ...]]] = []
    gate = BIDIRECTIONAL_SWAP_GATE_UM
    for _, frame_edge_indices in sorted(edge_indices_by_t.items()):
        if len(frame_edge_indices) < 2:
            continue
        target_positions = np.stack([
            position_um[int(edges[edge_index]["target_id"])] for edge_index in frame_edge_indices
        ])
        target_tree = cKDTree(target_positions)
        local_index_by_edge = {edge_index: local_index for local_index, edge_index in enumerate(frame_edge_indices)}

        for edge_i in frame_edge_indices:
            source_i = int(edges[edge_i]["source_id"])
            target_i = int(edges[edge_i]["target_id"])
            previous_i = incoming.get(source_i)
            following_i = outgoing.get(target_i)
            if previous_i is None or following_i is None:
                continue
            alternative_locals = target_tree.query_ball_point(position_um[source_i], r=gate)
            for local_j in alternative_locals:
                edge_j = frame_edge_indices[int(local_j)]
                if edge_j <= edge_i:
                    continue
                source_j = int(edges[edge_j]["source_id"])
                target_j = int(edges[edge_j]["target_id"])
                previous_j = incoming.get(source_j)
                following_j = outgoing.get(target_j)
                if previous_j is None or following_j is None:
                    continue
                stats["bidirectional_swap_pairs_examined"] += 1
                if float(np.linalg.norm(position_um[target_i] - position_um[source_j])) > gate:
                    continue
                involved = (previous_i, source_i, target_i, following_i, previous_j, source_j, target_j, following_j)
                if len(set(involved)) != len(involved):
                    continue

                current_acceleration = (
                    acceleration(previous_i, source_i, target_i, following_i)
                    + acceleration(previous_j, source_j, target_j, following_j)
                )
                swapped_acceleration = (
                    acceleration(previous_i, source_i, target_j, following_j)
                    + acceleration(previous_j, source_j, target_i, following_i)
                )
                current_distance = (
                    float(np.linalg.norm(position_um[target_i] - position_um[source_i]))
                    + float(np.linalg.norm(position_um[target_j] - position_um[source_j]))
                )
                swapped_distance = (
                    float(np.linalg.norm(position_um[target_j] - position_um[source_i]))
                    + float(np.linalg.norm(position_um[target_i] - position_um[source_j]))
                )
                current_probability = probability(source_i, target_i) + probability(source_j, target_j)
                swapped_probability = probability(source_i, target_j) + probability(source_j, target_i)
                current_cost = (
                    current_acceleration + 0.05 * current_distance
                    - BIDIRECTIONAL_SWAP_LEARNED_BONUS * current_probability
                )
                swapped_cost = (
                    swapped_acceleration + 0.05 * swapped_distance
                    - BIDIRECTIONAL_SWAP_LEARNED_BONUS * swapped_probability
                )
                improvement = current_cost - swapped_cost
                ratio = swapped_cost / max(current_cost, 1e-9)
                stats["bidirectional_swap_pairs_feasible"] += 1
                if improvement < BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM:
                    continue
                if ratio > BIDIRECTIONAL_SWAP_MAX_COST_RATIO:
                    continue
                proposals.append((improvement, ratio, edge_i, edge_j, involved))

    repaired = [dict(edge) for edge in edges]
    locked_nodes: set[int] = set()
    for improvement, _, edge_i, edge_j, involved in sorted(proposals, key=lambda item: (-item[0], item[1])):
        if any(node_id in locked_nodes for node_id in involved):
            continue
        source_i = int(edges[edge_i]["source_id"])
        target_i = int(edges[edge_i]["target_id"])
        source_j = int(edges[edge_j]["source_id"])
        target_j = int(edges[edge_j]["target_id"])
        previous_i = incoming[source_i]
        previous_j = incoming[source_j]

        for edge_index, source_id, target_id, previous_id in (
            (edge_i, source_i, target_j, previous_i),
            (edge_j, source_j, target_i, previous_j),
        ):
            source_position = position_um[source_id]
            previous_position = position_um[previous_id]
            target_position = position_um[target_id]
            predicted = source_position + MOTION_RELINK_VELOCITY_WEIGHT * (source_position - previous_position)
            repaired[edge_index].update({
                "source_id": source_id,
                "target_id": target_id,
                "edge_prob": probability(source_id, target_id),
                "distance_um": float(np.linalg.norm(target_position - source_position)),
                "motion_distance_um": float(np.linalg.norm(target_position - predicted)),
                "motion_relinked": 1,
                "motion_pass": "bidirectional_swap",
            })
        locked_nodes.update(involved)
        stats["bidirectional_swaps_accepted"] += 1
        stats["bidirectional_edges_changed"] += 2
        stats["bidirectional_improvement_milli_sum"] += int(round(improvement * 1000.0))

    stats["bidirectional_swap_proposals"] = len(proposals)
    return repaired
'''
    if marker not in source:
        raise RuntimeError("Could not find close_single_frame_gaps insertion point")
    source = source.replace(marker, function + marker, 1)

    source = source.replace(
        '        "motion_relink_skipped_large_frame": 0,',
        '''        "motion_relink_skipped_large_frame": 0,
        "bidirectional_swap_pairs_examined": 0,
        "bidirectional_swap_pairs_feasible": 0,
        "bidirectional_swap_proposals": 0,
        "bidirectional_swaps_accepted": 0,
        "bidirectional_edges_changed": 0,
        "bidirectional_improvement_milli_sum": 0,''',
    )
    source = source.replace(
        '''        motion_edges = motion_relink_edges(nodes_by_id, stats, learned_edge_probs)
        if motion_edges:''',
        '''        motion_edges = motion_relink_edges(nodes_by_id, stats, learned_edge_probs)
        motion_edges = bidirectional_crossing_repair(nodes_by_id, motion_edges, stats, learned_edge_probs)
        if motion_edges:''',
    )
    set_source(cell, source)

for cell in notebook["cells"]:
    if cell.get("cell_type") == "code":
        cell["execution_count"] = None
        cell["outputs"] = []

TARGET.write_text(json.dumps(notebook, indent=1, ensure_ascii=False) + "\n")
print(TARGET)
