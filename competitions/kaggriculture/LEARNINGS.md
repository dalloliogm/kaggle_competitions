# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- The competition bundle contains documentation rather than train/test tables.
  The environment state and public episode replays are the empirical data.

## Target And Metric

- Rank depends on episode wins/ties/losses, not the size of the coin margin.
- Final ranking is a Bradley-Terry tournament over episodes; evaluate policies
  on whole episodes and report uncertainty rather than a single mean bank value.

## Validation

- Use seeded, side-swapped matches and keep all steps from one episode in the
  same split if replay-derived models are developed.
- Freeze promoted agents and benchmark each candidate in a separate process to
  avoid Python module collisions.

## Leakage And Rules

- Evaluation has no network ingress/egress. A submission must be self-contained.
- Public replays may expose actions, so never treat adjacent steps from the same
  episode as independent validation examples.

## Features

- Public farm state, market inventory/prices, town demand, remaining time,
  private stock, and maintenance deadlines are all decision-relevant.

## Models

- A transparent deterministic scheduler is the first meaningful baseline.
  Behavior cloning or self-play should wait until replay tooling and the local
  arena are trustworthy.
- The single-tile carrot baseline is weaker than the built-in starter in the
  first side-swapped seed-21 smoke test (3391 vs 3489 in both seats). Do not
  submit it as a competitive candidate.
- Current public-notebook titles are unreliable score evidence: the notebook
  titled `2900+` returned a verified current score of 1203.7. Always query exact
  score metadata and version history.
- The strongest downloaded candidate in the focused 2026-09-07 audit was
  Tetsutani v11 at 2494.7. It uses stored route tapes, three public-state route
  switches, bounded weed/sell repairs, and a 99-item day-close shed target.
- A terminal-settlement derivative scored 2471.3 and was locally
  indistinguishable from Tetsutani across 20 side-swapped seeds; the theoretical
  change did not supply a measured promotion reason.

## Ensembling And Submission Behavior

- A live submission must be validated as an artifact (`main.py` at root), then
  survive Kaggle's self-play validation episode before joining the ladder.
- Only the newest two submissions are tracked, so every upload changes the live
  candidate set.
- Public code can establish a useful first ladder calibration, but its source
  score belongs to the author's submission. Our live score remains unknown until
  our exact artifact completes Kaggle validation and plays enough episodes.
- PUB-001 was accepted as submission 56075091 on 2026-09-07. Its first observed
  state was `PENDING`; acceptance is not validation success or a ladder score.

## Leaderboard Notes

- On 2026-09-07 the public leader was at 2875.2; refresh before comparison.
- There is no private leaderboard for this simulation competition.
