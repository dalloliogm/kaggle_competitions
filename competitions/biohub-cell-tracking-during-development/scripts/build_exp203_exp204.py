#!/usr/bin/env python3
"""Build the line-fit smoothing bracket from the exp183 public fork (0.915).

The 08-17 scan measured the centroid precision cliff at sigma ~= 2 um, not the
7 um match radius: matching is one-to-one and neighbouring cells sit ~9-10 um
apart, so centroid error makes adjacent cells steal each other's match, paying
an FP and an FN at once. 2.5 um costs 16%, 3 um costs 41%, 4 um costs 74%.

Our output stage is the only place the pipeline deliberately moves coordinates:

    q_out = (1 - w) * q_i + w * q_line     with w = 0.8, window = +-2

That is an 80% pull of every node in every linear track toward a fitted line,
and it has never been measured on the leaderboard by itself on any backbone
(exp171b ablated it locally only, against a harness the same scan suggests is
leaking at the cell level).

Two points rather than one, because a single point cannot distinguish "smoothing
is harmful" from "smoothing helps but is tuned too strong":

    exp203  BIOHUB_OUTPUT_LINEFIT_SMOOTH=0   smoothing off entirely
    exp204  BIOHUB_OUTPUT_LINEFIT_WEIGHT=0.4 half the pull, smoothing still on

Both fork exp183 (the public stack forked verbatim, public LB 0.915) so the only
moving part is the coordinate treatment.
"""

from __future__ import annotations

import json
from pathlib import Path

NOTEBOOKS = Path(__file__).resolve().parent.parent / "notebooks"
BASE = NOTEBOOKS / "biohub-exp183-public-ranker-fork.ipynb"
BASE_METADATA = NOTEBOOKS / "biohub-exp183-public-ranker-fork.kernel-metadata.json"
CONFIG_CELL = 4


def cell_source(nb: dict, index: int) -> str:
    return "".join(nb["cells"][index]["source"])


def set_cell_source(nb: dict, index: int, text: str) -> None:
    nb["cells"][index]["source"] = text.splitlines(keepends=True)


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def repoint_strategy_guard(nb: dict, key: str, old: str, new: str) -> None:
    """Move the inherited drift guard's expectation for ONE key.

    exp183 carries the public notebook's strategy guard, which asserts a frozen
    config and raises `Biohub 159B contains an unintended extra change` on any
    deviation. `OUTPUT_LINEFIT_WEIGHT: 0.8` is one of its expectations, which is
    exactly why the first exp204 attempt ERRORED while exp203 ran fine:
    `OUTPUT_LINEFIT_SMOOTH` is not in the guarded set, `OUTPUT_LINEFIT_WEIGHT`
    is.

    The guard exists to catch UNintended drift, so the right handling of a
    deliberate one-factor change is to move the expectation to the intended
    value, not to disable the check. Every other key stays guarded, so the run
    still fails loudly if anything else moves.
    """
    for index, cell in enumerate(nb["cells"]):
        source = "".join(cell["source"])
        if "_expected_numeric" not in source or key not in source:
            continue
        set_cell_source(nb, index, replace_once(source, old, new, f"guard {key}"))
        return
    raise RuntimeError(f"strategy guard cell holding {key} not found")


def build(slug: str, title: str, preset: str, axis: str,
          env_lines: str, heading: str, body: str,
          guard: tuple[str, str, str] | None = None) -> None:
    nb = json.loads(BASE.read_text())
    if guard is not None:
        repoint_strategy_guard(nb, *guard)
    config = cell_source(nb, CONFIG_CELL)

    if "LINEFIT" in config:
        raise RuntimeError("exp183 already sets a LINEFIT key; re-check the base")

    # Anchor on the preset assignment so the new keys sit with the rest of the
    # configuration rather than after the print statements.
    old_preset = [
        line for line in config.splitlines() if line.startswith("BIOHUB_PRESET")
    ]
    if len(old_preset) != 1:
        raise RuntimeError("expected exactly one BIOHUB_PRESET line")
    config = replace_once(
        config, old_preset[0], f"BIOHUB_PRESET = {preset!r}", "preset"
    )

    old_axis = [
        line for line in config.splitlines() if line.startswith("BIOHUB_SCORE_AXIS")
    ]
    if len(old_axis) != 1:
        raise RuntimeError("expected exactly one BIOHUB_SCORE_AXIS line")
    config = replace_once(
        config, old_axis[0], f"BIOHUB_SCORE_AXIS = {axis!r}", "score axis"
    )

    config = replace_once(
        config,
        '\nprint("BIOHUB_PRESET:", BIOHUB_PRESET)',
        f"\n{env_lines}\nprint(\"BIOHUB_PRESET:\", BIOHUB_PRESET)",
        "linefit env",
    )
    set_cell_source(nb, CONFIG_CELL, config)
    set_cell_source(nb, 1, heading + "\n\n" + body + "\n")

    out = NOTEBOOKS / f"{slug}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")

    metadata = json.loads(BASE_METADATA.read_text())
    metadata["id"] = f"dalloliogm/{slug}"
    metadata["title"] = title
    metadata["code_file"] = out.name
    (NOTEBOOKS / f"{slug}.kernel-metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n"
    )
    print(f"wrote {out.name}")


