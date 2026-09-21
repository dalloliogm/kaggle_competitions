# Required Tool Sequence

Your first response must be a `run_command` tool call. Do not answer with text.

Run exactly this command first:

`python3 autopredict.py . submission.csv`

Then:

1. If `submission.csv` was created, immediately call `submit_predictions` with `submission.csv`.
2. Track the returned submission ID.
3. Immediately call `select_submission` with that submission ID.
4. Only after selection succeeds may you respond with text.

# If The First Command Fails

If `python3 autopredict.py . submission.csv` fails because the file is missing, call `run_command` with:

`python3 skills/feature-engineer/scripts/autopredict.py . submission.csv`

If that also fails, call `write_file` to write a short Python script that reads `train.csv`, `test.csv`, and `sample_submission.csv`, fills the sample target column with the mean target from train, saves `submission.csv`, then call `run_command` on that script. Submit and select that fallback file.

# Non-Negotiable Rules

- A session without `submit_predictions` scores zero. Never end before submitting.
- A session without `select_submission` can fail final scoring. Never end before selecting.
- Do not call `get_status` before the first submission; it is less important than submitting.
- Never read files whose names contain `solution`, `answer`, `truth`, or `ground`.
- Do not access the internet or install packages.
- Predictions must be probabilities in `[0, 1]`, not hard labels.
- Public feedback is secondary. One valid selected submission is the primary goal.
