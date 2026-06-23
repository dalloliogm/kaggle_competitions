# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- This is an environment-agent competition, not a tabular prediction task.
- The map has 20-40 planets, a destructive central sun, orbiting inner
  planets, static outer planets, and temporary comets.
- Larger fleets travel faster; small drips are slow and often strategically
  wasteful.

## Target And Metric

- Ladder score uses repeated wins/losses, not victory margin.
- Final game score is total ships on planets plus fleets; ties at the maximum
  receive a winning reward.

## Validation

- Test both 2P and 4P. A single aggregate result hides meaningful specialization.
- Rotate seats and use fixed seeds. The selected challenger dominated local 2P,
  while the selected primary was clearly stronger in the local 4P lineup.
- Public notebook score claims are hypotheses, not validation.

## Leakage And Rules

- Publicly shared competition code is allowed, subject to competition rules and
  the source license.
- Exact submission archives must include `main.py` at the archive root.

## Features

- Predict target motion and aim at intercept positions rather than current
  positions.
- Account for reachable enemy reinforcement before committing to captures.
- Preserve frontline reserves and reinforce threatened planets before draining
  them for offense.
- Prefer high-production and strategically central planets, while suppressing
  attacks that cannot arrive before the endgame.

## Critical bug — player-count detection / hybrid router (2026-06-23)

- The real obs has NO `player_count` metadata and `initial_planets` is ALWAYS
  all-neutral (owner -1); seat ownership appears only in the live `planets`
  array. Confirmed against ladder replays (step 0 and mid-game).
- The hybrid router's `_infer_initial_player_count` keyed off `initial_planets`,
  so it detected 2 players in EVERY 4P game and routed 4P games to the 2P
  `primary` agent. Verified: in a live 4P game the router dispatched 270 calls to
  primary and 0 to producer-anchor. The "4P → producer-anchor" design never ran.
- The standalone `producer_anchor` agent detects player count correctly via the
  ADAPTER (`_infer_player_count_from_obs`, returns 4 if any owner >= 2), so
  `CONFIG_4P` DOES activate when it is called directly — the bug was only in the
  router's separate, redundant detector.
- Fix (submission 53963473): router now counts distinct seat owners from live
  `planets`/`fleets`. 2P unchanged (routes to primary); 4P now correctly routes
  to producer-anchor + CONFIG_4P. Live evidence backs this: producer-anchor went
  4/10 in live 4P vs primary's 1/9.
- LESSON: when two code paths each re-derive the same fact, verify BOTH on real
  obs. Instrument which sub-agent actually runs; don't assume routing works.

## Benchmarking pitfalls discovered (2026-06-23)

- Every agent ships its own `orbit_lite` package and shared module names. Running
  multiple agents in ONE python process collides in `sys.modules` (first load
  wins), so candidates that differ only in config produce byte-identical results.
  Run each candidate in a SEPARATE process. The real ladder isolates each agent.
- Binary win/loss vs a single weak opponent saturates (12/12 tells you nothing).
  Use mixed-opponent 4P lobbies and survival metrics (early-elimination rate,
  fraction-of-game-survived, final ship-share) to discriminate. Tools:
  `scripts/replay_tools.py`, `scripts/tournament.py`, `scripts/run_isolated_tournament.sh`.
- Local benchmark vs the available opponent trio did NOT match live results
  (local primary-in-4P looked fine; live it is 1/9). Treat local 4P benchmarks as
  weak evidence; the live ladder is ground truth.
- `commit_fraction` (send only X% of a planet's safe_drain to keep a reserve)
  REGRESSED hard locally (0.08 win at 0.6): smaller fleets under-capture and the
  agent gets out-produced. The forensic "keep reserves" insight does NOT
  translate to a blanket per-launch fraction. Excluded from the submission.

## Forensic diagnosis of 4P losses (2026-06-23)

- 11-replay forensic pass: losses are boom-bust overcommitment. The agent builds
  an early lead (often #1 in production by step ~40) then drains planet garrisons
  into continuous multi-launch attacks; in-flight ships spike to 300-528 while
  on-planet garrisons fall to ~0, planets become recapturable, and it is
  eliminated by step 80-160. Wins are capture-and-hold: in-flight stays <= garrison,
  both grow together, production compounds, planet count rises monotonically.
- Root code levers (planner_core/producer_anchor): `safe_drain` allows draining a
  planet to 0 (no reserve floor); line ~215 sends the full safe_drain; the
  cross-wave `source_budget` is the raw garrison so multiple waves empty a planet.
  These are the right levers in principle, but naive fixes (commit_fraction) hurt
  expansion — needs careful, well-benchmarked tuning, not a blunt multiplier.

## Models

- The current public meta is dominated by ProducerLite flow planning with
  orbital movement prediction, garrison projection, scored wave selection, and
  regrouping.
- Separate player-count presets are important. The same launch rhythm is not
  optimal in duels and four-player free-for-all games.
- Public role labels did not transfer reliably: the advertised 4P primary won
  11/12 early live 2P games but only 1/9 live 4P games.
- The R/K challenger is currently the more balanced ladder agent, with 5/11
  early 4P wins and the highest live rating of the two.
- The June 22 producer anchor was the first tested replacement to dominate an
  incumbent across modes: 8/8 4P wins against the primary and 4/4 2P wins
  against the challenger.
- The June 22 snapshot's recommended C2 and C3 generated candidates both failed
  every direct local incumbent match. Variant-level testing remains mandatory.

## Ensembling And Submission Behavior

- Two complementary agents are preferable to two correlated forks because the
  final evaluation retains two submissions and displays the better ladder score.
- Submitting a third candidate would remove the oldest of the two active
  submissions. Do not do this unless prepared to resubmit the desired incumbent
  and reset its rating/uncertainty.

## Leaderboard Notes

- Current leaderboard leader was 1745.6 on 2026-06-21.
- The previous account bot scored 698.4.
- New submissions receive faster episode allocation, so early submission matters
  with only two days remaining.