SHARED = (
    "The 08-17 scan measured the centroid precision cliff at `sigma ~= 2 um`, "
    "well inside the 7 um match radius, because matching is one-to-one and "
    "neighbouring cells are only ~9-10 um apart - centroid error makes adjacent "
    "cells steal each other's match, costing an FP and an FN at once. Line-fit "
    "smoothing is the only place this pipeline deliberately moves coordinates, "
    "and it has never been measured on the leaderboard by itself."
)


def main() -> None:
    build(
        slug="biohub-exp203-linefit-off",
        title="Biohub Exp203 Linefit Off",
        preset="linefit_smoothing_off",
        axis=(
            "exp183 public fork unchanged; disable output line-fit smoothing "
            "entirely (BIOHUB_OUTPUT_LINEFIT_SMOOTH=0) to measure the coordinate "
            "displacement against the 2um centroid cliff"
        ),
        env_lines='os.environ["BIOHUB_OUTPUT_LINEFIT_SMOOTH"] = "0"',
        heading="# Biohub Exp203: Line-Fit Smoothing Off",
        body=(
            "Forked from Exp183 (the public stack forked verbatim, public LB "
            "`0.915`). One change: `BIOHUB_OUTPUT_LINEFIT_SMOOTH=0`.\n\n"
            + SHARED
            + "\n\nThe vendored default pulls every node in every linear track "
            "80% toward a line fitted over its two neighbours on each side "
            "(`weight 0.8`, `window 2`). This run removes that pull completely. "
            "Paired with Exp204, which halves it instead."
        ),
    )
    build(
        slug="biohub-exp204-linefit-weight-040",
        title="Biohub Exp204 Linefit Weight 040",
        preset="linefit_smoothing_weight_040",
        axis=(
            "exp183 public fork unchanged; halve the output line-fit smoothing "
            "pull (BIOHUB_OUTPUT_LINEFIT_WEIGHT 0.8 -> 0.4) - the interior point "
            "of the bracket whose endpoint is exp203"
        ),
        env_lines='os.environ["BIOHUB_OUTPUT_LINEFIT_WEIGHT"] = "0.4"',
        heading="# Biohub Exp204: Line-Fit Smoothing at Half Weight",
        body=(
            "Forked from Exp183 (public LB `0.915`). One change: "
            "`BIOHUB_OUTPUT_LINEFIT_WEIGHT` `0.8 -> 0.4`; smoothing stays on.\n\n"
            + SHARED
            + "\n\nThis is the interior point of the bracket. Exp203 removes "
            "smoothing entirely; a single point cannot distinguish *smoothing is "
            "harmful* from *smoothing helps but is tuned too strong*, and these "
            "two together can.\n\n"
            "**Version 2.** Version 1 errored on the inherited strategy guard, "
            "which lists `OUTPUT_LINEFIT_WEIGHT: 0.8` among the values it freezes "
            "(`OUTPUT_LINEFIT_SMOOTH` is not in that set, which is why Exp203 ran "
            "unmodified). The guard's expectation for this one key now points at "
            "`0.4`; every other key stays frozen, so an unintended change still "
            "fails the run."
        ),
        guard=(
            "OUTPUT_LINEFIT_WEIGHT",
            '"OUTPUT_LINEFIT_WEIGHT": 0.8,',
            '"OUTPUT_LINEFIT_WEIGHT": 0.4,',
        ),
    )


if __name__ == "__main__":
    main()
