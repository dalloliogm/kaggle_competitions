#!/usr/bin/env python3
"""Run a small seeded tournament across selected Orbit Wars candidates."""

from __future__ import annotations

import itertools
import json
import os
from collections import defaultdict
from pathlib import Path

os.environ.setdefault("LITELLM_LOCAL_MODEL_COST_MAP", "True")

from kaggle_environments import make


ROOT = Path(__file__).resolve().parents[1]
CANDIDATES = ROOT / "submissions" / "candidates"
RESULTS = ROOT / "submissions" / "local-benchmark.json"

AGENTS = {
    "primary": CANDIDATES
    / "meta-primary-playercount-4p-fix"
    / "unpacked"
    / "main.py",
    "challenger": CANDIDATES
    / "meta-challenger-r-k-wave-complement"
    / "unpacked"
    / "main.py",
    "v8": CANDIDATES / "v8-1250" / "main.py",
    "frontier": CANDIDATES
    / "meta-backup-frontier-shortlist"
    / "unpacked"
    / "main.py",
}
SEEDS = [101, 202, 303]


def run_game(names: list[str], seed: int) -> dict:
    env = make("orbit_wars", configuration={"seed": seed}, debug=False)
    env.run([str(AGENTS[name]) for name in names])
    final = env.steps[-1]
    return {
        "seed": env.info.get("seed", seed),
        "agents": names,
        "rewards": [state.reward for state in final],
        "statuses": [state.status for state in final],
        "steps": len(env.steps),
    }


def main() -> None:
    games = []
    names = list(AGENTS)

    for left, right in itertools.combinations(names, 2):
        for seed in SEEDS:
            games.append(run_game([left, right], seed))
            games.append(run_game([right, left], seed))

    for seed in SEEDS:
        for offset in range(len(names)):
            lineup = names[offset:] + names[:offset]
            games.append(run_game(lineup, seed))

    summary = defaultdict(
        lambda: {
            "games": 0,
            "wins": 0,
            "ties": 0,
            "losses": 0,
            "errors": 0,
            "reward_sum": 0.0,
        }
    )
    for game in games:
        for name, reward, status in zip(
            game["agents"], game["rewards"], game["statuses"], strict=True
        ):
            row = summary[name]
            row["games"] += 1
            row["reward_sum"] += float(reward or 0)
            if status != "DONE":
                row["errors"] += 1
            if reward == 1:
                row["wins"] += 1
            elif reward == 0:
                row["ties"] += 1
            else:
                row["losses"] += 1

    payload = {"seeds": SEEDS, "summary": dict(summary), "games": games}
    RESULTS.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload["summary"], indent=2))
    print(f"Wrote {RESULTS}")


if __name__ == "__main__":
    main()
