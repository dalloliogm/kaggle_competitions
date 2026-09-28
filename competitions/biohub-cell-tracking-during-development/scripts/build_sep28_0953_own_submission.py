#!/usr/bin/env python3
"""Submission kernel for a configuration chosen by the sep28 own sweep.

Takes post-process overrides as KEY=VALUE pairs (the PP_SWEEP_KEYS names, e.g.
READMIT_RADIUS_UM=5), rewrites the matching BIOHUB_<KEY> line in the config
cell of our exact 0.953 copy, and keeps the configuration guard in step for the
keys it pins. Validator stays off, so the kernel runs in ~20 min.

Usage:
  build_sep28_0953_own_submission.py SLUG KEY=VALUE [KEY=VALUE ...]
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
SOURCE = WORKSPACE / "notebooks/public-reproductions/sep26-0953-original"


def main() -> None:
    slug, pairs = sys.argv[1], sys.argv[2:]
    overrides = dict(p.split("=", 1) for p in pairs)
    nb = json.loads((SOURCE / "biohub-sep26-0953-original.ipynb").read_text())

    config = "".join(nb["cells"][0]["source"])
    guard = "".join(nb["cells"][1]["source"])
    for key, value in overrides.items():
        pattern = rf'^os\.environ\["BIOHUB_{key}"\] = [^\n]*$'
        config, n = re.subn(pattern, f'os.environ["BIOHUB_{key}"] = "{value}"  # SEP28 own sweep',
                            config, flags=re.M)
        assert n == 1, (key, n)
        guard, _ = re.subn(rf'"BIOHUB_{key}": [0-9.]+,', f'"BIOHUB_{key}": {float(value)},', guard)
    nb["cells"][0]["source"] = config.splitlines(keepends=True)
    nb["cells"][1]["source"] = guard.splitlines(keepends=True)

    meta = json.loads((SOURCE / "kernel-metadata.json").read_text())
    meta.update(id=f"dalloliogm/{slug}", title=slug, code_file=f"{slug}.ipynb")
    out = WORKSPACE / "notebooks" / slug.removeprefix("biohub-")
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{slug}.ipynb").write_text(json.dumps(nb, indent=1))
    (out / "kernel-metadata.json").write_text(json.dumps(meta, indent=2))
    print(f"wrote {out}: {overrides}")


if __name__ == "__main__":
    main()
