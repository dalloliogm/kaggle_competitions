#!/usr/bin/env python3
"""Run one Kaggriculture candidate matchup in a fresh Python process."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from kaggle_environments import make


OFFICIAL_CONFIGURATION = {
    "episodeSteps": 720,
    "boardSize": 10,
    "startingMoney": 3000,
    "maxMarketOrdersPerTurn": 10,
    "turnsPerDay": 24,
    "shedCapacity": 100,
    "weedSpawnChance": 0.005,
    "townShopUnlockInterval": 3,
    "townShopSellInterval": 4,
    "townCenterSellInterval": 24,
    "farmHandCostMult": 1,
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--opponent", default="starter")
    parser.add_argument("--seed", type=int, default=21)
    parser.add_argument("--seat", type=int, choices=(0, 1), default=0)
    parser.add_argument("--steps", type=int, default=720)
    args = parser.parse_args()

    candidate = str(args.candidate.resolve())
    configuration = dict(OFFICIAL_CONFIGURATION)
    configuration["episodeSteps"] = args.steps
    configuration["seed"] = args.seed
    agents = [candidate, args.opponent]
    if args.seat == 1:
        agents.reverse()

    env = make("kaggriculture", configuration=configuration, debug=True)
    env.run(agents)
    final = env.steps[-1]
    candidate_state = final[args.seat]
    opponent_state = final[1 - args.seat]
    result = {
        "candidate": candidate,
        "opponent": args.opponent,
        "seed": args.seed,
        "seat": args.seat,
        "steps": args.steps,
        "candidate_reward": candidate_state.reward,
        "opponent_reward": opponent_state.reward,
        "candidate_status": candidate_state.status,
        "opponent_status": opponent_state.status,
    }
    if candidate_state.reward > opponent_state.reward:
        result["outcome"] = "win"
    elif candidate_state.reward < opponent_state.reward:
        result["outcome"] = "loss"
    else:
        result["outcome"] = "tie"
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
