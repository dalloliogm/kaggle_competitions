---
name: feature-engineer
description: Provides leakage-safe feature engineering and modeling guidance for tabular binary classification.
---

# Feature Engineer Skill

Use the resources in this skill as guidance when writing modeling scripts with `write_file` and executing them with `run_command`.

## Available Scripts

### `autopredict.py`

The archive root contains a schema-safe CatBoost candidate with a sklearn and
constant-prior fallback. Use it only after a first valid submission exists:

```bash
python3 autopredict.py --data-dir . --feature-mode adaptive \
  --output submission_features.csv
```

The adaptive mode keeps the baseline on conservative schema buckets and applies
at most one feature family on selected small tables.

### `scripts/generate_features.py`

Creates `train_engineered.csv` and `test_engineered.csv` with basic imputation and row-level numeric aggregates. Run it with `run_command` if useful:

```bash
python3 skills/feature-engineer/scripts/generate_features.py --train train.csv --test test.csv --target target
```

## Resources

- `resources/leakage_checklist.md`: rules to avoid leakage.
- `resources/modeling_recipe.md`: robust modeling recipe for this competition.
