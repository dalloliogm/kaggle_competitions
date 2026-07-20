# Tasks

## READ FIRST - 2026-07-20 CORRECTION (supersedes the earlier "strategic reset")

**The earlier reset was wrong and is retracted. See the RETRACTION section at the
top of `LEARNINGS.md`.**

Measured public LB, not inferred:

| Branch | Config | Divisions | Public LB |
| --- | --- | ---: | ---: |
| Exp110 post-processing | Exp073 family + ILP 0.0/1.4 | 320 | **`0.909`** |
| Exp116 minimal, clean | identical to hengck23 notebook | 0 | `0.877` |

**The minimal branch is WORSE by `0.032`. Post-processing ADDS score.** Exp110
remains the working baseline. Do not delete the post-processing stack.

Why the earlier claim was wrong: I attributed the `0.950` leaderboard score of
the *author* hengck23 to their public notebook. A team's LB entry is the best of
all their submissions (hengck23 had 12), not any single notebook's score.

Because clean minimal = `0.877` while hacked forks = `0.950`, **the division
hack is still paying `+0.073` on the live leaderboard** - the patch is not yet
live in scoring. The `0.950` cluster is hack-inflated and should collapse toward
~`0.877` on rescore. Our clean `0.909` already sits above that. **Do not chase
`0.950`, and do not copy the hack.**

Axes closed by measurement - do NOT re-test:
- ILP division weight (Exp117): `1.0` optimal.
- ILP cost grid on minimal branch (Exp118): inherited `0.0 / 1.4 / -1.0` already
  optimal; all 10 configs within `0.007`.
- ILP disappearance on the old branch (Exp110-115): flat `0.908`-`0.909`.

Most promising open direction: divisions. Exp110's `320` safe divisions are the
most plausible source of its `+0.032` over the division-free minimal branch, and
the old no-safe-divisions test (`0.886` vs `0.893`) points the same way. Exp117's
"zero division TPs" was a local artifact - the labelled split has only `3`
annotated divisions, so it had no power to measure this.

## Superseded: earlier strategic reset (2026-07-20, RETRACTED)

The Exp073/Exp110 post-processing branch is a dead end. Full reasoning and
evidence is in `LEARNINGS.md` (see the CRITICAL section). Summary:

- `hengck23/minimal-baseline-tta-2gpu` scores public LB `0.950` using the SAME
  weights pack, ILP costs, threshold, and D4 TTA as Exp110 (`0.909`), differing
  only in that it exports the ILP graph verbatim with NO post-processing.
- Our `filter_output_graph` step 4 (`edges = motion_edges`) discards all
  ~114,860 ILP edges and rebuilds them with a greedy causal Hungarian sweep. The
  global optimum is thrown away, which is why the ILP cost sweep is flat
  (`1.2 -> 0.908`; `1.4/1.5/1.6/1.8 -> 0.909`) and why the whole heavy
  post-processing lineage is stuck at `0.903` (`pilkwang` 80 subs, `beicicc` 71).
- Live LB: 1414 teams. Our `0.909` is rank ~209. Bronze AND silver both need
  `>= 0.950`; gold needs `>= 0.968`. The curve is a cliff: `0.940` -> rank ~190,
  `0.950` -> rank ~46. Tuning below `0.950` is close to worthless.
- The `0.950` cluster is NOT the division exploit. Hacked forks score the same
  as the clean original, so the patch is already live in scoring.

DO NOT resume tuning motion relink, gap closing, safe divisions, short-track
filtering, or ILP costs on top of the old post-processing stack.

## SUBMISSION SLOT COORDINATION - 2026-07-20 (read before submitting)

Two agents share ONE budget of 5 submissions/day. User decision: **the Claude
Code instance submits; the Codex instance keeps ONE slot in reserve.**

Actual usage for UTC day 2026-07-20, verified against `kaggle competitions
submissions` (an earlier version of this table over-counted - Exp120 was listed
as spent but never pushed):

| # | Submission | Result |
| ---: | --- | --- |
| 1 | Exp116 minimal ILP direct export (`54845958`) | **`0.877`** - minimal branch REJECTED |
| 2 | Exp119 minimal, threshold `0.98` (`54848728`) | PENDING; expected ~`0.877`, likely a spent slot |
| 3 | free - Claude | hold for an informed Exp110-branch candidate |
| 4 | free - Claude | hold |
| 5 | **RESERVED - Codex instance** | free |

Do not submit minimal-branch variants: that branch measures `0.877` against
Exp110's `0.909`. Exp120 (threshold `0.95`, minimal) was cancelled for this reason
and should not be revived.

Do NOT re-submit `biohub-exp116-clean-public-solution-ablation`: byte-identical
output to the direct-export kernel (SHA256
`dbba5f419e5b341bf0b413154ebf785bcf9caa19857f21f6242b012ebc65cd90`).

Kaggle evaluation is taking 5+ hours, so a wasted slot is lost for the day.

## Operational gotchas

- Kaggle caps **concurrent batch GPU sessions at 2**. Further pushes fail with
  `Maximum batch GPU session count of 2 reached`; retry when one frees.
- Kaggle derives the kernel slug from the **title**, not the metadata `id`. A
  title containing `0.9800` produced slug `...-0-9800`, and `kernels status` on
  the intended id returned a permission error. Submission with
  `-k owner/slug -v <version>` needs the slug from the notebook URL.

## Current Goal

- Strict strategy decision on 2026-07-20: stay with biologically plausible
  trackers. Do not add negative-time hubs, impossible coordinates, or artificial
  fork chains from metric-hack public notebooks unless the user explicitly
  reopens a metric-risk branch. This is now also the pragmatic choice, not only
  the principled one: the hack is scoring-neutral post-patch (hacked forks score
  the same `0.950` as the clean original).
