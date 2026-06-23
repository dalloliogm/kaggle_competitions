#!/usr/bin/env python3
"""Benchmark conservative producer-anchor against current variant in 4P."""

from __future__ import annotations

import json
import os
from collections import defaultdict
from pathlib import Path

os.environ.setdefault("LITELLM_LOCAL_MODEL_COST_MAP", "True")

from kaggle_environments import make


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "submissions" / "candidates"

# The variant we're testing
CONSERVATIVE = BASE / "producer-anchor-conservative-4p" / "main.py"

# Opponents to test against
OPPONENTS = {
    "current-anchor": (
        BASE / "meta0622-anchor-producer-wave-control" / "unpacked" / "main.py"
    ),
    "primary": BASE / "meta-primary-playercount-4p-fix" / "unpacked" / "main.py",
    "i-m-stronger": BASE / "i-m-stronger" / "main.py",
}

SEEDS = [911, 1012, 1113]
OUTPUT = ROOT / "submissions" / "benchmark-conservative-4p.json"


def main() -> None:
    games = []

    # 4P games only (conservative is for 4P improvement)
    players = 4

    for opponent_name, opponent in OPPONENTS.items():
        for seed in SEEDS:
            for seat in range(players):
                paths = [opponent] * players
                paths[seat] = CONSERVATIVE

                print(f"Running {opponent_name} vs conservative seed={seed} seat={seat}...")
                env = make("orbit_wars", configuration={"seed": seed}, debug=False)
                env.run([str(path) for path in paths])
                final = env.steps[-1]
                games.append(
                    {
                        "opponent": opponent_name,
                        "players": players,
                        "seed": seed,
                        "seat": seat,
                        "reward": final[seat].reward,
                        "status": final[seat].status,
                    }
                )

    summary = defaultdict(lambda: {"games": 0, "wins": 0, "errors": 0})
    for game in games:
        key = f"conservative|4P|{game['opponent']}"
        row = summary[key]
        row["games"] += 1
        row["wins"] += game["reward"] == 1
        row["errors"] += game["status"] != "DONE"

    payload = {"seeds": SEEDS, "summary": dict(summary), "games": games}
    OUTPUT.write_text(json.dumps(payload, indent=2) + "\n")
    print("\n" + json.dumps(payload["summary"], indent=2))
    print(f"\nWrote {OUTPUT}")


if __name__ == "__main__":
    main()
