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
| 2026-07-19 | Exp110 ILP birth/death costs | Test-only public run; exact train validation not yet reproduced | 0.909 user-reported | TBD | `notebooks/biohub-exp110-ilp-birth-death-cost-candidate.ipynb` / submission `54826078` | Current best; conservative ILP appearance/disappearance costs `0.0` / `1.4` reduced graph size substantially and broke the 0.903 plateau |
| 2026-07-27 | Exp148 adaptive two-seed edge fusion | Test-only structural harness | **0.913** | TBD | `notebooks/biohub-exp148-adaptive-edge-fusion.ipynb` / submission `55029450` | Current best; fixed 0.475 detection blend and confidence-adaptive edge fusion |
| 2026-08-10 | Exp183 full public association stack | Kaggle structural audit passed | **0.915** | TBD | `notebooks/biohub-exp183-public-ranker-fork.ipynb` / submission `55404125` | Current scored best; global 85/15 ranker, harmonic fusion, edge TTA, and inactive lookahead branch |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-03 | Exact DoG/Hungarian baseline | Offline exact evaluator, physical NMS, centroid refinement, 8 um linking, gap-1 interpolation, pruning | Completed on Kaggle; API output throttled | 0.827 | Successful first submission | Test one conservative gap-2 recovery pass |
| 2026-07-30 | Exp155 doubled safe-division budget | Exp148 backbone; frame cap 0.0076 to 0.0152 and global cap 0.00375 to 0.0075; geometry unchanged | Kaggle structural harness passed | 0.912 | Rejected: additional division proposals cost 0.001 | Move to division precision/evidence, not a 3x budget |
| 2026-07-31 | Exp159 half safe-division budget | Exp148 backbone; caps halved; 213 divisions | Exact output harness passed | 0.913 | Tied Exp148: quantity is flat from 213 to 333 divisions | Improve candidate identity rather than count |
| 2026-07-31 | Exp160 continuous DeepCenter division ranking | Same Exp148 caps; image evidence re-ranks all 367 proposals; 16/333 division sources changed | Exact output harness passed | 0.913 (`55130094`) | Tied Exp148 despite active image-based re-ranking | Stop division-only tuning |
| 2026-07-31 | Exp161 transformer-probability division ranking | Same Exp148 caps; transformer scores cover 60/367 proposals; 3/333 division sources changed | Exact output harness passed | 0.913 (`55129038`) | Tied Exp148; intervention was deliberately small | Stop division-only tuning |
| 2026-07-31 | Exp163 ambiguity-gated association | Learned bonus 1.0 to 3.0 only when top two geometric parent costs are within 0.75 um; 1,656 ambiguous targets; 637 edges replaced | Exact output harness passed | 0.913 (`55141367`) | Tied Exp148 despite changing 637 associations | Close learned-bonus strength axis |
| 2026-08-01 | Exp164 bidirectional crossing repair | Exp148 plus conservative pair swaps scored with predecessor and successor trajectory context | v1/v2: 0 accepted. v3: best feasible improvement only `+0.066 um` at ratio `0.996`; exact output unchanged | Diagnostic only; not submitted | Future-aware pair swapping has no meaningful signal under this cost | Closed; move to a genuinely different graph or detection mechanism |
| 2026-08-02 | Exp165 tiled dense relinking | Exp148 unchanged except overlapping `48 um` / `12 um` local Hungarian relinking on `6bba_05db0fb1` | Kaggle v1 completed; structural harness passed | Submitted as `55184986`; score pending | Targets the known dense-frame parent-assignment bottleneck while preserving three control movies. Controls are graph-identical; dense movie has 687 removed and 652 added edges (edge Jaccard 0.9807), 8 fewer nodes, and 6 more division-like sources | Distinct and valid; await the public score before stacking another structural change |
| 2026-08-02 | Public reverse-time harmonic association | `zoli800/biohub-cell-another-approch-2nd`: forward and reverse primary association logits calibrated and fused with a weighted harmonic mean; also uses D4-style detection TTA and the existing dual-seed low-margin consensus | Public versions scored `0.914`, `0.911`, `0.914`, `0.914`, `0.913` | Inspiration only; not copied or submitted | The reverse-time model-level signal is orthogonal to Exp165's dense spatial relinking and is the most useful transferable idea | If Exp165 does not improve, port only the reverse harmonic fusion into an Exp166 backbone and measure output delta before submission |
| 2026-08-11 | Exp187 constrained ranker rescue | Exp183 stack; ranker mode `low_margin_top2_rescue`; 554 ambiguous rows and 179 rescues; output changed by 5 rows | Structural harness passed | Pending (`55428011`) | Clean private-risk probe: constrains the public ranker to its documented tie-breaker role | Promote only if it beats or credibly matches Exp183; otherwise retain Exp183 |
| 2026-08-11 | Exp188 no-lookahead control | Exp183 with `BIOHUB_USE_FORWARD_ACCELERATION_LOOKAHEAD=0`; no active lookahead bonuses | Exact output signature match | Pending (`55428127`) | Submitted as an explicitly authorized control despite identical predictions: 123,088 nodes, 119,005 edges, 311 divisions | Do not revisit lookahead parameters without evidence of activation |
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
| 2026-07-31 | Exp162 symmetry-aware division ranking | `notebooks/biohub-exp162-symmetry-division-rank.ipynb` | Kaggle v1 complete; exact checks passed; 333 divisions and 7 division sources changed versus Exp148 | Hold as reserve; do not submit while Exp160/161 are pending |
| 2026-07-04 | Prefix-aware classical/learned hybrid | `notebooks/biohub-prefix-hybrid-candidate.ipynb` | Exact hybrid 0.842616; Kaggle v2 completed with a validated 260,287-row output identical to local | Manually submit version 2 and record LB |
| 2026-07-07 | LB893 exact-validation ablation runner | `notebooks/biohub-lb893-validation-ablation.ipynb` | JSON/Python syntax checked locally; requires Kaggle T4 plus `biohub-tracking-support-pack-50ep-v1` | Upload/run `full_lb893` validation, then one-factor ablations |
| 2026-07-08 | LB893 no-safe-divisions test candidate | `notebooks/biohub-lb893-no-safe-divisions-candidate.ipynb` | Kaggle v1 completed; 283,092-row output passed structural checks; public LB 0.886 | Superseded by copied LB893 0.893; use as negative control for division tuning |
| 2026-07-08 | LB893 conservative safe-divisions candidate | `notebooks/biohub-lb893-conservative-safe-divisions-candidate.ipynb` | Kaggle v1 completed; 283,385 rows and 287 safe divisions; structural checks passed | Submitted 2026-07-09 (`54490638`/`54490358`): public LB `0.889`, below copied LB893 `0.893`. Tightening divisions did not beat the baseline. |
| 2026-07-12 | Graph-aware consensus ensemble | `notebooks/biohub-graph-consensus-ensemble.ipynb` | Core + end-to-end cells verified locally (merge/prune/division/anchor/degree tests, ~12 s at scale, valid schema output) | Push kernel, attach the 3 diverse candidate outputs, run; then tune `TAU_*` via `VALIDATION_MODE` |
| 2026-07-16 | Exp084 threshold probe around Exp073 | `notebooks/biohub-exp084-threshold-096875-candidate.ipynb` | Kaggle v1 complete; 252,357 rows, 128,451 nodes, 123,906 edges, 419 division-like sources; structural checks passed; submitted as `54768957` | Pending public LB; decide if threshold helps |
| 2026-07-16 | Exp090 density-adaptive gap probe around Exp073 | `notebooks/biohub-exp090-density-adaptive-gap-candidate.ipynb` | Kaggle v2 complete; 252,231 rows, 128,379 nodes, 123,852 edges; density branch activated with 124 expanded candidates and 52 selected outside base; structural checks passed; submitted as `54768948` | Pending public LB; use to compare density gap effect |
| 2026-07-16 | Exp096 stable long-track bridge probe around Exp073 | `notebooks/biohub-exp096-stable-long-track-bridge-candidate.ipynb` | Kaggle v2 complete; output byte-identical to Exp090; 87 bridge candidates checked, 61 context-ok, 0 motion-ok, 0 selected | Do not submit; bridge branch inactive on test set |
| 2026-07-16 | Exp091 density gap + adaptive short-track rescue | `notebooks/biohub-exp091-density-plus-short-track-rescue-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp091-short-track-rescue`; structural checks passed; short-track rescue recovered 177 nodes in 40 components; submitted as `54769343` | Pending public LB |
| 2026-07-16 | Exp092 threshold 0.96875 + density gap | `notebooks/biohub-exp092-threshold-plus-density-gap-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp092-threshold-plus-density-gap-candidate`; structural checks passed; combines Exp084 threshold with Exp090 density gap; submitted as `54769344` | Pending public LB |
| 2026-07-17 | Exp100 division-risk prune around Exp073 | `notebooks/biohub-exp100-division-risk-prune-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp100-division-risk-prune`; structural checks passed locally; same `128,217` nodes, edges `123,683 -> 123,662`, division-like sources `418 -> 397`; submitted as `54776292` | Rejected by Kaggle as invalid submission format; do not resubmit as-is |
| 2026-07-17 | Exp101 upstream safe-division recall expansion | `notebooks/biohub-exp101-safe-division-recall-expansion-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp101-safe-division-recall-expansion`; structural checks passed; rows `252,174`, nodes `128,316`, edges `123,858`, division-like sources `531`; submitted as `54780672` | Public LB `0.902`; worse than Exp073 |
| 2026-07-17 | Exp102 mild upstream safe-division expansion | `notebooks/biohub-exp102-mild-safe-division-expansion-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp102-mild-safe-division-expansion`; structural checks passed; rows `252,001`, nodes `128,262`, edges `123,739`, division-like sources `442`; submitted as `54781687` | Public LB `0.903`; tied Exp073 |
| 2026-07-17 | Exp103 threshold+density gap plus mild safe divisions | `notebooks/biohub-exp103-threshold-density-mild-division-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp103-threshold-density-mild-division`; structural checks passed; rows `252,784`, nodes `128,656`, edges `124,128`, division-like sources `442`; submitted as `54784028` | Public LB `0.902`; worse than Exp073 |
| 2026-07-17 | Exp104 upstream safe-division precision tightening | `notebooks/biohub-exp104-safe-division-precision-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp104-safe-division-precision`; structural checks passed; rows `251,832`, nodes `128,216`, edges `123,616`, division-like sources `351`; submitted as `54785550` | Public LB `0.903`; tied Exp073 |
| 2026-07-18 | Exp105 weighted gap-node interpolation | `notebooks/biohub-exp105-weighted-gap-interpolation-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp105-weighted-gap-interpolation`; structural checks passed; rows `252,688`, nodes `128,614`, edges `124,074`; weighted motion used for `2019/2020` synthetic gaps; submitted as `54800958` | Public LB `0.903`; tied Exp073 |
| 2026-07-18 | Exp106 density spacing gate | `notebooks/biohub-exp106-density-spacing-gate-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp106-density-spacing-gate`; structural checks passed; rows `252,696`, nodes `128,617`, edges `124,079`, divisions `418` | User manually submitted as `54802933`; public LB `0.903`; tied Exp073 |
| 2026-07-18 | Exp107 density gain 0.0475 | `notebooks/biohub-exp107-density-gain-0475-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp107-density-gain-0475`; structural checks passed; rows `252,696`, nodes `128,616`, edges `124,080`, divisions `418` | User manually submitted as `54802935`; public LB `0.903`; tied Exp073 |
| 2026-07-18 | Exp108 frozen-transition-aware graph recipe | `notebooks/biohub-exp108-frozen-transition-aware-candidate.ipynb` and `notebooks/biohub-exp108-frozen-transition-validation.ipynb` | Candidate Kaggle v2 complete as `dalloliogm/biohub-exp108-frozen-transition-aware`; structural harness passed: `252,282` rows, `128,421` nodes, `123,861` edges, `418` division-like sources. Validation notebook errored and was not used as evidence. | Submitted candidate as `54813931`; status pending |
| 2026-07-18 | Exp109 Exp092/Exp108 one-movie split | `notebooks/biohub-exp109-exp092-exp108-6bba05db-split.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp109-exp092-exp108-6bba05db-split`; structural harness passed: `252,306` rows, `128,435` nodes, `123,871` edges. Uses Exp108 only for `6bba_05db0fb1`; Exp092 for all other datasets. | Submitted as `54815064`; Kaggle rejected with incorrect-format message despite local structural validity. Do not retry CSV-spliced outputs until the checker gap is understood. |
| 2026-07-19 | Exp110 ILP birth/death costs | `notebooks/biohub-exp110-ilp-birth-death-cost-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp110-ilp-birth-death-cost`; structural harness passed: `238,534` rows, `121,403` nodes, `117,131` edges, `320` division-like sources. Exp092-family TTA was already active, so this isolates ILP appearance/disappearance weights `0.0` / `1.4`. | Submitted as `54826078`; public LB `0.909`. This is the new working best and confirms the conservative ILP-cost graph was a productive axis after many `0.903` ties. A public-facing version was pushed as Kaggle v2 after removing private experiment shorthand from the notebook body; v2 completed successfully. |
| 2026-07-19 | Exp111 original-branch exploration | `notebooks/biohub-exp111-original-branch-exploration.ipynb` | Local JSON and Python syntax checks passed. Graph recipe intentionally frozen to Exp092/0.903-family settings; adds `exp111_original_branch_diagnostics.csv` with serialized-edge distance tails, relaxed motion-relink usage, gap additions, division burden, and short-track removal by dataset. | Upload/run on Kaggle T4, download diagnostics, and use them to choose the next targeted candidate. Do not submit by default unless output is materially different or a frozen-reference LB control is needed. |
| 2026-07-19 | Exp112 ILP disappearance 1.2 | `notebooks/biohub-exp112-ilp-disappearance-1-2-candidate.ipynb` | Kaggle v1 complete; structural harness valid with `240,779` rows, `122,541` nodes, `118,238` edges, `336` division-like sources. Compared with Exp110: `+2,245` rows, `+1,138` nodes, `+1,107` edges, `+16` divisions. Evidence: `references/exp112-ilp-disappearance-1-2-v1-output/`. | Submitted second as `54835647`; public LB `0.908`. Denser graph was slightly worse than Exp110. |
| 2026-07-19 | Exp113 ILP disappearance 1.6 | `notebooks/biohub-exp113-ilp-disappearance-1-6-candidate.ipynb` | Kaggle v1 complete; structural harness valid with `235,895` rows, `120,065` nodes, `115,830` edges, `304` division-like sources. Compared with Exp110: `-2,639` rows, `-1,338` nodes, `-1,301` edges, `-16` divisions. Evidence: `references/exp113-ilp-disappearance-1-6-v1-output/`. | Submitted first as `54835643`; public LB `0.909`, tying Exp110. More pruning did not improve public LB. |
| 2026-07-19 | Exp114 ILP disappearance 1.5 | `notebooks/biohub-exp114-ilp-disappearance-1-5-candidate.ipynb` | Kaggle v1 complete; fast structural checks passed with `237,078` rows, `120,663` nodes, `116,415` edges, and `310` division-like sources. Controlled Exp110 follow-up: appearance cost stays `0.0`, disappearance cost changes `1.4 -> 1.5`. | Submitted as `54838832`; public LB `0.909`, tying Exp110. |
| 2026-07-19 | Exp115 ILP disappearance 1.8 | `notebooks/biohub-exp115-ilp-disappearance-1-8-candidate.ipynb` | Kaggle v1 complete; fast structural checks passed with `233,682` rows, `118,940` nodes, `114,742` edges, and `290` division-like sources. Controlled Exp110 follow-up: appearance cost stays `0.0`, disappearance cost changes `1.4 -> 1.8`. | Submitted as `54838833`; public LB `0.909`, tying Exp110. Stronger pruning did not improve public LB. |
| 2026-07-20 | Exp116 minimal ILP direct export | `notebooks/biohub-exp116-minimal-ilp-direct-export-candidate.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp116-minimal-ilp-direct-export`; output SHA256 `dbba5f419e5b341bf0b413154ebf785bcf9caa19857f21f6242b012ebc65cd90`; rows `240,529`, nodes `124,743`, edges `115,786`, divisions `0`; strict structural checks passed. | Submitted as `54845958`; status pending as of 2026-07-20 live check. This is the strict minimal-branch test expected to approach the public `0.950` clean baseline. |
| 2026-07-20 | Exp116 clean public-solution tracker ablation | `notebooks/biohub-exp116-clean-public-solution-ablation.ipynb` | Kaggle v1 complete as `dalloliogm/biohub-exp116-clean-public-solution-ablation`. Starts from public `kaiwalyaatulraut/biohub-cell-tracking-solution`, removes the final negative-time hub/fork augmentation, and adds strict biological output checks. Downloaded `submission.csv` is byte-identical to Exp116 minimal ILP direct export: same SHA256 `dbba5f419e5b341bf0b413154ebf785bcf9caa19857f21f6242b012ebc65cd90`, rows/nodes/edges/divisions all identical. | Do not submit separately unless Kaggle rejects the direct-export kernel for a non-output reason. It would spend a slot on the same predictions. |
| 2026-07-20 | Exp117 ILP division-weight sweep diagnostic | `notebooks/biohub-exp117-ilp-division-weight-sweep.ipynb` | Kaggle v3 complete as `dalloliogm/biohub-exp117-ilp-division-weight-sweep`; writes `exp117_division_sweep.csv`, not a competition submission. Official-metric local aggregate was best at default `ILP_DIVISION_WEIGHT=1.0`: score `0.914831`, forks `0`, division TP/FP/FN `0/0/3`. Making division cheaper created forks but no true positives (`0.5`: 984 forks, 14 div FP, score `0.912502`; negative weights much worse). | Diagnostic resolved: simple division-cost lowering is not the next submission axis. Need better division candidate generation/scoring if we want to recover the division term. |
| 2026-07-27 | Exp148 confidence-adaptive two-seed edge fusion | `notebooks/biohub-exp148-adaptive-edge-fusion.ipynb` | Kaggle v1 completed; structural harness valid with `240,020` rows, `122,107` nodes, `117,913` edges, and `333` division-like sources. Output SHA256 `052a4d5807210868de98fad7c26f0d25bd831a460a3183c5af6fd7d9520146d8` differs from Exp144, with thousands of node/edge changes across all four datasets. Secondary detection weight remains `0.475`; only the two-seed link mode changes to `adaptive`. | Submitted as `55029450`; public LB pending. This tests whether the independent seed can correct ambiguous parent assignments rather than merely reinforce consensus. |

