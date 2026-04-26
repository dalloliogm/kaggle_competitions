#!/usr/bin/env python3
"""Initialize a Kaggle competition workspace folder."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
from pathlib import Path
from urllib.parse import urlparse


DEFAULT_PAGES = ("description", "evaluation", "rules")


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-{2,}", "-", value).strip("-")
    if not value:
        raise SystemExit("Could not derive a slug. Pass --slug explicitly.")
    return value


def competition_slug_from_url(value: str) -> str | None:
    parsed = urlparse(value)
    if not parsed.scheme or "kaggle.com" not in parsed.netloc:
        return None
    parts = [part for part in parsed.path.split("/") if part]
    if "competitions" not in parts:
        return None
    index = parts.index("competitions")
    if index + 1 >= len(parts):
        return None
    return parts[index + 1]


def title_from_slug(slug: str) -> str:
    return " ".join(part.upper() if part in {"ai", "nlp", "llm"} else part.capitalize() for part in slug.split("-"))


def load_kaggle_env(root: Path) -> dict[str, str]:
    env = os.environ.copy()
    dotenv = Path.home() / ".env"
    if dotenv.exists():
        for raw_line in dotenv.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            if line.startswith("export "):
                line = line.removeprefix("export ").strip()
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
                env.setdefault(key, value)

    if "KAGGLE_KEY" not in env and "KAGGLE_API_KEY" in env:
        env["KAGGLE_KEY"] = env["KAGGLE_API_KEY"]
    if "KAGGLE_USERNAME" not in env and "KAGGLE_API_USERNAME" in env:
        env["KAGGLE_USERNAME"] = env["KAGGLE_API_USERNAME"]

    env.setdefault("KAGGLE_CONFIG_DIR", str(root / ".kaggle_config"))
    env["PATH"] = f"{root / '.venv' / 'bin'}:{env.get('PATH', '')}"
    return env


def run_kaggle(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["kaggle", *args],
        cwd=root,
        env=load_kaggle_env(root),
        text=True,
        capture_output=True,
        check=False,
    )


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
- Kaggle CLI slug: `{args.competition_slug or slug}`

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
- Kaggle CLI slug: `{args.competition_slug or slug}`

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
    parser.add_argument("title", nargs="?", help="Competition title or Kaggle competition URL")
    parser.add_argument("--slug", help="Folder slug. Defaults to slugified title.")
    parser.add_argument("--url", default="", help="Kaggle competition URL")
    parser.add_argument("--competition-slug", default="", help="Kaggle competition URL suffix. Derived from URL when possible.")
    parser.add_argument("--metric", default="", help="Evaluation metric")
    parser.add_argument("--dataset-slug", default="", help="Kaggle input dataset folder name if different from workspace slug")
    parser.add_argument(
        "--external-data",
        default="TBD",
        choices=["TBD", "allowed", "not allowed", "restricted"],
        help="External data rule summary",
    )
    parser.add_argument("--notebook", type=Path, help="Optional existing notebook to copy into notebooks/")
    parser.add_argument("--template", help="Template notebook name from templates/notebooks/ or a notebook path to copy")
    parser.add_argument("--no-fetch", action="store_true", help="Do not fetch Kaggle pages/files when a competition slug is known")
    parser.add_argument("--force", action="store_true", help="Overwrite existing markdown files")
    args = parser.parse_args()

    root = Path.cwd()
    if not args.title and not args.url:
        raise SystemExit("Pass a competition title or Kaggle competition URL.")

    positional_url_slug = competition_slug_from_url(args.title or "")
    url_slug = competition_slug_from_url(args.url)
    if positional_url_slug:
        args.url = args.title
        args.title = ""

    args.competition_slug = args.competition_slug or positional_url_slug or url_slug or ""
    if not args.title:
        args.title = title_from_slug(args.competition_slug) if args.competition_slug else "TBD"

    slug = args.slug or slugify(args.competition_slug or args.title)
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

    if args.template:
        template = Path(args.template)
        if not template.suffix:
            template = root / "templates" / "notebooks" / f"{args.template}.ipynb"
        elif not template.is_absolute():
            template = root / template
        if not template.exists():
            raise SystemExit(f"Template notebook not found: {template}")
        destination = workspace / "notebooks" / template.name
        if destination.exists() and not args.force:
            print(f"exists: {destination}")
        else:
            shutil.copy2(template, destination)
            print(f"copied: {template} -> {destination}")

    if args.competition_slug and not args.no_fetch:
        references = workspace / "references"
        for page_name in DEFAULT_PAGES:
            result = run_kaggle(root, "competitions", "pages", args.competition_slug, "--content", "--page-name", page_name)
            target = references / f"kaggle_{page_name}.md"
            if result.returncode == 0 and result.stdout.strip():
                write_new(target, result.stdout, args.force)
            else:
                print(f"warn:   could not fetch Kaggle {page_name} page")
                if result.stderr.strip():
                    print(result.stderr.strip())

        result = run_kaggle(root, "competitions", "files", args.competition_slug)
        target = references / "kaggle_files.txt"
        if result.returncode == 0 and result.stdout.strip():
            write_new(target, result.stdout, args.force)
        else:
            print("warn:   could not fetch Kaggle file listing")
            if result.stderr.strip():
                print(result.stderr.strip())

    print(f"\nWorkspace ready: {workspace}")


if __name__ == "__main__":
    main()
