#!/usr/bin/env python3
"""Find exact scorer-aware ONNX cleanups for the current NeuroGolf best bundle."""

from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import json
import math
import pathlib
import tempfile
import zipfile
from dataclasses import dataclass, field

import numpy as np
import onnx
import onnxruntime
from onnx import numpy_helper


WORKSPACE = pathlib.Path(__file__).resolve().parents[1]
DATA_DIR = WORKSPACE / "data"
DEFAULT_BASE_ZIP = WORKSPACE / "submissions" / "exact-rewrite-pass-v1" / "submission.zip"
DEFAULT_OUT_DIR = WORKSPACE / "submissions" / "exact-rewrite-pass-v2"
GRID_SHAPE = (1, 10, 30, 30)
EXCLUDED_OP_TYPES = {"LOOP", "SCAN", "NONZERO", "UNIQUE", "SCRIPT", "FUNCTION", "COMPRESS"}
FILESIZE_LIMIT_IN_BYTES = 1.44 * 1024 * 1024
DATA_MOVEMENT_OPS = {
    "Expand",
    "Flatten",
    "Gather",
    "GatherElements",
    "GatherND",
    "Reshape",
    "Slice",
    "Squeeze",
    "Transpose",
    "Unsqueeze",
}
SAFE_CSE_OPS = {
    "Abs",
    "Add",
    "And",
    "ArgMax",
    "ArgMin",
    "AveragePool",
    "BitShift",
    "BitwiseAnd",
    "BitwiseNot",
    "BitwiseOr",
    "BitwiseXor",
    "Cast",
    "Ceil",
    "Clip",
    "Concat",
    "Conv",
    "Div",
    "Einsum",
    "Equal",
    "Expand",
    "Flatten",
    "Floor",
    "Gather",
    "GatherElements",
    "GatherND",
    "Greater",
    "GreaterOrEqual",
    "Less",
    "LessOrEqual",
    "MatMul",
    "Max",
    "MaxPool",
    "Min",
    "Mod",
    "Mul",
    "Neg",
    "Not",
    "Or",
    "Pow",
    "QLinearConv",
    "ReduceMax",
    "ReduceMin",
    "ReduceProd",
    "ReduceSum",
    "Relu",
    "Reshape",
    "Shape",
    "Sign",
    "Slice",
    "Squeeze",
    "Sub",
    "Transpose",
    "Unsqueeze",
    "Where",
    "Xor",
}
COMMUTATIVE_CSE_OPS = {
    "And",
    "BitwiseAnd",
    "BitwiseOr",
    "BitwiseXor",
    "Equal",
    "Or",
    "Xor",
}


@dataclass
class Score:
    memory: int
    params: int

    @property
    def cost(self) -> int:
        return self.memory + self.params

    @property
    def points(self) -> float:
        return max(1.0, 25.0 - math.log(max(1.0, self.cost)))


@dataclass
class TaskResult:
    task: str
    status: str
    rewrites: list[str] = field(default_factory=list)
    base_score: Score | None = None
    candidate_score: Score | None = None
    base_bytes: int = 0
    candidate_bytes: int = 0
    message: str = ""

    def to_row(self) -> dict[str, object]:
        base_cost = self.base_score.cost if self.base_score else ""
        candidate_cost = self.candidate_score.cost if self.candidate_score else ""
        base_points = f"{self.base_score.points:.9f}" if self.base_score else ""
        candidate_points = f"{self.candidate_score.points:.9f}" if self.candidate_score else ""
        return {
            "task": self.task,
            "status": self.status,
            "rewrites": ";".join(self.rewrites),
            "base_memory": self.base_score.memory if self.base_score else "",
            "base_params": self.base_score.params if self.base_score else "",
            "base_cost": base_cost,
            "base_points": base_points,
            "candidate_memory": self.candidate_score.memory if self.candidate_score else "",
            "candidate_params": self.candidate_score.params if self.candidate_score else "",
            "candidate_cost": candidate_cost,
            "candidate_points": candidate_points,
            "cost_delta": candidate_cost - base_cost if self.base_score and self.candidate_score else "",
            "point_delta": f"{self.candidate_score.points - self.base_score.points:.9f}"
            if self.base_score and self.candidate_score
            else "",
            "base_bytes": self.base_bytes,
            "candidate_bytes": self.candidate_bytes,
            "byte_delta": self.candidate_bytes - self.base_bytes if self.candidate_bytes else "",
            "message": self.message,
        }


def task_num(task_name: str) -> int:
    return int(task_name.removeprefix("task").removesuffix(".onnx"))


def load_examples(task: int) -> dict[str, list[dict[str, list[list[int]]]]]:
    with (DATA_DIR / f"task{task:03d}.json").open() as f:
        return json.load(f)


def convert_to_numpy(example: dict[str, list[list[int]]]) -> dict[str, np.ndarray] | None:
    out: dict[str, np.ndarray] = {}
    for mode in ("input", "output"):
        grid = example[mode]
        if max(len(grid), len(grid[0])) > 30:
            return None
        arr = np.zeros(GRID_SHAPE, dtype=np.float32)
        for r, row in enumerate(grid):
            for c, color in enumerate(row):
                arr[0, color, r, c] = 1.0
        out[mode] = arr
    return out


