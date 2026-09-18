# Density-adaptive relink: validated, and the sweep picked the wrong arm

## Result

Scored on 24 held-out videos, corrected (official) division rule, all candidates
on identical stems and identical cached predictions - so the comparison is
paired and run-to-run variance is removed.

Aggregate sweep table:

| config | proxy | adj edge | divJ | tp/fp/fn |
| --- | ---: | ---: | ---: | --- |
| densityfull (F) | 0.9263 | 0.9159 | 0.1042 | 5/14/29 |
| densitylow (E) | 0.9261 | 0.9155 | 0.1064 | 5/13/29 |
| tight55 | 0.9247 | 0.9138 | 0.1087 | 5/12/29 |
| base | 0.9226 | 0.9122 | 0.1042 | 5/14/29 |

On point estimates `densityfull` wins, and **the sweep selected it**. The paired
per-video analysis says that selection is wrong.

## Paired analysis (adjusted edge Jaccard, weighted as the official metric does)

| comparison | weighted delta | 95% CI (paired bootstrap, 20k) | win/tie/loss | leave-one-out range |
| --- | ---: | --- | ---: | --- |
| densitylow - tight55 | **+0.00167** | **[+0.00032, +0.00354]** excludes 0 | 7/15/2 | [+0.00110, +0.00192] |
| densityfull - tight55 | +0.00213 | [-0.00022, +0.00446] includes 0 | 15/3/6 | [+0.00158, +0.00251] |
| densityfull - densitylow | +0.00046 | [-0.00152, +0.00233] includes 0 | 8/12/4 | [-0.00022, +0.00080] |

**Arm E is real.** Its interval excludes zero, it loses on only 2 of 24 videos,
and no single video carries it - dropping the largest mover still leaves
+0.00110.

**Arm F is not distinguishable from zero.** Larger point estimate, but six
losses and swings of +0.0195 and -0.0160 on individual videos. Its interval
includes zero.

**The middle bucket adds nothing.** `densityfull - densitylow` is +0.00046 with
an interval straddling zero and a leave-one-out range that changes sign. All of
the effect is in the low-density bucket.

## Why the sweep chose wrong

`PP_CANDIDATES` selection compares point estimates only. It has no notion of
variance, so a noisy arm with a slightly higher mean beats a quiet arm with
solid evidence. Here it preferred `densityfull` (+0.0002 over `densitylow` -
pure noise) over the arm whose interval excludes zero. The selection rule is a
weakness worth fixing: it should require the *paired* improvement to be
distinguishable from zero, not merely larger.

## What this confirms

The prediction on 2026-09-18 was that the public notebook's mechanism is sound
but its constants are fitted to four movies, with the middle bucket (6.5, against
our sweep's 5.5) the most suspect. That is what the data shows: the physically
motivated low-density widening survives, and the middle bucket contributes
variance without signal.

It also vindicates holding arm E off the leaderboard. Its public score would
have read 0.946 within noise, because it only moves 45 rows inside the
lowest-weight video - and we would have concluded "no effect" and dropped a
change that is real.

## Carry into the private run

`densitylow`, **not** `densityfull`, despite what `ppsweep_selected.json` says.
