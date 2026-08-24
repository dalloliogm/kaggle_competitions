#!/usr/bin/env python3
"""Prepare the 0.918 notebook for publication. Markdown only - no code changes.

The notebook is verified at public LB 0.918 (submission 55724576). Editing any
code cell would invalidate that provenance and cost an hour to re-run, so this
script touches only markdown, plus `is_private` in the metadata (left TRUE here;
publication is a separate, deliberate act).

Three kinds of change:

1. **A public-facing introduction.** The current cell 1 is an internal
   experiment log - it opens "Forked from Exp220" and cites exp223/exp224 by
   number, which means nothing to a reader outside this workspace.

2. **A credits and provenance section.** This notebook stands on public work:
   pilkwang's model assets, the yusuketogashi no-hack stack it forks, and the
   divergence + mutual-NN filters read out of the kimi-notebook-v17 /
   kunaldesale lineage. Publishing without that would misrepresent the work.
   The section also states explicitly that no source author's leaderboard score
   is claimed for this notebook, which is the workspace's standing rule.

3. **Removal of inherited descriptions that are no longer true.** Cells 2, 9 and
   17 came from the upstream 159B/162 lineage and still say the single change is
   a "three-frame forward acceleration lookahead" and that the gate is a "0.916
   promotion". Neither describes this notebook. Publishing stale prose is worse
   than publishing none.
"""

from __future__ import annotations

import json
from pathlib import Path

NOTEBOOK = (
    Path(__file__).resolve().parent.parent
    / "notebooks"
    / "biohub-exp227-divergence-mutualnn-wide.ipynb"
)

INTRO = """# Biohub Cell Tracking — Divergence + Mutual-NN Safe Divisions (public LB 0.918)

Cell division is the hardest part of this competition's graph. A strictly
one-to-one linker scores **exactly zero** on the division term by construction,
because no node ever gets two children — and that term is 0.1 of the available
1.1. But dividing eagerly is worse than not dividing at all: a false fork adds a
second out-edge from a real parent, and a speculative edge out of an annotated
cell is graded as a false positive. It costs you in the Jaccard term *and* in
the division term.

So the division stage is a precision problem, and the usual lever — the
admission radius — trades one failure for the other. This notebook keeps a wide
radius and pays for it with two geometric filters instead.

**Mutual nearest orphan.** For each cell that already has one child, build a
KD-tree over the frame's unclaimed detections and take the nearest one. Only
that detection may become the sister. This caps every parent at a single
admissible second child, which is what a wide radius otherwise violates
immediately — without it, the same geometry produces cells dividing into three.

**Forward divergence.** Real daughters separate. Both putative daughters must
each have exactly one successor a frame later, and those two grandchildren must
have moved apart by more than the sisters are apart now, by a margin of
`1.5 µm`. A coincidental pair of neighbours fails this; a genuine mitosis passes.

Both run before the image-evidence veto, so the admission chain is:

    geometry gates → mutual nearest orphan → forward divergence → centre-prior veto

**Measured effect.** With the wide geometry alone, the graph audit fails:
`maximum_outdegree = 3`, 452 divisions. Adding the two filters drops
safe-division candidates from **7,823 to 1,555 (−80%)**, restores
`maximum_outdegree = 2`, and the submission scores **0.918** against 0.916 for
the same stack with a narrow radius.

The audit cell at the end is the honest gate: if `maximum_outdegree` is not 2,
the filters did not do their job and the output should not be submitted.
"""

