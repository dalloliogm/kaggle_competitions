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

## 2026-07-03: Gap-2 ablation result

- Exact aggregate baseline: `0.7943044375`; gap-2: `0.7935401013`; delta
  `-0.0007643362`.
- Aggregate edge TP/FP/FN stayed exactly `761/63/134`.
- `44b6`: 38 bridges added 84 nodes; score `0.941009 -> 0.940702`.
- `6bba`: 26 bridges added 64 nodes; score `0.785884 -> 0.785094`.
- The recovery pass found plausible geometric continuity but no additional
  annotated edges. The node-count adjustment converted every addition into a
  small penalty. Candidate rejected; no competition submission.
- Evidence: `references/gap2-v1-output/`.

## 2026-07-03: Detector screen result

- Best: physical NMS `3.8 um`, exact aggregate `0.8104577161` versus baseline
  `0.7943044375`; delta `+0.0161532785`.
- `44b6`: `0.941009 -> 0.942567`; edge counts unchanged `49/2/1`, nodes
  `26,110 -> 25,684`.
- `6bba`: `0.785884 -> 0.802713`; edges `712/61/133 -> 708/42/137`, nodes
  `6,361 -> 6,002`. Fewer false links dominated the modest TP/recall loss.
- Threshold `0.030` and NMS `2.8 um` increased density and reduced score. Threshold
  `0.060` helped slightly but was materially weaker than NMS `3.8 um`.
- Evidence: `references/detector-screen-v1-output/`.

## 2026-07-03: NMS-3.8 candidate complete

- Kernel: `dalloliogm/biohub-nms-3-8-submission-candidate`, version 1 complete.
- Candidate-only change confirmed: `min_distance_um=3.8`.
- Exact validation reproduced `0.8104577161` with edge TP/FP/FN `757/44/138`.
- Test graph rows: `25,684/24,710`, `28,601/25,692`, `6,002/5,646`, and
  `61,355/58,233` nodes/edges across the four movies.
- Final `submission.csv`: `235,923` rows; node uniqueness and all edge endpoint
  checks passed. Ready for manual submission; no automatic upload performed.
- Evidence: `references/nms38-v1-output/`.

## Feature Ideas

- TBD

## Model Ideas

- TBD

## Useful References

- TBD
