# Tasks

## Current Goal

- Reach medal range by testing a genuinely different learned/global-tracking
  pipeline against the exact embryo-disjoint validation benchmark.

## Next Experiments

- Build a locked learned full-test candidate using det threshold `0.99`, division
  weight `1.0`, split `0`, and a T4 GPU.
- Validate all four test graphs and submission rows. Do not submit automatically.
- After the default learned LB is known, test thresholds above `0.99` to reduce
  the `6bba` node overprediction without sacrificing its edge-recall gain.
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

## Questions

- What are the notebook runtime and accelerator limits?
- Which public baseline is the best reproducible starting point?
- What are the exact aggregate and per-embryo validation metrics from version 7?
  The kernel completed, but `ListKernelSessionOutput` still returns HTTP 429.
- What public LB does the default learned U-Net/transformer/ILP pipeline achieve?
