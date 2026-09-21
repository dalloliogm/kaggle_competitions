# Modeling Recipe

Write a script that creates `submission.csv` quickly, submits it, then iterates.

Recommended defaults:

- Read `target_col.txt` if present.
- Preserve `sample_submission.csv` columns and order.
- Use probabilities for ROC AUC.
- Use train-only preprocessing.
- Try LogisticRegression, HistGradientBoostingClassifier, RandomForestClassifier, ExtraTreesClassifier, and GradientBoostingClassifier.
- Average the top cross-validated model predictions.
- Fall back to the target prior if modeling fails.
- Secure and select the first valid submission before running the optional root
  `autopredict.py --feature-mode adaptive` candidate.
- Do not transform a binary target for normality. Predictor transformations need
  a concrete distributional rationale.
