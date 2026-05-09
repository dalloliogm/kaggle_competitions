# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Train/test are organized as per-well horizontal-well CSVs and paired type-well CSVs.
- Train also includes PNGs.
- Pulled notebook metadata indicates competition source ID `132265` and bundle version `17009696`.

## Target And Metric

- Submission target is `tvt`.
- Official metric is RMSE.
- Submission columns are `id,tvt`.

## Validation

- Treat well ID as the grouping unit for validation.
- Avoid row-level random splits across the same well.

## Leakage And Rules

- Track any feature engineering that uses hidden target values or blends train/test rows.
- Online/calibration-zone training needs explicit review before trusting leaderboard gains.

## Features

- Existing notebooks emphasize trajectory (`X`, `Y`, `Z`, `MD`), GR, lag/rolling features, type-well alignment, and calibration from known `TVT_input`.

## Models

- Initial copied notebooks cover PyTorch NN, TCN, and LightGBM approaches.

## Ensembling And Submission Behavior

- TBD

## Leaderboard Notes

- TBD
