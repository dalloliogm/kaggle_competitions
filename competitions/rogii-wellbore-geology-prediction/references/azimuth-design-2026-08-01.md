# Azimuth-aware GS1.30 experiment design (2026-08-01)

## Decision

The smallest clean first experiment is **one globally trained learned-trajectory model with explicit well-direction features**, leaving the GS1.30 particle filters, SP45 anchor, 60/40 SP45/learned blend, visible-prefix calibration, contact guard, and 0.00425 model-package correction unchanged.

Do **not** reverse well rows or gamma-ray sequences. Do **not** hard-route the existing pretrained model by azimuth. Do **not** begin with two separate NW/SE model stacks.

Why:

- The community suggestion in discussion 726465 is specifically that NW- and SE-drilled wells form opposite directions, and recommends either separate models or explicitly telling one model the direction. The forum statement is useful motivation, but it is a community claim rather than competition documentation, so it needs paired validation.
- The clean notebook already gives the boosters local direction derivatives (`dxdmd`, `dydmd`) and displacements (`dx`, `dy`), but it does not provide one stable, well-level direction label. Adding that label is the minimum intervention matching the claim.
- The active clean run loads `/kaggle/input/.../rogii-claude-models-pub/features.json` and pretrained `lgb*.pkl` models. Merely adding columns to `test_df` has **no effect** unless compatible models are retrained. Any real experiment therefore requires a new learned-model artifact.
- Reversing sequences is structurally wrong for this pipeline: the known TVT prefix is at the heel and the missing suffix starts at the prediction boundary. Reversal moves that boundary to the other end and invalidates lag/lead, PF initialization, warm-up, and last-known features.
- Two experts double the fit count and create small-group/fold failure modes. A tree ensemble can branch on an explicit binary direction feature, so separate experts should be a second experiment only if the conditioned global model shows a strong direction interaction but underfits it.

## What remains unchanged

Use `notebooks/rogii-frontier-lab-clean.ipynb` as the base, with:

- `SUBMISSION_PROFILE = 'vp_balanced_modelpkg_005'`;
- GS1.30 only in `lik_pf` (`gs * 1.3`);
- all PF and beam inputs in original MD order;
- the current `make_prediction` recipe;
- the final `SP45_BLEND_WEIGHT = 0.60` (therefore learned trajectory weight 0.40);
- visible-prefix candidate selection and its existing cut fractions;
- the guarded overlap layer and model-package correction as currently configured;
- all random seeds held exactly equal between control and azimuth candidates.

This isolates the question: does an explicit drilling direction improve the learned trajectory component enough to survive the existing downstream gates?

## Robust direction definition

Derive azimuth only from `X`, `Y`, and `MD`, all of which are available for the full horizontal trajectory at inference. Do not use `TVT`, formation targets, well IDs, or test labels.

### Per-well vector

1. Sort finite `X`, `Y`, `MD` rows by MD.
2. Let `k = max(10, ceil(0.05 * n_rows))`, capped so the first and last windows do not overlap.
3. Compute robust endpoints as the median `(X,Y)` of the first `k` and last `k` rows.
4. Set `v = end_xy - start_xy`, `length = ||v||`, and `u = v / length`.

Median endpoint windows are preferable to literal first/last rows because they tolerate survey noise and terminal doglegs.

### Dataset axis and binary group

Fit one unsigned dominant horizontal axis on **training wells only**:

```python
M = sum(np.outer(u_w, u_w) for u_w in valid_train_unit_vectors)
axis = eigenvector_of_largest_eigenvalue(M)
if axis[0] < 0 or (abs(axis[0]) < 1e-8 and axis[1] > 0):
    axis = -axis
```

The deterministic sign convention points the axis broadly east/southeast when the field is NW-SE. For each well:

```python
projection = float(np.dot(u, axis))
dir_sign = 1.0 if projection >= 0 else -1.0
dir_conf = abs(projection)
az_cos, az_sin = float(u[0]), float(u[1])
```

Use an ambiguous/fallback group (`dir_sign = 0`) if:

- fewer than 20 finite survey rows exist;
- horizontal displacement is less than 250 ft; or
- `dir_conf < 0.50` (trajectory more cross-axis than along-axis).

The 250-ft and 0.50 thresholds are initial safety values, not tuned constants. Record their coverage before training. If more than 5% of train wells are ambiguous, inspect the distribution rather than tuning thresholds against leaderboard outcomes.

## Features to add

Add only four well-constant columns to every evaluation row produced by `build_well`:

```python
"az_dir": sc(dir_sign),       # -1 NW-like, +1 SE-like, 0 ambiguous
"az_conf": sc(dir_conf),
"az_cos": sc(az_cos),
"az_sin": sc(az_sin),
```

Do not add direction-times-GR, reverse-index, or many angle-bin interactions in v1. LightGBM/CatBoost can learn interactions with the explicit columns. Existing row-level `dx`, `dy`, `dxdmd`, and `dydmd` remain untouched.

If feature importance later shows the four features are ignored but subgroup residuals differ, the next escalation is two experts. It is not part of the first submission candidate.

## Exact notebook hooks

The current clean notebook cells are described by their functions rather than fixed cell numbers, so this remains valid if cells are inserted.

### 1. Configuration cell

Near `LEARNED_MODEL_ROOTS`, add:

```python
RUN_AZIMUTH_CONDITIONING = True
AZIMUTH_MIN_DISPLACEMENT = 250.0
AZIMUTH_MIN_CONFIDENCE = 0.50
AZIMUTH_FEATURES = ("az_dir", "az_conf", "az_cos", "az_sin")
AZIMUTH_MODEL_ROOTS = (
    "/kaggle/input/datasets/<owner>/rogii-gs130-azimuth-models-v1",
    "/kaggle/input/rogii-gs130-azimuth-models-v1",
)
```

Put the azimuth artifact roots ahead of the existing generic learned-model roots only when the flag is true.

### 2. Feature-engineering cell (`build_well` / `init_imputers`)

Add:

- `_trajectory_unit_vector(hw)` implementing the robust endpoint calculation;
- `_fit_azimuth_axis(train_wids, data_dir)` using train horizontal files only;
- `_azimuth_features(hw, axis)` returning the four values and an audit status;
- a read-only global `_AZ_AXIS`, initialized in `init_imputers(train_wids)` before parallel feature building.

In `build_well`, call `_azimuth_features(hw, _AZ_AXIS)` once and add the four `sc(...)` columns to `feats`. The axis and feature calculation must be deterministic and thread-safe.

### 3. Training artifact builder

Do not compare the new runtime-trained candidate with the old external pretrained inference as if that isolated azimuth. Build two artifacts from the same feature rows, fold assignments, model configurations, and seeds:

- `control`: exclude `AZIMUTH_FEATURES`;
- `conditioned`: include `AZIMUTH_FEATURES`.

Use the existing `GroupKFold(n_splits=5)` by whole well. Save:

- `features.json`;
- the fold models required by the existing inference loader;
- `azimuth_manifest.json` with axis, thresholds, train-well group counts, code version, feature list, and OOF metrics;
- paired row-level OOF predictions for the validation report.

Because the production `main()` currently averages every `lgb*.pkl`, keep the artifact naming and ensemble semantics compatible. If CatBoost is used during validation but is not packaged by the existing inference loader, either package an inference path for it explicitly or exclude it from **both** paired control and conditioned comparisons. Do not validate a five-model stack and deploy a different three-model stack.

### 4. Inference loader (`_find_models` / `main`)

An azimuth run is active only if the selected artifact has:

- `features.json` containing all four `AZIMUTH_FEATURES`;
- `azimuth_manifest.json` with a finite two-element axis;
- at least one expected model file.

Load the axis from the manifest **before** building test features. The current `main()` builds test features before `_find_models()`, so reorder the start of `main()` to resolve/validate the model artifact and initialize `_AZ_AXIS` first.

If the azimuth artifact is absent or incompatible:

1. print a prominent `AZIMUTH FALLBACK` message;
2. load the original clean learned artifact;
3. continue to a valid clean GS1.30 submission;
4. write `azimuth_runtime_audit.json` with `active: false` and the reason.

Do not throw during grading solely because the optional artifact is unavailable. Conversely, do not spend a submission slot unless the interactive kernel audit says `active: true`.

### 5. Downstream blend

No code change is needed in `make_prediction` or the SP45 blend. The direction-conditioned learned trajectory flows through:

1. learned-model delta;
2. `make_prediction` (60% learned-model sub1, 40% lik-PF inside that branch);
3. `learned_trajectory_submission.csv`;
4. final 60% SP45 / 40% learned blend;
5. visible-prefix and model-package layers.

This attenuation is intentional. A learned-only effect reaches the pre-calibration final at roughly 0.40 × 0.60 = 0.24 weight, so a modest raw learned improvement may become small. Inspect all intermediate files to confirm it survives.

## Validation gate before any submission

### Primary paired GroupKFold gate

