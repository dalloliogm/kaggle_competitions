# Seed-Selection / LB-Overfitting Audit — Biohub Cell Tracking

**Date:** 2026-09-09 · **Scope:** `competitions/biohub-cell-tracking-during-development`
**Prompt:** a comment on *"The 0.950 Cluster: What Happens After the Rescore"* alleging that
entries near LB 0.950 (and the 0.94–0.95 band generally) are reached by sweeping/cherry-picking
random seeds rather than by genuine modeling gains.

**Sources audited:** `APPROACHES.md`, `TASKS.md`, `LEARNINGS.md`, `NOTES.md`,
`references/*.json` (`incumbent_manifest`, `validation_split_manifest`,
`sep06-live-submissions`, `sep06-diverge50-graph-audit`, `sep07-public-reproduction-execution`,
`factorial_experiment_manifest`), and the ~90 `notebooks/biohub-exp*` kernels + metadata.

---

## 1. Headline conclusion

**The specific accusation does not apply to this workspace. A different, more serious
version of it does.**

1. **No random-seed sweeping exists here.** Across every logged experiment (Exp073 → Exp209,
   the detector-fusion sweep, the division-geometry bracket, the Sep-05/06 probe batches) there
   is **not one submission whose only difference from another is an RNG seed.** No training is
   done in the submission path at all — every candidate runs *fixed, public, pretrained
   checkpoints* in inference. The word "seed" in this repo means a **fixed public checkpoint
   identity** (seed A = `pilkwang/biohub-tracking-support-pack-50ep-v1`,
   seed B = `biohub-temporal-unet3d-seed314159-v1`), not a sampled RNG state.
2. **LB scoring here is deterministic.** Exp188 produced a byte-identical output signature to
   Exp183 and scored the same `0.915`; the `sdec12` candidate reproduced the `.65` incumbent
   byte-for-byte. Identical bytes ⇒ identical score. There is therefore **no run-to-run RNG
   noise floor to cherry-pick from.**
3. **But the recent 0.94x numbers are not model improvement either.** They are **byte-identical
   reproductions of other people's public notebooks** (§4). And the own-tuning ladder that
   produced 0.936 → 0.938 → 0.939 sits **entirely inside the public-test sampling noise band**
   (§5). So the commenter's *conclusion* — that this band reflects public-LB fitting rather than
   task improvement — is substantially correct for these runs; the *mechanism* is public-notebook
   adoption plus max-picking over a flat, noisy axis, not seed roulette.

---

## 2. Evidence table — recent experiments

Seed column is uniform because no run varies one. `CV` = the repo's local official-metric
harness on labelled train movies.

### 2a. Detector-fusion sweep — 2026-09-01 (the "det-065…095" runs)

| Run | Seeds | What changed | Local CV | Public LB |
| --- | --- | --- | --- | ---: |
| det-065 | A+B fixed | secondary detector weight `.65` | not predictive (see §6) | 0.927 |
| det-075 | A+B fixed | weight `.75` | " | 0.928 |
| det-080 | A+B fixed | weight `.80` | " | **0.930** |
| det-085 | A+B fixed | weight `.85` | " | 0.929 |
| det-095 | A+B fixed | weight `.95` | " | 0.928 |

Single hyperparameter, everything downstream frozen. **Range 0.003, sd ≈ 0.0011.**
`APPROACHES.md` records the local proxy as *"not predictive of LB"* for this whole sweep.

### 2b. Division-geometry stack + fusion bracket — 2026-09-04

| Run | Ref | What changed vs previous | Local CV | Public LB |
| --- | --- | --- | --- | ---: |
| div45 geometry, fusion `.65` | 55979072/76 | **new mechanism**: Rishabh `9/14/4.5 µm` sister/max/divergence caps | none reported | 0.936 |
| div45, fusion `.75` | 56017062 | fusion weight only | none reported | 0.935 |
| div45, fusion `.80` | 56010101 | fusion weight only | none reported | **0.938** ← frozen incumbent |
| div45, fusion `.85` | 56017063 | fusion weight only | none reported | 0.932 |
| `sdec12` | — | `SAFE_DIV_EXISTING_CHILD_MAX_UM=12` | — | *byte-identical to `.65`; blocked* |

**Range across a 4-point weight bracket: 0.006, sd ≈ 0.0025 — larger than the sweep in 2a,
and non-monotonic** (`.80` is a spike sitting between two *lower* neighbours `.75` and `.85`).

### 2c. Five-probe gap/threshold factorial — 2026-09-05

