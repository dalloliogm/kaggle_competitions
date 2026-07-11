# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Practice data is organized as mini-competition folders with `DATA.md`, `train.csv`, `test.csv`, `sample_submission.csv`, and `solution.csv`.
- Hidden evaluation sessions should be treated as one dataset per session, not a loop over all practice folders.
- `solution.csv` exists for training mini-competitions only and must be excluded from any submitted agent's discovery/modeling path.
- `sample_submission.csv` is the safest source of required output column names, row order, and row count.

## Target And Metric

- Official metric is ROC AUC.
- The target is binary; submissions should be continuous probabilities in `[0, 1]`, not hard labels.
- Local validation should optimize ranking quality, not threshold accuracy.

## Validation

- Use stratified CV for binary classification.
- Use out-of-fold encoding for target/frequency features to avoid leakage.
- Build a local replay harness using `solution.csv` only outside the submitted agent. Score predictions after the agent/model has written them.
- For tiny training sets, simpler regularized models may beat complex engineered pipelines due to variance and overfitting.

## Leakage And Rules

- Never read files whose names imply `solution`, `answer`, `truth`, or `ground` in submitted agent code.
- Public notebook review shows a useful blacklist pattern for discovery functions.
- External data and AutoML tools are allowed only if they satisfy accessibility, cost, license, and reproducibility constraints.
- The competition allows public code sharing through Kaggle; private sharing outside teams is not allowed.

## Features

- Useful general-purpose tabular features from public notebooks:
  - row-level numeric aggregates
  - pairwise numeric interactions among high-correlation features
  - frequency encoding for categorical variables
  - K-fold target encoding for categorical variables
- Treat low-cardinality numeric columns as categorical candidates, but verify this does not hurt tree models.

## Models

- First baseline should be boring and reliable: preprocessing plus logistic regression or histogram gradient boosting.
- Optional higher-ceiling approach: LightGBM/XGBoost/CatBoost with OOF blending, if packages are available in the sandbox and runtime remains safe.
- Any search must have hard caps on row count, CV folds, iterations, and elapsed time.

## Ensembling And Submission Behavior

- Agent behavior matters as much as model choice. The system prompt should force:
  - `get_status`
  - run modeling skill
  - submit first valid `submission.csv`
  - only then attempt one improvement
  - select final submission before budget is low
- Always include a fallback prediction writer; a weak valid submission beats a crash or no submission.
- Validate both the source folder and the final `submission.zip`; a valid folder can still produce a stale or malformed archive.
- Upload filename matters in this beta: uploading the same valid archive as `baseline-autonomous-tabular-20260709.zip` returned a generic `400 Bad Request`, while naming it exactly `submission.zip` succeeded.
- The live tool registry exposed by the harness is: `edit_file`, `get_status`, `read_file`, `run_command`, `select_submission`, `submit_predictions`, `write_file`.
- `run_skill_script` is not currently available in the live runtime, despite appearing in some public notebooks.
- Custom prompts that only tell the agent to run a bundled script did not lead to a valid `submit_predictions` call in submissions `54491451` and `54491615`; the next strategy should either use the official demo workflow or make the first tool calls even more constrained through official-compatible structure.
- The official-demo structure is the only package so far that completed evaluation; preserve it when iterating.
- A v5 package that preserved official structure but changed prompt/resources was rejected at upload with generic `400 Bad Request` and created no row. This may be daily-limit behavior or stricter package validation.

## Leaderboard Notes

- Submission `54491451`: `ERROR`, detailed API message `Agent completed without submitting any valid predictions (submit_predictions was never called).`
- Submission `54491555`: `ERROR`, detailed API message `Tool 'run_skill_script' not found in registry.`
- Submission `54491615`: `ERROR`, detailed API message `Agent completed without submitting any valid predictions (submit_predictions was never called).`
- Submission `54491765`: `COMPLETE`, public score `0.815`; this is the extracted official demo package and current live baseline.
- v5 upload attempt `official-demo-v5-model-recipe-no-run-skill-script`: generic `400 Bad Request`, no submission row created.
- Leaderboard snapshot on 2026-07-09 after `54491765`: first page ranged from `0.825` down to `0.815`; Giovanni Marco Dall'Olio appeared with score `0.815`.
- Public feedback during a session can guide final selection, but do not design a strategy that depends on probing or overfitting public rows.
