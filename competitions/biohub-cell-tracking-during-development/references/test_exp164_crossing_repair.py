import ast
import json
import math
from pathlib import Path

import numpy as np
from scipy.spatial import cKDTree


NOTEBOOK = Path(__file__).parents[1] / "notebooks/biohub-exp164-bidirectional-crossing-repair.ipynb"
notebook = json.loads(NOTEBOOK.read_text())
source = next(
    "".join(cell["source"]) if isinstance(cell["source"], list) else cell["source"]
    for cell in notebook["cells"]
    if cell.get("id") == "57bca15b"
)
tree = ast.parse(source)
function = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == "bidirectional_crossing_repair")

BIDIRECTIONAL_SWAP_REPAIR = True
BIDIRECTIONAL_SWAP_GATE_UM = 6.0
BIDIRECTIONAL_SWAP_MIN_IMPROVEMENT_UM = 1.0
BIDIRECTIONAL_SWAP_MAX_COST_RATIO = 0.80
BIDIRECTIONAL_SWAP_LEARNED_BONUS = 0.50
MOTION_RELINK_VELOCITY_WEIGHT = 0.5


def _position_um(node):
    return np.array([node["z"], node["y"], node["x"]], dtype=np.float64)


namespace = globals()
exec(compile(ast.Module(body=[function], type_ignores=[]), str(NOTEBOOK), "exec"), namespace)

xs = {1: -2.0, 2: 2.0, 3: -1.0, 4: 1.0, 5: -0.2, 6: 0.2, 7: -1.2, 8: 1.2}
times = {1: 0, 2: 0, 3: 1, 4: 1, 5: 2, 6: 2, 7: 3, 8: 3}
nodes = {node_id: {"t": times[node_id], "z": 0.0, "y": 0.0, "x": x} for node_id, x in xs.items()}
edges = [
    {"source_id": 1, "target_id": 3},
    {"source_id": 2, "target_id": 4},
    {"source_id": 3, "target_id": 5},
    {"source_id": 4, "target_id": 6},
    {"source_id": 5, "target_id": 7},
    {"source_id": 6, "target_id": 8},
]
stats = {
    "bidirectional_swap_pairs_examined": 0,
    "bidirectional_swap_pairs_feasible": 0,
    "bidirectional_swap_proposals": 0,
    "bidirectional_swaps_accepted": 0,
    "bidirectional_edges_changed": 0,
    "bidirectional_improvement_milli_sum": 0,
    "bidirectional_best_improvement_milli": -1000000000,
    "bidirectional_best_ratio_milli": 1000000000,
}
repaired = bidirectional_crossing_repair(nodes, edges, stats)
edge_pairs = {(edge["source_id"], edge["target_id"]) for edge in repaired}
assert (3, 6) in edge_pairs and (4, 5) in edge_pairs, edge_pairs
assert (3, 5) not in edge_pairs and (4, 6) not in edge_pairs, edge_pairs
assert stats["bidirectional_swaps_accepted"] == 1, stats
assert stats["bidirectional_edges_changed"] == 2, stats
print("synthetic crossing repair passed", stats)