def examples_for_task(task: int) -> list[dict[str, np.ndarray]]:
    examples = load_examples(task)
    converted = []
    for subset in ("train", "test", "arc-gen"):
        for example in examples.get(subset, []):
            item = convert_to_numpy(example)
            if item is not None:
                converted.append(item)
    return converted


def random_inputs_for_task(task: int, count: int) -> list[np.ndarray]:
    rng = np.random.default_rng(20260713 + task)
    inputs = []
    for _ in range(count):
        height = int(rng.integers(1, 31))
        width = int(rng.integers(1, 31))
        colors = rng.integers(0, 10, size=(height, width))
        arr = np.zeros(GRID_SHAPE, dtype=np.float32)
        rows = np.arange(height)[:, None]
        cols = np.arange(width)[None, :]
        arr[0, colors, rows, cols] = 1.0
        inputs.append(arr)
    return inputs


def tensor_dtype_and_shape(model: onnx.ModelProto) -> tuple[dict[str, int], dict[str, tuple[int, ...]]]:
    dtypes: dict[str, int] = {}
    shapes: dict[str, tuple[int, ...]] = {}

    def add_value_info(value_info: onnx.ValueInfoProto) -> None:
        if not value_info.type.HasField("tensor_type"):
            return
        tensor_type = value_info.type.tensor_type
        dtypes[value_info.name] = tensor_type.elem_type
        if tensor_type.HasField("shape"):
            dims: list[int] = []
            for dim in tensor_type.shape.dim:
                if dim.HasField("dim_value"):
                    dims.append(dim.dim_value)
                else:
                    return
            shapes[value_info.name] = tuple(dims)

    try:
        graph = onnx.shape_inference.infer_shapes(model, strict_mode=False).graph
    except Exception:
        graph = model.graph

    for item in list(graph.input) + list(graph.value_info) + list(graph.output):
        add_value_info(item)
    for init in graph.initializer:
        dtypes[init.name] = init.data_type
        shapes[init.name] = tuple(init.dims)
    return dtypes, shapes


def initializer_arrays(model: onnx.ModelProto) -> dict[str, np.ndarray]:
    return {init.name: numpy_helper.to_array(init) for init in model.graph.initializer}


def constant_arrays(model: onnx.ModelProto) -> dict[str, np.ndarray]:
    arrays = initializer_arrays(model)
    for node in model.graph.node:
        if node.op_type != "Constant" or len(node.output) != 1:
            continue
        for attr in node.attribute:
            if attr.name == "value":
                arrays[node.output[0]] = numpy_helper.to_array(attr.t)
            elif attr.name == "value_float":
                arrays[node.output[0]] = np.array(attr.f, dtype=np.float32)
            elif attr.name == "value_int":
                arrays[node.output[0]] = np.array(attr.i, dtype=np.int64)
            elif attr.name == "value_floats":
                arrays[node.output[0]] = np.array(attr.floats, dtype=np.float32)
            elif attr.name == "value_ints":
                arrays[node.output[0]] = np.array(attr.ints, dtype=np.int64)
    return arrays


def array_is_value(arrays: dict[str, np.ndarray], name: str, value: float) -> bool:
    arr = arrays.get(name)
    return arr is not None and arr.size > 0 and bool(np.all(arr == value))


def replace_tensor_uses(model: onnx.ModelProto, old: str, new: str) -> None:
    for node in model.graph.node:
        for i, item in enumerate(node.input):
            if item == old:
                node.input[i] = new


def producer_map(model: onnx.ModelProto) -> dict[str, tuple[int, onnx.NodeProto]]:
    return {
        output: (index, node)
        for index, node in enumerate(model.graph.node)
        for output in node.output
        if output
    }


def consumer_map(model: onnx.ModelProto) -> dict[str, list[int]]:
    consumers: dict[str, list[int]] = {}
    for index, node in enumerate(model.graph.node):
        for item in node.input:
            if item:
                consumers.setdefault(item, []).append(index)
    return consumers


def unique_tensor_name(model: onnx.ModelProto, stem: str) -> str:
    names = {item.name for item in model.graph.input}
    names.update(item.name for item in model.graph.output)
    names.update(item.name for item in model.graph.value_info)
    names.update(init.name for init in model.graph.initializer)
    names.update(output for node in model.graph.node for output in node.output if output)
    candidate = stem
    suffix = 1
    while candidate in names:
        candidate = f"{stem}_{suffix}"
        suffix += 1
    return candidate


def cast_target(node: onnx.NodeProto) -> int | None:
    if node.op_type != "Cast":
        return None
    for attr in node.attribute:
        if attr.name == "to":
            return attr.i
    return None


def arrays_equal(arrays: dict[str, np.ndarray], left: str, right: str) -> bool:
    left_arr = arrays.get(left)
    right_arr = arrays.get(right)
    if left_arr is None or right_arr is None:
        return False
    return left_arr.dtype == right_arr.dtype and left_arr.shape == right_arr.shape and bool(
        np.array_equal(left_arr, right_arr, equal_nan=True)
    )


