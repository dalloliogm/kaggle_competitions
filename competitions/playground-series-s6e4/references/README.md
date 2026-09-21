# References

This folder is intended to hold local copies of the Kaggle competition pages
(description, evaluation, rules) and any related papers, blog posts, or notes.

## Auto-fetch

`scripts/init_competition_workspace.py` populates this folder with
`description.md`, `evaluation.md`, and `rules.md` by calling
`kaggle competitions pages <slug> --content --page-name <page>`.

That step did not run during the initial scaffold from Cowork because the
sandbox does not have the `kaggle` CLI on its `PATH` and the `kaggle.com`
domain is outside its network allowlist.

To fill this folder, re-run the init script from your terminal:

```bash
cd ~/workspace/kaggle_competitions
./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/playground-series-s6e4
```

The script is idempotent for the markdown scaffolding — it will only re-run
the Kaggle page fetch.

## What is known so far

- Title: **Predicting Irrigation Need**
- Slug: `playground-series-s6e4`
- Series: Kaggle Playground Series, Season 6 Episode 4 (April 2026 monthly)
- URL: https://www.kaggle.com/competitions/playground-series-s6e4
