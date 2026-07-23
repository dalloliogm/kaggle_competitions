---
name: kaggle-competition-workspace
description: Use when initializing or maintaining an active Kaggle competition workspace inside the kaggle_competitions repository, including creating the standard competition tutorial notebook, context files, notebooks, submissions, and references while preserving root-level Kaggle UI autosaved notebooks.
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
    <slug>-competition-tutorial.ipynb
  submissions/
  references/
```

## Create The Competition Tutorial

For each newly initialized competition, create
`notebooks/<slug>-competition-tutorial.ipynb` after capturing the official task,
data, metric, validation, and submission facts. Use the `jupyter-notebook` skill
with `--kind tutorial` and its tutorial quality checklist.

Make the tutorial competition-specific and include:

- audience, prerequisites, learning goals, and a short outline;
- the prediction target and real data/submission schemas;
- a small runnable example of the core modeling problem;
- the official metric's practical implications and common proxy mistakes;
- leakage-safe validation and a basic submission validator;
- at least one exercise with an answer scaffold;
- a progression from transparent baseline to higher-ceiling approaches.

Prefer a self-contained synthetic fallback so the notebook runs locally without
competition data. Activate optional real-data inspection on Kaggle when inputs
are attached. Respect offline-kernel constraints and avoid installing packages
into the live runtime when that can replace its numerical stack.

Run all code cells top-to-bottom when possible. If real data is unavailable,
execute the synthetic path and state which Kaggle-only path remains unverified.
Record the tutorial path in `TASKS.md`. Do not upload or publish it to Kaggle
unless the user explicitly asks.

## What To Capture

Use `COMPETITION.md` for durable facts: URL, objective, metric, data paths, submission format, rules, and current baseline.

Use `TASKS.md` for the current plan, open experiments, completed experiments, and questions.

Use `NOTES.md` for EDA observations, feature ideas, model ideas, leaderboard notes, and useful links.

Use `APPROACHES.md` for structured experiment history: current best, tried approaches, backlog ideas, and abandoned directions.

Use `LEARNINGS.md` for durable insights: data quirks, validation behavior, leakage risks, feature/model observations, and leaderboard behavior.

Use workspace `AGENTS.md` for competition-specific instructions that should guide future Codex/Claude work.

Before proposing or implementing a new modeling direction in an existing workspace, read `APPROACHES.md` and `LEARNINGS.md` so repeated failed experiments are avoided.

## Simulation / Agent Competitions

For Kaggle Environments or other simulation competitions where submissions play
episodes, use `docs/kaggle-simulation-competition-playbook.md` from the repo
root early in the workspace setup.

Before spending substantial time on heuristic tuning, check whether public
episode replays, replay datasets, or Meta Kaggle rating data are available. If
they are, add replay mining, behavior cloning, action-space analysis, and local
arena work to `TASKS.md` and capture findings in `LEARNINGS.md`.

Prioritize extracting the empirical action distribution from strong players:
no-op rate, all-in/partial-send rate, launch distance or ETA, source/target
patterns, player-count-specific behavior, and failure modes. Use these findings
to choose the simplest viable action abstraction before building a learned policy
or deep heuristic stack.

## Agent-Config Competitions

If the evaluation page asks for an autonomous agent package such as
`submission.zip` with `agent.yaml` at the archive root, use
`references/agent-config-competitions.md` in this skill.

In those workspaces, capture the agent config schema, allowed tools, prompt and
skill layout, and zip-validation requirements. Create `submissions/agent-configs/`
for source folders and validate both the folder and final zip before any upload.
Prioritize a first valid `submit_predictions` call in the agent prompt before
optional EDA or improvement loops.

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

### Authentication (do this first in any new environment)

Kaggle credentials are per-machine and are **not** committed to the repo, so a
fresh chat/session starts unauthenticated ("variables not set"). The current CLI
uses an **access token** (`auth_method: ACCESS_TOKEN`), not the legacy
`kaggle.json` username/key pair. Set it up once per environment:

```bash
# Preferred: save the KGAT... token (from https://www.kaggle.com/settings/api)
mkdir -p ~/.kaggle && printf 'KGAT...' > ~/.kaggle/access_token && chmod 600 ~/.kaggle/access_token
# or, for CI / non-interactive shells:
export KAGGLE_API_TOKEN=KGAT...
# verify:
uvx --index-url https://pypi.org/simple kaggle config view   # expect auth_method: ACCESS_TOKEN
```

`scripts/kaggle_env.sh` (sourced by the helpers below) accepts any of:
`~/.kaggle/access_token`, `KAGGLE_API_TOKEN`, legacy `~/.kaggle/kaggle.json`, or
`KAGGLE_USERNAME`+`KAGGLE_KEY`. Do not point `KAGGLE_CONFIG_DIR` away from
`~/.kaggle` when relying on the token file. Never write the token into a tracked
file.

### Running notebooks

For running notebooks on Kaggle from this repo, prefer the existing helper scripts:

```bash
./scripts/kaggle_push_notebook.sh NOTEBOOK.ipynb owner/kernel-slug
./scripts/kaggle_status.sh owner/kernel-slug
./scripts/kaggle_output.sh owner/kernel-slug
```

Preserve Kaggle compatibility in code: use `/kaggle/input/...` and `/kaggle/working` on Kaggle, with local fallbacks such as `data/` and `working/` only when useful.

### Code-Competition Submissions

Some competitions accept only code/notebook submissions even though the executed
notebook writes a `submission.csv`. For these, raw CSV upload may fail with a
generic Kaggle `400 Bad Request`. Submit the completed kernel version instead:

```bash
kaggle competitions submit <competition-slug> \
  -k owner/kernel-slug \
  -v <completed-version-number> \
  -f submission.csv \
  -m "short experiment description"
```

Before spending a daily submission slot:

- confirm the kernel status is `COMPLETE`;
- download the output with `./scripts/kaggle_output.sh owner/kernel-slug`;
- validate the produced `submission.csv` schema, row IDs, nulls, row types, and
  competition-specific graph/ID invariants;
- record the row/node/edge counts, the submission ID, and the pending/complete
  status in `TASKS.md` and `APPROACHES.md`.

When evaluations take hours and the user explicitly wants to use multiple daily
slots, do not wait for earlier pending submissions if independent completed
kernels are already valid. Submit the distinct completed kernel versions, then
compare all leaderboard results together after they finish.

### Public Notebook Publication

When the user wants to share a competition notebook publicly, treat this as a
publication edit rather than ordinary experiment logging:

- keep the algorithm and data sources unchanged unless the user asks for a new
  experiment;
- rewrite the title, introduction, and summary cells for an external reader;
- explain the competition objective, submission schema, metric implications, and
  the single modeling idea being demonstrated;
- remove private experiment shorthand, stale feedback/debug blocks, and
  references to private notebook IDs that readers cannot interpret;
- clear stale outputs before pushing a new public kernel version;
- set the sidecar `kernel-metadata.json` intentionally, including `is_private`
  and GPU/internet settings.

If Kaggle rejects the push with `Maximum batch GPU session count ... reached`,
check currently running kernels with `kaggle_status.sh` and retry after a batch
GPU slot frees. Do not cancel useful running experiments unless the user
explicitly authorizes it.

## When To Suggest A Separate Repo

Suggest a dedicated repo only when the competition grows into a real project: reusable `src/`, configs, tests, multiple pipelines, team collaboration, or a production-style inference package.