def deduplicate_initializers(model: onnx.ModelProto) -> int:
    outputs = graph_output_names(model)
    canonical: dict[tuple[str, tuple[int, ...], bytes], str] = {}
    kept = []
    removed = 0
    for init in model.graph.initializer:
        try:
            arr = numpy_helper.to_array(init)
        except Exception:
            kept.append(copy.deepcopy(init))
            continue
        if arr.dtype.hasobject or init.name in outputs:
            kept.append(copy.deepcopy(init))
            continue
        key = (arr.dtype.str, tuple(arr.shape), arr.tobytes())
        if key not in canonical:
            canonical[key] = init.name
            kept.append(copy.deepcopy(init))
            continue
        replace_tensor_uses(model, init.name, canonical[key])
        removed += 1
    if removed:
        del model.graph.initializer[:]
        model.graph.initializer.extend(kept)
    return removed


def eliminate_duplicate_nodes(model: onnx.ModelProto) -> int:
    outputs = graph_output_names(model)
    canonical: dict[tuple[object, ...], str] = {}
    kept = []
    removed = 0
    for node in model.graph.node:
        if len(node.output) != 1 or node.output[0] in outputs or node.op_type not in SAFE_CSE_OPS:
            kept.append(copy.deepcopy(node))
            continue
        node_inputs = tuple(node.input)
        if node.op_type in COMMUTATIVE_CSE_OPS and len(node_inputs) == 2:
            node_inputs = tuple(sorted(node_inputs))
        key = (
            node.domain,
            node.op_type,
            node_inputs,
            tuple(attr.SerializeToString() for attr in node.attribute),
        )
        if key not in canonical:
            canonical[key] = node.output[0]
            kept.append(copy.deepcopy(node))
            continue
        replace_tensor_uses(model, node.output[0], canonical[key])
        removed += 1
    if removed:
        del model.graph.node[:]
        model.graph.node.extend(kept)
    return removed


def push_cast_through_data_movement(model: onnx.ModelProto) -> str | None:
    producers = producer_map(model)
    consumers = consumer_map(model)
    outputs = graph_output_names(model)
    for movement_index, movement in enumerate(model.graph.node):
        if movement.op_type not in DATA_MOVEMENT_OPS or not movement.input or len(movement.output) != 1:
            continue
        cast_info = producers.get(movement.input[0])
        if cast_info is None:
            continue
        cast_index, cast = cast_info
        if cast.op_type != "Cast" or len(cast.input) != 1 or len(cast.output) != 1:
            continue
        if cast.output[0] in outputs or consumers.get(cast.output[0]) != [movement_index]:
            continue
        target_type = cast_target(cast)
        if target_type is None:
            continue

        old_output = movement.output[0]
        precast_output = unique_tensor_name(model, f"{old_output}__precast")
        rewritten_movement = copy.deepcopy(movement)
        rewritten_movement.input[0] = cast.input[0]
        rewritten_movement.output[0] = precast_output
        rewritten_cast = onnx.helper.make_node(
            "Cast",
            [precast_output],
            [old_output],
            name=f"{old_output}__cast_after_{movement.op_type.lower()}",
            to=target_type,
        )
        rewritten_nodes = []
        for index, node in enumerate(model.graph.node):
            if index == cast_index:
                continue
            if index == movement_index:
                rewritten_nodes.extend([rewritten_movement, rewritten_cast])
            else:
                rewritten_nodes.append(copy.deepcopy(node))
        del model.graph.node[:]
        model.graph.node.extend(rewritten_nodes)
        return f"cast_after_{movement.op_type.lower()}"
    return None


def push_cast_through_concat(model: onnx.ModelProto) -> str | None:
    producers = producer_map(model)
    consumers = consumer_map(model)
    outputs = graph_output_names(model)
    dtypes, _ = tensor_dtype_and_shape(model)
    initializers = {init.name: init for init in model.graph.initializer}
    for concat_index, concat in enumerate(model.graph.node):
        if concat.op_type != "Concat" or len(concat.input) < 2 or len(concat.output) != 1:
            continue
        cast_inputs: list[tuple[int, onnx.NodeProto]] = []
        for item in concat.input:
            producer = producers.get(item)
            if producer is not None and producer[1].op_type == "Cast":
                cast_inputs.append(producer)
        if not cast_inputs:
            continue
        first_cast = cast_inputs[0][1]
        target_type = cast_target(first_cast)
        source_type = dtypes.get(first_cast.input[0]) if first_cast.input else None
        if target_type is None or source_type is None:
            continue

        rewritten_inputs: list[str] = []
        converted_initializers: list[onnx.TensorProto] = []
        removable_cast_indices: set[int] = set()
        valid = True
        source_np_dtype = np.dtype(onnx.helper.tensor_dtype_to_np_dtype(source_type))
        target_np_dtype = np.dtype(onnx.helper.tensor_dtype_to_np_dtype(target_type))
        for item in concat.input:
            producer = producers.get(item)
            if producer is not None and producer[1].op_type == "Cast":
                cast_index, cast = producer
                if (
                    len(cast.input) != 1
                    or len(cast.output) != 1
                    or cast_target(cast) != target_type
                    or dtypes.get(cast.input[0]) != source_type
                    or cast.output[0] in outputs
                    or consumers.get(cast.output[0]) != [concat_index]
                ):
                    valid = False
                    break
                rewritten_inputs.append(cast.input[0])
                removable_cast_indices.add(cast_index)
                continue
            if dtypes.get(item) == source_type:
                rewritten_inputs.append(item)
                continue
            init = initializers.get(item)
            if init is None or dtypes.get(item) != target_type:
                valid = False
                break
            arr = numpy_helper.to_array(init)
            converted = arr.astype(source_np_dtype)
            restored = converted.astype(target_np_dtype)
            if not np.array_equal(restored, arr, equal_nan=True):
                valid = False
                break
            new_name = unique_tensor_name(model, f"{item}__as_{source_type}")
            converted_initializers.append(numpy_helper.from_array(converted, new_name))
            rewritten_inputs.append(new_name)
        if not valid:
            continue

        old_output = concat.output[0]
        precast_output = unique_tensor_name(model, f"{old_output}__precast")
        rewritten_concat = copy.deepcopy(concat)
        del rewritten_concat.input[:]
        rewritten_concat.input.extend(rewritten_inputs)
        rewritten_concat.output[0] = precast_output
        rewritten_cast = onnx.helper.make_node(
            "Cast",
            [precast_output],
            [old_output],
            name=f"{old_output}__cast_after_concat",
            to=target_type,
        )
        rewritten_nodes = []
        for index, node in enumerate(model.graph.node):
            if index in removable_cast_indices:
                continue
            if index == concat_index:
                rewritten_nodes.extend([rewritten_concat, rewritten_cast])
            else:
                rewritten_nodes.append(copy.deepcopy(node))
        del model.graph.node[:]
        model.graph.node.extend(rewritten_nodes)
        model.graph.initializer.extend(converted_initializers)
        return "cast_after_concat"
    return None


