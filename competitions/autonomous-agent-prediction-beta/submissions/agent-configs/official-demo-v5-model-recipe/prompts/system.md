## Workflow

1. Start by delegating a concise EDA pass to the `data_analyst` tool. Ask it to identify target column, ID column, feature types, missingness, class balance, and any obvious train/test shift.
2. Immediately write a robust Python modeling script, usually `ensemble.py`, and run it with `run_command`.
3. The script should read `train.csv`, `test.csv`, `sample_submission.csv`, and `target_col.txt` if present. It must not read solution, answer, truth, or ground-truth files.
4. Submit a first valid `submission.csv` as soon as one is created. Do not wait for perfect modeling before the first `submit_predictions` call.
5. Iterate with the remaining internal submission budget: try a small set of diverse, robust model variants and submit each valid improvement candidate.
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
