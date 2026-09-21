#!/usr/bin/env python3
"""Final-week benchmark for June 22 Orbit Wars public candidates."""

from __future__ import annotations

import json
import os
from collections import defaultdict
from pathlib import Path

os.environ.setdefault("LITELLM_LOCAL_MODEL_COST_MAP", "True")

from kaggle_environments import make


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "submissions" / "candidates"
INCUMBENTS = {
    "primary": BASE / "meta-primary-playercount-4p-fix" / "unpacked" / "main.py",
    "challenger": (
        BASE / "meta-challenger-r-k-wave-complement" / "unpacked" / "main.py"
    ),
}
CANDIDATES = {
    "c2-frontier-flow": (
        BASE / "meta0622-challenger-c2-frontier-flow" / "unpacked" / "main.py"
    ),
    "c3-4p-retention": (
        BASE / "meta0622-challenger-c3-4p-retention" / "unpacked" / "main.py"
    ),
    "producer-anchor": (
        BASE / "meta0622-anchor-producer-wave-control" / "unpacked" / "main.py"
    ),
    "apex-hybrid": BASE / "apex-hybrid" / "main.py",
}
SEEDS = [701, 802]
OUTPUT = ROOT / "submissions" / "benchmark-0622-candidates.json"


def run(paths: list[Path], seed: int) -> list:
    env = make("orbit_wars", configuration={"seed": seed}, debug=False)
    env.run([str(path) for path in paths])
    return env.steps[-1]


def main() -> None:
    games = []
    for candidate_name, candidate in CANDIDATES.items():
        for incumbent_name, incumbent in INCUMBENTS.items():
            for seed in SEEDS:
                for seat in range(2):
                    paths = [incumbent, incumbent]
                    paths[seat] = candidate
                    final = run(paths, seed)
                    games.append(
                        {
                            "mode": "2P",
                            "candidate": candidate_name,
                            "opponent": incumbent_name,
                            "seed": seed,
                            "seat": seat,
                            "reward": final[seat].reward,
                            "status": final[seat].status,
                        }
                    )
                for seat in range(4):
                    paths = [incumbent] * 4
                    paths[seat] = candidate
                    final = run(paths, seed)
                    games.append(
                        {
                            "mode": "4P",
                            "candidate": candidate_name,
                            "opponent": incumbent_name,
                            "seed": seed,
                            "seat": seat,
                            "reward": final[seat].reward,
                            "status": final[seat].status,
                        }
                    )

    summary = defaultdict(lambda: {"games": 0, "wins": 0, "errors": 0})
    for game in games:
        key = f"{game['candidate']}|{game['mode']}|{game['opponent']}"
        row = summary[key]
        row["games"] += 1
        row["wins"] += game["reward"] == 1
        row["errors"] += game["status"] != "DONE"

    payload = {"seeds": SEEDS, "summary": dict(summary), "games": games}
    OUTPUT.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload["summary"], indent=2))
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()
