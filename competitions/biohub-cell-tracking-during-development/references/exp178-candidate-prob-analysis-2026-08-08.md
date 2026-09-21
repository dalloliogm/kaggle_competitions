# Exp178 candidate-probability analysis - where the true edge actually dies (2026-08-08)

Answers the open **item 3** from `exp169-error-analysis-2026-08-03.md`: *"the learned
edge probability assigned to the true edge versus the chosen edge - did the model
rank the true link plausibly but lose to a cost term, or does it genuinely not see
it?"* Exp170 delivered items 1, 2 and 4 but not item 3, which Exp169 called "the
decisive one".

Diagnostic run of the UNCHANGED Exp148 stack on the five labelled train movies
(`dalloliogm/biohub-exp178-candidate-prob-dump`, kernel **v2**, no submission slot).
Raw artifacts: `exp178-candidate-prob-dump/error_dump_v4.csv`,
`error_summary_v4.csv`, `tp_baseline_v4.csv`.

## Why Exp177 could not answer it

Exp177 read `edge_prob` off the ILP geff. That fails for two independent reasons,
both now confirmed against the vendored source
(`pilkwang/biohub-tracking-support-pack-50ep-v1`, `repo/scripts/predict_unet_transformer.py`):

- `save_graph()` is called AFTER `solver.solve(graph)`, so the geff is the ILP
  **solution**, not the candidate set. For a mis-link the true edge is by
  definition not selected, so its probability is simply absent.
- Only 8 of 97 error rows had both probabilities, and in all 8 `p_true` and
  `p_chosen` were bit-identical while the geometry columns differed - consistent
  with those rows being match artifacts (line-fit smoothing displacing the node
  past the 7 um match radius) rather than genuine replacements.

**Do not use the ILP geff's `edge_prob` to compare a source's alternative
children.** It cannot discriminate them.

## Method

Patched `predict_video()` to dump the raw `(n_src, n_tgt)` probability matrix per
frame pair, keyed by global node index, before any filtering:

    probs = softmax(raw, dim=0)      # normalised over SOURCES, per target
    -> np.savez_compressed(pair_{t_src:04d}.npz, idx_src, idx_tgt, probs, t_src, t_tgt)

**Bug worth remembering:** the first attempt keyed the dump on `f_idx`. In
`predict_video` the loop is `for f_idx in range(W - 1)` with `W = window_size = 2`,
so `f_idx` is ALWAYS 0 - every frame pair overwrote one file and all 97 lookups
missed. The absolute frame is `t_src` from
`t_src, t_tgt = frame_indices[f_idx], frame_indices[f_idx + 1]` (line ~409).

The pipeline runs inference as two GPU subprocesses (`--slice 0::2`), but they
inherit the parent environment via `shard_env = {**os.environ, ...}`, so an env
flag set in the notebook does reach the hook.

## RESULT - the loss splits cleanly in two, and only half is fixable

| failure mode | n | p(true edge) median | p25 | rank of true parent |
| --- | ---: | ---: | ---: | --- |
| `below_threshold` | 44 | **0.128** | 0.041 | median 2, rank-1 only 16% |
| `survived_to_ilp` | 42 | **0.861** | 0.772 | **rank 1 in 100%** |
| `lost_greedy_cap_or_ilp` | 3 | 0.585 | 0.521 | rank 1 |
| unlocatable | 8 | - | - | - |
| **TP baseline** | **2067** | **0.935** | **0.883** | **rank 1 in 99%** |

The candidate threshold in force is `0.48` - the notebook's dual-seed patch sets
`cfg.threshold = BIOHUB_DUAL_SEED_EDGE_THRESHOLD` whenever a secondary model loads,
overriding the vendored default of `0.5`.

**The 42 post-processing losses are not a model problem at all.** The model ranked
the true parent first in every single case at confidence 0.861, and the ILP kept
those edges. Our own post-processing then destroyed them.

**The 44 threshold losses are purely a model limit.** Median 0.128 against 0.935
for correct links - a sevenfold gap - and rank-1 only 16% of the time. No
assignment-stage or graph work recovers these. Distribution below the cut:
`[0,0.01)` 5, `[0.01,0.05)` 8, `[0.05,0.10)` 7, `[0.10,0.25)` 11, `[0.25,0.48)` 13.

So the answer to item 3 is **both, split down the middle**, and the model-limited
half cannot be tuned away.

## CRITICAL - confidence and rank CANNOT isolate relink's mistakes

The 42 destroyed edges have median probability `0.861`, which is **below** the
`0.935` median of ordinary correct edges. They are rank-1 in 100% of cases, but so
are 99% of true positives. **Neither signal separates them from the general
population.**

This was learned the expensive way. Exp180 set a protection threshold of `0.80`
calibrated from the error distribution's p25 (`0.7715`) without checking the base
rate, and the guard fired on **95,298 of 119,571 edges (80%)** - effectively a
relink-disabled run, a config already known to score `0.911`. The TP baseline in
this very table (p25 `0.883`) predicted that outcome and was not consulted.

**Rule: before gating on a statistic measured over errors, check its distribution
over the whole population.** A threshold picked from the error tail is meaningless
without the base rate.

Cheap enforcement: a submission-shaped kernel writes `run_stats.csv` without
costing a submission slot. Read the guard's own counters there BEFORE submitting.
Exp181 was checked this way and fires on `1,296 / 119,311` edges (**1.09%**),
restoring 1,007 ILP edges.

## What IS usable as a discriminator

Direction, not confidence. Exp170 measured the wrong substitute sitting at a median
**128.8 deg** (p25 87.2) from the true motion step. Exp181 acts on exactly that:
reject a relink *replacement* whose turn from the ILP child exceeds
`BIOHUB_RELINK_MAX_TURN_DEG = 90`, and restore the ILP edge.

## Standing caveat

The 42/44 split is measured on the five labelled movies, which
`exp170-origin-analysis-2026-08-04.md` established are ANTI-predictive for
post-processing changes. The *diagnosis* (probabilities and ranks) is a direct
measurement of model behaviour and should transfer. Any *remedy* still has to be
proven on the leaderboard.
