# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Inputs are anisotropic 3D+time OME-Zarr movies. Physical scale is `(z, y, x) =
  (1.625, 0.40625, 0.40625)` um/voxel, so XY pooling by 4 produces an
  approximately isotropic working grid.
- Training labels are sparse GEFF tracking graphs, and dataset names group fields
  of view by embryo prefix.
- A 2026-07-18 forum scan found a credible report that many `6bba` train movies
  contain exact duplicate adjacent frames while `44b6` does not. The reported
  numbers were `947` duplicate adjacent pairs across `114/128` `6bba` movies and
  none across `71` `44b6` movies. Treat duplicated/frozen transitions as a
  likely acquisition artifact and test conditional linking/gap behavior rather
  than assuming constant time spacing everywhere.
- Boundary-adjacent cells may leave and re-enter the field of view with GT
  annotations split into separate lineages. Boundary gap closing is therefore
  risky: a biologically continuous link can be scored as a false positive if the
  sparse GT intentionally split the track.

## Target And Metric

- The exact objective is `adjusted_edge_jaccard + 0.1 * division_jaccard`.
- A predicted edge needs both endpoints to match within 7 um and the corresponding
  GT edge to exist. Detection quality therefore compounds into edge quality.
- Sparse-label unmatched detections are often ignored as edge false positives,
  but total-node overprediction is penalized separately.
- Official division evaluation allows temporal tolerance and tests connected
  lineage coverage; exact predicted-parent matching is not an adequate proxy.
- The hosts announced a patch for a division-Jaccard exploit on 2026-07-18 and
  plan to rescore submissions. Do not optimize around fake forks, duplicated
  tracks, artificial hubs, or other metric-hack graph patterns; use the patched
  local evaluator before trusting division-heavy gains.
- Current strategy choice: keep the main branch strict and biological. Public
  notebooks that use negative-time hubs, impossible coordinates, or artificial
  fork chains can be useful for diagnosing metric weaknesses, but do not copy
  those structures into submissions unless explicitly running a separate
  metric-risk branch.

## Exp122: the metric patch does NOT change our edge numbers (2026-07-20)

Ran the Exp121 ablation scoring every variant twice - vendored pre-patch metric
and official patched metric - side by side. Evidence:
`references/exp122-patched-metric-v2-output/exp122_postproc_ablation_patched.csv`.

**Edge delta (patched minus pre-patch) is exactly `+0.000000` for all 7 variants.**
This confirms the prediction: the patch's edge-side changes (non-consecutive-edge
filtering, duplicate-edge dedup) are no-ops for graphs that already have
consecutive-frame edges and in-degree `1`, which ours do. So the pre-patch metric
never corrupted our EDGE conclusions - only division numbers were at risk.

Division counts under the PATCHED metric (labelled train split):

| ablation | div TP / FP / FN | div Jaccard |
| --- | --- | ---: |
| full (320 safe divisions) | 0 / 3 / 3 | 0.0000 |
| no_safe_divisions | 0 / 0 / 3 | 0.0000 |
| ilp_only | 0 / 0 / 3 | 0.0000 |

- The labelled split contains only **3** GT divisions and we recover **none** of
  them under either metric, so `division_jaccard` is `0` everywhere and the local
  harness has NO power to evaluate divisions. This is a power problem, not a
  correctness one, and the patched metric does not fix it.
- Locally, safe divisions produce only false positives (`3` FP, `0` TP). But the
  leaderboard has Exp110 (320 divisions) at `0.909` versus Exp116 (0 divisions)
  at `0.877`, and that comparison confounds divisions with all the other
  post-processing. Divisions remain UNRESOLVED and can only be settled on the
  leaderboard.

## Motion relink: LEARNED_BONUS is a low-leverage knob

Exp123 raised `MOTION_RELINK_LEARNED_BONUS` from `1.0` to `1.5` on the Exp110
branch. Effect on the graph was small:

- nodes `121,403 -> 121,390`, edges `117,131 -> 117,127`, divisions `320 -> 318`
- `motion_relink_tight_edges` **identical** at `114,649`; relaxed `3,358 -> 3,371`
- versus Exp110: `1,303` edges differ out of `117,131` (edge Jaccard `0.978`),
  98.9% of nodes bit-identical

A 50% increase in the learned-probability weight moved only 1.1% of edges, so the
relink assignment is dominated by geometry rather than by learned edge
probability. Expect small leaderboard movement; the higher-leverage knob is the
gate radius `MOTION_RELINK_TIGHT_UM`, which governs 97% of edges (Exp124).

## CRITICAL 2026-07-20: the local harness INVERTS leaderboard ranking

Exp121 ablated Exp110's post-processing on labelled train movies with the
official metric. Evidence:
`references/exp121-postproc-ablation-v2-output/exp121_postproc_ablation.csv`.

| ablation | nodes | edges | forks | adjJ_6bba |
| --- | ---: | ---: | ---: | ---: |
| full | 121,123 | 116,875 | 325 | 0.887733 |
| no_motion_relink | 119,488 | 114,353 | 405 | 0.906630 |
| no_gap_close | 117,653 | 112,980 | 361 | 0.880888 |
| no_filter_short_tracks | 125,790 | 120,306 | 325 | 0.885256 |
| no_safe_divisions | 120,853 | 116,351 | 0 | 0.887846 |
| no_linefit_smooth | 121,123 | 116,875 | 325 | 0.890191 |
| **ilp_only** | 124,740 | 115,776 | 0 | **0.908261** |

The harness is MECHANICALLY correct: the `ilp_only` control reproduces the Exp116
minimal branch almost exactly (`124,740` nodes / `115,776` edges versus Exp116's
`124,743` / `115,786`).

But its RANKING is inverted against the leaderboard:

```
local:  ilp_only 0.9083  >  full 0.8877   (delta -0.021)
LB:     ilp_only 0.877   <  full 0.909    (delta +0.032)
```

Same comparison, opposite sign, comparable magnitude. **Local scoring cannot rank
graph-construction choices.** Probable cause: train GT is very sparse - `50` to
`1,183` annotated edges against `25k-70k` cells per movie, under 2% coverage - and
edges touching no annotated node are ignored by the metric entirely. The
annotated subset behaves like a biased easy sample where the raw ILP is already
right, while motion relink earns its value in dense regions the local labels do
not cover.

### Consequence: separate LEADERBOARD-measured from LOCAL-measured claims

Trustworthy (measured on the public LB):
- Exp110-115 ILP disappearance sweep is flat (`0.908`-`0.909`).
- Exp116 minimal branch `0.877` versus Exp110 `0.909`.
- Exp101-104 division permissiveness `0.902`-`0.903`.
- Exp073 family `0.903`.

NOT trustworthy (local only, and the harness inverts rankings):
- Exp118 "inherited ILP costs already optimal".
- Exp117 "division weight 1.0 optimal" (also computed with the pre-patch metric).
- Exp121 stage contributions above.

So MORE axes are open than previously recorded, not fewer. Do not close an axis
on local evidence alone.

### What the harness IS still good for

- Structural validity (schema, dangling edges, degree caps, consecutive frames).
- Catching catastrophic regressions and crashes before spending a slot.
- Confirming a code path is actually active (the `ilp_only` control worked).

It is NOT a substitute for a leaderboard probe when ranking graph construction.

## CRITICAL: our local harness used the PRE-PATCH metric (found 2026-07-20)

- The metric vendored inside `pilkwang/biohub-tracking-support-pack-50ep-v1`
  (module `biohub_tracking`, built 2026-07-08) **predates the division-exploit
  patch** and still contains `_weakly_connected_components`. Verified by reading
  the source shipped in Exp110's kernel output.
- Every local score from Exp117, Exp118 and Exp121 therefore used the OLD metric.
- The official patched implementation is `royerlab/kaggle-cell-tracking-competition`
  at commit `075fc5f` (contains `aa65e90` "updating metric to patch weakly
  connected component exploit"), module `tracking_cellmot`. Measured diff:
  - `division_metrics.py`: `450 -> 574` lines; division scoring rewritten
    (weak connectivity replaced by directed local topology, plus new FP rules for
    cross-GT-component and locally-merged branches).
  - `metrics.py`: 90 changed lines. Edge side adds non-consecutive-edge filtering
    and duplicate-edge dedup.
- **Our EDGE conclusions survive**: both edge changes are no-ops for our graphs
  (`dropped_nonconsecutive_edges = 0`, max in-degree `1`, no duplicate edges).
- **Our DIVISION numbers do not.** Any local division result computed before
  2026-07-20 was produced with the wrong metric and must not be trusted -
  including Exp117's "zero division true positives".

## Official scorer is packaged for offline kernels

- `dalloliogm/biohub-official-scorer-patched` (private dataset) contains an
  unmodified copy of the repo at `075fc5f`, BSD 3-Clause, with `PROVENANCE.md`.
  Kaggle auto-extracts it to `/kaggle/input/biohub-official-scorer-patched/
  tracking_cellmot_075fc5f/src`, so kernels only need `sys.path.insert`.
- Always assert the patched version actually loaded:
  `_weakly_connected_components` must be ABSENT from
  `tracking_cellmot.division_metrics`. A silent fallback to the old metric is the
  failure mode this guards against.
- The repo also ships the round trip the hosts document:
  `scripts/csv_to_geffs.py` then `scripts/evaluate.py` scores a submission CSV
  against train GT with no images loaded. This means **any candidate can be
  scored offline before spending a submission slot.**
- Gotcha: `kaggle datasets create -p DIR` defaults to `--dir-mode skip` and
  SILENTLY DROPS subdirectories. Package source trees as a tarball (Kaggle
  auto-extracts) and verify with `kaggle datasets files` after upload.

## Validation

- Use embryo-disjoint folds and the official metric implementation. Frame-level
  or field-level random splits can leak embryo-specific appearance.
- Do not select parameters using proxies that weight division equally with edges,
  substitute node F1, or approximate the node-count penalty differently.
- Validation has to be layered. Structural submission validity is separate from
  score prediction: a candidate can be structurally valid but bad on public LB,
  and a locally promising candidate can fail to generalize. Use
  `scripts/biohub_validation_harness.py` for repeatable structural checks,
  component diagnostics, optional duplicated-frame diagnostics, and optional
  official-metric scoring when train predictions are available.
- Dataset-local `node_id` keys matter. A naive global `node_id` check produces
  false errors because Biohub node IDs are reused across datasets; validators
  must key edges and degrees by `(dataset, node_id)`.
- Suspicious-event review can remain submission-agnostic and dependency-light:
  endpoint joins plus physical distances identify long links and division
  geometry, while union-find component counts and edge-to-node ratios expose
  fragmentation. Midpoint residuals provide a useful review queue for likely
  interpolated gap nodes, but every flag remains a triage heuristic rather than
  an error label.
- Image crops should be optional rather than a hard dependency. The public review
  notebook tries installed Zarr first and the competition's Blosc2 timepoint
  chunks second; without raw OME-Zarr movies it still provides complete event
  tables, coordinate overlays, comparison counts, and a clear attachment prompt.

## Leakage And Rules

- Public notebook titles and claimed LB scores are not sufficient evidence. Inspect
  the active execution path and independently reproduce scores.
- External public artifacts are allowed, but learned pipelines must remain
  reproducible without notebook internet access.
- Public-facing competition notebooks need a different narrative than internal
  experiment logs: explain the graph task, the node/edge/division schema, and the
  single modeling idea; remove private experiment IDs and stale feedback blocks.

## Features

- Multi-scale DoG is the dominant classical detector. Refine coordinates on the
  original volume and perform NMS in physical units.
- Per-movie detection density/count calibration is promising but unvalidated.
- Physical NMS `3.8 um` outperformed `3.2 um` on both held-out embryos. Aggregate
  exact validation improved `0.794304 -> 0.810458`: edge counts changed from
  `761/63/134` to `757/44/138`, so removing false links outweighed five lost TPs.
- Lowering the DoG threshold to `0.030` added nodes without changing edge counts.
  Raising it to `0.060` slightly improved only the node-count adjustment; NMS was
  the higher-impact control.

## Models

- Auditable rule-based family: DoG -> physical NMS -> Hungarian linking -> gap
  interpolation -> isolated-node pruning.
- Ceiling-raising family: temporal 3D U-Net + learned edge model/transformer + ILP.
- Forum discussion suggests a promising higher-ceiling reformulation: temporal
  affinity or flow-field tracking, where short-track pseudo-labels supervise
  local displacement/link fields. The lowest-cost version for this workspace is
  not a new model from scratch, but rescoring candidate links using existing
  learned edge probabilities plus local motion consistency.
- Several notebooks labeled U-Net/ILP actually execute only the rule-based path.
- The actual pretrained `unet_transformer` + ILP pipeline scored `0.839409` exact
  validation versus `0.810458` for the best classical model. Aggregate edges
  improved from `757/44/138` to `815/58/80` (TP/FP/FN).
- The aggregate learned gain hid opposite embryo effects: learned was worse on
  `44b6` (`0.883791` vs classical `0.942567`) but better on `6bba` (`0.836847`
  vs `0.802713`). Prefix-aware model selection gives exact validation `0.842616`.
- Learned validation strongly improved `6bba` node recall (`0.8815 -> 0.9849`)
  but overpredicted its node estimate by `19.5%`; threshold calibration above
  `0.99` may be useful after obtaining the default test baseline.
- The locked learned model processed all four test movies in `398.04` prediction
  seconds on a Tesla T4. It produced `164,682` nodes, `140,110` edges, and 12
  divisions across `304,792` submission rows; all structural checks passed.
- Test detection density varies sharply by movie (`76.03` to `757.60` nodes per
  frame). Any threshold calibration should be embryo- or density-aware and must
  be validated before replacing the global `0.99` threshold.
- Kaggle's current PyTorch build does not support P100 `sm_60`. Learned kernels
  must request `machine_shape: NvidiaTeslaT4`.
- The LB893 public notebook is not just the earlier learned pipeline. It uses a
  different support pack (`pilkwang/biohub-tracking-support-pack-50ep-v1`) and a
  score-oriented post-processor on top of learned U-Net/transformer/ILP outputs.
  Its public submission `54397298` scored `0.893`.
- LB893 output is much more biologically constrained than our learned-only output:
  `134,238` nodes, `128,121` edges, and `381` division-like sources versus
  `164,682` nodes, `140,110` edges, and 12 divisions for our learned candidate.
- The largest LB893 graph change is motion relinking: it replaced `118,984` raw
  learned edges with `122,937` motion-relinked edges, mostly under a tight
  `6.2 um` gate plus a relaxed `10.4 um` pass. Treat the learned model as a
  detector/edge-probability generator, not as the final graph.
- Gap repair should be re-tested in the LB893 context. Classical gap-2 recovery
  was harmful, but LB893 added `2,100` one-frame gap nodes and `402` gap-2 nodes
  after motion relinking.
- Safe-division insertion is risky. Full LB893 validation scored `0.9548016411`
  on the selected two labeled movies with division counts `0/4/0`. Disabling only
  safe divisions improved exact validation to `0.9606407955`, removed all four
  division false positives, and slightly improved edge Jaccard (`0.9596510360 ->
  0.9606557377`). This split has no true scored divisions, so the learning is not
  "divisions are always bad"; it is that the current safe-division heuristic must
  prove itself before being used.
- Public LB corrected that interpretation: no-safe-divisions scored `0.886`,
  below the copied LB893 score `0.893`. The hidden/public test set rewards at
  least some safe divisions. The next promising axis is not removing divisions
  completely, but tuning their precision/coverage.
- Exp073 division candidates are geometrically tight already: among 418
  division-like parents, the parent-to-daughter max distance has median about
  `3.17 um`, 95th percentile about `4.16 um`, and maximum about `6.11 um`.
  Division calibration around Exp073 should therefore use ranked risk, caps, or
  recall/coverage gates rather than broad distance cutoffs such as `8 um`.
- Post-hoc deletion of a single daughter edge is unsafe as a submission strategy:
  Exp100 passed local CSV/graph checks but Kaggle rejected submission `54776292`
  as invalid format. Prefer calibrating division insertion inside the graph
  generator, or prune a complete invalid component with a stricter validator,
  rather than surgically removing one edge from an existing fork.
- Exp101 is the safer division-calibration pattern: alter safe-division insertion
  gates/caps upstream before CSV serialization. Its output increased
  division-like sources from `418` to `531` while preserving all local structural
  invariants. Public LB will decide whether Exp073 needs more division recall or
  whether those extra divisions are mostly false positives.
- Exp102 provides a milder point on the same upstream-safe-division axis:
  division-like sources `418 -> 442`, with only `+45` nodes and `+56` edges
  versus Exp073. Use Exp101 and Exp102 together to infer whether division recall
  helps monotonically, only mildly, or not at all.
- Exp103 reuses Exp102's mild division setting with Exp092's threshold+density
  graph recipe. It has the same total division-like sources as Exp102 (`442`) but
  a much larger graph delta (`+439` nodes and `+445` edges versus Exp073), so its
  LB result will mainly test interaction between mild division expansion and the
  threshold/density-gap branch.
- Exp104 is the safer way to test division precision after the Exp100 rejection:
  tighten safe-division insertion upstream, then let the generator emit a fresh
  valid graph, rather than removing one daughter edge from an already serialized
  fork.
- Exp104 provides the precision-side comparison to Exp101/Exp102: it reduces
  division-like sources from `418` to `351` while preserving almost the same node
  count (`128,217 -> 128,216`). The public LB result should indicate whether the
  Exp073 hidden-test division policy is over- or under-permissive.
- The 2026-07-17 division batch did not improve public LB: Exp101 and Exp103
  scored `0.902`, while Exp102 and Exp104 tied Exp073 at `0.903`. Nearby
  safe-division permissiveness is therefore not the next high-leverage axis.
  Move to gap-node geometry and other non-division graph-construction changes.
- Exp105 confirms the weighted gap-node interpolation branch is active on test:
  local motion was used for `2019/2020` synthetic gap nodes and the output SHA
  differs from Exp092. The graph size barely changed (`+2` nodes, `+1` edge
  versus Exp092), so its public LB will mostly test whether coordinates of
  inserted gap nodes matter rather than graph-density changes.
- Exp105, Exp106, and Exp107 all scored public LB `0.903`, tying Exp073. This
  means weighted synthetic gap placement, outside-reference spacing gating, and
  a mild density-gain increase are active but not enough to move the public
  leaderboard. Stop spending submission slots on nearby density/gap-radius
  micro-tuning unless a stronger validation harness identifies a specific
  recoverable error mode.
- Exp111 should be treated as an exploratory branch, not a leaderboard-first
  branch. The Exp092-family motion relinker already uses a learned-affinity bonus
  in its assignment cost, so the immediate learning gap is not "add learned
  affinity"; it is measuring whether risky graph regions are dominated by
  relaxed motion links, long serialized edges, gap additions, safe divisions, or
  dataset-specific short-track filtering.
- Exp110 is the first clear improvement after the `0.903` plateau: the user
  reported public LB `0.909` for submission `54826078`. The important mechanism
  is conservative ILP appearance/disappearance costs (`0.0` / `1.4`), not TTA
  enablement, because Exp092-family logs already had D4-style detection TTA
  active. The output was much smaller than Exp092-family runs (`238,534` rows,
  `121,403` nodes, `117,131` edges, `320` division-like sources), so the score
  suggests the public LB rewarded pruning weak tracks/nodes/divisions more than
  preserving the denser `0.903` graph.
- The completed ILP disappearance-cost sweep shows that the broad pruning move
  mattered, but tiny changes around it are saturated on the public LB. Exp112
  (`1.2`) made the graph denser and scored `0.908`, while Exp113 (`1.6`), Exp114
  (`1.5`), and Exp115 (`1.8`) all tied Exp110 at `0.909` despite removing
  progressively more rows. Do not keep spending leaderboard slots on nearby
  disappearance-cost micro-sweeps without new validation evidence or a distinct
  structural change.
- Exp111's final submission and downloaded raw GEFF graphs are sufficient to
  enumerate synthetic gap insertions exactly: gap nodes are the final node IDs
  absent from the raw GEFF node-ID set. They also show that all 418 final
  division-like sources correspond to the 418 safe divisions added in this run,
  so the first division review queue can focus on distance-to-gate geometry.
- Exp111 does not retain the tight-versus-relaxed motion pass on individual final
  edges; only per-dataset counts survive in `run_stats.csv`. Any per-edge relaxed
  queue reconstructed from the downloaded artifacts must therefore be labeled a
  proxy. The static report uses the highest-distance non-gap/non-division links
  after reserving the exact 10 longest final edges.
- Raw competition test microscopy Zarr volumes are not present locally. The
  first report remains usable as a 100-event graph review table with crop
  placeholders and unsaved manual-label controls. Its generator accepts an
  optional `--image-root` containing `<dataset>.zarr` volumes and will embed
  t-1/t/t+1/t+2 XY max-projection crops when Zarr support and images are present.

## RETRACTION 2026-07-20: the "post-processing is the bottleneck" claim was WRONG

**Measured, not inferred:** Exp116 - the clean minimal pipeline, byte-identical
config to `hengck23/minimal-baseline-tta-2gpu` - scored public LB **`0.877`**
(submission `54845958`). Our post-processing branch Exp110 scores **`0.909`**.

**The minimal branch is WORSE by `0.032`. The post-processing stack ADDS score;
it does not cost `-0.041`.** Everything in the section below is retracted except
the leaderboard/rank arithmetic and the metric mechanics.

### The reasoning error

I inferred "hengck23's notebook scores 0.950" from the fact that the AUTHOR's
team score is `0.950`. A team's leaderboard entry is the best of ALL their
submissions - hengck23 had **12** - not the score of any particular notebook.
This is exactly the failure mode `references/top-notebooks-analysis.md` already
warned about: *"Public notebook titles and claimed LB scores are not sufficient
evidence"* and *"Popularity is not evidence of performance."* I applied that rule
to notebook titles but not to author leaderboard scores, which are equally
indirect. **Never attribute a team's LB score to a specific public notebook.**

### What this implies about the 0.95 cluster

Clean minimal = `0.877`; the hacked forks = `0.950`. The gap of `+0.073` means
**the division-Jaccard hack is STILL PAYING on the live leaderboard**, so the
`aa65e90a` patch has not yet been applied to live scoring. The earlier inference
that "hacked forks score the same as the clean original, therefore the hack is
neutral" rested on the same false premise and is also retracted.

Consequence: the 165-team `0.950` cluster is hack-inflated and should collapse
toward ~`0.877` when the hosts rescore. Our `0.909` is a legitimate clean score
and is already ABOVE where that cluster would land. **Do not chase `0.950`.**

### What actually earns us the +0.032

Exp110 emits `320` division-like sources; Exp116 emits **zero** (the ILP never
divides at `division_weight=1.0`). The most plausible account is that the
post-processor's safe divisions earn real `division_jaccard` on the hidden test
set, worth roughly `+0.03`. This is consistent with the older measurement that
no-safe-divisions scored `0.886` against LB893's `0.893`.

**Exp117's "zero division true positives" was a local artifact.** The labelled
split contains only `3` annotated divisions, so it had no power to detect
division value. Divisions matter on the hidden test set. Do not use Exp117 to
argue against divisions.

### Local harness calibration, corrected

Local aggregate `0.914831` corresponds to public LB `0.877`, so the harness
**over-reads by ~`0.038`** (I previously wrote "under-reads by 0.035", derived
from the false `0.950` premise). It also has almost no division signal. Treat it
as a weak ranking signal for EDGE quality only.

### Axes now closed by measurement

- ILP division weight (Exp117): `1.0` optimal; lower values add forks, no TPs.
- ILP cost grid (Exp118, minimal branch): the inherited `appearance 0.0 /
  disappearance 1.4 / edge -1.0` is already optimal; all 10 configs within
  `0.007`, default wins.
- ILP disappearance on the old branch (Exp110-115): flat `0.908`-`0.909`.

### Standing conclusion

`Exp110` (`0.909`) is our best and remains the working baseline. The productive
direction is the post-processing branch plus its divisions - NOT the minimal
branch. Detection threshold on the minimal branch (Exp119 `0.98`, submitted as
`54848728`) is expected to land near `0.877` and is likely a spent slot.

## CRITICAL 2026-07-20: our post-processing stack is the bottleneck [RETRACTED - SEE ABOVE]

- Verified from the live leaderboard (1414 teams) and source inspection:
  `hengck23/minimal-baseline-tta-2gpu` scores public LB `0.950` using the SAME
  weights pack (`pilkwang/biohub-tracking-support-pack-50ep-v1`, split_0), the
  SAME ILP weights (`edge -1.0`, `appearance 0.0`, `disappearance 1.4`,
  `division 1.0`), the SAME detection threshold (`0.9700` vs our `0.96875`), and
  D4 TTA — which our Exp110 also has (kernel logs confirm `TTA patch applied`).
- The ONLY material difference: hengck23 exports the ILP graph VERBATIM
  ("Direct node export. Rounding is only CSV serialization."). It has NO motion
  relink, NO gap closing, NO short-track filter, NO linefit smoothing, NO safe
  divisions. Our Exp110 runs 13 post-processing stages on top.
- Therefore our inherited Exp073/LB893 post-processing stack costs about
  `-0.041` of score. We are at `0.909`; the same model with no post-processing
  is at `0.950`.
- Mechanism: `filter_output_graph` step 4 does `edges = motion_edges`, a TOTAL
  REPLACEMENT that discards all `114,860` ILP edges and rebuilds association with
  a greedy causal two-pass Hungarian sweep. The global ILP optimum is thrown away;
  the ILP only determines which nodes survive.
- This explains the plateaus. The ILP disappearance sweep is flat because its
  edges are discarded: `1.2 -> 0.908`, `1.4/1.5/1.6/1.8 -> 0.909`. And the whole
  heavy-post-processing lineage is capped: `pilkwang` (author of the weights
  pack) `0.903` with 80 submissions, `beicicc` `0.903` with 71, `romanrozen`
  `0.903`, `chenwensheng` `0.903`. Everyone on the minimal branch is at `0.950`.
- Do NOT tune post-processing heuristics on top of the ILP. Fix or delete the
  post-processing and let the global optimizer's output stand.
- Exp116 confirmed that two clean routes to the minimal public-solution branch
  are exactly the same output. The direct export built from
  `hengck23/minimal-baseline-tta-2gpu` and the hack-stripped
  `kaiwalyaatulraut/biohub-cell-tracking-solution` both produced SHA256
  `dbba5f419e5b341bf0b413154ebf785bcf9caa19857f21f6242b012ebc65cd90` with
  `240,529` rows, `124,743` nodes, `115,786` edges, and zero divisions. Treat
  them as one experiment, not two independent submission candidates.
- Exp117 used the official local metric on labelled train movies to test whether
  the minimal ILP branch merely needed cheaper divisions. It did not. The default
  `ILP_DIVISION_WEIGHT=1.0` was locally best (`0.914831`) and emitted zero forks;
  cheaper/negative division weights emitted hundreds to thousands of forks but
  still found zero true-positive divisions on the labelled split. Lowering the
  division cost alone trades edge quality for false forks. Any division gain must
  come from better division candidates/features or a more selective division
  scorer, not a blind cost sweep.

## Metric mechanics confirmed from official source

- Read from `royerlab/kaggle-cell-tracking-competition`
  (`src/tracking_cellmot/metrics.py`, `division_metrics.py`, `metrics.md`).
- `adj_edge_jaccard = max(0, edge_jaccard * (1 - 0.1 * (N_pred - N_true)/N_true))`
  where `N_true` is `estimated_number_of_nodes` from GEFF metadata (ALL cells,
  including unannotated). **If `N_pred < N_true` the multiplier exceeds 1 and the
  adjusted score can exceed the raw Jaccard.** Under-predicting nodes is rewarded.
  This is an untapped, legitimate calibration axis.
- Edge FP uses OR, not AND: `pred_valid = out_valid(source) OR in_valid(target)`.
  Once a predicted node matches an annotated GT node with any GT out-edge, every
  outgoing predicted edge is forced to TP or FP; there is no ignore escape.
- FP and FN are structurally coupled, so fixing a MIS-LINK is worth ~2x either
  error alone: `d(J)` per mis-link fixed `= (1+J)/D` vs `1/D` for a recovered FN.
- `adj_edge_jaccard` is weight-averaged across datasets by `TP+FP+FN`;
  `division_jaccard` is pooled (micro) across datasets, then one Jaccard.
- Our detection is NOT the problem: measured `node_recall` `1.0000` and `0.9988`.
  All edge loss is linking loss.

## Division-metric exploit: patched, and already neutral

- The exploit welded predictions into one weakly connected component plus fake
  forks (hub node at `t=-1000`, coords `-10000`, `FORKS=5`,
  `MAX_COMPONENTS=1400`), making every GT division a free TP.
- Patched in commit `aa65e90a` (2026-07-17): `_weakly_connected_components` was
  replaced by `_is_strongly_connected_division` requiring directed local topology.
- Evidence the patch is ALREADY live in scoring: hacked forks score exactly the
  same as the clean original (`outwrest` `0.950` = `hengck23` `0.950`;
  `kaiwalyaatulraut`, `navazshfathi`, `nikitagajbhiye30` all `0.950`). If the
  exploit still paid, they would be above it.
- Therefore `0.950` is a legitimate clean score, NOT a hack score. Do not avoid
  it on ethics grounds, and do not expect a rescore to lift us past that cluster.
- The patch also hardened the edge side (non-consecutive edges dropped, duplicate
  edges deduped, out-degree capped at 2). All three are neutral for us:
  `dropped_nonconsecutive_edges=0`, `max_indegree=1`, `max_outdegree=2`.

## Exp117 division-weight sweep: RESOLVED 2026-07-20

Measured with the OFFICIAL metric on 5 labelled train movies. Evidence:
`references/exp117-division-sweep-v3-output/exp117_division_sweep.csv`.

| `ILP_DIVISION_WEIGHT` | forks | div TP | div FP | adj_edge_jaccard |
| ---: | ---: | ---: | ---: | ---: |
| `1.0` (current) | 0 | 0 | 0 | **0.914831** |
| `0.5` | 984 | 0 | 14 | 0.912502 |
| `0.25` | 1,048 | 0 | 16 | 0.911566 |
| `0.0` | 1,223 | 0 | 17 | 0.910153 |
| `-0.25` | 1,653 | 0 | 27 | 0.901540 |
| `-0.5` | 3,574 | 0 | 55 | 0.883607 |
| `-1.0` | 3,611 | 0 | 55 | 0.884176 |

- Sign convention confirmed: LOWER `ILP_DIVISION_WEIGHT` produces MORE forks.
- **Keep `ILP_DIVISION_WEIGHT = 1.0`.** It is optimal. Every lower value costs
  edge accuracy monotonically and returns nothing.
- **Zero division true positives at every setting**, including with `3,611`
  forks. ILP cost tuning generates divisions in the wrong places; this is not a
  viable route to the `0.1 * division_jaccard` term.
- Caveat on power: the labelled set contains only **3** annotated divisions in
  total (all in `6bba_05db0fb1`), so the division term is nearly unmeasurable
  locally. This does not prove divisions are worthless on the hidden test set;
  it proves naive ILP-cost-driven fork generation does not find them.

## What the local harness actually measures

- **Calibration point:** the minimal pipeline scores `0.914831` locally while the
  identical config (`hengck23/minimal-baseline-tta-2gpu`) scores `0.950` on the
  public LB. The harness under-reads by about `0.035`. Treat local numbers as
  RANKING signal, not absolute score prediction.
- **The 44b6 movies are useless for validation.** They carry ~50 GT edges each
  and we score them perfectly (`edge FP = 0`, `edge FN = 0`). Any change will
  look neutral there.
- **The node-count bonus multiplier is real and active.** `44b6_0b24845f` returns
  `adj_edge_jaccard = 1.03006` - above 1.0 - because we predict `22,937` nodes
  against `n_total = 32,795`. Confirms `adj = J * (1 - 0.1 * (N_pred-N_true)/N_true)`
  exceeds `J` when under-predicting.
- **Essentially all measurable loss sits in one movie.** Per-movie at the current
  config:

| dataset | nodes | edge TP | edge FP | edge FN | adj_edge_jaccard | local weight |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `44b6_0113de3b` | 25,533 | 50 | 0 | 0 | 1.00086 | 2% |
| `44b6_0b24845f` | 22,937 | 49 | 0 | 0 | 1.03006 | 2% |
| `44b6_33b596bf` | 24,431 | 49 | 0 | 0 | 0.99528 | 2% |
| `6bba_05b6850b` | 6,311 | 821 | 3 | 24 | 0.96894 | 38% |
| **`6bba_05db0fb1`** | **69,962** | **1,095** | **79** | **88** | **0.86747** | **56%** |

- `6bba_05db0fb1` is the highest-leverage target by a wide margin: fixing its
  `79` FP and `88` FN is worth roughly `+0.07` aggregate, and because edge FP and
  FN are structurally coupled, each mis-link fixed counts about double.
- It is also the densest movie (~757 nodes/frame) AND a `6bba` movie, the prefix
  carrying the duplicate/frozen-adjacent-frame artifact. Frozen-transition-aware
  linking (Exp108) tied at `0.903` on the old post-processing branch, but was
  never tested on the minimal branch - and is now measurable locally at zero
  submission cost.

## Ensembling And Submission Behavior

- One-frame gaps must be represented by an inserted node and consecutive edges;
  a direct edge across missing frames is not equivalent under the metric.
- Divisions should be conservative because their final weight is only 0.1 and a
  wrong daughter edge can hurt both metric components.
- Conservative velocity-aware gap-2 recovery did not recover any annotated edge
  on the two held-out embryos. It added 148 nodes, left aggregate edge TP/FP/FN
  unchanged at `761/63/134`, and reduced adjusted edge Jaccard by `0.000764`.
  Do not add interpolated nodes unless validation shows corresponding edge gains.

## Leaderboard Notes

- Self-reported public scores seen in reviewed notebooks range from roughly 0.72
  for classical baselines to 0.835-0.839 for newer rule-based variants, but these
  claims were not independently verified from the pulled source snapshots.
- Full review: `references/top-notebooks-analysis.md`.
- First verified public score: `0.827` for submission `54297736`.
- Physical NMS `3.8 um` improved public LB to `0.834` (submission `54307212`),
  but the current top-10% boundary is about `0.856` across 630 teams. The `0.022`
  gap is too large to justify continued nearby NMS tuning as the primary strategy.
- Learned-only submission `54323397` scored `0.810`, materially below the
  classical NMS-3.8 score `0.834`. Aggregate validation alone was misleading;
  preserve the classical model on `44b6` and test learned tracking only on the
  embryo prefix where its held-out edge recall improved.
- Copied public LB893 submission `54397298` scored `0.893`, superseding the
  prefix-aware hybrid as the working baseline. Future changes should ablate and
  improve LB893 rather than continue tuning the older classical/learned branch.
- No-safe-divisions scored `0.886`. This is competitive and novel, but it is not
  the new best. It indicates that the selected exact validation split is not
  representative for division tuning.
- Recent public notebooks on 2026-07-16 shifted the strongest graph recipe away
  from LB893 safe-division-only tuning. Exp073-style notebooks use lower
  detection threshold (`0.9700`), short-track filtering (`min_track_len=6`),
  gap2 disabled, two-frame gap close at `5.8 um`, learned motion bonus `1.0`,
  and safe divisions with looser sister radius `8.5`. Our copied Exp073 run
  produced `251,900` rows, `128,217` nodes, `123,683` edges, `418` divisions,
  and removed `6,435` short-track nodes. This suggests track-density cleanup and
  gap calibration are higher-leverage than continuing to tune only safe
  divisions.
- The copied Exp073 run scored public LB `0.903` as submission `54758569`,
  confirming the recent public-notebook claim and making Exp073 the new working
  baseline. Future original variants should modify Exp073 one mechanism at a
  time rather than reverting to LB893-only safe-division tuning.
- Private Kaggle notebook outputs are mounted under
  `/kaggle/input/notebooks/<owner>/<slug>/`. For composition kernels, discover
  expected files defensively and verify source identity before merging.
