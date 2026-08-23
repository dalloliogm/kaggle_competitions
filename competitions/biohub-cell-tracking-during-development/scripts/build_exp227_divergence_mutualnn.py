#!/usr/bin/env python3
"""Port the divergence + mutual-NN safe-division filters, then widen the geometry.

exp223/exp224 widened the safe-division geometry to the public 0.923 values
(12.0/15.0/10.0) and BOTH failed their own clean-graph audit:

    maximum_outdegree = 3     divisions = 452 (signature 311)

A cell dividing into three. The cause was porting three config keys without the
machinery that makes them survivable. The source recipe says so in its own
annotation, which the 08-22 scan quoted only half of:

    "The earlier 7.0 test (pre-divergence-check) added noise that pure geometry
     couldn't filter out; divergence + mutual-NN are active now and should do
     that filtering instead."

Verified: `divergence` and `mutual_nn` appear 12 and 11 times in the 0.923
notebook and ZERO times in ours. They are Python, not env flags, which is why a
35-key config diff showed only three differences and read as a complete recipe.

Two filters, both pure geometry over the graph we already build - no model, no
extra inference:

1. **Mutual nearest orphan.** For each existing child, KD-tree its nearest
   unclaimed candidate in the frame; only that candidate may become the sister.
   This collapses the candidate set to at most one per parent, which is exactly
   what stops a widened radius from attaching several children - the
   out-degree-3 failure.

2. **Forward divergence.** Both putative daughters must each have exactly one
   successor at t+2, and those grandchildren must have moved apart by more than
   `sister_dist + SAFE_DIV_DIVERGE_UM`. Real daughters separate; coincidental
   pairs do not.

Both run BEFORE the DeepCenter safe-division veto, so on the exp220 base the
full chain becomes: geometry gates -> mutual-NN -> divergence -> DeepCenter veto.

Built on exp220 (0.916) so the veto is present, and the widened geometry is
applied in the same run - widening without the filters is already measured as
invalid, so they are not separable into two experiments.
"""

from __future__ import annotations

import json
from pathlib import Path

NOTEBOOKS = Path(__file__).resolve().parent.parent / "notebooks"
BASE = NOTEBOOKS / "biohub-exp220-deepcenter-best-safediv-veto.ipynb"
BASE_METADATA = NOTEBOOKS / "biohub-exp220-deepcenter-best-safediv-veto.kernel-metadata.json"
SLUG = "biohub-exp227-divergence-mutualnn-wide"
TITLE = "Biohub Exp227 Divergence Mutualnn Wide"

CONFIG_ANCHOR = 'SAFE_DIV_GLOBAL_FRAC_CAP = float(os.environ.get("BIOHUB_SAFE_DIV_GLOBAL_FRAC_CAP", "0.004"))'
CONFIG_ADDED = '''
SAFE_DIV_DIVERGE_UM = float(os.environ.get("BIOHUB_SAFE_DIV_DIVERGE_UM", "1.5"))
SAFE_DIV_REQUIRE_DIVERGENCE = os.environ.get("BIOHUB_SAFE_DIV_REQUIRE_DIVERGENCE", "1") != "0"
SAFE_DIV_REQUIRE_MUTUAL_NN = os.environ.get("BIOHUB_SAFE_DIV_REQUIRE_MUTUAL_NN", "1") != "0"'''

# Anchor 1: after the existing-child distance gate, before the candidate loop.
TREE_ANCHOR = """            child_dist = edge_distance_um(source, existing_child)
            if child_dist > SAFE_DIV_EXISTING_CHILD_MAX_UM:
                continue
            for candidate_id in candidate_ids:"""
TREE_ADDED = """            child_dist = edge_distance_um(source, existing_child)
            if child_dist > SAFE_DIV_EXISTING_CHILD_MAX_UM:
                continue

            # Mutual nearest orphan: the existing child's nearest unclaimed
            # neighbour this frame is the ONLY admissible sister. Computed once
            # per existing child rather than once per candidate.
            mutual_nn_id = None
            if SAFE_DIV_REQUIRE_MUTUAL_NN and _safe_div_candidate_tree is not None:
                _, _nn_idx = _safe_div_candidate_tree.query(_position_um(existing_child))
                mutual_nn_id = candidate_ids[int(_nn_idx)]

            for candidate_id in candidate_ids:"""

