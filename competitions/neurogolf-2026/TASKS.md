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
- Use Kaggle's recent public notebook list before further grafting; newer
  public artifacts can supersede older local/public sources quickly near the
  deadline.
- Do not roll back Poby's six larger task files as a group; the grouped
  rollback lost public score despite reducing artifact size.
- Current best source is now `exact-rewrite-pass-v1`: the
  `lucifer-plus-kaiwalya-six-no205` graft plus exact stale-value-info cleanup
  on `task085`, `task105`, `task237`, `task355`, `task370`, and `task396`.
- Current best source is now
  `submissions/v9-fresh-gen-graft-v1/submission.zip`. It grafts 17 public v9
  variants that each passed 1,024 fresh ARC-GEN examples onto scored v3 and
  scored `7299.68` as submission `54660934`.
- Do not graft Anas `task054` onto the current best; both the isolated
  `task054` probe and the three-task Anas explicit bundle scored `7269.59`.
- Do not graft Jonathan's explicit `task197`/`task264` pair onto the current
  best; it scored `7269.54`.
- Public notebook byte-smaller consensus is not enough evidence. The live
  leaderboard repeatedly penalized smaller variants from lower-scoring bases.
- Current medal gap is large: downloaded public leaderboard snapshot from
  `2026-07-13T16:52:28` puts v3 `7269.80` at rank `540/3021`; the top-10%
  cutoff is `7373.94`, a gap of `+104.14`.
- Stop broad public recombination unless a genuinely newer top artifact
  appears. Biohack's 43 differences and the task-level release's 76 unseen
  variants yielded no scorer-positive validated replacement; ChatGPTLoop had
  no unseen task variant.
- Start a typed ARC-to-ONNX resynthesis branch. First targets by current scorer
  cost are `task233`, `task366`, `task286`, `task054`, and `task133`; require
  exact agreement across all available examples before building a candidate.
- Keep the validated `task243` carry rewrite in the current best package. On a
  matched 1,024-case fresh control it reduced the scored base's failure set
  from three cases to two without adding a failure.
- Fresh-generate and audit the remaining v9 cost-positive variants, then graft
  only models that survive the same task-domain gate onto scored `54660934`.
- Use `submissions/ryosuke-7281-positive-screen/submission.zip` as the current
  scored donor base. It scored `7329.90` as submission `54673405` after adding
  74 fresh-validated Ryosuke `7281.18` task variants to the `7320.02` package.
- Use `submissions/exact-rewrite-7329-v1/submission.zip` as the current scored
  exact-rewrite base. Twelve exact rewrites added `+0.07`, scoring `7329.97`
  as submission `54673593`; the live change matched the `+0.067639` local
  projection.
- Use `submissions/udit22-nine-stress/submission.zip` as the current scored
  base. Its nine fresh-validated targeted grafts scored `7330.16` as submission
  `54673781`, matching the `7330.160293` projection at displayed precision.
- If submitting, immediately inspect Kaggle's accepted/rejected message and
  record the exact result here.
- Current completed best is `submissions/exact-rewrite-7359-v1/submission.zip`,
  Kaggle ref `54722313`, public LB `7359.71`.
- Submission `54723158`
  (`submissions/exact-7359-plus-chimera-173-219-366/submission.zip`) errored
  before scoring despite local checks. Treat `task366` as the most likely
  rollback suspect from that package until isolated.
- Submission `54724599`
  `submissions/exact-7359-plus-chimera-173-219/submission.zip`, a Chimera donor
  graft for `task173` and `task219` only on the `7359.71` base, errored before
  scoring despite passing local checks.
- Submission `54726396` is
  `submissions/exact-7359-plus-chimera-173/submission.zip`, an isolated
  Chimera donor graft for `task173` only on the `7359.71` base; it errored
  before scoring despite all local checks.
- Current completed best is
  `submissions/hail-mary-late-public-top-scorepositive-no-known-processor-fails/submission.zip`,
  Kaggle ref `54740683`, public LB `7369.55`.