## ILP disappearance sweep: RESOLVED 2026-07-20 — the axis is flat

All five submissions scored, confirming the sweep is saturated:

| Exp | Disappearance | Nodes | Public LB |
| --- | ---: | ---: | ---: |
| Exp112 | 1.2 | 122,541 | `0.908` |
| Exp110 | 1.4 | 121,403 | `0.909` |
| Exp114 | 1.5 | 120,663 | `0.909` |
| Exp113 | 1.6 | 120,065 | `0.909` |
| Exp115 | 1.8 | 118,940 | `0.909` |

A 3.6k-node swing moves the score by at most `0.001`. This is a plateau, not a
peak, and the cause is now known: post-processing discards the ILP edges, so ILP
weights barely reach the submission. See the CRITICAL section in `LEARNINGS.md`.
Stop sweeping ILP costs while the post-processing stack is in place.

## 2026-07-20 STRATEGIC RESET: adopt the minimal branch

Live leaderboard (1414 teams): our `0.909` ranks ~209. Bronze AND silver both
require `>= 0.950`; gold requires `>= 0.968`. The rank curve is a cliff —
`0.940` gives rank ~190, `0.950` gives rank ~46. Incremental tuning below `0.950`
is close to worthless.

`hengck23/minimal-baseline-tta-2gpu` reaches `0.950` with our exact model,
weights, ILP settings, and TTA, by exporting the ILP graph directly with zero
post-processing. Verified clean (no hub/fork hack). The new baseline should be
that notebook, not the Exp073/Exp110 lineage.

