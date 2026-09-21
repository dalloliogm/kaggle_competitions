# GitHub Copilot Instructions

This repository is a personal Kaggle competition workspace. Root-level notebooks are expected because Kaggle's "Save notebook to GitHub" workflow writes them there.

Use `AGENTS.md` as the shared source of truth for repository conventions. Key rules:

- Do not reorganize, move, or rename root-level Kaggle notebooks unless explicitly asked.
- Treat notebooks as competition/experiment units; prefer small, auditable edits.
- Notebooks are designed to run on Kaggle kernels with inputs under `/kaggle/input/...`.
- For active competitions, use `competitions/<slug>/` workspaces with `COMPETITION.md`, `TASKS.md`, `NOTES.md`, `APPROACHES.md`, `LEARNINGS.md`, `AGENTS.md`, `notebooks/`, `submissions/`, and `references/`.
- In existing competition workspaces, inspect `APPROACHES.md` and `LEARNINGS.md` before suggesting new experiments.
- Prefer `scripts/init_competition_workspace.py` to create a competition workspace.
- A pasted Kaggle competition URL should be enough to initialize a workspace; derive the slug from the URL and fetch/store useful Kaggle context when possible.
- Use `scripts/list_kaggle_competitions.py` when listing, searching, or choosing competitions.
- Reusable notebook templates live under `templates/notebooks/` and are tracked in `templates/notebooks/TEMPLATE_REGISTRY.md`.
- Prefer `scripts/kaggle_push_notebook.sh`, `scripts/kaggle_status.sh`, and `scripts/kaggle_output.sh` for Kaggle execution.
- Do not commit generated submissions, downloaded outputs, model weights, secrets, `.env`, or local working data unless explicitly requested.
