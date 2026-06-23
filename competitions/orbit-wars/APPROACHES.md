# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-06-23 | Router player-count fix (4P -> producer-anchor) | Local 4P unreliable (see LEARNINGS); validated runtime-safe | `53963473` = **1134.9**; team rank **351/4767 (bronze, top 7.4%)** as "Orbitiamo" | `53963473` live; commit `8567dd3` | Counted score (better of active pair). Bronze cutoff ~rank 477/score ~1115; silver ~rank 238/score ~1155. |
| 2026-06-23 | pa-budget submitted (anti-boom-bust) | n/a | `53969352` ~1108 (converged with pa-routed) | `53969352` live; commit `c9708e1` | 4P source_budget cap ~neutral (not harmful). Both active subs settled ~1108; team slipped to rank ~512 (just under bronze ~1114). |
| 2026-06-23 | pa-prodweight submitted (production-weighted targets) | Probe: longer 4P survival at 2/3 seeds; runtime-safe; prod_weight calibrated to 20 (8 was a near no-op) | `53980317` PENDING | `53980317` live; commit pending | Router fix + budget cap + offensive shortlist ranks by `prod_weight*prod - proximity` (CONFIG_4P prod_weight=20). Active pair {pa-prodweight, pa-budget ~1108 floor}. UNVALIDATED swing for bronze; downside protected by floor. |
| 2026-06-22 | Player-count router plus restored primary (BUGGY) | n/a | Hybrid `53956567` 1074.1 | Superseded | Router mis-detected 4P as 2P; never used producer-anchor in 4P | Replaced by the router fix above. |

## Ready (built, not submitted)

| Date | Approach | Change | Local signal | Status |
| --- | --- | --- | --- | --- |
| 2026-06-23 | pa-budget (anti-boom-bust) | Cap cross-wave `source_budget` to `safe_drain` so 4P planets can't be drained to ~0 across multiple waves | Non-regressing vs pa-routed; surv_frac 0.90 vs 0.85; survives 500 vs 271 steps in probe; runtime-safe | Archive ready; HOLD until 1139 settles, then submit as low-risk upside (pa-routed 1139 stays as floor) |
| 2026-06-23 | pa-reserve / commit_fraction | Reserve floor / per-launch fraction | REGRESSED (over-throttles expansion) | Rejected |

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
