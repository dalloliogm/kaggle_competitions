#!/usr/bin/env python3
"""Build and validate reduced-pass variants of the packed task243 flood fill."""

from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import json
import pathlib
import re
import sys
import tempfile
import zipfile

import numpy as np
import onnx
from onnx import numpy_helper

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from exact_rewrite_toolchain import (  # noqa: E402
    GRID_SHAPE,
    apply_rewrites,
    deterministic_zip_write,
    examples_for_task,
    make_session,
    score_model,
)


TASK_NAME = "task243.onnx"
PASS_OUTPUT_RE = re.compile(r"^nf_.*p(?P<pass>\d+)_(?P<row>\d+)_\d+$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-zip", type=pathlib.Path, required=True)
    parser.add_argument("--output-dir", type=pathlib.Path, required=True)
    parser.add_argument("--random-trials", type=int, default=4096)
    parser.add_argument("--stress-trials", type=int, default=4096)
    parser.add_argument(
        "--variants",
        nargs="*",
        help="Evaluate only these named variants after constructing the ladder.",
    )
    parser.add_argument(
        "--accept-monotone-underfill",
        action="store_true",
        help=(
            "Allow stress-only mismatches when they contain no false-positive "
            "paint and differ solely by leaving reachable zeros unchanged."
        ),
    )
    return parser.parse_args()


def board_concat(model: onnx.ModelProto) -> onnx.NodeProto:
    matches = [
        node
        for node in model.graph.node
        if node.op_type == "Concat"
        and len(node.input) == 18
        and any(output.startswith("board_") for output in node.output)
    ]
    if len(matches) != 1:
        raise ValueError(f"expected one 18-row board Concat, found {len(matches)}")
    return matches[0]


def pass_snapshots(model: onnx.ModelProto) -> dict[int, list[str]]:
    latest: dict[tuple[int, int], tuple[int, str]] = {}
    for node_index, node in enumerate(model.graph.node):
        for output in node.output:
            match = PASS_OUTPUT_RE.match(output)
            if match is None:
                continue
            pass_index = int(match.group("pass"))
            row = int(match.group("row"))
            latest[(pass_index, row)] = (node_index, output)

    state: list[str | None] = [None] * 18
    snapshots: dict[int, list[str]] = {}
    for pass_index in range(7):
        for row in range(18):
            item = latest.get((pass_index, row))
            if item is not None:
                state[row] = item[1]
        if any(item is None for item in state):
            missing = [row for row, item in enumerate(state) if item is None]
            raise ValueError(f"pass {pass_index} has unresolved rows: {missing}")
        snapshots[pass_index] = [str(item) for item in state]
    return snapshots


def make_variant(model: onnx.ModelProto, row_outputs: list[str]) -> onnx.ModelProto:
    candidate = copy.deepcopy(model)
    concat = board_concat(candidate)
    del concat.input[:]
    concat.input.extend(row_outputs)
    candidate, _ = apply_rewrites(candidate)
    onnx.checker.check_model(candidate, full_check=True)
    return candidate


def shift_direction(node: onnx.NodeProto) -> bytes | None:
    for attribute in node.attribute:
        if attribute.name == "direction":
            return onnx.helper.get_attribute_value(attribute)
    return None


def other_input(node: onnx.NodeProto, known: str) -> str | None:
    if len(node.input) != 2 or known not in node.input:
        return None
    return node.input[1] if node.input[0] == known else node.input[0]


