---
name: feature-engineer
description: >-
  Provides a schema-agnostic tabular binary-classification baseline script:
  auto-detects ID/target columns, engineers leakage-safe features including
  pairwise interactions, cross-validates up to five in-process single-threaded
  models (including CatBoost when available), and writes a submission from
  whichever had the best out-of-fold AUC.
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
- Adds pairwise products and differences among the top 5 target-correlated
  numeric columns.
- Adds out-of-fold target encoding and frequency encoding for categorical
  columns (never uses a row's own target to encode that row).
- Cross-validates `LogisticRegression`, `HistGradientBoostingClassifier`,
  `RandomForestClassifier`, `ExtraTreesClassifier`, and — when the import
  succeeds — `CatBoostClassifier` (all single-threaded, in-process; no
  multiprocessing/subprocess timeouts, see below), and writes predictions from
  whichever single model had the best out-of-fold AUC.
- CatBoost receives a **different feature view** from the sklearn models: the
  engineered numerics plus the *raw* categorical columns via `cat_features`, so
  it applies its own ordered target statistics. Feeding it the pre-computed
  target/frequency encodings was measured to waste its only real advantage —
  on a high-cardinality categorical task its out-of-fold AUC rose from 0.80087
  (encoded view) to 0.81568 (native view), turning a loss into a win.
- CatBoost must clear a **0.003 out-of-fold margin** over the best sklearn model
  before it is used. On a 900-row task it won out-of-fold by 0.00044 and then
  lost 0.0028 on held-out test — a winner's-curse pick the margin now blocks.
  Measured out-of-fold noise here is ~0.0004; real CatBoost wins are ~0.01.
- CatBoost is a **gated candidate, not a new default.** A standalone CatBoost
  specialist measured 0.7990 mean over the 16 official replay tasks: 0.8247 on
  tasks with at least 2,000 rows, but only 0.7424 on the smaller ones with
  three scores below 0.70. Because the selector adopts it only when it wins
  out-of-fold, the large-table strength is available without the small-table
  risk. It runs with `thread_count=1`, `iterations=400`,
  `allow_writing_files=False`, and only starts if at least 60s of the time
  budget remains (a half-finished CatBoost would score artificially low and be
  wrongly discarded).
  Blending all four by weighted average was tried and consistently diluted
  the strongest model's signal (see `LEARNINGS.md` in the workspace root),
  so this script picks a winner instead of averaging.
- Clips predictions to `[1e-6, 1 - 1e-6]`.
- Falls back to a constant train-target-mean prediction if any step raises,
  so a run always produces a valid `submission.csv`.
- Refuses to open any path containing `solution`, `answer`, `truth`, or
  `ground` in its filename.

**Do not add `n_jobs=-1` or a multiprocessing/subprocess-based timeout to any
model here.** Both were tried during development: `n_jobs=-1` caused a single
`fit()` call to hang for hours in testing (thread contention), and a
fork-based subprocess timeout wrapper meant to fix that hung just as badly
on plain sklearn models with no GBDT libraries involved at all (a
fork-after-threading deadlock). Every model runs in-process, single-threaded,
on purpose.

Arguments: `--train`, `--test`, `--sample_sub`, `--target_hint`
(`target_col.txt`), `--output`, `--folds` (default 5), `--time_budget`
(seconds, default 240 — skips remaining models if the budget is nearly
exhausted).

## Resources

- `resources/leakage_checklist.md`: rules to avoid leakage.
