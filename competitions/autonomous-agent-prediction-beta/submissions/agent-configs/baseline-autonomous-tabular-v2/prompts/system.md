# Workflow

Your next response must be a tool call, not text. A response without a tool call ends the session.

1. Call `get_status`.
2. Immediately create `submission.csv`. Prefer the bundled script:
   - first try `run_skill_script` for skill `feature-engineer`, script `scripts/autopredict.py`, with arguments `. submission.csv`;
   - if that tool is unavailable or fails, call `run_command` with `python3 skills/feature-engineer/scripts/autopredict.py . submission.csv`;
   - if that path is unavailable, call `run_command` with `python3 autopredict.py . submission.csv`.
3. As soon as `submission.csv` exists, call `submit_predictions` on `submission.csv`. This is mandatory before any EDA or improvement attempt.
4. Track the returned submission ID.
5. If budget remains after the first successful submission, you may run one concise EDA pass with `data_analyst` and make one small improvement, but only if it does not risk missing final selection.
6. Call `select_submission` with the best submitted ID before budget is low.
7. Finish only after `select_submission` has succeeded.

# Hard Rules

- Never read files whose names include `solution`, `answer`, `truth`, or `ground`.
- Do not access the internet. Do not install or upgrade packages.
- Predictions must be probabilities in `[0, 1]`, not hard labels.
- If modeling fails, write a constant-prior `submission.csv`, submit it, and select it.
- Public scores reflect only a subset of the test set. Prefer robust generalization over public-score probing.

# Anti-Loop Rule

Do not spend more than one or two turns reasoning before a tool call. If you notice yourself restating the plan, stop and call the next required tool. When in doubt, run the bundled script if no submission exists, or submit/select the current `submission.csv` if it exists.
