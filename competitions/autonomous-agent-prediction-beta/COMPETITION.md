# Autonomous Agent Prediction Beta

## Links

- Competition: https://www.kaggle.com/competitions/autonomous-agent-prediction-beta/overview
- Kaggle workspace slug: `autonomous-agent-prediction-beta`
- Kaggle CLI slug: `autonomous-agent-prediction-beta`
- Kaggle metadata checked: 2026-07-09
- User entered: yes (`userHasEntered=True` from Kaggle CLI)
- Deadline: 2026-08-06 23:59:00
- Category: Playground
- Reward: Swag
- Team count at metadata check: 43

## Objective

Engineer an autonomous ML agent that can solve unseen tabular binary-classification mini-competitions. The submitted artifact is an agent configuration, not a fixed prediction CSV.

During evaluation, each agent session receives a training dataset, a test dataset, and a sample submission in a Kaggle CPU sandbox. The agent explores the data, trains models, submits predictions for public-feedback scoring, then selects final submissions for private scoring.

## Evaluation

- Metric: ROC AUC.
- Validation approach: local leakage-safe CV on the provided training mini-competitions, then live mini-competition public feedback inside the agent session.
- Public/private leaderboard notes: each agent submission runs through two mini-competition sessions, one for the public leaderboard and one for the private leaderboard. The agent may see public subset scores during a session and should select final submissions for hidden private scoring.

## Data

- Kaggle input path: `/kaggle/input/autonomous-agent-prediction-beta/`
- Local data path: `data/autonomous-agent-prediction-beta/`
- Key files:
  - `.env.example`
  - `data/train_01/` through the official training set folders described by Kaggle
  - each training folder contains `DATA.md`, `train.csv`, `test.csv`, `sample_submission.csv`, and `solution.csv`
- Schema sample from `data/train_01/DATA.md`: `row_id`, mixed numeric/categorical/ordinal `feature_*` columns, and binary categorical `target` in `train.csv` only.
- Downloaded schema references:
  - `references/data-samples/DATA.md`
  - `references/data-samples/sample_submission.csv`

## Submission

- Expected file: `submission.zip`.
- Required archive root: `agent.yaml`.
- Expected archive contents may include `prompts/`, `tools/`, and `skills/`.
- Runtime prediction file: the agent should generate a valid `submission.csv` during each mini-competition session and call `submit_predictions`.
- Sample prediction columns: `row_id,target`.
- Generated outputs: `submissions/`.

## Rules And Constraints

- External data: allowed if publicly available, equally accessible or otherwise reasonably accessible, and compliant with competition rules.
- Automated ML tools: allowed if license and reproducibility obligations are satisfied.
- Internet: design submitted agents for offline sandbox execution; do not rely on package installs or network access during evaluation.
- Compute: agents run in a standard Kaggle CPU environment.
- Team/merge rules: maximum team size is 5; team mergers allowed under the stated submission-count rules.
- Submission limits: 5 submissions per day; up to 2 final submissions for judging.
- Data license: CC BY 4.0.
- Data/security: do not privately redistribute competition data to people who have not accepted the rules.

## Current Baseline

- Local CV: not run yet.
- Public LB: no local submission recorded yet.
- Notebook/kernel: public notebooks copied under `references/public-notebooks/`; local tutorial scaffold is `notebooks/autonomous-agent-prediction-beta-competition-tutorial.ipynb`.
