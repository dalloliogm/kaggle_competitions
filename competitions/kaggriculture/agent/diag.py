"""Per-day accounting of where unit-turns go and what the herd's state is."""
import collections, json, os, sys
sys.path.insert(0, ".")
from kaggle_environments import make
import main

cfg = json.loads(os.environ.get("KAG_PARAMS", "{}"))
main.PARAMS.update(cfg)
seed = int(sys.argv[1]) if len(sys.argv) > 1 else 3
opp = sys.argv[2] if len(sys.argv) > 2 else "starter"

per_day = collections.defaultdict(collections.Counter)
state = {}

def f(obs, c=None):
    a = main._plan(obs)
    d = obs["day"]
    acts = [a["farmer"]] + list(a["hands"])
    for act in acts:
        op = act[0]
        per_day[d]["MOVE" if op in ("NORTH","SOUTH","EAST","WEST") else op] += 1
    me = obs["farms"][obs["player"]]
    animals = [t for row in me["tiles"] for t in row if isinstance(t, dict) and "animal" in t]
    plants = [t for row in me["tiles"] for t in row if isinstance(t, dict) and t.get("kind") == "PLANT"]
    state[d] = {
        "animals": len(animals),
        "unfed": sum(1 for t in animals if not t["fed_today"]),
        "uncared": sum(1 for t in animals if not t["cared_today"]),
        "starving": sum(1 for t in animals if t.get("consecutive_unfed", 0) >= 1),
        "plants": len(plants),
        "wheat": obs["private"]["shed"].get("WHEAT", 0),
        "money": int(me["money"]),
        "hands": len(me["hands"]),
    }
    return a

env = make("kaggriculture", configuration={"episodeSteps": 720, "seed": seed})
env.run([f, opp])
print("reward", env.steps[-1][0]["reward"])
print(f"{'day':>3} {'anim':>4} {'unfed':>5} {'starv':>5} {'plants':>6} {'wheat':>5} {'money':>7} {'hands':>5} | "
      f"{'MOVE':>5} {'PASS':>5} {'FEED':>5} {'CARE':>5} {'HARV':>5} {'WATER':>5} {'PLANT':>5} {'PICK':>5}")
for d in sorted(per_day):
    if d % 4 and d != 29:
        continue
    c, s = per_day[d], state.get(d, {})
    tot = sum(c.values()) or 1
    print(f"{d:>3} {s.get('animals',0):>4} {s.get('unfed',0):>5} {s.get('starving',0):>5} "
          f"{s.get('plants',0):>6} {s.get('wheat',0):>5} {s.get('money',0):>7} {s.get('hands',0):>5} | "
          f"{100*c['MOVE']//tot:>4}% {100*c['PASS']//tot:>4}% {c['FEED']:>5} {c['CARE']:>5} "
          f"{c['HARVEST']:>5} {c['WATER']:>5} {c['PLANT']:>5} {c['PICKUP']:>5}")
