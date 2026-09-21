# Neurogolf 2026

## Links

- Competition: https://www.kaggle.com/competitions/neurogolf-2026
- Kaggle workspace slug: `neurogolf-2026`
- Kaggle CLI slug: `neurogolf-2026`

## Objective

Build ONNX-formatted neural networks for ARC-AGI public training v1 tasks. Each
submitted network should reproduce a task transformation while minimizing size
and parameter count.

## Evaluation

- Metric: For each functionally correct task network, Kaggle awards
  `max(1, 25 - ln(cost))`, where `cost = parameters + memory footprint bytes`.
- Functional correctness: checked against the original ARC-AGI examples and a
  private benchmark suite intended to discourage overfitting.
- Validation approach: use the official `neurogolf_utils.py` conversion and
  ONNXRuntime execution locally; only include task networks that pass train,
  test, and `arc-gen` examples.
- Public/private leaderboard notes: missing task files are allowed by the
  submission schema; only correct submitted task networks earn points.

## Data

- Kaggle input path: `/kaggle/input/neurogolf-2026/`
- Local data path: `competitions/neurogolf-2026/data/`
- Key files: `task001.json` through `task400.json` plus
  `neurogolf_utils/neurogolf_utils.py`.

## Submission

- Expected file: `submission.zip`
- Required contents: at most one ONNX file per task, named
  `task001.onnx` through `task400.onnx`, placed at the archive root.
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: allowed if publicly available/equally accessible at no cost or
  otherwise reasonable under the rules.
- Internet: not yet checked for Kaggle notebook execution; local work does not
  require notebook internet.
- GPU/TPU: not required for the current ONNX construction baseline.
- Team/merge rules: maximum team size 5; team mergers allowed subject to the
  submission-count rule in the official rules.
- Submission limits: 5 submissions per day; up to 2 final submissions.
- Live Kaggle CLI check on 2026-07-10: `userHasEntered=True`, team count 2966,
  deadline reported as `2026-07-15 23:59:00`.

## Current Baseline

- Local validation: color-map baseline generates four ONNX files that pass all
  available train/test/arc-gen examples for `task016`, `task276`, `task309`,
  and `task337`.
- Public LB: not submitted.
- Script: `scripts/build_color_map_submission.py`
- Manual package: `submissions/color-map-baseline/submission.zip`
