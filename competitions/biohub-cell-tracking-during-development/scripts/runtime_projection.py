#!/usr/bin/env python3
"""Runtime projection for the ~199-sample private rerun, solved from two points.

## The modelling error this corrects

Every earlier projection divided the whole pre-graph runtime by 4 and multiplied
by 199, treating each phase as per-video. Two of those phases are not.

1. **The "association" block is module import time.** The silent 182-595 s gap
   between "Prediction completed" and the DeepCenter load contains only
   `import tracksdata / numpy / blosc2 / scipy / torch`, three constant
   assignments, and class and function definitions. No association work exists
   there. It is a one-time cost and does not scale with video count. Its huge
   run-to-run variance is Kaggle filesystem latency, which is also why it
   correlates with setup time.

2. **Prediction has a fixed component.** Model loading and shard startup are
   paid once, so dividing a 4-video prediction phase by 4 over-attributes them.

## Solving for the marginal

The validator runs predict 24 held-out videos in addition to the 4 test videos,
giving a second point on the same line:

    pred(4)  = fixed_p + 4m    ~ 575 s
    pred(24) = fixed_p + 24m   ~ 2781 s   (43.79, 47.37, 48.02 min)

so m is the true marginal cost of one video and fixed_p the startup.

## Why this matters

It is the difference between "the most likely private outcome is no score at
all" and a comfortable margin. The earlier figure drove a week of work.
"""
from __future__ import annotations

PRED_4 = 575.0                      # test-phase prediction, 4 videos
PRED_24 = (43.79 + 47.37 + 48.02) / 3 * 60   # validator prediction, 24 videos
N = 199

m = (PRED_24 - PRED_4) / 20.0
fixed_p = PRED_4 - 4 * m
print(f"marginal prediction per video : {m:.1f} s")
print(f"fixed prediction overhead     : {fixed_p:.1f} s")

for label, graph4, fixed_lo, fixed_hi in [
    ("KD-tree relink", 75.0, 203 + 222, 631 + 595),
    ("original quadratic relink", 260.0, 203 + 222, 631 + 595),
]:
    g = graph4 / 4.0
    lo = (fixed_lo + fixed_p + N * (m + g)) / 3600
    hi = (fixed_hi + fixed_p + N * (m + g)) / 3600
    print(f"\n{label}")
    print(f"  graph per video : {g:.1f} s")
    print(f"  per-video total : {m + g:.1f} s")
    print(f"  projection      : {lo:.2f} - {hi:.2f} h   "
          f"({'UNDER' if hi < 12 else 'OVER'} the 12 h limit)")
