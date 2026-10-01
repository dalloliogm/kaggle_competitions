# Public agents survey (2026-09-30, extended 2026-10-01)

All of these are public Kaggle notebooks under Apache-2.0 with upstream
attribution chains retained in the file headers. `tools/extract_notebook_agent.py`
recovers `main.py` without executing the notebook: the agent is shipped as a
base85 (occasionally base64) tar.gz assigned to a variable, usually as many
implicitly-concatenated string chunks, sometimes gzip and sometimes lzma. Where
the notebook publishes an `EXPECTED_MAIN_SHA256`, the extractor verifies it.

| notebook | vs `starter` (seed 3) | head-to-head | usable |
| --- | --- | --- | --- |
| tetsutani/demand-preserving-turn-sale-timing (step1009) | $182,013 | **beats thomastschinkel 20/20** | yes, sha verified |
| flexonafft/kaggriculture-multi-route-farming-agent | $182,013 | ties tetsutani every game (same lineage) | yes |
| thomastschinkel/the-2945-farm-96-vs-the-top-10-public-bots | $180,735 | loses 0/20 to tetsutani | yes |
| ahmedberatozer/kaggriculture-v38 | $184,270 | loses 0/16 to thomastschinkel | yes |
| kaitofukami/40-40-early-floor-v48-fast-routes | $186,825 | **loses 0/20 to tetsutani** | yes |
| leoprovorov/a-song-of-ice-and-fire (MarketShock-M1-WR1K) | $3,000 | n/a | no - imports but no-ops; needs its package siblings |
| guruprasaathas111/master-engine-v3, abhinav0370/cha22 | $3,000 | n/a | no - partial extraction |

Two lessons, both of which we had already learned the hard way about our own
agents and which apply here too:

- **The score against `starter` does not rank agents.** kaitofukami scores the
  highest of any agent tested against `starter` ($186,825) and loses every
  single game to tetsutani. Only head-to-head counts.
- **A broken agent scores $3,000** (the starting bank) because
  kaggle-environments swallows agent exceptions. Always smoke-test an extracted
  agent before submitting it; $3,000 is the tell.

## How these compare to our own agent

Our best hand-built agent (v6) scores ~$132k against `starter` where these
score $180k+, and its ladder rating settled at 600.5 against 2191 for the
public agent we submitted on day one. The public lineage is simply far ahead:
these files are 1,200-10,000 lines with month-long collaborative attribution
chains (thomastschinkel, yhay81, destbreso, aurax7, tetsutani, prvsiyan,
Dmitrii Gluzdov, Ahmed Berat Ozer and others).


## Second survey, 2026-10-01 (deadline extended to Oct 14)

The public lineage puts out new versions daily, so this is worth re-running
before each submission. Measured against `pub_tet` (tetsutani step1009), the
agent that reached 1595.9 on the ladder:

| notebook | vs `starter` (seed 3) | both-sides vs tetsutani step1009 |
| --- | --- | --- |
| leoprovorov/a-song-of-ice-and-fire-**final-update** | $182,019 | **wins 18/20** |
| guruprasaathas111/game-theoretic-master-discrete-optimization | $182,013 | byte-identical to flexonafft (same lineage) |
| evgendvorkin/kaggriculture-version-31-26-09 | $181,858 | loses 4/20 |
| haideptry/the-shepherds-ledger-herd-safe-sovereign | $180,770 | not run (lower solo score) |

`leoprovorov/a-song-of-ice-and-fire-final-update` is the current best: 18/20,
193ms/turn worst case, stdlib only. Staged at `agent/n_leo.py` and
`submissions/public_leoprovorov_songofice_final.py`. Note the *earlier*
leoprovorov notebook extracted to a no-op ($3,000) because that version ships a
multi-file package; the final-update version is a self-contained main.py.

Margins between these agents are tiny (0.2% on mean) but consistent across
seats, so head-to-head win counts are the only usable signal.

## Replay corpora available for the playbook's step 5

`docs/kaggle-simulation-competition-playbook.md` says to check for these before
committing to a heuristic path. They exist, in quantity:

| dataset | size | notes |
| --- | --- | --- |
| georgymamarin/kaggriculture-episodes | 29.9 GB | 34k downloads; full episodes |
| ashok205/kaggriculture-top10-replay-archive | 3.96 GB | daily top-10 |
| destbreso/kaggriculture-benchmark-matchups | 492 MB | replayable benchmark |
| vijaikm/kaggriculture-match-replay-corpus | 1.9 MB | 537 matches already parsed to action CSVs, curated for behavioural cloning |

The vijaikm corpus holds `matches_meta.csv` (teams, both scores, winner, margin),
`farmer_actions.csv` and `market_orders.csv` (250k rows each,
`episode_id, step, day, player, verb, item, qty`) plus town shop schedules. It
carries actions but not observations, so behavioural cloning on it needs the
state reconstructed by replaying, or the full 30 GB episode set.

This session has 4 CPUs, no GPU, 15 GB RAM and 27 GB free disk, and agents must
act in under 1s/turn — so replay *mining* (measuring what strong agents do by
day and porting those decisions) fits the constraints far better than training a
policy network, whose ceiling is its teacher anyway.
