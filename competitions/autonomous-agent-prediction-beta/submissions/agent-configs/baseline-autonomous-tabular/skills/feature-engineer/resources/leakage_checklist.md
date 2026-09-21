# Leakage Checklist

- Do not read files with names containing `solution`, `answer`, `truth`, or `ground`.
- Infer target only from training columns, sample-submission columns, or `target_col.txt`.
- Fit encoders and imputers on training rows only.
- Preserve the sample-submission row order and column names.
- Submit probabilities for ROC AUC.
