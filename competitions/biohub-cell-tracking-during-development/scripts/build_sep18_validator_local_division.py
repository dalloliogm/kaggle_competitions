#!/usr/bin/env python3
"""Wire the official (post-patch) division rule into the notebook validator.

## Why

`compute_division_confusion` in cell 8 credits a ground-truth division whenever
*any* forking node shares a weakly-connected component with both daughter
lineages. `metrics.md` removed that route in commit aa65e90 on 2026-07-17. The
official rule is local: the fork must be the matched parent or its immediate
successor, and the two daughters must be reached through two **distinct**
direct-child branches of that fork.

`scripts/division_metric_local_rule.py` demonstrates the gap on constructed
graphs. The decisive case: on a graph with no fork anywhere near the real cell -
the parent continues into one daughter, the other daughter is a separate track,
and a hub outside the volume merges everything - our validator returns a TRUE
POSITIVE. It would score the cheating exploit as a success. A genuinely correct
division still scores as a true positive under both rules, so this tightens the
metric without breaking real detections.

Everything we have measured locally on divisions is therefore an upper bound.
The 2026-09-14 arm that halved the safe-division caps was justified by a local
reading of 14 FP against 7 TP from this metric, and lost 0.946 -> 0.942.

## What this run is for

The validator drives `pp_apply`, which selects the post-processing config used
for the real submission. Correcting the metric can therefore change what the
sweep selects - which is the point, but it also means the output is not
guaranteed to be stable. So this run answers two questions at once:

1. **How inflated was the local number?** The same 24 held-out videos previously
   reported division Jaccard 0.2308 under the loose rule. Whatever the corrected
   rule reports is the honest figure, and the ratio is the inflation factor.
2. **Does the sweep still choose tight55?** It selected
   `MOTION_RELINK_TIGHT_UM=5.5` under the loose metric at both 8 and 24 videos.
   If it still does, the banked 0.946 configuration was not an artifact of the
   broken compass. If it does not, the selection was partly steered by it and
   the newly chosen config is a candidate worth running.

The tracking pipeline is untouched - only the validator's scoring function
changes - so any change in the submission comes from the sweep's *selection*,
not from different tracking.

This costs GPU time and no submission slot.
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
OUT_DIR = WORKSPACE / "notebooks" / "sep18-validator-local-division"
TITLE = "Biohub Sep18 Validator Official Division Rule"
SLUG = re.sub(r"[^a-z0-9]+", "-", TITLE.lower()).strip("-")

# Widen to 24 held-out videos so the corrected figure is directly comparable
# with the 0.2308 previously reported on the same sample.
ANCHOR = 'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "4"'
CONFIG = (
    '# 24 held-out videos, the same sample that reported division Jaccard\n'
    '# 0.2308 under the loose component rule, so the corrected number is\n'
    '# directly comparable.\n'
    'os.environ["BIOHUB_VALIDATOR_N_PER_TYPE"] = "12"'
)

NEW_FUNCTION = '''def compute_division_confusion(pred_nodes, pred_edges, gt_nodes, gt_edges, pred_to_gt, gt_to_pred):
    """Official post-patch rule (metrics.md, commit aa65e90, 2026-07-17).

    The previous implementation here credited a ground-truth division whenever
    any forking node shared a weakly-connected component with both daughter
    lineages. That is the route the organisers removed: "Merely sharing a
    weakly connected component is not sufficient." On a graph with no fork
    anywhere near the real cell, a hub node outside the volume merging every
    track into one component was enough to score a true positive.

    The rule is local. A ground-truth division at `gsrc` counts as a true
    positive only when there is a predicted fork F such that

      * F is the predicted match of `gsrc`, or F is an immediate successor of
        that match, and
      * F has at least two outgoing edges, and
      * the two ground-truth daughter lineages are reached through two
        DISTINCT direct-child branches of F.

    See scripts/division_metric_local_rule.py for the side-by-side test.
    """
    gt_out: dict[int, set[int]] = {}
    for s, t in gt_edges:
        gt_out.setdefault(s, set()).add(t)

    pred_out: dict[int, set[int]] = {}
    for s, t in pred_edges:
        pred_out.setdefault(s, set()).add(t)

    def gt_lineage(root_child: int) -> set[int]:
        seen = {root_child}
        stack = [root_child]
        while stack:
            cur = stack.pop()
            for nxt in gt_out.get(cur, ()):
                if nxt not in seen:
                    seen.add(nxt)
                    stack.append(nxt)
        return seen

    def pred_branch(child: int) -> set[int]:
        seen = {child}
        stack = [child]
        while stack:
            cur = stack.pop()
            for nxt in pred_out.get(cur, ()):
                if nxt not in seen:
                    seen.add(nxt)
                    stack.append(nxt)
        return seen

    tp = 0
    fn = 0
    tp_gt_sources: set[int] = set()

    for gsrc in [s for s, outs in gt_out.items() if len(outs) >= 2]:
        matched = gt_to_pred.get(gsrc)
        if matched is None:
            fn += 1
            continue
        children = sorted(gt_out[gsrc])[:2]
        pred_hits = [
            {p for g in gt_lineage(child) if (p := gt_to_pred.get(g)) is not None}
            for child in children
        ]

        found = False
        for fork in [matched, *sorted(pred_out.get(matched, ()))]:
            outs = sorted(pred_out.get(fork, ()))
            if len(outs) < 2:
                continue
            branches = {c: pred_branch(c) for c in outs}
            reach0 = {c for c, nodes in branches.items() if nodes & pred_hits[0]}
            reach1 = {c for c, nodes in branches.items() if nodes & pred_hits[1]}
            if any(a != b for a in reach0 for b in reach1):
                found = True
                break

        if found:
            tp += 1
            tp_gt_sources.add(gsrc)
        else:
            fn += 1

    fp = 0
    for n, outs in pred_out.items():
        if len(outs) < 2:
            continue
        g = pred_to_gt.get(n)
        if g is None or g not in gt_out or g in tp_gt_sources:
            continue
        fp += 1

    return tp, fp, fn


'''


def main() -> None:
    notebook_path = next(SOURCE.glob("*.ipynb"))
    nb = json.loads(notebook_path.read_text())
    before = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]

    target = [i for i, s in enumerate(before) if "def compute_division_confusion" in s]
    if len(target) != 1:
        raise RuntimeError(f"expected one definition of compute_division_confusion, found {len(target)}")
    cell_idx = target[0]

    old_cell = before[cell_idx]
    start = old_cell.find("def compute_division_confusion")
    end = old_cell.find("def decompose_errors")
    if start < 0 or end < 0 or end <= start:
        raise RuntimeError("could not bound compute_division_confusion; source has drifted")
    old_function = old_cell[start:end]
    # The loose rule is identifiable by its use of component ids; if that has
    # already changed, this patch is being applied to something unexpected.
    for marker in ("weakly_connected_components", "fork_components", "lineage_hit_components"):
        if marker not in old_function:
            raise RuntimeError(f"{marker} missing; this is not the loose implementation")

    replaced = 0
    for cell in nb["cells"]:
        if cell["cell_type"] != "code":
            continue
        text = "".join(cell["source"])
        touched = False
        if old_function in text:
            text = text.replace(old_function, NEW_FUNCTION, 1)
            replaced += 1
            touched = True
        if ANCHOR in text:
            text = text.replace(ANCHOR, CONFIG, 1)
            touched = True
        if touched:
            cell["source"] = text.splitlines(keepends=True)
    if replaced != 1:
        raise RuntimeError(f"expected one function replacement, made {replaced}")

    after = ["".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"]
    changed = [i for i, (a, b) in enumerate(zip(before, after)) if a != b]
    if changed != sorted({0, cell_idx}):
        raise RuntimeError(f"only the config and validator cells may change, got {changed}")

    # The tracking pipeline must not move: this is a scoring change. Cell 5
    # holds the post-processing and linking code and must be untouched.
    if before[5] != after[5]:
        raise RuntimeError("pipeline cell changed; this patch must only touch scoring")
    for guard in ("def add_safe_divisions_postlink", "def motion_relink_edges",
                  "def filter_output_graph", "def write_test_submission"):
        if sum(s.count(guard) for s in before) != sum(s.count(guard) for s in after):
            raise RuntimeError(f"{guard} occurrences changed")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
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
    print(f"  replaced compute_division_confusion in code cell {cell_idx}")
    print("  validator widened to 24 held-out videos (N_PER_TYPE=12)")
    print("  pipeline cell 5 verified untouched")
    print("  READ: corrected division Jaccard vs the 0.2308 loose figure, and")
    print("        whether the sweep still selects MOTION_RELINK_TIGHT_UM=5.5")


if __name__ == "__main__":
    main()