# Anchor 2: after the sister gate, before the DeepCenter veto.
FILTER_ANCHOR = """                sister_dist = edge_distance_um(existing_child, candidate)
                if sister_dist > SAFE_DIV_SISTER_MAX_UM:
                    continue
                if DEEPCENTER_SAFE_DIV_VETO and not deepcenter_accept_repair_point("""
FILTER_ADDED = """                sister_dist = edge_distance_um(existing_child, candidate)
                if sister_dist > SAFE_DIV_SISTER_MAX_UM:
                    continue

                if SAFE_DIV_REQUIRE_MUTUAL_NN and candidate_id != mutual_nn_id:
                    stats["safe_division_mutual_nn_rejected"] = (
                        stats.get("safe_division_mutual_nn_rejected", 0) + 1
                    )
                    continue

                # Forward divergence: both putative daughters need exactly one
                # successor at t+2, and those grandchildren must have separated
                # by more than the sisters are apart now.
                if SAFE_DIV_REQUIRE_DIVERGENCE:
                    _c1_succ = out_by_source.get(existing_child_id, [])
                    _q_succ = out_by_source.get(candidate_id, [])
                    if len(_c1_succ) != 1 or len(_q_succ) != 1:
                        stats["safe_division_divergence_rejected"] = (
                            stats.get("safe_division_divergence_rejected", 0) + 1
                        )
                        continue
                    _c1_grandchild = nodes_by_id.get(int(_c1_succ[0]["target_id"]))
                    _q_grandchild = nodes_by_id.get(int(_q_succ[0]["target_id"]))
                    if (
                        _c1_grandchild is None or _q_grandchild is None
                        or int(_c1_grandchild["t"]) != t + 2
                        or int(_q_grandchild["t"]) != t + 2
                    ):
                        stats["safe_division_divergence_rejected"] = (
                            stats.get("safe_division_divergence_rejected", 0) + 1
                        )
                        continue
                    if (
                        edge_distance_um(_c1_grandchild, _q_grandchild) - sister_dist
                        < SAFE_DIV_DIVERGE_UM
                    ):
                        stats["safe_division_divergence_rejected"] = (
                            stats.get("safe_division_divergence_rejected", 0) + 1
                        )
                        continue

                if DEEPCENTER_SAFE_DIV_VETO and not deepcenter_accept_repair_point("""

# Anchor 3: build the KD-tree once per frame, where candidate_ids is settled.
BUILD_ANCHOR = """        frame_cap = max(1, int(round(len(source_ids) * SAFE_DIV_FRAME_FRAC_CAP)))"""
BUILD_ADDED = """        _safe_div_candidate_tree = None
        if SAFE_DIV_REQUIRE_MUTUAL_NN and candidate_ids:
            _safe_div_candidate_tree = cKDTree(
                np.stack([_position_um(nodes_by_id[_cid]) for _cid in candidate_ids], axis=0)
            )

        frame_cap = max(1, int(round(len(source_ids) * SAFE_DIV_FRAME_FRAC_CAP)))"""

WIDE_GEOMETRY = (
    ("BIOHUB_SAFE_DIV_MAX_UM", '"12.0"'),
    ("BIOHUB_SAFE_DIV_SISTER_MAX_UM", '"15.0"'),
    ("BIOHUB_SAFE_DIV_EXISTING_CHILD_MAX_UM", '"10.0"'),
)


def cell_index(nb: dict, needle: str) -> int:
    for index, cell in enumerate(nb["cells"]):
        if cell["cell_type"] == "code" and needle in "".join(cell["source"]):
            return index
    raise RuntimeError(f"no code cell containing {needle!r}")


def set_cell_source(nb: dict, index: int, text: str) -> None:
    nb["cells"][index]["source"] = text.splitlines(keepends=True)


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"{label}: expected one match, found {text.count(old)}")
    return text.replace(old, new, 1)


def set_env(config: str, key: str, value: str) -> str:
    matches = [l for l in config.splitlines() if l.startswith(f'os.environ["{key}"]')]
    if len(matches) != 1:
        raise RuntimeError(f"{key}: expected one assignment, found {len(matches)}")
    return config.replace(matches[0], f'os.environ["{key}"] = {value}', 1)


