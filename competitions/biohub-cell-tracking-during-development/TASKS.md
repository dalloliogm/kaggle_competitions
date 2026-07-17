# Tasks

## Current Goal

- Improve beyond Exp073 public LB `0.903`. Exp073 is now the working baseline;
  copied LB893 `0.893`, no-safe `0.886`, and conservative-safe `0.889` are
  superseded.
- Submission `54758569`, copied
  `dalloliogm/biohub-exp073-gap-5-8-public`, completed with public LB `0.903`.
  It is byte-identical to public `lucashmateo/biohub-ct-exp073`.

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
  `0.0033`) instead of post-hoc edge deletion. Kaggle v1 is running as
  `dalloliogm/biohub-exp104-safe-division-precision`; submit if structural
  checks pass.
- Public-notebook follow-up plan from the 2026-07-17 scan:
  1. Exp105 weighted gap-node interpolation, using local motion to place
     inserted gap nodes instead of pure midpoint placement.
  2. Exp106 outside-base spacing gate for density-adaptive gap candidates,
     initially `8.50 um`, if density-gap branches look promising.
  3. Exp107 TTA plus ILP-cost branch, higher runtime and broader changes.
  4. Larger detector-preprocessing branch from bright/top-hat U-Net mix only
     after inspecting its weight artifact and output density.
  Detailed notes: `references/recent-public-notebooks-2026-07-17.md`.
- Operating rule for the rest of this challenge: Kaggle submissions may take
  several hours to validate, and user time is limited. If daily submission slots
  remain, run/validate/submit multiple independent candidates without waiting for
  the previous pending submission to score. Later, compare all completed public
  LB results together.
- Do not spend more slots on LB893 safe-division-only tuning unless Exp073-family
  probes regress sharply.
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
- Created and uploaded Exp104 safe-division precision tightening as
  `dalloliogm/biohub-exp104-safe-division-precision`; Kaggle v1 is running.
- Created, ran, validated, and submitted Exp091 density gap + adaptive
  short-track rescue as competition submission `54769343`. Short-track rescue
  activated and recovered 177 nodes across 40 components.
- Created, ran, validated, and submitted Exp092 threshold `0.96875` + density
  gap as competition submission `54769344`.

## Questions

- What are the notebook runtime and accelerator limits?
- Which LB893 post-processing components are actually positive under exact
  embryo-disjoint validation?
- What are the exact aggregate and per-embryo validation metrics from version 7?
  The kernel completed, but `ListKernelSessionOutput` still returns HTTP 429.
