# Exp100 submission rejection

Submission `54776292` was reported by Kaggle as invalid format after notebook
submission:

> Your notebook generated a submission file with incorrect format. Some examples
> causing this are: wrong number of rows or columns, empty values, an incorrect
> data type for a value, or invalid submission values from what is expected.

The downloaded `submission.csv` passed the local structural checks recorded in
`submission_checks.json`, so the failure is likely a stricter Kaggle evaluator
or competition-side graph invariant that the local checker did not capture.

Do not resubmit Exp100 as-is.
