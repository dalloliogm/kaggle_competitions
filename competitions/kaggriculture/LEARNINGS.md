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

## Ladder calibration (2026-09-08)

- A new submission enters at rating 600 and moves slowly, so the first score
  reading says nothing. v1 read 578 while actually going 5-5 in its first ten
  episodes.
- v1's real opponents scored $17k-$163k against it; the previously submitted
  public agent (rating 2191) scored ~$57k in a head-to-head with v1's ~$58k.
  So roughly $60k is mid-field and the top of the ladder is producing ~$160k.
- Only 4 CPUs are available in this session: running benchmarks with `--jobs 14`
  is slower than `--jobs 4` and leaves orphaned processes that poison later
  sweeps. Keep parallelism at the core count.

## Reading the ladder's replays (2026-09-09)

Replays of the opponents who beat v4 are the most useful tuning signal
available — they contain both farms' full tile state at every step, so the
winners' strategy can be read directly:

```
kaggle competitions episodes <submission_id> -v   # episode ids
kaggle competitions replay <episode_id> -p ./r    # full replay JSON
# steps[i][0]['observation']['farms'][player] -> tiles, money, hands
```

That is how the two pricing bugs above were found: the winners' farms were
full of strawberry while ours stood a third empty.

Things measured and rejected today (all roughly neutral against a v4 opponent,
kept in the code where harmless):

- Grouping jobs by tile so a unit is sent to the best *cluster* of work rather
  than a single job. Movement stayed at 64% — most crop tiles only ever have
  one pending job, and animal tiles already got consecutive turns for free.
- More than 13 farm hands, again: still 0/10, the fib hire cost eats the cash
  the early herd needs.
- Pricing the opponent's visible production into our own supply curve
  (`opponent_weight`): 50% at 0.5 against 62% at 0.

## Selling and feeding (2026-09-09, second pass)

- **Holding harvests for a better price loses.** The town's drain does lift the
  price of everything it consumes, so waiting genuinely sells higher — but
  every variant tried (2-5 day look-ahead, 2-15% required gain) came out behind
  selling on sight. Cash compounds: proceeds today buy the animal or the seed
  that earns for the rest of the season. Left in the code as `hold_days`,
  defaulted to 0.
- **The wheat purchase ceiling never binds** at a 12-animal herd, so making it
  scale with the herd's product price (`feed_price_share`) changed nothing. It
  only mattered for the big herds, which fail for other reasons.
- **The feed buffer was the real constraint.** Keeping two days of wheat per
  animal meant the herd went unfed whenever the town pushed wheat prices up:
  animals lose their banked CARE bonus on an unfed production day, and hands
  waste turns walking to an empty shed. Four days is worth ~7% and 20/24 games.
  Six days is too much - it ties up cash and shed space.

## Only the newest submissions actually play (2026-09-09)

Episode counts stop growing on older submissions: v1 froze at 15 episodes, v3
at 38, v4 at 44 while v5 (32) and v6 kept accruing. So a new submission does
not add to the pool — it *displaces* the previous one from active play, and
starts over at rating 600. Submitting anything that is not a measured
improvement therefore costs the ladder position of the agent it retires. This
is what dropped the team from rank 751 to ~4500 on day one.

## Both-sides benchmarking is mandatory (and the harness was lying)

`bench.py --both-sides` swapped the *parameter overrides* along with the seat
order, so the reversed half of every parameterised comparison silently ran
default-vs-default. The tell was identical "R" rows across three different
configs. Fixed: swap the seats only, since each agent file reads its own env
var. Any one-sided sweep result is also unreliable for near-identical agents —
`c6s3` looked like a +$5k improvement one-sided and lost 3/20 when measured
properly, because each variant plays a *different* game against the opponent.
Ties also deflate the win column: identical agents produce exact ties.

## Rejected today (all measured both-sides against v6)

Smaller herd (6 cows/3 sheep), larger herds (12-24), 4 quadrants, 15-16 hands,
higher cash reserve, faster seed buying, higher plant urgency, late weed
clearing, holding harvests for scarcity, herd-scaled wheat price ceiling, and
the winners' full configuration as a combination (4 quadrants + 16 hands + 24
animals: 0/20, mean $26k against $81k). Our scheduler simply cannot run a farm
that size — that is an execution limit, not a parameter choice.

## Movement is not waste (2026-09-10)

The standing theory was that ~65% of unit-turns going to movement was the big
remaining inefficiency, and that routing hands to work a cluster before moving
on would nearly double productive work. Zone routing was built to test it: a
unit claims a block of tiles and works everything in it before moving on.

It cuts movement exactly as intended, and income falls monotonically with it:

| zone size | movement | reward (seed 3, vs starter) |
| --- | --- | --- |
| off | 67% | $132.0k |
| 2 | 60% | $122.4k |
| 3 | 47% | $88.3k |
| 4 | 26% | $74.2k |
| 5 | 13% | $12.7k |

Distance is a proxy for value here: the far tiles are the crops that pay, the
near ones are the animals. Confining a unit to a block makes it do cheap work
nearby instead of expensive work across the farm, and `value - distance *
action_value` was already making that trade correctly. Both-sides against v6,
`zone_size=2` scores 9/20.

The corollary was also tested and also false. An animal visit buys four actions
(feed, care, harvest, collect) while a crop tile buys one, which argues for
crops near the shed and livestock pushed out. Measured: 0/20. Animals need the
shed too - that is where their wheat comes from - so moving them out just adds
a feed round-trip.

Both mechanisms are left in the code, disabled (`zone_size`, `structures_far`),
because the negative result is the useful part.

## Why big herds actually fail

Not routing. Capital. At day 12 a 16-animal farm has $262 in the bank and 36
plants; the 8-cow farm has $10,932 and 58 plants. Livestock at $400-500 a head
crowds out the strawberry seed that funds everything, and the crop engine never
starts. By day 16 the big farm holds 22 animals, zero wheat, 22 of them unfed,
and spends 87% of its turns walking because there is nothing it can afford to
do. The labour budget then makes it worse: `crop_capacity` charges 7 actions a
day per animal, so a big herd caps the crop plan at ~27 tiles by construction.
