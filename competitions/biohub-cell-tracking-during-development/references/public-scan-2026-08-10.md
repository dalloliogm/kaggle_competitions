# Public scan 2026-08-10 - the public frontier has passed us

First sweep since `recent-kernels-2026-08-02`. Baseline for "new" = everything already
catalogued in `public-model-inventory-2026-07-22.md`,
`public-notebooks-scan-2026-07-28.md`, `forum-scan-2026-07-18.md` and the
`recent-kernels-2026-08-0*` snapshots (prvsiyan, chukkkk, aaaa1597, Trackastra,
zoli800 harmonic - all previously catalogued, several already tested and closed).

## HEADLINE - we are now BELOW the public baseline

Leaderboard tie blocks (2,204 teams, up from 1,898 on 08-02):

| score | teams |
| ---: | ---: |
| `0.915` | **177** |
| `0.914` | 57 |
| `0.913` (our tier) | 146 |

**317 teams now score strictly above our `0.913`.** Our rank slid ~292/2156 (08-08) ->
~318-332/2204. The `0.915` block is now larger than our own tier, which means the
dominant public notebook lineage scores `0.002` above us. Adopting it is a gain, not a
sidegrade.

Leader unchanged: Mark Cooper `0.949`. Top: TWEAK `0.945`, Amin `0.943`, htnhtn
`0.942`, yuto083 `0.942`, enddl22 `0.939`.

Reported by `dariushafshar/144-teams-are-tied-at-0-915-bronze-is-inside` (08-09): the
**bronze cutoff falls INSIDE the `0.915` tie block**, and Kaggle's automatic
best-public-submission pick is arbitrary within a tie. Relevant to final selection.

## The one genuinely new MODEL - a local association ranker

Lineage: `yusuketogashi/no-hack-biohub-cell-another-approch-3rd` (127 votes, last run
08-05, self-numbered 145 -> 154 -> 159B -> 162 -> 162-G2), forked at least 5 times
(`sushanthtiruvaipati`, `daniilkrasnovvv`, `cluckinvv`, `raykkretzschmar`).

**`pilkwang/biohub-local-association-ranker-unet300-v1`** - a ~20KB learned reranker
over 22 geometric / degree / density features, blended **85% ranker / 15% our-style
edge probability** at the association step.

**This model is already listed in our own `public-model-inventory-2026-07-22.md`** as a
"tiny alternate linker/reranker" and we never integrated it. That is the miss. It acts
on exactly the stage Exp178 identified as our ceiling.

Other components in that lineage:
- **4-view JS-reliability log-pool TTA on the EDGE/association stage.** Our
  `predict_edges` runs once, canonical orientation only. This is precisely the item
  `LEARNINGS.md` flagged as untried headroom on 08-08 - the public field converging on
  it independently is corroboration.
- "Three-frame forward acceleration lookahead" (the `162` layer): a motion bonus
  rewarding candidates whose *next-frame* velocity residual is smooth. Self-claimed
  `0.915 -> 0.916`, **unverified**.
- `lonnieqin/biohub-gap2-joint-node-budget` (`162-G2`): re-enables gap-2 recovery with
  one shared monotonically-decreasing node budget across both gap stages. Graph repair
  only - **low priority**, our post-processing axis is independently closed by
  experiment (Exp172/174/180/181).

## CORRECTION - our detection TTA is already 8-view

The scan initially reported us as running a 4-view D4 subset. **Verified false.** The
Exp148 TTA patch runs the full dihedral set: original + 3 flips + 2 rot90 + transpose
+ anti-transpose = **8 views** (`_nv` reaches 8 at runtime; 4 source-level `_nv += 1`
sites, two of them inside loops). The vendored default is 4-view; our patch replaces
it. No action needed here.

## Forum - NOT READ

WebFetch returned only page shells for the discussion index and for an individual
thread, so no forum content could be verified. Treat forum state as unknown since
`forum-scan-2026-07-18.md`. `nekkon/your-linker-cannot-score-a-single-division` (08-07)
re-derives metric mechanics we already have documented - no new information.

## Actions, in priority order

1. **Integrate `biohub-local-association-ranker-unet300-v1` at 85/15.** The only new
   *model* in this scan, on the exact axis our own error analysis proved is the
   ceiling, and it is what the `0.915` block is built on.
2. **Edge/association-stage TTA.** Independently identified by us and by the public
   field. Cheap relative to retraining.
3. Ignore the forward-acceleration-lookahead claim until 1 and 2 are in - it is
   self-reported and sits on the motion/graph axis we have repeatedly failed to move.
