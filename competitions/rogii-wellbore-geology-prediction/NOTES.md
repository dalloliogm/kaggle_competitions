# Notes

## EDA Observations

- Initial file listing shows paired horizontal-well and type-well CSVs for train/test, plus train PNGs and a sample submission.
- Competition deadline from Kaggle competition search: 2026-08-05 23:59:00.
- Category: Featured; reward: 50,000 USD.

## Feature Ideas

- Use geometry and trajectory features from `X`, `Y`, `Z`, `MD`.
- Use GR curve matching against paired type-well curves.
- Treat known `TVT_input` regions as calibration anchors.

## Model Ideas

- Start with `notebooks/nn-starter-cv-15-5.ipynb` for a simple PyTorch baseline.
- Compare against `notebooks/wellbore-geology-tcn.ipynb` for per-well sequence modeling.
- Review `notebooks/rogii-lgbm-aug-online-training.ipynb` for engineered-feature LightGBM and online/calibration-zone augmentation.

## Useful References

- Competition URL: https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction
- Fetched references are under `references/`.
