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
- Learned U-Net/transformer/ILP submission (`54323397`) scored `0.810`.
- Copied LB893 learned graph tracker submission (`54397298`) scored `0.893`.

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

## Current public best — September 6 results

- Public best: 0.939, image threshold .08, submission 56050357,
  `dalloliogm/biohub-sep06-image08` v1.
- Preserve frozen .80 / 0.938 control 56010101; hashes in
  `references/incumbent_manifest.json`. This manifest remains the batch reference.
- Best artifact hash: `references/sep06-batch-execution.json` (image08).
- Independent holdout not established; `references/validation_split_manifest.json`.
- Five September 6 scores complete; see `TASKS.md` for results and next steps.
- GEFF diagnostic compatibility fixed locally following v1 error; not rerun.