- **Exp116 - TWO INDEPENDENT IMPLEMENTATIONS CONVERGED.** Both agents built the
  same minimal pipeline from different starting points on 2026-07-20:
  - `notebooks/biohub-exp116-minimal-ilp-direct-export-candidate.ipynb` ->
    `dalloliogm/biohub-exp116-minimal-ilp-direct-export`, derived from
    `hengck23/minimal-baseline-tta-2gpu` (already clean). Kernel v1 COMPLETE:
    `240,529` rows, `124,743` nodes, `115,786` edges, **0 divisions**, all
    structural checks passed. Submitted as `54845958`, PENDING as of 07:22.
  - `notebooks/biohub-exp116-clean-public-solution-ablation.ipynb` ->
    `dalloliogm/biohub-exp116-clean-public-solution-ablation`, derived from
    `kaiwalyaatulraut/biohub-cell-tracking-solution` with the hack stripped.
  Both carry identical config (`POINT_THRESHOLD 0.9700`, ILP
  `-1.0 / 0.0 / 1.4 / 1.0`, `USE_TTA=True`, same 50ep weights pack) because
  kaiwalyaatulraut is a verbatim copy of hengck23 plus the hub hack. Expect
  near-identical outputs. Downloaded outputs are byte-identical:
  SHA256 `dbba5f419e5b341bf0b413154ebf785bcf9caa19857f21f6242b012ebc65cd90`,
  `240,529` rows, `124,743` nodes, `115,786` edges, **0 divisions**. Do not spend
  a second submission slot on the clean-ablation kernel while the direct-export
  submission is pending.
- **Exp117** (`dalloliogm/biohub-exp117-ilp-division-weight-sweep`) is a
  diagnostic that writes NO submission and costs NO slot. It sweeps
  `ILP_DIVISION_WEIGHT` over `[1.0, 0.5, 0.25, 0.0, -0.25, -0.5, -1.0]`, reusing
  one cached inference pass per movie, and scores every setting with the OFFICIAL
  metric on labelled train movies. This doubles as the trustworthy offline
  harness the workspace has lacked. Kernel v3 COMPLETE. Local aggregate score was
  best at the inherited default `division_weight=1.0` (`0.914831`, 0 forks);
  making divisions cheaper created many forks but no division true positives on
  the labelled split (`division_weight=0.5`: 984 forks, 14 div FP, 0 div TP,
  score `0.912502`; negative weights worse). Conclusion: division improvement
  needs better division candidates/scoring, not only cheaper ILP division cost.
  v1 failed on a float-index bug, v2 on `GraphView.copy()` - both fixed (see
  Gotchas).
- Submission mechanism for this code competition: raw CSV upload fails with a
  generic `400`. Use
  `kaggle competitions submit <slug> -k owner/kernel-slug -v <version> -f submission.csv -m "..."`
  as documented in `.codex/skills/kaggle-competition-workspace/SKILL.md`.

## Gotchas when reusing the minimal notebook

- `np.savez` round-trips everything as float64. `build_graph` uses the edge
  endpoints as list indices, so they must be cast back to `int`.
- `ILPSolver.solve()` returns a `GraphView`. The official `evaluate()` internally
  calls `pred_graph.copy()`, which `GraphView` rejects - call `.detach()` first.
  hengck23's notebook sidesteps this by round-tripping through geff.

## Open findings worth acting on

- **The ILP never emits a division.** Exp116 has max outdegree 1 across all
  `115,786` edges. `ILP_DIVISION_WEIGHT=1.0` was inherited and never varied
  across Exp110-115. Exp110's `320` "division-like sources" came from
  `add_safe_divisions_postlink` (post-processing), not the optimizer. So the
  whole `0.1 * division_jaccard` term is unclaimed, and Exp101-104 were tuning a
  heuristic bolted onto an optimizer that was silently refusing to divide.
  Exp117 tests both cost directions because the tracksdata sign convention is
  unverified.
- **GT labels are very unevenly distributed.** Measured GT edge counts:
  `44b6_0113de3b` 50, `44b6_0b24845f` 49, `6bba_05b6850b` 845,
  `6bba_05db0fb1` 1,183, `44b6_33b596bf` 49. Since `adj_edge_jaccard` is
  weight-averaged by `TP+FP+FN`, any local score is ~95% determined by the two
  6bba movies. Treat local conclusions as 6bba-specific.
- **We under-predict `44b6_0b24845f` by ~30%** (`22,937` nodes vs
  `n_total = 32,795`). ~10k cells never detected in that movie. This contradicts
  the earlier "detection is solved" conclusion, which rested on
  `node_recall ~ 1.0` measured only on the two well-labelled movies. Unexplored.
- Measured `n_total` per movie (for node-count calibration; the metric pays a
  bonus multiplier > 1 when `N_pred < N_true`):
  `44b6_0113de3b` 25,755, `44b6_0b24845f` 32,795, `6bba_05b6850b` 6,362,
  `6bba_05db0fb1` 69,800, `44b6_33b596bf` 23,330.

## Superseded goals (kept for history)

- Publish a readable public version of
  `dalloliogm/biohub-exp110-ilp-birth-death-cost` (Kaggle v2 completed
  successfully). Low value now that the branch is superseded.
- Improve beyond Exp110 public LB `0.909` (verified from Kaggle submissions on
  2026-07-20). Exp073 `0.903`, copied LB893 `0.893`, no-safe `0.886`, and
  conservative-safe `0.889` are all superseded.
- Submission `54758569`, copied `dalloliogm/biohub-exp073-gap-5-8-public`,
  completed with public LB `0.903`, byte-identical to `lucashmateo/biohub-ct-exp073`.
- `scripts/biohub_validation_harness.py` remains useful for STRUCTURAL checks,
  but Exp117 supersedes it for official-metric scoring.

## Next Experiments

- Run one-factor improvements around Exp073:
  `DET_THRESHOLD=0.96875`, gap-close radius, short-track filtering, density-
  adaptive gap close, and stable long-track bridge extension.
- Current completed candidate: Exp073 + only `DET_THRESHOLD=0.96875` (Exp084
  idea), implemented as
  `notebooks/biohub-exp084-threshold-096875-candidate.ipynb`. Kaggle v1 completed
  with valid output, was submitted as `54768957`, and tied Exp073 with public LB
  `0.903`.
- Second recommended probe: Exp073 + density-adaptive gap close from
  `romanrozen/biohub-best-score`, implemented as
  `notebooks/biohub-exp090-density-adaptive-gap-candidate.ipynb` with adaptive
  short-track rescue disabled for the first controlled run.
