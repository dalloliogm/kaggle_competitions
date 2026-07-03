# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-03 | Multi-scale DoG + Hungarian + one-frame interpolation | Exact validation completed; output retrieval pending | 0.827 | TBD | `notebooks/biohub-exact-dog-hungarian-baseline.ipynb` | Strong first submission; divisions disabled |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-03 | Exact DoG/Hungarian baseline | Offline exact evaluator, physical NMS, centroid refinement, 8 um linking, gap-1 interpolation, pruning | Completed on Kaggle; API output throttled | 0.827 | Successful first submission | Test one conservative gap-2 recovery pass |

## Prepared

| Date | Approach | Notebook | Validation status | Next action |
| --- | --- | --- | --- | --- |
| 2026-07-03 | Conservative velocity-aware gap-2 recovery | `notebooks/biohub-gap2-velocity-ablation.ipynb` | Local syntax/config/graph tests passed; exact Kaggle run pending | Compare against frozen baseline on identical detections and held-out embryos |

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
| TBD | TBD | TBD | TBD |
