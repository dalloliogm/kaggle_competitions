# Notes

## 2026-07-02: First baseline prepared

- Notebook: `notebooks/biohub-exact-dog-hungarian-baseline.ipynb`
- Validation: official `tracking_cellmot.metrics`, sampled one video per embryo,
  with `validation_metrics.csv` and `validation_summary.json` outputs.
- Baseline: multi-scale DoG `(1.5, 4.0)` and `(2.2, 5.5)`, relative threshold
  `0.045`, physical NMS `3.2 um`, Hungarian gate `8.0 um`, interpolated one-frame
  gaps at `6.0 um`, isolated-node pruning, divisions disabled.
- Local checks passed. Private Kaggle kernel version 4 finished with error at
  `dalloliogm/biohub-exact-validation-and-dog-hungarian-baseline`.
- Version 1 failed because installing artifact wheels into the live kernel
  replaced NumPy/SciPy in-process. Version 3 isolated the evaluator with `venv`,
  but Kaggle disables `ensurepip`. Version 4 installs the official evaluator into
  an isolated `pip --target` directory and invokes it in a fresh subprocess via
  `PYTHONPATH`, leaving the baseline kernel's numerical stack untouched.
- Version 4 successfully produced `toy_0000_metrics.json` with edge TP/FP/FN
  `2/0/0`, node recall `1.0`, and adjusted edge Jaccard `1.0`. It failed before
  writing any real validation metrics. The latest log could not yet be retrieved
  because Kaggle returned HTTP 429 from `ListKernelSessionOutput`.
- On 2026-07-03 the user attached `cellmot-baseline-artifacts` in Kaggle and saved
  another run. Remote metadata confirmed the competition, artifact dataset,
  `thibautgoldsborough/unet-baseline-inference-submission`, and
  `amanatar/biohub-cell-tracking-v5-unet-ilp-reproduction`. The source code was
  identical to the local notebook. This run also ended with `ERROR`, with no
  failure message available through the status API.
- Version 7 fixes the reported `zarr is not installed` failure without adding a
  second environment notebook. The attached artifact already includes an offline
  Zarr wheel; GEFF reading now occurs entirely inside the isolated metric
  subprocess. The main detector/tracker uses raw Blosc2 image chunks and passes
  GEFF paths to that subprocess.

## 2026-07-03: First scored submission

- Kernel version 7 completed successfully.
- Kaggle submission `54297736` scored `0.827` public LB.
- This is close to the strongest public rule-based claims (`0.835-0.839`), so the
  first improvement should preserve the detector and normal linker and test only
  conservative velocity-aware two-missing-frame recovery.
- Exact validation artifacts remain unavailable through the CLI because Kaggle's
  output-list endpoint returns HTTP 429; do not infer their values from the LB.

## EDA Observations

- TBD

## 2026-07-03: Gap-2 ablation prepared

- Candidate source: the auditable delta in the reviewed LB-0.839 public notebook,
  not its misleading U-Net/ILP title.
- Frozen baseline and candidate share identical detections. Candidate-only config
  delta is `recover_gap2=True`.
- Recovery considers only `t -> t+3` tracklet ends/starts, requires displacement
  and local-velocity compatibility, and caps additions at `0.45%` of existing
  edges or `180` links per movie.
- Two interpolated nodes create three consecutive edges, matching the metric's
  temporal structure. A direct non-consecutive edge is never emitted.

## Feature Ideas

- TBD

## Model Ideas

- TBD

## Useful References

- TBD
