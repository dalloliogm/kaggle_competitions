---
name: kaggle-competition-discovery
description: Use when listing, searching, summarizing, comparing, or choosing Kaggle competitions from the kaggle_competitions repository before initializing an active competition workspace.
---

# Kaggle Competition Discovery

## Purpose

Find candidate Kaggle competitions, show simple metadata, and help the user choose one to initialize under `competitions/<slug>/`.

## List Or Search

Use the repo script:

```bash
./scripts/list_kaggle_competitions.py --search "search terms"
./scripts/list_kaggle_competitions.py --group entered
./scripts/list_kaggle_competitions.py --category playground --sort-by latestDeadline
```

The script wraps `kaggle competitions list --csv` and marks whether a local workspace already exists.

## Choose And Initialize

After showing candidates, ask the user which competition to use if it is ambiguous. Once chosen, initialize with the workspace skill/script:

```bash
./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/<slug>
```

If the user wants a reusable starting point, add `--template <template-name>`.

## Summaries

Keep competition summaries short: title/ref, deadline, category, reward, teams, and whether a local workspace already exists.