- Third recommended probe: Exp073 + stable long-track bridge extension from
  `yusuketogashi/biohub-another-approach`, implemented as
  `notebooks/biohub-exp096-stable-long-track-bridge-candidate.ipynb`; run only
  after Exp090 so the bridge effect can be separated from density adaptation.
- Current division-calibration probe: Exp100 post-processes the Exp073 output by
  pruning the farther daughter edge for the top 5% riskiest division-like
  parents. Kaggle v1 completed as `dalloliogm/biohub-exp100-division-risk-prune`
  and was submitted as `54776292`; Kaggle rejected it as invalid submission
  format despite passing local structural checks. Do not resubmit Exp100 as-is.
- Current upstream division-calibration probe: Exp101 loosens Exp073 safe-division
  insertion gates/caps before graph serialization. Kaggle v1 completed as
  `dalloliogm/biohub-exp101-safe-division-recall-expansion`; structural checks
  passed and submission `54780672` is pending public LB.
- Second upstream division-calibration probe: Exp102 is a milder safe-division
  expansion between Exp073 and Exp101. Kaggle v1 completed as
  `dalloliogm/biohub-exp102-mild-safe-division-expansion`; structural checks
  passed and submission `54781687` is pending public LB.
- Third batch probe: Exp103 combines Exp092 threshold+density-gap behavior with
  Exp102's mild safe-division settings. Kaggle v1 completed as
  `dalloliogm/biohub-exp103-threshold-density-mild-division`; structural checks
  passed and submission `54784028` is pending public LB.
- Fourth batch probe: Exp104 tests the precision side of Exp073 by tightening
  safe-division insertion upstream (`4.42`, `7.90`, `7.25`, `0.0069`,
  `0.0033`) instead of post-hoc edge deletion. Kaggle v1 completed as
  `dalloliogm/biohub-exp104-safe-division-precision`; structural checks passed
  and submission `54785550` scored public LB `0.903`, tying Exp073.
- Current next probe: Exp105 weighted gap-node interpolation. This keeps the
  Exp092 threshold+density-gap graph recipe but places inserted synthetic gap
  nodes using a local-motion blend (`BIOHUB_GAP_MIDPOINT_MOTION_WEIGHT=0.5`,
  clamp `4.0 um`) instead of a pure midpoint. Notebook:
  `notebooks/biohub-exp105-weighted-gap-interpolation-candidate.ipynb`. Kaggle
  v1 completed as `dalloliogm/biohub-exp105-weighted-gap-interpolation`;
  structural checks passed and submission `54800958` scored public LB `0.903`,
  tying Exp073.
- Parallel queued probe: Exp106 density spacing gate. This keeps Exp092's
  midpoint/refinement behavior, raises density-gap gain to `0.04375`, and blocks
  candidates outside the reference `0.040` density mask unless local spacing is
  at least `8.50 um`. Notebook:
  `notebooks/biohub-exp106-density-spacing-gate-candidate.ipynb`. Kaggle v1
  completed as `dalloliogm/biohub-exp106-density-spacing-gate`; structural checks
  passed with rows `252,696`, nodes `128,617`, edges `124,079`, and divisions
  `418`. CLI submit attempts returned HTTP 400 `CreateSubmission`; the user
  manually submitted it as `54802933`; public LB `0.903`, tying Exp073.
- Additional queued probe: Exp107 density gain `0.0475`. This keeps Exp092's
  midpoint/refinement behavior and all safe-division settings, changing only
  `BIOHUB_GAP_DENSITY_GAIN` from `0.040` to `0.0475`. Notebook:
  `notebooks/biohub-exp107-density-gain-0475-candidate.ipynb`. Kaggle v1
  completed as `dalloliogm/biohub-exp107-density-gain-0475`; structural checks
  passed with rows `252,696`, nodes `128,616`, edges `124,080`, and divisions
  `418`. CLI submit attempts returned HTTP 400 `CreateSubmission`; the user
  manually submitted it as `54802935`; public LB `0.903`, tying Exp073.
- Forum-derived next probe: build an original frozen-transition-aware candidate
  on top of Exp073/Exp092. Detect exact or near-exact duplicate adjacent frames
  in each test movie; across frozen transitions prefer zero/near-zero
  displacement links and suppress normal extrapolation; after a frozen run ends,
  allow a small one-step relaxed jump gate because real motion may be accumulated.
  Keep this conditional on detected duplicated transitions only.
- Prepared Exp108 frozen-transition-aware notebooks:
  `notebooks/biohub-exp108-frozen-transition-validation.ipynb` for labeled-train
  exact validation and
  `notebooks/biohub-exp108-frozen-transition-aware-candidate.ipynb` for test
  inference. The graph delta is conditional: exact duplicated adjacent frames use
  a near-zero relink gate with no velocity extrapolation; the first transition
  after a frozen pair uses a relaxed no-velocity release gate; gap closing through
  frozen pairs is suppressed. Local notebook Python syntax checks passed.
- Exp108 candidate completed on Kaggle v2 as
  `dalloliogm/biohub-exp108-frozen-transition-aware`; downloaded output passed
  `scripts/biohub_validation_harness.py --skip-metric` with `252,282` rows,
  `128,421` nodes, `123,861` edges, and no structural warnings. Frozen handling
  activated only for the `6bba` movies (`10` exact frozen pairs each). Submitted
  notebook version 2 with output `submission.csv` as Kaggle submission
  `54813931`; current status `PENDING`. The paired Exp108 train-validation
  kernel errored and should not be treated as validation evidence.
- Last-slot split candidate Exp109:
  `notebooks/biohub-exp109-exp092-exp108-6bba05db-split.ipynb`. It is a
  CSV-only notebook that uses Exp092 for `44b6_0113de3b`, `44b6_0b24845f`, and
  `6bba_05b6850b`, and Exp108 only for `6bba_05db0fb1`. Kaggle v1 completed as
  `dalloliogm/biohub-exp109-exp092-exp108-6bba05db-split`; downloaded output
  passed the structural harness with `252,306` rows, `128,435` nodes,
  `123,871` edges, and no warnings. Submitted as Kaggle submission `54815064`;
  Kaggle rejected it with the generic incorrect-format message. This is a
  checker gap: local schema, dtype, dataset coverage, contiguous row IDs, and
  dangling-edge checks all passed, but the competition-side validation still
  failed. Do not spend more slots on direct CSV-spliced outputs until the
  stricter failure condition is identified.
