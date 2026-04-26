#!/usr/bin/env python3
"""Initialize a Kaggle competition workspace folder."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-{2,}", "-", value).strip("-")
    if not value:
        raise SystemExit("Could not derive a slug. Pass --slug explicitly.")
    return value


def write_new(path: Path, content: str, force: bool) -> None:
    if path.exists() and not force:
        print(f"exists: {path}")
        return
    path.write_text(content, encoding="utf-8")
    print(f"wrote:  {path}")


def competition_md(args: argparse.Namespace, slug: str) -> str:
    return f"""# {args.title}

## Links

- Competition: {args.url or "TBD"}
- Kaggle workspace slug: `{slug}`

## Objective

TBD

## Evaluation

- Metric: {args.metric or "TBD"}
- Validation approach: TBD
- Public/private leaderboard notes: TBD

## Data

- Kaggle input path: `/kaggle/input/{args.dataset_slug or slug}/`
- Local data path: `data/{slug}/`
- Key files: TBD

## Submission

- Expected file: `submission.csv`
- Required columns: TBD
- Generated outputs: `submissions/`

## Rules And Constraints

- External data: {args.external_data}
- Internet: TBD
- GPU/TPU: TBD
- Team/merge rules: TBD

## Current Baseline

- Local CV: TBD
- Public LB: TBD
- Notebook/kernel: TBD
"""


def tasks_md() -> str:
    return """# Tasks

## Current Goal

- TBD

## Next Experiments

- TBD

## Done

- TBD

## Questions

- TBD
"""


def notes_md() -> str:
    return """# Notes

## EDA Observations

- TBD

## Feature Ideas

- TBD

## Model Ideas

- TBD

## Useful References

- TBD
"""


def agents_md(args: argparse.Namespace, slug: str) -> str:
    return f"""# AGENTS.md

Competition-specific instructions for `competitions/{slug}`.

## Context

- Competition: {args.title}
- Competition URL: {args.url or "TBD"}
- Metric: {args.metric or "TBD"}

## Working Rules

- Preserve Kaggle compatibility: code that runs on Kaggle should use `/kaggle/input/...` and `/kaggle/working`.
- Prefer small, auditable notebook/script edits over broad refactors.
- Keep root-level Kaggle UI autosaved notebooks in place unless explicitly asked to copy or move one.
- Put active competition notes in this folder: `COMPETITION.md`, `TASKS.md`, and `NOTES.md`.
- Put local submissions or downloaded outputs under `submissions/`; do not commit generated submission files unless explicitly requested.
- When running on Kaggle from this repository, prefer `../../scripts/kaggle_push_notebook.sh`, `../../scripts/kaggle_status.sh`, and `../../scripts/kaggle_output.sh`.

## Competition Constraints

- External data: {args.external_data}
- Internet/GPU/TPU assumptions: TBD
- Known leakage risks: TBD
"""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("title", help="Competition title")
    parser.add_argument("--slug", help="Folder slug. Defaults to slugified title.")
    parser.add_argument("--url", default="", help="Kaggle competition URL")
    parser.add_argument("--metric", default="", help="Evaluation metric")
    parser.add_argument("--dataset-slug", default="", help="Kaggle input dataset folder name if different from workspace slug")
    parser.add_argument(
        "--external-data",
        default="TBD",
        choices=["TBD", "allowed", "not allowed", "restricted"],
        help="External data rule summary",
    )
    parser.add_argument("--notebook", type=Path, help="Optional existing notebook to copy into notebooks/")
    parser.add_argument("--force", action="store_true", help="Overwrite existing markdown files")
    args = parser.parse_args()

    slug = args.slug or slugify(args.title)
    root = Path.cwd()
    workspace = root / "competitions" / slug

    for subdir in ("notebooks", "submissions", "references"):
        (workspace / subdir).mkdir(parents=True, exist_ok=True)

    write_new(workspace / "COMPETITION.md", competition_md(args, slug), args.force)
    write_new(workspace / "TASKS.md", tasks_md(), args.force)
    write_new(workspace / "NOTES.md", notes_md(), args.force)
    write_new(workspace / "AGENTS.md", agents_md(args, slug), args.force)

    if args.notebook:
        source = args.notebook if args.notebook.is_absolute() else root / args.notebook
        if not source.exists():
            raise SystemExit(f"Notebook not found: {source}")
        destination = workspace / "notebooks" / source.name
        if destination.exists() and not args.force:
            print(f"exists: {destination}")
        else:
            shutil.copy2(source, destination)
            print(f"copied: {source} -> {destination}")

    print(f"\nWorkspace ready: {workspace}")


if __name__ == "__main__":
    main()