- Current completed best is
  `submissions/final-7372-51-plus-task162-364/submission.zip`, Kaggle ref
  `54741759`, public LB `7373.00`. It stacks the eight released-example-exact
  negative-padding substitutions (`task046`, `task064`, `task089`, `task091`,
  `task200`, `task249`, `task263`, `task368`) with independently positive
  `task118`, `task135`, `task162`, and `task364` probes.
- The final mixed-precision sweep scanned all 400 tasks with conservative and
  aggressive float16 conversion under disabled ONNX Runtime optimization and
  accepted zero score-positive models. Do not repeat this conversion unchanged.
- Pending submission `54739665` is
  `submissions/exact-rewrite-7360-52-v1/submission.zip`, an exact `task191`
  cleanup on the `7360.52` base. It reduced `task191` local scorer cost
  `10811 -> 10794`, projected `+0.0016`, and passed zip CRC/root layout,
  400/400 ONNX checker, and 400/400 official `check_network`.
- Submission `54739851` is
  `submissions/exact-7360-52-plus-chimera-task285/submission.zip`, an isolated
  Chimera `task285` runtime-risk scorer probe on the `7360.52` base. It
  errored before scoring: Kaggle reported invalid ONNX processing for
  `task285`. The local archive had reduced scorer cost `18674 -> 16450`,
  projected `+0.1268`, and passed zip CRC/root layout, 400/400 ONNX checker,
  and 400/400 official `check_network`. Matched fresh 1,024-case control
  against the exact `7360.52` base: 1,015 both-correct, 7 both-wrong-same,
  0 base-only, 0 donor-only, 0 donor-only runtime, 2 both-runtime;
  classification `runtime-or-empty`.
- Reranked late public outputs downloaded on `2026-07-15` from NCT, JackGong,
  and Roman against the `7360.52` base:
  `references/analysis/cross-source-rankings/2026-07-15-late-vs-7360-52-cross-source-vs-base.csv`.
  Most cost-positive tasks were already known bad. JackGong `task366` projected
  `+3.4335` but failed matched fresh validation catastrophically: 962
  base-only vs 0 donor-only over 972 generated cases, so do not submit it.
- Submission `54740200` is
  `submissions/exact-7360-52-plus-jackgong-base-unscorable-171-354/submission.zip`,
  a JackGong replacement for base-unscorable negative-padding tasks `task171`
  and `task354`. Local score impact is unknown because the base graphs are not
  locally shape-inference-scoreable, but the donor graphs are locally scoreable.
  Fresh matched stress: both tasks were 4,096/4,096 no-regression against the
  exact `7360.52` base. Archive passed zip CRC/root layout, 400/400 ONNX
  checker, and 400/400 official `check_network`. It completed at public LB
  `7360.64`, a live `+0.12` improvement.
- Submission `54740339` is
  `submissions/exact-7360-52-plus-jackgong-both-unscorable-018-127-174/submission.zip`,
  a JackGong no-regression probe for both-unscorable tasks `task018`,
  `task127`, and `task174`. It passed 4,096 fresh generated cases per task
  with zero base-only or donor-only differences. `task005` was tested and
  rejected: 5 base-only regressions over 1,024 examples. It completed at public
  LB `7360.27`, below the `7360.52` base, so do not use these tasks as a group.
- Submission `54740366` is
  `submissions/exact-7360-52-plus-jackgong-unscorable-clean5/submission.zip`,
  the stacked JackGong clean unscorable probe for `task018`, `task127`,
  `task171`, `task174`, and `task354`. It completed at public LB `7360.39`,
  below the `7360.64` `task171`/`task354` pair.
- Submission `54740397` is
  `submissions/exact-7360-52-plus-jackgong-shrink-clean-127-171/submission.zip`,
  a shrink-only no-regression probe for `task127` and `task171`. It completed
  at public LB `7360.39`, below the `7360.52` base.
- Submissions `54740511` and `54740513` isolated JackGong `task171` and
  `task354`, respectively. They completed at public LB `7360.57` and
  `7360.59`, while the pair `54740200` remains better at `7360.64`.
