## Required Workflow

1. Your first action must be a `run_command` call:
   `python3 autopredict.py --data-dir . --feature-mode none --output submission.csv`
2. When the command succeeds, immediately call `submit_predictions` with
   `submission.csv`.
3. Track the returned submission ID and immediately call `select_submission`
   with it. A valid selected baseline is mandatory before analysis.
4. Call `get_status`. If fewer than 8 minutes remain, stop.
5. Call `data_analyst` once with this request:
   `Run python3 profile_transformations.py --data-dir . --output feature_profile.json.
   Inspect that profile and write transform_plan.json using only its allowed
   plan schema. Transform predictors only; never transform the binary target.`
6. If `transform_plan.json` exists, inspect it with:
   `cat transform_plan.json`
   Treat it as advice only. Then run the replay-tested, schema-gated candidate:
   `python3 autopredict.py --data-dir . --feature-mode adaptive --output submission_features.csv`
   Do not use `plan`, `numeric`, or `auto` mode in the live run.
7. Read the command's final JSON line. Submit `submission_features.csv` only
   when `feature_metadata.engineered_features` is non-empty. If the schema gate
   kept the baseline, do not submit an identical second file.
8. Use the returned public scores to call `select_submission` with the best one
   or two distinct successful IDs. Never invent an ID or run a third modeling
   candidate.

## Candidate Identity

This is a feature-engineered CatBoost branch. The bundled scripts:

- discovers train, test, sample-submission, and optional target metadata;
- excludes solution, answer, truth, and ground-truth paths;
- preserves the sample-submission schema and row order;
- use native CatBoost categorical handling and stratified folds;
- apply exactly one guarded family on selected small schemas: categorical
  frequency features, robust row statistics, or unsupervised pair interactions;
- ask the LLM analyst for a declarative transformation audit, but do not execute
  its plan as code or let it override the replay-tested schema gate;
- falls back to sklearn histogram gradient boosting if CatBoost is unavailable;
- falls back again to constant-prior probabilities if modeling fails.

Do not rewrite the bundled pipeline. Do not install packages or access the
internet.

## Important

- Each `submit_predictions` call returns a submission ID, such as `sub_1`. Track these IDs.
- Public scores reflect only a subset of the test set. Avoid overfitting to tiny public-score differences.
- The first valid selected submission is mandatory; the LLM-guided feature
  candidate is optional and secondary.
- A binary classification target is not expected to be normally distributed.
  Distributional transformations apply to predictors only.
- Do not install packages or access the internet.
- Do not use unavailable tools. The live tools are `run_command`, `write_file`, `edit_file`, `read_file`, `submit_predictions`, `select_submission`, and `get_status`; this config exposes the official subset used by the demo.
