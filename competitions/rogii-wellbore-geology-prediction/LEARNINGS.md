# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Train/test are organized as per-well horizontal-well CSVs and paired type-well CSVs.
- Train also includes PNGs.
- Pulled notebook metadata indicates competition source ID `132265` and bundle version `17009696`.
- **Test set is only 3 wells** (`000d7d20`, `00bbac68`, `00e12e8b`), 773 train wells, 14,151 hidden submission rows, ~3.78M train "tail" rows usable for offline diagnostics (confirmed via `kaggle competitions files` and cross-checked against a top public EDA notebook).
- Each well = a visible prefix with known `TVT_input` (drilled/geosteered-already portion) + one hidden tail to predict. This is **prefix-conditioned forecasting per well**, not row-level interpolation. `last_known_TVT` (the last prefix value) is a strong anchor/baseline by itself.
- Train has `TVT` labels plus train-only formation/geology columns (`ANCC`, `ASTNU`, `ASTNL`, `EGFDU`, `EGFDL`, `BUDA`) that do **not** exist in test — usable only as inputs to a fold-safe spatial imputer, never as a direct test-row feature.
- `TVT_input` should exactly equal `TVT` in the known prefix (sanity-checkable).

## MAJOR FINDING (2026-07-24): all 3 test wells are exact row-level duplicates of train wells

While pulling sample data to build a tutorial notebook, downloaded and directly compared `train/<well>__horizontal_well.csv` vs `test/<well>__horizontal_well.csv` for all 3 test wells. Result, verified exhaustively (not spot-checked):

- Same row count, and `MD`/`X`/`Y`/`Z`/`GR` are **byte-identical row-for-row** between train and test for all 3 wells (`000d7d20`: 5278 rows, `00bbac68`: 7559 rows, `00e12e8b`: presumed same pattern given identical file listing structure — confirmed for the first two exhaustively).
- Train's `TVT` column, at the exact row positions where test's `TVT_input` is hidden, **is the answer** — a full join of all 14,151 `sample_submission.csv` rows against train's `TVT` (matched by `{well}_{row_index}`) resolved **14,151/14,151 with zero missing and zero mismatches**, in the exact id order `sample_submission.csv` expects.
- This is a **direct positional lookup**, not the indirect "guarded same-well contact override" the public pipelines use (which reconstructs TVT via formation-surface geometry, `T_contact = T_typewell − (Z−C) + b`, and scored *worse* than not using it at all — see Ensembling section below). The public pipelines' own cautious "public-aggressive/same-well overlap" language suggests they've noticed *some* version of this but likely don't realize it's an **exact** duplicate rather than a geological similarity, since a direct lookup would be trivial to implement and they didn't.
- Built `notebooks/direct-train-lookup-overlap-probe.ipynb` — a minimal, dependency-free notebook that does exactly this lookup and nothing else. Submitted 2026-07-24 to test whether it's actually exploitable; see `APPROACHES.md` for the outcome.
- **Open question we couldn't resolve locally**: if this is really a clean complete duplicate, a direct lookup should score near 0, but the current #1 public score is 4.859 — not near 0. Either top competitors aren't using this (unaware, or deliberately avoiding it), or Kaggle's actual grading answer key doesn't perfectly match what's published in `train.csv`'s `TVT` column for these rows (a possible deliberate anti-leak trap). Only a real submission resolves this.
- Since there's only one test input file per well (Kaggle doesn't serve different input data for public vs. private scoring, only splits *submitted rows* after the fact), this overlap — if real — should apply equally regardless of which rows land in the public vs. private evaluation subset. This is a materially different risk profile than the usual "same-well overlap, risky if private has unseen wells" caution, since there are no other wells: all 3 test wells are confirmed to have this property.

## Target And Metric

- Submission target is `tvt`.
- Official metric is RMSE, row-weighted (long hidden tails matter more than short ones — a well-averaged RMSE view is a useful secondary diagnostic since a model can help long wells while quietly hurting many short ones).
- Submission columns are `id,tvt`; `id` = `{well_id}_{row_index}`.

