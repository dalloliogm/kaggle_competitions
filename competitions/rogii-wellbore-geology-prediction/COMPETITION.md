# Rogii Wellbore Geology Prediction

## Links

- Competition: https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction
- Kaggle workspace slug: `rogii-wellbore-geology-prediction`
- Kaggle CLI slug: `rogii-wellbore-geology-prediction`

## Objective

Predict the true vertical thickness/depth target (`tvt`) along horizontal wellbores from drilling and well-log data. The competition is framed around automating geological interpretation during well placement, using horizontal well measurements, paired type-well curves, and partial known `TVT_input` values.

## Evaluation

- Metric: root mean squared error (RMSE) on hidden test rows.
- Validation approach: use grouped validation by well ID; avoid splitting rows from the same well across train/validation folds.
- Public/private leaderboard notes: TBD.

## Data

- Kaggle input path: `/kaggle/input/rogii-wellbore-geology-prediction/`
- Alternate Kaggle input path used by some notebooks: `/kaggle/input/competitions/rogii-wellbore-geology-prediction/`
- Local data path: `data/rogii-wellbore-geology-prediction/`
- Key files:
  - `train/*__horizontal_well.csv`
  - `train/*__typewell.csv`
  - `train/*.png`
  - `test/*__horizontal_well.csv`
  - `test/*__typewell.csv`
  - `sample_submission.csv`
  - `AI_wellbore_geology_prediction_task_en.pptx`

## Submission

- Expected file: `submission.csv`
- Required columns: `id,tvt`
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: check competition rules before using any non-competition data.
- Internet: notebooks currently pulled from Kaggle metadata have internet disabled.
- GPU/TPU: TBD
- Team/merge rules: no private sharing outside the official Kaggle team; public code sharing should be through the competition forum/notebooks.

## Current Baseline

- Local CV: TBD
- Public LB: TBD
- Notebook/kernel:
  - `notebooks/nn-starter-cv-15-5.ipynb`
  - `notebooks/rogii-lgbm-aug-online-training.ipynb`
  - `notebooks/wellbore-geology-tcn.ipynb`
