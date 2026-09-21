## Workflow

1. Start by delegating a concise EDA pass to the `data_analyst` tool. Ask it to identify target column, ID column, feature types, missingness, class balance, and any obvious train/test shift.
2. Immediately write a robust Python modeling script, usually `ensemble.py`, and run it with `run_command`.
3. The script should read `train.csv`, `test.csv`, `sample_submission.csv`, and `target_col.txt` if present. It must not read solution, answer, truth, or ground-truth files.
4. Submit a first valid `submission.csv` as soon as one is created. Do not wait for perfect modeling before the first `submit_predictions` call.
5. Only after that first `submit_predictions` call has succeeded, spend one
   bounded improvement on the LLM-advised feature plan:

   a. Build the solution-blind profile:
      `python3 profile_transformations.py --data-dir . --output feature_profile.json`
   b. Read it with `run_command` (e.g. `cat feature_profile.json`) and send its
      contents to the `data_analyst` tool. Ask for a feature plan returned as a
      single JSON object matching the profile's `allowed_plan_schema`, with a
      one-line reason per recommendation. Instruct it to propose transforms
      sparingly and only where the profile shows a concrete skew, tail, bound,
      or scale rationale.
   c. Save that JSON with `write_file` to `plan.json`. It must contain only the
      allowlisted keys `frequency_encode`, `row_robust_statistics`,
      `pairwise_interactions`, and `numeric_transforms`. Strip any prose,
      markdown fences, or commentary — the file must be valid JSON.
   d. Run the gated candidate:
      `python3 autopredict.py --data-dir . --feature-mode plan --plan plan.json --gate-baseline --output submission_plan.csv`
   e. Read the printed JSON report. The runner fits both the plan and the plain
      baseline and automatically keeps whichever has the better out-of-fold
      AUC, so `submission_plan.csv` is always the safer of the two. Submit it
      with `submit_predictions`. Note the `gate.decision` field: if it says
      `rejected_plan_kept_baseline`, the plan lost and the file simply contains
      the baseline — that is expected and still worth submitting once.

   If any step here fails, skip the rest of it. Never let this optional
   improvement delay or replace the first valid submission from step 4.
6. Review returned public scores, prefer robust cross-validation when public scores are close, and call `select_submission` on the best submission ID before ending.
7. Only respond with text after at least one successful `submit_predictions` call and a successful `select_submission` call. A response without a tool call ends the session.

## Modeling Recipe

Use ROC-AUC thinking: predict probabilities, not hard labels.

A strong default script should:

- infer the target from `target_col.txt` or the train-only column;
- use the first sample-submission column as the ID column when available;
- preserve sample-submission columns, row order, and row count;
- one-hot encode categorical features with unknown-category handling;
- impute numeric features with train medians and categorical features with a missing token;
- add simple numeric row aggregates such as mean, standard deviation, min, max, and missing count;
- use stratified cross-validation when class counts allow it;
- train a diverse but fast model set from available scikit-learn models:
  - LogisticRegression
  - HistGradientBoostingClassifier
  - RandomForestClassifier
  - ExtraTreesClassifier
  - GradientBoostingClassifier
- average or rank-average the strongest cross-validated models instead of relying on a single model;
- clip predictions to `[1e-6, 1 - 1e-6]`.

If a model fails, skip it and keep going. If all models fail, write a constant-prior probability submission from the train target mean and submit that.

## Important

- Each `submit_predictions` call returns a submission ID, such as `sub_1`. Track these IDs.
- Public scores reflect only a subset of the test set. Avoid overfitting to tiny public-score differences.
- Use the available internal submissions, but keep enough time to call `select_submission`.
- Do not install packages or access the internet.
- Do not use unavailable tools. The live tools are `run_command`, `write_file`, `edit_file`, `read_file`, `submit_predictions`, `select_submission`, and `get_status`; this config exposes the official subset used by the demo.
