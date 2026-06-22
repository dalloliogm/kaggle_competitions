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
