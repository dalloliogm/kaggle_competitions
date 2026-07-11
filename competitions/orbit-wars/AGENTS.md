# AGENTS.md

Competition-specific instructions for `competitions/orbit-wars`.

## Context

- Competition: Orbit Wars
- Competition URL: https://www.kaggle.com/competitions/orbit-wars/code?competitionId=138420&sortBy=scoreDescending&excludeNonAccessedDatasources=true
- Metric: repeated-game estimated skill rating
- Kaggle CLI slug: `orbit-wars`

## Working Rules

- Preserve Kaggle compatibility: code that runs on Kaggle should use `/kaggle/input/...` and `/kaggle/working`.
- Prefer small, auditable notebook/script edits over broad refactors.
- Keep root-level Kaggle UI autosaved notebooks in place unless explicitly asked to copy or move one.
- Put active competition notes in this folder: `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, and `LEARNINGS.md`.
- Before suggesting a new modeling direction, review `APPROACHES.md` and `LEARNINGS.md` to avoid repeating failed experiments.
- Put local submissions or downloaded outputs under `submissions/`; do not commit generated submission files unless explicitly requested.
- When running on Kaggle from this repository, prefer `../../scripts/kaggle_push_notebook.sh`, `../../scripts/kaggle_status.sh`, and `../../scripts/kaggle_output.sh`.

## Competition Constraints

- External code: public competition notebooks and public open-source datasets
  may be used under the competition rules and source license.
- Runtime: submitted agents must run offline and respect the 1-second action
  timeout plus overage budget.
- Validation must cover both 2-player and 4-player games with seat rotation.
- Preserve the two-role portfolio: 4P-oriented primary plus 2P-oriented
  challenger, unless ladder/replay evidence supports replacing one.
