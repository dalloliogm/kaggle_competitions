#!/usr/bin/env python3
"""Push the line-fit weight ABOVE the shipped 0.8, where the bracket points.

The 2026-08-22 bracket came back monotone and opposite to its hypothesis:

    LINEFIT_WEIGHT 0.0 -> 0.906     0.4 -> 0.910     0.8 (shipped) -> 0.915

Smoothing corrects detector jitter far more than it displaces true centroids,
and nothing above 0.8 has ever been tested on any stack. The gradient across the
measured range is about +0.005 per 0.4 of weight, so 0.9 and 1.0 bracket the top
of the axis; 1.0 replaces each coordinate with the local line fit entirely.

Base is exp220 (0.916, DeepCenter best.pt + safe-division veto) rather than
exp183 (0.915), so a gain compounds with the one we already hold. That does
change the base from the original bracket - noted deliberately - but the two
mechanisms act on different stages: the veto is a division-admission change and
line-fit is an output-stage coordinate transform.

`OUTPUT_LINEFIT_WEIGHT` IS frozen by the inherited strategy guard (this is what
made exp204 v1 error), so the guard expectation moves with the value. Everything
else stays frozen.
"""

from __future__ import annotations

import json
from pathlib import Path

NOTEBOOKS = Path(__file__).resolve().parent.parent / "notebooks"
BASE = NOTEBOOKS / "biohub-exp220-deepcenter-best-safediv-veto.ipynb"
BASE_METADATA = NOTEBOOKS / "biohub-exp220-deepcenter-best-safediv-veto.kernel-metadata.json"


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


def build(weight: str, slug: str, title: str, note: str) -> None:
    nb = json.loads(BASE.read_text())

    guard_index = cell_index(nb, "_expected_numeric")
    guard = "".join(nb["cells"][guard_index]["source"])
    guard = replace_once(
        guard,
        '"OUTPUT_LINEFIT_WEIGHT": 0.8,',
        f'"OUTPUT_LINEFIT_WEIGHT": {weight},',
        "guard OUTPUT_LINEFIT_WEIGHT",
    )
    set_cell_source(nb, guard_index, guard)

    config_index = cell_index(nb, "BIOHUB_PRESET")
    config = "".join(nb["cells"][config_index]["source"])
    if "BIOHUB_OUTPUT_LINEFIT_WEIGHT" in config:
        raise RuntimeError("base already sets the weight; re-check before editing")
    config = replace_once(
        config,
        '\nprint("BIOHUB_PRESET:", BIOHUB_PRESET)',
        f'\nos.environ["BIOHUB_OUTPUT_LINEFIT_WEIGHT"] = "{weight}"'
        f'\nprint("BIOHUB_PRESET:", BIOHUB_PRESET)',
        "linefit env",
    )
    for name, value in (
        ("BIOHUB_PRESET", f"linefit_weight_{weight.replace('.', '')}"),
        ("BIOHUB_SCORE_AXIS",
         f"exp220 backbone (0.916) with output line-fit weight 0.8 -> {weight}; "
         "the 08-22 bracket was monotone in the weight and nothing above 0.8 has been tested"),
    ):
        line = [l for l in config.splitlines() if l.startswith(name)]
        if len(line) != 1:
            raise RuntimeError(f"expected one {name} line")
        config = config.replace(line[0], f"{name} = {value!r}", 1)
    set_cell_source(nb, config_index, config)

    set_cell_source(
        nb, 1,
        f"# Biohub {title.split()[1]}: Line-Fit Weight {weight}\n\n"
        f"Forked from Exp220 (public LB `0.916`). One change: "
        f"`BIOHUB_OUTPUT_LINEFIT_WEIGHT` `0.8 -> {weight}`.\n\n"
        "The 2026-08-22 bracket measured `0.0 -> 0.906`, `0.4 -> 0.910`, "
        "`0.8 -> 0.915`: monotone in the weight, and opposite to the "
        "centroid-cliff hypothesis that motivated it. Smoothing corrects "
        "detector jitter far more than it displaces true centroids, and **no "
        "weight above 0.8 has ever been tested on any stack**.\n\n"
        f"{note}\n\n"
        "The inherited strategy guard freezes `OUTPUT_LINEFIT_WEIGHT`, so its "
        "expectation moves with the value; every other key stays frozen.\n",
    )

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


if __name__ == "__main__":
    build("0.9", "biohub-exp225-linefit-weight-090", "Biohub Exp225 Linefit Weight 090",
          "One step past the shipped value, paired with Exp226 at the extreme.")
    build("1.0", "biohub-exp226-linefit-weight-100", "Biohub Exp226 Linefit Weight 100",
          "The extreme: each coordinate is replaced by its local line fit entirely, "
          "with no original position retained. If the axis has an interior optimum "
          "this is the point that finds it.")