def collapse_reshape_chain(model: onnx.ModelProto) -> int:
    producers = producer_map(model)
    consumers = consumer_map(model)
    arrays = constant_arrays(model)
    outputs = graph_output_names(model)
    for node_index, node in enumerate(model.graph.node):
        if node.op_type != "Reshape" or len(node.input) < 2 or len(node.output) != 1:
            continue
        producer_info = producers.get(node.input[0])
        if producer_info is None:
            continue
        producer_index, producer = producer_info
        if producer.op_type != "Reshape" or len(producer.input) < 1 or len(producer.output) != 1:
            continue
        target_shape = arrays.get(node.input[1])
        if target_shape is None or np.any(target_shape == 0):
            continue
        if producer.output[0] in outputs or consumers.get(producer.output[0]) != [node_index]:
            continue
        node.input[0] = producer.input[0]
        remove_node_by_index(model, producer_index)
        return 1
    return 0


def graph_output_names(model: onnx.ModelProto) -> set[str]:
    return {item.name for item in model.graph.output}


def remove_node_by_index(model: onnx.ModelProto, index: int) -> None:
    del model.graph.node[index]


def normalize_value_info(model: onnx.ModelProto) -> int:
    node_outputs = {output for node in model.graph.node for output in node.output if output}
    output_names = graph_output_names(model)
    keep_names = node_outputs | output_names
    kept = []
    removed = 0
    seen = set()
    for vi in model.graph.value_info:
        if vi.name in keep_names and vi.name not in seen:
            kept.append(copy.deepcopy(vi))
            seen.add(vi.name)
        else:
            removed += 1
    del model.graph.value_info[:]
    model.graph.value_info.extend(kept)
    return removed


def prune_unused_initializers(model: onnx.ModelProto) -> int:
    used_inputs = {inp for node in model.graph.node for inp in node.input if inp}
    used_inputs |= graph_output_names(model)
    kept = []
    removed = 0
    for init in model.graph.initializer:
        if init.name in used_inputs:
            kept.append(copy.deepcopy(init))
        else:
            removed += 1
    del model.graph.initializer[:]
    model.graph.initializer.extend(kept)
    return removed


def eliminate_dead_nodes(model: onnx.ModelProto) -> int:
    needed = set(graph_output_names(model))
    keep_rev = []
    for node in reversed(model.graph.node):
        outputs = {out for out in node.output if out}
        if outputs & needed:
            keep_rev.append(copy.deepcopy(node))
            needed.update(inp for inp in node.input if inp)
    removed = len(model.graph.node) - len(keep_rev)
    if removed:
        del model.graph.node[:]
        model.graph.node.extend(reversed(keep_rev))
    return removed


