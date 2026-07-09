# Tasks

## Current Goal

- Improve on completed baseline submission `54491765` (`official-demo-v4-extracted-reference-agent`, public score `0.815`) without losing the known-good official demo submission behavior.

## Next Experiments

- Create `submissions/agent-configs/baseline-autonomous-tabular/` with:
  - `agent.yaml` at archive root
  - a low-temperature system prompt with an anti-loop rule
  - a `feature-engineer` skill script that discovers train/test/sample files, infers ID and target columns, and writes fallback predictions on failure
  - a local structural validator for `agent.yaml`, `!include` paths, tool names, skill manifests, and final zip contents
- Download or mount the full training set locally only if needed for offline replay; keep large generated data out of git.
- Build a replay harness over the provided `train_01`... training folders:
  - hide `solution.csv` from the modeling script
  - train on `train.csv`
  - predict `test.csv`
  - score against `solution.csv` with ROC AUC
  - aggregate per-folder scores and runtime
- Compare three modeling levels:
  - fast logistic regression / HistGradientBoosting fallback
  - row-wise numeric aggregates plus interactions and CV-safe target encoding
  - LightGBM/XGBoost/CatBoost blend if available in the target environment
- Package and validate `submission.zip` locally before any Kaggle upload.
- After first live submission, inspect public feedback and record exact outcome in `APPROACHES.md` and `LEARNINGS.md`.
- If `54491765` errors, retrieve the detailed API error with:
  - `.venv/bin/python` plus `KaggleApi().competition_submissions('autonomous-agent-prediction-beta')`
- If another custom package is needed, keep the zip filename exactly `submission.zip` and do not include `run_skill_script`.
- Before the next upload, check whether the daily quota has reset; v5 was rejected with generic `400 Bad Request` after four recorded rows and one earlier upload-gate rejection.

## Done

- Initialized workspace from the official Kaggle URL on 2026-07-09.
- Confirmed Kaggle metadata on 2026-07-09: `userHasEntered=True`, deadline `2026-08-06 23:59:00`, 43 teams, reward `Swag`.
- Pulled official description, evaluation, rules, and file listing into `references/`.
- Confirmed Kaggle CLI data access by downloading `data/train_01/DATA.md` and `data/train_01/sample_submission.csv`.
- Pulled public notebooks:
  - `sidhaarthshree/autonomous-agent-prediction-a-to-z-guide`
  - `nursrijan/agent-starter-dynamic-automl-guide`
- Created local tutorial scaffold:
  - `notebooks/autonomous-agent-prediction-beta-competition-tutorial.ipynb`
- Added source-level notes and repo-improvement backlog in `references/`.
- Submitted four agent packages on 2026-07-09:
  - `54491451`: custom v1, errored with no `submit_predictions`
  - `54491555`: custom v2, errored because `run_skill_script` is unavailable
  - `54491615`: custom v3, errored with no `submit_predictions`
  - `54491765`: official-demo v4, completed with public score `0.815`
- Attempted v5 (`official-demo-v5-model-recipe-no-run-skill-script`); upload rejected with generic `400 Bad Request` and no row.

## Questions

- Re-check the deadline before serious submission work; current CLI metadata says `2026-08-06 23:59:00`, but Kaggle timelines can change.
- Verify the exact supported ADK config keys against the demo notebook/sample submission before uploading. The public notebooks disagree on `agent.yaml` shape (`instruction`/`tools` versus `system_prompt`/`allowed_tools`).
- Verify which Python packages are preinstalled inside the evaluation sandbox before relying on LightGBM, XGBoost, or CatBoost.
