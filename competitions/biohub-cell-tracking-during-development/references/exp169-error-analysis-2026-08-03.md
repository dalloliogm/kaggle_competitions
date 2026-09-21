# Exp169 error analysis - what the scored mis-links actually are (2026-08-03)

Diagnostic run of the UNCHANGED Exp148 stack on the five labelled movies
(`dalloliogm/biohub-exp169-error-dump`, kernel v1 COMPLETE, no submission slot
spent). Raw artifacts: `error_dump.csv`, `error_summary.csv`, kernel log.

## Trust boundary - read this before using the numbers

Individual errors were reconstructed independently (per-frame Hungarian matching
within `7 um`) and cross-checked against the official `evaluate()` counts:

| dataset | official TP/FP/FN | reconstructed TP/FP/FN | agree |
| --- | --- | --- | --- |
| `44b6_0113de3b` | 47 / 2 / 3 | 47 / 1 / 3 | FP only |
| `44b6_0b24845f` | 47 / 3 / 2 | 47 / 2 / 2 | FP only |
| `44b6_33b596bf` | 49 / 0 / 0 | 49 / 0 / 0 | yes |
| `6bba_05b6850b` | 833 / 19 / 12 | 833 / 11 / 12 | FP only |
| `6bba_05db0fb1` | 1103 / 138 / 80 | 1103 / 69 / 80 | FP only |

**TP and FN reconstruct EXACTLY on every movie. FP is under-counted** (69 of 138
in the dense movie). So FN-side conclusions below are sound; FP-side conclusions
cover only about half the FPs and are indicative only. The likely cause is that
the official rule counts a predicted edge as FP from more situations than the
"source matched an annotated GT node that has out-edges" rule used here.

## Current Exp148 error budget (this differs from the older table in LEARNINGS)

`6bba_05db0fb1` now shows **138 FP / 80 FN**, versus the previously recorded
`79 FP / 88 FN`. Exp148 trades FN for FP relative to that older config. Edge
Jaccard on the dense movie is `0.834974`; it carries the great majority of all
measurable loss. `node_recall` is `0.9959` there and `1.0000`/`0.9977` elsewhere.

## MAIN FINDING - the failure is confident mis-linking, not near-ties

Breakdown of the 80 dense-movie FN (exact):

| class | count | share |
| --- | ---: | ---: |
| **mis-link**: true target WAS detected, parent linked to a different cell | **62** | 78% |
| **termination**: matched parent has NO predicted child at all | 15 | 19% |
| true target not detected | 4 | 5% |

So detection contributes ~5% of the loss. This is a linking-decision problem
among candidates that were all successfully detected.

**The wrong choices are not near-misses.** For the mis-links, the cell we picked
sits a median `7.54 um` from the true child (min `4.61`, p75 `9.07`). The linker
is not narrowly mis-ranking two adjacent candidates - it is confidently selecting
a clearly different cell. Local crowding is modest (median 4 predicted nodes
within `10 um`, max 8).

### This explains two earlier null results

- **Exp163** raised the learned bonus only when the top two parent costs were
  within `0.75 um` - i.e. it targeted near-ties. It replaced 637 edges and scored
  `0.913`. The real errors are not near-ties, so it could not help.
- **Exp164** proposed pairwise crossing swaps and accepted **0** of 5,842
  candidates across three calibrations. Crossings are also a near-tie/adjacent
  geometry; the actual failures are larger-displacement mistakes.

Both were reasonable hypotheses that the error data now rules out.

## Secondary finding - safe divisions are pure loss on labelled data

Official division counts: `division_tp = 0` on EVERY movie, with
`division_fp = 7` (`6bba_05db0fb1`) + `3` (`6bba_05b6850b`) = **10 FP** and
`3 FN`. Our safe-division insertion currently produces no true positives at all
locally while adding 10 false ones, so it is a net negative on the
`0.1 * division_jaccard` term here. Caveat on power: only 3 GT divisions exist in
the labelled set, so this cannot prove divisions are worthless on the hidden test
- but it does show the current proposals are not finding real ones.

## What is NOT yet established

- **No enrichment baseline for step length.** 42% of FN have GT step `> 6 um`
  and 22% `> 7 um`, but the distribution of step length over ALL GT edges
  (including the 1,103 TPs) was not measured, so it is unknown whether long steps
  are over-represented among errors. Do not act on the step-length hypothesis
  until that baseline exists.
- **Geometry of the wrong choice relative to the parent.** The dump records the
  distance from the chosen child to the TRUE child, but not the parent-to-chosen
  and parent-to-true distances side by side, nor the parent's incoming velocity.
  Without those it cannot be shown whether the linker is defaulting to a nearer
  neighbour while the true cell moved further.

## Recommended next step - Exp170, a second diagnostic (no slot)

Extend the dump rather than guessing at a fix:
1. `parent_to_true_um` and `parent_to_chosen_um` side by side (is the chosen cell
   nearer to the parent than the true one?).
2. The parent's incoming velocity vector and the angle between the true step and
   the chosen step (does motion continuation disambiguate them?).
3. The learned edge probability assigned to the true edge versus the chosen edge
   (did the model rank the true link plausibly but lose to a cost term, or does
   it genuinely not see it?).
4. Baseline distributions of the same quantities over TP edges, for enrichment.

Item 3 is the decisive one: if the true edge already carries a competitive
learned probability, the fix is in the cost/assignment stage we control. If it
does not, the linker model itself is the limit and no post-processing will help.