def eliminate_passthrough_nodes(model: onnx.ModelProto) -> list[str]:
    rewrites: list[str] = []
    outputs = graph_output_names(model)
    dtypes, shapes = tensor_dtype_and_shape(model)
    arrays = constant_arrays(model)
    i = 0
    while i < len(model.graph.node):
        node = model.graph.node[i]
        if len(node.output) != 1 or node.output[0] in outputs:
            i += 1
            continue
        out = node.output[0]
        replacement = None
        reason = None
        if node.op_type == "Identity" and len(node.input) == 1:
            replacement = node.input[0]
            reason = "identity"
        elif node.op_type == "Cast" and len(node.input) == 1:
            to_type = None
            for attr in node.attribute:
                if attr.name == "to":
                    to_type = attr.i
                    break
            if to_type is not None and dtypes.get(node.input[0]) == to_type:
                replacement = node.input[0]
                reason = "noop_cast"
        elif node.op_type == "Reshape" and len(node.input) >= 1:
            if shapes.get(node.input[0]) == shapes.get(out) and node.input[0] in shapes:
                replacement = node.input[0]
                reason = "noop_reshape"
        elif node.op_type == "Transpose" and len(node.input) == 1:
            perm = None
            for attr in node.attribute:
                if attr.name == "perm":
                    perm = list(attr.ints)
                    break
            in_shape = shapes.get(node.input[0])
            if perm is not None and in_shape and perm == list(range(len(in_shape))):
                replacement = node.input[0]
                reason = "noop_transpose"
        elif node.op_type == "Where" and len(node.input) == 3:
            condition = arrays.get(node.input[0])
            if node.input[1] == node.input[2] or arrays_equal(arrays, node.input[1], node.input[2]):
                replacement = node.input[1]
                reason = "same_branch_where"
            elif condition is not None and condition.dtype == np.bool_ and bool(np.all(condition)):
                replacement = node.input[1]
                reason = "constant_true_where"
            elif condition is not None and condition.dtype == np.bool_ and bool(np.all(~condition)):
                replacement = node.input[2]
                reason = "constant_false_where"
        elif node.op_type == "Concat" and len(node.input) == 1:
            replacement = node.input[0]
            reason = "single_input_concat"
        elif node.op_type in {"Add", "Mul"} and len(node.input) == 2:
            identity = 0 if node.op_type == "Add" else 1
            if array_is_value(arrays, node.input[0], identity):
                replacement = node.input[1]
                reason = f"{node.op_type.lower()}_identity_lhs"
            elif array_is_value(arrays, node.input[1], identity):
                replacement = node.input[0]
                reason = f"{node.op_type.lower()}_identity_rhs"
        elif node.op_type in {"Sub", "Div"} and len(node.input) == 2:
            identity = 0 if node.op_type == "Sub" else 1
            if array_is_value(arrays, node.input[1], identity):
                replacement = node.input[0]
                reason = f"{node.op_type.lower()}_identity_rhs"

        if replacement:
            replace_tensor_uses(model, out, replacement)
            remove_node_by_index(model, i)
            rewrites.append(reason or "passthrough")
        else:
            i += 1
    return rewrites


def eliminate_bitwise_identities(model: onnx.ModelProto) -> list[str]:
    """Apply shape-preserving idempotence and absorption identities."""
    rewrites: list[str] = []
    outputs = graph_output_names(model)
    _, shapes = tensor_dtype_and_shape(model)
    identity_ops = {
        "And": "Or",
        "BitwiseAnd": "BitwiseOr",
        "Or": "And",
        "BitwiseOr": "BitwiseAnd",
    }
    i = 0
    while i < len(model.graph.node):
        node = model.graph.node[i]
        if (
            node.op_type not in identity_ops
            or len(node.input) != 2
            or len(node.output) != 1
            or node.output[0] in outputs
        ):
            i += 1
            continue
        out = node.output[0]
        replacement = None
        reason = None
        if node.input[0] == node.input[1] and shapes.get(node.input[0]) == shapes.get(out):
            replacement = node.input[0]
            reason = f"{node.op_type.lower()}_idempotent"
        else:
            producers = producer_map(model)
            opposite_op = identity_ops[node.op_type]
            for direct_input, nested_input in ((node.input[0], node.input[1]), (node.input[1], node.input[0])):
                producer_info = producers.get(nested_input)
                if producer_info is None:
                    continue
                nested = producer_info[1]
                if (
                    nested.op_type == opposite_op
                    and len(nested.input) == 2
                    and direct_input in nested.input
                    and shapes.get(direct_input) == shapes.get(out)
                    and shapes.get(nested_input) == shapes.get(out)
                ):
                    replacement = direct_input
                    reason = f"{node.op_type.lower()}_absorption"
                    break
        if replacement:
            replace_tensor_uses(model, out, replacement)
            remove_node_by_index(model, i)
            rewrites.append(reason or "bitwise_identity")
        else:
            i += 1
    return rewrites


def apply_rewrites(model: onnx.ModelProto) -> tuple[onnx.ModelProto, list[str]]:
    candidate = copy.deepcopy(model)
    rewrites: list[str] = []
    changed = True
    while changed:
        changed = False
        duplicate_initializers = deduplicate_initializers(candidate)
        if duplicate_initializers:
            rewrites.append(f"duplicate_initializers:{duplicate_initializers}")
            changed = True
        concat_cast = push_cast_through_concat(candidate)
        if concat_cast:
            rewrites.append(concat_cast)
            changed = True
        movement_cast = push_cast_through_data_movement(candidate)
        if movement_cast:
            rewrites.append(movement_cast)
            changed = True
        reshape_chains = collapse_reshape_chain(candidate)
        if reshape_chains:
            rewrites.append(f"reshape_chain:{reshape_chains}")
            changed = True
        pass_rewrites = eliminate_passthrough_nodes(candidate)
        if pass_rewrites:
            rewrites.extend(pass_rewrites)
            changed = True
        bitwise_rewrites = eliminate_bitwise_identities(candidate)
        if bitwise_rewrites:
            rewrites.extend(bitwise_rewrites)
            changed = True
        duplicate_nodes = eliminate_duplicate_nodes(candidate)
        if duplicate_nodes:
            rewrites.append(f"duplicate_nodes:{duplicate_nodes}")
            changed = True
        dead = eliminate_dead_nodes(candidate)
        if dead:
            rewrites.append(f"dead_nodes:{dead}")
            changed = True
        unused_init = prune_unused_initializers(candidate)
        if unused_init:
            rewrites.append(f"unused_initializers:{unused_init}")
            changed = True
        stale_vi = normalize_value_info(candidate)
        if stale_vi:
            rewrites.append(f"stale_value_info:{stale_vi}")
            changed = True
    return candidate, rewrites


