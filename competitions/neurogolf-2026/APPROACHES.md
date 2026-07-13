# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-13 | Public Lucifer AGI Circuit Forge artifact | Notebook log reported `400/400` ONNX checker pass, static IO pass, changed-model ORT load pass, and 400 bit-exact ORT trials for accepted rewrites on `task205` and `task368` | 7269.60, submission ref `54645666` | Unknown | Public notebook `lucifer19/neurogolf-agi-circuit-forge` | New current best seen in this workspace; output zip SHA-256 `644938043f8b9d729235e66dfeaef7ed586a69ca9cc4c198cb5164f81b3b3ad0`. |
| 2026-07-12 | Public Poby 7268 artifact | Kaggle notebook log reported archive integrity OK; local archive inspection found 400 root ONNX files | 7268.00, submission ref `54619344` | Unknown | Public notebook `poby7722/7268-neurogolf-best-score` | Former account best; now superseded by public Lucifer artifact `54645666`. |
| 2026-07-09 | Account baseline artifact | Not reproduced locally from source; output zip has 400 task files | 7267.32, submission ref `54487100` | Unknown | Kaggle kernel `dalloliogm/2026-neurogolf-baseline` | Former account best; now superseded by public Lucifer artifact `54645666`. |
| 2026-07-10 | Color-map 1x1 convolution baseline | 4 task networks pass all provided examples | 81.57, submission ref `54528731` | Unknown | `scripts/build_color_map_submission.py` | Generates `submission.zip` for `task016`, `task276`, `task309`, and `task337`; useful mechanics anchor, not final-worthy. |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-10 | Pure color-map task scan | Scanned all 400 JSON files for same-shape tasks where output is a consistent per-color mapping across train/test/arc-gen. | Found and validated 4 tasks. | 81.57, submission ref `54528731` | Completed and scored, but far below existing account score `7267.32`. | Expand to affine/geometric/local-neighborhood transforms; do not rely on four-task package. |
| 2026-07-10 | `own7267-plus-ryosuke-7` graft | Replaced seven smaller task files from public close-scoring `ryosuke-7266-48`: `task005`, `task008`, `task107`, `task233`, `task310`, `task366`, `task370`. Candidate zip was 25,274 uncompressed bytes smaller than the account baseline. | The seven replacements passed all official-valid provided examples under NeuroGolf 30x30 one-hot semantics. | 7267.19, submission ref `54529022` | Worse than the account baseline by 0.13 public LB points, so at least one replacement loses hidden correctness or score. | Do not use this full graft as final. Test future grafts in smaller isolated groups. |
| 2026-07-10 | `ryosuke-7266-48` lower-risk split tests | Tested smaller subsets from the failed seven-task graft: five-task `task005/task008/task107/task310/task370`, A3 `task005/task008/task107`, and B2 `task310/task370`. | All selected replacements passed official-valid provided examples before submission. | Five-task `54529420`: 7267.27; A3 `54529552`: 7267.29; B2 `54529559`: 7267.29 | No tested subset beats the account baseline `54487100` at 7267.32. | Stop broad Ryosuke grafting; look for genuinely new task improvements or another public source with stronger evidence. |
| 2026-07-12 | Frank `task074` single-task probe | Replaced only `task074` from public `franksunp/7245-63-lb-neurogolf-variant-b-mark-a`; candidate shrank `task074` from 8001 to 708 bytes. | Replacement passed all 267 provided examples. | 7267.24, submission ref `54619246` | Failed despite local validation and large byte reduction; likely hidden correctness loss or worse hidden scoring. | Do not treat byte reduction as safety evidence; prefer higher-scoring public artifacts or source-level improvements. |
| 2026-07-12 | Public Poby 7268 artifact | Submitted full output from public `poby7722/7268-neurogolf-best-score`; differs from the 7267.32 baseline on 25 tasks, with net uncompressed delta `-53687` bytes. | Archive had 400 root ONNX files and notebook log reported integrity OK. | 7268.00, submission ref `54619344` | Improves the account best by `+0.68` over `54487100`. | Use as the current best candidate unless a later submission beats it. |
| 2026-07-13 | Poby six-task larger-file rollback | Started from Poby `54619344` and rolled back the six tasks where Poby was larger than the old baseline: `task008`, `task035`, `task044`, `task074`, `task085`, `task363`. Candidate was 9,820 uncompressed bytes smaller than Poby. | Archive validation passed: 400 canonical root ONNX files and zip CRC clean. | 7267.90, submission ref `54638892` | Worse than Poby by 0.10, so grouped rollback removes hidden-value changes. | Do not use this candidate. If spending more slots, isolate individual rollbacks or use fresher public sources. |
| 2026-07-13 | Public Lucifer AGI Circuit Forge artifact | Submitted full output from `lucifer19/neurogolf-agi-circuit-forge`; archive differs from Poby on 61 tasks and notebook audit claims exact accepted rewrites on `task205` and `task368` over a `7269.56` anchor. | Notebook log reports 400/400 checker pass and 400 bit-exact ORT trials. | 7269.60, submission ref `54645666` | Improves over Poby by `+1.60` and becomes the new current best. | Use this artifact as the baseline for further source mining or task-level grafts. |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| More same-shape color logic | Many tasks preserve the nonzero mask or shape but require slightly richer local rules than a pure color map. | Medium: several quick extra task files. | Low-medium | High |
| Task001 Kronecker expansion | Task001 appears to apply an input-mask-driven expansion; likely a reusable pattern for several size-changing ARC tasks. | Medium if solved generically. | Medium | High |
| Public notebook/discussion mining | Competition has thousands of teams; accepted ONNX operator patterns may already be public. | High for speed. | Low-medium | High |
| ONNX graph template library | Reusable builders for color maps, shifts, flips, crops, masks, and simple convolutions. | High over several days. | Medium | Medium |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| Submit all task files as memorized constants | Private benchmark suite is explicitly designed to prevent overfitting, and constant test outputs would likely fail. | Official evaluation text requires correctness on original ARC-AGI plus private benchmark. | Only for local debugging, never as the main submission strategy. |
