# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Post-competition result and top-solution lessons (2026-07-09)

- Final result: bronze medal, rank 394 / 4730, score 1102.3. See `POSTMORTEM.md`.
- The winner used a 200M-parameter transformer trained for 15B self-play PPO steps; second place used a 4.3M ModernBERT/1D-CNN model trained with imitation learning and PPO/self-play. Gold was dominated by scaled RL, not by shallow heuristic forks.
- A major top-solution insight: strong play often reduces to `no-op` or near all-in launches from a small number of sources. The hard part is source/target/timing, not arbitrary fractional fleet sizing.
- The strongest rule-based write-up reached top-50/top-100 territory by adding what our ProducerLite-derived bots lacked: early-game search, 20-30 step planet forecasting, target-wise multi-source planning, delayed execution, reinforcement chains, and source-vulnerability scoring.
- Bronze-level heuristic patching fixed local bugs and overcommitment symptoms. Silver/gold required either a fast RL pipeline or a deeper planning stack with coherent opening search and future-state evaluation.

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

## Live validation of the router fix + remaining failure (2026-06-23)

- Router fix (sub 53963473, display name now "Orbitiamo") settled to ~1139
  (≈bronze), up from the buggy hybrid's 1074.
- Analyzed 20 fresh LIVE replays via `kaggle competitions episodes/replay`
  (CLI 2.2.2 has these subcommands; pull IDs with `episodes <submission_id>`,
  download with `replay <episode_id> -p <dir>`). NOTE zsh does not word-split
  unquoted vars — iterate IDs with `while read`, not `for e in $eps`.
- 2P: 5/10 wins, led production by step 40 in 9/10 (we build leads, convert ~half).
- 4P: 3/10 wins, 5/10 EARLY ELIMINATIONS, led prod by step 40 in 6/10. The
  boom-bust persists and is now live-confirmed: lead early, then in-flight ship
  share sits ~0.5-0.6 (half the army permanently in transit) and we get
  counter-eliminated. Wins snowball to 22-30 planets — outcome is binary
  (snowball-and-win vs overcommit-and-die).
- => `pa-budget` (cap cross-wave source_budget to safe_drain) directly targets
  this live-confirmed failure; it is the evidence-backed next submission once 1139
  settles. Secondary levers from forensics still untested live: production-weighted
  target scoring, 1v1-endgame consolidation (mass when 2 of 4 seats are out).

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

## Agent mechanics and the two active submission strategies (2026-06-23)

Shared base — "ProducerLite" flow planner. Each turn: (1) list source planets
(ours, enough ships); (2) list targets (nearby capturable planets + own threatened
planets for defense); (3) size one fleet per source→target pair via `safe_drain`;
(4) score each by a "me − Σ opponents" net-ship flow over a short look-ahead horizon
(13 turns in 4P); (5) greedily fire the few best, then regroup leftovers toward
threatened planets. A router sends 2P→primary (duel-tuned), 4P→producer-anchor.
Both submissions share this base and play 2P identically; they differ ONLY in 4P
offense.

`safe_drain` = max ships a planet can send NOW and still survive the horizon.
Mechanism: project the planet's ship count each future turn under a "do-nothing"
assumption (keeps producing; enemy fleets ALREADY in flight arrive; no NEW enemy
attacks); take the minimum projected count over turns we still own it; cap at the
current garrison. Sending that many lands the worst upcoming turn at exactly 0.
Doomed planets (lost within horizon regardless) return the full garrison. BLIND
SPOT: the do-nothing assumption ignores REACTIVE counter-attacks — the enemy seeing
us empty a planet and launching a fresh fleet the projection never saw. That blind
spot is the 4P boom-bust; `reinforce_size_beta` and pa-budget's cap are patches for it.

Why proximity-only targeting hurt: the shortlist ranks targets nearest-first, but
"nearest" ≠ "most valuable". Planet production is ~1-5 ships/turn and COMPOUNDS over
100-200 turns, so a far prod-5 planet is worth far more than a near prod-1 rock.
Grabbing the closest planets grew our planet COUNT but froze our PRODUCTION (~14-34
in losses) while winners compounded to 50+. Caveat: the shortlist is only half the
cause — the scorer's 13-turn horizon also under-credits long-payoff captures even
when they are candidates; pa-prodweight fixes the shortlist half only.

Active pair (final): pa-budget (53969352) and pa-prodweight (53980317).
- pa-budget = base + reserve cap: cap a planet's TOTAL contribution across all its
  attacks in one turn to its safe_drain, so it is never emptied by multiple waves.
  Strategy: capture but always leave a garrison — hold what you take.
- pa-prodweight = pa-budget + production-weighted targeting: rank offensive targets
  by `prod_weight*production − proximity` (CONFIG_4P prod_weight=20) so high-prod
  planets surface. Strategy: capture economically valuable planets to compound, not
  just the nearest. The shortlist-only lever is partial; magnitude 8 was a near
  no-op (prod is small vs distances), 20 bites consistently.

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
