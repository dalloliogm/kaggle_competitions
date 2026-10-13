# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-09-07 | PUB-001: Tetsutani v11 public-state route + 99-slot guard | 10/10 vs starter; 10/10 vs Salem; full self-play `DONE` | Pending (ref 56075091); source notebook score 2494.7 | N/A | `submissions/prepared/PUB-001-tetsutani-shape-shop-pasture/` | Exact public source hash and deterministic archive submitted once |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-09-07 | Workspace/tutorial setup | Official rules, agent API, executed tutorial, first source agent, arena harness | 0-2 smoke test | N/A | Prepared | Pin matching environment and benchmark |
| 2026-09-07 | Public notebook audit | 200 metadata rows; four source agents; focused exact-score screen | PUB-001 strongest downloaded candidate at 2494.7 | Pending, ref 56075091 | Submitted as first live calibration | Wait for validation and ladder evidence |
| 2026-09-07 | ALT-001 exact terminal settlement | Same route as PUB-001 plus turn-718 liquidation | 2W/36T/2L vs PUB-001 across 20 side-swapped seeds; zero aggregate margin | 2471.3 source score | Hold | No measured gain over PUB-001 |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| Multi-tile daily scheduler | Uses more of the board while respecting maintenance deadlines | High | Medium | High |
| Replay mining | Public episodes can reveal strong openings and action allocation | High | Medium | High |
| Opening search | Long-horizon capital allocation likely dominates early strategy | High | High | Medium |
| Behavior cloning | Useful if strong replay actions can be reconstructed reliably | Medium | High | Low until replay audit |
| Self-play RL | Potentially high ceiling, but only after a trustworthy arena exists | High | Very high | Low |
| PUB-001 live calibration follow-up | Establishes the frozen ladder baseline after validation | High information value | Already submitted | Track ref 56075091 |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| None yet | N/A | N/A | N/A |