| Priority | Action | Expected |
| --- | --- | --- |
| P0 | Run `hengck23/minimal-baseline-tta-2gpu` verbatim, hack-free, as our own kernel | `~0.950` (+0.041) |
| P0 | Use its built-in `MODE="local"` evaluator as the trustworthy local harness we never had | unblocks all tuning |
| P1 | Sweep `POINT_THRESHOLD` and exploit `N_pred < N_true` bonus multiplier | `+0.005-0.015` |
| P1 | Sweep `ILP_DIVISION_WEIGHT` (never once varied; `0.1 * division_jaccard` is ~fully untapped) | `+0.02-0.04` |
| P2 | Compare TTA variants already in the notebook (`4flip`, `8yx`, `8fliprot`, `9public`) | small |
| P2 | Multi-checkpoint / multi-split ensembling at probability-map level | unknown |

## Backlog

### Active 2026-08-13 batch

The minimal direct-export branch is being tested before further post-processing:

| exp | change | status |
| --- | --- | --- |
| exp116 | direct ILP export, point threshold 0.9700, 8-view TTA | submitted `55484317` |
| exp119 | direct ILP export, point threshold 0.9800 | submitted `55484319` |
| exp120 | direct ILP export, point threshold 0.9500 | running |
| exp121 | direct ILP export with 9-public-view TTA | held until selector is verified |

