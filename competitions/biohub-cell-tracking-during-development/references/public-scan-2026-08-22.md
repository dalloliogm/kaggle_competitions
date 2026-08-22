# Public scan - 2026-08-22

Triggered by `yunusgmsoy/kimi-notebook-v17` (65 votes, posted ~1h before this
scan). The more important find is its predecessor:

**`yunusgmsoy/lb-0-920-biohub-cell-tracking-v17` claims LB `0.920`** (23 votes,
08-21). Our best is `0.917`. Treat the title claim with the usual caution - this
workspace's own rule is that a claimed score in a title is not evidence - but the
notebook carries a detailed inline iteration log with telemetry-driven `REVIEW`
comments, which reads like a real record rather than a label.

It is the same `BIOHUB_*` codebase again, so its config is a line-by-line diff
against ours.

## The 0.920 recipe is a DIFFERENT lineage from our 0.917

It carries **no local association ranker and no edge TTA** (`LOCAL_RANKER` and
`EDGE_TTA` appear zero times). It is dual-seed + harmonic fusion + DeepCenter.
Our `0.917` came from the independent three-model detector-linker. **Two
distinct routes now sit above `0.915`, and they share no new component.**

### Deltas against our exp183/exp196 stack

| key | 0.920 notebook | ours (exp183 / exp196) |
| --- | --- | --- |
| `DEEPCENTER_CHECKPOINT` | `.../full_frame_center/best.pt` | `''` (DeepCenter OFF) |
| `DEEPCENTER_EXPECTED_EPOCH` | `2` | `0` |
| `USE_DEEPCENTER_VETO` / `REQUIRE_` | `1` / `1` | off |
| `DEEPCENTER_SAFE_DIV_VETO` | **`1`** | `0` |
| `DEEPCENTER_GAP_VETO` / `_THRESHOLD` | `1` / `0.25` | off |
| `BIDIRECTIONAL_EDGE_WEIGHT` | **`0.30`** | `0.20` |
| `DUAL_SEED_MIN_CANDIDATE_RETENTION` | `0.90` | not set |
| safe-div geometry | `4.66` / `8.5` / `7.65` | same |

### The finding that matters: `best.pt` vs `checkpoint_last.pt`

Their comment: *"best.pt is epoch 2, not checkpoint_last.pt's epoch 500"*.

**We have never used `best.pt`.** Every DeepCenter run in this workspace pointed
at `checkpoint_last.pt` with `EXPECTED_EPOCH=500` - the last checkpoint of the
run, not the validation-selected one.

That reframes one of our own results. **Exp158 turned the safe-division veto on
and scored `0.905`**, and we recorded that the veto "rejected all candidate
divisions", filing it as a known-weak no-division direction. It ran with the
epoch-500 checkpoint. The 0.920 notebook turns the same veto on *with `best.pt`*
and reports it helping, on telemetry showing safe-div was accepting 81-100% of
its own candidates. **A center-prior model taken from the wrong checkpoint
vetoing everything is exactly the failure Exp158 observed.** So Exp158 may have
measured a bad checkpoint rather than a bad gate - untested either way, because
the two were never separated.

This is a one-line change with a concrete mechanism behind it, and it is cheap.

### Negative results they publish (worth having, none of them ours to repeat)

- `ILP_DIVISION_WEIGHT` at `0.3 / 1.0 / 2.0 / 3.0` - **all `0.915`** on the real
  leaderboard. Matches our own finding that the division-cost axis is flat.
- `SAFE_DIV_MAX_UM` at `7.0` - local proxy improved (first non-zero division
  Jaccard) but the real score **dropped to `0.914`**. They reverted.
- Their local proxy diverged from the leaderboard in the same direction ours
  does, and they reached the same operational conclusion: trust the LB.

### CAUTION on the newer `kimi-notebook-v17`

The newer notebook widens the safe-division geometry to `12.0 / 15.0 / 10.0`
(from `4.66 / 8.5 / 7.65`), commented *"widened to match the 0.917 notebook"*.
**This is NOT part of the `0.920` recipe** - the `0.920` notebook keeps the
narrow values, and the same author's own note records `7.0` losing a thousandth.
Do not read the widening as proven; it is their next experiment, not their
result.

## Actions, in priority order

1. **DeepCenter from `best.pt`, with the safe-division veto ON.** One config
   block, one slot. It is the only delta with a mechanism, a published positive
   result, and a plausible explanation for one of our own negatives (Exp158).
   Run it as the pair - checkpoint and veto together - because separating them
   is what nobody has done, and the pair is what is claimed to work.
2. **`BIDIRECTIONAL_EDGE_WEIGHT` `0.20 -> 0.30`.** We bracketed 0.10/0.20/0.30
   at exp166/167/168 and all tied `0.913`, but that was the pre-ranker,
   pre-three-model backbone. Cheap, and it is the one value they deliberately
   moved off the reference.
3. `DUAL_SEED_MIN_CANDIDATE_RETENTION=0.90` - unset in our stack; closest
   relative is our exp154 retention guard, which tied.

Nothing here is a new *model*. The two routes above `0.915` are the three-model
detector-linker (ours, `0.917`) and this DeepCenter/harmonic line (`0.920`
claimed). They are orthogonal, which is the interesting part: if the `0.920`
config holds up, its DeepCenter block has never been combined with our
three-model detector.

## Sources

- `yunusgmsoy/lb-0-920-biohub-cell-tracking-v17` (23 votes, 08-21) - the recipe
- `yunusgmsoy/kimi-notebook-v17` (65 votes, 08-22) - successor; widened
  safe-division geometry, unproven
- `backtracking/biohub-general-v2..v5`, `arnav170/biohub-ens5`,
  `wuwenmin/biohub-kunal-0917-exact-repro` - reproductions of the 0.917 tier