- Submission `54740487`, the full NCT public artifact discovery shot,
  completed at public LB `7302.22`; it is not a stronger base.
- Submission `54740683` is a high-risk late public Hail Mary bundle on the
  `7360.64` base. It grafts top local score-positive public variants while
  excluding known Kaggle-processing failures `task308`, `task316`, `task361`,
  `task397`, Chimera `task285`, and fresh-catastrophic JackGong `task366`.
  Local scorer-only projection is `+8.9094`; archive validation passed zip
  CRC/root layout, 400/400 ONNX checker, and 400/400 official `check_network`.
  It completed at public LB `7369.55`, a live `+8.91` gain over `54740200`.
- Exact rewrite scan on the `7369.55` base produced no accepted changes:
  `submissions/exact-rewrite-7369-55-v1/rewrite_report.csv`,
  `accepted_count=0`.
- Reranked late public sources against the `7369.55` base:
  `references/analysis/cross-source-rankings/2026-07-15-late-vs-7369-55-cross-source-vs-base.csv`.
  Only `task316` and `task366` remain cost-positive. `task316` belongs to the
  known Kaggle-processing-failure family from the 2026-07-14 refresh, and
  JackGong `task366` already failed fresh validation catastrophically, so there
  is no clean remaining late-public graft.
- Submission `54739101` is
  `submissions/exact-7359-97-plus-lockbox-task157-risk-probe/submission.zip`,
  a risky lockbox `task157` probe on the `7359.97` base. It scored
  `7360.49`, a live `+0.52` improvement.
- Exact rewrite scan on the `7360.49` base produced no accepted changes:
  `submissions/exact-rewrite-7360-49-v1/rewrite_report.csv`, `accepted_count=0`.
- Reranked refreshed public sources against the `7360.49` base:
  `references/analysis/cross-source-rankings/2026-07-15-vs-7360-49-cross-source-vs-base.csv`.
- Submission `54739406` is
  `submissions/exact-7360-49-plus-lockbox-task191/submission.zip`, a lockbox
  `task191` no-regression micro-graft on the `7360.49` base. It scored
  `7360.52`, a live `+0.03` improvement. It passed zip CRC/root layout,
  400/400 ONNX checker, and 400/400 official `check_network`. Matched fresh
  1,024-case control: 1,013 both-correct, 11 both-wrong-same, 0 base-only,
  0 donor-only, 0 runtime; projected scorer gain `+0.0248`.
- Exact rewrite scan on the `7359.97` base produced no accepted changes:
  `submissions/exact-rewrite-7359-97-v1/rewrite_report.csv`, `accepted_count=0`.
- Reranked refreshed public sources against the `7359.97` base:
  `references/analysis/cross-source-rankings/2026-07-15-vs-7359-97-cross-source-vs-base.csv`.
- Submission `54739101` is
  `submissions/exact-7359-97-plus-lockbox-task157-risk-probe/submission.zip`, a
  risky lockbox `task157` probe on the `7359.97` base. It scored `7360.49`,
  a live `+0.52` improvement. It passed zip
  CRC/root layout, 400/400 ONNX checker, and 400/400 official `check_network`.
  Two independent 256-case matched fresh blocks each showed 243 both-correct,
  11 donor-only, 0 base-only, 1 both-wrong-diff, and 1 base-runtime/0
  donor-runtime; projected scorer gain `+0.5237`.
- Exact rewrite scan on the `7359.74` base produced no accepted changes:
  `submissions/exact-rewrite-7359-74-v1/rewrite_report.csv`, `accepted_count=0`.
- Submission `54726909` is
  `submissions/exact-7359-plus-chimera-219/submission.zip`, an isolated
  Chimera donor graft for `task219` only on the `7359.71` base. It scored
  `7359.74`, matching the small projected gain at displayed precision.
- Reranked refreshed public sources against the `7359.74` base:
  `references/analysis/cross-source-rankings/2026-07-15-vs-7359-74-cross-source-vs-base.csv`.
