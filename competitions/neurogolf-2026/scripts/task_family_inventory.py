#!/usr/bin/env python3
"""Mine reusable semantic and ONNX families across NeuroGolf tasks."""

from __future__ import annotations

import argparse
import csv
import json
import math
import pathlib
import zipfile
from collections import Counter, defaultdict, deque

import numpy as np
import onnx

from exact_rewrite_toolchain import (
    WORKSPACE,
    calculate_params,
    sanitize_model,
    tensor_dtype_and_shape,
)


DEFAULT_BASE_ZIP = WORKSPACE / "submissions" / "exact-rewrite-pass-v3-validated" / "submission.zip"
DEFAULT_OUT_DIR = WORKSPACE / "references" / "analysis" / "task-families-v3"
TOP_TARGETS = (233, 366, 286, 54, 133, 285, 187, 349, 2, 367)
BITWISE_OPS = {"And", "BitShift", "BitwiseAnd", "BitwiseNot", "BitwiseOr", "BitwiseXor", "Not", "Or", "Xor"}
INDEX_OPS = {"ArgMax", "ArgMin", "Gather", "GatherElements", "GatherND", "ScatterElements", "ScatterND", "TopK"}
SPATIAL_OPS = {"AveragePool", "Conv", "ConvTranspose", "MaxPool", "Pad", "Resize", "RoiAlign"}
SEMANTIC_FIELDS = (
    "shape_relation",
    "palette_relation",
    "nonzero_relation",
    "component_relation",
    "same_shape_mask_relation",
    "output_is_input_subgrid",
    "output_is_nonzero_bbox",
    "input_is_output_subgrid",
    "exact_geometric_transform",
    "exact_integer_scale",
    "input_shape_variability",
    "output_shape_variability",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-zip", type=pathlib.Path, default=DEFAULT_BASE_ZIP)
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--component-examples", type=int, default=48)
    parser.add_argument("--neighbors", type=int, default=12)
    return parser.parse_args()


def load_task(task: int) -> dict[str, list[dict[str, list[list[int]]]]]:
    with (WORKSPACE / "data" / f"task{task:03d}.json").open() as f:
        return json.load(f)


def task_examples(task: int) -> list[tuple[np.ndarray, np.ndarray]]:
    data = load_task(task)
    examples: list[tuple[np.ndarray, np.ndarray]] = []
    for split in ("train", "test", "arc-gen"):
        for item in data.get(split, []):
            examples.append((np.asarray(item["input"], dtype=np.uint8), np.asarray(item["output"], dtype=np.uint8)))
    return examples


def relation(values: list[int]) -> str:
    signs = {int(np.sign(value)) for value in values}
    if signs == {0}:
        return "same"
    if signs <= {-1, 0} and -1 in signs:
        return "decrease"
    if signs <= {0, 1} and 1 in signs:
        return "increase"
    return "mixed"


def aggregate_bool(values: list[bool], eligible: int | None = None) -> str:
    if eligible == 0 or not values:
        return "not_applicable"
    count = sum(values)
    if count == len(values):
        return "all"
    if count == 0:
        return "none"
    return "mixed"


def contains_subgrid(container: np.ndarray, candidate: np.ndarray) -> bool:
    if candidate.shape[0] > container.shape[0] or candidate.shape[1] > container.shape[1]:
        return False
    windows = np.lib.stride_tricks.sliding_window_view(container, candidate.shape)
    return bool(np.any(np.all(windows == candidate, axis=(-2, -1))))


def nonzero_bbox(grid: np.ndarray) -> np.ndarray | None:
    coords = np.argwhere(grid != 0)
    if not len(coords):
        return None
    top, left = coords.min(axis=0)
    bottom, right = coords.max(axis=0) + 1
    return grid[top:bottom, left:right]


def exact_geometry(inp: np.ndarray, out: np.ndarray) -> str:
    candidates = {
        "identity": inp,
        "rot90": np.rot90(inp, 1),
        "rot180": np.rot90(inp, 2),
        "rot270": np.rot90(inp, 3),
        "flip_h": np.fliplr(inp),
        "flip_v": np.flipud(inp),
        "transpose": inp.T,
        "anti_transpose": np.fliplr(np.flipud(inp)).T,
    }
    matches = [name for name, candidate in candidates.items() if candidate.shape == out.shape and np.array_equal(candidate, out)]
    return matches[0] if matches else "none"


def exact_scale(inp: np.ndarray, out: np.ndarray) -> str:
    if out.shape[0] % inp.shape[0] or out.shape[1] % inp.shape[1]:
        return "none"
    row_scale = out.shape[0] // inp.shape[0]
    col_scale = out.shape[1] // inp.shape[1]
    if row_scale < 1 or col_scale < 1 or (row_scale == 1 and col_scale == 1):
        return "none"
    expanded = np.repeat(np.repeat(inp, row_scale, axis=0), col_scale, axis=1)
    return f"{row_scale}x{col_scale}" if np.array_equal(expanded, out) else "none"


def component_count(grid: np.ndarray) -> int:
    mask = grid != 0
    seen = np.zeros(mask.shape, dtype=bool)
    count = 0
    for row, col in np.argwhere(mask):
        row = int(row)
        col = int(col)
        if seen[row, col]:
            continue
        count += 1
        queue = deque([(row, col)])
        seen[row, col] = True
        while queue:
            current_row, current_col = queue.popleft()
            for next_row, next_col in (
                (current_row - 1, current_col),
                (current_row + 1, current_col),
                (current_row, current_col - 1),
                (current_row, current_col + 1),
            ):
                if (
                    0 <= next_row < mask.shape[0]
                    and 0 <= next_col < mask.shape[1]
                    and mask[next_row, next_col]
                    and not seen[next_row, next_col]
                ):
                    seen[next_row, next_col] = True
                    queue.append((next_row, next_col))
    return count


def categorical_consensus(values: list[str]) -> str:
    unique = sorted(set(values))
    return unique[0] if len(unique) == 1 else "mixed"


def palette_relation(inp: np.ndarray, out: np.ndarray) -> str:
    in_colors = set(np.unique(inp).tolist()) - {0}
    out_colors = set(np.unique(out).tolist()) - {0}
    if out_colors == in_colors:
        return "same"
    if out_colors < in_colors:
        return "output_subset"
    if in_colors < out_colors:
        return "output_superset"
    if out_colors.isdisjoint(in_colors):
        return "disjoint"
    return "overlap"


def mask_relation(inp: np.ndarray, out: np.ndarray) -> str:
    if inp.shape != out.shape:
        return "not_applicable"
    in_mask = inp != 0
    out_mask = out != 0
    if np.array_equal(in_mask, out_mask):
        return "same"
    if np.all(out_mask <= in_mask):
        return "output_subset"
    if np.all(in_mask <= out_mask):
        return "output_superset"
    return "overlap"


def semantic_features(task: int, component_examples: int) -> dict[str, object]:
    examples = task_examples(task)
    shape_relations = []
    palette_relations = []
    mask_relations = []
    geometries = []
    scales = []
    output_subgrids = []
    input_subgrids = []
    bbox_matches = []
    nonzero_deltas = []
    component_deltas = []
    input_shapes = []
    output_shapes = []
    same_shape_count = 0

    for index, (inp, out) in enumerate(examples):
        row_relation = relation([out.shape[0] - inp.shape[0]])
        col_relation = relation([out.shape[1] - inp.shape[1]])
        shape_relations.append(f"rows_{row_relation}:cols_{col_relation}")
        palette_relations.append(palette_relation(inp, out))
        if inp.shape == out.shape:
            same_shape_count += 1
            mask_relations.append(mask_relation(inp, out))
        geometries.append(exact_geometry(inp, out))
        scales.append(exact_scale(inp, out))
        output_subgrids.append(contains_subgrid(inp, out))
        input_subgrids.append(contains_subgrid(out, inp))
        bbox = nonzero_bbox(inp)
        bbox_matches.append(bbox is not None and bbox.shape == out.shape and np.array_equal(bbox, out))
        nonzero_deltas.append(int(np.count_nonzero(out)) - int(np.count_nonzero(inp)))
        input_shapes.append(tuple(inp.shape))
        output_shapes.append(tuple(out.shape))
        if index < component_examples:
            component_deltas.append(component_count(out) - component_count(inp))

    geometry_non_none = [value for value in geometries if value != "none"]
    scale_non_none = [value for value in scales if value != "none"]
    primitive_tags: list[str] = []
    shape_relation = categorical_consensus(shape_relations)
    palette = categorical_consensus(palette_relations)
    nonzero = relation(nonzero_deltas)
    components = relation(component_deltas)
    mask = categorical_consensus(mask_relations) if mask_relations else "not_applicable"
    output_subgrid = aggregate_bool(output_subgrids)
    bbox_match = aggregate_bool(bbox_matches)
    input_subgrid = aggregate_bool(input_subgrids)
    geometry = categorical_consensus(geometries)
    scale = categorical_consensus(scales)

    if shape_relation == "rows_same:cols_same":
        primitive_tags.append("same_shape")
    if "decrease" in shape_relation:
        primitive_tags.append("crop_or_extract")
    if "increase" in shape_relation:
        primitive_tags.append("expand_or_compose")
    if output_subgrid == "all":
        primitive_tags.append("subgrid_extract")
    if bbox_match == "all":
        primitive_tags.append("bbox_crop")
    if geometry != "none" and len(geometry_non_none) == len(examples):
        primitive_tags.append("geometry")
    if scale != "none" and len(scale_non_none) == len(examples):
        primitive_tags.append("integer_scale")
    if mask == "same":
        primitive_tags.append("mask_preserving")
    if palette == "output_subset":
        primitive_tags.append("palette_filter")
    if palette == "output_superset":
        primitive_tags.append("palette_add")
    if nonzero == "increase":
        primitive_tags.append("paint_or_fill")
    if nonzero == "decrease":
        primitive_tags.append("select_or_erase")
    if "crop_or_extract" in primitive_tags and output_subgrid != "all" and palette in {"same", "output_subset"}:
        primitive_tags.append("extract_and_recompose")

    return {
        "task": f"task{task:03d}",
        "example_count": len(examples),
        "shape_relation": shape_relation,
        "palette_relation": palette,
        "nonzero_relation": nonzero,
        "component_relation": components,
        "same_shape_mask_relation": mask,
        "same_shape_examples": same_shape_count,
        "output_is_input_subgrid": output_subgrid,
        "output_is_nonzero_bbox": bbox_match,
        "input_is_output_subgrid": input_subgrid,
        "exact_geometric_transform": geometry,
        "exact_integer_scale": scale,
        "input_shape_variability": "fixed" if len(set(input_shapes)) == 1 else "variable",
        "output_shape_variability": "fixed" if len(set(output_shapes)) == 1 else "variable",
        "primitive_tags": ";".join(primitive_tags),
    }


def model_memory(model: onnx.ModelProto) -> tuple[int, int, int, float, bool]:
    sanitized = sanitize_model(model)
    if sanitized is None:
        return 0, 0, 0, 0.0, False
    dtypes, shapes = tensor_dtype_and_shape(sanitized)
    node_outputs = {output for node in sanitized.graph.node for output in node.output if output}
    graph_outputs = {item.name for item in sanitized.graph.output}
    memory = 0
    complete = True
    for name in node_outputs - graph_outputs:
        dtype = dtypes.get(name)
        shape = shapes.get(name)
        if dtype is None or shape is None or any(dim <= 0 for dim in shape):
            complete = False
            continue
        np_dtype = np.dtype(onnx.helper.tensor_dtype_to_np_dtype(dtype))
        memory += math.prod(shape) * np_dtype.itemsize
    params = calculate_params(sanitized) or 0
    cost = memory + params
    points = max(1.0, 25.0 - math.log(max(1, cost))) if cost else 0.0
    return memory, params, cost, points, complete


def architecture_family(op_counts: Counter[str]) -> str:
    total = sum(op_counts.values())
    if total == 1:
        return f"single_{next(iter(op_counts)).lower()}"
    candidates = {
        "bitwise": sum(op_counts[op] for op in BITWISE_OPS),
        "index_scatter": sum(op_counts[op] for op in INDEX_OPS),
        "spatial": sum(op_counts[op] for op in SPATIAL_OPS),
        "einsum": op_counts["Einsum"],
        "quantized": sum(count for op, count in op_counts.items() if op.startswith("QLinear") or op == "QuantizeLinear"),
    }
    family, count = max(candidates.items(), key=lambda item: item[1])
    return family if count and count / total >= 0.2 else "mixed"


def model_features(task: int, raw: bytes) -> dict[str, object]:
    model = onnx.load_model_from_string(raw)
    op_counts = Counter(node.op_type for node in model.graph.node)
    memory, params, cost, points, complete = model_memory(model)
    return {
        "model_bytes": len(raw),
        "node_count": len(model.graph.node),
        "initializer_count": len(model.graph.initializer),
        "estimated_memory": memory,
        "parameter_count": params,
        "estimated_cost": cost,
        "estimated_points": f"{points:.9f}" if points else "",
        "shape_inventory_complete": complete,
        "architecture_family": architecture_family(op_counts),
        "top_ops": ";".join(f"{op}:{count}" for op, count in op_counts.most_common(10)),
    }


def semantic_signature(row: dict[str, object]) -> str:
    return "|".join(str(row[field]) for field in SEMANTIC_FIELDS)


def semantic_similarity(left: dict[str, object], right: dict[str, object]) -> float:
    matches = 0.0
    weight = 0.0
    for field in SEMANTIC_FIELDS:
        field_weight = 2.0 if field in {"shape_relation", "palette_relation", "same_shape_mask_relation"} else 1.0
        weight += field_weight
        if left[field] == right[field]:
            matches += field_weight
    left_tags = set(str(left["primitive_tags"]).split(";")) - {""}
    right_tags = set(str(right["primitive_tags"]).split(";")) - {""}
    if left_tags or right_tags:
        matches += 3.0 * len(left_tags & right_tags) / len(left_tags | right_tags)
    weight += 3.0
    return matches / weight


def write_csv(path: pathlib.Path, rows: list[dict[str, object]]) -> None:
    fieldnames = sorted({key for row in rows for key in row})
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    args = parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.base_zip) as archive:
        payloads = {name: archive.read(name) for name in archive.namelist() if name.endswith(".onnx") and "/" not in name}
    if len(payloads) != 400:
        raise SystemExit(f"Expected 400 root ONNX files, found {len(payloads)}")

    rows = []
    for task in range(1, 401):
        task_name = f"task{task:03d}.onnx"
        row = semantic_features(task, args.component_examples)
        row.update(model_features(task, payloads[task_name]))
        row["semantic_signature"] = semantic_signature(row)
        rows.append(row)
        print(f"[family] {row['task']} {row['primitive_tags']} cost={row['estimated_cost']}")

    grouped: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        grouped[str(row["semantic_signature"])].append(row)
    family_rows = []
    family_index = 0
    for signature, members in sorted(grouped.items(), key=lambda item: (-len(item[1]), item[0])):
        if len(members) < 2:
            continue
        family_index += 1
        known_costs = [int(member["estimated_cost"]) for member in members if member["shape_inventory_complete"]]
        family_rows.append(
            {
                "family": f"family_{family_index:03d}",
                "task_count": len(members),
                "tasks": ";".join(str(member["task"]) for member in members),
                "known_aggregate_cost": sum(known_costs),
                "known_cost_tasks": len(known_costs),
                "primitive_tags": members[0]["primitive_tags"],
                "shape_relation": members[0]["shape_relation"],
                "palette_relation": members[0]["palette_relation"],
                "architecture_families": ";".join(sorted({str(member["architecture_family"]) for member in members})),
                "semantic_signature": signature,
            }
        )

    by_task = {str(row["task"]): row for row in rows}
    neighbor_rows = []
    for target in TOP_TARGETS:
        target_name = f"task{target:03d}"
        target_row = by_task[target_name]
        ranked = sorted(
            (
                (semantic_similarity(target_row, candidate), candidate)
                for candidate in rows
                if candidate["task"] != target_name
            ),
            key=lambda item: (-item[0], -int(item[1]["estimated_cost"]), str(item[1]["task"])),
        )[: args.neighbors]
        for rank, (similarity, candidate) in enumerate(ranked, start=1):
            neighbor_rows.append(
                {
                    "target": target_name,
                    "target_cost": target_row["estimated_cost"],
                    "rank": rank,
                    "neighbor": candidate["task"],
                    "neighbor_cost": candidate["estimated_cost"],
                    "similarity": f"{similarity:.6f}",
                    "target_tags": target_row["primitive_tags"],
                    "neighbor_tags": candidate["primitive_tags"],
                    "target_architecture": target_row["architecture_family"],
                    "neighbor_architecture": candidate["architecture_family"],
                }
            )

    write_csv(args.out_dir / "tasks.csv", rows)
    write_csv(args.out_dir / "families.csv", family_rows)
    write_csv(args.out_dir / "neighbors.csv", neighbor_rows)

    ranked_families = sorted(
        family_rows,
        key=lambda row: (-int(row["known_aggregate_cost"]), -int(row["task_count"]), str(row["family"])),
    )
    report_lines = [
        "# NeuroGolf Task Family Inventory",
        "",
        f"- Base: `{args.base_zip}`",
        f"- Tasks: `{len(rows)}`",
        f"- Repeated semantic families: `{len(family_rows)}`",
        "",
        "## Highest Aggregate-Cost Families",
        "",
        "| Family | Tasks | Known aggregate cost | Primitive tags | Architectures |",
        "| --- | ---: | ---: | --- | --- |",
    ]
    for family in ranked_families[:20]:
        report_lines.append(
            f"| {family['family']} | {family['task_count']} | {family['known_aggregate_cost']} | "
            f"{family['primitive_tags']} | {family['architecture_families']} |"
        )
        report_lines.append(f"Tasks: {family['tasks']}")
    report_lines.extend(["", "## Expensive-Task Neighbors", ""])
    for target in TOP_TARGETS:
        target_name = f"task{target:03d}"
        report_lines.append(f"### {target_name}")
        for item in [row for row in neighbor_rows if row["target"] == target_name][:5]:
            report_lines.append(
                f"- `{item['neighbor']}` similarity `{item['similarity']}`, cost `{item['neighbor_cost']}`, "
                f"tags `{item['neighbor_tags']}`"
            )
        report_lines.append("")
    (args.out_dir / "REPORT.md").write_text("\n".join(report_lines) + "\n")

    manifest = {
        "base_zip": str(args.base_zip),
        "task_count": len(rows),
        "repeated_family_count": len(family_rows),
        "top_targets": [f"task{task:03d}" for task in TOP_TARGETS],
        "outputs": ["tasks.csv", "families.csv", "neighbors.csv", "REPORT.md"],
    }
    (args.out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
