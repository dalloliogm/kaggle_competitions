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
- Expanded exact rewrites found another cumulative local gain of
  `+0.054862` from `task206`, `task208`, `task222`, and `task243`. The final
  candidate differs from scored v1 on exactly those four files, has SHA-256
  `5a6cffc666895ac0cd79922fcd31db0e11cf1d0fa2fed3d115b27aa6f062c866`,
  and passed the 400-model ONNX checker and archive audit.
- Exact rewrite pass v3 scored `7269.80` as submission `54654005`, improving
  v1 by `+0.06`. The displayed movement closely matches the local estimate of
  `+0.054862`, providing a second live validation of the local scorer.
- `task222` supplies most of that candidate gain: exact global Concat/Cast
  fusion reduces scorer cost `2725 -> 2605`, worth `+0.045036` locally.
  `task243` yielded a smaller exact algebraic gain: two bitwise absorption
  rewrites reduce cost `10706 -> 10690`, worth `+0.001496`.
- The 63-node Frank `task243` model is raw-output identical to the current
  bitwise circuit on all 265 available examples and 16 arbitrary random grids,
  but scores much worse locally (`22650` vs `10690`). The metric rewards
  parameters plus tensor memory, not serialized bytes or node count.
- Other compact public variants fail the same cost test. Hoang `task286` costs
  `+77`; Poby and Ryosuke `task366` cost about `+2272`; Poby `task090`,
  `task165`, and `task368` are also neutral or worse. Do not graft these exact
  alternatives merely because their files are smaller.
- Leaderboard deconvolution is underdetermined at the available submission
  count: its in-sample RMSE is `0.00139`, but leave-one-out RMSE is `0.05711`
  across 107 variant features and only two exact single-task constraints. Use
  its ranking to choose audits, never as proof of a positive task contribution.
- Local official-style scoring cannot currently evaluate models with negative
  Conv/MaxPool padding (`task018` and `task240`) because installed ONNX shape
  inference rejects those attributes. Functional equivalence alone is not a
  sufficient reason to replace them.
- A `2026-07-13T16:52:28` leaderboard refresh puts the v3 score `7269.80` at
  rank `540` of `3021`. The rank-302 top-10% cutoff is `7373.94`, leaving a
  `104.14` point gap. Isolated sub-point rewrites cannot reach medals.
- A broader public refresh found no newer leading artifact after Lucifer's
  compression core. Biohack contributed 43 differing task variants and the
  task-level release contributed 76 unseen variants, but direct audits found
  zero scorer-positive validated replacements. ChatGPTLoop was entirely a
  recombination of variants already present in the local public archive.
- Across 378 shape-inference-compatible v3 tasks, static intermediate memory is
  about `891462` bytes: `218564` float32, `26584` int64, and `160125` bool.
  Universal float16 and int32 narrowing has a theoretical local ceiling near
  `+53.69`, but most int64 tensors are required by ArgMax/TopK/Gather/Scatter
  schemas and many float paths touch required float32 input/output tensors.
- Deeper associative/commutative CSE and generalized absorption found no new
  bitwise reductions. The remaining credible branch is task-level algorithm
  resynthesis, beginning with the highest-cost scoreable graphs: `task233`
  (`32011`), `task366` (`27887`), `task286` (`26909`), `task054` (`24717`),
  and `task133` (`21135`).
- Cross-task runtime sharing does not reduce the metric: each task ONNX is
  loaded and charged independently for its own parameters and intermediate
  memory. V3 has four byte-identical pairs and nine structural families
  covering 28 tasks, but the repeated families are already one-node models.
  The useful cross-task leverage is a shared typed DSL/compiler that applies a
  discovered primitive or architecture rewrite separately to every matching
  task, not a universal multi-task ONNX or shared external-weight file.
- The first all-task semantic/ONNX inventory found 58 repeated coarse
  signatures, but manual inspection exposed false groupings: for example,
  `task184` and `task233` both crop/recompose yet solve unrelated problems.
  Family features are an audit queue, not proof of a reusable algorithm.