- Submission `54738494` is
  `submissions/exact-7359-74-plus-lockbox-task255-risk-probe/submission.zip`, a
  risky lockbox `task255` probe on the `7359.74` base. It scored `7359.97`,
  a live `+0.23` improvement. It passed zip
  CRC/root layout, 400/400 ONNX checker, and 400/400 official `check_network`.
  Matched fresh stress over 4,096 cases: 3,731 both-correct, 100 donor-only,
  88 base-only, 160 both-wrong-same, 17 both-wrong-diff, net `+12`; projected
  scorer gain `+0.2311`.
- Do not stack lockbox `task095`, `task382`, `task050`, `task246`, or
  `task277`; each looked clean at 128 examples but showed base-only
  regressions in the 1,024-case matched fresh screen.

## Done

- Submitted isolated Chimera `task219` as Kaggle ref `54726909`; it completed
  at public LB `7359.74`.
- Ran exact rewrite scan on the `7359.74` base; no candidate archive was
  produced because there were zero accepted rewrites.
- Submitted risky lockbox `task255` probe as Kaggle ref `54738494`; it
  completed at public LB `7359.97`.
- Ran exact rewrite scan on the `7359.97` base; no candidate archive was
  produced because there were zero accepted rewrites.
- Submitted risky lockbox `task157` probe as Kaggle ref `54739101`; it
  completed at public LB `7360.49`.
- Ran exact rewrite scan on the `7360.49` base; no candidate archive was
  produced because there were zero accepted rewrites.
- Submitted lockbox `task191` no-regression micro-graft as Kaggle ref
  `54739406`; it completed at public LB `7360.52`.
- Submitted exact `task191` cleanup on the `7360.52` base as Kaggle ref
  `54739665`; it completed at public LB `7360.52`, no displayed improvement.
- Submitted isolated Chimera `task285` scorer probe on the `7360.52` base as
  Kaggle ref `54739851`; it errored before scoring with invalid ONNX processing
  for `task285`.
- Submitted JackGong base-unscorable `task171`/`task354` no-regression probe
  as Kaggle ref `54740200`; it completed at public LB `7360.64`.
- Submitted JackGong both-unscorable `task018`/`task127`/`task174`
  no-regression probe as Kaggle ref `54740339`; it completed at public LB
  `7360.27`, a regression.
- Submitted stacked JackGong clean unscorable five-task probe as Kaggle ref
  `54740366`; it completed at public LB `7360.39`, a regression versus the
  `task171`/`task354` pair.
- Submitted JackGong shrink-only `task127`/`task171` no-regression probe as
  Kaggle ref `54740397`; it completed at public LB `7360.39`, a regression.
- Submitted isolated JackGong `task171` and `task354` as Kaggle refs `54740511`
  and `54740513`; they completed at public LB `7360.57` and `7360.59`,
  respectively.
- Submitted the full NCT public artifact as Kaggle ref `54740487`; it completed
  at public LB `7302.22`.
- Submitted high-risk late public Hail Mary bundle as Kaggle ref `54740683`;
  it completed at public LB `7369.55`.
- Ran exact rewrite scan on the `7369.55` base; no candidate archive was
  produced because there were zero accepted rewrites.
- Reranked late public sources against the `7369.55` base; only known-bad
  `task316` and `task366` remained cost-positive.
- Submitted isolated Chimera `task173` as Kaggle ref `54726396`; it errored
  before scoring.
- Submitted Chimera no-regression subset `task173`/`task219` as Kaggle ref
  `54724599`; it errored before scoring.
- Submitted Chimera no-regression stack `task173`/`task219`/`task366` as
  Kaggle ref `54723158`; it errored before scoring.
- Exact rewrite `task188` on the `7359.69` base completed as Kaggle ref
  `54722313` with public LB `7359.71`.
- Submitted the nine-task Udit22 survivor package as Kaggle ref `54673781`;
  it completed at `7330.16`, improving the exact-rewrite base by `+0.19`.
- Rejected Udit22 `task205` and `task233` after fresh-generation failures;
  neither model is present in the scored package.