| Gap µm | Div threshold | Ref | Public LB |
| ---: | ---: | --- | ---: |
| 5.0 | .25 | 56029383 | 0.935 |
| 5.0 | .12 | 56032186 | 0.938 |
| 5.8 | .25 | 56032312 | 0.935 |
| 5.0 | .18 | 56032624 | 0.936 |
| 5.4 | .25 | 56032813 | 0.935 |

All arms share `.80` fusion. Nothing beat the incumbent. Repo's own note: *"no beneficial
gap/threshold interaction"*, and *"the public 0.941 claim was not reproduced."*

### 2d. Threshold / TTA / post-processing batch — 2026-09-06

| Candidate | Ref | Public LB |
| --- | --- | ---: |
| Image threshold `.08` | 56050357 | **0.939** ← current own best |
| Retention `.95` | 56051153 | 0.937 |
| Divergence 5.0 | 56050349 | 0.933 |
| Image `.08` + divergence 5.0 | 56050780 | 0.933 |
| Symmetry `.45` | 56050782 | 0.933 |

**Range 0.006 across five small post-processing perturbations of one frozen detector.**

### 2e. Historical plateau blocks (for scale)

| Block | Runs | Public LB |
| --- | --- | ---: |
| ILP disappearance sweep (Exp110/112/113/114/115) | 3.6k-node swing | 0.908–0.909 |
| Exp159–168 "thirteen consecutive ties" | division budgets ×0.5/×2, two division re-rankings, 637 and 687 edge replacements, model-level bidirectional fusion at 3 weights | **0.913 every time** |
| Exp183/187/188/193/195 | ranker/lookahead/TTA variants | **0.915 every time** |
| Exp135 reseed ensemble | *closest thing to a seed change*: independent same-arch checkpoint (v34) added to the ensemble | 0.908 vs 0.910 baseline (**worse**) |

---

## 3. Do jumps track seeds more than modeling changes?

**Not testable as posed — no seed-only runs exist.** The nearest proxies both point away from
seed diversity being a lever at all:

- **Exp135** (independent same-architecture retrain added to the ensemble — the "seed ensembling"
  the commenter implicitly recommends) scored **0.908 against a 0.910 baseline.** Recorded verdict:
  *"reseed diversity is a dead end."*
- **Exp133** (3-member checkpoint ensemble) never returned a usable score.
- **Exp129** (fine-tuning the full model) scored **0.900 vs 0.910** — worse.

So on this task, the checkpoint/seed axis is *measured, and it is flat-to-negative*. Nobody in
this workspace could have climbed to 0.94x by seed selection even if they had tried.

**What the jumps actually track:** adopting someone else's pipeline. Every real step up in the
log is an import, not a tune — 0.834 (own classical) → 0.893 (copied LB893) → 0.903 (Exp073 public
recipe) → 0.913 (pilkwang two-seed blend) → 0.915 (public ranker stack) → 0.917 (public classical
ensemble) → 0.930 (Rishabh recipe) → 0.936/0.938 (Rishabh division geometry) → 0.946 (public
edge-feature TTA). The **one internally-derived jump above noise** is the `9/14/4.5` division
geometry adoption at fixed `.80` fusion: 0.930 → 0.938, **+0.008**, which is ~2–3× the noise band
and is mechanism-attributable. Everything else in the 0.93x band is ±0.003 shuffling.

---

## 4. The 0.94x runs are reproductions, not results

`references/sep07-public-reproduction-execution.json` is unambiguous:

| Candidate | Public source | Public LB | Our artifact |
| --- | --- | ---: | --- |
| Edge-feature TTA | `redoctopusk/biohub-942tta` v1 | 0.946 | `byte_identical_to_public_scored_output: true`, ref 56075335 **PENDING** |
| Threshold `.960` | `busyaprime/biohub-0-942-lb-one-knob-past-the-public-line` v2 | 0.942 | byte-identical, **held, unsubmitted** |