- Add component-size diagnostics to the submission validator before any stronger
  graph repair. The forum reports scoring timeouts may depend on connected
  component structure, not just node count.
- Integrate `scripts/biohub_validation_harness.py` into every new candidate
  notebook immediately after writing `submission.csv`. Require a valid
  `validation_report.json` before submission.
- Build a train-mode Exp073/Exp092 runner that emits candidate train predictions
  and calls the harness with `--train-dir` and `--tracking-repo`, so controlled
  exact validation becomes routine rather than notebook-specific.
- Medium-effort forum-derived branch: affinity rescoring from existing learned
  edge probabilities plus local motion consistency, inspired by the temporal
  affinity/flow-field discussion. Do this after the frozen-transition probe or
  when current Exp105/106/107 results return.
- Public-notebook follow-up plan from the 2026-07-17 scan:
  1. Exp105 weighted gap-node interpolation, using local motion to place
     inserted gap nodes instead of pure midpoint placement.
  2. Exp106 outside-base spacing gate for density-adaptive gap candidates,
     initially `8.50 um`, if density-gap branches look promising.
  3. Exp107 TTA plus ILP-cost branch, higher runtime and broader changes.
  4. Larger detector-preprocessing branch from bright/top-hat U-Net mix only
     after inspecting its weight artifact and output density.
  Detailed notes: `references/recent-public-notebooks-2026-07-17.md`.
- Current breakthrough: Exp110 ILP birth/death costs. Inspection of Exp092/107/108
  logs showed that D4-style detection TTA was already active, so this is not a
  new TTA enablement experiment. It keeps the Exp092 threshold+density-gap graph
  recipe and changes only ILP appearance/disappearance weights to `0.0` / `1.4`,
  matching the public TTA/ILP-cost idea's distinctive cost setting. Notebook:
  `notebooks/biohub-exp110-ilp-birth-death-cost-candidate.ipynb`. Kaggle v1
  completed as `dalloliogm/biohub-exp110-ilp-birth-death-cost`; downloaded
  output passed the structural harness with `238,534` rows, `121,403` nodes,
  `117,131` edges, `320` division-like sources, and no warnings. It is
  materially different from Exp092: `12,141` semantic rows added and `26,292`
  removed. This satisfies the "do not submit if count-identical" rule, but it is
  a more conservative graph, so the strategic question is whether to spend a
  slot testing fewer nodes/edges/divisions after many `0.903` ties. Submitted as
  Kaggle submission `54826078`; user reported completed public LB `0.909`. This
  breaks the repeated `0.903` plateau and makes ILP-cost/graph-size calibration
  the highest-priority follow-up axis. CLI verification remains pending because
  the approval service rejected live Kaggle polling in the recording turn.
- Prepared controlled Exp110 follow-ups:
  `notebooks/biohub-exp112-ilp-disappearance-1-2-candidate.ipynb` and
  `notebooks/biohub-exp113-ilp-disappearance-1-6-candidate.ipynb`. Both keep ILP
  appearance cost at `0.0` and change only disappearance cost around Exp110's
  winning `1.4` setting (`1.2` tests less aggressive pruning; `1.6` tests more
  aggressive pruning). Local notebook JSON and Python syntax checks passed.
  Next action: upload/run both on Kaggle T4, download outputs, run the structural
  harness, compare row/node/edge/division deltas against Exp110, then decide
  which if any deserves a submission slot. Uploaded both as Kaggle v1 kernels on
  2026-07-19; both initially reported `RUNNING`.
- Exp112 and Exp113 completed on Kaggle and both passed the structural harness
  with no warnings. Exp112 (`disappearance=1.2`) produced `240,779` rows,
  `122,541` nodes, `118,238` edges, and `336` division-like sources; versus
  Exp110 this is `+2,245` rows, `+1,138` nodes, `+1,107` edges, and `+16`
  divisions. Exp113 (`disappearance=1.6`) produced `235,895` rows, `120,065`
  nodes, `115,830` edges, and `304` division-like sources; versus Exp110 this is
  `-2,639` rows, `-1,338` nodes, `-1,301` edges, and `-16` divisions. Evidence:
  `references/exp112-ilp-disappearance-1-2-v1-output/` and
  `references/exp113-ilp-disappearance-1-6-v1-output/`. If only one gets a slot,
  prefer Exp113 because it continues the pruning direction that likely drove
  Exp110's `0.909`; Exp112 is a useful control for whether Exp110 over-pruned.
- User manually submitted both Exp112 and Exp113 on 2026-07-19. Live Kaggle list
  shows two new pending blank-description submissions: `54835643` at
  `17:02:32.247` and `54835647` at `17:02:40.103`. Because descriptions are
  blank, the user clarified the order: Exp113 was submitted first as `54835643`,
  and Exp112 was submitted second as `54835647`. Both have now completed:
  Exp113 scored public LB `0.909`, tying Exp110; Exp112 scored public LB `0.908`,
  so relaxing the disappearance penalty back toward denser graphs appears worse.
- Prepared two more same-day ILP-cost candidates while Exp112/Exp113 are pending:
  `notebooks/biohub-exp114-ilp-disappearance-1-5-candidate.ipynb` and
  `notebooks/biohub-exp115-ilp-disappearance-1-8-candidate.ipynb`. Both keep ILP
  appearance cost `0.0` and change only disappearance cost. Exp114 (`1.5`) is a
  near-optimum interpolation between Exp110 `1.4` and Exp113 `1.6`; Exp115
  (`1.8`) tests stronger pruning. Local notebook JSON and Python syntax checks
  passed. Next action: upload/run both on Kaggle, download outputs, run
  structural validation, then submit manually if valid and materially different.
  Uploaded both as Kaggle v1 kernels on 2026-07-19; both initially reported
  `RUNNING`.