- Submitted the 12-task exact rewrite stack as Kaggle ref `54673593`; it
  completed at `7329.97`, improving the Ryosuke graft by `+0.07`.
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
- Submitted a different single-task probe from Frank's public `7245.63` output:
  `task074` shrank from `8001` to `708` bytes and passed all 267 provided
  examples, but Kaggle ref `54619246` scored `7267.24`, below the account best.
- Downloaded newer public notebook output
  `poby7722/7268-neurogolf-best-score` from Kaggle on `2026-07-12`. Its
  `submission.zip` had 400 root-level ONNX files, `445478` zip bytes,
  `1522819` total uncompressed bytes, and SHA-256
  `be56d01a2a5eaf82af76582105c55dba62885889379ce154ae7264573db93e66`.
  Submitted it as Kaggle ref `54619344`; final status
  `SubmissionStatus.COMPLETE`; public score `7268.00`, now the best account
  submission seen in this workspace.
- Built `submissions/poby7268-rollback-six-larger-tasks/submission.zip` by
  starting from Poby `54619344` and rolling back the six tasks where Poby is
  larger than the old `7267.32` baseline: `task008`, `task035`, `task044`,
  `task074`, `task085`, and `task363`. The candidate was `9820` uncompressed
  bytes smaller than Poby, but Kaggle ref `54638892` scored `7267.90`, below
  Poby's `7268.00`.
- Downloaded newer public notebook output
  `lucifer19/neurogolf-agi-circuit-forge` from Kaggle on `2026-07-13`. Its
  notebook log reported a confirmed anchor public score `7269.56`, accepted
  exact rewrites on `task205` and `task368`, `400/400` ONNX checker pass, and
  SHA-256 `644938043f8b9d729235e66dfeaef7ed586a69ca9cc4c198cb5164f81b3b3ad0`.
  Submitted the emitted `submission.zip` as Kaggle ref `54645666`; final status
  `SubmissionStatus.COMPLETE`; public score `7269.60`, now the best account
  submission seen in this workspace.
- Built
  `submissions/lucifer-plus-kaiwalya-six-no205/submission.zip` by starting from
  Lucifer Circuit Forge and replacing only Kaiwalya tasks `task018`, `task090`,
  `task105`, `task133`, `task174`, and `task355`. The archive has 400 root
  ONNX files, SHA-256
  `e547ca18dfecca166236a0ef86f9ec42d530a0288877a58640c0db538ae63894`, and was
  submitted as Kaggle ref `54646591` on `2026-07-13`; final status
  `SubmissionStatus.COMPLETE`; public score `7269.61`, now the best account
  submission seen in this workspace.
- Submitted an Anas explicit-rewrite graft on top of current best:
  `task054`, `task101`, and `task396`. Kaggle ref `54647024` completed with
  public score `7269.59`, below the current best.
- Submitted the isolated Anas `task054` rewrite on top of current best. Kaggle
  ref `54647140` completed with public score `7269.59`, confirming the Anas
  regression is driven by `task054` and not rescued by `task101`/`task396`.
- Downloaded and audited late Jonathan public workbench outputs. The latest
  `jonathanncoletti/neurogolf-merged91-workbench` artifact reported
  `base_local_score=7266.56`, so it is not a stronger base.
- Submitted the two named Jonathan explicit grafts that differed from current
  best: `task197` and `task264` from
  `jonathanncoletti/neurogolf-7242-task-graft-with-explainations`. Kaggle ref
  `54647351` completed with public score `7269.54`, below the current best.
- Built `scripts/exact_rewrite_toolchain.py`, a local ONNX rewrite scanner that
  profiles the current best bundle, removes conservative no-op graph structure
  or stale scoring metadata, validates candidate outputs against the base on
  local examples, and accepts only official-style cost reductions.
- Ran the exact rewrite pass against all 400 tasks. It accepted stale
  value-info cleanup on `task085`, `task105`, `task237`, `task355`, `task370`,
  and `task396`, with estimated local cost delta `-192` and point delta
  `+0.134907`. Candidate zip SHA-256:
  `a497085e3d462908302ca44e72220b157398d2c49f3c93474380beb7af61a2de`.
