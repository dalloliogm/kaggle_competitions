#!/usr/bin/env python3
"""Confirm flow65 and gap45+flow65 on a fresh held-out set, 0.953 base.

## Why

The sep28 own sweep left flow65 (MOTION_RELINK_FLOW_TIGHT_UM 7.0 -> 6.5) as the
only lead: +0.00065 weighted, 13/5, but its CI spans zero and two videos carry
it. The validator always picks the first 12 TRAIN videos per embryo type, so
re-running on the same 24 adds nothing. This run takes the NEXT 12 per type
(BIOHUB_VALIDATOR_OFFSET=12) and measures the combination itself, so a
submission of gap45+flow65 can be judged on direct evidence instead of on two
single-arm results. Same caveat as before: the v1284 head may have seen some
of these videos, which affects every arm equally.

Arms are named without a "combo" prefix because paired_sweep_analysis.py
skips those.
"""

from __future__ import annotations

import json

import build_sep28_0953_own_sweep as sweep

sweep.SLUG = "biohub-sep29-flow65-confirm"
sweep.OUT_DIR = sweep.WORKSPACE / "notebooks" / "sep29-flow65-confirm"
sweep.ARMS = {
    "gap45": {"GAP_CLOSE_UM": 4.5},
    "flow65": {"MOTION_RELINK_FLOW_TIGHT_UM": 6.5},
    "gap45flow65": {"GAP_CLOSE_UM": 4.5, "MOTION_RELINK_FLOW_TIGHT_UM": 6.5},
}
sweep.CANDIDATES_NEW = "PP_CANDIDATES: dict[str, dict] = {\n" + "".join(
    f'    "{name}": {json.dumps(cfg)},\n' for name, cfg in sweep.ARMS.items()) + "}\n"
sweep.REPLACEMENTS = sweep.REPLACEMENTS + [
    ("        val_stems.extend(ranked[:VALIDATOR_N_PER_TYPE])",
     "        _off = int(os.environ.get(\"BIOHUB_VALIDATOR_OFFSET\", \"12\"))  # SEP29: fresh held-out set\n"
     "        val_stems.extend(ranked[_off:_off + VALIDATOR_N_PER_TYPE])"),
]

if __name__ == "__main__":
    sweep.main()
