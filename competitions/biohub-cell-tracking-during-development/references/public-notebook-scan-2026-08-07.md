# Public notebook scan - 2026-08-07

First scan since `recent-public-notebooks-2026-07-17.md`. Covers everything
published between 2026-08-02 and 2026-08-07. Four items carry new information;
the rest are forks of `saitejabandaruin/biohub-top-notebook-0-913` and of the
pilkwang backbone we already run.

**Discussion forum could not be read.** `kaggle forums topics list
biohub-cell-tracking-during-development` returns `403 Forbidden` from
`discussions.DiscussionApiService/ListTopics` (the general forum works, so the
competition forum is simply not exposed to the CLI token), and the web
discussion index is client-rendered so `WebFetch` returns only the page title.
Everything below is from notebook source, which is authoritative in a different
way: it is the configuration people actually ran.

---

## 1. The 0.915 stack is ours plus two components - `yusuketogashi`

`no-hack-biohub-cell-another-approch-3rd` (115 votes, 2026-08-05) is the
"Biohub 162" step on top of **Biohub 159B, stated clean LB `0.915`**.

The decisive fact: **their environment-variable namespace is identical to ours**
(`BIOHUB_DET_THRESHOLD`, `BIOHUB_SAFE_DIV_FRAME_FRAC_CAP`,
`BIOHUB_GAP_DENSITY_GAIN`, ...). Same codebase lineage, so their config block is
a line-by-line diff against our Exp148 rather than a different pipeline that
happens to score higher.

Config that MATCHES our Exp148 exactly:

| key | theirs | ours |
|---|---|---|
| `DET_THRESHOLD` | 0.96875 | 0.96875 |
| `SAFE_DIV_FRAME_FRAC_CAP` / `GLOBAL` | 0.0076 / 0.00375 | 0.0076 / 0.00375 |
| `OUTPUT_MIN_TRACK_LEN` | 6 | 6 |
| `GAP_CLOSE_MAX_GAP` / `_UM` | 2 / 5.8 | 2 / 5.8 |
| `BIDIRECTIONAL_EDGE_WEIGHT` / mode | 0.20 / harmonic_probability | 0.20 (Exp166, neutral) |

Independent convergence on the division budget and detection threshold is a
useful negative: those axes really are closed, for them as well as us.

**Config we do NOT have at all** - no `LOCAL_RANKER` or `EDGE_TTA` key exists
anywhere in our notebooks:

```
BIOHUB_USE_LOCAL_ASSOCIATION_RANKER = 1
BIOHUB_LOCAL_RANKER_MODE            = full_motion_assignment
BIOHUB_LOCAL_RANKER_FULL_WEIGHT     = 0.85
BIOHUB_LOCAL_RANKER_PRIMARY_RETAIN_WEIGHT = 0.15
BIOHUB_LOCAL_RANKER_MARGIN_UM       = 0.35
BIOHUB_LOCAL_RANKER_MIN_ADVANTAGE   = 0.15
BIOHUB_EDGE_TTA_MODE                = js_reliability_log_pool
BIOHUB_EDGE_TTA_VIEWS               = 4
```

They also run DeepCenter **entirely off** (`USE_DEEPCENTER_VETO=0`,
`DEEPCENTER_CHECKPOINT=''`) where we use it for gap confirmation, and ILP
weights appearance `0.0` / disappearance `1.5` / division `1.0`.

### The local association ranker

