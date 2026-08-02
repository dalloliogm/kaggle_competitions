import ast
import json
from pathlib import Path

import numpy as np
from scipy.optimize import linear_sum_assignment


NOTEBOOK = Path(__file__).parents[1] / "notebooks/biohub-exp165-tiled-dense-relink.ipynb"
notebook = json.loads(NOTEBOOK.read_text())
source = next(
    "".join(cell["source"]) if isinstance(cell["source"], list) else cell["source"]
    for cell in notebook["cells"]
    if cell.get("id") == "57bca15b"
)
tree = ast.parse(source)
function = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == "tiled_motion_relink_edges")

TILED_RELINK_DATASET = "dense"
TILED_RELINK_TILE_UM = 10.0
TILED_RELINK_OVERLAP_UM = 3.0
MOTION_RELINK_TIGHT_UM = 3.0
MOTION_RELINK_RELAXED_UM = 5.0
MOTION_RELINK_VELOCITY_WEIGHT = 0.5
MOTION_RELINK_LEARNED_BONUS = 1.0


def _position_um(node):
    return np.array([node["z"], node["y"], node["x"]], dtype=np.float64)


namespace = globals()
exec(compile(ast.Module(body=[function], type_ignores=[]), str(NOTEBOOK), "exec"), namespace)

nodes = {
    1: {"t": 0, "z": 0.0, "y": 0.0, "x": 1.0},
    2: {"t": 0, "z": 0.0, "y": 0.0, "x": 21.0},
    3: {"t": 1, "z": 0.0, "y": 0.0, "x": 2.0},
    4: {"t": 1, "z": 0.0, "y": 0.0, "x": 22.0},
}
stats = {
    "motion_relink_tight_edges": 0,
    "motion_relink_relaxed_edges": 0,
    "tiled_relink_frames": 0,
    "tiled_relink_candidate_edges": 0,
    "tiled_relink_selected_edges": 0,
    "motion_relink_edges": 0,
    "motion_relink_frames": 0,
}
edges = tiled_motion_relink_edges(nodes, stats, {})
pairs = {(edge["source_id"], edge["target_id"]) for edge in edges}
assert pairs == {(1, 3), (2, 4)}, pairs
assert stats["tiled_relink_frames"] == 1, stats
assert stats["tiled_relink_selected_edges"] == 2, stats
assert stats["tiled_relink_candidate_edges"] >= 2, stats
print("synthetic tiled relink passed", stats)
