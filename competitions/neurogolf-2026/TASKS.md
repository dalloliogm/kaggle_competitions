# Tasks

## Current Goal

- Produce a valid first `submission.zip` quickly, then expand solved task
  coverage before the Kaggle-reported deadline of `2026-07-15 23:59:00`.

## Next Experiments

- Submit the validated color-map package manually if we want an immediate
  leaderboard anchor.
- Add more low-risk ONNX builders for same-shape tasks: pure color swaps,
  single-pixel/local-neighborhood rules, masks, and simple geometric flips.
- Investigate task001-style Kronecker expansion and other repeated-pattern
  transforms with fixed ONNX reshape/matmul/gather graphs.
- Search public NeuroGolf notebooks/discussions for accepted ONNX construction
  patterns and current leaderboard tactics before deeper implementation.
- Isolate candidate public-kernel grafts one task or small group at a time
  before replacing the existing `7267.32` account baseline.
- Move on from the `ryosuke-7266-48` smaller-file graft family unless there is
  a reason to spend single-task submissions; all tested groups scored below the
  existing account best.
- If submitting, immediately inspect Kaggle's accepted/rejected message and
  record the exact result here.

## Done

- Initialized `competitions/neurogolf-2026/` from the Kaggle URL.
- Downloaded and unpacked the official task JSONs and `neurogolf_utils.py`.
- Verified via Kaggle CLI that the account has entered the competition
  (`userHasEntered=True`).
- Built `submissions/color-map-baseline/submission.zip` with four validated
  ONNX files at archive root: `task016.onnx`, `task276.onnx`, `task309.onnx`,
  and `task337.onnx`.
- Created and locally executed the tutorial notebook
  `notebooks/neurogolf-2026-competition-tutorial.ipynb`; it builds and validates
  the same four-task ONNX baseline and writes a reviewable `submission.zip`.
- Uploaded the tutorial notebook to Kaggle as private kernel version 1:
  https://www.kaggle.com/code/dalloliogm/neurogolf-2026-first-onnx-submission-tutorial
- Version 1 failed on Kaggle because the offline notebook image has `onnx` but
  not `onnxruntime`; patched the notebook to validate color-map rules directly
  while still generating the same ONNX files. Uploaded corrected version 2.
- Submitted `submissions/color-map-baseline/submission.zip` to Kaggle with
  message `color-map baseline: 4 validated ONNX tasks`. Kaggle submission ref:
  `54528731`; upload accepted on `2026-07-10 13:24:51.423000`; final status
  `SubmissionStatus.COMPLETE`; public score `81.57`.
- Pulled the account's stronger Kaggle kernel output and public reference
  outputs for comparison. Built
  `submissions/own7267-plus-ryosuke-7/submission.zip` by starting from the
  account `7267.32` artifact and replacing seven smaller ONNX files from the
  close public `ryosuke-7266-48` output: `task005`, `task008`, `task107`,
  `task233`, `task310`, `task366`, and `task370`.
- Locally validated those seven replacements against all official-valid
  provided examples using the helper's 30x30 one-hot semantics. Submitted the
  candidate as Kaggle ref `54529022`; final status `SubmissionStatus.COMPLETE`;
  public score `7267.19`, below the existing account best `7267.32`.
- Submitted isolated lower-risk splits from the same `ryosuke-7266-48` source:
  five-task `task005/task008/task107/task310/task370` graft `54529420` scored
  `7267.27`; A3 split `task005/task008/task107` graft `54529552` scored
  `7267.29`; B2 split `task310/task370` graft `54529559` scored `7267.29`.
  None beats the account best `7267.32`.

## Questions

- Is Kaggle's displayed deadline timezone UTC? The CLI reports
  `2026-07-15 23:59:00` without an explicit timezone.
- Existing account submissions still show a much stronger public score
  (`7267.32` from submission `54487100`), so the four-task color-map package
  and the tested `ryosuke-7266-48` grafts should not be selected as final
  submissions.
