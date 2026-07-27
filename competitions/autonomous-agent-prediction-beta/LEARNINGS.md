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
- A binary target is not expected to follow a normal distribution. Do not log,
  rank, Box-Cox, or otherwise transform it for normality; inspect and transform
  predictors only when their distribution suggests a concrete benefit.

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
- Turning on all plausible feature families at once reduced the CatBoost
  specialist's 16-task replay mean from 0.7990 to 0.7981.
- Numeric predictor transformations alone reached 0.7994. They helped some
  tasks but hurt others, so non-normality is not by itself a reason to transform
  a predictor for a tree model.
- A replay-derived schema gate reached 0.8001: it kept 12 tasks identical to the
  CatBoost baseline and improved four selected small-table tasks. This is a
  useful candidate, but its thresholds were chosen after ablation results and
  therefore require live validation.
- An LLM can safely assist by reading a solution-blind distribution profile and
  emitting an allowlisted JSON recommendation. It should never generate
  executable feature code, inspect solution files, transform the binary target,
  or override the mandatory first baseline.

## Models

- First baseline should be boring and reliable: preprocessing plus logistic regression or histogram gradient boosting.
- Optional higher-ceiling approach: LightGBM/XGBoost/CatBoost with OOF blending, if packages are available in the sandbox and runtime remains safe.
- Any search must have hard caps on row count, CV folds, iterations, and elapsed time.
- The standalone CatBoost specialist averaged 0.7990 test AUC over all 16 official replay tasks. It averaged 0.8247 on the 11 tasks with at least 2,000 training rows but only 0.7424 on the five smaller tasks, with three scores below 0.70. CatBoost is useful as a gated specialist, not a universal default.
- Evaluating only `train_01`–`train_03` would have been misleading: the CatBoost candidate averaged 0.8315 on those three but degraded substantially across the complete 16-task set.
- AutoGluon classical averaged 0.7995 over the same 16 tasks, essentially tying CatBoost's 0.7990 with eight wins each. Its small-task mean was slightly worse, so the wrapper is not justified as a standalone dependency.
- Mitra zero-shot CPU inference was 28x to 173x slower than AutoGluon classical on identical 1,000-row samples while remaining within 0.003 AUC on all three completed comparisons. AutoGluon estimated about 7 GB RAM, and one 3,501-row task did not fit under the available memory.
- AutoGluon, Mitra, and TabPFN are absent from the current official Kaggle Python image. The offline evaluator cannot install them or download model weights. TPOT, H2O, Optuna, and CatBoost are present.
- Current TabPFN is not a safe submission dependency: its documentation recommends GPU use, the default weights have a non-commercial license, and the older v2 license has an additional attribution provision that needs competition-rule clearance.

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
- Submission `55029319` showed that passing YAML/include checks and dry-run ADK
  compilation does not verify runtime tool use. Its imperative
  `run_command`-first prompt repeated the same terminal failure as v1 and v3:
  the agent ended without ever calling `submit_predictions`.
- The next candidate must preserve the proven v4/v5 orchestration layer,
  including the official agent identity, generation settings, initial
  `data_analyst` delegation, and explicit warning that a text-only response ends
  the session. Modeling improvements should live underneath that shell.
- A failed daily submission can be refunded even though a conservative
  submission-history counter still reports the nominal 1/day allowance as
  exhausted. On 2026-07-27, Kaggle accepted recovery submission `55030429`
  after `55029319` errored.

## Leaderboard Notes

- Submission `55030429`: `PENDING`; v9 restores the v5 control shell and makes
  adaptive feature engineering optional after the first valid submission.
- Submission `55029319`: `ERROR`; `Agent completed without submitting any valid
  predictions (submit_predictions was never called).` Kaggle refunded its
  2026-07-27 slot.
- Submission `55011609`: `COMPLETE`, public score `0.818`; the model-recipe prompt did not improve on v6.
- Submission `54972472`: `COMPLETE`, public score `0.819`; `official-demo-v6-blended-baseline` is the current live best.
- Submission `54491451`: `ERROR`, detailed API message `Agent completed without submitting any valid predictions (submit_predictions was never called).`
- Submission `54491555`: `ERROR`, detailed API message `Tool 'run_skill_script' not found in registry.`
- Submission `54491615`: `ERROR`, detailed API message `Agent completed without submitting any valid predictions (submit_predictions was never called).`
- Submission `54491765`: `COMPLETE`, public score `0.815`; this is the extracted official demo package and current live baseline.
- v5 upload attempt `official-demo-v5-model-recipe-no-run-skill-script`: generic `400 Bad Request`, no submission row created.
- Leaderboard snapshot on 2026-07-09 after `54491765`: first page ranged from `0.825` down to `0.815`; Giovanni Marco Dall'Olio appeared with score `0.815`.
- Public feedback during a session can guide final selection, but do not design a strategy that depends on probing or overfitting public rows.
- Live Kaggle metadata reported a 1/day submission limit on 2026-07-26, superseding the older 5/day workspace note.
