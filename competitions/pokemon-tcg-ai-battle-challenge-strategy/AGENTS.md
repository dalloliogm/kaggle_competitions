# AGENTS.md

Competition-specific instructions for `competitions/pokemon-tcg-ai-battle-challenge-strategy`.

## Context

- Competition: Pokemon Tcg AI Battle Challenge Strategy
- Competition URL: https://www.kaggle.com/competitions/pokemon-tcg-ai-battle-challenge-strategy
- Metric: TBD
- Kaggle CLI slug: `pokemon-tcg-ai-battle-challenge-strategy`

## Working Rules

- Preserve Kaggle compatibility: code that runs on Kaggle should use `/kaggle/input/...` and `/kaggle/working`.
- Prefer small, auditable notebook/script edits over broad refactors.
- Keep root-level Kaggle UI autosaved notebooks in place unless explicitly asked to copy or move one.
- Put active competition notes in this folder: `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, and `LEARNINGS.md`.
- Before suggesting a new modeling direction, review `APPROACHES.md` and `LEARNINGS.md` to avoid repeating failed experiments.
- Put local submissions or downloaded outputs under `submissions/`; do not commit generated submission files unless explicitly requested.
- When running on Kaggle from this repository, prefer `../../scripts/kaggle_push_notebook.sh`, `../../scripts/kaggle_status.sh`, and `../../scripts/kaggle_output.sh`.

## Competition Constraints

- External data: TBD
- Internet/GPU/TPU assumptions: TBD
- Known leakage risks: TBD
