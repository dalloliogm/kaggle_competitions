# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-03 | Multi-scale DoG + Hungarian + one-frame interpolation | Exact validation completed; output retrieval pending | 0.827 | TBD | `notebooks/biohub-exact-dog-hungarian-baseline.ipynb` | Strong first submission; divisions disabled |
| 2026-07-03 | Baseline with physical NMS 3.8 um | 0.810458 | 0.834 | TBD | `notebooks/biohub-nms38-candidate.ipynb` / `e8f4ee7` | Rank 203/630; ~0.022 below top-10% cutoff |
| 2026-07-04 | Pretrained U-Net + transformer + ILP | 0.839409 | 0.810 | TBD | `notebooks/biohub-learned-unet-ilp-candidate.ipynb` | Validation gain did not transfer; worse than classical LB by 0.024 |
| 2026-07-06 | LB893 learned graph tracker with motion relink, gap repair, line fit, and safe divisions | Exact validation pending in workspace runner | 0.893 | TBD | `notebooks/biohub-lb893-safe-divisions-source.ipynb` | New working baseline; copied public notebook output dominates previous approaches |
| 2026-07-08 | LB893 minus safe-division insertion | 0.960641 on selected exact split | 0.886 | TBD | `notebooks/biohub-lb893-no-safe-divisions-candidate.ipynb` | Novel variant, but public LB -0.007 versus copied LB893; selected validation split underweights true divisions |
| 2026-07-16 | Exp073 public graph calibration | Test-only public run; exact train validation not yet reproduced | 0.903 | TBD | `dalloliogm/biohub-exp073-gap-5-8-public` / `references/own-kernels-2026-07-16/` | New working baseline; lower detection threshold, short-track filtering, gap2 disabled, two-frame gap close |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-03 | Exact DoG/Hungarian baseline | Offline exact evaluator, physical NMS, centroid refinement, 8 um linking, gap-1 interpolation, pruning | Completed on Kaggle; API output throttled | 0.827 | Successful first submission | Test one conservative gap-2 recovery pass |
| 2026-07-03 | Conservative velocity-aware gap-2 recovery | Added capped `t -> t+3` bridges with two inserted nodes | 0.793540 vs 0.794304 baseline | Not submitted | Rejected: same 761/63/134 edge counts, more nodes, delta -0.000764 | Move to detector threshold/NMS sweep |
| 2026-07-03 | Detector one-factor screen | Threshold 0.030/0.060 and NMS 2.8/3.8 um | Best 0.810458 at NMS 3.8 vs 0.794304 baseline | Not submitted | NMS 3.8 improved both embryos; lower threshold and NMS 2.8 hurt | Build dedicated candidate kernel |
| 2026-07-03 | NMS 3.8 submission | Stronger suppression; otherwise frozen rule-based pipeline | 0.810458 | 0.834 | Improved LB +0.007 but remains outside medal range | Pivot to learned/global tracking |
| 2026-07-04 | Default pretrained U-Net + transformer + ILP | Real learned detections/edges and global ILP; det 0.99, division weight 1.0 | 0.839409 | 0.810 | Rejected as full replacement: LB -0.024 versus NMS-3.8 | Retain learned pipeline only for `6bba` |
| 2026-07-07 | LB893 source import and ablation harness | Preserved source notebook, output stats/log, and created validation-ablation runner | Syntax checked; local GPU run not possible | 0.893 from submission `54397298` | Adopt as baseline for further work | Run exact validation ablations on Kaggle T4 |
| 2026-07-08 | LB893 exact-validation baseline | Full LB893 with motion relink, gap close, gap2, linefit, and safe divisions | 0.954802 | 0.893 from copied submission | Established validation reference; division FP = 4 on selected split | Compare one-factor ablations against this score |
| 2026-07-08 | No-safe-divisions LB893 ablation | Same as full LB893, but `BIOHUB_OUTPUT_SAFE_DIVISIONS=0` | 0.960641 | 0.886 | Useful negative/diagnostic result: local validation misled because it had no true scored divisions | Tune safe divisions rather than deleting them |
| 2026-07-16 | Exp073 copied public recipe | `DET_THRESHOLD=0.9700`, short-track filtering on, min track length 6, gap2 off, gap close max gap 2 at 5.8 um, safe divisions kept | Not yet exact-validated locally | 0.903 | Accepted as new baseline; submission `54758569` | Tune one factor at a time around Exp073 |

