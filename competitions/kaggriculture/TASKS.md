# Tasks

## Current Goal

- Track PUB-001 through Kaggle validation and initial ladder scoring, then use
  it as the frozen baseline for the next promotion decision.

## Next Experiments

- Inspect the public leaderboard and download representative high-rated replays
  before investing heavily in heuristic tuning.
- Build a replay parser for observation/action trajectories and measure crop,
  market, hiring, land-purchase, and no-op patterns by game phase.
- Add a stronger multi-tile planner with daily task scheduling and deliberate
  end-of-season liquidation.
- Refresh submission 56075091 until validation and initial scoring are
  terminal; keep validation state and ladder score separate.

## Done

- Initialized the standard competition workspace.
- Downloaded and unpacked the official README and agent guide.
- Confirmed Kaggle access-token authentication, competition entry, live
  deadline/team count, and that there are no existing submissions.
- Created the competition tutorial notebook and baseline-v1 source agent.
- Executed the tutorial top-to-bottom and completed two full-season,
  side-swapped runtime smoke tests; baseline-v1 finished cleanly but lost both
  matches to `starter` (3391 vs 3489).
- Installed `kaggle-environments==1.32.7` in the competition-local `.venv` and
  confirmed that its official defaults match the downloaded competition files.
- Ingested 200 competition-scoped public notebooks and audited exact score/code
  evidence for a focused shortlist.
- Extracted four public agents without executing untrusted notebook setup code;
  compiled and locally screened all four.
- Prepared PUB-001 from Tetsutani v11 (verified source score 2494.7), validated
  exact source hash and archive layout, and completed a full self-play smoke
  test.
- Submitted the frozen PUB-001 archive once as Kaggle ref 56075091 at
  2026-09-07 10:43:18 UTC. Kaggle accepted the upload; validation was pending
  on the first status check.

## Questions

- Which official Kaggle Environments release or commit exactly matches the live
  evaluator?
- How stochastic is the starter matchup, and how many paired seeds are needed
  for a stable promotion decision?
- Which high-rated public episodes are downloadable, and what action abstraction
  best captures their policies?
