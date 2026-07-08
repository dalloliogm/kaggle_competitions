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

## 2026-07-03: Second submission and strategy pivot

- Submission `54307212` scored `0.834`, improving the first submission by `0.007`.
- Current rank: `203/630`. Approximate top-10% score: `0.856`; gap `0.022`.
- Nearby rule-based tuning is unlikely to close that gap alone. Next gate is the
  genuinely learned/global pipeline in `cellmot-baseline-artifacts`: temporal 3D
  U-Net detections, learned edge transformer, and ILP optimization.
- Start with exact validation only. Do not inherit the public notebook's proxy
  objective or launch a costly parameter sweep before reproducing the default.

## 2026-07-04: Learned pipeline exact validation

- Version 1 failed on a Tesla P100 because PyTorch 2.10 supports `sm_70+`, not
  P100 `sm_60`. Pinning `machine_shape=NvidiaTeslaT4` fixed execution.
- Default learned parameters: detection threshold `0.99`, ILP edge weight `-1.0`,
  appearance/disappearance `0.1`, division weight `1.0`, split `0`.
- Exact aggregate: `0.8394088969`, delta `+0.0289511808` versus classical
  `0.8104577161`; edge TP/FP/FN `815/58/80`.
- `44b6`: `0.883791`, edges `46/2/4`, 25,995 nodes, 3 predicted divisions.
- `6bba`: `0.836847`, edges `769/56/76`, 7,603 nodes, 1 predicted division,
  node recall `0.9849`, node overprediction `19.5%`.
- Training labels selected contain no scored divisions, so division Jaccard is
  undefined; leaderboard behavior remains necessary evidence.
- Evidence: `references/learned-v1-output/` and `references/learned-v2-output/`.

## 2026-07-04: Learned full-test candidate complete

- Kernel: `dalloliogm/biohub-learned-unet-ilp-candidate`, version 1, Tesla T4.
- Prediction completed in `398.04` seconds; full kernel runtime was about 472
  seconds including isolated dependency setup and notebook export.
- All four 100-frame test movies were processed. Submission totals: `304,792`
  rows, `164,682` nodes, `140,110` edges, and 12 divisions.
- Per-movie nodes/edges/divisions: `25,995/23,538/3`, `55,324/44,335/2`,
  `7,603/6,899/1`, and `75,760/65,338/6`.
- Independent local validation passed exact schema, unique IDs, no missing
  values, node endpoint membership, consecutive-frame edges, and degree limits.
- Ready for manual submission. No automatic competition submission was made.
- Evidence: `references/learned-candidate-v1-output/`.

## 2026-07-04: Learned LB failure and prefix-aware hybrid

- Learned submission `54323397` scored `0.810`, down `0.024` from NMS-3.8.
- The held-out split explains a safer composition: classical wins `44b6`
  (`0.942567` vs `0.883791`), while learned wins `6bba` (`0.836847` vs
  `0.802713`). Their weighted exact hybrid score is `0.842616`.
- A lightweight merge of the two completed test outputs produced `260,287`
  rows, `137,648` nodes, `122,639` edges, and seven divisions. All schema and
  graph checks passed locally.
- Next gate: execute the merge on Kaggle, inspect artifacts, then submit manually.
- Kaggle version 1 failed on fixed attachment paths. Version 2 discovered both
  private outputs under `/kaggle/input/notebooks/` and completed successfully.
- Kaggle and local `submission.csv` outputs have identical SHA-256
  `abbbb913fa188f505e314a7c6c4a5846e6c6377c0788025d6ba799f0b9d968b0`.
- Version 2 is ready for manual submission. Evidence: `references/hybrid-v2-output/`.

## 2026-07-07: LB893 source import and ablation setup

- Copied public notebook
  `dalloliogm/lb893-learned-graph-tracker-micro-safe-divisi` into
  `notebooks/biohub-lb893-safe-divisions-source.ipynb`.
- Confirmed Kaggle submission `54397298` scored `0.893`, superseding the
  classical, learned-only, and prefix-aware hybrid branches.
- Preserved output evidence in `references/lb893-v1-output/`. The tracked
  `run_stats.csv` reports `262,359` rows: `134,238` nodes, `128,121` edges, and
  `381` division-like sources.
- LB893 is a learned model plus heavy graph repair, not just a U-Net/ILP rerun:
  motion relink replaced `118,984` raw edges with `122,937` relinked edges,
  one-frame gap close added `2,100` nodes, gap-2 recovery added `402` nodes, and
  safe-division insertion added `381` edges.
- Created `notebooks/biohub-lb893-validation-ablation.ipynb`. It defaults to
  `BIOHUB_VALIDATION_MODE=1`, selects one labeled training movie per embryo, and
  writes `validation_metrics.csv` and `validation_summary.json` after running the
  LB893 post-processor.
- Created `notebooks/biohub-lb893-postprocessing-ablation.ipynb` and
  `references/lb893-v1-output/ablation_plan.json` to define one-factor ablations:
  `no_motion_relink`, `no_safe_divisions`, `no_gap_close`, `no_gap2`, and
  `no_linefit`.
- Local syntax checks pass. Local top-to-bottom execution of the controller was
  blocked only because no `python3` Jupyter kernelspec is installed; the runner
  itself requires Kaggle T4, competition data, and the 50-epoch support pack.
