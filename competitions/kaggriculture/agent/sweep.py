"""Sweep one parameter (or a set of overrides) and report mean final money."""

import argparse
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))


def run_one(task):
    agent_a, agent_b, seed, params = task
    env = dict(os.environ)
    env["KAG_PARAMS"] = json.dumps(params)
    cmd = [sys.executable, os.path.join(HERE, "run_match.py"), agent_a, agent_b, str(seed)]
    out = subprocess.run(cmd, capture_output=True, text=True, env=env, cwd=HERE, timeout=1800)
    for line in out.stdout.splitlines():
        if line.startswith("RESULT "):
            return json.loads(line[7:])["rewards"]
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--a", default="main.py")
    ap.add_argument("--b", default="starter")
    ap.add_argument("--seeds", default="1,2,3,4,5,6")
    ap.add_argument("--variants", required=True,
                    help='JSON list of {"label":..., "params": {...}}')
    ap.add_argument("--jobs", type=int, default=8)
    args = ap.parse_args()

    seeds = [int(s) for s in args.seeds.split(",")]
    variants = json.loads(args.variants)
    tasks, index = [], []
    for vi, v in enumerate(variants):
        for s in seeds:
            tasks.append((args.a, args.b, s, v.get("params", {})))
            index.append(vi)

    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        results = list(ex.map(run_one, tasks))

    for vi, v in enumerate(variants):
        rows = [r for i, r in zip(index, results) if i == vi and r]
        if not rows:
            print(f"{v['label']:28s} FAILED")
            continue
        mine = sorted(r[0] for r in rows)
        wins = sum(1 for r in rows if r[0] > r[1])
        n = len(mine)
        print(f"{v['label']:28s} mean={sum(mine) / n:8.0f} median={mine[n // 2]:8.0f} "
              f"min={mine[0]:8.0f} max={mine[-1]:8.0f} wins={wins}/{n}")


if __name__ == "__main__":
    main()
