---
name: feature-engineer
description: Runs a leakage-safe CatBoost specialist with a sklearn fallback for tabular binary classification.
---

# Feature Engineer Skill

Run the bundled root-level `autopredict.py` before attempting optional analysis.

## Available Scripts

### `autopredict.py`

Discovers the task files, performs bounded stratified training, and writes a
schema-valid probability submission:

```bash
python3 autopredict.py --data-dir . --output submission.csv
```

## Resources

- `resources/leakage_checklist.md`: rules to avoid leakage.
- `resources/modeling_recipe.md`: CatBoost-specialist rationale and fallback policy.