**Own scored frontier is 0.939.** The 0.942/0.946 figures are provenance of the public artifacts;
`LEARNINGS.md` already states this correctly (*"0.946 remains public-source provenance rather than
our confirmed score"*). If asked publicly whether the 0.94x is a genuine modeling gain, the honest
answer is: it is a verified reproduction of a public notebook, and the private-LB transfer is
unknown.

---

## 5. The noise floor

Because scoring is deterministic, the relevant noise is **public-test sampling noise**, not RNG.
Three independent estimates converge on the same number:

**(a) From the metric's own sensitivity.** The repo's derivation (`TASKS.md`, "THE ACTUAL REASON
FOR THE 13 TIES"): ground truth is *sparse* — ~2,258 scored edges total across labelled movies,
with `6bba_05db0fb1` carrying ~56% of the weight. With `d(J)` per fixed mis-link `= (1+J)/D` and
mis-links counting double, **one mis-link ≈ +0.0008 aggregate, i.e. 1–2 edge decisions = 0.001 LB.**

**(b) From the winning submission's actual diff.** The 0.939 result (56050357) beat the 0.938
control by changing, in total, **18 node rows, 2 edges removed and 3 added, on one movie**
(`references/sep06-diverge50-graph-audit.json` and the Sep-06 handoff note). Five edge changes
buying +0.001 is *exactly* what (a) predicts for a coin-flip, not for a real improvement.

**(c) From dispersion within frozen-detector brackets.** Across every batch where only a scalar
post-processing knob moved on an identical detector:

| Batch | n | Range | sd |
| --- | ---: | ---: | ---: |
| det-fusion 065–095 | 5 | 0.003 | 0.0011 |
| div45 fusion bracket | 4 | 0.006 | 0.0025 |
| Sep-05 gap/threshold | 5 | 0.003 | ~0.0012 |
| Sep-06 threshold/TTA | 5 | 0.006 | ~0.0027 |

**Pooled: sd ≈ 0.002, observed range 0.003–0.006.**

There are only **four test movies** (25,470 / 18,540 / 6,044 / 69,285 predicted nodes), one of
which dominates the weight, and only ~2% of edges are scored at all. That is a tiny effective
sample; a ±0.003 band is the expected consequence.

> **Noise band: ≈ ±0.003 (2σ ≈ 0.004–0.005).**
> **Improvements currently being chased: 0.001–0.002.**
> The signal being optimized is roughly **half the size of the noise**, and the log contains
> 5 batches × ~5 arms ≈ 25 recent draws from that distribution. Picking the max of 25 draws from
> an sd-0.002 distribution buys about **+0.004 of pure selection bias** — which is the entire
> distance from 0.935 to 0.939.

**This is the real finding: the 0.936→0.938→0.939 ladder is best explained as max-selection over
noise, not as three improvements.**

---

## 6. Why local CV cannot catch this — leakage and validation defects

Local CV is not merely uninformative here; it is **documented as anti-predictive**, and it is
**leaked**. Four separate problems:

1. **Ranking inversion (measured).** `LEARNINGS.md`, "CRITICAL 2026-07-20": on the identical
   comparison, local said `ilp_only 0.9083 > full 0.8877` (Δ −0.021) while LB said
   `ilp_only 0.877 < full 0.909` (Δ +0.032). *Same comparison, opposite sign, comparable
   magnitude.* Confirmed again 2026-08-05 ("the ablation ladder INVERTED").
2. **The obvious confounder was checked and eliminated.** The node-count penalty hypothesis was
   tested (2026-08-06) with the true adjusted metric: the multiplier moves the ladder by ≤0.004
   against a ~0.03 discrepancy and does not flip the ordering. The inversion is real.
3. **Root cause: sparse, biased labels.** 50–1,183 annotated edges against 25k–70k cells per movie
   (<2% coverage); edges touching no annotated node are ignored entirely. The labelled subset
   behaves like an easy sample where raw ILP is already correct, so post-processing that earns its
   value in dense unlabelled regions is *penalized* locally.
4. **Checkpoint leakage (hard evidence).** `references/validation_split_manifest.json`:
   ```
   status: "CHECKPOINT_EXPOSED_DIAGNOSTIC_ONLY"
   checkpoint_exposure.secondary.train_movies: 199
   diagnostic_overlap: [44b6_12dfb391, 44b6_267148e4, 6bba_062c8d37, 6bba_07e24132]  # all four
   checkpoint_exposure.primary: "UNKNOWN"
   checkpoint_exposure.deepcenter: "UNKNOWN"
   final_holdout: []
   ```
   **All four validation movies are in the secondary checkpoint's training list.** Primary and
   DeepCenter exposure is unaudited. `LEARNINGS.md` adds that the checkpoint's own *test* list
   overlaps its *train* list by 40 movies — *"a filename or column called 'test' does not establish
   independence."*

**Consequence:** the standard defence against LB overfitting ("submit on CV, not LB") is currently
**unavailable**. There is no trustworthy internal signal, which is precisely the condition under
which a 25-arm LB sweep converts noise into apparent progress. This is the highest-priority defect
in the setup, above any modeling idea.

---

## 7. Recommendations before the 2026-09-29 deadline

**Do now**

1. **Stop scalar sweeps.** Threshold, gap, divergence, symmetry, retention and fusion-weight
   sweeps have produced 25 arms with a total spread smaller than 2σ. Additional arms buy selection
   bias, not score. (`TASKS.md` already says *"Pause further threshold sweeps"* — enforce it.)
2. **Adopt a decision rule with a real threshold.** Treat **Δ < 0.004 as no evidence** unless a
   mechanism explains it *and* the output diff is large enough to plausibly move scored edges.
   Cross-check with the diff: a change touching <50 rows on one movie cannot honestly claim +0.001.
   By this rule: `0.930 → 0.938` (division geometry) is **real**; `0.936 → 0.938 → 0.939` is **not**.
3. **Build the unexposed holdout.** This is the one high-value engineering task left. Audit the
   primary and DeepCenter checkpoint training manifests, then carve complete movies/embryos
   excluded from *all three*, and score with the pinned official scorer
   (`075fc5f5a52d11077f9dc2b074644618f26939e2`). Until `final_holdout` is non-empty, every promotion
   is an LB guess. Retraining a fold-specific model may be required — worth it.
4. **Until then, gate on scored-error deltas, not aggregate score.** The harness reports per-movie
   edge TP/FP/FN and there are only ~167 known errors. Require a candidate to *reduce FP+FN on
   `6bba_05db0fb1`* before spending a slot. This sidesteps the inversion (which affects ranking of
   aggregate scores) and is the repo's own recommendation.

**Final-submission selection (two slots)**

5. **Do not pick both finals by public LB rank.** Choose:
   - **Slot 1 — mechanism:** the edge-feature TTA reproduction (56075335) *if it scores*. It
     changes the learned edge representation (averaging augmented intermediate U-Net features)
     rather than a scalar, so it has a real reason to transfer. Feature-level TTA is a variance-
     reduction mechanism — the most defensible thing in the candidate set.
   - **Slot 2 — robustness:** the `.80` division-geometry incumbent 56010101 (0.938), *not* the
     0.939 image-`.08` variant. The 0.001 that separates them is 5 edge rows; the `.80` config is
     the centre of a bracket rather than a max-picked spike, and centres of brackets transfer
     better than peaks.
   - Explicitly **do not** select `image .08` + `divergence 5.0` + `symmetry .45` stacks: each
     component is individually within noise, and stacking noise-selected knobs is the classic
     private-LB collapse.
6. **Prefer averaging to selecting, where averaging is available.** Classic seed ensembling is
   ruled out on this task (Exp135 = 0.908 vs 0.910; Exp129 fine-tune = 0.900; Exp133 unusable), so
   the *available* variance-reduction is at the **augmentation/feature level** — exactly what the
   edge-feature TTA candidate does. That is the right form of "ensemble instead of select" here.
7. **Do not chase 0.950.** The gap from 0.939 to 0.950 is ~5× the noise band and ~14× the size of
   the steps currently being produced. It will not be closed by another knob. The only remaining
   levers with headroom, per this repo's own measurements, are association/linking quality in
   dense frames (detection `node_recall` is already 0.998–1.000, so **all** remaining edge loss is
   linking loss) and division candidate identity.

**On the forum comment**

8. The commenter's *mechanism* is wrong for these entries and worth correcting factually: no seeds
   are being swept, and on this task seed diversity is measurably *negative*. Their *concern* is
   right: with four test movies and <2% edge annotation, the 0.93–0.95 band is compressed to within
   a few multiples of its own sampling noise, and a post-rescore reshuffle inside that band should
   surprise nobody. If replying publicly, it would be accurate — and more useful than a rebuttal —
   to publish the sensitivity derivation (1–2 mis-links ≈ 0.001) that makes this quantitative.

---

## 8. Caveats on this analysis

- **No private-LB data exists yet.** Every `privateScore` in the ledger is empty. The claim
  "these gains are noise" is a claim about *evidential support*, not a prediction that the private
  score will fall.
- **The noise-floor estimate is indirect.** With deterministic scoring and no repeated submissions
  of identical outputs across time, sd is estimated from within-bracket dispersion of *nearby but
  distinct* configs. That conflates true (small) config effects with sampling noise, so **≈0.002
  is an upper bound on sd** — but since the improvements being chased (0.001–0.002) are smaller
  still, the conclusion is unchanged under any tightening.
- **Not every tie is noise.** The 13-tie block at 0.913 has a *known mechanical* cause (edits
  landing on unscored edges), which is a different failure from statistical noise, though it has
  the same practical implication: the axis was uninformative.
- One genuine improvement is credited above and should not be discounted along with the rest:
  the `9/14/4.5` division-geometry adoption, +0.008 at fixed fusion weight.
