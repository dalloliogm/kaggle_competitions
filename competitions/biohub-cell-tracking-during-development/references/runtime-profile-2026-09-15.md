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
