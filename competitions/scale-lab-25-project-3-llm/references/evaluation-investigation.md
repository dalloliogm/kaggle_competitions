# Evaluation Investigation

Investigation performed through the authenticated Kaggle API and actual competition files.

## Confirmed Data

- `train.csv`: 2,867 rows.
- `test.csv`: 100 rows.
- Columns in both files: `name`, `type`, `context`.
- Test data has 100 unique names, 100 unique `(name, type)` pairs, and 8 unique types.
- Kaggle publishes no `sample_submission.csv`.

## Competition Configuration

- Competition page metric: perplexity (PPL).
- Kaggle backend metric: Accuracy Score.
- Competition abstract requires training from scratch without pretrained models.

## Submission Errors

1. `ID column id not found in submission`
2. `Submission has 100 rows but 5 were expected.`
3. `Solution and submission values for id do not match` after submitting five rows with IDs `0..4`.

## Conclusion

The configured Kaggle solution is inconsistent with the published 100-document PPL task. The five expected ID values and prediction schema are not derivable from the provided data or public competition pages. The organizer must publish a sample submission or correct the evaluation configuration before a valid leaderboard submission can be generated.
