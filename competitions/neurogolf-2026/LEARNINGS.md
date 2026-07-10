# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Official data contains 400 JSON task files plus the Kaggle helper
  `neurogolf_utils.py`.
- Each task file has `train`, `test`, and `arc-gen` example groups. The
  `arc-gen` group is large and useful for rejecting overfit task logic before
  submitting.
- Local data is unpacked under `competitions/neurogolf-2026/data/`.

## Target And Metric

- Target artifact is one ONNX model per solved task, not `submission.csv`.
- Scoring is per correct network: `max(1, 25 - ln(parameters + memory bytes))`.
- Smaller networks matter, but correctness is the gating condition.

## Validation

- Use official conversion semantics from `neurogolf_utils.py`: inputs and
  outputs are one-hot tensors of shape `[1, 10, 30, 30]`; cells outside the ARC
  grid remain all-zero.
- A local candidate should pass every available train/test/arc-gen example
  before inclusion in `submission.zip`.
- The color-map baseline was validated with ONNXRuntime using disabled graph
  optimization, matching the helper's execution mode.

## Leakage And Rules

- Do not rely on memorized public test outputs: the official evaluation includes
  a private benchmark suite.
- Winner code must be deliverable and Apache-2.0-compatible; keep builders
  reproducible.
- Kaggle CLI reported `userHasEntered=True` on 2026-07-10.

## Features

- A quick full-task scan found 262 same-shape tasks, 52 same-shape tasks with
  preserved nonzero masks, and 4 pure color-map tasks across train/test/arc-gen.

## Models

- Pure color maps can be represented as 1x1 convolution networks using
  `neurogolf_utils.single_layer_conv2d_network`.
- Four pure color-map networks are currently generated: `task016`, `task276`,
  `task309`, and `task337`.

## Ensembling And Submission Behavior

- Submission zip may contain at most one ONNX file per task. Missing tasks are
  acceptable by schema; they simply do not earn points.
- Current manual package is
  `submissions/color-map-baseline/submission.zip` and contains four root-level
  ONNX files.

## Leaderboard Notes

- First local color-map anchor submission `54528731` completed with public score
  `81.57`. This proves the zip/mechanics path works, but it is not
  final-worthy.
- Existing account submissions shown by Kaggle include a much stronger public
  score `7267.32` for submission `54487100`, so future work should improve from
  that baseline rather than the four-task color-map package.
