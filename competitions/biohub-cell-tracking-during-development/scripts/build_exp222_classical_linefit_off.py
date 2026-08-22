#!/usr/bin/env python3
"""Port the line-fit test onto the 0.917 classical three-model stack.

`biohub-exp203-classical-ensemble.ipynb` is our best-scoring notebook (public LB
0.917) and is a STANDALONE classical pipeline - it uses none of the `BIOHUB_*`
env-var machinery, so most of our config-level experiments cannot be ported to
it at all. The line-fit test can, because the stack carries the identical
smoothing formula as a plain module constant:

    LINEFIT_WEIGHT = 0.8
    LINEFIT_WINDOW = 2
    ...
    updates[nid] = (1.0 - LINEFIT_WEIGHT) * orig[nid] + LINEFIT_WEIGHT * fit

and `_linefit()` opens with `if LINEFIT_WEIGHT <= 0: return`, so zeroing the
weight disables it cleanly rather than leaving a partly-applied transform.

Measured on the exp183 stack, that 0.8 pull moves 92.6% of all nodes - median
0.575 um, p99 3.375 um, 8.94% beyond 2 um - against a centroid cliff measured at
sigma ~= 2 um and our own median same-frame cell spacing of 8.135 um.

Ordering note: this run is built now but should NOT be submitted before the
exp183 line-fit pair scores. If smoothing turns out to help there, the
interesting variant here is a reduced weight rather than zero, and the slot is
better spent on that.
"""

from __future__ import annotations

import json
from pathlib import Path

NOTEBOOKS = Path(__file__).resolve().parent.parent / "notebooks"
BASE = NOTEBOOKS / "biohub-exp203-classical-ensemble.ipynb"
BASE_METADATA = NOTEBOOKS / "biohub-exp203-classical-ensemble.kernel-metadata.json"
SLUG = "biohub-exp222-classical-linefit-off"
TITLE = "Biohub Exp222 Classical Linefit Off"


def main() -> None:
    nb = json.loads(BASE.read_text())

    config_index = next(
        i for i, cell in enumerate(nb["cells"])
        if cell["cell_type"] == "code" and "LINEFIT_WEIGHT = 0.8" in "".join(cell["source"])
    )
    source = "".join(nb["cells"][config_index]["source"])
    if source.count("LINEFIT_WEIGHT = 0.8") != 1:
        raise RuntimeError("expected exactly one LINEFIT_WEIGHT assignment")
    source = source.replace(
        "LINEFIT_WEIGHT = 0.8",
        "LINEFIT_WEIGHT = 0.0  # exp222: line-fit smoothing OFF (_linefit early-returns at <= 0)",
        1,
    )
    source = source.replace(
        "EXPERIMENT_TAG = 'exp203_classical_three_model_ensemble'",
        "EXPERIMENT_TAG = 'exp222_classical_three_model_linefit_off'",
        1,
    )
    nb["cells"][config_index]["source"] = source.splitlines(keepends=True)

    # Guard against the constant being read anywhere the early return misses.
    joined = "".join("".join(c["source"]) for c in nb["cells"])
    if "if LINEFIT_WEIGHT <= 0: return" not in joined:
        raise RuntimeError("the _linefit early return is gone; zeroing is no longer safe")

    nb["cells"][0]["source"] = (
        "# Exp222 - Three-Classical-Model Cell Tracking, Line-Fit Smoothing OFF\n"
        "\n"
        "Forked from Exp203 (`biohub-exp203-classical-ensemble`, public LB "
        "`0.917`, our best). One change: `LINEFIT_WEIGHT` `0.8 -> 0.0`, which "
        "makes `_linefit()` return immediately and leaves detected centroids "
        "where the detector put them.\n"
        "\n"
        "The 08-17 public scan measured the centroid precision cliff at "
        "`sigma ~= 2 um` - well inside the 7 um match radius, because matching "
        "is one-to-one and neighbouring cells sit only ~9-10 um apart, so "
        "centroid error makes adjacent cells steal each other's match and costs "
        "an FP and an FN at once. Measured on our own output, this stack's "
        "sibling pipeline moves 92.6% of nodes under the 0.8 weight, 8.94% of "
        "them beyond 2 um.\n"
        "\n"
        "Everything else - the three-model heatmap ensemble, physical NMS, "
        "velocity-aware assignment, gap repair, short-component removal and the "
        "safe-division patch - is unchanged.\n"
    ).splitlines(keepends=True)

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