- Submitted `submissions/exact-rewrite-pass-v1/submission.zip` to Kaggle as
  ref `54652438`; final status `SubmissionStatus.COMPLETE`; public score
  `7269.74`, now the best account submission seen in this workspace.
- Extended `scripts/exact_rewrite_toolchain.py` with scorer-aware Cast
  pushdown, global Concat/Cast fusion, initializer/node deduplication,
  reshape-chain cleanup, constant identities, commutative CSE, and bitwise
  absorption. Full scans accepted exact improvements on `task206`, `task208`,
  `task222`, and `task243`, reducing cumulative cost by `160` for local point
  delta `+0.054862` over scored v1.
- Built `scripts/leaderboard_variant_deconvolution.py` and fit 13 scored
  archive comparisons. The fit is useful for audit ordering but too
  underdetermined for direct task attribution: leave-one-out RMSE `0.05711`.
- Built `scripts/audit_public_variants.py` and rejected byte-smaller public
  alternatives for `task243`, `task286`, `task366`, `task090`, `task165`, and
  `task368` because their scorer cost was neutral or worse. `task018` and
  `task240` remain held because local ONNX shape inference rejects their
  negative padding.
- Validated `submissions/exact-rewrite-pass-v3-validated/submission.zip`:
  400 root ONNX files, clean zip CRC, 400/400 ONNX checker pass, exactly four
  changed tasks versus scored v1, SHA-256
  `5a6cffc666895ac0cd79922fcd31db0e11cf1d0fa2fed3d115b27aa6f062c866`.
- Submitted exact rewrite pass v3 to Kaggle as ref `54654005`; final status
  `SubmissionStatus.COMPLETE`; public score `7269.80`, improving the prior
  account best by `+0.06` and closely matching the local `+0.054862` estimate.
- Refreshed the current public-kernel list and audited three previously unused
  families. Biohack had 43 differences, the task-level release had 76 unseen
  variants, and ChatGPTLoop had no unseen variants; no candidate passed both
  functional and lower-scorer-cost gates.
- Added stable hashed report names to `scripts/audit_public_variants.py` so
  large multi-task audits do not exceed filesystem filename limits.
- Inventoried dtype memory and checked deeper bitwise equivalences. The broad
  dtype ceiling is materially larger than metadata cleanup but mostly blocked
  by ONNX type constraints; no additional safe bitwise rewrite was found.
- Built `scripts/task_family_inventory.py` and indexed all 400 tasks into 58
  repeated coarse semantic signatures with ONNX cost/operator metadata under
  `references/analysis/task-families-v3/`.
- Built `scripts/task243_floodfill_pruner.py`, identified `task243` as packed
  seeded flood fill, rejected unsafe pass cutoffs, and produced the conservative
  carry-closure candidate. It reduces task cost `10690 -> 9602`, projects
  `+0.107337`, passes all 265 provided examples plus 10,000 ordinary random
  grids, and passed the 400-model archive gate.
- Audited discussion `704942` and recovered the official public ARC-GEN source
  used by NeuroGolf. Added `scripts/validate_arc_gen_fresh.py` so public or local
  task models can be checked against unseen generator seeds.
- Downloaded the public `haonanzhengh/neurogolf-v9-models` archive and audited
  its top 20 scorer-positive variants. Fresh generation rejected `task188`,
  `task161`, and `task079`, while the other 17 passed 1,024/1,024 fresh cases.
- Added `scripts/build_task_graft_bundle.py` and built the conservative 17-task
  v9 graft on scored v3. The archive has 400 canonical root ONNX files, clean
  CRC, 441,213 zip bytes, a largest model of 118,088 bytes, and SHA-256
  `fba281ad3d9a5719834467a4c6b23a99575127b8d487ed14be745107ca0a8950`.
- Submitted the 17-task fresh-ARC-GEN v9 graft as Kaggle ref `54660934`. It
  completed successfully with public score `7299.68`, improving the previous
  best by `+29.88` and becoming the current scored base.
