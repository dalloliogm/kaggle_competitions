# AGENTS.md

Competition-specific instructions for `competitions/neurogolf-2026`.

## Context

- Competition: Neurogolf 2026
- Competition URL: https://www.kaggle.com/competitions/neurogolf-2026
- Metric: per-task `max(1, 25 - ln(parameters + memory bytes))` for
  functionally correct ONNX networks.
- Kaggle CLI slug: `neurogolf-2026`

## Working Rules

- Preserve Kaggle compatibility: code that runs on Kaggle should use `/kaggle/input/...` and `/kaggle/working`.
- Prefer small, auditable notebook/script edits over broad refactors.
- Keep root-level Kaggle UI autosaved notebooks in place unless explicitly asked to copy or move one.
- Put active competition notes in this folder: `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, and `LEARNINGS.md`.
- Before suggesting a new modeling direction, review `APPROACHES.md` and `LEARNINGS.md` to avoid repeating failed experiments.
- Put local submissions or downloaded outputs under `submissions/`; do not commit generated submission files unless explicitly requested.
- Submit `submission.zip`, not `submission.csv`. The zip must contain root-level
  ONNX files named `task001.onnx` through `task400.onnx`; missing task files are
  allowed by schema.
- Validate generated ONNX files against train, test, and `arc-gen` examples
  using the official `data/neurogolf_utils/neurogolf_utils.py` conventions
  before adding them to a manual submission package.
- The current reproducible baseline builder is
  `scripts/build_color_map_submission.py`; it creates
  `submissions/color-map-baseline/submission.zip` for four pure color-map tasks.
- When running on Kaggle from this repository, prefer `../../scripts/kaggle_push_notebook.sh`, `../../scripts/kaggle_status.sh`, and `../../scripts/kaggle_output.sh`.

## Competition Constraints

- External data: allowed under the competition's reasonable/equally-accessible
  rule; keep provenance reproducible.
- Internet/GPU/TPU assumptions: current local ONNX construction does not need
  GPU/TPU or notebook internet.
- Known leakage risks: do not submit memorized public outputs as a strategy;
  evaluation includes private benchmark examples.
