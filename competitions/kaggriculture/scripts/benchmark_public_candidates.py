#!/usr/bin/env python3
"""Benchmark extracted public agents in isolated Kaggriculture processes."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
ARENA = ROOT / "scripts" / "run_arena.py"
CANDIDATE_ROOT = ROOT / "submissions" / "public-notebook-candidates"
DEFAULT_CANDIDATES = sorted(path.parent for path in CANDIDATE_ROOT.glob("*/main.py"))


def run_game(candidate: Path, opponent: str, seed: int, seat: int) -> dict:
    command = [
        sys.executable,
        str(ARENA),
        str(candidate / "main.py"),
        "--opponent",
        opponent,
        "--seed",
        str(seed),
        "--seat",
        str(seat),
        "--steps",
        "720",
    ]
    completed = subprocess.run(command, text=True, capture_output=True, check=False)
    if completed.returncode != 0:
        return {
            "candidate": candidate.name,
            "opponent": opponent,
            "seed": seed,
            "seat": seat,
            "outcome": "error",
            "returncode": completed.returncode,
            "stderr_tail": completed.stderr[-2000:],
            "stdout_tail": completed.stdout[-2000:],
        }
    start = completed.stdout.rfind("\n{")
    payload = completed.stdout[start + 1 :] if start >= 0 else completed.stdout
    result = json.loads(payload)
    result["candidate"] = candidate.name
    return result


def summarize(results: list[dict]) -> list[dict]:
    rows = []
    for candidate in sorted({row["candidate"] for row in results}):
        games = [row for row in results if row["candidate"] == candidate]
        valid = [row for row in games if row["outcome"] != "error"]
        rows.append(
            {
                "candidate": candidate,
                "games": len(games),
                "valid_games": len(valid),
                "wins": sum(row["outcome"] == "win" for row in valid),
                "ties": sum(row["outcome"] == "tie" for row in valid),
                "losses": sum(row["outcome"] == "loss" for row in valid),
                "errors": sum(row["outcome"] == "error" for row in games),
                "mean_bank_difference": (
                    sum(row["candidate_reward"] - row["opponent_reward"] for row in valid) / len(valid)
                    if valid
                    else None
                ),
                "minimum_candidate_reward": min((row["candidate_reward"] for row in valid), default=None),
            }
        )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--opponent", default="starter")
    parser.add_argument("--seeds", default="7,21,42,84,168")
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument(
        "--candidates",
        help="Comma-separated candidate directory names (default: all extracted candidates)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "references" / "public-kernel-research" / "benchmark-v1.json",
    )
    args = parser.parse_args()
    seeds = [int(value) for value in args.seeds.split(",") if value.strip()]
    candidates = DEFAULT_CANDIDATES
    if args.candidates:
        requested = {value.strip() for value in args.candidates.split(",") if value.strip()}
        candidates = [candidate for candidate in DEFAULT_CANDIDATES if candidate.name in requested]
        missing = requested - {candidate.name for candidate in candidates}
        if missing:
            raise SystemExit(f"Unknown candidates: {', '.join(sorted(missing))}")
    jobs = [(candidate, args.opponent, seed, seat) for candidate in candidates for seed in seeds for seat in (0, 1)]

    results = []
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(run_game, *job): job for job in jobs}
        for future in as_completed(futures):
            result = future.result()
            results.append(result)
            print(result["candidate"], result["seed"], result["seat"], result["outcome"])

    results.sort(key=lambda row: (row["candidate"], row["seed"], row["seat"]))
    report = {
        "environment": "kaggle-environments==1.32.7",
        "opponent": args.opponent,
        "seeds": seeds,
        "side_swapped": True,
        "fresh_process_per_game": True,
        "summary": summarize(results),
        "games": results,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report["summary"], indent=2))
    print(args.output)


if __name__ == "__main__":
    main()