- Exp114 and Exp115 completed on Kaggle on 2026-07-19. Downloaded outputs passed
  fast structural checks. Exp114 produced `237,078` rows, `120,663` nodes,
  `116,415` edges, and `310` division-like sources; submitted as `54838832`,
  and scored public LB `0.909`. Exp115 produced `233,682` rows, `118,940` nodes, `114,742`
  edges, and `290` division-like sources; submitted as `54838833`, status
  `COMPLETE`, public LB `0.909`. A direct raw-CSV submission attempt returned Kaggle `400 Bad
  Request`; code-submitting the completed kernel versions with `-k ... -v 1 -f
  submission.csv` succeeded. This means the disappearance-cost sweep from `1.4`
  to `1.8` is flat on public LB, while `1.2` is slightly worse; do not keep
  spending slots on tiny disappearance-cost changes without new validation
  evidence.
- Operating rule for the rest of this challenge: Kaggle submissions may take
  several hours to validate, and user time is limited. If daily submission slots
  remain, run/validate/submit multiple independent candidates without waiting for
  the previous pending submission to score. Later, compare all completed public
  LB results together.
- Do not spend more slots on LB893 safe-division-only tuning unless Exp073-family
  probes regress sharply.
- Prepared strict Exp116 clean-public-solution ablation:
  `notebooks/biohub-exp116-clean-public-solution-ablation.ipynb`. It starts from
  public `kaiwalyaatulraut/biohub-cell-tracking-solution` but removes the final
  negative-time hub/fork augmentation and adds strict checks rejecting negative
  frame indices, negative coordinates, dangling edges, nulls, and malformed row
  IDs. Purpose: measure the real learned+ILP tracker without metric-hack graph
  structures. Local notebook JSON and Python syntax checks passed; upload/run on
  Kaggle next. Uploaded as Kaggle v1 on 2026-07-20:
  `dalloliogm/biohub-exp116-clean-public-solution-ablation`; initial status
  `RUNNING`.
- Manually submit Kaggle version 1 of
  `dalloliogm/biohub-lb893-conservative-safe-divisions-candidate` and record the
  public LB before further safe-division tuning.
- Run one-factor ablations from `references/lb893-v1-output/ablation_plan.json`,
  continuing with `no_motion_relink`, `no_gap_close`, `no_gap2`, and
  `no_linefit`.
- Prioritize `no_gap2` and `no_gap_close` after safe-division tuning; these
  components add many synthetic nodes/edges and may be easier to improve without
  relying on division-heavy validation.
- PREPARED: `notebooks/biohub-lb893-nogap2-candidate.ipynb` and
  `notebooks/biohub-lb893-nogapclose-candidate.ipynb`. Each = the conservative
  candidate's proven machinery on the default `safe_div_precision_050` preset
  (the full LB893 `0.893` baseline) with exactly one flag flipped
  (`BIOHUB_OUTPUT_GAP2_RECOVERY=0` / `BIOHUB_OUTPUT_GAP_CLOSE=0`) and no safe-div
  tightening. Run each with `VALIDATE_FIRST=True` first, compare exact score to
  the full_lb893 baseline `0.954802`, and only submit the winner
  (`VALIDATE_FIRST=False`).
- Push and run `notebooks/biohub-graph-consensus-ensemble.ipynb`. Attach the
  three diverse candidate outputs (LB893 `0.893` anchor, classical NMS-3.8
  `0.834`, learned U-Net/ILP `0.810`), verify the pairwise-agreement matrix shows
  real diversity, submit the consensus `submission.csv`, and record public LB.
- Optionally run the notebook's discovery layer once with `DISCOVER_PUBLIC=1`
  (internet ON + Kaggle/OpenRouter secrets) to auto-pull ORIGINAL public
  tracking pipelines as extra sources; then re-run internet-off to submit. Sanity
  check the LLM keep/drop decisions before trusting them.
- Then tune the ensemble `TAU_NODE_FRAC`/`TAU_EDGE_FRAC`/`TAU_DIV_FRAC` with
  `VALIDATION_MODE=1` on labeled train movies (needs per-source train submissions
  + support pack) before further submissions.

## Done

- Initialized the competition workspace and downloaded Kaggle overview,
  evaluation, rules, and file-list references.
- Queried the top public notebooks by votes/hotness, downloaded nine
  representative sources, and recorded the source-level comparison in
  `references/top-notebooks-analysis.md`.
- Created `notebooks/biohub-exact-dog-hungarian-baseline.ipynb` with the frozen
  official metric implementation, an exact-metric smoke test, one-video-per-embryo
  validation, full test inference, and submission-schema checks.
- Passed notebook JSON/Python syntax validation and synthetic tests for DoG
  detection, Hungarian linking, interpolated one-frame gap closure, and pruning.
- Prepared Kaggle kernel metadata with the competition and
  `thibautgoldsborough/cellmot-baseline-artifacts` attached.
- Uploaded private Kaggle kernel version 4 as
  `dalloliogm/biohub-exact-validation-and-dog-hungarian-baseline`. Version 4
  passed the exact-metric toy test, then finished with error before producing a
  real validation result. Versions 1 and 3 exposed dependency setup failures;
  version 2 lacked attached inputs and was superseded immediately.
- Fixed offline GEFF/Zarr evaluation in version 7, which completed successfully.
- Submitted version 7 as Kaggle submission `54297736`; public score `0.827`.
- Created and uploaded `notebooks/biohub-cell-tracking-competition-tutorial.ipynb`,
  including the expanded Hungarian-assignment explanation.
- Created `notebooks/biohub-gap2-velocity-ablation.ipynb`. It changes only the
  gap-2 recovery switch, shares detections between variants, compares exact
  metrics by embryo, and automatically falls back to the frozen baseline unless
  the candidate improves overall without a regression worse than `0.002`.
- Passed notebook JSON/Python validation and a structural test confirming one
  accepted `t -> t+3` bridge inserts exactly two nodes and three consecutive edges.
