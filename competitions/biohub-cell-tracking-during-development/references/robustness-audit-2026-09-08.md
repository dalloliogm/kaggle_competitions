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

## 5. The public leaderboard is a weaker instrument than it looks

This turned out to be the most consequential finding, and it partly inverts the
question.

**The graded movies are four, and we have ground truth for them.** The
submission covers exactly `44b6_0113de3b`, `44b6_0b24845f`, `6bba_05b6850b`,
`6bba_05db0fb1`. Those are the same stems this workspace's own harness scores
against ground truth (`LEARNINGS.md` carries their per-movie TP/FP/FN and node
counts), and the 08-17 public scan found the visible `test/` volumes to be
copies of train volumes. So the data the public leaderboard scores has
available labels - for us and for every other competitor.

**And the score is concentrated in two of them.** The official metric
weight-averages by `TP+FP+FN`, and `LEARNINGS.md` records the split:

| movie | share of public score |
| --- | ---: |
| `6bba_05db0fb1` | **56.1%** |
| `6bba_05b6850b` | **37.4%** |
| the three `44b6` movies | ~2.2% each |

**93.5% of the public leaderboard comes from two movies.** A public score is
therefore close to an `n = 2` measurement taken on data whose labels are
obtainable. That makes it both easy to fit deliberately and noisy by nature -
which is the real reason a 119-team cluster at one value should not be taken at
face value, and why the July `0.950` cluster could collapse the way it did.

**Why our artifact is not exposed to this.** The notebook's validator selects
its held-out videos from `TRAIN_DIR` while explicitly excluding every stem that
appears in `TEST_DIR`. Its post-processing config was therefore chosen against
videos that are *not* the graded ones. That safeguard looked like ordinary
hygiene on first reading; given the above it is the single thing that separates
this artifact from one fitted to the four graded movies.

**Consequence for how we evaluate from here.** Our own 24-video held-out
validation is arguably a *better* generalization estimate than the public
leaderboard, because it averages over three times as many videos and none of
them are the graded ones. Where the two disagree, the wider local estimate
deserves at least equal weight.

**One thing genuinely unresolved:** whether the private leaderboard is a
disjoint split *within* these four movies, or a hidden set swapped in at rerun.
The 08-17 scan reported the latter; this competition also accepts CSV uploads
and was rescored server-side in July, which fits the former. The implication
differs - a within-movie split would transfer well, a swapped unseen-embryo set
much less so - and we cannot currently tell which. The competition pages are
JS-rendered and not retrievable through the API, so this needs a human to read
the Data/Evaluation tab.

## 6. What is NOT established

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

## 7. In flight

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

---

# UPDATE - the official Dataset Description resolves the split, and exposes a bigger risk

The competition's Dataset Description settles what section 5 left open, and the
answer moves the main risk somewhere else entirely.

## The split, resolved

> "Train and test sets are embryo-disjoint — no embryo appears in both."
> "test/ - Example test samples (copies from train)... When a notebook is
> submitted for rerun, a new hidden test set is swapped in. **The size of the
> hidden test set is approximately the same size as the training dataset.**"

So:

- The **public** score is computed on 4 visible movies that are copies of train,
  93.5% of the weight on two of them. Confirmed as an `n≈2` measurement on data
  whose labels everyone has. Its value as evidence is close to nil.
- The **private** score comes from **re-executing the kernel** on a hidden set of
  roughly **199 samples** from **unseen embryos**.

Our submissions do go through the code path (`competitions submit -k <kernel>
-v <version>`), so they are kernel submissions and are eligible for rerun. That
part is fine.

Two consequences. Good: with ~199 samples instead of 4, private-score *variance*
will be far lower than public. Bad: unseen embryos mean domain shift that no
validator built from train data can measure, since every train video comes from
the two embryos the models were fitted on.

## The risk that actually threatens the result: RERUN TIMEOUT

Phase timings from the scored `0.946` run (`2x T4`, prediction already sharded
across both GPUs):

| phase | wall clock | scales with test size? |
| --- | ---: | --- |
| setup, install, model load | 12.3 min | no |
| test-set prediction, 4 videos | 9.6 min | **yes** |
| tracking, post-processing, audit, 4 videos | 21.8 min | **yes** |
| held-out validator, 8 train videos | 62.4 min | no (removable) |
| **total** | **106.1 min** | |

Test-side cost is **7.84 min per video**. Projected at rerun:

| hidden videos | projected wall clock | 12 h limit |
| ---: | ---: | --- |
| 100 | **14.3 h** | OVER |
| 199 | **27.3 h** | OVER |

Even with the validator disabled, the budget allows only about **90 videos**.
The Dataset Description implies roughly **199**.

**On this arithmetic the kernel does not finish at rerun, and a kernel that does
not finish scores nothing on the private leaderboard.** That would make the
public `0.946` irrelevant regardless of how well it generalizes - which is a
larger threat to the result than any amount of leaderboard overfitting.

