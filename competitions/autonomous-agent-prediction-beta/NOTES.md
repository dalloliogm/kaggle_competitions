# Notes

## EDA Observations

- Official description says there are 16 training datasets drawn from a common family of data-generating processes.
- `data/train_01/DATA.md` documents a binary tabular task with `row_id`, mixed `feature_*` columns, and `target` only in `train.csv`.
- Downloaded `sample_submission.csv` has 10,000 prediction rows plus header and columns `row_id,target`.
- The public AutoML starter says "18 synthetic datasets"; treat that as unverified because it conflicts with the official description.
- The CLI file listing returned a next-page token and showed `train_01` through `train_04` on the first page. Refresh the full listing if file counts matter.

## Feature Ideas

- Schema-agnostic file discovery: never assume file names or column names beyond what can be inferred from train/test/sample structure.
- ID/target inference:
  - ID from sample submission first column or unique ID-like test column.
  - Target from train-only column, `target_col.txt` hint, or binary train-only column.
- Numeric row aggregates: mean, min, max, sum, std, null count.
- Pairwise interactions among the top correlated numeric columns.
- CV-safe target encoding for categorical columns; never use a row's own target to encode that row.
- Frequency encoding for categorical columns, especially high-cardinality columns.
- Train-size branch:
  - small datasets: regularized logistic regression or simpler models to avoid overfitting
  - larger datasets: histogram gradient boosting or tree ensembles with capped search effort

## Model Ideas

- First valid agent: prioritize a guaranteed `submit_predictions` call over extended reasoning.
- Baseline model stack:
  - logistic regression with preprocessing for small data
  - `HistGradientBoostingClassifier` with bounded `RandomizedSearchCV` for medium data
  - optional LightGBM/XGBoost/CatBoost blend after package availability is verified
- Always produce calibrated probability-like outputs in `[0, 1]`; never submit hard labels for ROC AUC.
- Add a constant-prior fallback path so a failed modeling attempt still writes a valid prediction file.
- Use public feedback inside the session only after a valid baseline has already been submitted.

## Useful References

- Official description: `references/kaggle_description.md`
- Official evaluation: `references/kaggle_evaluation.md`
- Official rules: `references/kaggle_rules.md`
- Official demo notebook: `references/official-demo/autonomous-agent-prediction-beta-demo-agent.ipynb`
- Official file list snapshot: `references/kaggle_files.txt`
- Schema sample: `references/data-samples/DATA.md`
- Sample submission: `references/data-samples/sample_submission.csv`
- Public notebook source summary: `references/public-notebooks/NOTEBOOK_SUMMARY.md`
- Repo improvement backlog: `references/repo-improvement-backlog.md`
- A-to-Z public notebook: `references/public-notebooks/a-to-z-guide/autonomous-agent-prediction-a-to-z-guide.ipynb`
- Dynamic AutoML public notebook: `references/public-notebooks/dynamic-automl-guide/agent-starter-dynamic-automl-guide.ipynb`
