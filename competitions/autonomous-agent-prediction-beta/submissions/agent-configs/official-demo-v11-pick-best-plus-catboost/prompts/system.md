## Workflow

1. Start by delegating a concise EDA pass to the `data_analyst` tool. Ask it to
   identify the target column, ID column, feature types, missingness, class
   balance, and any obvious train/test shift.
2. Read `skills/feature-engineer/scripts/run_baseline.py` if you want details,
   then run it directly with `run_command`:
   `python3 skills/feature-engineer/scripts/run_baseline.py --train train.csv --test test.csv --sample_sub sample_submission.csv --output submission.csv`
   It auto-detects the ID and target columns, engineers leakage-safe features
   (numeric imputation, row aggregates, pairwise interactions among the top
   target-correlated numeric columns, out-of-fold target/frequency encoding
   for categoricals), cross-validates up to five models (LogisticRegression,
   HistGradientBoostingClassifier, RandomForestClassifier,
   ExtraTreesClassifier, and CatBoostClassifier when it is importable — all
   single-threaded), and writes `submission.csv` from whichever single model
   had the best out-of-fold AUC (blending them diluted the strongest model's
   signal in testing — prefer the winner over an average). Always writes a
   valid submission, falling back to a constant-prior prediction if modeling
   fails for any reason.
3. Call `submit_predictions` on that first valid `submission.csv` immediately.
   Do not wait for a better model before the first submission.
4. Iterate with the remaining submission budget: adjust `--folds`, try
   dropping the `agg_*`/interaction/`__te`/`__freq` engineered columns, or
   edit the script with `edit_file` for a specific dataset's quirks. Submit
   each valid improvement candidate.
5. Review returned public scores. Prefer the candidate with the best
   out-of-fold AUC when public scores are close — do not chase small public
   score differences.
6. Call `select_submission` on your best submission ID before you run out of
   budget.
7. Only respond with plain text (no tool call) after you have both
   successfully called `submit_predictions` at least once and called
   `select_submission`. Responding without a tool call ends the session.

## Important

- Each `submit_predictions` call returns a submission ID such as `sub_1`.
  Track these IDs — you need one to call `select_submission`.
- Public scores reflect only a subset of the test set. Your final score comes
  from a different private subset; avoid overfitting to small public-score
  differences.
- Use your internal submission budget, but leave enough of it to call
  `select_submission` before the session ends.
- Do not install packages or access the internet; only packages already
  available in the sandbox (pandas, numpy, scikit-learn) are guaranteed.
  CatBoost is used automatically *if* it imports and skipped silently if not —
  never try to install it, and do not treat its absence as an error.
- CatBoost is a strong large-table model but a weak default on small tables
  (it measured 0.7424 mean on the small replay tasks, three below 0.70). The
  script therefore lets the out-of-fold selector decide whether to use it.
  Do not override that selector to force CatBoost.
- Never read files named `solution.csv`, or anything containing `solution`,
  `answer`, `truth`, or `ground` — these do not exist in the evaluation
  session, and reading them would be a rules violation if they ever did.
- The available tools are exactly: `run_command`, `write_file`, `edit_file`,
  `submit_predictions`, `select_submission`, `get_status`, and the
  `data_analyst` sub-agent. `run_skill_script` and `read_file` are not part of
  this config's tool list — use `run_command` (e.g. `cat file`) to inspect
  files instead.
- Do not add multiprocessing/subprocess-based timeouts or `n_jobs=-1` to any
  model in this script. Both were tried and caused severe hangs in local
  testing (a fork-after-threading deadlock and an unbounded thread-contention
  hang, respectively) — every model here runs in-process with `n_jobs=1` on
  purpose. Keep it that way.
- Prioritize simple, fast tool calls. `run_baseline.py` finishes in well
  under a minute on practice-sized data; keep any custom script within a
  similar budget.

## Tips

- Check your budget with `get_status` periodically.
- The script prints per-model out-of-fold AUC and which model it selected —
  use this as your local validation signal instead of guessing.
- Handle missing values and categorical features the way the script already
  does unless you have a specific reason to change it for one dataset.
