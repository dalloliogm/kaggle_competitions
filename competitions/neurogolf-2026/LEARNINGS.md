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
- Generated submissions and downloaded reference kernel outputs are local
  artifacts only; keep them ignored unless a small metadata manifest is worth
  preserving.

## Leaderboard Notes

- First local color-map anchor submission `54528731` completed with public score
  `81.57`. This proves the zip/mechanics path works, but it is not
  final-worthy.
- Existing account submissions shown by Kaggle include a much stronger public
  score `7267.32` for submission `54487100`, so future work should improve from
  that baseline rather than the four-task color-map package.
- A conservative seven-task graft from public kernel `ryosuke-7266-48` scored
  `7267.19` as submission `54529022`, even though it was smaller and passed
  provided examples. Public-kernel ONNX replacements must be isolated before
  adoption; provided examples are not enough to prove hidden correctness.
- Follow-up split tests from the same public source also failed to beat the
  account baseline: five-task lower-risk `54529420` scored `7267.27`, A3
  `54529552` scored `7267.29`, and B2 `54529559` scored `7267.29`. The
  `ryosuke-7266-48` smaller ONNX files are not a useful direct graft path at
  the group level.
- A single-task `task074` byte-reduction probe from Frank's public `7245.63`
  artifact scored only `7267.24` as submission `54619246`, despite passing all
  267 provided examples. This reinforces that local public-example validation
  does not prove hidden correctness.
- The newer public notebook `poby7722/7268-neurogolf-best-score`, downloaded on
  `2026-07-12`, scored `7268.00` as submission `54619344` and is the current
  best account submission observed in this workspace. Checking current public
  notebooks can be higher leverage than continuing older graft families.
- Rolling back the six tasks where Poby's ONNX files were larger than the old
  `7267.32` baseline reduced uncompressed bytes by `9820`, but scored only
  `7267.90` as submission `54638892`. Larger files can encode hidden-value
  fixes; size-only rollback is not reliable.
- The public notebook `lucifer19/neurogolf-agi-circuit-forge`, downloaded on
  `2026-07-13`, scored `7269.60` as submission `54645666` and is the current
  best account submission observed in this workspace. The notebook audit claims
  it starts from a `7269.56` anchor and applies exact rewrites to `task205` and
  `task368`.
- A local six-task graft from Kaiwalya onto Lucifer Circuit Forge scored
  `7269.61` as submission `54646591`, improving Lucifer by `+0.01`. The grafted
  tasks were `task018`, `task090`, `task105`, `task133`, `task174`, and
  `task355`; `task205` was deliberately left as Lucifer's version because
  Lucifer's audit reports a stronger scorer-cost rewrite for that task.
- Downloaded public leaderboard snapshot
  `neurogolf-2026-publicleaderboard-2026-07-13T12:52:33.csv` showed
  `7269.61` at rank `523` out of `3017` teams. The top 10% cutoff was
  `7373.05`, so the medal gap was roughly `+103.44` public LB points at that
  snapshot; small byte-graft improvements are not a realistic medal path by
  themselves.
- Anas explicit rewrites do not transfer to the current Lucifer/Kaiwalya base:
  the three-task `task054/task101/task396` graft scored `7269.59` as
  submission `54647024`, and isolated `task054` also scored `7269.59` as
  submission `54647140`.
- Late Jonathan workbench outputs were not stronger bases. The latest
  `jonathanncoletti/neurogolf-merged91-workbench` log reported
  `base_local_score=7266.56`; the two named grafts from the `7242` explanation
  notebook, `task197` and `task264`, scored only `7269.54` when grafted onto
  the current best as submission `54647351`.
- Consensus among lower-scoring public notebooks is negative evidence unless
  paired with exact proof on the current base. Several smaller variants shared
  by many public sources are precisely the variants replaced by the stronger
  Lucifer/Kaiwalya line.
- Building a current-base exact rewrite scanner was productive. The first pass
  removed stale `value_info` entries that inflated the official-style memory
  cost without changing computation. Accepted tasks were `task085`, `task105`,
  `task237`, `task355`, `task370`, and `task396`, with local cost delta `-192`
  and estimated point delta `+0.134907`.
- Exact rewrite pass v1 scored `7269.74` as submission `54652438`, improving
  the previous best `54646591` by `+0.13`. This validates direct scorer-aware
  cleanup on the current base as a better path than lower-score public grafts.
