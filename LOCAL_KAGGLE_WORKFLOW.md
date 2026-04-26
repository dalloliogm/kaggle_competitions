# Local-to-Kaggle Notebook Workflow

This repository intentionally keeps Kaggle-saved notebooks in the root folder, because Kaggle's "Save notebook to GitHub" button writes them that way. The local workflow below keeps that layout intact while making it easy to edit notebooks in Codex, Claude Code, VS Code, or Jupyter, then execute them on Kaggle.

## Active Competition Workspaces

Root notebooks are the Kaggle UI archive. For active competitions, create a focused workspace under `competitions/`:

```bash
./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/<slug>
```

When a URL is provided, the script derives the Kaggle slug and attempts to save Kaggle description, evaluation, rules, and file-list context under `references/`.

This creates:

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

The Codex skill that describes this workflow is versioned in the repo at:

```text
.codex/skills/kaggle-competition-workspace/
```

Cross-agent configuration is intentionally adapter-based:

```text
AGENTS.md
CLAUDE.md
.github/copilot-instructions.md
.github/instructions/kaggle-competition-workspace.instructions.md
.codex/skills/kaggle-competition-workspace/
.codex/skills/kaggle-competition-discovery/
```

`AGENTS.md` is the shared source of truth. The other files exist so Claude Code, GitHub Copilot, and Codex can each discover the same workflow through their native conventions.

Use `APPROACHES.md` to record experiments, scores, outcomes, backlog ideas, and abandoned directions. Use `LEARNINGS.md` for durable insights about data, validation, leakage, features, models, ensembling, and leaderboard behavior.

To seed the workspace with an existing root notebook:

```bash
./scripts/init_competition_workspace.py "Playground Series S6E4" \
  --slug playground-s6e4 \
  --notebook root-notebook.ipynb
```

To start from a reusable template:

```bash
./scripts/init_competition_workspace.py https://www.kaggle.com/competitions/<slug> \
  --template tabular-lightgbm-baseline
```

Reusable templates live in `templates/notebooks/`.

To list/search competitions:

```bash
./scripts/list_kaggle_competitions.py --search "playground"
./scripts/list_kaggle_competitions.py --group entered
```

## Authentication

The helper scripts load `~/.env` if it exists. Kaggle's CLI expects:

```bash
KAGGLE_USERNAME=your_username
KAGGLE_KEY=your_api_key
```

If your `~/.env` uses `KAGGLE_API_KEY` instead of `KAGGLE_KEY`, the scripts map it automatically:

```bash
KAGGLE_USERNAME=your_username
KAGGLE_API_KEY=your_api_key
```

Do not commit `.env` files. The repo already ignores `.env`.

## One-time Setup

Install the Kaggle CLI in the environment you use for local work:

```bash
pip install kaggle
```

Check authentication without printing secrets:

```bash
kaggle config view
```

## Push and Run a Root Notebook on Kaggle

Use the root notebook file directly:

```bash
./scripts/kaggle_push_notebook.sh my-notebook.ipynb dalloliogm/my-notebook-slug
```

The script creates a temporary Kaggle kernel folder under `.kaggle_work/my-notebook-slug/`, copies the notebook there, writes `kernel-metadata.json`, and runs:

```bash
kaggle kernels push -p .kaggle_work/my-notebook-slug
```

By default the kernel is created as private, CPU-only, with internet disabled. Edit the generated metadata file if the competition needs GPU, TPU, internet, or attached datasets/competitions:

```bash
.kaggle_work/my-notebook-slug/kernel-metadata.json
```

Then push again with the same command.

## Check Execution Status

```bash
./scripts/kaggle_status.sh dalloliogm/my-notebook-slug
```

## Download Kaggle Outputs

```bash
./scripts/kaggle_output.sh dalloliogm/my-notebook-slug
```

Outputs are downloaded to:

```text
kaggle_outputs/my-notebook-slug/
```

That folder is intentionally local working state; add it to `.gitignore` if you do not want outputs appearing in `git status`.

## Local Debugging Pattern

For notebooks you want to run both locally and on Kaggle, put this near the top:

```python
import os
from pathlib import Path

ON_KAGGLE = os.environ.get("KAGGLE_KERNEL_RUN_TYPE") is not None

if ON_KAGGLE:
    INPUT_DIR = Path("/kaggle/input")
    WORK_DIR = Path("/kaggle/working")
else:
    INPUT_DIR = Path("data")
    WORK_DIR = Path("working")
    WORK_DIR.mkdir(exist_ok=True)
```

Then prefer paths like:

```python
train = INPUT_DIR / "competition-name" / "train.csv"
submission_path = WORK_DIR / "submission.csv"
```

This lets Codex/Claude Code edit and reason about the notebook locally while Kaggle remains the authoritative execution environment.
