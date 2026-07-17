# AGENTS.md

Competition-specific instructions for `competitions/biohub-cell-tracking-during-development`.

## Context

- Competition: Biohub Cell Tracking During Development
- Competition URL: https://www.kaggle.com/competitions/biohub-cell-tracking-during-development/overview
- Metric: `adjusted_edge_jaccard + 0.1 * division_jaccard`
- Kaggle CLI slug: `biohub-cell-tracking-during-development`

## Working Rules

- Preserve Kaggle compatibility: code that runs on Kaggle should use `/kaggle/input/...` and `/kaggle/working`.
- Prefer small, auditable notebook/script edits over broad refactors.
- Keep root-level Kaggle UI autosaved notebooks in place unless explicitly asked to copy or move one.
- Put active competition notes in this folder: `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, and `LEARNINGS.md`.
- Before suggesting a new modeling direction, review `APPROACHES.md` and `LEARNINGS.md` to avoid repeating failed experiments.
- Put local submissions or downloaded outputs under `submissions/`; do not commit generated submission files unless explicitly requested.
- When running on Kaggle from this repository, prefer `../../scripts/kaggle_push_notebook.sh`, `../../scripts/kaggle_status.sh`, and `../../scripts/kaggle_output.sh`.
- Kaggle competition submissions can take several hours to validate. For this
  challenge, do not wait for one pending public-LB result before preparing the
  next independent candidate. When daily submission slots remain and a candidate
  has completed on Kaggle with structural checks passing, submit multiple
  distinct candidates in parallel, then interpret the leaderboard results later.
  Still avoid submitting known-invalid outputs such as Exp100.

## Competition Constraints

- External data: Allowed when publicly available/equally accessible at no cost,
  or otherwise satisfies Kaggle's reasonableness standard.
- Internet/GPU/TPU assumptions: TBD
- Known leakage risks: Do not split individual frames or cells from the same
  time series across training and validation; validate on complete datasets.
