# Tasks

## Current Goal

- Improve the `0.827` public baseline using controlled exact-metric ablations.

## Next Experiments

- Add a tightly capped velocity-aware `t -> t+3` recovery pass that inserts two
  consecutive interpolated nodes, without changing detection or normal linking.
- Compare frozen baseline and gap-2 variant on the same embryo-disjoint
  validation videos using the exact evaluator.
- Retrieve `validation_summary.json` when Kaggle's output endpoint stops
  returning HTTP 429.
- Only submit the gap-2 variant if exact validation is non-inferior across
  embryos; otherwise move to the detector-density/NMS sweep.

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

## Questions

- What are the notebook runtime and accelerator limits?
- Which public baseline is the best reproducible starting point?
- What are the exact aggregate and per-embryo validation metrics from version 7?
  The kernel completed, but `ListKernelSessionOutput` still returns HTTP 429.
- Does conservative gap-2 recovery improve exact validation consistently enough
  to justify a second leaderboard submission?