def replace_left_expansions(model: onnx.ModelProto) -> tuple[onnx.ModelProto, int]:
    """Replace two-step left dilations with exact carry-based row closure."""
    candidate = copy.deepcopy(model)
    nodes = list(candidate.graph.node)
    inserted: dict[int, list[onnx.NodeProto]] = {}
    replacements: dict[str, str] = {}
    count = 0
    for index in range(len(nodes) - 5):
        shift1, and1, or1, shift2, and2, or2 = nodes[index : index + 6]
        if (
            shift1.op_type != "BitShift"
            or shift_direction(shift1) != b"LEFT"
            or and1.op_type != "BitwiseAnd"
            or or1.op_type != "BitwiseOr"
            or shift2.op_type != "BitShift"
            or shift_direction(shift2) != b"LEFT"
            or and2.op_type != "BitwiseAnd"
            or or2.op_type != "BitwiseOr"
            or not shift1.output
            or not and1.output
            or not or1.output
            or not shift2.output
            or not and2.output
            or not or2.output
        ):
            continue
        source = shift1.input[0]
        free = other_input(and1, shift1.output[0])
        if free is None or other_input(or1, and1.output[0]) != source:
            continue
        if shift2.input[0] != or1.output[0]:
            continue
        if other_input(and2, shift2.output[0]) is None:
            continue
        if other_input(or2, and2.output[0]) != or1.output[0]:
            continue

        prefix = f"ff_left_{count}"
        add_output = f"{prefix}_add"
        xor_output = f"{prefix}_xor"
        masked_output = f"{prefix}_masked"
        final_output = f"{prefix}_output"
        inserted[index] = [
            onnx.helper.make_node("Add", [free, source], [add_output], name=add_output),
            onnx.helper.make_node(
                "BitwiseXor", [add_output, free], [xor_output], name=xor_output
            ),
            onnx.helper.make_node(
                "BitwiseAnd", [xor_output, free], [masked_output], name=masked_output
            ),
            onnx.helper.make_node(
                "BitwiseOr", [source, masked_output], [final_output], name=final_output
            ),
        ]
        replacements[or2.output[0]] = final_output
        count += 1

    if not replacements:
        return candidate, 0
    rebuilt: list[onnx.NodeProto] = []
    for index, node in enumerate(nodes):
        rebuilt.extend(inserted.get(index, []))
        rebuilt.append(node)
    del candidate.graph.node[:]
    candidate.graph.node.extend(rebuilt)
    for node in candidate.graph.node:
        for input_index, input_name in enumerate(node.input):
            if input_name in replacements:
                node.input[input_index] = replacements[input_name]
    return candidate, count


def replace_initializer(
    model: onnx.ModelProto, name: str, array: np.ndarray
) -> None:
    for initializer in model.graph.initializer:
        if initializer.name == name:
            initializer.CopyFrom(numpy_helper.from_array(array, name=name))
            return
    raise ValueError(f"initializer not found: {name}")


def reverse_bit_encoding(model: onnx.ModelProto) -> onnx.ModelProto:
    """Reverse packed row bits while preserving the external column order."""
    candidate = copy.deepcopy(model)
    initializers = {
        initializer.name: numpy_helper.to_array(initializer)
        for initializer in candidate.graph.initializer
    }
    replace_initializer(candidate, "convW", initializers["convW"][..., ::-1].copy())
    replace_initializer(candidate, "pow0", initializers["pow0"][..., ::-1].copy())
    replace_initializer(candidate, "pow2", initializers["pow2"][..., ::-1].copy())
    replace_initializer(candidate, "sh8", np.asarray(2, dtype=np.uint32))
    replace_initializer(candidate, "sh16", np.asarray(10, dtype=np.uint32))

    board_output = board_concat(candidate).output[0]
    low_cast = next(
        node
        for node in candidate.graph.node
        if node.op_type == "Cast" and list(node.input) == [board_output]
    )
    high_shift = next(
        node
        for node in candidate.graph.node
        if node.op_type == "BitShift"
        and len(node.input) == 2
        and node.input[0] == board_output
        and node.input[1] == "sh16"
    )
    high_cast = next(
        node
        for node in candidate.graph.node
        if node.op_type == "Cast" and list(node.input) == [high_shift.output[0]]
    )
    mirror_output = "mirror_shift10"
    mirror_shift = onnx.helper.make_node(
        "BitShift",
        [board_output, "sh16"],
        [mirror_output],
        direction="RIGHT",
        name=mirror_output,
    )
    low_cast.input[0] = mirror_output
    high_cast.input[0] = board_output
    index = list(candidate.graph.node).index(low_cast)
    candidate.graph.node.insert(index, mirror_shift)
    return candidate


def build_variants(model: onnx.ModelProto) -> dict[str, onnx.ModelProto]:
    snapshots = pass_snapshots(model)
    final_rows = list(board_concat(model).input)
    pass6 = list(snapshots[6])

    no_row9 = list(final_rows)
    no_row9[9] = pass6[9]

    no_rows5_6 = list(final_rows)
    no_rows5_6[5] = pass6[5]
    no_rows5_6[6] = pass6[6]

    no_tail = list(pass6)
    # Row 17's normal pass-6 completion was retained under a later pass name.
    no_tail[17] = final_rows[17]

    rows_by_name = {
        "drop_row9_correction": no_row9,
        "drop_rows5_6_correction": no_rows5_6,
        "drop_tail_corrections": no_tail,
        "through_pass5": snapshots[5],
        "through_pass4": snapshots[4],
        "through_pass3": snapshots[3],
        "through_pass2": snapshots[2],
    }
    variants = {name: make_variant(model, rows) for name, rows in rows_by_name.items()}

    carry_model, replacement_count = replace_left_expansions(model)
    if replacement_count == 0:
        raise ValueError("no left-expansion chains were found")
    carry_snapshots = pass_snapshots(carry_model)
    carry_final = list(board_concat(carry_model).input)
    variants["carry_full_graph"] = make_variant(carry_model, carry_final)
    for pass_index in (5, 4, 3, 2):
        variants[f"carry_through_pass{pass_index}"] = make_variant(
            carry_model, carry_snapshots[pass_index]
        )

    mirror_model = reverse_bit_encoding(model)
    mirror_final = list(board_concat(mirror_model).input)
    variants["mirror_graph"] = make_variant(mirror_model, mirror_final)
    mirror_carry_model, mirror_replacement_count = replace_left_expansions(mirror_model)
    if mirror_replacement_count != replacement_count:
        raise ValueError(
            "normal and mirrored graphs exposed different expansion counts: "
            f"{replacement_count} != {mirror_replacement_count}"
        )
    mirror_carry_snapshots = pass_snapshots(mirror_carry_model)
    mirror_carry_final = list(board_concat(mirror_carry_model).input)
    variants["mirror_carry_full_graph"] = make_variant(
        mirror_carry_model, mirror_carry_final
    )
    variants["mirror_carry_through_pass5"] = make_variant(
        mirror_carry_model, mirror_carry_snapshots[5]
    )
    return variants


