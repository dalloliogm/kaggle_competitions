#!/usr/bin/env python3
"""Tighter flow-relink gates with gap45, on the sep29 fresh held-out set.

## Why

On the fresh set (validator offset 12, no overlap with the sep28 sweep)
gap45+flow65 was SUPPORTED against base (+0.00232, 13/8, CI [+0.00013,
+0.00522]), and flow75 was negative on the sep28 set. So the gate improves
as it tightens from 7.5 to 6.5. This run asks whether 6.0 or 5.5 is better
still, against gap45flow65 as the reference, on the same fresh videos.
"""

from __future__ import annotations

import json

import build_sep29_flow65_confirm  # noqa: F401  (applies the offset-12 replacement)
import build_sep28_0953_own_sweep as sweep

sweep.SLUG = "biohub-sep29-flow-tight"
sweep.OUT_DIR = sweep.WORKSPACE / "notebooks" / "sep29-flow-tight"
sweep.ARMS = {
    "gap45flow65": {"GAP_CLOSE_UM": 4.5, "MOTION_RELINK_FLOW_TIGHT_UM": 6.5},
    "gap45flow60": {"GAP_CLOSE_UM": 4.5, "MOTION_RELINK_FLOW_TIGHT_UM": 6.0},
    "gap45flow55": {"GAP_CLOSE_UM": 4.5, "MOTION_RELINK_FLOW_TIGHT_UM": 5.5},
}
sweep.CANDIDATES_NEW = "PP_CANDIDATES: dict[str, dict] = {\n" + "".join(
    f'    "{name}": {json.dumps(cfg)},\n' for name, cfg in sweep.ARMS.items()) + "}\n"

if __name__ == "__main__":
    sweep.main()