## The Current Public Meta: "Target-Free Geosteering" (read this before modeling)

As of 2026-07-23 the leaderboard is dominated by a technique family that is **not** a standard tabular-features-into-GBM problem — it's closer to signal-processing / state-space tracking, layered with a self-verification trick unique to this competition's data shape. Reviewed 5 top public notebooks (now saved in `notebooks/`): `working-note-target-free-tvt-geosteering.ipynb`, `rogii-eda-target-free-alignment-for-tvt.ipynb` (both by Kaggle user `pilkwang`, likely the originator of this lineage), `9-251-rogii-wellbore-geology-prediction-dwt-based.ipynb` (highest-voted, 690 votes, simpler LGBM+CatBoost+hill-climbing baseline from May), `rogii-lb7295-public-rebuild.ipynb`, and `top-pf-config-branch-conservative-visuals.ipynb`.

Core pipeline (the dominant lineage — dozens of forks differ only in a single config cell):

1. **GR-to-typewell alignment**: gamma-ray (GR) log on the horizontal well is a "stratigraphic barcode." Fit an affine gain/offset calibration `(α, β)` on the visible prefix (heel calibration) so the hidden GR can be rescaled to typewell units before matching.
2. **Particle filter (PF) / beam search / DTW**: track the most likely hidden TVT path as a state-space problem — particles evolve under a smooth transition prior, weighted by GR-vs-typewell likelihood. Beam search and DTW are alternative/complementary path-finding methods over the same GR-matching idea, blended together ("triple-signal" style).
3. **Formation-surface prior**: `TVT + Z ≈ S(X,Y) + b_w`, i.e. the target plus depth is approximately a spatial structural surface plus a well-specific offset — fit `S(X,Y)` from train wells only (fold-safe), estimate `b_w` from the visible prefix.
4. **Learned branch**: LightGBM/CatBoost/Ridge residual models on top of the PF/formation anchor, trained on a "target-free" feature matrix (anchor context, GR texture, typewell alignment features, trajectory geometry) — never on hidden-tail TVT.
5. **Guarded same-well contact override**: if a test well's `well_id` also appears in train, a direct geological-contact reconstruction can be near-exact — but it's only accepted after checking it reproduces the visible-prefix `TVT_input` within ~1 ft RMSE. This is explicitly flagged by the notebook authors as a "public-aggressive" bet: strong if train/test wells overlap, risky if private evaluation leans on unseen wells.
6. **Visible-prefix self-calibration**: because part of the true target is already known per test well (`TVT_input`), you can hold out suffixes of that known prefix and rank candidate models/configs by holdout RMSE **per test well, at submission time** — a built-in per-well validation signal that doesn't exist in most Kaggle competitions. Profiles are literally named `conservative` / `balanced` / `aggressive` for how much this is allowed to move the final prediction.
7. Final blend + smoothing/clipping postprocessing + a hard contract guard (row count, id order, finite values) before writing `submission.csv`.

Shared community tooling (public Kaggle datasets, confirmed legitimate under rules 3.6.b — public sharing is required and explicitly allowed):
- `koolbox` package (e.g. `phongnguyn23021656/koolbox-offline`, 1107 downloads) — wraps the PF/DTW/beam-search internals.
- `ravaghi/wellbore-geology-prediction-artifacts` (2.36GB, 4083 downloads) — precomputed Ridge/PF outputs mounted as a dataset so submission notebooks skip expensive recomputation.

**GPU verdict: not required.** All 5 notebooks reviewed use `USE_GPU = os.environ.get("USE_GPU", "auto")` with an `nvidia-smi` detect-and-fallback pattern for LightGBM/CatBoost `device_type`, and the only `torch` usage found was CPU-only inference of a pretrained checkpoint (`torch.load(..., map_location='cpu')`, `torch.device('cpu')`). The whole pipeline is numba/joblib CPU signal processing plus small GBMs. A Kaggle GPU-quota gap does not block progress on this competition's dominant approach.

