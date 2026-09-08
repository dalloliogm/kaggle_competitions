"""Run a short episode with the agent called directly so exceptions surface.

kaggle-environments swallows agent errors and substitutes a default action, which
makes a crashed agent look like a very passive one.
"""

import sys

from kaggle_environments import make

sys.path.insert(0, ".")
import main  # noqa: E402


def loud(obs, config=None):
    return main.agent(obs)


def main_():
    steps = int(sys.argv[1]) if len(sys.argv) > 1 else 720
    env = make("kaggriculture", configuration={"episodeSteps": steps, "seed": 3})
    env.run([loud, "starter"])
    print("rewards", [s["reward"] for s in env.steps[-1]],
          "statuses", [s["status"] for s in env.steps[-1]])


if __name__ == "__main__":
    main_()
