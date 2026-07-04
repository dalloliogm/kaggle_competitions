# Biohub Cell Tracking During Development

## Links

- Competition: https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/overview
- Kaggle workspace slug: `biohub-cell-tracking-during-development`
- Kaggle CLI slug: `biohub-cell-tracking-during-development`
- Final submission deadline: 2026-09-29 23:59 UTC (verify on Kaggle for changes)

## Objective

Detect cells in 3D time-lapse microscopy, link detections across frames, and
identify division events to reconstruct cell lineages.

## Evaluation

- Metric: `adjusted_edge_jaccard + 0.1 * division_jaccard`
- Validation approach: Split complete training sequences by dataset; score
  held-out sequences with the competition metric rather than randomizing
  individual cells or frames.
- Public leaderboard: first DoG/Hungarian submission scored `0.827` on
  2026-07-03 (submission `54297736`).
- Second submission (`54307212`) with physical NMS `3.8 um` scored `0.834`.
- Current snapshot: rank `203/630`; top-10% boundary approximately `0.856`.

## Data

- Kaggle input path: `/kaggle/input/biohub-cell-tracking-during-development/`
- Local data path: `data/biohub-cell-tracking-during-development/`
- Key files: `sample_submission.csv`, Zarr datasets under `train/` and `test/`

## Submission

- Expected file: `submission.csv`
- Required columns: `id,dataset,row_type,node_id,t,z,y,x,source_id,target_id`
- Row types: node rows contain integer centroid coordinates; edge rows contain
  `source_id` and `target_id`; unused fields are `-1`.
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: Allowed when publicly available/equally accessible at no cost,
  or otherwise satisfies Kaggle's reasonableness standard.
- Internet: Confirm notebook runtime settings before the first submission.
- GPU/TPU: Confirm notebook runtime settings before the first submission.
- Team/merge rules: Timeline and merge details must be verified on Kaggle.
- Submission limit: 5 per day

## Current Baseline

- Local CV: exact validation completed on Kaggle; artifact download remains
  blocked by Kaggle output API HTTP 429.
- Public LB: `0.827`
- Notebook: `notebooks/biohub-exact-dog-hungarian-baseline.ipynb`
- Kaggle kernel: `dalloliogm/biohub-exact-validation-and-dog-hungarian-baseline`
- Kernel version 7 completed successfully on 2026-07-03 and produced the first
  scored submission (`54297736`).

## Current Candidate

- Notebook: `notebooks/biohub-learned-unet-ilp-candidate.ipynb`
- Kaggle kernel: `dalloliogm/biohub-learned-unet-ilp-candidate`, version 1.
- Exact validation: `0.8394088969` versus classical NMS-3.8 `0.8104577161`.
- Test output: all four movies, `304,792` rows (`164,682` nodes and `140,110`
  edges), with 12 conservative division events.
- Validation: exact columns, global IDs, no missing values, per-dataset node
  IDs, edge endpoints, consecutive-frame edges, and graph degrees all passed.
- Competition status: ready for manual submission; public LB not yet known.