The detection-density/count-calibration axis has also been started in
`notebooks/diagnostics/biohub-detection-density-count-calibration.ipynb`.
Its first pass is diagnostic-only and records per-movie target counts, predicted
counts, node recall, edge metrics, and the node-count multiplier before applying
any calibration. The under-counted `44b6_0b24845f` movie is the primary target;
no count adjustment should be promoted without a frozen direct-export control.

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
| Weighted gap-node interpolation | Recent public notebook changes synthetic gap-node placement using local motion; compatible with Exp073/Exp092 without changing detector | Medium | Low-medium | P0 |
| Outside-base spacing gate for density gaps | Preserve safe base gap mask but require local spacing for extra density-adaptive candidates | Medium | Low | P1 |
| TTA plus ILP-cost branch | Public notebook changes inference averaging and ILP appearance/disappearance costs; broader signal than post-processing only | Medium-high | High | P1 |
| ILP disappearance sweep around Exp110 | Exp110 broke the plateau; sweep `1.2` and `1.6` around the winning `1.4` to determine graph-size direction | Medium-high | Medium | P0 |
| Bright/top-hat detector mix | Alternative detector preprocessing could complement Exp073 errors | Unknown | High | P2 |
| Frozen-transition-aware relink/gap repair | Forum evidence reports systematic exact duplicate adjacent frames in `6bba`; condition motion relinking and gap closing on detected frozen transitions | Medium | Medium | P0 |
| Original-branch diagnostic-driven tuning | Exp111 measures where the 0.903-family branch is fragile before spending more submission slots | Medium | Low | P0 |

