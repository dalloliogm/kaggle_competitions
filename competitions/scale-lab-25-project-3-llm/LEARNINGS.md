# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- Fetched file listing shows `train.csv` and `test.csv`; no sample submission was listed.
- The task text says the training data is a Lu Xun corpus.

## Target And Metric

- Metric is perplexity (PPL), computed on the test set.

## Validation

- Initial notebook uses a chronological token split from the encoded training corpus and reports validation negative log-likelihood and PPL.

## Leakage And Rules

- Tokenizer must be character-level and built from the training text's unique characters and punctuation.
- Model must be a Transformer with <=6 layers, hidden dimension <=512, <=8 attention heads, <=50M parameters, and <=8k vocabulary.

## Features

- TBD

## Models

- TBD

## Ensembling And Submission Behavior

- TBD

## Leaderboard Notes

- TBD