## Prepared

| Date | Approach | Notebook | Validation status | Next action |
| --- | --- | --- | --- | --- |
| 2026-07-04 | Prefix-aware classical/learned hybrid | `notebooks/biohub-prefix-hybrid-candidate.ipynb` | Exact hybrid 0.842616; Kaggle v2 completed with a validated 260,287-row output identical to local | Manually submit version 2 and record LB |
| 2026-07-07 | LB893 exact-validation ablation runner | `notebooks/biohub-lb893-validation-ablation.ipynb` | JSON/Python syntax checked locally; requires Kaggle T4 plus `biohub-tracking-support-pack-50ep-v1` | Upload/run `full_lb893` validation, then one-factor ablations |
| 2026-07-08 | LB893 no-safe-divisions test candidate | `notebooks/biohub-lb893-no-safe-divisions-candidate.ipynb` | Kaggle v1 completed; 283,092-row output passed structural checks; public LB 0.886 | Superseded by copied LB893 0.893; use as negative control for division tuning |
| 2026-07-08 | LB893 conservative safe-divisions candidate | `notebooks/biohub-lb893-conservative-safe-divisions-candidate.ipynb` | Kaggle v1 completed; 283,385 rows and 287 safe divisions; structural checks passed | Submitted 2026-07-09 (`54490638`/`54490358`): public LB `0.889`, below copied LB893 `0.893`. Tightening divisions did not beat the baseline. |
| 2026-07-12 | Graph-aware consensus ensemble | `notebooks/biohub-graph-consensus-ensemble.ipynb` | Core + end-to-end cells verified locally (merge/prune/division/anchor/degree tests, ~12 s at scale, valid schema output) | Push kernel, attach the 3 diverse candidate outputs, run; then tune `TAU_*` via `VALIDATION_MODE` |
| 2026-07-16 | Exp084 threshold probe around Exp073 | `notebooks/biohub-exp084-threshold-096875-candidate.ipynb` | Kaggle v1 complete; 252,357 rows, 128,451 nodes, 123,906 edges, 419 division-like sources; structural checks passed; submitted as `54768957` | Pending public LB; decide if threshold helps |
| 2026-07-16 | Exp090 density-adaptive gap probe around Exp073 | `notebooks/biohub-exp090-density-adaptive-gap-candidate.ipynb` | Kaggle v2 complete; 252,231 rows, 128,379 nodes, 123,852 edges; density branch activated with 124 expanded candidates and 52 selected outside base; structural checks passed; submitted as `54768948` | Pending public LB; use to compare density gap effect |
| 2026-07-16 | Exp096 stable long-track bridge probe around Exp073 | `notebooks/biohub-exp096-stable-long-track-bridge-candidate.ipynb` | Kaggle v2 complete; output byte-identical to Exp090; 87 bridge candidates checked, 61 context-ok, 0 motion-ok, 0 selected | Do not submit; bridge branch inactive on test set |

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
| LB893 component ablations | Public LB 0.893 likely comes from post-processing, not only the learned backbone | High | Medium | P0 |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| Conservative velocity-aware gap-2 recovery | Added nodes but recovered no annotated edges; exact score fell | Two embryos: edge TP/FP/FN unchanged at 761/63/134; nodes increased 32,471 to 32,619; score 0.794304 -> 0.793540 | Only if a detector change creates demonstrable two-frame misses that recover edge TPs |