Artifact: `pilkwang/biohub-local-association-ranker-unet300-v1` - **public,
18,994 bytes, 327 downloads**. We catalogued it once (`TASKS.md:770`, "small
alternate linker/reranker") and never tried it.

19 KB means a small tabular model, not a network. Reading their implementation,
it scores each *candidate* association edge from ~22 cheap graph/geometry
features computed after detection:

- `edge_prob` from the primary model, `has_learned_edge`
- source/target in-degree and out-degree in the raw candidate graph
- source/target frame occupancy, `t` normalised by movie length
- raw distance, motion-predicted distance, xy-only distance
- **local density: neighbour count within 7 µm** (`cKDTree.query_ball_point`)
- candidate rank by distance, candidate count

At `FULL_WEIGHT=0.85` this is the *dominant* association signal in their stack;
the primary model's own edge probability is retained at only `0.15`. There is no
extra GPU inference - it runs on the candidate list we already build.

**Why this is the right thing to try.** Every error analysis now agrees the
remaining loss is a *wrong-partner* choice, not a missing detection or a missing
link, and that motion models cannot fix it:

- our Exp170: 42 of 97 missed GT edges were correct in the ILP; 33 of those had
  the correct child *replaced*, the substitute at a median **128.8°** from the
  true step;
- tomasa2 (below): 57% of losses are wrong-partner, and the correct target sits
  a median **6.08 µm** away against a 1.8 µm typical displacement;
- our Exp164: generic pairwise swap repair accepted **0 of 5,842** candidates.

A discriminative re-ranker with density and degree context is precisely the
"sharper discrimination" that a cost-function tweak cannot supply, and it is the
one structural component separating our 0.913 from their 0.915.

---

## 2. Metric mechanics, measured on synthetic graphs - `nekkon`

Two short notebooks that build graphs by hand and run the host's own evaluator.

`your-linker-cannot-score-a-single-division` (2026-08-07):

1. **Over-detection is nearly free.** An unmatched predicted node is never an
   edge FP; the entire cost is the node-count term
   `1 - 0.1·(T_pred - T_true)/T_true`. Doubling the node count costs 10% of edge
   Jaccard, so 10% more detections need only a **1% relative** edge-Jaccard gain
   to break even.
2. **A duplicate detection costs ~9% and buys nothing.** Node matching is
   one-to-one bipartite, so a twin one voxel away matches nothing at all -
   invisible except to the node count. Measured on a *perfect* prediction, score
   goes `1.1000 -> 1.0000 -> 0.9000` while edge Jaccard stays `1.0000`. TTA that
   unions detections instead of clustering them pays this in full.
3. A strictly one-to-one linker scores division Jaccard **exactly 0.000**, i.e.
   forfeits 0.1 of the available 1.1 by construction.
4. The `aa65e90` patch (2026-07-17) changed three things: directed local topology
   for divisions, a consecutive-frames filter on edges, and merge collapsing.

Point 4 is already handled here - our harness is pinned to `075fc5f`, which
contains `aa65e90` (`LEARNINGS.md:713`), and we verified
`dropped_nonconsecutive_edges=0`, `max_indegree=1`, `max_outdegree=2`. Points 1
and 2 are actionable and are items 3 and 5 in the plan below.

`the-linking-radius-is-8-4-um` (2026-08-06), measured over all 199 training
movies and 128,883 GT links:

- frame-to-frame displacement median **1.82 µm**, p95 **5.34 µm**, p99 **8.38 µm**;
- **151 divisions across all 199 movies - one link in 853**;
- ~22 annotated tracks per movie, ~30 frames each, and **100% of GT edges span
  exactly one frame** - the GT never skips a frame inside a track, so an
  unannotated blob is not a missed detection.

The division rate is the number to act on. We emit **333 divisions on 117,913
edges = one in 354**, about **2.4x the ground-truth rate**. Our own bracket is
consistent with over-proposal: 2x budget (Exp155) scored `0.912`, half budget
(Exp159, 213 divisions = 1 in 553) tied at `0.913`. Nobody has tested the
natural rate.

---

## 3. Eleven changes, three helped - `tomasa2`

`biohub-what-worked-and-what-didnt-for-me` (11 votes, 2026-08-06). LB 0.841 on a
weaker association stack, but the measurements are paired across 16 movies and
the null results are the point.

**Their structural decomposition over 6 movies / 1,178 GT edges:**

| | count | share of losses |
|---|---|---|
| correct | 1084 | - |
| linked to the **wrong** partner | 52 | **57%** |
| both endpoints found, no link made | 29 | 32% |
| an endpoint not detected | 10 | 11% |
| division semantics wrong | 3 | 3% |

Wrong-partner breakdown: 21 had the correct target taken by a competing source,
20 ranked it worse on cost, 11 had it outside the gate. The correct target sits
a median **6.08 µm** away against 1.8 µm typical displacement - cells that
*suddenly accelerated*, which no past-velocity extrapolation can reach. That is
their explanation for why every cost-weight variant came back null, and it
matches our own Exp164 result exactly.

**Nulls worth having** (all measured, paired): divisions `-0.007`; gap repair
`-0.003`, better on 0 of 6 movies; per-movie adaptive gate `+0.001, p=0.85`; ILP
vs greedy Hungarian `-0.001, p=0.84`; cost-weight tuning inert; harmonic
bidirectional fusion **provably zero** on their hints (100% exclusive, fused
value identically 1.0 at every lambda - a cleaner explanation of our own Exp166-168
tie than "the backbone is saturated").

**Their one positive is a warning for us:** all their `det_threshold` gains
(`0.826 -> 0.832 -> 0.838 -> 0.841`) were **entirely the over-prediction
penalty**. Raw edge Jaccard was flat from 0.5 to 0.96875; only `detect_ratio`
moved. "If your local scorer computes only edge Jaccard, it cannot see this."

Two methodological notes they paid for: per-movie scores span 0.70-0.99, so an
unpaired six-movie mean is worthless (the same config measured 0.921 on one
six-movie sample and 0.824 on another); and two of their own diagnostics were
silently measuring nothing until a control group was added.

---

## 4. Ranked plan

1. **Port the local association ranker.** Highest expected value. Attacks the
   57%/43% wrong-partner class that four independent analyses converge on, needs
   no extra GPU inference, the artifact is public and 19 KB, and it is the main
   structural difference between our `0.913` and a stated clean `0.915`. Port at
   their weights first (`0.85 / 0.15`, margin `0.35`, min advantage `0.15`) - a
   weight sweep is a second experiment, not part of the first.
2. **Four-view JS-reliability edge TTA** (`js_reliability_log_pool`). The other
   component we lack. Same model, four views, pooled by JS reliability. Second
   because it is an evidence-quality change on top of the same association
   choice the ranker makes.
3. **Duplicate-node audit - no submission slot, no kernel.** Run a KD-tree over
   the node rows of the last submission and count pairs closer than ~2 µm in the
   same frame. Each duplicate is worth ~9% of the score for nothing. This is
   arithmetic on a file we already have; it either finds free score or closes the
   question in an hour.
4. **`detect_ratio` audit - also free.** `LEARNINGS.md:1045` already flags "if
   `N_pred < N_true` the multiplier exceeds 1 ... untapped, legitimate
   calibration axis", and tomasa2 measured that this term, not edge Jaccard, was
   where their gains came from. Compute `N_pred / estimated_number_of_nodes` per
   dataset and find out which side of 1.0 we are on before touching a threshold.
5. **Divisions at the natural rate.** One slot. Cut the safe-division budget to
   land near **one division per 853 edges** (~140, vs our 333). Our own half-budget
   point tied rather than lost, so the gradient permits it, and 1-in-853 is
   measured from all 199 movies rather than guessed.

Items 3 and 4 are pure measurement and should run first regardless - they cost
no slot and no GPU quota, and item 4 gates whether any threshold change is even
worth a slot.

**Harness caveat still stands.** The labelled-movie harness is anti-predictive
for post-processing changes (2026-08-05, three monotone points). Items 1 and 2
are model-level rather than post-processing so that finding does not directly
apply, but neither does the harness earn trust as a gate. Items 3 and 4 are
arithmetic on the metric definition and are unaffected either way.

## Sources

- `yusuketogashi/no-hack-biohub-cell-another-approch-3rd` (115 votes, 08-05)
- `nekkon/your-linker-cannot-score-a-single-division` (08-07)
- `nekkon/the-linking-radius-is-8-4-um` (4 votes, 08-06)
- `tomasa2/biohub-what-worked-and-what-didnt-for-me` (11 votes, 08-06)
- `pilkwang/biohub-local-association-ranker-unet300-v1` (dataset, 18,994 bytes)
