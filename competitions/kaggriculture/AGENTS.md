# AGENTS.md

Competition-specific instructions for `competitions/kaggriculture`.

## Context

- Competition: Kaggriculture
- Competition URL: https://www.kaggle.com/competitions/kaggriculture
- Metric: episode outcomes aggregated as skill rating; final Bradley-Terry tournament
- Kaggle CLI slug: `kaggriculture`

## Working Rules

- Preserve Kaggle compatibility: code that runs on Kaggle should use `/kaggle/input/...` and `/kaggle/working`.
- Prefer small, auditable notebook/script edits over broad refactors.
- Keep root-level Kaggle UI autosaved notebooks in place unless explicitly asked to copy or move one.
- Put active competition notes in this folder: `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, and `LEARNINGS.md`.
- Before suggesting a new modeling direction, review `APPROACHES.md` and `LEARNINGS.md` to avoid repeating failed experiments.
- Read `references/competition-files/unpacked/README.md` and `AGENTS.md` before
  changing game logic; they are the downloaded official 2026-09-07 source.
- Benchmark candidate agents in separate processes, using seeded side-swapped
  episodes. Preserve prior promoted agents as frozen opponents.
- Inspect public episode replays before extensive heuristic tuning.
- Put local submissions or downloaded outputs under `submissions/`; do not commit generated submission files unless explicitly requested.
- When running on Kaggle from this repository, prefer `../../scripts/kaggle_push_notebook.sh`, `../../scripts/kaggle_status.sh`, and `../../scripts/kaggle_output.sh`.

## Competition Constraints

- External data: allowed if reasonably accessible to all at minimal cost.
- Internet/GPU/TPU assumptions: no network ingress/egress during evaluation;
  baseline is CPU-only and self-contained.
- Known leakage risks: adjacent replay steps are correlated; split replay data
  by episode and avoid tuning only to public ladder outcomes.
- Submission interface: `main.py` at archive root with `agent(obs)` returning
  `farmer`, `hands`, and `market` actions.
- Submission boundary: never upload without explicit artifact-and-destination
  approval after checksum, archive-layout, and local runtime validation.