def sanitize_model(model: onnx.ModelProto) -> onnx.ModelProto | None:
    model = copy.deepcopy(model)
    for node in model.graph.node:
        if node.output and "kernel_time" in node.output[0]:
            return None
        if node.output:
            node.name = node.output[0]

    name_map: dict[str, str] = {}
    counter = 0

    def safe(old_name: str) -> str:
        nonlocal counter
        if not old_name or old_name in {"input", "output"}:
            return old_name
        if old_name not in name_map:
            name_map[old_name] = f"safe_name_{counter}"
            counter += 1
        return name_map[old_name]

    for inp in model.graph.input:
        inp.name = safe(inp.name)
    for init in model.graph.initializer:
        init.name = safe(init.name)
    for node in model.graph.node:
        for i, item in enumerate(node.input):
            node.input[i] = safe(item)
        for i, item in enumerate(node.output):
            node.output[i] = safe(item)
        if node.output:
            node.name = node.output[0]
    for out in model.graph.output:
        out.name = safe(out.name)
    for vi in model.graph.value_info:
        vi.name = safe(vi.name)
    for node in model.graph.node:
        if node.output:
            node.name = node.output[0]
    return model


def calculate_params(model: onnx.ModelProto) -> int | None:
    params = 0
    for init in model.graph.initializer:
        if any(d <= 0 for d in init.dims):
            return None
        params += math.prod(init.dims)
    for sparse_init in model.graph.sparse_initializer:
        if any(d <= 0 for d in sparse_init.values.dims):
            return None
        params += math.prod(sparse_init.values.dims)
    for node in model.graph.node:
        if node.op_type != "Constant":
            continue
        for attr in node.attribute:
            if attr.name == "value":
                if any(d <= 0 for d in attr.t.dims):
                    return None
                params += math.prod(attr.t.dims)
            elif attr.name == "sparse_value":
                if any(d <= 0 for d in attr.sparse_tensor.values.dims):
                    return None
                params += math.prod(attr.sparse_tensor.values.dims)
            elif attr.name == "value_floats":
                params += len(attr.floats)
            elif attr.name == "value_ints":
                params += len(attr.ints)
            elif attr.name == "value_strings":
                params += len(attr.strings)
            elif attr.name in {"value_float", "value_int", "value_string"}:
                params += 1
    return params


def calculate_memory(model: onnx.ModelProto, trace_path: str) -> int | None:
    onnx.checker.check_model(model, full_check=True)
    graph = onnx.shape_inference.infer_shapes(model, strict_mode=True).graph
    if len(graph.input) > 1 or len(graph.output) > 1:
        return None
    init_names = {init.name for init in graph.initializer}
    init_names.update(init.name for init in graph.sparse_initializer)
    io_names = {t.name for t in list(graph.input) + list(graph.output)}
    if io_names.intersection(init_names):
        return None
    if model.functions:
        return None
    for opset in model.opset_import:
        if opset.domain not in {"", "ai.onnx"}:
            return None
    node_outputs: dict[str, list[str]] = {}
    tensor_names = set()
    for node in graph.node:
        for attr in node.attribute:
            if attr.type in {onnx.AttributeProto.GRAPH, onnx.AttributeProto.GRAPHS}:
                return None
        node_outputs[node.name] = list(node.output)
        for output_name in node.output:
            if output_name:
                tensor_names.add(output_name)
    tensor_memory: dict[str, int] = {}
    tensor_dtypes: dict[str, np.dtype] = {}
    tensor_map = {t.name: t for t in list(graph.input) + list(graph.value_info) + list(graph.output)}
    tensor_names.update(tensor_map.keys())
    for tensor_name in tensor_names:
        item = tensor_map.get(tensor_name)
        if not item:
            return None
        if item.type.HasField("sequence_type"):
            return None
        if not item.type.HasField("tensor_type"):
            continue
        tensor_type = item.type.tensor_type
        if not tensor_type.HasField("shape"):
            return None
        num_elements = 1
        for dim in tensor_type.shape.dim:
            if dim.HasField("dim_param") or not dim.HasField("dim_value") or dim.dim_value <= 0:
                return None
            num_elements *= dim.dim_value
        if tensor_name in {"input", "output"}:
            continue
        np_dtype = onnx.helper.tensor_dtype_to_np_dtype(tensor_type.elem_type)
        tensor_memory[tensor_name] = num_elements * np.dtype(np_dtype).itemsize
        tensor_dtypes[tensor_name] = np_dtype

    seen = set()
    for item in list(graph.input) + list(graph.value_info) + list(graph.output):
        if item.name in seen:
            return None
        seen.add(item.name)
    for node in graph.node:
        for output_name in node.output:
            if output_name and output_name != "output":
                item = tensor_map.get(output_name)
                if item is None or not item.type.HasField("tensor_type"):
                    return None

    with open(trace_path) as f:
        trace_data = json.load(f)
    for event in trace_data:
        if event.get("cat") != "Node" or "args" not in event:
            continue
        if "output_type_shape" not in event["args"]:
            continue
        node_name = event.get("name", "").replace("_kernel_time", "")
        if node_name not in node_outputs:
            continue
        for i, shape_dict in enumerate(event["args"]["output_type_shape"]):
            if i >= len(node_outputs[node_name]):
                continue
            output_name = node_outputs[node_name][i]
            if output_name not in tensor_dtypes:
                continue
            itemsize = np.dtype(tensor_dtypes[output_name]).itemsize
            mem = itemsize * sum(math.prod(dims) for dims in shape_dict.values())
            tensor_memory[output_name] = max(tensor_memory[output_name], mem)
    return sum(tensor_memory.values())