CREDITS = """## Credits and provenance

This notebook is built on public work and does not claim originality for the
components it inherits. Nothing here uses external raw competition data.

| Source | What is used |
| --- | --- |
| [`pilkwang/biohub-tracking-support-pack-50ep-v1`](https://www.kaggle.com/datasets/pilkwang/biohub-tracking-support-pack-50ep-v1) | U-Net + node-transformer checkpoint and inference code |
| [`pilkwang/biohub-temporal-unet3d-seed314159-v1`](https://www.kaggle.com/datasets/pilkwang/biohub-temporal-unet3d-seed314159-v1) | Independently seeded second detection model |
| [`pilkwang/biohub-local-association-ranker-unet300-v1`](https://www.kaggle.com/datasets/pilkwang/biohub-local-association-ranker-unet300-v1) | 22-feature local association ranker |
| [`pilkwang/biohub-deepcenter-unet3d-center-prior-v1`](https://www.kaggle.com/datasets/pilkwang/biohub-deepcenter-unet3d-center-prior-v1) | Centre-prior model used as the division veto |
| [`yusuketogashi/no-hack-biohub-cell-another-approch-3rd`](https://www.kaggle.com/code/yusuketogashi/no-hack-biohub-cell-another-approch-3rd) | The association stack this notebook forks: ranker blending, edge-stage TTA, reverse-time harmonic fusion, graph repair |
| [`zoli800/biohub-cell-another-approch-2nd`](https://www.kaggle.com/code/zoli800/biohub-cell-another-approch-2nd) | Reverse-time harmonic association design, adapted rather than copied |
| [`yunusgmsoy/kimi-notebook-v17`](https://www.kaggle.com/code/yunusgmsoy/kimi-notebook-v17) and [`kunaldesale2408/biohub-cell-tracking`](https://www.kaggle.com/code/kunaldesale2408/biohub-cell-tracking) | The divergence and mutual-nearest-neighbour admission filters, and the wide safe-division geometry, re-implemented here from their published source |

**On scores.** `0.918` is this notebook's own public-leaderboard result. The
sources above have their own scores, and none of them is claimed here — a score
belongs to the submission that earned it, not to a component lineage.

**What is original here** is narrow and worth stating plainly: the two filters
are re-implementations of a published mechanism, placed on a different
association backbone, with the wide geometry they make survivable. The
measurement that they take candidates from 7,823 to 1,555 and turn a failing
graph audit into a passing one is this notebook's contribution, not the idea.
"""

COMPONENTS = """## Model components

Detection comes from two independently seeded 3D U-Nets whose logits are blended
before peak finding, rather than unioning their detections — a union inflates the
node count, which the metric charges for directly.

Association combines the primary model's edge probabilities, four-view
JS-reliability test-time augmentation at the edge stage, reverse-time harmonic
fusion, and a 22-feature local ranker at `0.85` weight. A constrained integer
program then selects the lineage under one-parent and at-most-two-children
constraints.

Graph repair adds one-frame gap closure with density-adaptive gating, short
component removal, and local line-fit smoothing. Division insertion is the stage
this notebook changes.
"""

PROBE = """## The change under test

Everything upstream of division insertion is held fixed. The only modifications
are the two admission filters described above and the widened radius they make
usable: `SAFE_DIV_MAX_UM 12.0`, `SAFE_DIV_SISTER_MAX_UM 15.0`,
`SAFE_DIV_EXISTING_CHILD_MAX_UM 10.0`, against `4.66 / 8.5 / 7.65` on the
narrow-radius baseline.
"""

AUDIT = """## Full submission audit

Graph validity, output-scale checks, and provenance counters. The audit is a
gate, not a report: `maximum_outdegree` must be `2` and `maximum_indegree` must
be `1`, or the filters failed and the output is not a valid lineage. The
candidate and rejection counters below show how much work each filter did.
"""

REPLACEMENTS = {1: INTRO, 2: COMPONENTS, 9: PROBE, 17: AUDIT}


def main() -> None:
    nb = json.loads(NOTEBOOK.read_text())

    for index, text in REPLACEMENTS.items():
        cell = nb["cells"][index]
        if cell["cell_type"] != "markdown":
            raise RuntimeError(f"cell {index} is {cell['cell_type']}, refusing to edit")
        cell["source"] = text.splitlines(keepends=True)

    # Credits go immediately after the introduction.
    if any("## Credits and provenance" in "".join(c["source"]) for c in nb["cells"]):
        raise RuntimeError("credits section already present")
    nb["cells"].insert(
        2,
        {
            "cell_type": "markdown",
            "metadata": {},
            "source": CREDITS.splitlines(keepends=True),
        },
    )

    code_before = [
        "".join(c["source"]) for c in json.loads(NOTEBOOK.read_text())["cells"]
        if c["cell_type"] == "code"
    ]
    code_after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    if code_before != code_after:
        raise RuntimeError("a code cell changed; publication polish must be markdown only")

    NOTEBOOK.write_text(json.dumps(nb, indent=1) + "\n")
    print(f"polished {NOTEBOOK.name}: {len(nb['cells'])} cells, code untouched")


if __name__ == "__main__":
    main()
