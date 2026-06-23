#!/usr/bin/env python3
"""Benchmark Option 2 (horizon24) vs Option 1 (conservative) in 4P only."""

from __future__ import annotations

import json
import os
from collections import defaultdict
from pathlib import Path

os.environ.setdefault("LITELLM_LOCAL_MODEL_COST_MAP", "True")

from kaggle_environments import make


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "submissions" / "candidates"

OPTION1 = BASE / "producer-anchor-conservative-4p" / "main.py"
OPTION2 = BASE / "producer-anchor-horizon24" / "main.py"

OPPONENTS = {
    "current-anchor": (
        BASE / "meta0622-anchor-producer-wave-control" / "unpacked" / "main.py"
    ),
}

SEEDS = [911, 1012, 1113]
OUTPUT = ROOT / "submissions" / "benchmark-option2-vs-option1.json"


def main() -> None:
    games = []
    players = 4

    # Test both options in 4P
    for option_name, option_path in [("option1-conservative", OPTION1), ("option2-horizon24", OPTION2)]:
        for opponent_name, opponent in OPPONENTS.items():
            for seed in SEEDS:
                for seat in range(players):
                    paths = [opponent] * players
                    paths[seat] = option_path

                    print(f"Running {option_name} vs {opponent_name} 4P seed={seed} seat={seat}...")
                    env = make(
                        "orbit_wars", configuration={"seed": seed}, debug=False
                    )
                    env.run([str(path) for path in paths])
                    final = env.steps[-1]
                    games.append(
                        {
                            "variant": option_name,
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
        key = f"{game['variant']}|4P|{game['opponent']}"
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
