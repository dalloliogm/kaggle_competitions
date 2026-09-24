# Final submission selection

Deadline 2026-09-29 23:59 UTC. Fifteen submissions sit at public 0.947 and the
public board cannot separate them, so this is decided on held-out evidence and
on robustness, not on the public score.

**Confirmed 2026-09-24: exactly two selections are allowed.** Kaggle scores
every selected submission privately and the final rank comes from the best of
them, so the second pick only earns its slot by being able to *beat* the first.

## The candidates

All four carry the KD-tree relink rewrite and the wall-clock deadline guard, so
all four are runtime-safe for the private rerun, and the guard's degraded path
was verified valid on 2026-09-23.

| candidate | sha | held-out weighted | W/L | top-1 share of gain |
| --- | --- | --- | --- | --- |
| arm F (SEP20-1) | `fe6f0a6f` | 0 (reference) | - | - |
| gap45 | `eace787d` | +0.00014 | 15/2 | **87%** |
| **gap45+dlow800** | `e494d6de` | +0.00083 | **19/2** | 61% |
| triple | `30e82e7c` | +0.00138 | 16/5 | 45% |

`top-1 share` is how much of the total positive contribution comes from the
single most-affected video. It is the number that changed the recommendation.

## Recommendation (revised once two selections were confirmed)

**1. `gap45+dlow800` (`e494d6de`), ref 56437708.** The best-validated
configuration on both axes that matter: highest win rate (19 of 21 affected
videos), and its gain is not resting on one sample. Both components are
independently supported by the restricted paired test - gap45 at 15/2-16/0
across four separate runs, dlow800 at +0.00070 with a CI excluding zero - and
they act on different stages, so the combination was a real composition test
rather than a lucky pairing.

**2. `triple` (`30e82e7c`), ref 56441396.** Highest held-out delta (+0.00138)
and the least concentrated gain (45% top-1 against 61% and 87%).

**arm F was the earlier second pick and is withdrawn.** The reasoning that it
hedged against a post-processing failure does not survive checking what the
configs actually differ by: arm F *is* the density-full configuration, so it
carries the same density-adaptive relink as the other two and differs only in
`GAP_CLOSE_UM` (5.0 vs 4.5) and `DENSITY_LOW_TIGHT_UM` (7.25 vs 8.0). Their
outputs differ by tens of rows out of 241,000. It is a near-duplicate of pick 1,
not a different bet, and under best-of-selected scoring a pick that cannot beat
the other one is a wasted slot.

The residual risk of this pair is that both carry gap45 and dlow800, so a
systematic failure of either would take both picks down. That risk is accepted:
those are the two changes with the strongest held-out support, and arm F would
only have covered it by giving up all measured upside.

## Why not the others

- **`gap45` alone** looks safest on its 15/2 record, but **87% of its gain comes
  from one video**. That is the same failure mode as the 2026-09-18 error where
  an aggregate looked validated because a handful of samples carried it. A
  result resting on one sample is more likely luck than a transferable property.
- **`triple`** carries `bonus125`, which is 7/12 on the videos it moves and
  whose own gain sits in 3 of 24 videos. Per-video deltas are additive to
  2.9e-05, so the triple's 16/5 is inherited from gap45 and dlow800 - it is not
  evidence that bonus125 became reliable. That argued against it as a *sole*
  pick. As the second of two under best-of-selected it is the right choice
  anyway: its downside is bounded by pick 1, which contains it minus bonus125,
  so the only thing it can cost is the slot itself.

## What this is not

None of these differences is resolvable on the public board - every one reads
0.947, and the spread between them (0.0001 to 0.0014) is below its 0.001
quantisation. The honest summary is that we are choosing between four
configurations that are probably equivalent, on the best evidence available,
and the expected difference is small.
