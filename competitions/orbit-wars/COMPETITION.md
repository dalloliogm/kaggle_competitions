# Orbit Wars

## Links

- Competition: https://www.kaggle.com/competitions/orbit-wars/code?competitionId=138420&sortBy=scoreDescending&excludeNonAccessedDatasources=true
- Kaggle workspace slug: `orbit-wars`
- Kaggle CLI slug: `orbit-wars`

## Objective

Build an agent for a 2- or 4-player real-time strategy ladder. Capture neutral
and enemy planets, avoid the central sun, and finish with the highest total
ships across owned planets and fleets.

## Evaluation

- Metric: estimated ladder skill rating from repeated head-to-head episodes.
- Final deadline: 2026-06-23 23:59 UTC, as reported by the Kaggle API on
  2026-06-21.
- Validation approach: deterministic local seeded matches in
  `kaggle_environments`, covering both 2-player and 4-player games.
- Final evaluation continues for approximately two weeks after submissions
  lock.
- Only the latest two submissions remain active for final evaluation; the
  leaderboard displays the better of those two.

## Data

- Kaggle input path: `/kaggle/input/orbit-wars/`
- Local data path: `data/`
- Key files: `README.md`, `agents.md`, and the starter `main.py`.

## Submission

- Expected file: `main.py` or a `tar.gz` containing root-level `main.py`.
- Agent entry point: `agent(obs)`, returning
  `[from_planet_id, direction_angle, num_ships]` moves.
- Generated outputs: `submissions/`.

## Rules And Constraints

- Daily limit: 5 agents.
- Final submissions: up to 2.
- Public competition code can be reused under the competition rules and its
  applicable open-source license.
- Runtime: 1 second act timeout plus the environment overage-time budget.

## Current Baseline

- Previous account submission: 698.4, submitted 2026-04-25.
- New primary: June 21 player-count-aware 4P flow variant.
- New complement: June 21 R/K wave variant for stronger 2P coverage.
- Local seeded benchmark: primary won 8/12 four-player matches; challenger won
  18/18 two-player matches. Both completed every match without runtime errors.
