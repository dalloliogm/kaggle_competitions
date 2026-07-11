# Notebook Templates

Put reusable notebooks here when they become useful starting points across competitions.

Suggested naming:

```text
tabular-lightgbm-baseline.ipynb
tabular-catboost-cv.ipynb
nlp-transformer-inference.ipynb
vision-pytorch-training.ipynb
ensemble-blending.ipynb
```

Use a template when initializing a competition workspace:

```bash
./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/<slug> \
  --template tabular-lightgbm-baseline
```

Templates should avoid competition-specific hardcoding. Prefer variables near the top for:

- competition slug
- input directory
- target column
- ID column
- metric
- submission columns

