# Notes

## Public notebooks reviewed

- `romantamrazov/orbit-wars-i-m-stronger`
- `caoyupeng/v2-gru`
- `shummingfang/orbit-wars-exp50`
- `alycemiki/light-ver-1200-simple-orbit-intruder`
- `ranjeet258/orbit-wars-producer`
- `jek1wantaufik/simplified-orbit-wars-agent`
- `pilkwang/orbit-wars-meta-snapshot-0621`
- `evgendvorkin/orbit-wars-v8-max-1250-score`
- `olasadek/i-the-orbit`

The June 21 meta snapshot explicitly recommends a player-count-aware primary
plus a mid-size-wave challenger as complementary final slots. Local tests
supported that split.

## Local benchmark

Three fixed seeds, both 2P seat orders for every candidate pair, plus four seat
rotations for 4P lineups:

| Candidate | Overall | 2P | 4P | Errors |
| --- | ---: | ---: | ---: | ---: |
| Challenger R/K wave | 22/30 | 18/18 | 4/12 | 0 |
| Primary player-count fix | 17/30 | 9/18 | 8/12 | 0 |
| Frontier shortlist | 9/30 | 9/18 | 0/12 | 0 |
| Self-contained v8 | 0/30 | 0/18 | 0/12 | 0 |

Raw results: `submissions/local-benchmark.json`.

## Live submissions

| Role | Submission ID | Validation episode | Initial score | Status |
| --- | ---: | ---: | ---: | --- |
| Primary 4P | `53920165` | `81149461` | 600.0 | Complete; awaiting ladder episodes |
| Challenger 2P | `53920164` | `81149460` | 600.0 | Complete; awaiting ladder episodes |

Both validation logs contain no stderr or exceptions. The primary's 2P
self-play ended by elimination at step 238. The challenger's 4P self-play
reached step 500 with a four-way tie. Both retained roughly 49-50 seconds of
the 60-second overage budget, so runtime is currently safe.

The Kaggle CLI was upgraded from 2.1.0 to 2.2.2 because 2.1.0 failed to
download episode replays and logs when the response omitted `Content-Length`.

## Early ladder evidence

Snapshot after 45 downloaded public episodes:

| Agent | Rating | 2P record | 4P record | Interpretation |
| --- | ---: | ---: | ---: | --- |
| Primary | 1141.8 | 11/12 | 1/9 | Strong duel specialist; advertised 4P behavior did not transfer |
| Challenger | 1185.9 | 7/13 | 5/11 | Better overall and substantially more balanced |

All primary 4P losses and all but one challenger 4P loss ended in elimination.
The primary's 4P problem is therefore survival, not merely losing close
endgame ship-count comparisons.

Focused replacement benchmark against three challenger seats:

| Candidate | 4P wins |
| --- | ---: |
| `i-the-orbit` frontier-reserve agent | 2/12 |
| Current primary | 0/12 |
| Frontier shortlist | 0/12 |
| `i-m-stronger` | 0/12 |
| `exp50` | 0/12 |
| `light-1200` | 0/12 |
| `v2-gru` | 0/12 |

`i-the-orbit` was directionally better but not strong enough to risk evicting
the live challenger. Raw results are in
`submissions/benchmark-4p-candidates.json`; replay-derived results are in
`submissions/ladder-analysis.json`.

## June 22 final-week screen

Overnight ratings before the new submission:

- Primary: 1147.5
- Challenger: 1106.6

Direct benchmark results:

| Candidate | 2P vs primary | 4P vs primary | 2P vs challenger | 4P vs challenger |
| --- | ---: | ---: | ---: | ---: |
| Producer anchor | 2/4 | 8/8 | 4/4 | 4/8 |
| Apex hybrid | 2/4 | 0/8 | 4/4 | 5/8 |
| C2 frontier flow | 0/4 | 0/8 | 0/4 | 0/8 |
| C3 4P retention | 0/4 | 0/8 | 0/4 | 0/8 |

The producer anchor was submitted on June 22, replacing the older,
lower-rated challenger in the two-active-submission window. Raw results:
`submissions/benchmark-0622-candidates.json`.

## Medal-gap diagnosis

Full leaderboard snapshot at 2026-06-22 19:28 UTC:

