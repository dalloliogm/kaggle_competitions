#!/usr/bin/env python3
"""Benchmark candidate agents against three challenger seats in 4P games."""

from __future__ import annotations

import json
import os
from collections import defaultdict
from pathlib import Path

os.environ.setdefault("LITELLM_LOCAL_MODEL_COST_MAP", "True")

from kaggle_environments import make


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "submissions" / "candidates"
CHALLENGER = (
    BASE / "meta-challenger-r-k-wave-complement" / "unpacked" / "main.py"
)
CANDIDATES = {
    "primary": BASE / "meta-primary-playercount-4p-fix" / "unpacked" / "main.py",
    "frontier": BASE / "meta-backup-frontier-shortlist" / "unpacked" / "main.py",
    "i-the-orbit": BASE / "i-the-orbit" / "main.py",
    "i-m-stronger": BASE / "i-m-stronger" / "main.py",
    "exp50": BASE / "exp50" / "main.py",
    "light-1200": BASE / "light-1200" / "main.py",
    "v2-gru": BASE / "v2-gru" / "main.py",
}
SEEDS = [401, 502, 603]
OUTPUT = ROOT / "submissions" / "benchmark-4p-candidates.json"


def main() -> None:
    games = []
    for name, candidate in CANDIDATES.items():
        for seed in SEEDS:
            for seat in range(4):
                agents = [str(CHALLENGER)] * 4
                agents[seat] = str(candidate)
                env = make("orbit_wars", configuration={"seed": seed}, debug=False)
                env.run(agents)
                final = env.steps[-1]
                games.append(
                    {
                        "candidate": name,
                        "seed": seed,
                        "seat": seat,
                        "steps": len(env.steps),
                        "candidate_reward": final[seat].reward,
                        "rewards": [state.reward for state in final],
                        "statuses": [state.status for state in final],
                    }
                )

    summary = defaultdict(lambda: {"games": 0, "wins": 0, "errors": 0})
    for game in games:
        row = summary[game["candidate"]]
        row["games"] += 1
        row["wins"] += game["candidate_reward"] == 1
        row["errors"] += game["statuses"][game["seat"]] != "DONE"

    payload = {"seeds": SEEDS, "summary": dict(summary), "games": games}
    OUTPUT.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload["summary"], indent=2))
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()
