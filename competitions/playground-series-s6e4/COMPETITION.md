# Playground Series S6e4 — Predicting Irrigation Need

## Links

- Competition: https://www.kaggle.com/competitions/playground-series-s6e4
- Kaggle workspace slug: `playground-series-s6e4`
- Kaggle CLI slug: `playground-series-s6e4`

## Objective

Predict irrigation need from a tabular synthetic dataset. The classification flavor (binary vs. multiclass) needs to be confirmed from the competition page — the public-ensemble notebook auto-detects it from `sample_submission.csv`.

## Evaluation

- Metric: TBD — confirm on competition Overview/Evaluation tab
- Validation approach: TBD (typical Playground Series setup is stratified K-fold for classification, K=5)
- Public/private leaderboard notes: TBD

## Data

- Kaggle input path: `/kaggle/input/playground-series-s6e4/`
- Local data path: `data/playground-series-s6e4/`
- Key files: typically `train.csv`, `test.csv`, `sample_submission.csv` for Playground Series — confirm

## Submission

- Expected file: `submission.csv`
- Required columns: TBD (read from `sample_submission.csv` after data download)
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: TBD
- Internet: TBD
- GPU/TPU: TBD
- Team/merge rules: standard Playground Series rules unless stated otherwise

## Current Baseline

- Local CV: TBD
- Public LB: TBD
- Notebook/kernel: `notebooks/ps6e4-automated-public-ensemble-v2.ipynb` (automated public-solutions blender)

## Notes

- This is the April 2026 monthly Playground Series (S6E4 = Season 6 Episode 4).
- Detailed Overview / Evaluation / Rules text could not be auto-fetched here: the sandbox has `kaggle.com` outside its network allowlist, and the `init_competition_workspace.py` fetch step requires the local `kaggle` CLI. Run the init script from your terminal to populate `references/`:
  ```bash
  cd ~/workspace/kaggle_competitions
  ./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/playground-series-s6e4
  ```
