# Public scan - 2026-08-17

Scan since `public-scan-2026-08-10.md`. **One notebook carries new information.**
Everything else published in the last week is a fork of the stack we already run
- `backtracking/biohub-medal-v1`, `anhadmahajan06/biohub-track-your-cells-development`
and `saitejabandaruin/biohub-masterpiece-tracker` are the same `BIOHUB_*` pipeline
with boundary-track rescue and velocity weight `0.65` (our exp194 already measured
boundary rescue at `0.914`), and `liyansen/biohub-v12..v16` are checkpoint swaps on
the public no-hack pipeline. No new component, no new artifact.

The competition discussion forum remains unreadable from this environment: the
CLI returns `403` on the competition forum and the web index is client-rendered.

---

## `sleepymegacat/the-metric-decides-your-architecture-8-measured` (7 votes, 08-17)

Eight facts probed against the organisers' own scorer and measured on the
training data. Three of them bear directly on decisions we have already made,
and one of those contradicts an assumption embedded in our pipeline.

### 1. The centroid precision cliff is at sigma ~= 2 um, not 7 um

Take the ground truth as a perfect detector, add Gaussian centroid noise, score
it. Linking untouched, every cell found, **only the coordinates move**:

| centroid noise | score kept |
| --- | --- |
| < 1.5 um | free |
| 2.5 um | -16% |
| 3.0 um | -41% |
| 4.0 um | -74% |

The 7 um match radius is misleading because matching is **one-to-one** and
neighbouring cells sit only **~9-10 um apart** (measured, and the same value in
both embryos despite several-fold different cell counts). Independent centroid
error therefore makes adjacent cells *steal each other's match* - you do not
merely fail to match, you match wrongly, paying an FP and an FN at once.

**This is the finding that matters for us.** `LEARNINGS.md:110` already
suspected line-fit smoothing of "displacing a node past the 7 um match radius" -
the direction was right, but the tolerance we assumed is about **3.5x too
loose**. Our output stage applies

```
q_out = 0.2 * q_i + 0.8 * q_line
```

i.e. an 80% pull of every node in every linear track toward a fitted line. On a
curved trajectory that is a systematic coordinate displacement applied to the
whole graph, and it has never been evaluated against a 2 um budget.

`BIOHUB_OUTPUT_LINEFIT_SMOOTH=0` has been ablated locally (exp171b) but has
**never been submitted on its own**, on any backbone. On the current `0.915`
stack it is a one-env-var run.

### 2. A duplicate detection HALVES the score, not 9%

Measured `1.000 -> 0.500` from one extra peak `0.4 um` away. This is much worse
than the `~9%` the 08-07 scan recorded from `nekkon`, and the mechanism is
different: the losing twin's edges still touch annotated evidence, so they are
graded as **FPs** rather than merely inflating the node count.

Consequence: "exactly one out-edge per node, two only at a real division", and
an entire parallel track in *unannotated* territory is free (1.000) while
speculative extra edges from an *annotated* cell cost (0.667).

The duplicate-node audit proposed on 08-07 has still not been run. It needs no
submission slot and no GPU - a KD-tree over the node rows of a scored
submission, counting same-frame pairs below ~2 um.

### 3. Our local harness is probably LEAKING, which would explain the inversion

- `44b6` / `6bba` are **embryo ids**, and train contains only **two embryos**.
- The 199 "samples" are **overlapping crops of two movies**. Decoding the GEFF
  node ids (`(t + offset) * BASE + label`) shows **6,206 of 8,128 `6bba` file
  pairs share annotated cells**, up to 29% of the smaller file.
- The visible `test/` is four byte-identical copies of train volumes, verified
  to the sha256 of every chunk. The graded set is swapped in at rerun and is
  embryo-disjoint - **unseen embryos**.

So a per-video split does not merely correlate, **the same physical cells appear
on both sides**. The honest estimate is leave-one-embryo-out, which gives two
lopsided folds (`6bba` 113k annotated nodes vs `44b6` 20k).

This is a **better-mechanised explanation for the 08-05 "the harness is
anti-predictive" finding** than the one on file. We eliminated the node-count
multiplier as a confounder (`LEARNINGS.md`, 08-06) and concluded the harness
inverts. But a harness scored on overlapping crops of the same two embryos,
against a hidden set of unseen embryos, would produce exactly that signature
without any inversion being real. The 08-05 conclusion is not refuted - it is
still the correct operational rule - but the cause may be leakage rather than
anything intrinsic, and leakage is fixable where "anti-predictive" is not.

### 4. Already-known or already-closed, recorded so nobody re-derives them

- **`dt != 1` edges are silently dropped, not counted as FPs.** The official
  `metrics.md` says otherwise; the code wins. We already comply
  (`dropped_nonconsecutive_edges=0`), and our gap repair already inserts
  interpolated NODES plus two `dt=1` edges, which is the construction that
  recovers full credit.
- **The node-count penalty has no upper clip, so under-prediction pays up to
  1.1x.** We have already measured our own position: we under-predict by
  **~7.6%** in aggregate for a bonus of about **`+0.008`** (`LEARNINGS.md`,
  08-06). We are on the rewarded side already and the headroom is small. Do not
  re-open this as an untapped axis - it is tapped and nearly spent.
- Ground truth is **2.82% dense** (133,318 annotated nodes vs ~4,725,117
  estimated real cells) and contains **zero gaps, zero merges, 151 divisions**.

---

## Actions, in priority order

1. **Submit `BIOHUB_OUTPUT_LINEFIT_SMOOTH=0` on the current `0.915` stack.** One
   env var, one slot. It is the only place our pipeline deliberately moves
   coordinates, the cliff is now quantified at ~3.5x tighter than we assumed,
   and the configuration has never been measured on the leaderboard by itself.
2. **Run the duplicate-node audit.** Free - no slot, no GPU. A single duplicate
   is now measured at *half* the score rather than a node-count rounding error,
   which promotes this from housekeeping to a real risk check.
3. **Rebuild validation leave-one-embryo-out.** Two folds, grouped by prefix,
   reproducing the official aggregation (per-sample adjusted Jaccard weighted by
   `TP+FP+FN`; division Jaccard micro-averaged). If the leakage hypothesis is
   right, this is what turns local measurement back into a usable gate - and we
   have been flying without one since 08-05.
4. **Sub-voxel centroid refinement**, if 1 lands. The same cliff says peak
   position refinement buys score directly, and we have never touched it.

Nothing here argues for another post-processing variant. Eight consecutive
experiments now tie at `0.915` (exp193/195/196/197/198/200/201 plus controls),
which is the same signature as the ten-way `0.913` tie that preceded it - and
that plateau broke only when an external component was adopted, not by tuning.

## Sources

- `sleepymegacat/the-metric-decides-your-architecture-8-measured` (7 votes, 08-17)
- `backtracking/biohub-medal-v1` / `-v2`, `anhadmahajan06/biohub-track-your-cells-development`,
  `saitejabandaruin/biohub-masterpiece-tracker` - forks of our own stack, no new component
- `liyansen/biohub-v12-public-ranker-reproduction` .. `-v16-ranker-persistent-divisions` -
  checkpoint swaps on the public no-hack pipeline