## Exp156/157 - Trackastra linker swap: MEASURED AND REJECTED (2026-07-29)

The only pipeline stage never varied was the linker. Exp156 replaced it with
the pretrained Trackastra association transformer (`ctc` checkpoint) over
byte-identical detections and scored every arm with the official metric on the
labelled train movies. Evidence:
`references/exp156-trackastra-headtohead-v1-output/`.

| arm | adjJ all | adjJ 6bba | edges | forks | agreement with ILP |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ilp_only` | **`0.9099`** | `0.9030` | 138,671 | `0` | `1.000` |
| `incumbent_full` | `0.8936` | `0.8877` | 140,022 | `363` | `0.891` |
| `trackastra_s2` | `0.8304` | `0.8207` | 138,321 | `2,485` | `0.912` |
| `trackastra_s3` | `0.8631` | `0.8567` | 140,488 | `1,678` | `0.926` |
| `trackastra_s4` | `0.8596` | `0.8555` | 139,059 | `1,376` | `0.919` |

The best Trackastra arm is `-0.031` against `incumbent_full` and `-0.047`
against `ilp_only`. The pre-registered decision rule was "submit only if within
~`0.01` of `incumbent_full`, so Exp156 itself remained diagnostic and spent no
slot. Exp157 was later submitted because the local harness is known to invert
some graph-construction rankings; its live `0.898` result confirmed the local
rejection.

Per movie, the loss concentrates exactly where the metric weight is. On
`6bba_05db0fb1` (700 detections/frame, ~56% of local weight) Trackastra scores
`0.786` against `ilp_only`'s `0.859`. It does not win on any movie at its best
overall scale.

**Mechanism: association quality in dense frames.** The natural hypothesis was
division over-firing - Trackastra emits `1,376`-`2,485` forks where the
incumbent emits `363` and the raw ILP emits `0`. That was tested directly and
rejected: re-linking the dense movie with `allow_divisions=False` drops forks to
zero and moves edge agreement by `+0.002` (`0.723 -> 0.725` at scale `3.0`,
`0.800 -> 0.803` at scale `4.0`). The forks are a genuine risk under capped
division credit, but they are not what costs the score.

What does track the failure is sequence length. `6bba_05db0fb1` puts ~2,900
tokens in each 4-frame window against the `max_tokens: 1024` the model was
trained with. Agreement with our ILP edges falls from `0.96` on the sparse
movie to `0.72`-`0.80` on the dense one, and edge false positives there rise
from `88` (`ilp_only`) to `163` (`trackastra_s3`). Trackastra essentially ties
`ilp_only` on the sparse movies (`44b6_33b596bf` `0.9953` vs `0.9953`).

**What was NOT the problem** (so nobody re-tests it): the 2D/3D question - the
`ctc` checkpoint is natively 3D; offline packaging - the mirror ships a
pure-python wheel; masks - `WRFeatures` builds fine from centroids; the greedy
acceptance threshold - inert from `0.5` down to `0.01`; and coordinate scale -
a per-movie ORACLE scores `0.8642` against fixed-`3.0`'s `0.8631`, so the whole
axis is worth `0.001` and adaptive scale selection is not worth building.

Exp157 (`notebooks/biohub-exp157-trackastra-linker-candidate.ipynb`) is the
submission-shaped version: the Exp148 backbone with only the association stage
swapped, behind `BIOHUB_USE_TRACKASTRA_LINKER`. Its v1 run failed on a scope
bug (`torch` unbound in the bootstrap cell), which was fixed in v2. Because the
local harness can invert graph-construction rankings, v2 was submitted as
`55092602`; its public LB score was **`0.898`**, decisively below Exp148's
`0.913`. The live result confirms the diagnostic rejection. Reviving it via
division gating is ruled out by the probe above; the only lead with support is
spatially tiling dense frames into sub-windows within the model's ~1024-token
budget - a real build whose likely upside is parity with `ilp_only`, not a gain
over the incumbent post-processing stack.

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| Conservative velocity-aware gap-2 recovery | Added nodes but recovered no annotated edges; exact score fell | Two embryos: edge TP/FP/FN unchanged at 761/63/134; nodes increased 32,471 to 32,619; score 0.794304 -> 0.793540 | Only if a detector change creates demonstrable two-frame misses that recover edge TPs |