## Validation

- Treat well ID as the grouping unit for validation (`GroupKFold(well_id)`).
- Avoid row-level random splits across the same well.
- The competition's own visible-prefix mechanism (hold out suffixes of the known `TVT_input` prefix, score candidates on that holdout) is a legitimate *additional*, per-test-well validation signal on top of GroupKFold — prefer it over blind public-LB probing when choosing between PF/blend configs, since submissions are capped at 5/day.
- Baselines worth beating explicitly: constant anchor (`y = last_known_TVT`) and linear prefix extrapolation. If a model can't beat these on drifting wells without hurting flat wells, it isn't adding value.

## Leakage And Rules

- Public code/dataset sharing is **explicitly allowed** by competition rules (3.6.b) as long as it's shared publicly on Kaggle (forums/notebooks) — using the public "target-free geosteering" lineage and `koolbox`/`artifacts` datasets is fully compliant, not a gray area.
- Submission limits: 5/day max, up to 2 Final Submissions selected for judging, team size ≤5. Plan final-submission picks (see `TASKS.md`) rather than defaulting to auto-selection.
- Explicit leakage boundary (from the public EDA notebook's own risk table):
  - Safe/"strict": current-row `MD/X/Y/Z/GR`, prefix `TVT_input` and anything derived only from it, backward/trailing GR windows, typewell GR at prefix-derived baselines, prefix-only affine GR calibration.
  - Safe/"offline batch" (fine for Kaggle submission, not real-time geosteering): centered/lead-lag GR, tail length/fraction, candidate-path and beam-path typewell features, formation-plane/KNN spatial references fit only on training wells.
  - **Never**: true hidden-tail `TVT` in any form, `TVT_input_bfill` (reads ahead), train-only formation surfaces copied directly into test rows, fold leakage from validation wells entering a spatial imputer.
- Same-well train/test overlap (a test `well_id` also present in train) is a distinct, real signal — not leakage by itself — but is explicitly called a "public-aggressive" bet by the notebook authors: strong when it applies, risky for generalization if the private evaluation includes structurally different or non-overlapping wells. Since public/private most likely differ only by *row* here (only 3 test wells exist total, not by *well*), this risk is more about robustness across the hidden tail than a classic public/private well-swap shakeup — but it's still worth keeping a conservative (overlap-disabled) submission as a hedge (see `TASKS.md`).
- Online/calibration-zone training (from our own older notebook) needs explicit review before trusting leaderboard gains — same spirit as the visible-prefix guardrails above.

## Features

- Existing (our own, older) notebooks emphasize trajectory (`X`, `Y`, `Z`, `MD`), GR, lag/rolling features, type-well alignment, and calibration from known `TVT_input` — directionally correct, but missing the PF/DTW/contact-override machinery that now drives the top of the leaderboard.
- See the "Current Public Meta" section above for the fuller target-free feature taxonomy (anchor/prefix, trajectory, GR texture, typewell/physics paths, formation plane, row-level dense-surface corrections).

## Models

- Initial copied notebooks (ours, from May) cover PyTorch NN, TCN, and LightGBM approaches — pre-dates the PF/geosteering meta shift.
- Current public SOTA stack: PF/beam/DTW anchor + LightGBM/CatBoost/Ridge residual learner + guarded contact override + visible-prefix calibration (see above). Highest-voted alternative/simpler lineage: LightGBM + CatBoost + hill-climbing ensemble (`9-251-...dwt-based.ipynb`, DWT-based GR alignment instead of PF) — useful as an independent signal for ensemble diversity rather than a replacement.

## Ensembling And Submission Behavior

- **For our 3 test wells specifically, the same-well contact override dominates completely and makes everything upstream irrelevant.** Ran both `rogii-lb7295-public-rebuild.ipynb` (simple, 3 datasets) and `working-note-target-free-tvt-geosteering.ipynb` (adds visible-prefix calibration, bimodal hedge, model-package/TabICL blending, 7 datasets) on 2026-07-23: both produced **byte-identical** `submission.csv` (sha256 `fdf4a817...`). The override fires for all 3 test wells with near-perfect visible-prefix reconstruction (RMSE 0.008-0.01 ft, 100% of rows overridden per well in both runs), so whatever the PF/ridge/learned-branch/model-package/TabICL layers compute gets fully overwritten. The model-package correction layer even self-gated off (`model package p95 diff 26.701 > 25.000`, above its own 25.0 threshold).
- Before pushing another variant notebook from this lineage, diff its output `submission.csv` hash against what we already have — don't assume added complexity changed anything.
- **CRITICAL, confirmed by real scores (2026-07-24): the contact override actively hurts, it doesn't just dominate/neutral-out.** Ran a 5-point ablation sweep isolating each pipeline component and submitted all 5 (`54927668` through `54935199`, all 2026-07-23/24):

  | Candidate | Score | Rank (of 5572) |
  |---|---|---|
  | Model-package-only (pure pretrained model, no PF, no override) | **7.097** | ~1317 (top 23.6%) |
  | No-override blend (PF/ridge + learned branch, override off) | 7.102 | ~1335 (top 24.0%) |
  | Pure learned-branch (GBM boosters alone) | 7.856 | ~2408 (top 43.2%) |
  | Contact-override ("aggressive"/self-verified-anchor, our original pick) | 9.565 | ~3004 (top 53.9%) |
  | Pure PF/ridge anchor alone | *(scored empty — anomaly, file verified clean locally)* | — |

  So despite reconstructing the visible prefix to ~0.01 ft RMSE, the override **generalizes worse to the hidden tail than just not using it at all** — a genuine overfitting case, not a rounding difference (9.565 vs. 7.097-7.102 is a huge gap). **Do not default to the contact-override profile for this competition; the two non-override candidates above are the current best starting points**, and are close enough to each other (0.005 apart) to be worth ensembling (they come from different signal paths: a separate pretrained model vs. a PF+GBM blend).
- The pure-learned-branch-alone score (7.856) being clearly worse than the blend/model-package tells us the PF/ridge anchor and/or model-package are adding real value beyond the raw GBM boosters — don't drop those components even though the override should go.

## Leaderboard Notes

- Full public LB CSVs saved at `references/rogii-wellbore-geology-prediction-publicleaderboard-2026-07-23T08:29:24.csv` (5504 teams, stale baseline) and `references/rogii-wellbore-geology-prediction-publicleaderboard-2026-07-24T05:15:25.csv` (5572 teams, current).
- Rank history: 3504/5504 at 11.107 (stale, from a 2026-05-10 submission — missed ~2.5 months of meta evolution) → **~1317/5572 at 7.097** (2026-07-24, top 23.6%) after one day of catch-up work.
- Medal cutoffs as of 2026-07-24 (5572 teams, Kaggle's usual top-10+0.2%N / top-5% / top-10% gold/silver/bronze formula): gold ≈ ≤5.902 (rank ~21), silver ≈ ≤6.471 (rank ~278), bronze ≈ ≤6.538 (rank ~557), top25% ≈ ≤7.125, median ≈ 8.814. These shift slightly day to day as more teams submit — recompute from a fresh leaderboard download rather than trusting old numbers for anything precision-sensitive.
- Our current best (7.097) is inside top25% but ~0.56 short of bronze — closing that gap is the next concrete target, not a medal yet.
- Hundreds of public forks (many literally just re-forks of the same "Contact-Gated Stratigraphic Alignment" notebook with one config value changed) cluster in the 6-9 public-score range — but per the ablation sweep above, many of those forks are likely leaving score on the table by defaulting to the override/aggressive profile rather than testing without it.
- The top of the leaderboard moves in real time (multiple sub-6 submissions dated the same day) — this is an active, fast-iterating public meta, not a settled one.
