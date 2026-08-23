#!/usr/bin/env python3
"""Test the widened safe-division geometry that separates the public 0.923 from 0.920.

The 2026-08-23 scan attributed the 42-team `0.923` cluster to
`yunusgmsoy/kimi-notebook-v17` / `kunaldesale2408/biohub-cell-tracking` - the same
recipe published from two accounts, verified by diffing their `BIOHUB_*` blocks
(35 keys, byte-identical). Against the `0.920` recipe it moves exactly three
keys, all of them the safe-division admission geometry:

    SAFE_DIV_MAX_UM             4.66 -> 12.0
    SAFE_DIV_SISTER_MAX_UM       8.5 -> 15.0
    SAFE_DIV_EXISTING_CHILD_MAX_UM 7.65 -> 10.0

Roughly 2.5x on the parent gate. This workspace closed the division-geometry
axis in early August, but only ever tested tightening and one small widening
(`7.0`, which lost a thousandth); `12.0` is far outside anything tried here.

Two runs, completing a 2x2 against results we already hold, so a gain can be
attributed rather than assumed:

    | geometry \\ DeepCenter | veto off        | best.pt + safe-div veto |
    | narrow (4.66/8.5/7.65) | exp183   0.915  | exp220   0.916          |
    | wide   (12.0/15.0/10.0)| exp224          | exp223                  |

exp223 forks exp220 and exp224 forks exp183, so each is one factor from a
scored corner. The two mechanisms act on the same stage - widening ADMITS more
division candidates while the veto REJECTS them on image evidence - so the
interaction is the interesting cell, not an afterthought.
"""

from __future__ import annotations

import json
from pathlib import Path

NOTEBOOKS = Path(__file__).resolve().parent.parent / "notebooks"

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


def assert_unguarded(nb: dict, keys: list[str]) -> None:
    """The inherited strategy guard freezes a key list; fail if we touch it."""
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
    matches = [
        line for line in config.splitlines()
        if line.startswith(f'os.environ["{key}"]')
    ]
    if len(matches) != 1:
        raise RuntimeError(f"{key}: expected one assignment, found {len(matches)}")
    return config.replace(matches[0], f'os.environ["{key}"] = {value}', 1)


def build(base_name: str, slug: str, title: str, preset: str, axis: str,
          heading: str, body: str) -> None:
    base = NOTEBOOKS / f"{base_name}.ipynb"
    nb = json.loads(base.read_text())
    assert_unguarded(nb, [key for key, _ in WIDE_GEOMETRY])

    config_index = cell_index(nb, "BIOHUB_PRESET")
    config = "".join(nb["cells"][config_index]["source"])
    for key, value in WIDE_GEOMETRY:
        config = set_env(config, key, value)
    for name, value in (("BIOHUB_PRESET", preset), ("BIOHUB_SCORE_AXIS", axis)):
        line = [l for l in config.splitlines() if l.startswith(name)]
        if len(line) != 1:
            raise RuntimeError(f"expected one {name} line")
        config = config.replace(line[0], f"{name} = {value!r}", 1)
    set_cell_source(nb, config_index, config)
    set_cell_source(nb, 1, heading + "\n\n" + body + "\n")

    out = NOTEBOOKS / f"{slug}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")

    metadata = json.loads((NOTEBOOKS / f"{base_name}.kernel-metadata.json").read_text())
    metadata["id"] = f"dalloliogm/{slug}"
    metadata["title"] = title
    metadata["code_file"] = out.name
    (NOTEBOOKS / f"{slug}.kernel-metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n"
    )
    print(f"wrote {out.name} (from {base_name})")


SHARED = (
    "The public `0.923` cluster differs from the `0.920` recipe by exactly three "
    "keys, all safe-division admission geometry: `SAFE_DIV_MAX_UM` "
    "`4.66 -> 12.0`, `SAFE_DIV_SISTER_MAX_UM` `8.5 -> 15.0`, and "
    "`SAFE_DIV_EXISTING_CHILD_MAX_UM` `7.65 -> 10.0`. This workspace closed the "
    "division-geometry axis in early August, but only tested tightening and one "
    "small widening (`7.0`, which lost a thousandth) - `12.0` is far outside "
    "anything tried here."
)


def main() -> None:
    build(
        base_name="biohub-exp220-deepcenter-best-safediv-veto",
        slug="biohub-exp223-wide-safediv-with-veto",
        title="Biohub Exp223 Wide Safediv With Veto",
        preset="wide_safe_div_geometry_with_deepcenter_veto",
        axis=(
            "exp220 (DeepCenter best.pt + safe-division veto, 0.916) with the "
            "public 0.923 safe-division geometry 12.0/15.0/10.0"
        ),
        heading="# Biohub Exp223: Wide Safe-Division Geometry + DeepCenter Veto",
        body=(
            "Forked from Exp220 (public LB `0.916`, our best on the Exp183 base). "
            + SHARED
            + "\n\nThis is the interaction cell: widening ADMITS more division "
            "candidates while the DeepCenter veto REJECTS them on image "
            "evidence, so the two act on the same stage. Paired with Exp224, "
            "which applies the same widening without the veto."
        ),
    )
    build(
        base_name="biohub-exp183-public-ranker-fork",
        slug="biohub-exp224-wide-safediv-no-veto",
        title="Biohub Exp224 Wide Safediv No Veto",
        preset="wide_safe_div_geometry_only",
        axis=(
            "exp183 (0.915) with only the public 0.923 safe-division geometry "
            "12.0/15.0/10.0 - isolates the widening from the DeepCenter veto"
        ),
        heading="# Biohub Exp224: Wide Safe-Division Geometry Only",
        body=(
            "Forked from Exp183 (public LB `0.915`). " + SHARED
            + "\n\nThis isolates the widening. With Exp183 (`0.915`, narrow, no "
            "veto) and Exp220 (`0.916`, narrow, veto) already scored, Exp223 and "
            "Exp224 complete a 2x2 and make any gain attributable to the "
            "geometry, the veto, or their interaction."
        ),
    )


if __name__ == "__main__":
    main()
