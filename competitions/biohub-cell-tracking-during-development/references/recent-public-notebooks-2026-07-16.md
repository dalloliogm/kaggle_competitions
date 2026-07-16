# Recent public notebooks review - 2026-07-16

## Current submission state

- `54758569`: `Notebook Biohub Exp073 Gap 5.8 Public | Version 2`, submitted
  2026-07-16 10:40:20, still pending when checked.
- Conservative safe-divisions candidate was submitted after the previous session
  and scored `0.889` (`54490358`, `54490638`), below copied LB893 `0.893`.

## Pulled public notebooks

Pulled under `references/public-kernels-2026-07-16/`:

- `lucashmateo/biohub-ct-exp073`
- `beicicc/biohub-exp084-det-0-96875-gap-5-8-public`
- `russcore/biohub-praxel-0902-exact`
- `yusuketogashi/biohub-another-approach`
- `hengck23/minimal-baseline-tta-2gpu`
- `chiranjithdharma/motion-relink-tight-um-6-0-5-0`
- `romanrozen/biohub-best-score`
- `arnavsalkade/biohub-exp073-gap58-edge-consensus-v1`

Also pulled our exact copied kernel under
`references/own-kernels-2026-07-16/biohub-exp073-gap-5-8-public/`. It is
byte-identical to `lucashmateo/biohub-ct-exp073` by flattened notebook source
SHA-256: `59726b19ad3b6aea22dd193c04c7de2e3db93ff6808491c84ad341eb7dbdfe8b`.

## Main lesson

The recent public jump is not a new model training recipe. It is a stronger
graph-calibration recipe on top of the same Pilkwang 50-epoch support pack.

Compared with our LB893-derived experiments, Exp073 changes several graph-level
settings together:

- `BIOHUB_DET_THRESHOLD=0.9700` instead of the previous `0.99`;
- `BIOHUB_OUTPUT_FILTER_SHORT_TRACKS=1`;
- `BIOHUB_OUTPUT_MIN_TRACK_LEN=6`;
- `BIOHUB_OUTPUT_GAP2_RECOVERY=0`;
- `BIOHUB_GAP_CLOSE_MAX_GAP=2`;
- `BIOHUB_GAP_CLOSE_UM=5.8`;
- `BIOHUB_MOTION_RELINK_LEARNED_BONUS=1.0`;
- safe divisions kept on, with `SAFE_DIV_MAX_UM=4.66`,
  `SAFE_DIV_SISTER_MAX_UM=8.5`, `SAFE_DIV_EXISTING_CHILD_MAX_UM=7.65`,
  `SAFE_DIV_FRAME_FRAC_CAP=0.0076`, `SAFE_DIV_GLOBAL_FRAC_CAP=0.00375`.

This is materially different from our conservative-safe-divisions candidate,
which only tightened safe division gates and left density/filtering/gap behavior
closer to the previous LB893 branch.

## Exp073 output stats from our copied run

Downloaded output for `dalloliogm/biohub-exp073-gap-5-8-public`:

- rows: `251,900`
- nodes: `128,217`
- edges: `123,683`
- division-like sources: `418`
- safe divisions added: `418`
- gap added nodes: `1,974`
- gap2 added nodes: `0`
- motion relink edges: `123,647`
- short-track nodes removed: `6,435`
- short-track edges removed: `4,330`
- structural checks passed: unique contiguous IDs, no missing values, no duplicate
  node keys, all endpoints present, all edges consecutive, max indegree `1`,
  max outdegree `2`.

Comparison with key previous outputs:

| Output | Rows approx | Nodes | Edges | Divisions | Gap nodes | Gap2 nodes | Short-track nodes removed | Public LB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Copied LB893 | 262,359 | 134,238 | 128,121 | 381 | 2,100 | 402 | 0 | 0.893 |
| No-safe | 283,092 | 145,034 | 138,058 | 0 | 2,477 | 412 | 0 | 0.886 |
| Conservative safe | 283,385 | 145,040 | 138,345 | 287 | 2,477 | 412 | 0 | 0.889 |
| Exp073 copied run | 251,900 | 128,217 | 123,683 | 418 | 1,974 | 0 | 6,435 | pending |

Interpretation: the strongest new signal is not merely adding/tightening
divisions. It is reducing noisy tracks after allowing a lower detection threshold,
disabling gap2, and using two-frame gap close with a shorter distance.

## Other recent variants

- `beicicc/biohub-exp084-det-0-96875-gap-5-8-public`: same family as Exp073 but
  `BIOHUB_DET_THRESHOLD=0.96875`.
- `russcore/biohub-praxel-0902-exact`: same public-0902 family plus component
  filters such as `BIOHUB_COMPONENT_MEDIAN_DETECTION_LOGIT=5.5` and
  `BIOHUB_COMPONENT_MEAN_EDGE_PROB_MAX=0.65`.
- `romanrozen/biohub-best-score`: adds density-adaptive gap parameters and
  short-track rescue thresholds.
- `yusuketogashi/biohub-another-approach`: adds density-adaptive gap close and a
  stable long-track bridge extension with two-step source/target context and
  midpoint agreement checks. Its source claims account submission `54633411`
  scored `0.902`.
- `arnavsalkade/biohub-exp073-gap58-edge-consensus-v1`: starts from Exp073 and
  adds an edge-error consensus/critic layer. Treat as experimental until verified
  because it is more complex than the plain public recipe.
- `hengck23/minimal-baseline-tta-2gpu`: different lean TTA inference baseline.
  Useful as an architectural reference, but not the fastest path from our current
  LB893/Pilkwang branch.

## Recommended next actions

1. Wait for `54758569` to score. If it lands near the claimed `0.902-0.903`, make
   Exp073 the new baseline.
2. If Exp073 is strong, do one-factor ablations around it rather than continuing
   LB893 safe-division-only tuning:
   - `DET_THRESHOLD=0.96875` vs `0.9700`;
   - gap close `5.8` vs nearby values;
   - short-track filtering on/off;
   - density-adaptive gap close from Roman/Yusuke;
   - stable long-track bridge extension from Yusuke.
3. Do not prioritize our prepared `no_gap2` / `no_gapclose` LB893 candidates
   unless Exp073 underperforms, because Exp073 already includes a stronger
   combined gap/track-filter recipe.
