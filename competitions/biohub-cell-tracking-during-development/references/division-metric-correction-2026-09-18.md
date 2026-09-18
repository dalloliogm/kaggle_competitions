# The division metric was reading double (2026-09-18)

## What was wrong

`compute_division_confusion` credited a ground-truth division whenever *any*
forking node shared a weakly-connected component with both daughter lineages.
`metrics.md` removed that route in commit `aa65e90` on 2026-07-17. The official
rule is local: the fork must be the matched parent or its immediate successor,
and the two daughters must be reached through two **distinct** direct-child
branches of that fork.

On a constructed graph with no fork anywhere near the real cell - the parent
continues into one daughter, the other daughter is a separate track, and a hub
outside the volume merges everything into one component - the old rule returned
a **true positive**. It would have scored the cheating exploit as a success.

## The corrected numbers, on the same 24 held-out videos

| | loose rule | official rule |
| --- | ---: | ---: |
| division Jaccard | 0.2308 | **0.1087** |
| inflation factor | | **2.12x** |

That independently reproduces the 2x a public notebook measured on its own
predictions (0.2500 -> 0.1250). Our local division figure was reading roughly
double for as long as we have been tuning against it.

Division confusion under the official rule, 24 videos, selected config:

    5 TP   12 FP   29 FN      recall 15%   precision 29%

We find about one real division in seven, and two thirds of the forks we do
emit are wrong. The headroom is real - the term is worth 0.1 - but nothing we
have tried so far collects it.

## The reassuring part: the banked configuration survives

The sweep still selects `tight55` (`MOTION_RELINK_TIGHT_UM = 5.5`) with the
corrected metric:

    base     adjusted edge 0.9122   division 0.1042   proxy 0.9226
    tight55  adjusted edge 0.9138   division 0.1087   proxy 0.9247   <- selected

The margin over base is +0.0021, the same as the +0.0020 measured under the
loose metric, and `tight55` improves *both* terms rather than trading one for
the other. So the 0.946 configuration was **not** an artifact of the broken
compass. This is direct evidence against the overfitting concern raised on
2026-09-08, and it is stronger evidence than before because the instrument
producing it is now the official one.

## What changed in how we should read local numbers

The corrected local proxy is **0.9247** against a public **0.946**. Previously
the local figure (0.9268-0.9290) sat just below public and looked reassuring;
with an honest division term the gap is wider, and it is wider for a
well-understood reason rather than an unexplained one.

## Open: a diagnostic counter that cannot be right

`ppsweep_results.csv` reports `spurious_pred_nodes` around 453,000 against
`missed_gt_nodes` of 276, on roughly 480,000 predicted nodes across 24 videos.
That would mean ~94% of predicted nodes are unmatched, which is impossible
alongside an adjusted edge Jaccard of 0.91. The `decompose_errors` counters are
therefore mis-scaled or accumulated across configs. They are **not** to be used
for decisions until that is traced; the Jaccard and TP/FP/FN figures above come
from a different code path and are unaffected.
