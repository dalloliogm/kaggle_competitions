# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-09 | Account baseline artifact | Not reproduced locally from source; output zip has 400 task files | 7267.32, submission ref `54487100` | Unknown | Kaggle kernel `dalloliogm/2026-neurogolf-baseline` | Current account best; use as the baseline to beat. |
| 2026-07-10 | Color-map 1x1 convolution baseline | 4 task networks pass all provided examples | 81.57, submission ref `54528731` | Unknown | `scripts/build_color_map_submission.py` | Generates `submission.zip` for `task016`, `task276`, `task309`, and `task337`; useful mechanics anchor, not final-worthy. |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-07-10 | Pure color-map task scan | Scanned all 400 JSON files for same-shape tasks where output is a consistent per-color mapping across train/test/arc-gen. | Found and validated 4 tasks. | 81.57, submission ref `54528731` | Completed and scored, but far below existing account score `7267.32`. | Expand to affine/geometric/local-neighborhood transforms; do not rely on four-task package. |
| 2026-07-10 | `own7267-plus-ryosuke-7` graft | Replaced seven smaller task files from public close-scoring `ryosuke-7266-48`: `task005`, `task008`, `task107`, `task233`, `task310`, `task366`, `task370`. Candidate zip was 25,274 uncompressed bytes smaller than the account baseline. | The seven replacements passed all official-valid provided examples under NeuroGolf 30x30 one-hot semantics. | 7267.19, submission ref `54529022` | Worse than the account baseline by 0.13 public LB points, so at least one replacement loses hidden correctness or score. | Do not use this full graft as final. Test future grafts in smaller isolated groups. |

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
