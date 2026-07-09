# AGENTS.md

Competition-specific instructions for `competitions/autonomous-agent-prediction-beta`.

## Context

- Competition: Autonomous Agent Prediction Beta
- Competition URL: https://www.kaggle.com/competitions/autonomous-agent-prediction-beta/overview
- Metric: ROC AUC
- Kaggle CLI slug: `autonomous-agent-prediction-beta`

## Working Rules

- Preserve Kaggle compatibility: code that runs on Kaggle should use `/kaggle/input/...` and `/kaggle/working`.
- Prefer small, auditable notebook/script edits over broad refactors.
- Keep root-level Kaggle UI autosaved notebooks in place unless explicitly asked to copy or move one.
- Put active competition notes in this folder: `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, and `LEARNINGS.md`.
- Before suggesting a new modeling direction, review `APPROACHES.md` and `LEARNINGS.md` to avoid repeating failed experiments.
- Put local submissions or downloaded outputs under `submissions/`; do not commit generated submission files unless explicitly requested.
- When running on Kaggle from this repository, prefer `../../scripts/kaggle_push_notebook.sh`, `../../scripts/kaggle_status.sh`, and `../../scripts/kaggle_output.sh`.

## Competition Constraints

- Submission artifact is `submission.zip`, not `submission.csv`; `agent.yaml` must be at the archive root.
- The agent must generate and submit prediction CSVs inside the evaluation session.
- Agents run in a standard Kaggle CPU environment; submitted logic should not rely on internet access or package installation.
- External data and AutoML tools are allowed only when reasonably accessible, properly licensed, and reproducible under the rules.
- Daily submission limit is 5; final submission selection limit is 2.
- Known leakage risks:
  - submitted agent code must not read `solution.csv` or similarly named answer/ground-truth files
  - target encoding must be out-of-fold for training rows
  - public-feedback scores should not become an unbounded probing loop

## Agent-Config Guidance

- Before proposing a new modeling direction, read `APPROACHES.md`, `LEARNINGS.md`, and `references/public-notebooks/NOTEBOOK_SUMMARY.md`.
- Prioritize a valid first submission over exploration. A good prompt should make `submit_predictions` mandatory before optional EDA.
- Submitted skills should be schema-agnostic:
  - discover train/test/sample files from the task directory
  - infer ID and target columns from train/test/sample structure
  - preserve sample submission columns/order when present
  - write a constant-prior fallback if modeling fails
- Validate both the folder and the final zip before uploading:
  - `agent.yaml` exists at archive root
  - `!include` paths stay inside the archive
  - allowed tools are spelled correctly
  - every skill folder has `SKILL.md`
  - no `__pycache__`, `.pyc`, or stale/generated junk is packaged
