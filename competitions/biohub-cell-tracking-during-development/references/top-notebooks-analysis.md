# Top Public Notebook Analysis

Snapshot: 2026-07-02. Notebooks were queried with the Kaggle CLI using the
competition filter and `voteCount`/`hotness` sorting. Representative originals
were downloaded and inspected at source level.

## Important limitation

The pulled notebooks contain source but no execution outputs. Leaderboard scores
below are author claims from titles or markdown, not independently verified
submission scores. Popularity is also not evidence of performance: starter and
EDA notebooks receive many votes, while newer competitive variants may receive
few.

## Ranking and source assessment

| Votes | Notebook | Executed method | Assessment |
| ---: | --- | --- | --- |
| 142 | [Nearest Neighbor starter](https://www.kaggle.com/code/inversion/cell-tracking-getting-started-w-nearest-neighbor) | Downsample all axes by 4, uniform filtering, 90th-percentile connected components, Hungarian linking at 15 um | Clear format tutorial, but deliberately weak: coarse Z sampling, loose links, no gap handling, divisions, or pruning. |
| 116 | [Data Model, EDA, Baseline](https://www.kaggle.com/code/pilkwang/biohub-cell-tracking-data-model-eda-baseline) | Multi-scale DoG, centroid refinement, physical NMS, 8 um Hungarian links, one-frame gap interpolation, isolated-node pruning | Best auditable rule-based starting implementation. It defines a U-Net function, but the submitted configuration uses the DoG detector and Hungarian linker. |
| 80 | [Artifact-Safe UNet + ILP Baseline](https://www.kaggle.com/code/yusuketogashi/lb839-artifact-safe-unet-ilp-baseline) | Multi-scale DoG + Hungarian + interpolated one-frame gaps, then a tightly capped velocity-aware two-missing-frame recovery | Despite the title, the executed path contains no U-Net or ILP. Its meaningful delta from the rule-based base is conservative `t -> t+3` recovery with two interpolated nodes. The author claims LB 0.839. |
| 77 | [DoG Band-Pass](https://www.kaggle.com/code/romanrozen/strong-start-dog-band-pass-lb-0-73) | Multi-scale DoG, physical NMS, two-pass motion-aware Hungarian, isolated-node pruning, per-movie count calibration | Strong standalone classical design. The main novel idea is estimating a test movie's node budget from image-derived density calibrated on train. Author claims LB 0.73+. |
| 73 | [V4 UNet ILP Reproduction](https://www.kaggle.com/code/yaroslavkholmirzayev/biohub-cell-tracking-v4-unet-ilp-reproduction) | Full-resolution multi-scale DoG, Hungarian links, direct gap edges, capped geometric division recovery | The title is misleading: no U-Net or ILP is executed. Direct `t -> t+2` gap edges do not reproduce consecutive GT edges, and isotropic peak suppression in voxel units over-suppresses Z. Treat as an idea source for division gates, not a trusted baseline. |
| 56 | [Classical Baseline](https://www.kaggle.com/code/xiaoleilian/biohub-cell-tracking-classical-baseline) | XY pooling by 4, robust single-scale peaks, centroid refinement, physical NMS, two-pass half-velocity Hungarian at 7/11 um, pruning | Useful compact ablation baseline. Its markdown reports about LB 0.720 and warns that much denser DoG detection reduced its score. |
| 35 | [Rule-Based Baseline](https://www.kaggle.com/code/seshurajup/lb-0-835-biohub-rule-based-baseline) | Not auditable from the pulled source | Author claims LB 0.835, but Kaggle returned a notebook with one empty code cell. Several later notebooks state that they derive from it. Do not rely on it until reproducible source is available. |
| 16 | [Actually Tuning the ILP](https://www.kaggle.com/code/aman5153684/actually-tuning-the-ilp) | External pretrained 3D U-Net + node transformer + ILP tracker from `cellmot-baseline-artifacts`; sweeps detection threshold and ILP division weight | This is the reviewed notebook that actually invokes the learned/ILP pipeline. It is strategically important, but its custom validation objective does not match the official metric closely enough to trust its selected parameters without re-evaluation. |
| 10 | [tracksdata Tutorial and Metric Tests](https://www.kaggle.com/code/tom99763/tracksdata-tutorial-evaluation-mock-tests) | Official-repository metric examples and synthetic graph tests | Not a submission model, but the most important notebook for building the validation harness and understanding sparse-label edge scoring. |

## What the public field has converged on

### Detection

- The useful classical detector is multi-scale 3D Difference-of-Gaussians, not
  global thresholded connected components.
- XY pooling by 4 makes the working grid approximately isotropic because Z is
  1.625 um/voxel and XY is 0.40625 um/voxel.
- Candidate coordinates should be refined on the original volume and deduplicated
  in physical micrometres.
- Detection density is a central metric tradeoff. More candidates can improve
  endpoint recall, but total-node overprediction reduces adjusted edge Jaccard.

### Linking

- Hungarian assignment with distances measured in physical units is the common
  baseline.
- Stronger classical notebooks use motion prediction and/or a tight first pass
  before a wider recovery pass.
- One-frame detection gaps should be repaired by inserting an interpolated node
  and two consecutive edges. A direct edge across two frames is not equivalent.
- Unlinked detections are usually pruned because they cannot contribute edge true
  positives and still increase the predicted-node count.

### Divisions

- Most high-scoring rule-based notebooks disable divisions by default or cap them
  aggressively. A wrong second edge can hurt both edge and division terms.
- Divisions are only weighted by 0.1 in the final score. Edge quality remains the
  primary target.
- Conservative geometric recovery is worth testing only after the edge baseline
  is stable under the exact evaluator.

### Learned/global tracking

- The genuinely different ceiling-raising family uses a pretrained temporal 3D
  U-Net, a learned edge model/transformer, and ILP global optimization.
- It depends on a public artifact dataset containing repository code, wheels, and
  weights; it is not a small modification of the standalone classical notebooks.
- This family should be evaluated as a separate pipeline, not conflated with
  rule-based notebooks whose titles mention U-Net/ILP but whose active code does
  not use them.

## Metric lessons that should control strategy

- A predicted edge only becomes a true positive when both endpoint detections
  match annotated nodes and the corresponding GT edge exists.
- Unmatched predictions are often ignored because labels are sparse, but excess
  total node count is penalized separately.
- Matching uses a 7 um physical gate. Z localization errors therefore cost about
  four times as much per voxel as XY errors.
- Official division matching is tolerant by about one timepoint and checks whether
  the pre-split stage and both daughter lineages lie in one predicted connected
  component containing a fork. It is not simple exact parent-node matching.
- The official objective is `adjusted_edge_jaccard + 0.1 * division_jaccard`.
  Proxy metrics using node F1, equal edge/division weights, or a different
  overprediction penalty can select the wrong parameters.

## Source-level risks found

1. **Titles do not identify the active pipeline.** Two highly voted notebooks
   branded as U-Net/ILP execute only DoG/Hungarian code.
2. **Public score claims are not reproduced by the downloaded sources.** The
   pulled notebooks have no outputs, and the LB 0.835 base itself is empty.
3. **Several validation proxies are materially wrong.** The ILP-tuning notebook
   averages edge and division scores 50/50 and uses a harsher custom node penalty,
   while the official division weight is 0.1. It also reduces tolerant
   component-level division scoring to exact mapped parent IDs.
4. **Some gap closing is metric-invalid.** Direct non-consecutive edges should not
   be assumed to recover missing consecutive edges.
5. **Some code mixes voxel and physical radii.** This can over-suppress along Z or
   use gates inconsistent with the 7 um matcher.

## Strategy implications

1. Implement the exact official evaluator and embryo-disjoint folds before tuning.
2. Reproduce the auditable multi-scale DoG + refinement + physical NMS + 8 um
   Hungarian + one-frame interpolation + pruning baseline.
3. Run controlled ablations for detection threshold/density, NMS radius, link
   gate, motion/two-pass linking, and gap insertion. Record nodes, matched nodes,
   edge TP/FP/FN, adjusted edge Jaccard, and runtime per embryo.
4. Test per-movie node-count calibration only after its train-to-validation
   generalization can be measured.
5. Add conservative divisions and gap-2 recovery separately; retain them only if
   the exact combined score improves across embryos.
6. In parallel conceptually, reproduce the actual artifact-backed U-Net +
   transformer + ILP pipeline and score it with the same folds. It is the likely
   ceiling raiser, but it has higher dependency and runtime risk.
