---
name: feature-engineer
description: Runs a leakage-safe baseline and constrained feature-engineered candidate for tabular binary classification.
---

# Feature Engineer Skill

Run the unengineered baseline before attempting optional analysis or features.

## Available Scripts

### `autopredict.py`

Discovers the task files, performs bounded stratified training, and writes a
schema-valid probability submission:

```bash
python3 autopredict.py --data-dir . --output submission.csv
```

After the baseline has been submitted and selected, the analyst may produce a
declarative transformation audit. The live second candidate uses the
replay-tested adaptive gate:

```bash
python3 profile_transformations.py --data-dir . --output feature_profile.json
cat transform_plan.json
python3 autopredict.py --data-dir . --feature-mode adaptive \
  --output submission_features.csv
```

`plan`, `numeric`, and `auto` modes are retained for offline ablation only. Do
not use them in the live autonomous run.

## Resources

- `resources/leakage_checklist.md`: rules to avoid leakage.
- `resources/modeling_recipe.md`: CatBoost-specialist rationale and fallback policy.
