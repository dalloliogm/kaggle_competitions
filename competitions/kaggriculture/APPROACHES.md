# Approaches — Kaggriculture

Kaggriculture is a 2-player farming sim on `kaggle_environments`; submit a
`main.py` with an `agent(obs)` entry point. Score is the bank balance at the end
of a 30-day / 720-turn season, and the leaderboard is a rating ladder.

## Economics established from the rules (see `references/price_model.py`)

Selling drives a resource's price down its own curve; town shops and the town
centre drain inventory all season, which drives prices *up* for anything nobody
produces. Total revenue for dumping N units from the starting inventory:

| product | 50 u | 200 u | 800 u | price after 800 |
| --- | --- | --- | --- | --- |
| EGG | $2.2k | $8.5k | $32.2k | $38 |
| WHEAT | $1.1k | $4.3k | $16.2k | $19 |
| MELON | $12.1k | $26.5k | $27.1k | $1 |
| FERTILIZER | $4.8k | $16.0k | $25.4k | $1 |
| WOOL | $7.7k | $8.1k | $8.7k | $1 |
| MILK | $5.4k | $6.3k | $6.9k | $1 |
| CARROT | $1.5k | $4.8k | $10.6k | $2 |

So egg and wheat are the only volume-tolerant sinks; melon, fertilizer, wool and
milk are rich but small *pools*; carrot / tomato / strawberry sit on steep
scarcity curves (carrot and tomato use `hinge`) and climb to several times base
when nobody supplies the town.

## What was tried

1. **Fixed melon + large goose herd** (first working agent). Buy geese
   aggressively, grow/buy wheat to feed them, 12 melon tiles.
   ~$47k mean vs `starter`.
2. **Value-based scheduler.** Replaced arbitrary job priorities with dollar
   values (`value - distance * action_value`) plus a stickiness bonus so units
   stop oscillating between equally attractive jobs. Large win once the
   attendant bugs were out (see LEARNINGS.md).
3. **Herd sizing sweep.** Fewer animals is strictly better: 26 geese → $47k,
   16 → $64k, 8 → $69k, 4 → $69k, none at all → $28k. Animals are worth having
   for the fertilizer they drop for free (1/day each, fed or not), not for eggs:
   feeding daily costs a wheat, and importing wheat at herd scale walks its
   price from $25 to $65.
4. **Price-driven crop planner** (current). Each free tile is assigned to
   whichever crop maximises `(marginal revenue - seed) / days occupied`, valued
   after the units already growing will have hit the market. This makes the
   agent open with melon and rotate into carrot/tomato/wheat as melon crashes
   and town scarcity lifts the others. ~$80k mean vs `starter`.

5. **Feeding valued at what it returns.** An unfed animal still produces its
   base unit; feeding only buys the CARE bonus (one extra unit at the next
   tick). Valuing FEED at `product_price - wheat_price` makes the agent feed
   cows daily and geese only when they are about to starve. +3%.
6. **Dairy/wool herd** (current). Fixing the build-type deadlock (see
   LEARNINGS.md) made larger herds viable and completely changed the optimum:
   a cow cared for daily yields 3 milk every 2 days, and CARE pays a whole
   unit of product per action — milk and wool are the most valuable things a
   hand can touch, while an egg is the least. 12 cows / 6 sheep / no geese.
   ~$111k mean vs `starter`.

7. **Tuning in a contested market** (current, v4). Every result above was
   measured against `starter`, which sells almost nothing and so leaves the
   whole market to us. Re-running the sweeps with a frozen copy of v3 as the
   opponent changed the answer: 8 cows / 4 sheep beats 12 / 6, because a rival
   herd crashes the milk and wool pools much sooner than the town can drain
   them. v4 wins 22 of 24 position-balanced games against v3.
   The opponent's farm is public, so `opponent_weight` will price their
   growing crops and herd into our own supply curve — measured no better than
   ignoring it (50% at weight 0.5 vs 62% at 0), so it ships disabled.

## Submitted agents

| version | local vs `starter` (12 seeds) | notes |
| --- | --- | --- |
| v1 (56100155) | $80,157 | small herd, price-driven crops |
| v3 (56100666) | $111,100 | dairy herd, deadlock fixed; 16/16 head-to-head vs v1 |
| v4 (`submissions/main_v4.py`) | ~$100k | herd tuned against a real opponent; 22/24 vs v3 |

v1's real ladder episodes came in at $52k-72k against opponents scoring
$32k-92k (2 wins / 2 losses in its first four games), so the local numbers are
in the right league — but note that `starter` sells nothing, so playing it
overstates every score by roughly 2x versus a contested market. In self-play v3
scores ~$55k a side.

Current tuned parameters: `cows=12`, `sheep=6`, `max_geese=0` (caps only — the
mix inside them is chosen by `animal_value()` from live prices),
`struct_slots_ahead=12`, `wheat_crop_bias=0.8`, `min_crop_value=25`,
`action_value=30`, `feed_gain=1.0`, `max_quadrants=3`.

## Not yet tried

- Fertilizing crops was implemented and **rejected**: at `fertilize_gain` 0.3 it
  is worth +0.5% (noise) and at 0.4 it costs 30%, because fertilizer sells for
  more than the extra yield is worth. Left in the code, disabled by default.
- The third quadrant is worth buying, the fourth is not (`max_quadrants=3`).
- More than 13 farm hands loses badly: `fib(14..16)` = 377/610/987 a day.
- **Movement is 65% of every unit-turn** (8% is PASS, only 26% is productive
  work). Bigger wheat loads per shed trip, leaving idle hands in the field, and
  a smaller farm footprint were all tried and all came out even, so cutting it
  needs a real routing change — servicing a cluster of jobs per trip rather
  than re-deciding a single best job every turn — not another parameter.
- Top ladder opponents score $160k in games where we score $60k, so roughly
  half the achievable output is still on the table.
