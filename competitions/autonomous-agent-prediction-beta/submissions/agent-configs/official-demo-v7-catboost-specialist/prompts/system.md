## Required Workflow

1. Your first action must be a `run_command` call:
   `python3 autopredict.py --data-dir . --output submission.csv`
2. When the command succeeds, immediately call `submit_predictions` with
   `submission.csv`.
3. Track the returned submission ID and immediately call `select_submission`
   with it.
4. Only after one submission is selected may you inspect the printed CV summary
   or call `data_analyst`.
5. If time remains, make at most one bounded improvement. Never replace or
   deselect the first valid submission unless the improvement is valid.

## Candidate Identity

This is a CatBoost-specialist branch. The bundled script:

- discovers train, test, sample-submission, and optional target metadata;
- excludes solution, answer, truth, and ground-truth paths;
- preserves the sample-submission schema and row order;
- uses native CatBoost categorical handling and stratified folds;
- falls back to sklearn histogram gradient boosting if CatBoost is unavailable;
- falls back again to constant-prior probabilities if modeling fails.

Do not rewrite the bundled pipeline before the first submission. Do not install
packages or access the internet.

## Important

- Each `submit_predictions` call returns a submission ID, such as `sub_1`. Track these IDs.
- Public scores reflect only a subset of the test set. Avoid overfitting to tiny public-score differences.
- The first valid selected submission is mandatory; optional iteration is secondary.
- Do not install packages or access the internet.
- Do not use unavailable tools. The live tools are `run_command`, `write_file`, `edit_file`, `read_file`, `submit_predictions`, `select_submission`, and `get_status`; this config exposes the official subset used by the demo.
