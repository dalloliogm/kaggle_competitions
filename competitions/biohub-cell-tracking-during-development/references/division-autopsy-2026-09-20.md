# Division autopsy: the misses are reachable (2026-09-20)

## Why this was run

Division recall never moved once, across six configurations tried between
2026-09-14 and 09-19 - base, tight55, densityfull, densitylow, dlow800,
dlow650. Every one scored **TP = 5, FN = 29** on 34 ground-truth divisions in
24 held-out videos. Only the false-positive count moved (12-14). Meanwhile the
safe-division machinery adds ~400 forks across those videos to convert 5.

Gate-constant tuning cannot reach that, and opening the gates outright
(2026-09-17) scored 0.917-0.925 against 0.946. So rather than propose another
fix, this attributes every miss to the stage that lost it.

## Result

| stage | n | share |
| --- | ---: | ---: |
| `no_second_child` | 20 | 58.8% |
| `daughter_undetected` | 8 | 23.5% |
| `true_positive` | 5 | 14.7% |
| `parent_undetected` | 1 | 2.9% |

**The division term is not a detection problem.** Only 9 of 34 (26.5%) are lost
because a node was never detected or matched. In **20 of 34 (58.8%)** the
parent and both daughters are detected and matched within the 7 um radius, and
the predicted parent simply never acquires a second child.

## The addressable subset is narrower still

Geometry of the 20 misses against the gates actually in force:

| | parent -> 2nd daughter | sister separation |
| --- | --- | --- |
| missed, n=20 | min 0.18, median 3.85, max 12.22 um | min 5.76, median 10.40, max 15.43 um |
| found, n=5 | min 3.80, median 4.93, max 6.33 um | min 6.78, median 7.57, max 8.57 um |

Against `SAFE_DIV_MAX_UM = 9.0` and `SAFE_DIV_SISTER_MAX_UM = 14.0`:

    pass parent gate   14 / 20
    pass sister gate   18 / 20
    pass BOTH          13 / 20

So **13 of the 20 are already geometrically eligible**. They are not refused by
the distance gates. Something else rejects them - divergence, symmetry,
mutual-NN, the DeepCenter veto, the per-frame or global cap, or they are never
proposed as a candidate pair at all.

The found divisions occupy a tight envelope that the missed ones overlap
heavily, so the two populations are not separable on distance alone. That is
consistent with the 2026-09-17 failure: widening the gates globally took the
candidate pool from 730 to 4,887 and made the score worse, because the extra
candidates were duplicates rather than divisions.

## What it is worth

If all 13 geometry-eligible misses were converted without adding false
positives, TP goes 5 -> 18 of 34 and division Jaccard goes 5/48 = 0.104 to
18/48 = 0.375. At the 0.1 metric weight that is **+0.027**, which would take
0.947 to roughly 0.974. Half of them is still +0.013.

This is the largest quantified opportunity found in the competition. Every
gate-tuning experiment of the past week has been worth 0.000 to 0.001.

## Next, and deliberately not yet

Which specific filter kills each of the 13 is not yet known - the autopsy
records per-video rejection counters, not per-division attribution. The next
run traces each ground-truth division through the safe-division proposal loop
and records the exact test that refused it.

Only then is there a case for changing anything. The runtime work established
what it costs to optimise a stage before confirming what it does.

## Method note

The v1 autopsy died with `FileNotFoundError` on `test/44b6_12dfb391.zarr` - a
train stem resolved under the test directory, because DeepCenter reads frames
through `TEST_DIR` and the appended cell omitted the `TEST_DIR = TRAIN_DIR`
swap that `score_validator_config` performs. Only the appended cell failed, so
the run's sweep output survived and incidentally confirmed the harness is
deterministic: its `base` and the previous sweep's `densityfull` are the same
configuration and scored bit-identically (proxy 0.92628, adj 0.91586).
