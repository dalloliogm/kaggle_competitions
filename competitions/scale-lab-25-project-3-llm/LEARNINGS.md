# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Authenticated Kaggle download confirms 2,867 train documents and 100 test documents.
- Both files contain `name`, `type`, and `context`; test rows are 100 unique documents, not five candidate groups.
- Fetched file listing shows `train.csv` and `test.csv`; no sample submission was listed.
- The task text says the training data is a Lu Xun corpus.

## Target And Metric

- Metric is perplexity (PPL), computed on the test set.

## Validation

- Initial notebook uses a chronological token split from the encoded training corpus and reports validation negative log-likelihood and PPL.

## Leakage And Rules

- Tokenizer must be character-level and built from the training text's unique characters and punctuation.
- Model must be a Transformer with <=6 layers, hidden dimension <=512, <=8 attention heads, <=50M parameters, and <=8k vocabulary.
- The authenticated competition abstract says to train from scratch and not rely on pretrained models.

## Features

- TBD

## Models

- TBD

## Ensembling And Submission Behavior

- Kaggle checker expects 5 rows and an `id` column, although the published test set has 100 documents.
- IDs `0..4` were rejected because they do not match the hidden solution IDs.
- Kaggle backend metadata reports Accuracy Score while the competition page says PPL.
- Do not infer five groups from `name` or `type`: test has 100 unique names, 100 unique `(name, type)` pairs, and 8 types.
- Until the organizer publishes a sample submission or fixes evaluation, save test PPL diagnostics but do not fabricate `submission.csv`.

## Leaderboard Notes

- Submission errors observed:
  - Missing `id` column.
  - 100 rows submitted but 5 expected.
  - Five rows with IDs `0..4`, but solution and submission ID values did not match.
