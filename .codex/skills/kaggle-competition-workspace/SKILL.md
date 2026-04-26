---
name: kaggle-competition-workspace
description: Use when initializing or maintaining an active Kaggle competition workspace inside the kaggle_competitions repository, especially when the user wants a competitions/<slug>/ folder with COMPETITION.md, TASKS.md, NOTES.md, AGENTS.md, notebooks, submissions, and references while preserving root-level Kaggle UI autosaved notebooks.
---

# Kaggle Competition Workspace

## Purpose

Set up and maintain lightweight per-competition workspaces without reorganizing the root Kaggle notebook archive.

Root-level notebooks are expected because Kaggle's "Save notebook to GitHub" flow writes there. Do not move or rename them unless the user explicitly asks.

## Initialize A Workspace

When the user pastes a Kaggle competition URL, initialize directly from the URL:

```bash
./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/competition-slug
```

The script derives the competition slug from the URL and attempts to fetch Kaggle pages/files into `references/`.

If the user provides a starter root notebook or reusable template, copy it into the workspace with:

```bash
./scripts/init_competition_workspace.py "Competition title" \
  --slug competition-slug \
  --notebook root-notebook.ipynb

./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/competition-slug \
  --template tabular-lightgbm-baseline
```

The expected layout is:

```text
competitions/<slug>/
  COMPETITION.md
  TASKS.md
  NOTES.md
  APPROACHES.md
  LEARNINGS.md
  AGENTS.md
  notebooks/
  submissions/
  references/
```

## What To Capture

Use `COMPETITION.md` for durable facts: URL, objective, metric, data paths, submission format, rules, and current baseline.

Use `TASKS.md` for the current plan, open experiments, completed experiments, and questions.

Use `NOTES.md` for EDA observations, feature ideas, model ideas, leaderboard notes, and useful links.

Use `APPROACHES.md` for structured experiment history: current best, tried approaches, backlog ideas, and abandoned directions.

Use `LEARNINGS.md` for durable insights: data quirks, validation behavior, leakage risks, feature/model observations, and leaderboard behavior.

Use workspace `AGENTS.md` for competition-specific instructions that should guide future Codex/Claude work.

Before proposing or implementing a new modeling direction in an existing workspace, read `APPROACHES.md` and `LEARNINGS.md` so repeated failed experiments are avoided.

## Discover Competitions

When the user asks to list, search, compare, or choose Kaggle competitions, use:

```bash
./scripts/list_kaggle_competitions.py --search "search terms"
./scripts/list_kaggle_competitions.py --group entered
./scripts/list_kaggle_competitions.py --category playground --sort-by latestDeadline
```

Use the results to offer a short list and ask which competition to initialize.

## Notebook Templates

Reusable starter notebooks live under `templates/notebooks/` and are tracked in `templates/notebooks/TEMPLATE_REGISTRY.md`.

Use templates for repeatable patterns such as tabular LightGBM baselines, CatBoost CV, ensemble blending, NLP inference, or vision training.

## Kaggle Execution

For running notebooks on Kaggle from this repo, prefer the existing helper scripts:

```bash
./scripts/kaggle_push_notebook.sh NOTEBOOK.ipynb owner/kernel-slug
./scripts/kaggle_status.sh owner/kernel-slug
./scripts/kaggle_output.sh owner/kernel-slug
```

Preserve Kaggle compatibility in code: use `/kaggle/input/...` and `/kaggle/working` on Kaggle, with local fallbacks such as `data/` and `working/` only when useful.

## When To Suggest A Separate Repo

Suggest a dedicated repo only when the competition grows into a real project: reusable `src/`, configs, tests, multiple pipelines, team collaboration, or a production-style inference package.