- Completed the exact gap-2 ablation. Baseline scored `0.794304`; candidate
  `0.793540` (delta `-0.000764`). Edge counts were identical, while candidate
  nodes increased from `32,471` to `32,619`; automatic selection kept baseline.
- Created validation-only `notebooks/biohub-detector-screening.ipynb` with the
  frozen baseline plus one-factor threshold `0.030/0.060` and physical-NMS
  `2.8/3.8 um` candidates. Local syntax and config-isolation checks passed.
- Completed the exact detector screen. NMS `3.8 um` scored `0.810458` versus
  baseline `0.794304` (`+0.016153`) and improved both held-out embryos.
- Created `notebooks/biohub-nms38-candidate.ipynb` with candidate-only delta
  `min_distance_um=3.8`, exact validation, full test inference, and schema checks.
  Local JSON/Python and config-isolation checks passed.
- Kaggle candidate version 1 completed. It reproduced exact validation
  `0.8104577161`, processed all four test movies, passed edge endpoint/schema
  assertions, and wrote a `235,923`-row `submission.csv`.
- Submitted NMS `3.8 um` as `54307212`; public LB improved `0.827 -> 0.834`.
- Leaderboard snapshot: rank `203/630`; approximate top-10% cutoff `0.856`.
- Created validation-only `notebooks/biohub-learned-unet-ilp-validation.ipynb`.
  It isolates artifact dependencies, runs the real pretrained U-Net/transformer/ILP
  script, scores predicted GEFF graphs exactly, and cannot emit a submission.
- Passed notebook JSON/Python validation and syntax validation of the embedded
  exact-metric runner. Full execution requires the Kaggle artifact and GPU.
- Learned validation version 1 failed because Kaggle assigned a P100 incompatible
  with PyTorch 2.10 (`sm_60` unsupported). Version 2 pinned a Tesla T4 and passed.
- Default learned exact score: `0.8394088969`, delta `+0.0289511808` versus the
  NMS-3.8 classical benchmark; aggregate edge TP/FP/FN `815/58/80`.
- Created `notebooks/biohub-learned-unet-ilp-candidate.ipynb` with locked learned
  parameters, isolated GEFF-to-CSV conversion, full dataset/schema assertions,
  and no automatic submission. Notebook and embedded writer compile locally.
- Uploaded learned candidate version 1 with a Tesla T4. The kernel completed in
  472 seconds and processed all four 100-frame test movies.
- Generated `304,792` rows: `164,682` nodes, `140,110` edges, and 12 divisions.
  Independent validation confirmed exact columns, unique IDs, no missing values,
  valid endpoints, consecutive-frame edges, and lineage degrees of at most two
  outgoing and one incoming edge. No competition submission was created.
- Learned submission `54323397` scored `0.810`, below NMS-3.8's `0.834`; the
  exact aggregate validation gain did not transfer to the public leaderboard.
- Built `notebooks/biohub-prefix-hybrid-candidate.ipynb`, selecting classical
  `44b6` and learned `6bba` rows based on per-embryo exact validation. The hybrid
  exact score is `0.842616`; local top-to-bottom composition produced `260,287`
  structurally valid rows.
- Hybrid kernel version 1 failed because private notebook outputs mount under
  `/kaggle/input/notebooks/<owner>/<slug>/`, not the assumed direct slug path.
  Version 2 discovers both files by exact row-count fingerprints and completed.
- Kaggle version 2 produced the same `260,287`-row CSV as the local execution;
  both files have SHA-256 `abbbb913fa188f505e314a7c6c4a5846e6c6377c0788025d6ba799f0b9d968b0`.
- Copied LB893 source into
  `notebooks/biohub-lb893-safe-divisions-source.ipynb` and preserved its Kaggle
  metadata under `references/top_notebooks/lb893-safe-divisions/`.
- Copied LB893 run evidence into `references/lb893-v1-output/`: kernel log,
  `run_stats.csv`, and `ablation_plan.json`. The large `submission.csv` remains
  ignored.
- Created `notebooks/biohub-lb893-postprocessing-ablation.ipynb` as a lightweight
  local controller and `notebooks/biohub-lb893-validation-ablation.ipynb` as the
  Kaggle GPU exact-validation runner. All code cells parse locally.
- Uploaded `dalloliogm/biohub-lb893-validation-ablation`. Version 1 failed on a
  bad validation train path; the error log is preserved in
  `references/lb893-validation-v1-output/`. Version 2 fixes the path and is
  completed prediction/metric scoring but failed while writing the summary due a
  bad `CONFIG` reference. The v2 error log is preserved in
  `references/lb893-validation-v2-output/`; version 3 patches summary writing.
- Version 3 completed successfully. Exact validation artifacts are preserved in
  `references/lb893-validation-v3-output/`. Full LB893 validation score on the
  selected two train movies is `0.9548016411`; the next step is not submission,
  but one-factor validation ablations against this baseline.
- Created and ran
  `notebooks/biohub-lb893-no-safe-divisions-validation.ipynb`. Disabling only
  safe-division insertion improved exact validation to `0.9606407955`, removed
  division false positives (`0/4/0 -> 0/0/0`), and preserved evidence under
  `references/lb893-no-safe-divisions-v1-output/`.
- Created `notebooks/biohub-lb893-no-safe-divisions-candidate.ipynb` for the
  real test set. It forces `BIOHUB_VALIDATION_MODE=0`,
  `BIOHUB_TEST_DIR=/kaggle/input/competitions/biohub-cell-tracking-during-development/test`,
  and `BIOHUB_OUTPUT_SAFE_DIVISIONS=0`.
- Uploaded `dalloliogm/biohub-lb893-no-safe-divisions-candidate`; version 1
  completed on Kaggle T4. It produced `283,092` rows: `145,034` nodes and
  `138,058` edges, with zero division-like sources and zero safe divisions.
  Local structural checks passed: unique contiguous ids, no missing values, no
  duplicate node keys, all edge endpoints present, and no nonconsecutive edges.
  Evidence is preserved under
  `references/lb893-no-safe-divisions-candidate-v1-output/`. No automatic
  competition submission was made.
