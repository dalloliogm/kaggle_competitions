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
- Do not graft Anas `task054` onto the current best; both the isolated
  `task054` probe and the three-task Anas explicit bundle scored `7269.59`.
- Do not graft Jonathan's explicit `task197`/`task264` pair onto the current
  best; it scored `7269.54`.
- Public notebook byte-smaller consensus is not enough evidence. The live
  leaderboard repeatedly penalized smaller variants from lower-scoring bases.
- Current medal gap is large: downloaded public leaderboard snapshot from
  `2026-07-13T12:52:33` puts `7269.61` at rank `523`; top 10% cutoff is
  `7373.05`, a gap of `+103.44`.
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

## Questions

- Is Kaggle's displayed deadline timezone UTC? The CLI reports
  `2026-07-15 23:59:00` without an explicit timezone.
- Existing account submissions still show a much stronger public score
  (`7267.32` from submission `54487100`), so the four-task color-map package
  and the tested `ryosuke-7266-48` grafts should not be selected as final
  submissions.
- The grouped six-task rollback `54638892` should not be selected as final.
- Current account best is now exact-rewrite pass v1 submission `54652438` with
  public score `7269.74`.
- Prepared but unsubmitted fallback archives exist under
  `submissions/lucifer-plus-kaiwalya-task355/`,
  `submissions/lucifer-plus-kaiwalya-no205-no174/`, and
  `submissions/lucifer-plus-kaiwalya-task174/`; use these only if isolating
  which Kaiwalya task was responsible for the small gain becomes useful.
