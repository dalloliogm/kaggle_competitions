# Kaggriculture

## Links

- Competition: https://www.kaggle.com/competitions/kaggriculture
- Kaggle workspace slug: `kaggriculture`
- Kaggle CLI slug: `kaggriculture`

## Objective

Build an autonomous `agent(obs)` policy for a two-player, turn-based farming
simulation. Each game lasts 720 turns (30 days of 24 turns). The winner is the
player with the most coins in the bank at the end; unsold inventory is worth
nothing.

## Evaluation

- Metric: episode win/loss/tie outcomes aggregated into a skill rating; the
  final leaderboard uses a Bradley-Terry tournament over played episodes.
- Validation approach: seeded, side-swapped head-to-head arenas against the
  built-in `starter` agent and frozen prior candidates. Report wins, losses,
  ties, bank balances, and uncertainty across whole episodes.
- Public/private leaderboard notes: this simulation competition has no private
  leaderboard. Only the latest two submissions are tracked and used for final
  evaluation; the public leaderboard shows the better of them. After the
  submission deadline, games continue for about two weeks before the final
  Bradley-Terry tournament.

## Data

- Kaggle input path: `/kaggle/input/kaggriculture/`
- Local data path: `data/kaggriculture/`
- Key files: official `README.md` (mechanics) and `AGENTS.md` (agent API and
  submission workflow), saved under `references/competition-files/unpacked/`.
- This is an agent competition, not a train/test tabular prediction task.

## Submission

- Expected file: `main.py`, or a `.tar.gz` with `main.py` at archive root.
- Required interface: a top-level `agent(obs)` function returning a dict with
  `farmer`, `hands`, and `market` actions.
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: allowed if reasonably accessible to all participants at no or
  minimal cost.
- Episode network access: prohibited; the agent may not pull information in or
  send information out during evaluation.
- Compute: start with CPU-only deterministic policies; no GPU/TPU requirement
  is stated for the baseline.
- Team/merge rules: maximum team size 5; at most 5 submissions per day and 2
  final submissions.
- License: competition data is Apache 2.0; a winning submission and its source
  must be licensed CC-BY 4.0.
- Deadline: 2026-09-30 23:59 UTC (live CLI snapshot on 2026-09-07; refresh
  before relying on it).
- Prize pool: $50,000, split into ten $5,000 prizes.

## Current Baseline

- Local arena: PUB-001 completed all 720-turn tests under the matching
  `kaggle-environments==1.32.7`: 10/10 wins against `starter`, 10/10 against
  the independent Salem public agent, and a two-seat `DONE` self-play smoke
  test. These are local screens, not ladder performance proof.
- Public LB: pending (submission 56075091)
- Agent: `submissions/prepared/PUB-001-tetsutani-shape-shop-pasture/submission.tar.gz`
- Tutorial: `notebooks/kaggriculture-competition-tutorial.ipynb`

## Live Snapshot (2026-09-07)

- Entered: yes (`dalloliogm`)
- Teams: 8,006
- Existing submissions: PUB-001, ref 56075091, initially pending
- Leaderboard leader: 2875.2 skill rating
- Kaggle authentication: access token confirmed

## Local Environment

Use the competition-local `.venv`, pinned to `kaggle-environments==1.32.7`.
Its Kaggriculture defaults match the official files downloaded on 2026-09-07.
The repository root `.venv` remains on the stale 1.29.3 engine and should not be
used for promotion tests.

## Prepared Candidate PUB-001

- Source: public notebook `tetsutani/shape-the-shop-work-the-pasture-kaggriculture`, version 11.
- Verified source score snapshot: 2494.7 on 2026-09-07.
- `main.py` SHA-256: `2b97e2c653018ac4aeffb8463ec91c8f26b097b4cef81289acc25ccdbc68f916`.
- Archive SHA-256: `ffaa5a43da5cf37c084c02a0c4e03eca9cb8ccb5766bbb9d2a4d3b0783e8017d`.
- Archive contents: exactly one root member, `main.py`.
- Submitted once on 2026-09-07 at 10:43:18 UTC as Kaggle ref 56075091.
- Initial status: `SubmissionStatus.PENDING`; no public score yet.
