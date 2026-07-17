# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Inputs are anisotropic 3D+time OME-Zarr movies. Physical scale is `(z, y, x) =
  (1.625, 0.40625, 0.40625)` um/voxel, so XY pooling by 4 produces an
  approximately isotropic working grid.
- Training labels are sparse GEFF tracking graphs, and dataset names group fields
  of view by embryo prefix.

## Target And Metric

- The exact objective is `adjusted_edge_jaccard + 0.1 * division_jaccard`.
- A predicted edge needs both endpoints to match within 7 um and the corresponding
  GT edge to exist. Detection quality therefore compounds into edge quality.
- Sparse-label unmatched detections are often ignored as edge false positives,
  but total-node overprediction is penalized separately.
- Official division evaluation allows temporal tolerance and tests connected
  lineage coverage; exact predicted-parent matching is not an adequate proxy.

## Validation

- Use embryo-disjoint folds and the official metric implementation. Frame-level
  or field-level random splits can leak embryo-specific appearance.
- Do not select parameters using proxies that weight division equally with edges,
  substitute node F1, or approximate the node-count penalty differently.

## Leakage And Rules

- Public notebook titles and claimed LB scores are not sufficient evidence. Inspect
  the active execution path and independently reproduce scores.
- External public artifacts are allowed, but learned pipelines must remain
  reproducible without notebook internet access.

## Features

- Multi-scale DoG is the dominant classical detector. Refine coordinates on the
  original volume and perform NMS in physical units.
- Per-movie detection density/count calibration is promising but unvalidated.
- Physical NMS `3.8 um` outperformed `3.2 um` on both held-out embryos. Aggregate
  exact validation improved `0.794304 -> 0.810458`: edge counts changed from
  `761/63/134` to `757/44/138`, so removing false links outweighed five lost TPs.
- Lowering the DoG threshold to `0.030` added nodes without changing edge counts.
  Raising it to `0.060` slightly improved only the node-count adjustment; NMS was
  the higher-impact control.

## Models

- Auditable rule-based family: DoG -> physical NMS -> Hungarian linking -> gap
  interpolation -> isolated-node pruning.
- Ceiling-raising family: temporal 3D U-Net + learned edge model/transformer + ILP.
- Several notebooks labeled U-Net/ILP actually execute only the rule-based path.
- The actual pretrained `unet_transformer` + ILP pipeline scored `0.839409` exact
  validation versus `0.810458` for the best classical model. Aggregate edges
  improved from `757/44/138` to `815/58/80` (TP/FP/FN).
- The aggregate learned gain hid opposite embryo effects: learned was worse on
  `44b6` (`0.883791` vs classical `0.942567`) but better on `6bba` (`0.836847`
  vs `0.802713`). Prefix-aware model selection gives exact validation `0.842616`.
- Learned validation strongly improved `6bba` node recall (`0.8815 -> 0.9849`)
  but overpredicted its node estimate by `19.5%`; threshold calibration above
  `0.99` may be useful after obtaining the default test baseline.
- The locked learned model processed all four test movies in `398.04` prediction
  seconds on a Tesla T4. It produced `164,682` nodes, `140,110` edges, and 12
  divisions across `304,792` submission rows; all structural checks passed.
- Test detection density varies sharply by movie (`76.03` to `757.60` nodes per
  frame). Any threshold calibration should be embryo- or density-aware and must
  be validated before replacing the global `0.99` threshold.
- Kaggle's current PyTorch build does not support P100 `sm_60`. Learned kernels
  must request `machine_shape: NvidiaTeslaT4`.
- The LB893 public notebook is not just the earlier learned pipeline. It uses a
  different support pack (`pilkwang/biohub-tracking-support-pack-50ep-v1`) and a
  score-oriented post-processor on top of learned U-Net/transformer/ILP outputs.
  Its public submission `54397298` scored `0.893`.
- LB893 output is much more biologically constrained than our learned-only output:
  `134,238` nodes, `128,121` edges, and `381` division-like sources versus
  `164,682` nodes, `140,110` edges, and 12 divisions for our learned candidate.
- The largest LB893 graph change is motion relinking: it replaced `118,984` raw
  learned edges with `122,937` motion-relinked edges, mostly under a tight
  `6.2 um` gate plus a relaxed `10.4 um` pass. Treat the learned model as a
  detector/edge-probability generator, not as the final graph.
- Gap repair should be re-tested in the LB893 context. Classical gap-2 recovery
  was harmful, but LB893 added `2,100` one-frame gap nodes and `402` gap-2 nodes
  after motion relinking.
- Safe-division insertion is risky. Full LB893 validation scored `0.9548016411`
  on the selected two labeled movies with division counts `0/4/0`. Disabling only
  safe divisions improved exact validation to `0.9606407955`, removed all four
  division false positives, and slightly improved edge Jaccard (`0.9596510360 ->
  0.9606557377`). This split has no true scored divisions, so the learning is not
  "divisions are always bad"; it is that the current safe-division heuristic must
  prove itself before being used.
- Public LB corrected that interpretation: no-safe-divisions scored `0.886`,
  below the copied LB893 score `0.893`. The hidden/public test set rewards at
  least some safe divisions. The next promising axis is not removing divisions
  completely, but tuning their precision/coverage.
- Exp073 division candidates are geometrically tight already: among 418
  division-like parents, the parent-to-daughter max distance has median about
  `3.17 um`, 95th percentile about `4.16 um`, and maximum about `6.11 um`.
  Division calibration around Exp073 should therefore use ranked risk, caps, or
  recall/coverage gates rather than broad distance cutoffs such as `8 um`.
- Post-hoc deletion of a single daughter edge is unsafe as a submission strategy:
  Exp100 passed local CSV/graph checks but Kaggle rejected submission `54776292`
  as invalid format. Prefer calibrating division insertion inside the graph
  generator, or prune a complete invalid component with a stricter validator,
  rather than surgically removing one edge from an existing fork.
- Exp101 is the safer division-calibration pattern: alter safe-division insertion
  gates/caps upstream before CSV serialization. Its output increased
  division-like sources from `418` to `531` while preserving all local structural
  invariants. Public LB will decide whether Exp073 needs more division recall or
  whether those extra divisions are mostly false positives.

## Ensembling And Submission Behavior

- One-frame gaps must be represented by an inserted node and consecutive edges;
  a direct edge across missing frames is not equivalent under the metric.
- Divisions should be conservative because their final weight is only 0.1 and a
  wrong daughter edge can hurt both metric components.
- Conservative velocity-aware gap-2 recovery did not recover any annotated edge
  on the two held-out embryos. It added 148 nodes, left aggregate edge TP/FP/FN
  unchanged at `761/63/134`, and reduced adjusted edge Jaccard by `0.000764`.
  Do not add interpolated nodes unless validation shows corresponding edge gains.

## Leaderboard Notes

- Self-reported public scores seen in reviewed notebooks range from roughly 0.72
  for classical baselines to 0.835-0.839 for newer rule-based variants, but these
  claims were not independently verified from the pulled source snapshots.
- Full review: `references/top-notebooks-analysis.md`.
- First verified public score: `0.827` for submission `54297736`.
- Physical NMS `3.8 um` improved public LB to `0.834` (submission `54307212`),
  but the current top-10% boundary is about `0.856` across 630 teams. The `0.022`
  gap is too large to justify continued nearby NMS tuning as the primary strategy.
- Learned-only submission `54323397` scored `0.810`, materially below the
  classical NMS-3.8 score `0.834`. Aggregate validation alone was misleading;
  preserve the classical model on `44b6` and test learned tracking only on the
  embryo prefix where its held-out edge recall improved.
- Copied public LB893 submission `54397298` scored `0.893`, superseding the
  prefix-aware hybrid as the working baseline. Future changes should ablate and
  improve LB893 rather than continue tuning the older classical/learned branch.
- No-safe-divisions scored `0.886`. This is competitive and novel, but it is not
  the new best. It indicates that the selected exact validation split is not
  representative for division tuning.
- Recent public notebooks on 2026-07-16 shifted the strongest graph recipe away
  from LB893 safe-division-only tuning. Exp073-style notebooks use lower
  detection threshold (`0.9700`), short-track filtering (`min_track_len=6`),
  gap2 disabled, two-frame gap close at `5.8 um`, learned motion bonus `1.0`,
  and safe divisions with looser sister radius `8.5`. Our copied Exp073 run
  produced `251,900` rows, `128,217` nodes, `123,683` edges, `418` divisions,
  and removed `6,435` short-track nodes. This suggests track-density cleanup and
  gap calibration are higher-leverage than continuing to tune only safe
  divisions.
- The copied Exp073 run scored public LB `0.903` as submission `54758569`,
  confirming the recent public-notebook claim and making Exp073 the new working
  baseline. Future original variants should modify Exp073 one mechanism at a
  time rather than reverting to LB893-only safe-division tuning.
- Private Kaggle notebook outputs are mounted under
  `/kaggle/input/notebooks/<owner>/<slug>/`. For composition kernels, discover
  expected files defensively and verify source identity before merging.