- Submitted no-safe-divisions candidate; public LB was `0.886`. This is below
  the copied LB893 public baseline `0.893`, so complete removal of safe divisions
  is rejected as a replacement.
- Created `notebooks/biohub-lb893-conservative-safe-divisions-candidate.ipynb`
  as the next original candidate. It keeps the LB893 graph pipeline intact and
  only tightens safe-division gates/caps.
- Uploaded `dalloliogm/biohub-lb893-conservative-safe-divisions-candidate`;
  version 1 completed on Kaggle T4. It produced `283,385` rows: `145,040` nodes
  and `138,345` edges, with `287` safe divisions. Local structural checks passed:
  unique contiguous ids, no missing values, no duplicate node keys, all edge
  endpoints present, no nonconsecutive edges, max indegree `1`, and max outdegree
  `2`. Evidence is preserved under
  `references/lb893-conservative-safe-divisions-candidate-v1-output/`. No
  automatic competition submission was made.
- Reviewed recent public notebooks from 2026-07-16 and saved the analysis in
  `references/recent-public-notebooks-2026-07-16.md`. Pulled public sources under
  `references/public-kernels-2026-07-16/` and our exact copied Exp073 source
  under `references/own-kernels-2026-07-16/biohub-exp073-gap-5-8-public/`.
  Downloaded our copied Exp073 output locally; its submission `54758569` is still
  pending on Kaggle.
- Reviewed recent public notebooks from 2026-07-17 and saved the ranked plan in
  `references/recent-public-notebooks-2026-07-17.md`. Pulled five representative
  sources under `references/public-notebooks-2026-07-17/`: weighted
  interpolation, outside-spacing/density gap, TTA/ILP-cost, bright/top-hat
  detector mix, and local-validation reliability.
- Created `notebooks/biohub-exp084-threshold-096875-candidate.ipynb` as the first
  original Exp073-family probe. The only intentional code-path delta is
  `BIOHUB_DET_THRESHOLD=0.96875`; all other Exp073 graph-calibration settings are
  unchanged.
- Created `notebooks/biohub-exp090-density-adaptive-gap-candidate.ipynb` as the
  second Exp073-family probe. It enables the local density-adaptive gap-radius
  branch from `romanrozen/biohub-best-score` but keeps adaptive short-track rescue
  disabled, so its first output isolates gap-radius behavior.
- Created `notebooks/biohub-exp096-stable-long-track-bridge-candidate.ipynb` as
  the third queued probe. It keeps the density-adaptive gap recipe and enables
  Yusuke's stable long-track bridge extension; run after Exp090, not before.
- Exp084 Kaggle v1 completed under
  `dalloliogm/biohub-exp084-threshold-0-96875-candidate`; saved output evidence
  to `references/exp084-threshold-096875-candidate-v1-output/`. Structural checks
  passed. Versus Exp073 it produced +457 rows, +234 nodes, +223 edges, and +1
  division-like source.
- Exp090 Kaggle v2 completed under
  `dalloliogm/biohub-exp090-density-adaptive-gap-candidate`; saved output
  evidence to `references/exp090-density-adaptive-gap-candidate-v2-output/`.
  Structural checks passed. Density-adaptive gap branch activated: 124 expanded
  candidates, 52 selected outside the base gate, 0 restricted candidates, and
  short-track rescue remained off.
- Exp096 Kaggle v2 completed under
  `dalloliogm/biohub-exp096-stable-long-track-bridge-candidate`; saved output
  evidence to `references/exp096-stable-long-track-bridge-candidate-v2-output/`.
  Structural checks passed, but output is byte-identical to Exp090. Bridge branch
  checked 87 candidates, 61 passed context, 0 passed motion, and 0 were selected.
  Do not submit Exp096 unless the bridge gates are changed.
- Submitted Exp090 density-adaptive gap as competition submission `54768948`;
  status pending at submit time.
- Submitted Exp084 threshold as competition submission `54768957`; status pending
  at submit time.
- Exp091, Exp092, Exp084, and Exp090 all completed with public LB `0.903`,
  tying Exp073 but not improving it. Exp096 was byte-identical to Exp090 and was
  not submitted.
- Created and submitted Exp100 division-risk prune. It leaves all nodes unchanged,
  removes 21 high-risk division daughter edges, and reduces division-like sources
  from `418` to `397`. Submission `54776292` was rejected by Kaggle as invalid
  submission format despite passing local checks. Evidence:
  `references/exp100-division-risk-prune-v1-output/`.
- Created, ran, validated, and submitted Exp101 upstream safe-division recall
  expansion as competition submission `54780672`. Compared with Exp073, it
  changes rows `251,900 -> 252,174`, nodes `128,217 -> 128,316`, edges
  `123,683 -> 123,858`, and division-like sources `418 -> 531`. Evidence:
  `references/exp101-safe-division-recall-expansion-v1-output/`.
- Created, ran, validated, and submitted Exp102 mild upstream safe-division
  expansion as competition submission `54781687`. Compared with Exp073, it
  changes rows `251,900 -> 252,001`, nodes `128,217 -> 128,262`, edges
  `123,683 -> 123,739`, and division-like sources `418 -> 442`. Evidence:
  `references/exp102-mild-safe-division-expansion-v1-output/`.
- Created, ran, validated, and submitted Exp103 threshold+density gap plus mild
  safe-divisions as competition submission `54784028`. Compared with Exp073, it
  changes rows `251,900 -> 252,784`, nodes `128,217 -> 128,656`, edges
  `123,683 -> 124,128`, and division-like sources `418 -> 442`. Evidence:
  `references/exp103-threshold-density-mild-division-v1-output/`.
- Created, ran, validated, and submitted Exp104 safe-division precision
  tightening as competition submission `54785550`. Compared with Exp073, it
  changes rows `251,900 -> 251,832`, nodes `128,217 -> 128,216`, edges
  `123,683 -> 123,616`, and division-like sources `418 -> 351`. Evidence:
  `references/exp104-safe-division-precision-v1-output/`.
- Public LB returned for the 2026-07-17 division batch: Exp101 `0.902`, Exp102
  `0.903`, Exp103 `0.902`, Exp104 `0.903`. Broadening or tightening safe
  divisions did not improve beyond Exp073, so the next active axis is gap-node
  geometry.
