---
name: feature-engineer
description: >-
  Provides a schema-agnostic tabular binary-classification baseline script:
  auto-detects ID/target columns, engineers leakage-safe features, blends
  LogisticRegression and HistGradientBoostingClassifier by out-of-fold AUC,
  and always writes a valid submission.
---

# Feature Engineer Skill

Run the bundled script with `run_command` (there is no `run_skill_script`
tool in this evaluation runtime):

```bash
python3 skills/feature-engineer/scripts/run_baseline.py \
  --train train.csv --test test.csv --sample_sub sample_submission.csv \
  --output submission.csv
```

## Available Scripts

### `scripts/run_baseline.py`

- Infers the target column from `target_col.txt` (if present) or the
  train-only column, and the ID column from the first `sample_submission.csv`
  column.
- Imputes numeric columns with train medians and categorical columns with a
  missing token.
- Adds row-wise numeric aggregates (mean, std, min, max, sum).
- Adds out-of-fold target encoding and frequency encoding for categorical
  columns (never uses a row's own target to encode that row).
- Trains a `LogisticRegression` and a `HistGradientBoostingClassifier` with
  stratified cross-validation, blends them weighted by out-of-fold AUC, and
  clips predictions to `[1e-6, 1 - 1e-6]`.
- Falls back to a constant train-target-mean prediction if any step raises,
  so a run always produces a valid `submission.csv`.
- Refuses to open any path containing `solution`, `answer`, `truth`, or
  `ground` in its filename.

Arguments: `--train`, `--test`, `--sample_sub`, `--target_hint`
(`target_col.txt`), `--output`, `--folds` (default 5), `--time_budget`
(seconds, default 240 — skips the gradient-boosting model if the budget is
nearly exhausted after logistic regression).

## Resources

- `resources/leakage_checklist.md`: rules to avoid leakage.
