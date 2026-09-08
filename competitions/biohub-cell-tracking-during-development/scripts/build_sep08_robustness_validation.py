#!/usr/bin/env python3
"""Widen the held-out validation behind the 0.946 result, to test its robustness.

The 0.946 submission is a byte-identical reproduction of a public notebook, so
none of its choices were made against the public leaderboard by us. Its own
held-out validator already gives encouraging evidence:

    weighted adjusted edge Jaccard   0.9261   (raw 0.9232, node multiplier 1.0032)
    + 0.1 x division Jaccard 0.2308
    = local score                    0.9492   against public LB 0.946
    44b6 only 0.9534   |   6bba only 0.9431

But it runs on only **8 videos** (`BIOHUB_VALIDATOR_N_PER_TYPE = 4`, two embryo
prefixes), and a bootstrap over those videos puts the 95% interval on adjusted
edge Jaccard at **[0.8815, 0.9709]** - about +-0.045. The agreement with the
public score is therefore consistent with robustness but does not establish it;
the sample is too small to distinguish "genuinely 0.946-class" from "lucky
draw of eight videos".

This run changes exactly one environment variable, `VALIDATOR_N_PER_TYPE`
4 -> 12, giving **24 held-out training videos** instead of 8. Nothing in the
tracking pipeline changes, so the submission output should stay byte-identical
to the scored 0.946 artifact (sha a852d1d0...795b3e) - which doubles as a
correctness check on this edit.

What the wider sample buys:

1. A CI roughly sqrt(3) tighter, enough to say whether the local estimate really
   brackets 0.946.
2. A per-embryo split on 12 videos each rather than 4, which is the closest
   available proxy for the hidden test being embryo-disjoint.
3. More ground-truth divisions in view. The 8-video sample had only 13 division
   events total (3 TP / 1 FP / 9 FN), so division Jaccard is currently measured
   on almost nothing.

This costs GPU time and no submission slot.
"""

from __future__ import annotations

import json
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
SOURCE = Path(
    "/tmp/claude-0/-home-user-kaggle-competitions/"
    "079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad/audit946"
)
OUT_DIR = WORKSPACE / "notebooks" / "sep08-robustness-validation"
SLUG = "biohub-sep08-robustness-wide-validation"
TITLE = "Biohub Sep08 Robustness Wide Validation"

OLD = 'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "4"'
NEW = (
    'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"  '
    "# robustness check: 24 held-out videos instead of 8"
)


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())

    before = [
        "".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"
    ]

    hits = 0
    for cell in nb["cells"]:
        if cell["cell_type"] != "code":
            continue
        text = "".join(cell["source"])
        if OLD in text:
            hits += text.count(OLD)
            cell["source"] = text.replace(OLD, NEW, 1).splitlines(keepends=True)
    if hits != 1:
        raise RuntimeError(f"expected exactly one validator-count assignment, found {hits}")

    after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    changed = [i for i, (a, b) in enumerate(zip(before, after)) if a != b]
    if changed != [0]:
        raise RuntimeError(f"expected only the config cell to change, got {changed}")

    # Nothing outside the validator may move: the tracking pipeline must be
    # untouched so the submission stays byte-identical to the scored artifact.
    for guard in ("BIOHUB_SAFE_DIV", "BIOHUB_DET_THRESHOLD", "BIOHUB_OUTPUT_LINEFIT"):
        if sum(c.count(guard) for c in before) != sum(c.count(guard) for c in after):
            raise RuntimeError(f"{guard} occurrences changed; pipeline must stay fixed")

    OUT_DIR.mkdir(exist_ok=True)
    out = OUT_DIR / f"{SLUG}.ipynb"
    out.write_text(json.dumps(nb, indent=1) + "\n")

    metadata = json.loads((SOURCE / "kernel-metadata.json").read_text())
    metadata["id"] = f"dalloliogm/{SLUG}"
    metadata["title"] = TITLE
    metadata["code_file"] = out.name
    metadata["is_private"] = True
    for key in ("id_no", "docker_image"):
        metadata.pop(key, None)
    (OUT_DIR / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")

    print(f"wrote {out.relative_to(WORKSPACE)}")
    print("  one env var changed: VALIDATOR_N_PER_TYPE 4 -> 12 (8 -> 24 videos)")
    print("  tracking pipeline unchanged; submission should stay byte-identical")


if __name__ == "__main__":
    main()