- Created and uploaded Exp105 weighted gap-node interpolation candidate as
  `dalloliogm/biohub-exp105-weighted-gap-interpolation`. Local notebook JSON and
  Python syntax checks passed. Kaggle v1 completed with rows `252,688`, nodes
  `128,614`, edges `124,074`; weighted motion used for `2019/2020` synthetic
  gap nodes. Submitted as `54800958`. Evidence:
  `references/exp105-weighted-gap-interpolation-v1-output/`.
- Created and uploaded Exp106 density spacing gate candidate as
  `dalloliogm/biohub-exp106-density-spacing-gate`. Local notebook JSON and
  Python syntax checks passed; Kaggle v1 is running.
- Created and uploaded Exp107 density gain `0.0475` candidate as
  `dalloliogm/biohub-exp107-density-gain-0475`. Local notebook JSON and Python
  syntax checks passed; Kaggle v1 is running.
- Exp106 and Exp107 both completed on Kaggle and were downloaded locally under
  `kaggle_outputs/`. Structural checks passed for both using dataset-local
  `node_id` keys. Exp106 output SHA-256:
  `f4689e43df5b769dc45117b96e09c91753b73326a9ad2157c232df6bb63d3565`; Exp107
  output SHA-256:
  `c8429be1242e8bfb342e46e66620d491b87674ab73aa45e6a59a5c345a528029`.
  Evidence preserved in
  `references/exp106-density-spacing-gate-v1-output/` and
  `references/exp107-density-gain-0475-v1-output/`.
- Tried to submit Exp106 and Exp107 after validation on 2026-07-18. Both uploads
  reached Kaggle, but `CreateSubmission` returned HTTP 400 and neither attempt
  created a new submission record. Current live submission list still has only
  Exp105 (`54800958`) pending for 2026-07-18.
- The user manually submitted the two validated CSVs on 2026-07-18. Kaggle
  submission records were created: Exp106 is assumed to be `54802933` and Exp107
  is assumed to be `54802935`, based on the order and timestamps of the manual
  uploads. Both completed with public LB `0.903`.
- Exp105 (`54800958`), Exp106 (`54802933`), and Exp107 (`54802935`) all completed
  with public LB `0.903`. These tied Exp073 and did not improve the leaderboard.
  The next branch should move away from small density/gap-radius tweaks and
  toward the frozen-frame-aware candidate or the validation-harness train-mode
  work.
- Created `scripts/biohub_validation_harness.py` and
  `references/validation-harness-plan.md`. The harness was smoke-tested on
  downloaded Exp106 and Exp107 outputs with `--skip-metric`; both produced valid
  reports with no structural errors. Exact metric mode remains environment-gated
  until train GEFF and `biohub_tracking`/`traccuracy` dependencies are attached.
- Created, ran, validated, and submitted Exp091 density gap + adaptive
  short-track rescue as competition submission `54769343`. Short-track rescue
  activated and recovered 177 nodes across 40 components.
- Created, ran, validated, and submitted Exp092 threshold `0.96875` + density
  gap as competition submission `54769344`.
- Created Exp111 original-branch exploration notebook:
  `notebooks/biohub-exp111-original-branch-exploration.ipynb`. This freezes the
  Exp092/0.903-family graph recipe and adds diagnostics rather than a new scoring
  tweak. Static notebook JSON and Python syntax checks passed. Next action:
  upload/run on Kaggle T4, download `run_stats.csv` and
  `exp111_original_branch_diagnostics.csv`, then decide the next targeted branch
  from measured relaxed-link, long-edge, gap, division, and short-track patterns.
- Exp111 completed and its downloaded output is under
  `kaggle_outputs/biohub-exp111-original-branch-exploration/`. Created
  `scripts/generate_exp111_suspicious_events_report.py` and the first static
  review artifact at `reports/exp111_suspicious_events.html`. The report contains
  100 events: 40 safe-division boundary cases, 30 synthetic gap insertions
  prioritized to `44b6_0b24845f`, 20 explicitly marked relaxed-motion proxies,
  and the 10 longest final edges. It includes all eight requested manual labels,
  but labels are not persisted. Raw test image Zarr volumes are not local, so the
  current report contains graph-derived tables and clear crop placeholders.
  Next action: review this queue, attach/download the competition `test/*.zarr`
  volumes and regenerate with `--image-root` if crops are useful, then choose one
  targeted Exp112 rule from the reviewed labels. Do not build a full UI yet.
- Created the public-facing, submission-agnostic review notebook
  `notebooks/biohub-suspicious-tracking-event-review.ipynb` plus its sidecar
  Kaggle kernel metadata. It discovers or accepts one or more `submission.csv`
  files, ranks division-like sources, long edges, midpoint-like gap nodes,
  fragmented movies, and low edge-to-node-ratio movies, and shows four-frame XY
  projections when competition OME-Zarr data is attached. The graph-only path
  ran top-to-bottom locally on two example submissions; notebook JSON, every
  Python cell, metadata JSON, and the image-unavailable placeholder were
  validated. This artifact is a notebook/kernel only and was not submitted to
  the competition. Published Kaggle kernel version 1, then attached the public
  `romanrozen/biohub-best-score` output as the generic example submission for
  version 2 so the public notebook can run immediately without private inputs.
  The subsequent presentation revision hides every code cell by default and
  enlarges the four-frame event viewer into a 2x2 grid for easier inspection.

## Questions

- What are the notebook runtime and accelerator limits?
- Which LB893 post-processing components are actually positive under exact
  embryo-disjoint validation?
- What are the exact aggregate and per-embryo validation metrics from version 7?
  The kernel completed, but `ListKernelSessionOutput` still returns HTTP 429.
- Exp111 decision question: after diagnostics run, which single failure regime
  is largest enough to justify exp112: relaxed motion links, long gap edges,
  dataset-specific density, or safe-division burden?
- Exp111 review question: which event class has the highest manual false-event
  rate, and does that support a narrow upstream rule that can be validated before
  another submission?
