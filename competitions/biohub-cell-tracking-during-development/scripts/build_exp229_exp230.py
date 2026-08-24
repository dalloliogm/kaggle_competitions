#!/usr/bin/env python3
"""Tighten division precision on the 0.918 backbone.

exp227 scored 0.918 while retaining **456 divisions**. Ground truth runs about
one division per 853 links (151 across all 199 training movies), which for our
~119k edges implies roughly **139**. We are proposing ~3x the natural rate, and
this workspace has prior evidence that over-proposing costs score: exp155
doubled the budget and lost, exp158's veto-everything run scored 0.905, and
exp220 gained 0.916 -> only after the veto removed 67 proposals.

So 456 is the flagged risk on our best submission, and it has two independent
knobs, neither tested on this backbone:

exp229 - **budget**. Halve the frame and global fraction caps
(`0.0076 -> 0.0038`, `0.00375 -> 0.001875`). This keeps the admission geometry
and filters intact and simply takes fewer of the ranked proposals. Note exp159
ran the same halving on the OLD pre-ranker backbone and tied; the backbone and
the candidate set are both different now.

exp230 - **divergence margin**. `SAFE_DIV_DIVERGE_UM 1.5 -> 2.25`. The public
recipe's own annotation says 2.25 was "carried over from 0.917 which operates
at a much wider base radius" and was reduced to 1.5 for their scale. Our base
radius differs again, so the stricter margin is untested here. This rejects on
evidence - daughters that fail to separate - rather than on quota.

The pair separates "fewer divisions" from "better-chosen divisions", which is
the distinction exp220 already showed matters: quota-based cuts tied, while an
evidence-based cut gained.
"""

from __future__ import annotations

import json
from pathlib import Path

NOTEBOOKS = Path(__file__).resolve().parent.parent / "notebooks"
BASE = NOTEBOOKS / "biohub-exp227-divergence-mutualnn-wide.ipynb"
BASE_METADATA = NOTEBOOKS / "biohub-exp227-divergence-mutualnn-wide.kernel-metadata.json"


def cell_index(nb: dict, needle: str) -> int:
    for index, cell in enumerate(nb["cells"]):
        if cell["cell_type"] == "code" and needle in "".join(cell["source"]):
            return index
    raise RuntimeError(f"no code cell containing {needle!r}")


def assert_unguarded(nb: dict, keys: list[str]) -> None:
    for cell in nb["cells"]:
        source = "".join(cell["source"])
        if "_expected_numeric" not in source:
            continue
        clashes = [key for key in keys if f'"{key}"' in source]
        if clashes:
            raise RuntimeError(f"strategy guard freezes {clashes}; repoint it first")
        return
    raise RuntimeError("strategy guard cell not found - base changed?")


def set_env(config: str, key: str, value: str) -> str:
    matches = [l for l in config.splitlines() if l.startswith(f'os.environ["{key}"]')]
    if len(matches) != 1:
        raise RuntimeError(f"{key}: expected one assignment, found {len(matches)}")
    return config.replace(matches[0], f'os.environ["{key}"] = {value}', 1)


def build(slug: str, title: str, preset: str, axis: str,
          env: tuple[tuple[str, str], ...], heading: str, body: str) -> None:
    nb = json.loads(BASE.read_text())
    assert_unguarded(nb, [key for key, _ in env])

    index = cell_index(nb, "BIOHUB_PRESET")
    config = "".join(nb["cells"][index]["source"])
    for key, value in env:
        config = set_env(config, key, value)
    for name, value in (("BIOHUB_PRESET", preset), ("BIOHUB_SCORE_AXIS", axis)):
        line = [l for l in config.splitlines() if l.startswith(name)]
        if len(line) != 1:
            raise RuntimeError(f"expected one {name} line")
        config = config.replace(line[0], f"{name} = {value!r}", 1)
    nb["cells"][index]["source"] = config.splitlines(keepends=True)
    nb["cells"][1]["source"] = (heading + "\n\n" + body + "\n").splitlines(keepends=True)

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
    "Forked from Exp227 (public LB `0.918`, our best). Exp227 retains **456 "
    "divisions**, while ground truth runs about one division per 853 links - "
    "roughly **139** for our edge count. A false fork costs twice, as an FP edge "
    "and an FP fork, so over-proposal is the open risk on the current best."
)


def main() -> None:
    build(
        slug="biohub-exp229-safediv-half-budget",
        title="Biohub Exp229 Safediv Half Budget",
        preset="safe_division_half_budget_on_0918",
        axis=("exp227 backbone (0.918) with the safe-division frame and global "
              "fraction caps halved - fewer proposals, same geometry and filters"),
        env=(("BIOHUB_SAFE_DIV_FRAME_FRAC_CAP", '"0.0038"'),
             ("BIOHUB_SAFE_DIV_GLOBAL_FRAC_CAP", '"0.001875"')),
        heading="# Biohub Exp229: Half Safe-Division Budget on the 0.918 Backbone",
        body=(SHARED + "\n\nThis halves the budget caps (`0.0076 -> 0.0038` and "
              "`0.00375 -> 0.001875`) and changes nothing else: the widened "
              "geometry, the mutual-NN and divergence filters, and the centre-prior "
              "veto all stay as they are. It takes fewer of the same ranked "
              "proposals.\n\nExp159 ran this same halving on the old pre-ranker "
              "backbone and tied. Both the backbone and the candidate set are "
              "different now, and Exp220 showed the distinction that matters: a "
              "quota-based cut tied, while an evidence-based cut gained.")
    )
    build(
        slug="biohub-exp230-diverge-margin-225",
        title="Biohub Exp230 Diverge Margin 225",
        preset="safe_division_diverge_margin_225",
        axis=("exp227 backbone (0.918) with SAFE_DIV_DIVERGE_UM 1.5 -> 2.25 - a "
              "stricter forward-divergence requirement, rejecting on evidence "
              "rather than quota"),
        env=(("BIOHUB_SAFE_DIV_DIVERGE_UM", '"2.25"'),),
        heading="# Biohub Exp230: Stricter Forward-Divergence Margin",
        body=(SHARED + "\n\nThis raises the divergence margin from `1.5 µm` to "
              "`2.25 µm`: the two grandchildren must separate further, relative to "
              "how far apart the sisters are now, before a division is admitted. "
              "Where Exp229 takes fewer proposals by quota, this one rejects the "
              "proposals whose daughters do not actually move apart.\n\nThe public "
              "recipe's own annotation records `2.25` as the value carried over "
              "from a stack with a much wider base radius, reduced to `1.5` for "
              "their scale. Our base radius differs again, so the stricter margin "
              "has never been tested here.")
    )


if __name__ == "__main__":
    main()
