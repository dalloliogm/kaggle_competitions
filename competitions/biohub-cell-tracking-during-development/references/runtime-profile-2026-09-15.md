# Runtime profile and the motion-relink rewrite (2026-09-15)

## Why runtime is the binding constraint

The private score comes from re-executing the kernel on a hidden test set of
roughly 199 samples. A kernel that does not finish inside the 12 h limit scores
nothing, so the public 0.947 is worth nothing without a run that completes. A
competitor in the `focus3d` thread reports exactly this failure.

## Measured phase split

Kernel `biohub-sep14-motion-relink-tight-50`, 1362 s total, 4 test videos,
prediction sharded across 2 GPUs:

| phase | wall | scales with |
| --- | ---: | --- |
| setup + model artifacts | 262.9 s | fixed |
| detection inference (2 GPU shards) | 579.1 s | videos |
| association | 253.1 s | videos |
| graph construction | 254.8 s | videos |

An earlier note put graph construction at "about half" the per-video cost. That
was wrong: it is 19%.

## The graph stage was quadratic

Per-video cost of the load + edge-filter + motion-relink block:

| raw nodes | time |
| ---: | ---: |
| 6 303 | 1.7 s |
| 22 507 | 16.6 s |
| 25 821 | 21.1 s |
| 70 697 | 150.7 s |

2.74x the nodes cost 7.28x the time - a log-log slope of **1.97**. This matters
more than the 19% share suggests: a *linear* per-video extrapolation to the
hidden test understates the cost of any sample larger than the four visible
ones, and understates it in the dangerous direction.

The cause is `assign_pass` inside `motion_relink_edges`. It allocates four dense
`len(sources) x len(targets)` float64 matrices per frame per pass and fills them
with a pure-Python double loop calling `np.linalg.norm` on a 3-vector for every
pair - then discards nearly all of them at the `raw > gate_um` test. On the
largest video that is ~714 cells per frame over 99 frames, about 50 M
iterations. The tight pass carries ~91% of matches, so the full matrix is the
cost; the relaxed pass runs on the ~9% left unmatched and is negligible.

## Why not simply vectorise

Computing the pair distances with one vectorised `np.linalg.norm(..., axis=-1)`
is 4.2x faster and **not bit-exact**. A 1-D `np.linalg.norm` goes through BLAS
`ddot`, which may fuse multiply-add; an axis reduction does not. Measured on
120- to 2000-cell frames, the two disagree by up to 3.6e-15 on ~200 of 1.4 M
cells. Those matrices feed `linear_sum_assignment`, where a last-bit difference
can flip a match, change an edge and change the submission. Fast and unusable.

## What was done instead

Keep **every arithmetic operation of the original** - the same scalar
`np.linalg.norm` call, the same `raw > gate_um` test, the same cost expression -
and use a `cKDTree` purely as a *superset* filter so the loop never visits pairs
the gate would reject. The tree radius is padded by 1e-9 relative, far beyond
the ~1e-16 slack between two float64 distance evaluations, so no pair the exact
test would accept can be dropped; the exact test still makes every accept/reject
decision. The matrices are identical by construction, not by tolerance.

Local verification against a verbatim transcription of the original, on frames
of 120-2600 cells (real frames hold 73-848; the pipeline skips frames above
`MOTION_RELINK_MAX_FRAME_NODES` = 2600) at densities from 1 to 370 in-gate
neighbours per cell:

- bit-identical on all four matrices at every point tested
- 20-50x faster in the real density regime
- 1.1x - never slower - in the degenerate all-pairs-inside-gate case

## Result on Kaggle

Kernel `biohub-sep15-motion-relink-kdtree-exact`, same pinned base
(`MOTION_RELINK_TIGHT_UM=5.5`, validator off).

**Submission sha `a852d1d07ff8c930...795b3e` - byte-identical to the scored
0.946 artifact.** The rewrite is proven equivalent, not merely close.

