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

## Models

- Auditable rule-based family: DoG -> physical NMS -> Hungarian linking -> gap
  interpolation -> isolated-node pruning.
- Ceiling-raising family: temporal 3D U-Net + learned edge model/transformer + ILP.
- Several notebooks labeled U-Net/ILP actually execute only the rule-based path.

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