**Independent corroboration.** In the `focus3d` forum thread, one competitor
reports "I tried to use focus-3d to segment cells, but **it timed out when
submitting**", and another asks whether an approach "fits under kaggle 12 hour
window run". Rerun timeout is a live, known failure mode in this competition,
not a theoretical one.

## Where the time goes, and what to do

Of the 31.4 min of test-side work on 4 videos, prediction is 9.6 (30%) and
**tracking plus post-processing is 21.8 (70%)**. The bottleneck is the graph
stage, not the U-Net.

1. **Disable the validator in any submitted kernel**
   (`BIOHUB_VALIDATOR_ENABLE=0`). Saves 62 min. Necessary, nowhere near
   sufficient, and it costs nothing since the diagnostic belongs in a separate
   run.
2. **Measure before optimising.** The 7.84 min/video figure is an average over
   four videos whose node counts differ by 11x (`6bba_05db0fb1` has 70,301
   nodes, `6bba_05b6850b` 6,150). If cost is driven by node count rather than
   video count, the projection needs redoing against the hidden set's expected
   density, and could be better or worse than linear.
3. **Then attack the graph stage**, which needs roughly a 2.2x speedup at
   N=199.

## Revised verdict

On the original question - is `0.946` fitted to the public leaderboard? - the
evidence says no: it was not tuned by us, its config was selected against videos
excluding the graded ones, it carries no exploit patterns, and it decomposes
into raw tracking quality with a negligible `1.0032` node-count multiplier.

But that question turns out to be secondary. The public score is an `n≈2`
measurement on fittable data, and the private score depends on a rerun that,
on current timings, **will not complete**. Robustness work should move to
runtime before it moves anywhere else.

---

# UPDATE 2 - the widened validation CORRECTS the earlier reading

The 24-video run finished. First, a methodological control: its `submission.csv`
sha is `a852d1d07ff8c930...`, **byte-identical to the scored `0.946` artifact**,
confirming the only change was the validator width and the pipeline is untouched.

| | 8 videos (earlier) | **24 videos** |
| --- | ---: | ---: |
| weighted RAW edge Jaccard | 0.9232 | **0.9088** |
| weighted ADJ edge Jaccard | 0.9261 | **0.9122** |
| node-count multiplier | 1.0032 | **1.0038** |
| division Jaccard | 0.2308 (13 events) | **0.1458** (48 events: 7 TP / 14 FP / 27 FN) |
| **local score** | 0.9492 | **0.9268** |
| bootstrap 95% CI on adj J | [0.8815, 0.9709] | **[0.8797, 0.9407]** |
| CI width | 0.0894 | **0.0609** |

## The earlier "local ≈ public" reading does not survive

On 8 videos the local score was `0.9492` against a public `0.946`, and section 3
read that as reassuring agreement. **On 24 videos the local score is `0.9268`,
and the public `0.946` now sits ABOVE the upper bound of the local 95% interval
(`0.9407`).** The gap is about `0.019` and is no longer explainable as sampling
noise.

The 8-video sample was the notebook's own selection - 4 per embryo, preferring
division-bearing videos - and it was an easy draw. Per-video adjusted Jaccard
ranges from `0.80` to `0.995`, so an 8-video mean was never going to be stable.
**The correction runs against the artifact**, which is the direction that
matters: the public score is optimistic relative to held-out data, not
pessimistic.

## Embryo-to-embryo variation is larger than it looked

| embryo | 8-video | **24-video** |
| --- | ---: | ---: |
| `44b6` | 0.9534 | **0.9510** |
| `6bba` | 0.9431 | **0.9154** |
| gap | 0.010 | **0.036** |

Since the hidden test is embryo-disjoint, `0.036` is a realistic scale for how
much performance can move on unseen embryos - and that is between two embryos
the models were *trained* on. Unseen ones can reasonably be worse.

Divisions also look weaker with more events in view: `0.1458` with **14 false
positives against 7 true positives**, where the small sample suggested `0.2308`.

## What still holds

The node-count multiplier is `1.0038` on 24 videos - unchanged and negligible.
**The score is still earned by raw tracking, not by gaming the node-count
penalty**, and the source is still free of exploit patterns. The result is not a
hack.

## Revised verdict, second pass

1. **Not a metric hack, not fitted by us.** That stands on the source audit and
   the raw-vs-adjusted decomposition.
2. **But the public `0.946` is optimistic.** Best held-out estimate is `0.9268`
   (95% CI `[0.880, 0.941]`), and public sits outside it. Expect the private
   score to land materially below `0.946` even before domain shift.
3. **Unseen-embryo shift adds roughly `±0.036`** on the evidence of the two
   training embryos.
4. **And none of that matters if the kernel times out at rerun** - projected
   `27.3 h` against a `12 h` limit at ~199 hidden videos.

Priority order for the remaining three weeks: fix the runtime, then treat
`~0.93` rather than `0.946` as the honest expectation and stop reading public
ticks of `0.001-0.003` as real improvements - they are well inside the noise of
an `n≈2` public measurement.
