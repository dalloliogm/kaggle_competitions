-----------------------
Kaggle Competitions
-----------------------

This is my Kaggle profile: [dalloliogm](https://www.kaggle.com/dalloliogm/). This repo is linked to the Kaggle account, and contains all my notebooks for the competitions, in an utterly disorganized and chaotic way.

## Starting a new competition chat

When opening a new Codex, Claude Code, or Copilot chat for an active Kaggle competition, start with something like:

```text
Use this repository's Kaggle competition workspace workflow. Initialize a workspace for:

Competition: <competition name>
URL: <kaggle competition URL>
Metric: <metric, if known>
Starter notebook: <root notebook filename, if any>

Create/update the competition context files, preserve root-level Kaggle notebooks, and use the repo Kaggle helper scripts when running on Kaggle.
```

If the workspace already exists:

```text
Use the existing workspace at competitions/<slug>. Read its COMPETITION.md, TASKS.md, NOTES.md, and AGENTS.md, then help me with <specific task>.
```

The initializer script is:

```bash
./scripts/init_competition_workspace.py "Competition title" --slug competition-slug
```

See `LOCAL_KAGGLE_WORKFLOW.md`, `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, and `.codex/skills/kaggle-competition-workspace/` for the agent-specific setup.