def main() -> None:
    nb = json.loads(BASE.read_text())

    config_defs_index = cell_index(nb, "SAFE_DIV_GLOBAL_FRAC_CAP = float")
    defs = "".join(nb["cells"][config_defs_index]["source"])
    defs = replace_once(defs, CONFIG_ANCHOR, CONFIG_ANCHOR + CONFIG_ADDED, "config defs")
    set_cell_source(nb, config_defs_index, defs)

    body_index = cell_index(nb, "sister_dist = edge_distance_um")
    body = "".join(nb["cells"][body_index]["source"])
    body = replace_once(body, BUILD_ANCHOR, BUILD_ADDED, "candidate tree")
    body = replace_once(body, TREE_ANCHOR, TREE_ADDED, "mutual-nn lookup")
    body = replace_once(body, FILTER_ANCHOR, FILTER_ADDED, "filters")
    set_cell_source(nb, body_index, body)

    env_index = cell_index(nb, "BIOHUB_PRESET")
    config = "".join(nb["cells"][env_index]["source"])
    for key, value in WIDE_GEOMETRY:
        config = set_env(config, key, value)
    config = replace_once(
        config,
        '\nprint("BIOHUB_PRESET:", BIOHUB_PRESET)',
        '\nos.environ["BIOHUB_SAFE_DIV_REQUIRE_MUTUAL_NN"] = "1"\n'
        'os.environ["BIOHUB_SAFE_DIV_REQUIRE_DIVERGENCE"] = "1"\n'
        'os.environ["BIOHUB_SAFE_DIV_DIVERGE_UM"] = "1.5"\n'
        '\nprint("BIOHUB_PRESET:", BIOHUB_PRESET)',
        "filter env",
    )
    for name, value in (
        ("BIOHUB_PRESET", "divergence_mutual_nn_wide_safe_division"),
        ("BIOHUB_SCORE_AXIS",
         "exp220 backbone with the divergence + mutual-NN safe-division filters "
         "ported from the public 0.923 recipe, plus its widened geometry "
         "12.0/15.0/10.0 which is invalid without them"),
    ):
        line = [l for l in config.splitlines() if l.startswith(name)]
        if len(line) != 1:
            raise RuntimeError(f"expected one {name} line")
        config = config.replace(line[0], f"{name} = {value!r}", 1)
    set_cell_source(nb, env_index, config)

    set_cell_source(
        nb, 1,
        "# Biohub Exp227: Divergence + Mutual-NN Filters, Wide Safe-Division Geometry\n\n"
        "Forked from Exp220 (public LB `0.916`). Ports the two safe-division "
        "admission filters that the public `0.923` recipe relies on, and applies "
        "its widened geometry on top.\n\n"
        "Exp223/Exp224 applied that widening alone and both failed the clean-graph "
        "audit with `maximum_outdegree = 3` and 452 divisions - a cell dividing "
        "into three. The recipe's own annotation says the widening is only viable "
        "because *\"divergence + mutual-NN are active now\"*; those are Python, not "
        "env flags, so a config diff did not reveal them.\n\n"
        "**Mutual nearest orphan** restricts each parent to at most one admissible "
        "sister - the existing child's nearest unclaimed neighbour by KD-tree - "
        "which is precisely what a widened radius otherwise violates. **Forward "
        "divergence** additionally requires both daughters to have a single "
        "successor at `t+2` whose separation exceeds the sisters' current distance "
        "by `SAFE_DIV_DIVERGE_UM = 1.5`.\n\n"
        "Both run before the DeepCenter veto, so the chain is geometry gates -> "
        "mutual-NN -> divergence -> DeepCenter veto. The clean-graph audit is the "
        "gate: if `maximum_outdegree` is not 2, the filters did not do their job.\n",
    )

    out = NOTEBOOKS / f"{SLUG}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")
    metadata = json.loads(BASE_METADATA.read_text())
    metadata["id"] = f"dalloliogm/{SLUG}"
    metadata["title"] = TITLE
    metadata["code_file"] = out.name
    (NOTEBOOKS / f"{SLUG}.kernel-metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n"
    )
    print(f"wrote {out.name}")


if __name__ == "__main__":
    main()