- Added `scripts/rank_bundle_variants.py` and ranked all 400 v9 task models
  against the scored `7299.68` bundle. The second-wave queue contained 53
  locally positive variants plus nine base-unscorable alternatives.
- Screened all 62 second-wave variants on 128 fresh ARC-GEN cases, rejecting
  seven, then ran 896 independent cases for each survivor and rejected
  `task246`, `task377`, and `task382` as rare failures.
- Built `submissions/v9-fresh-gen-graft-v2/submission.zip` from the 52 final
  survivors. It differs from scored v1 on exactly those tasks, has 400
  canonical root models, clean CRC, 433,757 zip bytes, standard ONNX checker
  pass, and SHA-256
  `62ec43744d8ecea00a2db70c1cf9efaba1198c4b655df89e7abb28bcdc8032ce`.
- Submitted the second-wave v9 graft as Kaggle ref `54661618`. It completed
  successfully with public score `7319.89`, improving `54660934` by `+20.21`
  and becoming the scored base for the next audit.
- Added `scripts/rank_cross_source_variants.py` and scored 699 unique task
  variants from 21 canonical public archives against `7319.89`. Seven variants
  were cost-positive; fresh generation rejected `task191` and `task233`.
- Added `scripts/build_ranked_graft_bundle.py`. The surviving `task044`,
  `task046`, `task200`, `task364`, and `task382` variants each passed 128 plus
  896 independent ARC-GEN cases and projected `+0.014643` in total.
- Audited 23 equal-cost task alternatives. None improved fresh correctness;
  `task193` regressed from 128/128 to 124/128, so no neutral variant was kept.
- Stacked the `task243` carry rewrite. On a matched 1,024-example ARC-GEN block,
  the base failed indices `[11, 910, 964]` and carry failed only `[11, 964]`.
- Built and verified
  `submissions/cross-source-five-task243-final/submission.zip`. It changes six
  tasks, has 400 canonical root models, clean CRC, 400/400 standard checker
  pass, full checks on all changed tasks, and SHA-256
  `f8f03cb1b0d13ac787d0875d638ee20b00957ffd86b560104de2ad85f37d9537`.
- Submitted the final six-task package as Kaggle ref `54661951`. It completed
  with public score `7320.02`, improving `54661618` by `+0.13` and closely
  matching the local `+0.121980` projection.
- Refreshed public kernels on 2026-07-14 and downloaded the full Ryosuke
  `7281.18` archive plus the partial Auto-Golfer output. Auto-Golfer contained
  only 262 dynamic fallback models and was rejected as incomplete and locally
  unscorable under the official-style memory metric.
- Ranked Ryosuke `7281.18` against scored `7320.02`. Seventy-four replacements
  were locally cost-positive with combined projection `+9.884902`.
- All 74 replacements passed independent 128- and 896-request ARC-GEN blocks:
  75,763/75,763 generated in-bounds examples correct. Thirteen oversized
  `task055` examples were skipped by the fixed 30x30 competition conversion.
- Built and verified `submissions/ryosuke-7281-positive-screen/submission.zip`:
  400 canonical root models, clean CRC, 400/400 standard checker pass, full
  checks on all 74 changed tasks, and SHA-256
  `7fc66b3cb949ca501077fa4971b60a21ec299291b3e71db5969427f06a3d148a`.
- Submitted the 74-task graft as Kaggle ref `54673405`. It completed with public
  score `7329.90`, improving `54661951` by `+9.88` and matching the local
  `7329.904902` projection at displayed precision.
- Continued from `7329.90` with an exact rewrite pass, a fresh-validated Udit22
  targeted graft, and the late 2026-07-14 public refresh. The corrected
  late-refresh package at
  `submissions/refresh-2026-07-14-survivors-896-no-chimera-failures/submission.zip`
  rolled back Kaggle-processing failures `task308`, `task316`, `task361`, and
  `task397`; Kaggle ref `54700213` scored `7358.16`.
