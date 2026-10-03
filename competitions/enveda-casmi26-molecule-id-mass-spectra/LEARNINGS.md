# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- TBD

## Target And Metric

- TBD

## Validation

- TBD

## Leakage And Rules

- TBD

## Features

- TBD

## Models

- TBD

## Ensembling And Submission Behavior

- TBD

## Leaderboard Notes

- TBD

- `train.parquet` has NO `spectrum_id`/`molecule_id` columns (only test does); the notebook uses the global row index as spectrum id.
- Kaggle mounts the competition at `/kaggle/input/competitions/<slug>/` (found via recursive glob). Notebook needs `kernelspec` metadata or papermill fails.
- Visible test.parquet is drawn from train (400 mols, 1213 spectra), so its predictions are leaky; hidden test replaces it on rerun.
- Kaggle CLI (`uvx kaggle`): pages via `kaggle competitions pages list --content -c <slug>`; `init_competition_workspace.py` needs fixing for this.
