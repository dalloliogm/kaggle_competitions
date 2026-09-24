# Final submission selection

Deadline 2026-09-29 23:59 UTC. Fifteen submissions sit at public 0.947 and the
public board cannot separate them, so this is decided on held-out evidence and
on robustness, not on the public score.

**Open question:** how many submissions Kaggle lets you select for private
scoring here is not recorded in `COMPETITION.md` and should be confirmed on the
competition page before the deadline. The recommendation below assumes two.

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

## Recommendation

**1. `gap45+dlow800` (`e494d6de`).** The best-validated configuration on both
axes that matter: highest win rate (19 of 21 affected videos), and its gain is
not resting on one sample. Both components are independently supported by the
restricted paired test - gap45 at 15/2-16/0 across four separate runs, dlow800
at +0.00070 with a CI excluding zero - and they act on different stages, so the
combination was a real composition test rather than a lucky pairing.

**2. arm F (`fe6f0a6f`) as the hedge.** The simplest configuration and the one
with the most public evidence, scored 0.947 repeatedly across many days and
several distinct kernels. If the post-processing stack has an interaction that
behaves differently on the private distribution, this is the artifact least
exposed to it.

## Why not the others

- **`gap45` alone** looks safest on its 15/2 record, but **87% of its gain comes
  from one video**. That is the same failure mode as the 2026-09-18 error where
  an aggregate looked validated because a handful of samples carried it. A
  result resting on one sample is more likely luck than a transferable property.
- **`triple`** has the largest held-out delta and the least concentrated gain,
  which is a genuine argument for it. It is not recommended only because it
  carries `bonus125`, which is 7/12 on the videos it moves and whose own gain
  sits in 3 of 24 videos. Per-video deltas are additive to 2.9e-05, so the
  triple's 16/5 is inherited from gap45 and dlow800 - it is not evidence that
  bonus125 became reliable. **If the final selection allows three, add it**:
  the upside is real and the downside is bounded by the other two picks.

## What this is not

None of these differences is resolvable on the public board - every one reads
0.947, and the spread between them (0.0001 to 0.0014) is below its 0.001
quantisation. The honest summary is that we are choosing between four
configurations that are probably equivalent, on the best evidence available,
and the expected difference is small.