def make_session(model: onnx.ModelProto, profile_prefix: pathlib.Path | None = None) -> onnxruntime.InferenceSession:
    options = onnxruntime.SessionOptions()
    options.graph_optimization_level = onnxruntime.GraphOptimizationLevel.ORT_DISABLE_ALL
    if profile_prefix is not None:
        options.enable_profiling = True
        options.profile_file_prefix = str(profile_prefix)
    return onnxruntime.InferenceSession(model.SerializeToString(), options)


def run_outputs(model: onnx.ModelProto, examples: list[dict[str, np.ndarray]], profile_prefix: pathlib.Path | None = None) -> tuple[list[np.ndarray], str | None, onnxruntime.InferenceSession]:
    session = make_session(model, profile_prefix)
    outputs = []
    for example in examples:
        result = session.run(["output"], {"input": example["input"]})
        outputs.append(result[0])
    return outputs, None, session


def score_model(model: onnx.ModelProto, examples: list[dict[str, np.ndarray]], tmp_dir: pathlib.Path, prefix: str) -> Score:
    sanitized = sanitize_model(model)
    if sanitized is None:
        raise ValueError("sanitize_model failed")
    for node in sanitized.graph.node:
        if node.op_type.upper() in EXCLUDED_OP_TYPES or "Sequence" in node.op_type:
            raise ValueError(f"excluded op type: {node.op_type}")
    profile_prefix = tmp_dir / prefix
    _, _, session = run_outputs(sanitized, examples, profile_prefix)
    trace_path = session.end_profiling()
    memory = calculate_memory(sanitized, trace_path)
    params = calculate_params(sanitized)
    if memory is None or params is None or memory < 0 or params < 0:
        raise ValueError("network performance could not be measured")
    return Score(memory=memory, params=params)


def validate_candidate(
    base_model: onnx.ModelProto,
    candidate: onnx.ModelProto,
    examples: list[dict[str, np.ndarray]],
    tmp_dir: pathlib.Path,
    task_name: str,
    random_trials: int,
) -> tuple[bool, str, Score | None, Score | None]:
    sanitized_base = sanitize_model(base_model)
    sanitized_candidate = sanitize_model(candidate)
    if sanitized_base is None or sanitized_candidate is None:
        return False, "sanitize failed", None, None
    try:
        # Tensor shapes are static under the competition schema, so one profiled
        # example is sufficient before the exhaustive output comparison.
        profile_examples = examples[:1]
        base_score = score_model(base_model, profile_examples, tmp_dir, f"{task_name}_base")
        candidate_score = score_model(candidate, profile_examples, tmp_dir, f"{task_name}_candidate")
    except Exception as exc:
        return False, f"scoring failed: {exc}", None, None
    if candidate_score.cost >= base_score.cost:
        return False, "no cost improvement", base_score, candidate_score
    try:
        base_outputs, _, base_session = run_outputs(sanitized_base, examples)
        candidate_outputs, _, candidate_session = run_outputs(sanitized_candidate, examples)
    except Exception as exc:
        return False, f"runtime failed: {exc}", None, None
    for left, right in zip(base_outputs, candidate_outputs, strict=True):
        if not np.array_equal(left, right):
            return False, "candidate output differs from base on examples", None, None

    random_exact = 0
    symmetric_failures = 0
    for random_input in random_inputs_for_task(task_num(task_name), random_trials):
        base_result = candidate_result = None
        base_error = candidate_error = None
        try:
            base_result = base_session.run(["output"], {"input": random_input})[0]
        except Exception as exc:
            base_error = exc
        try:
            candidate_result = candidate_session.run(["output"], {"input": random_input})[0]
        except Exception as exc:
            candidate_error = exc
        if base_error is not None or candidate_error is not None:
            if base_error is not None and candidate_error is not None:
                symmetric_failures += 1
                continue
            return False, "candidate and base differ on random-input runtime behavior", None, None
        if not np.array_equal(base_result, candidate_result):
            return False, "candidate output differs from base on random inputs", None, None
        random_exact += 1
    return True, f"random_exact={random_exact};symmetric_failures={symmetric_failures}", base_score, candidate_score


def deterministic_zip_write(zip_path: pathlib.Path, payloads: dict[str, bytes]) -> None:
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for name in sorted(payloads):
            info = zipfile.ZipInfo(name)
            info.date_time = (1980, 1, 1, 0, 0, 0)
            info.compress_type = zipfile.ZIP_DEFLATED
            zf.writestr(info, payloads[name])