- `task243` is a seeded flood fill: color 1 spreads through the 4-connected
  component of cells colored 0 or 1, and reached zeros become 1. The current
  graph packs each of the first 18 rows into a `uint32` mask and unrolls
  neighborhood propagation.
- A one-direction row closure has an exact carry form:
  `seed | (free & ((free + seed) xor free))`. Replacing 136 two-step,
  six-node expansions with this four-node form reduces `task243` scorer cost
  from `10690` to `9602`, worth a projected `+0.107337` points.
- The carry rewrite is exact on all 265 provided examples and 10,000 ordinary
  random grids. In 10,000 deliberately dense mazes it never painted an
  unreachable cell; six cases retained 27 reachable zero cells. This is a
  semantic improvement over the scored graph, not arbitrary approximation:
  the replacement only expands through the same free-row mask, so any hidden
  case already solved by the base remains solved.
- More aggressive `task243` pass pruning is not safe. Stopping after pass 5
  saves `1032` cost before carry substitution and passes all provided examples,
  but fails dense-connectivity cases much more often. Keep the full propagation
  graph and use only the carry substitution.
- The validated standalone `task243` candidate is
  `submissions/task243-carry-v2-validated/submission.zip`, SHA-256
  `790dd11eade66211e3e44b49dbbcc981604d5116b68f944039ba8c91ab7ac033`.
  It was later stacked into scored submission `54661951`.
- Discussion `704942` contains one high-value validation tactic: use the public
  ARC-GEN task generators to produce fresh examples instead of testing semantic
  variants on arbitrary random grids. Google publishes the exact generators at
  `google/ARC-GEN`, and NeuroGolf uses ARC-GEN as its official benchmark
  generator.
- Fresh generator validation overturned the earlier arbitrary-grid rejection of
  compact v9 variants. Seventeen top variants passed all 1,024 new ARC-GEN
  examples per task: `task033`, `task045`, `task052`, `task058`, `task060`,
  `task078`, `task099`, `task114`, `task132`, `task163`, `task225`, `task240`,
  `task257`, `task287`, `task293`, `task296`, and `task332`.
- The same fresh generator gate caught rare failures that the released examples
  missed: v9 `task188` passed 126/128, `task161` passed 126/128, and `task079`
  passed 127/128. Exclude all three from conservative grafts.
- The 15 locally scoreable accepted v9 replacements project `+25.813616` over
  scored v3. `task045` and `task240` also passed 1,024 fresh cases, but their
  delta remains locally unresolved because the old negative-padding models
  fail current ONNX full shape inference.
- The conservative bundle is available at
  `submissions/v9-fresh-gen-graft-v1/submission.zip`, SHA-256
  `fba281ad3d9a5719834467a4c6b23a99575127b8d487ed14be745107ca0a8950`.
  It has 400 canonical root models, a clean CRC, and passes the standard ONNX
  checker. Do not conflate this technical validation with a compliance ruling:
  late public model sharing remains disputed in the forum and no explicit host
  ruling was observed.
- The 17-task bundle scored `7299.68` as submission `54660934`, improving v3 by
  `+29.88`. This exceeds the 15-task measurable projection by about `+4.07`,
  consistent with additional gains from fresh-validated `task045` and
  `task240`. Fresh ARC-GEN validation is now a proven source-selection gate for
  this competition, although the live leaderboard remains authoritative.
- Ranking the rest of public v9 against the scored `7299.68` bundle found 53
  additional locally cost-positive variants after the first three known
  failures, plus nine base models that local shape inference could not score.
- A 128-case fresh ARC-GEN screen rejected `task018`, `task118`, `task157`,
  `task158`, `task251`, `task255`, and `task355`. An additional 896 independent
  cases rejected three rarer failures: `task246`, `task377`, and `task382`.
- The final second-wave set contains 52 variants that each passed 1,024 fresh
  generated cases. Forty-six have a measurable combined projection of
  `+20.702662`; the six locally unscorable survivors are `task046`, `task162`,
  `task200`, `task235`, `task266`, and `task364`.
