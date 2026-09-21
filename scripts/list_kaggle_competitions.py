#!/usr/bin/env python3
"""List Kaggle competitions and show whether local workspaces exist."""

from __future__ import annotations

import argparse
import csv
import hashlib
import os
import re
import subprocess
import sys
from io import StringIO
from pathlib import Path

CACHE_VERSION = "v1"


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


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return re.sub(r"-{2,}", "-", value).strip("-")


def run_list(args: argparse.Namespace, root: Path) -> str:
    cache_dir = root / ".kaggle_cache" / "competition_lists"
    cache_dir.mkdir(parents=True, exist_ok=True)
    cache_key = "|".join(
        [
            CACHE_VERSION,
            args.group,
            args.category,
            args.sort_by,
            str(args.page_size),
            args.search,
        ]
    )
    cache_path = cache_dir / f"{hashlib.sha256(cache_key.encode('utf-8')).hexdigest()[:16]}.csv"
    meta_path = cache_path.with_suffix(".txt")

    if cache_path.exists() and not args.refresh:
        print(f"Using cached Kaggle competition list: {cache_path}", file=sys.stderr)
        return cache_path.read_text(encoding="utf-8")

    if args.offline:
        raise SystemExit(f"No cached result for this query: {cache_path}")

    command = [
        "kaggle",
        "competitions",
        "list",
        "--csv",
        "--group",
        args.group,
        "--category",
        args.category,
        "--sort-by",
        args.sort_by,
        "--page-size",
        str(args.page_size),
    ]
    if args.search:
        command.extend(["--search", args.search])

    result = subprocess.run(command, cwd=root, env=load_kaggle_env(root), text=True, capture_output=True, check=False)
    if result.returncode != 0:
        if cache_path.exists():
            print(f"warn: Kaggle API failed; using stale cache: {cache_path}", file=sys.stderr)
            sys.stderr.write(result.stderr or result.stdout)
            return cache_path.read_text(encoding="utf-8")
        sys.stderr.write(result.stderr or result.stdout)
        raise SystemExit(result.returncode)

    cache_path.write_text(result.stdout, encoding="utf-8")
    meta_path.write_text(
        "\n".join(
            [
                f"group={args.group}",
                f"category={args.category}",
                f"sort_by={args.sort_by}",
                f"page_size={args.page_size}",
                f"search={args.search}",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    return result.stdout


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--search", "-s", default="", help="Search term")
    parser.add_argument("--group", default="general", choices=["general", "entered", "inClass"])
    parser.add_argument(
        "--category",
        default="all",
        choices=["all", "featured", "research", "recruitment", "gettingStarted", "masters", "playground"],
    )
    parser.add_argument(
        "--sort-by",
        default="latestDeadline",
        choices=["grouped", "prize", "earliestDeadline", "latestDeadline", "numberOfTeams", "recentlyCreated"],
    )
    parser.add_argument("--page-size", type=int, default=20)
    parser.add_argument("--refresh", action="store_true", help="Fetch fresh results instead of using the local cache")
    parser.add_argument("--offline", action="store_true", help="Only use cached results; fail if the query is not cached")
    args = parser.parse_args()

    root = Path.cwd()
    reader = csv.DictReader(StringIO(run_list(args, root)))
    rows = list(reader)
    if not rows:
        print("No competitions found.")
        return

    print("ref | local | title | deadline | category | reward | teams")
    print("--- | --- | --- | --- | --- | --- | ---")
    for row in rows:
        ref = row.get("ref") or row.get("Ref") or ""
        title = row.get("title") or row.get("Title") or ""
        local_slug = slugify(ref or title)
        local = "yes" if (root / "competitions" / local_slug).exists() else "no"
        deadline = row.get("deadline") or row.get("Deadline") or ""
        category = row.get("category") or row.get("Category") or ""
        reward = row.get("reward") or row.get("Reward") or ""
        teams = row.get("teamCount") or row.get("TeamCount") or row.get("teams") or ""
        print(f"{ref} | {local} | {title} | {deadline} | {category} | {reward} | {teams}")


if __name__ == "__main__":
    main()
