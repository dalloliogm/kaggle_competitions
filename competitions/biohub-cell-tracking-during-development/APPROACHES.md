# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-03 | Multi-scale DoG + Hungarian + one-frame interpolation | Exact validation completed; output retrieval pending | 0.827 | TBD | `notebooks/biohub-exact-dog-hungarian-baseline.ipynb` | Strong first submission; divisions disabled |
| 2026-07-03 | Baseline with physical NMS 3.8 um | 0.810458 | Not submitted | TBD | Candidate notebook pending | +0.016153 exact; both embryos improved |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-03 | Exact DoG/Hungarian baseline | Offline exact evaluator, physical NMS, centroid refinement, 8 um linking, gap-1 interpolation, pruning | Completed on Kaggle; API output throttled | 0.827 | Successful first submission | Test one conservative gap-2 recovery pass |
| 2026-07-03 | Conservative velocity-aware gap-2 recovery | Added capped `t -> t+3` bridges with two inserted nodes | 0.793540 vs 0.794304 baseline | Not submitted | Rejected: same 761/63/134 edge counts, more nodes, delta -0.000764 | Move to detector threshold/NMS sweep |
| 2026-07-03 | Detector one-factor screen | Threshold 0.030/0.060 and NMS 2.8/3.8 um | Best 0.810458 at NMS 3.8 vs 0.794304 baseline | Not submitted | NMS 3.8 improved both embryos; lower threshold and NMS 2.8 hurt | Build dedicated candidate kernel |

## Prepared

| Date | Approach | Notebook | Validation status | Next action |
| --- | --- | --- | --- | --- |
| 2026-07-03 | Physical NMS 3.8 um candidate | Dedicated submission notebook pending | Exact screen passed on two embryos | Run full test inference and schema checks; do not submit automatically |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| Exact official evaluator + embryo-disjoint folds | Public proxies often misweight divisions or node penalties | Prevents false optimization | Medium | P0 |
| Reproduce auditable DoG/Hungarian baseline | Strongest transparent common denominator across public notebooks | Establish competitive, debuggable baseline | Medium | P0 |
| Detection-density and physical-NMS sweep | Endpoint recall and node penalty dominate edge score | High | Medium | P0 |
| Link-gate, motion, and two-pass ablation | Reduces assignment steals without changing detections | Medium | Low | P1 |
| One-frame interpolated gap recovery | Restores two consecutive edges after a missed detection | Medium | Low | P1 |
| Per-movie count calibration | Adapts to embryo density while controlling node penalty | Medium-high if it generalizes | Medium | P1 |
| Artifact-backed U-Net + transformer + ILP reproduction | Only reviewed pipeline with learned detection and global tracking | Highest likely ceiling | High | High | P1 |
| Conservative division recovery | Can add up to 0.1, but risks edge and division FPs | Low-medium | Low | P2 |
| Velocity-aware gap-2 interpolation | Newer claimed LB improvement, but very small/capped effect | Low | Low | P2 |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| Conservative velocity-aware gap-2 recovery | Added nodes but recovered no annotated edges; exact score fell | Two embryos: edge TP/FP/FN unchanged at 761/63/134; nodes increased 32,471 to 32,619; score 0.794304 -> 0.793540 | Only if a detector change creates demonstrable two-frame misses that recover edge TPs |
