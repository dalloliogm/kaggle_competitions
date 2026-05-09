# Tasks

## Current Goal

- Establish a reliable local workspace for ROGII - Wellbore Geology Prediction and review the pulled Kaggle notebooks.

## Next Experiments

- Run a lightweight read-through of `nn-starter-cv-15-5.ipynb` as the simplest PyTorch baseline.
- Review `rogii-lgbm-aug-online-training.ipynb` for feature ideas and leakage risks.
- Review `wellbore-geology-tcn.ipynb` for sequence modeling setup, grouped CV, and runtime feasibility on Kaggle.
- Decide on one validation protocol by well ID before making leaderboard submissions.

## Done

- Initialized workspace from `https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction`.
- Fetched Kaggle description, evaluation, rules, and file listing into `references/`.
- Copied initial ROGII notebooks from `origin/main` into `notebooks/`.

## Questions

- Which notebook is the current best public/private baseline?
- Are type-well files always available for each horizontal well in train and test?
- What are the competition-specific rules for external data and model/code licensing beyond the standard Kaggle rules?
