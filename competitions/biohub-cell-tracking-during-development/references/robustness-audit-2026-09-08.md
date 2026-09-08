# Robustness audit of the 0.946 result - 2026-09-08

Question: is `0.946` (submission `56075335`, rank ~#67/3238, silver) robust, or
is it fitted to the public leaderboard?

This matters here for a specific reason. In July a **165-team cluster at
`0.950` was hack-inflated and collapsed on rescore** toward `~0.877`. Our
`0.946` sits in a **119-team cluster** and came from a public notebook. Same
shape. So the cluster is not evidence either way and the artifact has to be
checked directly.

## 1. The artifact was not tuned by us against the leaderboard

`0.946` is a **byte-identical reproduction** of `redoctopusk/biohub-942tta` v1
(sha `a852d1d0...795b3e`, recorded in
`references/sep07-public-reproduction-execution.json`). No configuration choice
in it was made by us against the public LB, so the usual overfitting-by-probing
mechanism does not apply on our side. The risk that remains is inherited: the
public author may have fitted it, and 119 teams share the exposure.

## 2. Source audit - no exploit patterns

Scanned the public source (12 cells, 203k chars):

| pattern | hits |
| --- | ---: |
| dataset-id branching (`44b6`/`6bba`) | **0** |
| hardcoded dataset names | **0** |
| hub node / fake-fork metric hack | **0** |
| per-movie constant table | **0** |
| negative timepoints | 1 - the required `"t": -1` for unused edge-row fields |
| ground-truth `.geff` reads | 11 - all in the LOCAL validator |

The ground-truth reads deserved a closer look and came back clean: they select
validation videos from `TRAIN_DIR` and explicitly exclude any stem that also
appears in `TEST_DIR` (`candidates = [s for s in train_stems_all if s not in
test_stem_set]`). Division-bearing videos are chosen by computing out-degree on
each candidate's own GT graph, not from a hardcoded list. Nothing from the
ground truth reaches the submission.

## 3. Held-out evidence from the run's own validator

The pipeline scores itself on held-out TRAIN videos with the official metric.

| measure | value |
| --- | ---: |
| weighted adjusted edge Jaccard | `0.9261` |
| division Jaccard (micro) | `0.2308` |
| **local score** | **`0.9492`** |
| **public LB** | **`0.946`** |

Local sits `+0.003` above public. That is the ordinary direction - train-adjacent
data scoring slightly high - and **not** the local-much-greater-than-public
signature of an overfitted artifact.

**Per embryo**, which is the closest available proxy for the hidden test being
embryo-disjoint:

| embryo | n | score |
| --- | ---: | ---: |
| `44b6` | 4 | `0.9534` |
| `6bba` | 4 | `0.9431` |

A `0.010` gap, with no collapse on either. A pipeline tuned to one embryo's
appearance would not behave this evenly.

**Across 8 post-processing configs** the total spread is `0.0030`, so the result
is not balanced on a knife-edge setting.

## 4. The score is earned by tracking, not by the node-count penalty

This is the strongest single piece of evidence. The metric multiplies raw
Jaccard by `1 - 0.1*(N_pred - N_true)/N_true`, so a result can be inflated by
calibrating node counts rather than tracking well.

| | |
| --- | ---: |
| weighted RAW edge Jaccard | `0.9232` |
| weighted ADJUSTED edge Jaccard | `0.9261` |
| **net node-count multiplier** | **`1.0032`** |

The multiplier contributes **0.3%**. The score is essentially all raw tracking
quality. Per-video node ratios range `0.713` to `1.360`, yet because the penalty
is only `0.1x` the relative error, even the worst video's `+36%` over-prediction
costs `3.6%`. **Density differences on unseen embryos are therefore bounded to a
few tenths of a percent** - a quantified limit on the main generalization risk.

Divisions point the same way: the submission contains **102 divisions**, below
the ground-truth-implied `~139` and far below the `456` our own Exp227 emitted.
Local division counts are `3 TP / 1 FP / 9 FN` - under-calling, not fabricating.

## 5. What is NOT established

- **The sample is small.** Eight videos, and a bootstrap over them gives a 95%
  interval on adjusted edge Jaccard of **`[0.8815, 0.9709]`**, about `+-0.045`.
  The public score sits at the 79.9th percentile of that distribution. The
  agreement is consistent with robustness; it does not prove it.
- **Held-out video is not held-out embryo.** All 8 come from the same two
  embryos the models were trained on, and the 08-17 scan established that videos
  within an embryo are overlapping crops that share annotated cells. Genuine
  unseen-embryo generalization **cannot be measured from the data we have**.
- **Public-vs-private split** within the hidden test is unknown, so
  public-to-private transfer is unmeasured.

## 6. In flight

`dalloliogm/biohub-sep08-robustness-wide-validation` raises
`BIOHUB_VALIDATOR_N_PER_TYPE` `4 -> 12`, giving **24 held-out videos** instead of
8, with the tracking pipeline untouched. It should tighten the interval by
roughly `sqrt(3)`, give a 12-vs-12 per-embryo split, and put more ground-truth
divisions in view than the 13 events the current estimate rests on. The
submission output should stay byte-identical to the scored artifact, which
doubles as a correctness check on the edit. No submission slot.

## Verdict so far

No evidence of leaderboard overfitting, and one positive result that is hard to
fake: the score survives decomposition into raw tracking quality with a
negligible node-count multiplier. The open question is precision, not honesty -
the estimate rests on 8 videos, and that is what the wider run addresses.