def random_input(rng: np.random.Generator) -> np.ndarray:
    height = int(rng.integers(1, 19))
    width = int(rng.integers(1, 19))
    colors = rng.integers(0, 10, size=(height, width))
    result = np.zeros(GRID_SHAPE, dtype=np.float32)
    rows = np.arange(height)[:, None]
    cols = np.arange(width)[None, :]
    result[0, colors, rows, cols] = 1.0
    return result


def stress_input(rng: np.random.Generator) -> np.ndarray:
    height = int(rng.integers(8, 19))
    width = int(rng.integers(8, 19))
    free_probability = float(rng.uniform(0.25, 0.95))
    seed_probability = float(rng.uniform(0.005, 0.35))
    free = rng.random((height, width)) < free_probability
    seeds = free & (rng.random((height, width)) < seed_probability)
    if not seeds.any() and free.any():
        row, col = np.argwhere(free)[int(rng.integers(int(free.sum())))]
        seeds[row, col] = True
    colors = rng.integers(2, 10, size=(height, width))
    colors[free] = 0
    colors[seeds] = 1
    result = np.zeros(GRID_SHAPE, dtype=np.float32)
    rows = np.arange(height)[:, None]
    cols = np.arange(width)[None, :]
    result[0, colors, rows, cols] = 1.0
    return result


def flood_expected(input_array: np.ndarray) -> np.ndarray:
    free = (input_array[0, 0] > 0) | (input_array[0, 1] > 0)
    reached = input_array[0, 1] > 0
    while True:
        neighbors = reached.copy()
        neighbors[1:] |= reached[:-1]
        neighbors[:-1] |= reached[1:]
        neighbors[:, 1:] |= reached[:, :-1]
        neighbors[:, :-1] |= reached[:, 1:]
        updated = neighbors & free
        if np.array_equal(updated, reached):
            break
        reached = updated
    paint = reached & (input_array[0, 0] > 0)
    output = input_array.copy()
    for channel in range(output.shape[1]):
        output[0, channel][paint] = 0.0
    output[0, 1][paint] = 1.0
    return output


def compare_session(
    candidate_session,
    inputs: list[np.ndarray],
    expected_outputs: list[np.ndarray] | None = None,
) -> dict[str, int]:
    exact = 0
    first_mismatch = -1
    false_positive_cells = 0
    false_negative_cells = 0
    non_monotone_cases = 0
    for index, input_array in enumerate(inputs):
        candidate_output = candidate_session.run(["output"], {"input": input_array})[0]
        expected = (
            expected_outputs[index]
            if expected_outputs is not None
            else flood_expected(input_array)
        )
        if np.array_equal(expected, candidate_output):
            exact += 1
            continue
        if first_mismatch < 0:
            first_mismatch = index
        expected_paint = expected[0, 1] > 0
        candidate_paint = candidate_output[0, 1] > 0
        false_positive_cells += int((candidate_paint & ~expected_paint).sum())
        missing = expected_paint & ~candidate_paint
        false_negative_cells += int(missing.sum())
        allowed = expected.copy()
        for channel in range(allowed.shape[1]):
            allowed[0, channel][missing] = input_array[0, channel][missing]
        if not np.array_equal(allowed, candidate_output):
            non_monotone_cases += 1
    return {
        "exact": exact,
        "first_mismatch": first_mismatch,
        "false_positive_cells": false_positive_cells,
        "false_negative_cells": false_negative_cells,
        "non_monotone_cases": non_monotone_cases,
    }


