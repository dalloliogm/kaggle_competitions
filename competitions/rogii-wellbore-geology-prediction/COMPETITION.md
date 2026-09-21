# Rogii Wellbore Geology Prediction

## Links

- Competition: https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction
- Kaggle workspace slug: `rogii-wellbore-geology-prediction`
- Kaggle CLI slug: `rogii-wellbore-geology-prediction`

## Objective

Predict the true vertical thickness/depth target (`tvt`) along horizontal wellbores from drilling and well-log data. The competition is framed around automating geological interpretation during well placement, using horizontal well measurements, paired type-well curves, and partial known `TVT_input` values.

## Evaluation

- Metric: root mean squared error (RMSE) on hidden test rows (row-weighted, so long wells dominate more than short ones).
- Validation approach: use grouped validation by well ID; avoid splitting rows from the same well across train/validation folds.
- Public/private leaderboard notes: confirmed joined (`userHasEntered: True`, verified via `kaggle competitions list -s rogii`). 3 submissions so far, best public score **11.107** (2026-05-10, submission `52524349`; see `APPROACHES.md` for the full table and notebook attribution). Team count ~5,504 as of 2026-07-23.
- **Our real standing (2026-07-23): rank 3504/5504 at score 11.107 — worse than ~64% of the field.** Full public LB snapshot saved at `references/rogii-wellbore-geology-prediction-publicleaderboard-2026-07-23T08:29:24.csv`.
- **Medal math from that snapshot** (5504 teams; Kaggle's usual "top 10 + 0.2%N" gold / "top 5%" silver / "top 10%" bronze formula): gold ≈ top 21 teams → score ≤ **5.945**; silver ≈ top 275 → ≤ **6.542**; bronze ≈ top 550 → ≤ **6.662**; top 25% (rank 1376) → ≤ **7.160**; median (rank 2752) → **8.863**. Bronze and silver cutoffs are close together (6.54 vs 6.66) — the harder jump is bronze→gold, not top25%→bronze.
- Deadline 2026-08-05 23:59:00 → ~13 days left as of 2026-07-23. Realistically, the $50k cash prize (top 4 only) is out of reach from rank 3504; medal (bronze/silver, stretch gold) is the realistic target.

## Data

- Kaggle input path: `/kaggle/input/rogii-wellbore-geology-prediction/`
- Alternate Kaggle input path used by some notebooks: `/kaggle/input/competitions/rogii-wellbore-geology-prediction/`
- Local data path: `data/rogii-wellbore-geology-prediction/`
- Key files:
  - `train/*__horizontal_well.csv`
  - `train/*__typewell.csv`
  - `train/*.png`
  - `test/*__horizontal_well.csv`
  - `test/*__typewell.csv`
  - `sample_submission.csv`
  - `AI_wellbore_geology_prediction_task_en.pptx`
- **Test set is only 3 wells** (`000d7d20`, `00bbac68`, `00e12e8b`; confirmed via `kaggle competitions files`), 773 train wells, 14,151 hidden submission rows total (~3.78M train "tail" rows for offline diagnostics). Each test well has a visible prefix (known `TVT_input`) followed by one hidden tail to predict — this is prefix-conditioned forecasting per well, not row-level interpolation.
- Because there are only 3 test wells, public vs. private LB most likely splits **rows within the same 3 wells**, not separate unseen wells (Kaggle doesn't disclose the split mechanism — this is an inference from the file listing, not confirmed). That implies lower private-shakeup risk than a typical Kaggle competition, but see `LEARNINGS.md` for the one exception (same-well train/test overlap tricks).

## Submission

- Expected file: `submission.csv`
- Required columns: `id,tvt`
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: allowed if publicly available at no/minimal cost to all participants (standard Kaggle "Reasonableness" clause). Public dataset/notebook sharing is **explicitly permitted** by Section 3.6.b of the rules (must be shared on Kaggle forums/notebooks, not privately) — so using widely-forked public notebooks and shared "toolkit" datasets (see `LEARNINGS.md`) is fully compliant.
- Internet: notebooks currently pulled from Kaggle metadata have internet disabled.
- **GPU/TPU: NOT required for the current best public approach.** Reviewed 5 top public notebooks (see `LEARNINGS.md`) — all use `USE_GPU = os.environ.get("USE_GPU", "auto")` with an `nvidia-smi`-based detect-and-fallback-to-CPU pattern for LightGBM/CatBoost, and any `torch` usage found was CPU-only inference (`torch.load(..., map_location='cpu')`, `torch.device('cpu')`) loading a pretrained checkpoint, never GPU training. The core technique (particle filter / DTW / beam search over GR curves) is classic CPU signal processing (numba/joblib), not deep learning. **A Kaggle GPU-quota gap is not a blocker for this competition's dominant approach.**
- Submission limits: max 5 submissions/day, up to 2 Final Submissions selected for judging, max team size 5.
- Team/merge rules: no private sharing outside the official Kaggle team; public code sharing should be through the competition forum/notebooks.

## Current Baseline

- Local CV: TBD
- Public LB: 11.107 (best of 3 submissions; see `APPROACHES.md`) — rank 3504/5504, well below the current public-notebook meta cluster (6-9 range). See `LEARNINGS.md` for the "target-free geosteering" technique that now dominates the leaderboard and `TASKS.md` for the catch-up plan.
- Notebook/kernel (likely best of our own): `notebooks/triple-signal-beam-search-dual-pf-lightgbm.ipynb` (attribution inferred from timing, not yet confirmed)
- Other notebooks in `notebooks/`: `nn-starter-cv-15-5.ipynb`, `rogii-lgbm-aug-online-training.ipynb`, `wellbore-geology-tcn.ipynb`, `rogii-ultranote-v6-gp-main.ipynb`, `rogii-automated-public-ensemble-v2.ipynb` (in `../playground-series-s6e5/notebooks/`, likely misfiled)
- 5 top public notebooks pulled 2026-07-23 for reference/adaptation (see `LEARNINGS.md` for what each contains): `working-note-target-free-tvt-geosteering.ipynb`, `rogii-eda-target-free-alignment-for-tvt.ipynb`, `9-251-rogii-wellbore-geology-prediction-dwt-based.ipynb`, `rogii-lb7295-public-rebuild.ipynb`, `top-pf-config-branch-conservative-visuals.ipynb`