def model_bytes(model: onnx.ModelProto) -> bytes:
    return model.SerializeToString()


def process_task(name: str, raw: bytes, tmp_dir: pathlib.Path, random_trials: int) -> tuple[TaskResult, bytes]:
    result = TaskResult(task=name, status="unchanged", base_bytes=len(raw))
    try:
        base_model = onnx.load_from_string(raw)
    except Exception as exc:
        result.status = "error"
        result.message = f"load failed: {exc}"
        return result, raw
    candidate, rewrites = apply_rewrites(base_model)
    candidate_raw = model_bytes(candidate)
    result.candidate_bytes = len(candidate_raw)
    if candidate_raw == raw or not rewrites:
        result.message = "no structural rewrite"
        return result, raw
    result.rewrites = rewrites
    if len(candidate_raw) > FILESIZE_LIMIT_IN_BYTES:
        result.status = "rejected"
        result.message = "candidate exceeds filesize limit"
        return result, raw
    examples = examples_for_task(task_num(name))
    ok, message, base_score, candidate_score = validate_candidate(
        base_model,
        candidate,
        examples,
        tmp_dir,
        name.removesuffix(".onnx"),
        random_trials,
    )
    result.base_score = base_score
    result.candidate_score = candidate_score
    if not ok:
        result.status = "rejected"
        result.message = message
        return result, raw
    if candidate_score is None or base_score is None:
        result.status = "rejected"
        result.message = "missing score"
        return result, raw
    if candidate_score.cost < base_score.cost:
        result.status = "accepted"
        result.message = f"cost improved;{message}"
        return result, candidate_raw
    result.status = "rejected"
    result.message = "no cost improvement"
    return result, raw


def parse_tasks(items: list[str] | None) -> set[str] | None:
    if not items:
        return None
    parsed = set()
    for item in items:
        if item.startswith("task") and item.endswith(".onnx"):
            parsed.add(item)
        else:
            parsed.add(f"task{int(item):03d}.onnx")
    return parsed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-zip", type=pathlib.Path, default=DEFAULT_BASE_ZIP)
    parser.add_argument("--out-dir", type=pathlib.Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--tasks", nargs="*", help="Optional task numbers or taskNNN.onnx names.")
    parser.add_argument("--random-trials", type=int, default=16)
    args = parser.parse_args()

    selected_tasks = parse_tasks(args.tasks)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    report_path = args.out_dir / "rewrite_report.csv"
    manifest_path = args.out_dir / "manifest.json"
    zip_path = args.out_dir / "submission.zip"

    with zipfile.ZipFile(args.base_zip) as zf:
        names = sorted(name for name in zf.namelist() if name.endswith(".onnx") and "/" not in name)
        payloads = {name: zf.read(name) for name in names}
    if len(payloads) != 400:
        raise SystemExit(f"Expected 400 root ONNX files, found {len(payloads)}")

    results: list[TaskResult] = []
    improved_payloads = dict(payloads)
    with tempfile.TemporaryDirectory(prefix="neurogolf_exact_rewrite_") as tmp:
        tmp_dir = pathlib.Path(tmp)
        for name in names:
            if selected_tasks is not None and name not in selected_tasks:
                continue
            print(f"[scan] {name}", flush=True)
            result, chosen_raw = process_task(name, payloads[name], tmp_dir, args.random_trials)
            results.append(result)
            improved_payloads[name] = chosen_raw
            if result.status == "accepted":
                print(
                    f"[accept] {name} cost {result.base_score.cost}->{result.candidate_score.cost} "
                    f"points {result.base_score.points:.6f}->{result.candidate_score.points:.6f}",
                    flush=True,
                )

    accepted = [r for r in results if r.status == "accepted"]
    fieldnames = list(TaskResult("task", "status").to_row().keys())
    with report_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for result in results:
            writer.writerow(result.to_row())

    if accepted:
        deterministic_zip_write(zip_path, improved_payloads)
        with zipfile.ZipFile(zip_path) as zf:
            bad = zf.testzip()
            root_count = len([name for name in zf.namelist() if name.endswith(".onnx") and "/" not in name])
    else:
        bad = None
        root_count = 0

    manifest = {
        "base_zip": str(args.base_zip),
        "base_sha256": hashlib.sha256(args.base_zip.read_bytes()).hexdigest(),
        "out_dir": str(args.out_dir),
        "accepted_count": len(accepted),
        "scanned_count": len(results),
        "accepted_tasks": [r.task for r in accepted],
        "cost_delta": sum((r.candidate_score.cost - r.base_score.cost) for r in accepted if r.base_score and r.candidate_score),
        "point_delta": sum((r.candidate_score.points - r.base_score.points) for r in accepted if r.base_score and r.candidate_score),
        "report": str(report_path),
        "submission_zip": str(zip_path) if accepted else None,
        "zip_testzip": bad,
        "root_onnx_count": root_count,
    }
    if accepted:
        manifest["submission_sha256"] = hashlib.sha256(zip_path.read_bytes()).hexdigest()
        manifest["submission_bytes"] = zip_path.stat().st_size
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
