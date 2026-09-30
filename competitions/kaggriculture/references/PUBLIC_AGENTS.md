# Public agents (final-day survey, 2026-09-30)

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
