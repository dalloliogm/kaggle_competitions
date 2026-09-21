# Targeted steal — the division ceiling was never +0.031

Kernel: `dalloliogm/biohub-sep21-targeted-steal-held-out` v1, 24 held-out
videos, arm F configuration, official division rule. Completed 2026-09-21
10:54 UTC (~2.4h). **No submission slot used. Direction closed.**

## What was tested

The 2026-09-20 trace attributed 15 of 34 ground-truth divisions to
`P2_daughter_already_claimed`: the second daughter already had an incoming
edge when `add_safe_divisions_postlink` ran, so it was excluded from the
candidate list by construction. Four arms let a division reclaim such a node
when the claiming edge was weak *and* the dividing parent explained the node
better:

| Arm | max claim prob | min gain (µm) |
| --- | --- | --- |
| `steal_none_g1` | 0.00 (None only) | 1.0 |
| `steal_p20_g1` | 0.20 | 1.0 |
| `steal_p50_g1` | 0.50 | 1.0 |
| `steal_p50_g0` | 0.50 | 0.0 |

## Result: every arm lost, and none of them touched a real division

| Config | adj edge J | div J | proxy | div tp/fp/fn |
| --- | --- | --- | --- | --- |
| **base** | 0.915859 | 0.104167 | 0.926275 | 5 / 14 / 29 |
| `steal_p50_g1` | 0.915407 | 0.093023 | 0.924710 | 4 / 9 / 30 |
| `steal_p20_g1` | 0.915032 | 0.093023 | 0.924334 | 4 / 9 / 30 |
| `steal_none_g1` | 0.915032 | 0.093023 | 0.924334 | 4 / 9 / 30 |
| `steal_p50_g0` | 0.915233 | 0.090909 | 0.924323 | 4 / 10 / 30 |

Every arm lost a true fork and lost on both metric terms, so the sweep kept
`base`. The emitted `submission.csv` is sha `fe6f0a6f` — byte-identical to the
banked SEP18-1 / SEP20-1 artifact already scored 0.947. Nothing to submit.

No paired test was needed: an arm that loses on the aggregate *and* on the
division term directly cannot be rescued by restricting to affected videos.
The restricted paired test guards against **accepting** a narrow change, not
against rejecting one that loses on every axis.

## Why — the blocked claims, characterised

`blocked_claims.csv`, 15 rows:

| Quantity | min | median | max |
| --- | --- | --- | --- |
| claiming edge length (µm) | 0.21 | 1.68 | 3.06 |
| dividing parent → daughter (µm) | 6.42 | 10.22 | 13.13 |
| gain = claim − parent (µm) | −11.69 | −7.71 | −5.11 |

**The gain is negative in all 15 cases.** The node that already holds the
daughter is 0.2–3.1 µm away; the dividing parent is 6.4–13.1 µm away. The
existing link is not a weak claim we can out-argue — it is short, tight, and
in 11 of 15 cases carries a learned probability above 0.5. Stage of the
claiming edge: 14 motion-relink, 1 gap2.

So the "division explains the node better" condition fires on **0 of 15** for
every arm, including the geometry-only arm that required no gain at all. What
the arms did instead was steal elsewhere — on nodes that are not real
daughters — which is exactly how they lost a true positive.

## The ceiling estimate was wrong by 3×

The trace's +0.031 assumed all 15 P2 cases were convertible. They are not:
**10 of the 15 have parent→daughter distance above `SAFE_DIV_MAX_UM = 9.0`**,
so the existing G4 gate would reject them even if the claim were released. The
reachable set is at most 5 divisions, or roughly +0.010 at the 0.1 division
weight — and all 5 of those still fail the better-explanation test by 5–8 µm.

Counting a blocked candidate as a recoverable one is the same error as
counting an aggregate delta over samples a change does not move. Before
quoting a ceiling from a blocked-reason tally, check the blocked items against
the gates they would face *next*.

## What this closes, and what it points at

Closed: any post-hoc rule at the division stage that tries to reclaim a
claimed daughter. Probability thresholds, distance gains and
detection-stage provenance were all tested, and the geometry refuses all of
them.

Pointed at: the constraint is **upstream**. In 14 of 15 cases motion-relink
confidently linked the daughter to a nearer track, at a distance well inside
the tight gate. Either the matched parent is a matching artifact at 6–13 µm,
or the daughter's true parent is simply not the nearest node. Division recall
of 5/34 is a detection-and-linking property of this pipeline, not a
post-processing threshold, and no further division-gate tuning is warranted.

## Verification performed before the run

- With `SAFE_DIV_ALLOW_STEAL` off, the patched `add_safe_divisions_postlink`
  is behaviourally identical to the original across 120 random graphs — the
  control arm is a real control.
- With the flag on, no run produced a multi-parent node or out-degree above
  two; the steal fired 5 times, so the ON path was exercised, not vacuous.
