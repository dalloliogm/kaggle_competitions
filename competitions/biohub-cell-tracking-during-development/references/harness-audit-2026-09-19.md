# Offline harness audit (2026-09-19)

Three defects, one repaired, one quantified, one contained.

## 1. REPAIRED - aggregate deltas over-credit changes that move few videos

Arm E was called validated on a paired bootstrap over all 24 held-out stems:
+0.00167, CI [+0.00032, +0.00354] excluding zero. It scored **0.944** against a
0.946 baseline.

Only **9 of the 24** videos are affected by the low-density bucket at all -
every one low-density - and the other 15 are exact ties. Bootstrapping over all
24 dilutes the sample with structural zeros, tightening the interval without
adding evidence.

`scripts/paired_sweep_analysis.py` now reports every comparison twice: the
weighted aggregate the competition metric computes, and paired statistics
restricted to the affected videos, with `n_affected` and win/loss in the same
row.

It immediately caught a second instance. `dmid700` topped the aggregate sweep
table at +0.0024 yet **loses on 9 of its 12 affected videos** - its positive
weighted delta is two high-weight wins masking nine losses.

### The check that matters

On both comparisons where the held-out harness and the leaderboard have each
spoken, the restricted test now agrees:

| comparison | restricted paired | public LB | agree |
| --- | --- | --- | --- |
| arm F vs tight55 | -0.00213 for tight55 | 0.947 > 0.946 | yes |
| arm E vs arm F | -0.00046 for arm E | 0.944 < 0.947 | yes |

The old aggregate method got the second backwards. The harness is repaired, not
differently wrong.

## 2. QUANTIFIED - `decompose_errors` counters are internally impossible

Across 24 stems under the selected config:

    t_pred                468,576
    t_true                589,730
    spurious_pred_nodes   453,693   (96.8% of predicted nodes)
    missed_gt_nodes           276

`missed_gt_nodes = 276` implies almost every ground-truth node was matched, and
`t_true > t_pred` means there are more ground-truth nodes than predicted ones -
so 96.8% of predicted nodes cannot simultaneously be unmatched. The two
counters are computed against different collections. They are **not usable for
decisions** and nothing here relies on them.

## 3. CONTAINED - the primary metric is internally consistent

The concern raised by (2) was whether `adjusted_edge_jaccard` - which drives
every decision - is computed over a suspiciously small edge set. Two checks:

* `edge_jaccard == tp/(tp+fp+fn)` holds on **24/24** stems, so the reported
  Jaccard is consistent with its own confusion counts.
* Density derived independently as `t_pred/100` predicts **exactly** which
  videos the low bucket moves: 9 videos under 120 cells/frame, 9 videos
  changed, identical sets. So `t_pred` is a node count and the density
  grouping used throughout is sound.

Whatever the absolute edge-set scale, every comparison here is **paired** -
same stems, same ground truth, differing only in configuration - so relative
rankings are valid even if the absolute denominator is a subset. That is
confirmed empirically by the leaderboard agreement in (1).

## Operational note

Kaggle output downloads are unreliable: `validator_results.csv` and kernel logs
repeatedly required 2-4 attempts. A single failed fetch looks exactly like a
file the kernel never wrote - one commit message today wrongly claimed the
CSV was missing when it was download lag. Retry before concluding a kernel
failed to produce something.
