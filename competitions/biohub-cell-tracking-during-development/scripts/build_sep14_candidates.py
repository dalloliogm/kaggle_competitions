#!/usr/bin/env python3
"""Two one-factor candidates on the fast pinned 0.946 base.

Both build on the verified pinned configuration
(`MOTION_RELINK_TIGHT_UM=5.5`, validator off), which reproduces the scored
0.946 byte-for-byte in 24.9 min instead of 106.1 - so each candidate costs
about 25 min of GPU rather than an hour and three quarters.

**A - extend the winning gradient.** The post-processing sweep's only override
is `MOTION_RELINK_TIGHT_UM`, and moving it `6.0 -> 5.5` is what lifted the
public base from 0.939 to 0.946. The sweep never tried anything tighter than
5.5, and the same selection won on both 8 and 24 held-out videos, so the
gradient is real rather than a small-sample artifact. This tries `5.0`.

**B - division precision.** On 24 held-out videos the division term scores
`0.1458` with **14 false positives against 7 true positives** - it is calling
roughly twice as many divisions wrong as right. A false fork costs twice over,
as an FP edge and an FP fork. This halves the frame and global admission caps,
keeping the geometry and filters intact and simply taking fewer of the ranked
proposals.

Each changes exactly one thing against the same base, so a score moves for a
readable reason.
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
ANCHOR = 'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "4"'

PINNED_HEADER = (
    '# Pinned fast base: the sweep selects MOTION_RELINK_TIGHT_UM=5.5 on both 8\n'
    '# and 24 held-out videos, so pin it and skip the validator (verified\n'
    '# byte-identical to the scored 0.946, 24.9 min instead of 106.1).\n'
    'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"\n'
)

CANDIDATES = {
    "biohub-sep14-tight50": {
        "title": "Biohub Sep14 Motion Relink Tight 50",
        "env": [
            ('BIOHUB_MOTION_RELINK_TIGHT_UM', '5.0'),
        ],
        "note": (
            "Extends the one override the sweep actually chose. 6.0 -> 5.5 took the "
            "public base 0.939 -> 0.946; nothing tighter than 5.5 has been tried."
        ),
    },
    "biohub-sep14-safediv-half": {
        "title": "Biohub Sep14 Safe Division Half Budget",
        "env": [
            ('BIOHUB_MOTION_RELINK_TIGHT_UM', '5.5'),
            ('BIOHUB_SAFE_DIV_FRAME_FRAC_CAP', '0.0038'),
            ('BIOHUB_SAFE_DIV_GLOBAL_FRAC_CAP', '0.001875'),
        ],
        "note": (
            "Divisions score 0.1458 on 24 held-out videos with 14 FP against 7 TP. "
            "Halves the admission caps; geometry and filters unchanged."
        ),
    },
}


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    base = json.loads(notebook_path.read_text())
    base_metadata = json.loads((SOURCE / "kernel-metadata.json").read_text())

    joined = "\n".join(
        "".join(c["source"]) for c in base["cells"] if c["cell_type"] == "code"
    )
    for slug, spec in CANDIDATES.items():
        for key, _value in spec["env"]:
            if f'os.environ.get("{key}"' not in joined:
                raise RuntimeError(f"{key} is not read from the environment; pinning it is a no-op")

    for slug, spec in CANDIDATES.items():
        nb = json.loads(notebook_path.read_text())
        before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

        block = PINNED_HEADER + "\n".join(
            f'os.environ["{k}"] = "{v}"' for k, v in spec["env"]
        )
        hits = 0
        for cell in nb["cells"]:
            if cell["cell_type"] != "code":
                continue
            text = "".join(cell["source"])
            if ANCHOR in text:
                hits += text.count(ANCHOR)
                cell["source"] = text.replace(ANCHOR, block, 1).splitlines(keepends=True)
        if hits != 1:
            raise RuntimeError(f"{slug}: expected one anchor, found {hits}")

        after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
        changed = [i for i, (a, b) in enumerate(zip(before, after)) if a != b]
        if changed != [0]:
            raise RuntimeError(f"{slug}: only the config cell may change, got {changed}")

        out_dir = WORKSPACE / "notebooks" / slug
        out_dir.mkdir(exist_ok=True)
        out = out_dir / f"{slug}.ipynb"
        out.write_text(json.dumps(nb, indent=1) + "\n")

        metadata = dict(base_metadata)
        metadata["id"] = f"dalloliogm/{slug}"
        metadata["title"] = spec["title"]
        metadata["code_file"] = out.name
        metadata["is_private"] = True
        for key in ("id_no", "docker_image"):
            metadata.pop(key, None)
        (out_dir / "kernel-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
        print(f"wrote {slug}: {spec['note'][:70]}...")


if __name__ == "__main__":
    main()
