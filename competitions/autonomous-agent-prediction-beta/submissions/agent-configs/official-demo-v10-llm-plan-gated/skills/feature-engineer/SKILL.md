---
name: feature-engineer
description: Provides leakage-safe feature engineering and modeling guidance for tabular binary classification.
---

# Feature Engineer Skill

Use the resources in this skill as guidance when writing modeling scripts with `write_file` and executing them with `run_command`.

## Available Scripts

### `autopredict.py`

The archive root contains a schema-safe CatBoost candidate with a sklearn and
constant-prior fallback. Use it only after a first valid submission exists.

Preferred mode — run the LLM-advised feature plan behind an out-of-fold gate:

```bash
python3 autopredict.py --data-dir . --feature-mode plan --plan plan.json \
  --gate-baseline --output submission_plan.csv
```

With `--gate-baseline` the runner fits **both** the plan's feature set and the
plain baseline, then keeps the plan's predictions only when its out-of-fold AUC
beats the baseline by at least `--gate-margin` (default `0.002`). Differences
smaller than that measured as noise in replay testing, so the margin exists to
stop a coin-flip fluctuation from shipping extra features. The printed JSON
report includes a `gate` object with the decision and both AUCs.

A plan is read through a strict allowlist: only the keys `frequency_encode`,
`row_robust_statistics`, `pairwise_interactions`, and `numeric_transforms` are
honored, `numeric_transforms` entries must name a real numeric column, and each
operation must be one of `signed_log1p`, `log1p_nonnegative`, `quantile_rank`,
or `logit_unit_interval`. Anything else is ignored, and a structurally invalid
plan falls back to the plain baseline instead of failing the run.

The `adaptive` mode remains available and keeps the baseline on conservative
schema buckets, applying at most one feature family on selected small tables.

### `profile_transformations.py`

Writes a compact, solution-blind JSON profile of the task (row/feature counts,
class balance, per-column kind, missingness, skew, bounds, Spearman correlation
with the target, and candidate transforms) for the `data_analyst` sub-agent to
turn into a plan:

```bash
python3 profile_transformations.py --data-dir . --output feature_profile.json
```

It never reads solution files and never proposes transforming the binary
target.

### `scripts/generate_features.py`

Creates `train_engineered.csv` and `test_engineered.csv` with basic imputation and row-level numeric aggregates. Run it with `run_command` if useful:

```bash
python3 skills/feature-engineer/scripts/generate_features.py --train train.csv --test test.csv --target target
```

## Resources

- `resources/leakage_checklist.md`: rules to avoid leakage.
- `resources/modeling_recipe.md`: robust modeling recipe for this competition.
