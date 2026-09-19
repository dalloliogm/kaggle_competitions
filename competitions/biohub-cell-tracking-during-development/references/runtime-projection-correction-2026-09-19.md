# The runtime projection was wrong by ~2x (2026-09-19)

## Summary

Every projection since 2026-09-15 divided the whole pre-graph runtime by 4 and
multiplied by 199. Two of the phases in that sum are not per-video, so the
figures were inflated:

| build | claimed | corrected |
| --- | ---: | ---: |
| original quadratic relink | 15.09 h | **9.85 - 10.07 h** |
| KD-tree relink | 12.69 h | **7.30 - 7.52 h** |

The 12 h limit was never the binding constraint it was presented as. This drove
a week of work and framed the private outcome as "most likely no score at all".
That framing was wrong.

## Error 1 - the "association stage" does not exist

The silent 182-595 s gap between "Prediction completed" and the DeepCenter load
was labelled *association* and reported as 31% of per-video cost. Parsing the
notebook shows the window contains only:

    import tracksdata as td, numpy, blosc2, scipy.optimize, scipy.spatial
    import torch
    3 constant assignments
    class and function definitions

There is no association work in it. It is **module import time**, paid once,
independent of video count. Its 3.3x run-to-run variance is Kaggle filesystem
latency - which is why it correlates with setup time across 19 runs (fastest
run 203 s setup / 222 s imports; slowest 631 s / 595 s).

A public notebook independently reported this cause: *"Direct Path Resolution:
eliminates recursive FUSE glob() freezes on Kaggle drives (saving ~5.75
minutes)"* - 345 s, the same order as our variance.

## Error 2 - prediction has a fixed component

Model loading and GPU shard startup are paid once. Dividing a 4-video
prediction phase by 4 attributes a quarter of that startup to each video, then
multiplies it by 199.

## Solving it properly

The validator runs predict 24 held-out videos in addition to the 4 test videos,
which gives a second point on the same line:

    pred(4)  = fixed_p +  4m  =  575 s
    pred(24) = fixed_p + 24m  = 2781 s   (43.79 / 47.37 / 48.02 min, three runs)

    => marginal per video  m = 110.4 s
    => fixed overhead fixed_p = 133.3 s

Per-video cost is then `m + graph_per_video`:

| build | graph/video | per-video | projection |
| --- | ---: | ---: | ---: |
| KD-tree | 18.8 s | 129.2 s | 7.30 - 7.52 h |
| original | 65.0 s | 175.4 s | 9.85 - 10.07 h |

The range spans the fastest and slowest observed fixed cost.

## What still holds

* **The KD-tree rewrite is still worth having.** It removes a quadratic term,
  so a hidden sample larger than anything in our four test videos cannot
  detonate the budget. It also buys 2.5 h of margin. It was verified
  byte-identical, so it cost nothing in accuracy.
* **The deadline guard is still worth carrying.** It is verified inert
  (`deadline_degraded=0`, sha identical to arm F) and costs nothing when the
  run fits. With ~4.5 h of margin it is unlikely to fire, but the fixed cost
  varies 3x between sessions and the hidden set may be larger than 199.

## What changes

Runtime is no longer the binding constraint. Work aimed purely at speed -
profiling the (non-existent) association stage, cutting `EDGE_TTA views=8` at a
cost in accuracy - should stop. The remaining days are better spent on score,
where the division term still collects about one real division in seven.

## Method note

The error survived a week because every projection came from a single run with
no second point to constrain the intercept. Two points were available the whole
time in the validator logs. When extrapolating 4 samples to 199, fit the line
rather than scaling the average.
