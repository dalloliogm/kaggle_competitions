# AGENTS.md

This file provides shared AI-agent guidance for Codex, Claude Code, GitHub Copilot, and similar coding agents when working with this repository.

Adapter files for specific tools:

- `CLAUDE.md` imports this file for Claude Code.
- `.github/copilot-instructions.md` summarizes this file for GitHub Copilot.
- `.github/instructions/kaggle-competition-workspace.instructions.md` adds Copilot path-specific guidance for `competitions/**`.
- `.codex/skills/kaggle-competition-workspace/` contains the repo-local Codex skill for initializing active competition workspaces.
- `.codex/skills/kaggle-competition-discovery/` contains the repo-local Codex skill for listing/searching competitions before choosing one.

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

**Agent / bot competitions** (e.g. Orbit Wars, Maze Crawler) run on `kaggle_environments`: define an `agent(obs)` entry point in `main.py`, submit `main.py` (or a `tar.gz` with `main.py` at the archive root), and Kaggle scores it on a head-to-head episode ladder. When iterating on these:

- **Run the Kaggle CLI via `uvx`** — it is not installed in this repo's env: `uvx --index-url https://pypi.org/simple kaggle <command>` (the default package index is a private mirror that returns 401). Useful subcommands: `competitions submit | submissions | episodes <submission_id> | replay <episode_id> | leaderboard`.
- **Kaggle authentication (per environment — this is what breaks in a fresh chat).** The current CLI authenticates with an **access token**, not the legacy `kaggle.json` username/key pair. Verify with `uvx --index-url https://pypi.org/simple kaggle config view` — a working setup reports `auth_method: ACCESS_TOKEN`. Each new machine/session needs the token re-supplied; it is **not** committed to the repo (never commit it). Set it up either way:
  - **Token file (what this repo uses):** save the `KGAT…` token to `~/.kaggle/access_token` (`chmod 600`). Generate it at <https://www.kaggle.com/settings/api> ("Create New Token" / "API tokens") or via `kaggle auth login`.
  - **Env var:** `export KAGGLE_API_TOKEN=KGAT…` (handy for CI / non-interactive shells).
  - Legacy fallback still accepted by the CLI: `~/.kaggle/kaggle.json` with `{"username":…,"key":…}`, or `KAGGLE_USERNAME`+`KAGGLE_KEY`. Prefer the access token.
  - Do **not** override `KAGGLE_CONFIG_DIR` away from `~/.kaggle` when relying on `~/.kaggle/access_token`, or the CLI will not find the token.
- **Read `docs/kaggle-simulation-competition-playbook.md` early.** Before spending substantial time on heuristic tuning, check whether public episode replays, replay datasets, or Meta Kaggle rating data can support replay mining, behavior cloning, action-space analysis, or self-play setup.
- **Benchmark each candidate agent in a SEPARATE process.** Agents that bundle their own packages and share module names (e.g. a vendored `orbit_lite`) collide in `sys.modules` when run in one Python process (first load wins), producing misleadingly identical results across candidates.
- **Trust the live ladder over local benchmarks.** Local seeded matches can diverge from live results; verify a submission's real behavior by downloading its replays (`kaggle competitions episodes <id>`, then `replay <episode_id>`) and analyzing them.
- **Verify current state directly before acting or assuming.** Check which submissions are actually live (`kaggle competitions submissions`) and whether files changed (`git status`) rather than relying on assumptions — submission slots and the latest-N active-pair window are easy to misjudge.

**Notebook-only ("code") competitions** (e.g. ROGII Wellbore Geology Prediction) reject a plain file upload outright:

- `kaggle competitions submit -c <slug> -f submission.csv -m "..."` fails with a 400 and a generic `Bad Request` from the CLI. The real reason only shows up if you catch the `requests.HTTPError` and read `e.response.text` — it says `"Submission not allowed: This competition only accepts Submissions from Notebooks."` The CLI swallows this detail.
- The CLI's documented `-k KERNEL -v VERSION` flags route to a **different** API endpoint (`CreateCodeSubmission` instead of `CreateSubmission`) but still fail with a bare 400 if you don't also pass `-f <output-filename>` — the file name (e.g. `submission.csv`) is required so Kaggle knows which of the kernel's output files to grade, and the CLI's argument parser doesn't enforce that combination.
- **What works**: call the Python client directly rather than fighting the CLI:
  ```python
  from kaggle.api.kaggle_api_extended import KaggleApi
  api = KaggleApi(); api.authenticate()
  api.competition_submit_code(
      file_name='submission.csv',        # the kernel's output file to grade
      message='...',
      competition='<competition-slug>',
      kernel='<owner>/<kernel-slug>',    # the pushed kernel, not a local path
      kernel_version=1,                  # from `kaggle kernels push` output
  )
  ```
  Run it via `uvx --index-url https://pypi.org/simple --from kaggle python3 -c "..."` in this repo's env. This returns a submission `ref` immediately (still scores asynchronously — poll `kaggle competitions submissions -c <slug> --format json` and compare `ref` as an `int`, not a string).
- A kernel can produce many candidate output files, but Kaggle only ever grades whichever one is passed as `file_name` (almost always `submission.csv`) — to submit a *different* candidate file as the graded one, the kernel itself must write it out under that name (e.g. append a final cell that overwrites `submission.csv` from the desired file), not just have it sitting alongside as another output.

## Running notebooks

Notebooks are designed to run on Kaggle kernels, not locally. Input data paths are `/kaggle/input/<competition-name>/`. There is no local test runner or CI.

To open and edit a notebook locally: `jupyter notebook <filename>.ipynb`

## Active competition workspaces

Root-level notebooks are expected because they are saved by Kaggle's "Save notebook to GitHub" workflow. Do not reorganize or move root notebooks unless explicitly asked.

For ongoing competitions, create a focused workspace with:

`./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/competition-slug`

Each workspace should contain `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, `LEARNINGS.md`, `AGENTS.md`, `notebooks/`, `submissions/`, and `references/`. Use the workspace markdown files to capture competition-specific context and instructions.

Before proposing or implementing a new modeling direction in an existing workspace, read `APPROACHES.md` and `LEARNINGS.md` so previous experiments and durable insights are not lost.

When listing, searching, or choosing competitions, use `./scripts/list_kaggle_competitions.py`. It caches identical queries under `.kaggle_cache/competition_lists/`; use `--refresh` when current Kaggle results matter.

Reusable notebook templates live in `templates/notebooks/`; track them in `templates/notebooks/TEMPLATE_REGISTRY.md` and copy them into workspaces with `init_competition_workspace.py --template`.

When executing on Kaggle, prefer the helper scripts in `scripts/`: `kaggle_push_notebook.sh`, `kaggle_status.sh`, and `kaggle_output.sh`.

The repository-local Codex skill for this workflow lives at `.codex/skills/kaggle-competition-workspace/`. Treat that copy as the versioned source of truth for the skill.

The repository-local Codex skill for competition discovery lives at `.codex/skills/kaggle-competition-discovery/`.

## Gitignore

Submission files (`submission*`), `.h5` model files, and `.env` are excluded.
