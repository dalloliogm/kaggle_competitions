-----------------------
Kaggle Competitions
-----------------------

This is my Kaggle profile: [dalloliogm](https://www.kaggle.com/dalloliogm/). This repo is linked to the Kaggle account, and contains all my notebooks for the competitions, in an utterly disorganized and chaotic way.

## Starting a new competition chat

When opening a new Codex, Claude Code, or Copilot chat for an active Kaggle competition, start with something like:

```text
Use this repository's Kaggle competition workspace workflow.

Competition URL: <paste Kaggle competition URL>

Initialize the workspace, read the competition page for objective/rules/evaluation context, preserve root-level Kaggle notebooks, and use the repo Kaggle helper scripts when running on Kaggle.
```

If the workspace already exists:

```text
Use the existing workspace at competitions/<slug>. Read its COMPETITION.md, TASKS.md, NOTES.md, APPROACHES.md, LEARNINGS.md, and AGENTS.md, then help me with <specific task>.
```

The initializer script is:

```bash
./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/<slug>
```

To search or choose competitions from the command line:

```bash
./scripts/list_kaggle_competitions.py --search "playground"
./scripts/list_kaggle_competitions.py --group entered
```

In a new chat, you can also ask:

```text
Use this repository's Kaggle competition discovery workflow. List active Kaggle competitions related to <topic>, show simple metadata, and help me choose one to initialize.
```

## Notebook templates

Reusable starter notebooks live in `templates/notebooks/` and are tracked in `templates/notebooks/TEMPLATE_REGISTRY.md`.

Good candidates for templates are notebooks you reuse across many competitions: tabular baselines, CV training loops, inference-only notebooks, ensembling/blending notebooks, and local/Kaggle path setup cells.

Use a template when initializing a workspace:

```bash
./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/<slug> \
  --template tabular-lightgbm-baseline
```

Keep templates generic: put competition-specific values near the top of the notebook, avoid hardcoded `/kaggle/input/<old-competition>/` paths, and document expected columns/metric in the first markdown cell.

## Tracking progress

Active competition workspaces include two files for memory across chats:

- `APPROACHES.md` tracks modeling approaches tried so far, scores, outcomes, backlog ideas, and abandoned directions.
- `LEARNINGS.md` tracks durable information learned about the data, metric, validation, leakage risks, features, models, ensembling, and leaderboard behavior.

Ask agents to read both before proposing new experiments.

See `LOCAL_KAGGLE_WORKFLOW.md`, `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, and `.codex/skills/` for the agent-specific setup.
