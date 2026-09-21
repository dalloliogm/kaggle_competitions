#!/usr/bin/env python3
"""Cut the rerun runtime by pinning the sweep's choice instead of re-deriving it.

## Why runtime is the priority

The private score comes from re-executing the kernel on a hidden test set
"approximately the same size as the training dataset" (~199 samples). A kernel
that does not finish inside the 12 h limit scores nothing, which would make the
public 0.946 irrelevant. A competitor in the `focus3d` thread reports exactly
this failure ("it timed out when submitting").

Differential measurement across two completed runs, identical except for
validator width:

    8 held-out videos  -> 106.1 min
    24 held-out videos -> 170.6 min
    marginal cost       ->   4.03 min per video
    fixed + 4 test videos -> 73.8 min

(An earlier single-run decomposition put the per-video cost at 7.84 min by
attributing all fixed tracking overhead to the four test videos. 4.03 is the
measured marginal, and it is the number to trust.)

## What the validator actually does - it is NOT a diagnostic

`PP_BASE_CONFIG` is labelled "public 0.939". The validator scores 8 post-process
configs on held-out TRAIN videos, picks a winner, and `pp_apply` overrides module
globals with it for the real test output. So the validator is load-bearing: the
`0.946` submission is the `0.939` base plus the one override the sweep chose.
Switching the validator off reverts to base - the notebook says so directly
("reproduces 0.915 if VALIDATOR_ENABLE is turned off").

## Why the choice can be pinned safely

The sweep selected the **same** config at both sample sizes:

    8 videos : selected tight55  {MOTION_RELINK_TIGHT_UM: 5.5}  proxy 0.9492 -> 0.9512
    24 videos: selected tight55  {MOTION_RELINK_TIGHT_UM: 5.5}  proxy 0.9268 -> 0.9290

Tripling the held-out sample does not change the winner, and the margin over
base is consistent (+0.0020, +0.0022). The selection is therefore not an artifact
of a small sample, and hard-coding it is not the same as trusting one lucky draw.

## This run

Sets `MOTION_RELINK_TIGHT_UM = 5.5` directly and disables the validator. If the
sweep is doing nothing except choosing that constant, the submission must come
out **byte-identical to the scored 0.946 artifact** (sha `a852d1d0...795b3e`).
That sha check is the whole experiment: it proves the pin is equivalent, and it
simultaneously gives the third equation needed to separate fixed cost from
per-test-video cost, because this run's total is `FIXED + cost(4 test videos)`
with no validator term.

If the sha does NOT match, the validator influences the output through some path
beyond the override, and pinning is unsafe - which is exactly what this needs to
establish before anything is submitted.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
SOURCE = Path(
    "/tmp/claude-0/-home-user-kaggle-competitions/"
    "079e2126-1615-5dfd-bdeb-d1a861286f6c/scratchpad/audit946"
)
OUT_DIR = WORKSPACE / "notebooks" / "sep10-runtime-candidate"
TITLE = "Biohub Sep10 Runtime Pinned Config No Validator"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

VALIDATOR_LINE = 'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "4"'
REPLACEMENT = (
    '# Runtime candidate: pin the sweep\'s stable selection (tight55) and skip the\n'
    '# validator entirely. The sweep chose MOTION_RELINK_TIGHT_UM=5.5 on both 8 and\n'
    '# 24 held-out videos, so this is the same configuration without the cost of\n'
    '# re-deriving it on every run. Verified by submission sha against the scored\n'
    '# 0.946 artifact.\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
    'os.environ["BIOHUB_MOTION_RELINK_TIGHT_UM"] = "5.5"'
)


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())

    code_before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    # The constant must be env-readable, or setting the variable achieves nothing.
    joined = "\n".join(code_before)
    if 'os.environ.get("BIOHUB_MOTION_RELINK_TIGHT_UM"' not in joined:
        raise RuntimeError(
            "MOTION_RELINK_TIGHT_UM is not read from the environment; "
            "pinning it via os.environ would be silently ignored"
        )
    # And it must not be frozen by an inherited strategy guard.
    for cell in nb["cells"]:
        source = "".join(cell["source"])
        if "_expected_numeric" in source and "MOTION_RELINK_TIGHT_UM" in source:
            raise RuntimeError(
                "a strategy guard freezes MOTION_RELINK_TIGHT_UM; repoint it first"
            )

    hits = 0
    for cell in nb["cells"]:
        if cell["cell_type"] != "code":
            continue
        text = "".join(cell["source"])
        if VALIDATOR_LINE in text:
            hits += text.count(VALIDATOR_LINE)
            cell["source"] = text.replace(
                VALIDATOR_LINE, REPLACEMENT, 1
            ).splitlines(keepends=True)
    if hits != 1:
        raise RuntimeError(f"expected one validator-count line, found {hits}")

    code_after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    changed = [i for i, (a, b) in enumerate(zip(code_before, code_after)) if a != b]
    if changed != [0]:
        raise RuntimeError(f"only the config cell may change, got {changed}")

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
    print("  VALIDATOR_ENABLE=0 and MOTION_RELINK_TIGHT_UM pinned to 5.5")
    print("  PASS criterion: submission sha == a852d1d07ff8c930... (the scored 0.946)")


if __name__ == "__main__":
    main()