- Ran `scripts/exact_rewrite_toolchain.py` on the `7358.16` package. It found
  one exact rewrite on `task080`, reducing local cost `8883 -> 8823` and
  projecting `+0.006777`. The candidate
  `submissions/exact-rewrite-7358-v1/submission.zip` passed fresh ARC-GEN
  `824/824` generated in-bounds examples for `task080`, zip CRC/layout,
  400/400 standard ONNX checker, and 400/400 official `check_network`.
  Submitted as Kaggle ref `54713237`; it completed with public score `7358.17`.
- Downloaded the 2026-07-15 public leaderboard snapshot. Score `7358.16` ranked
  `482/3037`; top 10% was rank `304` at `7383.03`, so the current gap to that
  threshold is about `24.87` points.
- Re-ranked the late-refresh public archives against the `7358.16` base. The
  remaining cost-positive donors are the filtered risky leftovers: fresh-fail
  tasks such as `task161`, `task188`, `task079`, `task377`, and `task205`, plus
  the Kaggle-processing failure tasks. Next medal-scale work should target
  repair or resynthesis of those tasks, not another blind public bundle.
- Added `scripts/diagnose_fresh_failures.py` to regenerate selected failing
  ARC-GEN cases and compare base/donor grids. Diagnosed `task188` as a square
  orientation bug in the compact lockbox model: it sometimes took the top half
  when a square input was duplicated horizontally and needed the left half.
- Added `scripts/patch_task188_lockbox.py`. The patched `task188` model keeps
  the compact donor architecture but replaces the square orientation test with
  the current base's color-weighted `col0 == col2` and `col1 == col3` signal.
  It reduced local cost `525 -> 225`, projected `+0.847298`, matched the
  `7358.17` base with zero regressions across 8,192 fresh ARC-GEN examples, and
  passed zip CRC/layout, 400/400 ONNX checker, and 400/400 `check_network`.
  Submitted as Kaggle ref `54713652`; it completed with public score `7359.01`.
- Built `submissions/task188-patch-plus-task205-lockbox-probe/submission.zip`
  by stacking raw lockbox `task205` onto the scored `7359.01` base. This is a
  risky net-correctness probe rather than a no-regression repair: the 1,024-case
  matched fresh control had 9 donor-only improvements, 1 base-only regression,
  1,014 both-correct cases, and no runtime failures. Archive validation passed
  zip CRC/layout, 400/400 ONNX checker, and 400/400 `check_network`. Submitted
  as Kaggle ref `54717401`; it completed with public score `7359.69`.
- Re-ranked the late-refresh public archives against the `7359.69` base. The
  top remaining cost-positive tasks are still risky leftover donors:
  `task161`, `task079`, `task377`, `task105`, `task370`, `task355`, `task251`,
  `task157`, and `task095`; `task205` is no longer positive because it is now
  in the base.
- Re-ran `scripts/exact_rewrite_toolchain.py` on the `7359.69` package. It
  found one safe `task188` cleanup, reducing cost `225 -> 220` and projecting
  `+0.022473`. The candidate
  `submissions/exact-rewrite-7359-v1/submission.zip` matched the scored base
  across 8,192 fresh `task188` cases with zero regressions and passed zip
  CRC/layout, 400/400 ONNX checker, and 400/400 `check_network`. Submitted as
  Kaggle ref `54722313`; status was pending at last check.

## Questions

- Is Kaggle's displayed deadline timezone UTC? The CLI reports
  `2026-07-15 23:59:00` without an explicit timezone.
- Existing account submissions still show a much stronger public score
  (`7267.32` from submission `54487100`), so the four-task color-map package
  and the tested `ryosuke-7266-48` grafts should not be selected as final
  submissions.
- The grouped six-task rollback `54638892` should not be selected as final.
- Current completed account best is task205 probe ref `54717401` with public
  score `7359.69`; exact-rewrite ref `54722313` is pending.
- Prepared but unsubmitted fallback archives exist under
  `submissions/lucifer-plus-kaiwalya-task355/`,
  `submissions/lucifer-plus-kaiwalya-no205-no174/`, and
  `submissions/lucifer-plus-kaiwalya-task174/`; use these only if isolating
  which Kaiwalya task was responsible for the small gain becomes useful.
