# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Repository overview

Personal Kaggle competition notebooks for [dalloliogm](https://www.kaggle.com/dalloliogm/). The repo is linked to Kaggle and contains a flat collection of ~350+ notebooks and scripts in an intentionally unstructured way — one file per competition/experiment, no shared library, no build system.

## File types

- **`.ipynb`** — Jupyter notebooks (Python). The vast majority of files. Contain full EDA, training, and submission pipelines inline.
- **`.r`** — R scripts for competition entries using tidymodels, LightGBM, H2O, XGBoost.
- **`.rmd`** — R Markdown notebooks.
- **`notebooks/`** — A small subfolder with a couple of structured notebooks.
- **`.py`** — Rare; used for competition inference servers (e.g. Mitsui, which requires a `predict()` function served via `kaggle_evaluation`).

## Common patterns

**Python notebooks** typically use: `pandas`, `polars`, `numpy`, `scikit-learn`, `lightgbm`, `xgboost`, `catboost`, `autogluon`, `keras`/`tensorflow`/`pytorch`, and `kaggle_evaluation` (for inference-server competitions).

**R notebooks** typically use: `tidymodels`, `lightgbm`, `h2o`, `xgboost`, `tidyverse`.

**Inference-server competitions** (e.g. Mitsui) follow the pattern: define a `predict(test, ...)` function, wrap it in a competition-specific inference server, and call `inference_server.serve()` when `KAGGLE_IS_COMPETITION_RERUN` is set.

## Running notebooks

Notebooks are designed to run on Kaggle kernels, not locally. Input data paths are `/kaggle/input/<competition-name>/`. There is no local test runner or CI.

To open and edit a notebook locally: `jupyter notebook <filename>.ipynb`

## Gitignore

Submission files (`submission*`), `.h5` model files, and `.env` are excluded.
