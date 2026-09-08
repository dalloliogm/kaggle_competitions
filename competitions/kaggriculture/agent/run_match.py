"""Run one Kaggriculture episode in this process and print the final money.

Usage: run_match.py <agent0> <agent1> <seed>
Each agent is either a builtin name (pass/random/starter) or a path to a .py file.
Run one match per process: agents that share module names would otherwise
collide in sys.modules.
"""

import json
import sys

from kaggle_environments import make


def main():
    a0, a1, seed = sys.argv[1], sys.argv[2], int(sys.argv[3])
    env = make("kaggriculture", configuration={"episodeSteps": 720, "seed": seed})
    env.run([a0, a1])
    final = env.steps[-1]
    rewards = [s["reward"] for s in final]
    out = {"seed": seed, "rewards": rewards,
           "statuses": [s["status"] for s in final]}
    obs = final[0]["observation"]
    out["market_inventory"] = obs["market"]["inventory"]
    out["shops"] = obs["town"]["unlocked_shops"]
    print("RESULT " + json.dumps(out))


if __name__ == "__main__":
    main()