- The second-wave bundle is
  `submissions/v9-fresh-gen-graft-v2/submission.zip`, SHA-256
  `62ec43744d8ecea00a2db70c1cf9efaba1198c4b655df89e7abb28bcdc8032ce`.
  Its measurable local projection was about `7320.38`, before any contribution
  from the six unresolved variants. It has 400 canonical models, clean CRC, and
  passes the standard ONNX checker.
- The second-wave bundle scored `7319.89` as submission `54661618`, a live gain
  of `+20.21` over `7299.68`. The result was only about `0.49` below the
  measurable local projection, providing a third strong validation of the
  scorer-plus-fresh-generator workflow while preserving the live leaderboard
  as the final authority.
- Deduplicating 21 older public archives against `7319.89` exposed 699 unique
  task variants but only seven local cost improvements. Fresh ARC-GEN rejected
  the largest apparent gain (`task191`, 127/128) and `task233` (126/128), while
  `task044`, `task046`, `task200`, `task364`, and `task382` each passed
  1,024/1,024 across two independent seed blocks.
- Equal scorer cost is not evidence of equal correctness. Across 23 equal-cost
  task alternatives, none improved the base control and `task193` regressed
  from 128/128 to 124/128. Do not graft cost-neutral public variants without a
  demonstrated correctness advantage.
- On matched fresh `task243` cases, the carry rewrite's failures `[11, 964]`
  were a strict subset of the scored base failures `[11, 910, 964]`. This is
  empirical confirmation of the monotone-reachability argument, not merely an
  absolute pass-rate comparison.
- The final six-task archive is
  `submissions/cross-source-five-task243-final/submission.zip`, SHA-256
  `f8f03cb1b0d13ac787d0875d638ee20b00957ffd86b560104de2ad85f37d9537`.
  Its five public variants projected `+0.014643` and `task243` projected
  `+0.107337`; Kaggle submission `54661951` scored `7320.02`, a live `+0.13`
  over `7319.89` and close to the combined `+0.121980` local estimate.
- The public Ryosuke `7281.18` archive exposed 74 cost-positive variants against
  the much stronger `7320.02` combined base. Their gains summed to `+9.884902`,
  showing that a lower-scoring full bundle can still contain many orthogonal
  improvements after a newer source family is released.
- Every one of the 74 Ryosuke variants passed both the 128-request screen and
  the independent 896-request stress block. Across 75,763 generated in-bounds
  examples there were no incorrect outputs; only 13 oversized `task055`
  examples were outside the fixed 30x30 conversion and skipped.
- Kaggle submission `54673405` scored `7329.90`, exactly matching the displayed
  precision of the `7329.904902` projection. This confirms that scorer-positive
  task grafting is highly reliable when every replacement also passes fresh
  task-domain generation.
- The 2026-07-14 Auto-Golfer notebook is not a viable donor package: its output
  contains 262 dynamic PyTorch fallback models trained on released examples,
  not 400 canonical static models, and the official-style memory scorer cannot
  measure them. Do not spend a submission slot on that artifact.
- Re-running the exact scorer rewrite toolchain on the Ryosuke-enhanced base
  found 12 additional safe reductions totaling 114 cost units and a projected
  `+0.067639`. Every changed task passed 1,024/1,024 fresh ARC-GEN examples.
- Kaggle submission `54673593` scored `7329.97`, a displayed `+0.07` over the
  Ryosuke package and another close match to the local scorer projection.
- The Udit22 targeted collection contained 11 cost-positive candidates against
  `7329.97`, but fresh ARC-GEN caught hidden-risk behavior in `task205`
  (126/128) and `task233` (124/128). The nine remaining tasks passed every one
  of 8,828 generated in-bounds examples across independent seed blocks.
- Kaggle submission `54673781` scored `7330.16`, exactly matching the displayed
  precision of its `7330.160293` projection. Targeted donor directories are a
  useful source format, but only after each named task is rescored against the
  current base and independently fresh-validated.