| | before | after | |
| --- | ---: | ---: | ---: |
| relink blocks (4 videos) | 190.0 s | 7.7 s | 24.8x |
| graph stage | 254.8 s | 74.3 s | 3.4x |
| per-video cost | 271.7 s | 229.7 s | 1.18x |

Per-video relink cost, and the point of the exercise - the quadratic term is
gone and cost is now linear in node count:

| raw nodes | before | after |
| ---: | ---: | ---: |
| 6 303 | 1.7 s | 0.6 s |
| 22 507 | 16.6 s | 1.4 s |
| 25 821 | 21.1 s | 1.7 s |
| 70 697 | 150.7 s | 4.0 s |

## Where this leaves the 12 h limit

Projection for ~199 hidden samples:

- before: **15.09 h** - 3.09 h over
- after: **12.79 h** - 0.79 h over

So this is a real saving and it removes the scaling hazard, but it **does not by
itself clear the limit**. About 1.07x more is still needed.

Remaining per-video budget: detection inference 562 s (61%), association 282 s
(31%), graph 74 s (8%). The graph stage is close to spent - only 7.7 s of its
74.3 s is relink now, and the remainder scales sub-linearly. Further runtime
work should target association or detection inference.

`EDGE_TTA views=8` is the obvious lever on inference, but unlike this change it
would alter the output, so it costs accuracy and needs its own evidence.

---

# Update 2026-09-19: the carry-forward build

## An integration gap that would have undone the runtime work

The density-adaptive arms (2026-09-18) were built from the *unpatched* source,
so arm E - submitted on held-out evidence - did not contain the KD-tree relink
speedup. The two fixes had never been in the same kernel.

| run | total | graph | relink | per-video | projection |
| --- | ---: | ---: | ---: | ---: | ---: |
| baseline, KD-tree only | 1264.6 s | 74.3 s | 7.7 s | 229.7 s | 12.79 h |
| arm E, density only | 1399.6 s | 300.5 s | **219.3 s** | 274.5 s | **15.25 h** |
| **carry-forward, both** | **1196.8 s** | **76.5 s** | **8.3 s** | **228.1 s** | **12.69 h** |

Arm E's per-video relink profile (24.2 / 19.3 / 1.9 / 174.0 s) is the original
quadratic signature. Carrying it forward as submitted would have projected
**15.25 h** - worse than the 15.09 h before any runtime work - and timed out on
the private rerun, scoring nothing regardless of its held-out Jaccard.

## The carry-forward is proven, not merely assumed

Submission sha `bbca0613a4a7a19b...` - **byte-identical to arm E**. The density
groups still resolve from the graph (63 -> low @ 7.25; 225.1 and 258.2 ->
middle @ 5.5; 707 -> high @ 5.5). Same output, relink 219.3 s -> 8.3 s.

The patches compose because they touch disjoint regions of
`motion_relink_edges`: the density gate is computed before `position_um` and
consumed by the pass loop after `assign_pass`, while the KD-tree change is
entirely inside `assign_pass`, whose `gate_um` parameter carries whatever gate
the density logic supplies.

## Corrections to earlier estimates

* Arm E alone was estimated at "~15.8 h"; measured, **15.25 h**. The conclusion
  (certain timeout) stands; the number was wrong.
* Arm E's largest video at 174 s against the pre-KD-tree 150.7 s was flagged as
  unexplained. The carry-forward shows the same ~15% gap in miniature (4.5 s vs
  4.0 s), so it is the widened low-density gate plus run variance, not a
  pathology.

## Still over the limit

**12.69 h against a 12 h limit.** Combining the two fixes bought 0.10 h, not a
rescue. Roughly **1.06x** more is still needed, from the two blocks the KD-tree
work did not touch:

| block | per-video share |
| --- | ---: |
| detection inference | 61% |
| association | 31% |
| graph construction | 8% |

Association is the larger unexamined block and the only remaining place where
an output-preserving fix is plausible, as the KD-tree change was. Cutting
`EDGE_TTA views=8` is the obvious lever on inference but would change the
output, so it needs its own held-out evidence rather than a sha check.