- Team rank: 820 / 4752
- Team score: 1059.2
- Approximate bronze cutoff (top 10%, rank 475): 1118.2
- Approximate silver cutoff (top 5%, rank 237): 1160.3
- Approximate gold cutoff (top 1%, rank 47): 1332.9

The primary previously scored 1145.1, which would be inside the current bronze
zone. It was displaced from the latest-two active window by submission
`53939966`, the Kaggle notebook `Orbit Wars | I'M STRONGER`, which currently
scores 1021.0.

Current active replay records:

| Agent | 2P | 4P | Rating |
| --- | ---: | ---: | ---: |
| Producer anchor | 13/17 | 4/10 | 1058.3 |
| I'M STRONGER | 20/34 | 6/19 | 1021.0 |

The final hybrid routes:

- 2P to the former primary, which previously scored 1145.1 and won 11/12 early
  live 2P games.
- 4P to the producer anchor, which has the stronger local 4P behavior.

Recommended submission order is hybrid first, restored primary second. This
leaves those two as the latest active submissions and removes both weaker
current slots.

Executed final submission order:

1. Hybrid `53956567` — validation complete, early rating still unstable.
2. Restored primary `53956759` — submitted at 2026-06-22 19:49 UTC and pending
   validation at the latest check.

No additional submission should be made without deliberately changing this
final pair.

## Router-fix submission (2026-06-23)

Deep reanalysis (forensics + code audit via multi-agent workflow) uncovered a
deployed bug: the hybrid router detected player count from the all-neutral
`initial_planets` and routed EVERY 4P game to the 2P `primary` agent (verified:
270 primary / 0 producer-anchor calls in a live 4P game). The intended
"4P → producer-anchor" path never ran on the ladder.

- Submitted `53963473` (pa-routed): router now counts owners from live
  `planets`/`fleets`. 2P unchanged; 4P → producer-anchor + CONFIG_4P.
  Validation COMPLETE, runtime-safe (full 60s overage), no errors.
- Excluded `commit_fraction` reserve idea: regressed hard locally (0.08 win) by
  under-expanding. See LEARNINGS.
- Active final pair: `53963473` (pa-routed) + `53956759` (restored primary).
  Buggy hybrid `53956567` aged out of the latest-two window.
- Caveat: local 4P benchmarks are weak/unrepresentative (didn't match live);
  the fix rests on live evidence (producer-anchor 4/10 vs primary 1/9 in 4P).

## Standing at 2026-06-23 16:50 BST (deadline 23:59 UTC)

- Router fix `53963473` peaked ~1139, then it and the budget-cap fix `53969352`
  settled/drifted to ~1105 / ~1096 as ratings converged toward true skill and the
  field hardened near the deadline.
- Submitted `53980317` (pa-prodweight, production-weighted targeting) as a
  downside-protected upside swing. It validated but STALLED at 892.4 / 21 episodes
  — team-wide daily episode quota exhausted (all our subs' public scores froze).
  892.4 is undersampled, NOT a settled verdict.
- Active final pair: `53980317` (pa-prodweight) + `53969352` (pa-budget ~1096
  floor). pa-routed `53963473` aged out of the latest-two window.
- Team "Orbitiamo": rank 579/4784 (top 12.1%), counted 1096.2. Bronze line
  rank ~478 / score ~1115.3 → currently ~19 pts / ~100 ranks UNDER bronze.
- Can we predict pa-prodweight's settled level from trajectory? No — at 21 episodes
  the rating uncertainty (±100+) overlaps the floor; early ratings overshoot then
  regress (pa-routed 1139→1105, pa-budget 1117→1096). Weak negative signal:
  pa-prodweight (892@21ep) is climbing slower than pa-budget was (~1090@27ep). The
  real predictor would be its actual win-rate / 4P early-elimination rate vs
  opponent strength in those 21 games, not the rating number.
- Verdict: borderline ~1100 team, just under bronze. Router fix was the real
  validated gain (~+65). Medals decided by the ~2-week post-deadline re-eval (both
  locked subs re-play from scratch), so the public snapshot is not final. HOLD —
  episodes throttled, and pa-budget/pa-routed are near-identical so swapping buys
  nothing.

## EDA Observations

- TBD

## Feature Ideas

- TBD

## Model Ideas

- TBD

## Useful References

- TBD
