"""Run an episode and print a per-day trace of one player's farm."""

import sys

from kaggle_environments import make


def main():
    a0 = sys.argv[1] if len(sys.argv) > 1 else "main.py"
    a1 = sys.argv[2] if len(sys.argv) > 2 else "starter"
    seed = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    days = [int(d) for d in (sys.argv[4].split(",") if len(sys.argv) > 4 else "1,3,6,10,15,20,29".split(","))]
    env = make("kaggriculture", configuration={"episodeSteps": 720, "seed": seed})
    env.run([a0, a1])
    for d in days:
        idx = min(len(env.steps) - 1, d * 24 + 23)
        st = env.steps[idx]
        obs = st[0]["observation"]
        farm = obs["farms"][0]
        priv = st[0]["observation"]["private"]
        counts = {}
        for row in farm["tiles"]:
            for t in row:
                if t is None:
                    k = "empty"
                elif t == "LOCKED":
                    k = "locked"
                elif t.get("kind") == "PLANT":
                    k = t["crop"]
                elif "animal" in t:
                    k = t["animal"]
                else:
                    k = t.get("kind")
                counts[k] = counts.get(k, 0) + 1
        print(f"day {d:2d} money={farm['money']:9.0f} hands={len(farm['hands'])} "
              f"quads={farm['unlocked_quadrants']} tiles={counts}")
        print(f"        shed={{k:v for k,v in ...}}".replace("{k:v for k,v in ...}",
              str({k: v for k, v in priv["shed"].items() if v}))
              + f" seeds={ {k: v for k, v in priv['seeds'].items() if v} }")
        print("        prices=" + str(obs["market"]["prices"]))
    final = env.steps[-1]
    print("FINAL", [s["reward"] for s in final])


if __name__ == "__main__":
    main()
