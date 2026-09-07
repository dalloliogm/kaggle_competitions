# September 6: five proposed exploratory submissions

Status: COMPLETE. All five scored; public best .939. See sep06-live-submissions.json and TASKS.md. User approved this plan with "do it" on September 6.
Live preflight found no September 6 submissions. Execution is date-bound to September 6;
see `sep06-batch-execution.json` for live progress and exact artifact hashes.
This is an explicitly approved exploratory exception, not an independent holdout promotion.

## Frozen reference

Incumbent: dalloliogm/rishabh-division-geometry-080 v1, public 0.938,
SHA256 650be35eeebb3489001a3ff32f1fbde0a8c0bd2f02bacb18046c23fece534587.
Keep .80 fusion, gap 5.8um, parent/sister caps 9/14um, image threshold .12,
minimum daughter divergence 4.5um, symmetry tolerance .6, retention .90,
except for the explicit changes below. Do not change the reference to yesterday's
5.0um gap variant merely because it tied at three-decimal precision.

## Proposed batch

| Order | Candidate | Exact change | Hypothesis / interpretation |
| --- | --- | --- | --- |
| 1 | Softer division image veto | DeepCenter safe-division threshold .12 -> .08 | Yesterday's stricter veto hurt; test whether modestly more image-supported proposals help. This is a hypothesis, not an extrapolated gain. |
| 2 | Stronger daughter separation | SAFE_DIV_DIVERGE_UM 4.5 -> 5.0 | Retain forks with stronger forward separation; earlier weaker-divergence experiments regressed on older baselines. |
| 3 | Image/geometry interaction | Combine only changes 1 and 2 | Test whether stronger motion evidence offsets a softer image veto. Together with the incumbent and arms 1/2 this is a complete 2x2 factorial. |
| 4 | Stronger sister symmetry | SAFE_DIV_SISTER_SYMMETRY_TAU .60 -> .45 | Permit less asymmetry between parent-daughter distances, testing division identity rather than an arbitrary division quota. Smaller tau is stricter in the inspected implementation. |
| 5 | More conservative detector fallback | DUAL_SEED_MIN_CANDIDATE_RETENTION .90 -> .95 | Fall back to primary detections on more frames where blending reduces candidate count. .80 remains the nominal blend weight on other frames. This changes the effective mixture and may hurt; it is the orthogonal detector probe. |

All five hypotheses and settings are fixed before scoring. No predicted score
ranges are claimed. These are small production-pipeline changes suitable for
same-day runs, not new model training or synthetic integration.

## Evidence and bounds

- September 5 image-threshold .18/.25 variants scored .936/.935; gap-only tied
  .938. Do not spend slots on another gap-distance or tighter image-threshold sweep.
- Incumbent run_stats.csv: 169 division geometric proposals, 37 image-veto
  rejections, 74 symmetry rejections, 58 surviving proposals, 47 added divisions.
  Counts measure activation, not correctness or independent events across gates.
- Divergence rejection counter is 4,588, but includes missing/ambiguous successors
  and timing failures as well as inadequate distance increase. It does NOT mean
  4,588 proposals are affected by moving the numeric margin. Split these reasons
  or compare boundary-eligible proposals during the output audit.
- Older 1.50um divergence reproduction scored .919 vs its .926 control. This
  discourages broad relaxation, but does not prove that 5.0 improves today's base.
- Retention .95 has been prepared on an older .926 branch. It is not a novel
  mechanism; inspect prior output/score records during preparation and label this
  as a current-base interaction test. No current-base .95 result was located in
  the reviewed records/latest 50 live submissions.
- Official score includes edge quality and division quality; counts alone are
  insufficient. Source: https://github.com/royerlab/kaggle-cell-tracking-competition/blob/main/metrics.md
- Existing four validation movies are secondary-checkpoint-exposed. Local
  diagnostic results must not be described as independent holdout evidence.

## Execution plan

1. Confirm approval to execute this date's five-probe exploratory batch, including
   private notebook uploads/GPU runs and submission of distinct audited outputs.
   Keep routine promotion rules unchanged; document any user-directed exploratory
   exception explicitly without claiming that holdout requirements passed.
2. Prepare all five from the frozen .80 source. Update every environment setting,
   internal guard, runtime manifest and (for retention) both assignments together.
   Verify only intended production code changes; avoid inactive configuration edits.
3. Run two private kernels at a time, in order 1/2, then 3/4, then 5. Use available
   time for the fixed GEFF-loader diagnostic; do not displace the five requested
   production runs with extra GPU work. Submit completed candidates without waiting
   for public scores, as those can take hours.
4. For each: resolve actual version from returned/live metadata, download that
   version's output, run both structural validators, inspect per-movie node/edge/
   division changes and activation counters, compare SHA against all submitted
   outputs, reconcile live quota immediately before submission. Stop on uncertainty.
5. A duplicate or inactive arm does not earn a slot. If arm 3 duplicates a single
   factor, evaluate a predeclared reserve with retention .85 (all other incumbent
   settings fixed); do not submit it unless distinct and audited. Other failures
   require diagnosing the cause rather than silently filling slots with repeats.
6. Preserve incumbent unless a result improves it. Compare the 2x2 score interaction
   at reported precision; judge large graph changes and private-transfer claims
   separately. Record all five refs, hashes, counts and eventual scores.

The prior batch took roughly an hour from first to last production candidate
completion; that is historical timing, not a runtime guarantee. Launch with ample
margin before 00:00 UTC. Never let a September 6 runner spend September 7 slots.
