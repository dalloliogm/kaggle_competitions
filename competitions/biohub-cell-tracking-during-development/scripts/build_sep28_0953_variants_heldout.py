#!/usr/bin/env python3
"""Held-out paired test of our two Sep26 variants on the 0.953 (v1284) base.

## Question

All three Sep26 submissions read 0.953 on the public board: the exact public
copy, `gap45` (GAP_CLOSE_UM 5.0 -> 4.5) and `mtl5` (OUTPUT_MIN_TRACK_LEN 6 -> 5).
The board's 0.001 quantisation cannot separate them. This run measures both
against the plain 0.953 base on the same 24 held-out TRAIN videos the old
harness used (VALIDATOR_N_PER_TYPE=12; the stem selection is deterministic).

## What it can and cannot answer

The v1284 coordinate head was trained on "20 TRAIN movies" we cannot identify,
so the base itself may be in-sample on some of these 24 videos. That rules out
a base-vs-0.947 comparison here. Every arm below shares the same inference
output and the same head, so the variant-vs-base comparison stays paired.

## Build

Source is our byte-identical copy of anvithpothula/biohub-0-953-lb-original
(`notebooks/public-reproductions/sep26-0953-original`). Changes:

* BIOHUB_VALIDATOR_ENABLE 0 -> 1, BIOHUB_VALIDATOR_N_PER_TYPE 4 -> 12
* PP_CANDIDATES replaced by exactly {gap45, mtl5}
* one appended cell writing every sweep row (all configs, all stems) to
  validator_results_all.csv for scripts/paired_sweep_analysis.py

Not a submission: the output is analysed, not uploaded.
"""

from __future__ import annotations

import json
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
SOURCE = WORKSPACE / "notebooks/public-reproductions/sep26-0953-original"
SLUG = "biohub-sep28-0953-variants-heldout"
OUT_DIR = WORKSPACE / "notebooks" / "sep28-0953-variants-heldout"

REPLACEMENTS = [
    ('os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "4"',
     'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"  # SEP28: 24 held-out videos'),
    ('os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"          # in-sample train proxy, ~11 min of GPU per run',
     'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "1"  # SEP28: held-out paired test'),
]

CANDIDATES_OLD_START = "PP_CANDIDATES: dict[str, dict] = {\n"
CANDIDATES_NEW = (
    "PP_CANDIDATES: dict[str, dict] = {\n"
    '    "gap45": {"GAP_CLOSE_UM": 4.5},\n'
    '    "mtl5": {"OUTPUT_MIN_TRACK_LEN": 5},\n'
    "}\n"
)

DUMP_CELL = '''# SEP28: every sweep row, all configs x all stems, for paired_sweep_analysis.py
_all_path = WORKING_DIR / "validator_results_all.csv"
pd.DataFrame(validator_sample_rows).to_csv(_all_path, index=False)
print(f"Wrote {len(validator_sample_rows)} rows to {_all_path}")
print(pd.DataFrame(validator_sample_rows).groupby("config").size())
'''


def main() -> None:
    nb = json.loads((SOURCE / "biohub-sep26-0953-original.ipynb").read_text())
    counts = [0] * len(REPLACEMENTS)
    replaced_candidates = 0
    for cell in nb["cells"]:
        if cell["cell_type"] != "code":
            continue
        src = "".join(cell["source"])
        for i, (old, new) in enumerate(REPLACEMENTS):
            if old in src:
                src = src.replace(old, new)
                counts[i] += 1
        if CANDIDATES_OLD_START in src:
            start = src.index(CANDIDATES_OLD_START)
            end = src.index("\n}\n", start) + 3
            src = src[:start] + CANDIDATES_NEW + src[end:]
            replaced_candidates += 1
        cell["source"] = src.splitlines(keepends=True)
    assert counts == [1, 1], counts
    assert replaced_candidates == 1, replaced_candidates

    nb["cells"].append({"cell_type": "code", "execution_count": None, "metadata": {},
                        "outputs": [], "source": DUMP_CELL.splitlines(keepends=True)})

    meta = json.loads((SOURCE / "kernel-metadata.json").read_text())
    meta.update(id=f"dalloliogm/{SLUG}", title=SLUG, code_file=f"{SLUG}.ipynb")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / f"{SLUG}.ipynb").write_text(json.dumps(nb, indent=1))
    (OUT_DIR / "kernel-metadata.json").write_text(json.dumps(meta, indent=2))
    print(f"wrote {OUT_DIR}")


if __name__ == "__main__":
    main()
