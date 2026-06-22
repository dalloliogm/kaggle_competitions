# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-06-22 | Player-count router plus restored primary | Router uses primary for 2P and producer anchor for 4P | Hybrid: 4/6 2P vs I'M STRONGER; zero errors; component behavior already ladder-tested | Hybrid `53956567` complete; restored primary `53956759` pending | Final active pair once validation completes | Submit nothing else unless intentionally replacing the hybrid. |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-06-21 | June 21 meta primary | Player-count-aware flow planner with 4P seat fixes | 17/30 overall; 8/12 4P | 1141.8; 11/12 early 2P wins, 1/9 early 4P wins | Keep as 2P specialist despite advertised 4P role | Do not replace without a clearly stronger overall candidate. |
| 2026-06-21 | R/K wave challenger | Mid-size wave pattern intended to decorrelate 2P outcomes | 22/30 overall; 18/18 2P | 1185.9; 7/13 early 2P wins, 5/11 early 4P wins | Keep as balanced slot | Current best overall live rating. |
| 2026-06-21 | Focused public 4P replacement screen | Seven candidates against three challenger seats, three seeds, all seats | `i-the-orbit` 2/12; every other candidate 0/12 | Not submitted | No replacement cleared the bar | A third submission would evict the current challenger, so preserve both active slots. |
| 2026-06-22 | June 22 final public screen | C2 frontier flow, C3 retention, producer anchor, Apex against both incumbents | Producer anchor: 8/8 4P vs primary, 4/8 4P vs challenger, 2/4 and 4/4 in 2P | Submitted | Clear replacement for the lower-rated challenger | Monitor validation and early ladder settlement. |
| 2026-06-22 | C2/C3 generated challengers | Wider defense/regroup and 4P retention presets | Both 0 wins across 24 games each | Rejected | Failed direct incumbent tests | Do not submit based on notebook recommendation alone. |
| 2026-06-22 | Apex hybrid defense | Ring conquest and border-aware proactive defense | 5/8 4P vs challenger, 0/8 4P vs primary; strong 2P | Rejected for now | Less robust than producer anchor | Revisit only if producer anchor underperforms live. |
| 2026-06-22 | Player-count specialist router | Primary code in 2P; producer anchor in 4P | 2P: 3/6 vs primary, 3/6 vs anchor, 4/6 vs I'M STRONGER. 4P: anchor-equivalent; zero errors | Not submitted | Best evidence-backed architecture | Submit before restoring primary to preserve intended latest-two ordering. |
| 2026-06-21 | Self-contained v8 heuristic | Forward simulation, anti-snipe, hammer and endgame logic | 0/30 in this tournament | Claimed 1250 in public notebook | Rejected | Local transfer was poor despite sophisticated code. |
| 2026-06-21 | Frontier shortlist backup | Safer ProducerLite derivative | 9/30 overall | Not tested | Rejected | Inferior to selected variants. |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| Inspect losses after ratings settle | Replay-specific failures are more useful than more blind parameter forks | High | Medium | P0 |
| Submit one evidence-backed revision on 2026-06-22 | New agents receive faster episode allocation | Medium | Medium | P1 |
| Preserve the current two-agent portfolio if evidence is noisy | The final ladder keeps only the latest two submissions | High downside avoidance | Low | P0 |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| Copy the most complex public heuristic | Public score claims did not transfer locally | v8 lost all 30 seeded matches | A replay identifies a specific fix or the public settled score materially changes |
| Use current latest-two unchanged | I'M STRONGER displaced the bronze-level primary and both active agents are below cutoff | Current rank 820, score 1059.2 | Never; slot ordering must be repaired |
