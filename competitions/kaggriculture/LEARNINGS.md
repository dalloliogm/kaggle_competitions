# Learnings — Kaggriculture

## Environment mechanics that are easy to get wrong

- `FEED` takes wheat from the **acting unit's inventory**, not the shed. Units
  must `PICKUP WHEAT n` at a shed-access tile first.
- `SELL` sells from the **shed** only; harvested goods sit in unit inventories
  until dropped, and the shed caps at 100 items (overflow at the end-of-day drop
  is discarded). `BUY_PRODUCT` and `BUY_ANIMAL` also fail when the shed is full.
- Only `maxMarketOrdersPerTurn` (10) orders are processed per turn. Queueing a
  SELL for every product silently starves the buy orders — this alone kept the
  first agent from ever restocking wheat or buying land.
- An animal produces its base unit whether or not it was fed; `CARE` banks +1 per
  fed-and-cared day, paid out at the next scheduled production. Fertilizer is
  produced by every surviving animal daily regardless of feeding or caring.
- A plant dies after two consecutive unwatered days, and a fresh planting starts
  at `consecutive_unwatered = 1`, so it must be watered the day it goes in.
  Outside the yield-bonus window, watering every *other* day is enough, which
  cuts crop labour by about a third.
- Yield only rises from watering inside the bonus window
  (`ceil(max_yield_day/2) .. max_yield_day`), capped at `max_yield`
  (unfertilized: wheat 4, carrot 3, melon 6 by age 10).
- `episodeSteps=720`, `actTimeout=1` second per turn. The agent runs at ~0.8ms
  per turn, so the scheduler has plenty of headroom.

## Debugging

- kaggle-environments **swallows agent exceptions** and substitutes a default
  action, so a crashed agent looks like a very passive one. `agent/smoke.py`
  calls the agent directly; a flat-money trace is the tell.
- Agent `print()` output is captured, not shown. `agent/main.py` writes a
  per-turn trace to a file when `KAG_TRACE=<days>` is set; that trace is what
  exposed the two big bugs below.
- Run one episode per process (`agent/run_match.py`): variants that share module
  state contaminate each other inside one interpreter.
- Single seeds are far too noisy to tune on — the same config ranged $65k-$91k
  across ten seeds. Use `agent/sweep.py` (6-10 seeds, ~10s for six episodes).

## Bugs worth remembering

- **Shed deadlock**: a unit standing at the shed that "wants an animal" but has
  no *matching* free structure fell through an `elif` chain to a no-op, then to
  a walk-to-shed that resolved to `PASS` because it was already there. Every
  unit passed for entire days. Always check that a fallback cannot resolve to a
  zero-length move.
- **Priority scale vs distance**: scoring jobs as `priority*5 - distance` made a
  single priority point outweigh five tiles of walking, so units crossed the
  farm for marginally better jobs and thrashed. Scoring in dollars, with
  distance charged at the value of a unit-turn, fixed it.
- Buying livestock faster than coops could be built left 15 geese ($4.5k) parked
  in the shed all game. Buy against structures that already exist.

## Strategy findings

- **CARE is the highest-value action in the game for pasture animals.** The
  banked bonus pays one whole extra unit of product at the next scheduled
  yield, so a cared-for cow yields 3 milk every 2 days. At $200-300 a unit that
  is far better than anything a crop tile returns per action.
- **Eggs are the worst.** A goose fed and cared for daily produces 2 eggs (~$80)
  for a wheat and three actions, and importing wheat at herd scale walks its
  price from $25 to $65. Geese are worth zero in the tuned config; their only
  merit is the fertilizer every animal drops for free.
- **The town is a price pump.** Shops and the town centre consume products all
  season. Anything nobody produces climbs its scarcity curve — carrot and
  tomato use `hinge` and reach several times base — so the profitable crop
  changes as the season runs and should be chosen from live prices.
- Melon opens at $250 but the pool is only ~150 units before the floor.
- `starter` sells almost nothing, so benchmarking against it overstates results
  by roughly 2x: the same agent scores ~$111k against `starter` and ~$55k a
  side in self-play. Always confirm a change head-to-head as well.
