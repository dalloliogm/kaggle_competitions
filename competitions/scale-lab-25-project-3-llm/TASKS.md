# Tasks

## Current Goal

- [ ] Run `notebooks/char_transformer_baseline.ipynb` on Kaggle with the competition dataset attached.
- [ ] Ask the competition organizer to publish `sample_submission.csv` or correct the Kaggle evaluation setup.
- [ ] Record validation PPL and any public leaderboard result in `APPROACHES.md`.

## Next Experiments

- [ ] Tune model capacity within constraints after the first end-to-end run.
- [ ] Try longer context lengths if memory allows.
- [ ] Add learning-rate warmup if training is unstable.

## Done

- [x] Initialized workspace from Kaggle competition URL.
- [x] Created baseline character-level Transformer notebook.
- [x] Downloaded and inspected the real train/test CSV schemas.
- [x] Confirmed that the hidden five-row submission IDs cannot be derived from `test.csv`.
- [x] Removed the invalid five-group submission heuristic from the notebook.

## Questions

- What are the five expected `id` values and prediction column?
- Should the organizer change the Kaggle backend metric from Accuracy Score to PPL?
