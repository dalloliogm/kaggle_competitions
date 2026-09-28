#!/usr/bin/env python3
"""Our own post-process sweep on the 0.953 (v1284) base, 24 held-out videos.

## Why

The three Sep26 submissions differ from the public 0.953 artifact by one
constant each. The aim here is a configuration of our own: sweep the
post-process stages on the new base, including the three the 0.953 notebook
added and nobody has swept (flow relink, readmission of discarded detections,
sub-threshold gap filling), and submit whatever the restricted paired test
supports.

## Arms, and what each one is grounded in

* gap45, bonus125 - carried from the old-base harness (supported / concentrated).
* readmit3, readmit5, readmit090 - readmission adds nodes near open track ends
  (363 on 6bba_207c6aaf). The node-count factor makes node additions a real
  trade-off, so both directions are measured.
* gapfill04 - more bridging from sub-threshold peaks.
* flow65, flow75 - the flow-relink gate (7.0 um), new in this base.
* divmax95 - the 2026-09-20 division trace's near miss (parent 9.27 > 9.0 um).
* diverge15 - the trace's divergence miss (1.60 < 2.25 um).

The new-stage constants are module globals read at call time, so adding them
to PP_SWEEP_KEYS makes them sweepable exactly like the existing ones. The
readmission/gap-fill pool is dumped for validation videos too (checked in the
sep28 variants log), so those arms are live on held-out data.

Same caveat as the variants run: the v1284 head may have seen some of these
videos, which affects every arm equally and leaves the paired comparison valid.
"""

from __future__ import annotations

import json
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
SOURCE = WORKSPACE / "notebooks/public-reproductions/sep26-0953-original"
SLUG = "biohub-sep28-0953-own-sweep"
OUT_DIR = WORKSPACE / "notebooks" / "sep28-0953-own-sweep"

REPLACEMENTS = [
    ('os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "4"',
     'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"  # SEP28: 24 held-out videos'),
    ('os.environ["BIOHUB_VALIDATOR_ENABLE"] = "0"          # in-sample train proxy, ~11 min of GPU per run',
     'os.environ["BIOHUB_VALIDATOR_ENABLE"] = "1"  # SEP28: held-out paired test'),
    ('    "GAP_CLOSE_REUSE_UM", "OUTPUT_EDGE_MAX_UM",\n]',
     '    "GAP_CLOSE_REUSE_UM", "OUTPUT_EDGE_MAX_UM",\n'
     '    # SEP28: stages new in the 0.953 base, read as globals at call time\n'
     '    "READMIT_RADIUS_UM", "READMIT_MIN_SCORE", "GAPFILL_MIN_SCORE",\n'
     '    "MOTION_RELINK_FLOW_TIGHT_UM",\n]'),
]

ARMS = {
    "gap45": {"GAP_CLOSE_UM": 4.5},
    "bonus125": {"MOTION_RELINK_LEARNED_BONUS": 1.25},
    "readmit3": {"READMIT_RADIUS_UM": 3.0},
    "readmit5": {"READMIT_RADIUS_UM": 5.0},
    "readmit090": {"READMIT_MIN_SCORE": 0.90},
    "gapfill04": {"GAPFILL_MIN_SCORE": 0.4},
    "flow65": {"MOTION_RELINK_FLOW_TIGHT_UM": 6.5},
    "flow75": {"MOTION_RELINK_FLOW_TIGHT_UM": 7.5},
    "divmax95": {"SAFE_DIV_MAX_UM": 9.5},
    "diverge15": {"SAFE_DIV_DIVERGE_UM": 1.5},
}

CANDIDATES_OLD_START = "PP_CANDIDATES: dict[str, dict] = {\n"
CANDIDATES_NEW = "PP_CANDIDATES: dict[str, dict] = {\n" + "".join(
    f'    "{name}": {json.dumps(cfg)},\n' for name, cfg in ARMS.items()) + "}\n"

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
    assert counts == [1, 1, 1], counts
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