def package_candidate(
    base_zip: pathlib.Path,
    model: onnx.ModelProto,
    output_path: pathlib.Path,
) -> str:
    with zipfile.ZipFile(base_zip) as archive:
        payloads = {name: archive.read(name) for name in archive.namelist()}
    payloads[TASK_NAME] = model.SerializeToString()
    deterministic_zip_write(output_path, payloads)
    return hashlib.sha256(output_path.read_bytes()).hexdigest()


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.base_zip) as archive:
        base_model = onnx.load_model_from_string(archive.read(TASK_NAME))

    examples = examples_for_task(243)
    example_inputs = [example["input"] for example in examples]
    example_outputs = [example["output"] for example in examples]
    rng = np.random.default_rng(20260713)
    random_inputs = [random_input(rng) for _ in range(args.random_trials)]
    stress_inputs = [stress_input(rng) for _ in range(args.stress_trials)]
    variants = build_variants(base_model)
    if args.variants:
        unknown = sorted(set(args.variants) - set(variants))
        if unknown:
            raise ValueError(f"unknown variants: {unknown}")
        variants = {name: variants[name] for name in args.variants}

    rows: list[dict[str, object]] = []
    accepted: list[tuple[int, str, onnx.ModelProto, dict[str, object]]] = []
    with tempfile.TemporaryDirectory(prefix="task243-pruner-") as tmp:
        tmp_dir = pathlib.Path(tmp)
        base_score = score_model(base_model, examples[:1], tmp_dir, "base")
        for name, candidate in variants.items():
            candidate_session = make_session(candidate)
            example_result = compare_session(
                candidate_session, example_inputs, example_outputs
            )
            random_result = {
                "exact": 0,
                "first_mismatch": -1,
                "false_positive_cells": 0,
                "false_negative_cells": 0,
                "non_monotone_cases": 0,
            }
            stress_result = dict(random_result)
            if example_result["first_mismatch"] < 0:
                random_result = compare_session(
                    candidate_session, random_inputs
                )
            if (
                example_result["first_mismatch"] < 0
                and random_result["first_mismatch"] < 0
            ):
                stress_result = compare_session(
                    candidate_session, stress_inputs
                )
            candidate_score = score_model(
                candidate, examples[:1], tmp_dir, name
            )
            stress_allowed = stress_result["first_mismatch"] < 0 or (
                args.accept_monotone_underfill
                and stress_result["false_positive_cells"] == 0
                and stress_result["non_monotone_cases"] == 0
            )
            accepted_by_gate = (
                example_result["first_mismatch"] < 0
                and random_result["first_mismatch"] < 0
                and stress_allowed
                and candidate_score.cost < base_score.cost
            )
            row = {
                "variant": name,
                "accepted": accepted_by_gate,
                "bytes": len(candidate.SerializeToString()),
                "nodes": len(candidate.graph.node),
                "base_cost": base_score.cost,
                "candidate_cost": candidate_score.cost,
                "cost_delta": candidate_score.cost - base_score.cost,
                "point_delta": candidate_score.points - base_score.points,
                "example_exact": example_result["exact"],
                "example_total": len(example_inputs),
                "example_first_mismatch": example_result["first_mismatch"],
                "random_exact": random_result["exact"],
                "random_total": len(random_inputs),
                "random_first_mismatch": random_result["first_mismatch"],
                "stress_exact": stress_result["exact"],
                "stress_total": len(stress_inputs),
                "stress_first_mismatch": stress_result["first_mismatch"],
                "stress_false_positive_cells": stress_result[
                    "false_positive_cells"
                ],
                "stress_false_negative_cells": stress_result[
                    "false_negative_cells"
                ],
                "stress_non_monotone_cases": stress_result[
                    "non_monotone_cases"
                ],
            }
            rows.append(row)
            if accepted_by_gate:
                accepted.append((candidate_score.cost, name, candidate, row))
            print(json.dumps(row, sort_keys=True))

    report_path = args.output_dir / "pruning_report.csv"
    with report_path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    manifest: dict[str, object] = {
        "base_zip": str(args.base_zip),
        "task": TASK_NAME,
        "base_cost": base_score.cost,
        "random_trials": args.random_trials,
        "stress_trials": args.stress_trials,
        "accept_monotone_underfill": args.accept_monotone_underfill,
        "variants": rows,
        "selected": None,
    }
    if accepted:
        _, name, candidate, row = min(accepted, key=lambda item: item[0])
        model_path = args.output_dir / TASK_NAME
        onnx.save_model(candidate, model_path)
        zip_path = args.output_dir / "submission.zip"
        digest = package_candidate(args.base_zip, candidate, zip_path)
        manifest["selected"] = {
            **row,
            "submission_zip": str(zip_path),
            "sha256": digest,
        }
    (args.output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    )


if __name__ == "__main__":
    main()
