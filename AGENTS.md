# AGENTS.md

This file provides shared AI-agent guidance for Codex, Claude Code, GitHub Copilot, and similar coding agents when working with this repository.

Adapter files for specific tools:

- `CLAUDE.md` imports this file for Claude Code.
- `.github/copilot-instructions.md` summarizes this file for GitHub Copilot.
- `.github/instructions/kaggle-competition-workspace.instructions.md` adds Copilot path-specific guidance for `competitions/**`.
- `.codex/skills/kaggle-competition-workspace/` contains the repo-local Codex skill for initializing active competition workspaces.

## Repository overview

Personal Kaggle competition notebooks for [dalloliogm](https://www.kaggle.com/dalloliogm/). The repo is linked to Kaggle and contains a flat collection of ~350+ notebooks and scripts in an intentionally unstructured way — one file per competition/experiment, no shared library, no build system.

## File types

- **`.ipynb`** — Jupyter notebooks (Python). The vast majority of files. Contain full EDA, training, and submission pipelines inline.
- **`.r`** — R scripts for competition entries using tidymodels, LightGBM, H2O, XGBoost.
- **`.rmd`** — R Markdown notebooks.
- **`competitions/<slug>/`** — Optional active-competition workspace folders with local context files, notes, copied notebooks, submissions, and references.
- **`notebooks/`** — A small subfolder with a couple of structured notebooks.
- **`.py`** — Rare; used for competition inference servers (e.g. Mitsui, which requires a `predict()` function served via `kaggle_evaluation`).

## Common patterns

**Python notebooks** typically use: `pandas`, `polars`, `numpy`, `scikit-learn`, `lightgbm`, `xgboost`, `catboost`, `autogluon`, `keras`/`tensorflow`/`pytorch`, and `kaggle_evaluation` (for inference-server competitions).

**R notebooks** typically use: `tidymodels`, `lightgbm`, `h2o`, `xgboost`, `tidyverse`.

**Inference-server competitions** (e.g. Mitsui) follow the pattern: define a `predict(test, ...)` function, wrap it in a competition-specific inference server, and call `inference_server.serve()` when `KAGGLE_IS_COMPETITION_RERUN` is set.

## Running notebooks

Notebooks are designed to run on Kaggle kernels, not locally. Input data paths are `/kaggle/input/<competition-name>/`. There is no local test runner or CI.

To open and edit a notebook locally: `jupyter notebook <filename>.ipynb`

## Active competition workspaces

Root-level notebooks are expected because they are saved by Kaggle's "Save notebook to GitHub" workflow. Do not reorganize or move root notebooks unless explicitly asked.

For ongoing competitions, create a focused workspace with:

`./scripts/init_competition_workspace.py "Competition title" --slug competition-slug`

Each workspace should contain `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `AGENTS.md`, `notebooks/`, `submissions/`, and `references/`. Use the workspace markdown files to capture competition-specific context and instructions.

When executing on Kaggle, prefer the helper scripts in `scripts/`: `kaggle_push_notebook.sh`, `kaggle_status.sh`, and `kaggle_output.sh`.

The repository-local Codex skill for this workflow lives at `.codex/skills/kaggle-competition-workspace/`. Treat that copy as the versioned source of truth for the skill.

## Gitignore

Submission files (`submission*`), `.h5` model files, and `.env` are excluded.