Use the original train `TVT_input` masks, which reproduce the known-prefix/hidden-suffix information pattern. All rows from a well stay in one fold. Compare control and conditioned models with identical fold assignments and random seeds at three levels:

1. learned model delta alone;
2. output of `make_prediction` with the same likelihood-PF arrays;
3. the 60/40 SP45/learned blend, which is the closest locally measurable analogue of the deployed path.

Report pooled row-weighted RMSE (the competition metric), each fold, each direction group, ambiguous wells, and well-bootstrap confidence intervals for the paired RMSE delta.

### Masked-prefix stress gate

For each train well with at least 140 known-prefix rows, create deterministic pseudo-test masks at the existing fractions `(0.50, 0.65, 0.75)`:

- retain `TVT_input` through the selected cutoff;
- set later `TVT_input` rows to NaN;
- retain `TVT` only as evaluation truth, never as a feature;
- recompute every prefix-dependent feature, PF initialization, and direction feature;
- keep all masks from the same well in the same GroupKFold fold.

Score only rows hidden by that pseudo-mask. For tractability, first run the same deterministic, direction-balanced well subset for control and conditioned models. If it passes, run all eligible wells before packaging.

The direction feature may use full `X/Y` in this test because full trajectory coordinates are available at real inference. It may not use held-out TVT.

### Required pass conditions

Package/deploy the conditioned model only if all conditions hold:

- primary pooled RMSE improves by at least **0.05 ft**;
- at least 3 of 5 folds improve;
- neither NW-like nor SE-like pooled RMSE regresses by more than **0.10 ft**;
- the pooled masked-prefix stress result does not regress by more than **0.05 ft**, and at least two of the three cut fractions improve;
- all predictions are finite and every validation row is covered;
- direction groups each contain at least 100 train wells; otherwise keep the single conditioned model but do not attempt split experts;
- the paired improvement is not caused solely by ambiguous wells or one very long well (inspect row-weighted and equal-well summaries).

These thresholds are deliberately stricter than the current ~0.02-ft bronze gap because downstream attenuation and PF randomness can erase a tiny CV effect.

## Kernel/output gate

Before submitting the notebook fork:

- kernel status must be `COMPLETE` within the time limit;
- `azimuth_runtime_audit.json` must report `active: true`, finite axis, expected feature list, and sensible train/test group counts;
- `learned_trajectory_submission.csv` must differ from the clean control on a material number of rows;
- `submission.csv` must still differ after visible-prefix/model-package processing; if it is byte-identical, it is a no-op and must not consume a slot;
- validate exact sample ID order, row count, unique IDs, finite `tvt`, and no extra index column;
- save a per-well comparison report for clean final, direction learned, and direction final predictions.

A reasonable anti-no-op diagnostic is more than 1% of final rows changed by over `1e-6` and final RMSE-distance from clean greater than `0.01 ft`. This is not a quality criterion; it only proves the experiment reached the scored file.

## Failure-safe behavior

- Invalid/short/ambiguous trajectory: set `az_dir=0`, retain angle features if finite, and use the globally trained conditioned model.
- Missing direction artifact or manifest mismatch: fall back to the exact clean learned artifact and emit `active:false`; do not throw.
- Non-finite direction features: replace only those four values with zero and report the well.
- Empty direction group in hidden test: harmless for the single conditioned model.
- Runtime pressure: do not train on the hidden grading run. Train and package the artifact beforehand; hidden execution is inference only.
- Downstream gate collapses the change: mark as no-op and do not submit; do not force-copy the learned file over `submission.csv`, because that would remove the validated SP45/visible-prefix/model-package stack and cease to be an isolated azimuth experiment.

## When to try two separate experts

Only escalate to hard NW/SE experts if the v1 report shows:

- clear opposite residual patterns by `az_dir`;
- the conditioned global model improves both groups but leaves a material group gap;
- each training fold has enough wells in both groups.

Then train global fallback plus two expert stacks. Route confident wells to their expert and use the global model for `az_dir=0`. A soft expert/global blend can use `w = clip((az_conf - 0.50) / 0.25, 0, 1)`. Validate it against the same paired masked-prefix gate. This is a separate experiment, not an automatic extension of v1.

## Bottom line

The clean next build is **direction-conditioned learned models, packaged as a compatible artifact, with all physics/PF/final-selection layers unchanged**. Orientation normalization by row reversal is unsafe, and hard split experts are premature. The candidate earns a submission only after a paired GroupKFold plus masked-prefix pass and proof that the effect survives to final `submission.csv`.