- Kaggle validation runner version 1 failed before prediction because the train
  path missed the `/competitions/` mount segment. Version 2 fixed the path and
  completed prediction/post-processing for `44b6_0113de3b` and `6bba_05b6850b`,
  but failed while writing `validation_summary.json` due a bad `CONFIG`
  reference. The useful exact metric lines were printed before that failure:
  `44b6` adjusted edge score `0.941693`, edge `49/2/1`, divisions `0/0/0`;
  `6bba` adjusted edge score `0.955590`, edge `831/20/14`, divisions `0/4/0`.
  Weighted adjusted edge score is approximately `0.954802`; division Jaccard is
  `0.0` on this selected split. Version 3 patches summary writing.
- Version 3 completed and wrote formal validation artifacts. Summary:
  `score=0.9548016411`, `adj_edge_jaccard=0.9548016411`,
  `edge_jaccard=0.9596510360`, `node_recall=0.9982578397`,
  `division_jaccard=0.0` (`division_tp/fp/fn = 0/4/0`). Evidence:
  `references/lb893-validation-v3-output/`.

## 2026-07-08: LB893 no-safe-divisions ablation

- Ablation definition: keep LB893 learned U-Net/transformer/ILP, motion relink,
  one-frame gap close, gap-2 recovery, pruning, and linefit smoothing unchanged;
  disable only `BIOHUB_OUTPUT_SAFE_DIVISIONS`.
- Exact validation improved from full LB893 `0.9548016411` to `0.9606407955`
  (`+0.0058391544`) on the selected two labeled train movies.
- Edge Jaccard slightly improved from `0.9596510360` to `0.9606557377`; node
  recall improved from `0.9982578397` to `0.9994192799`.
- The main change is division risk: full LB893 had division counts `0/4/0`,
  while no-safe-divisions had `0/0/0`. The split contains no true scored
  divisions, so this does not prove divisions are globally harmful; it proves the
  current safe-division heuristic is not safe on this validation slice.
- Per-sample summary: `44b6_0113de3b` adjusted edge `0.943299`, edge `49/2/1`,
  divisions `0/0/0`; `6bba_05b6850b` adjusted edge `0.961686`, edge `830/18/15`,
  divisions `0/0/0`.
- Created `notebooks/biohub-lb893-no-safe-divisions-candidate.ipynb` for the
  real test set. It explicitly forces test mode and the competition test path.
  No automatic competition submission has been made.
- Evidence: `references/lb893-no-safe-divisions-v1-output/`.

## 2026-07-08: LB893 no-safe-divisions full-test candidate

- Kernel: `dalloliogm/biohub-lb893-no-safe-divisions-candidate`, version 1,
  Tesla T4, no internet, with `pilkwang/biohub-tracking-support-pack-50ep-v1`.
- Completed successfully and wrote `submission.csv` with SHA-256
  `8bb5c53b2a76053452dddc565c6863628d8882d36438763d3cd0ddd298c7b827`.
- Output rows: `283,092` total = `145,034` nodes + `138,058` edges. There are no
  division-like sources because `BIOHUB_OUTPUT_SAFE_DIVISIONS=0`.
- Per-dataset rows: `44b6_0113de3b=50,070`, `44b6_0b24845f=79,527`,
  `6bba_05b6850b=12,412`, `6bba_05db0fb1=141,083`.
- Structural checks passed locally: unique contiguous `id`, no missing values,
  no duplicate node keys, all edge endpoints present, all edges consecutive in
  time, max indegree `1`, max outdegree `1`.
- The output is larger than the copied LB893 public notebook output
  (`262,359` rows), mainly because the current rerun produced more raw detections
  and relinked edges for `44b6_0b24845f`. Treat public LB as the deciding
  evidence.
- Ready for manual competition submission. No automatic submission was made.
- Manual submission scored public LB `0.886`, below copied LB893 `0.893`. This
  rejects complete safe-division removal as the next baseline, but it remains a
  useful negative control: public test appears to reward some safe divisions even
  though the selected validation split penalized them.
- Evidence: `references/lb893-no-safe-divisions-candidate-v1-output/`.

## 2026-07-08: Conservative safe-divisions candidate

- Goal: create an original single-pipeline submission, not a per-dataset blend.
- Rationale: full LB893 safe divisions scored `0.893`; no-safe-divisions scored
  `0.886`. Public LB rewards some division recovery, but validation showed the
  default heuristic can add false positives. The next candidate keeps divisions
  but tightens their gates.
- Notebook: `notebooks/biohub-lb893-conservative-safe-divisions-candidate.ipynb`.
- Only intentional changes versus full LB893: `SAFE_DIV_MAX_UM 4.7 -> 4.25`,
  `SAFE_DIV_SISTER_MAX_UM 6.85 -> 6.2`, `SAFE_DIV_EXISTING_CHILD_MAX_UM
  7.45 -> 6.8`, `SAFE_DIV_FRAME_FRAC_CAP 0.0072 -> 0.0055`, and
  `SAFE_DIV_GLOBAL_FRAC_CAP 0.00375 -> 0.0028`.
- Expected behavior: safe-division count between full LB893 (`381`) and no-safe
  (`0`), with fewer borderline division edges.

## Feature Ideas

- TBD

## Model Ideas

- TBD

## Useful References

- TBD
