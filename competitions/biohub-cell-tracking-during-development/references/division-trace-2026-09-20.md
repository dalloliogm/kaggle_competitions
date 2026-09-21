# Division trace: it is a linking problem, not a gating problem (2026-09-20)

## Result

Every ground-truth division in the 24 held-out videos, traced through the
admission sequence of `add_safe_divisions_postlink` in order, recording the
first test that refuses it:

| verdict | n | tunable? |
| --- | ---: | --- |
| `P2_daughter_already_claimed` | **15** | **no - not a threshold** |
| `detection` | 9 | no |
| `true_positive` | 5 | - |
| `G4_parent_dist` | 2 | yes |
| `G7_divergence` | 1 | yes |
| `G6_not_mutual_nn` | 1 | yes |
| `G9_symmetry` | 1 | yes |

**Self-check: the trace finds exactly the 5 true positives the pipeline finds.**
A replication that disagreed there would not be trustworthy for the other 29;
this one agrees, so the verdicts stand.

## What it means

`add_safe_divisions_postlink` builds its candidate list as

    candidate_ids = [n for n in child_frame_ids
                     if n not in incoming and n not in used_targets]

A node that already has an incoming edge is excluded **by construction**. In 15
of the 34 divisions - three quarters of the 20 that are reachable at all - the
second daughter has already been linked to a different parent by the time the
division stage runs. No gate value reaches them. There is no threshold to move.

Only **5 divisions** fail on a tunable threshold, and their margins are:

    G7 divergence     grandchild_sep - sister = 1.60  < 2.25
    G6 mutual-NN      nearest unclaimed is 4.74 um away vs our 5.76 um
    G4 parent_dist    9.27  > 9.0
    G4 parent_dist    12.22 > 9.0
    G9 symmetry       asym = 1.166 > 0.6

One of those (G4 at 9.27 against 9.0) is a near miss; the rest fail by wide
margins. So the entire week of gate tuning - low 6.5/7.25/8.0/9.0, middle
6.0/6.5/7.0, high 5.5/6.0, divergence and symmetry opened and half-opened - was
competing for at most five divisions, and realistically one or two.

That is why division recall never moved: **TP = 5, FN = 29 on all six
configurations tried.** The measurement was telling us this all along.

## The ceilings

| change | TP | division Jaccard | metric delta |
| --- | ---: | ---: | ---: |
| convert the 5 threshold cases | 5 -> 10 | 0.104 -> 0.208 | +0.010 |
| convert the 15 P2 cases | 5 -> 20 | 0.104 -> 0.417 | +0.031 |

## What would actually have to change

The second daughter is being claimed by another parent during linking. Two
possible responses:

1. **Make the linker less eager** - a global change to edge admission, which
   risks the edge term. Edge Jaccard is weighted 1.0 against the division
   term's 0.1, so a change that costs 0.003 on edges to gain 0.03 on divisions
   is barely break-even and easy to get wrong.
2. **Let the division stage re-assign a claimed node** - allow a fork to steal
   a daughter when the evidence is better than the existing link. Breaking 15
   edges out of ~118,000 costs about 0.0001 on edge Jaccard, so the arithmetic
   strongly favours this *if* the steal can be targeted.

The difficulty with (2) is that at inference time we cannot know which claimed
nodes are the real daughters. A steal rule fires on every candidate that looks
like one, and the false-positive cost is what sank the 2026-09-17 attempt:
opening the gates took the pool from 730 to 4,887 candidates and the score fell
from 0.946 to 0.917.

So the honest position is that the ceiling is +0.031, the mechanism is
understood, and the safe way to capture any of it is not yet established. What
is established is that **further gate tuning is worth at most +0.010 and
probably far less**, and that direction should stop.
