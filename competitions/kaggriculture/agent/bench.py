"""Benchmark agent variants over several seeds, one episode per process.

Each match runs in its own subprocess: agents that share module names (or module
level state) contaminate each other inside a single interpreter, which silently
makes every variant look identical.

Usage:
  bench.py --a main.py --b starter --seeds 1,2,3,4,5,6 [--params-a '{"max_geese":30}']
"""

import argparse
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))


def run_one(args):
    a, b, seed, params_a, params_b, swap = args
    if swap:
        a, b = b, a
        params_a, params_b = params_b, params_a
    env = dict(os.environ)
    # Both sides read KAG_PARAMS, so a variant match needs the two agents in
    # separate processes anyway; pass the side-specific overrides by file.
    env["KAG_PARAMS"] = params_a or "{}"
    env["KAG_PARAMS_B"] = params_b or "{}"
    cmd = [sys.executable, os.path.join(HERE, "run_match.py"), a, b, str(seed)]
    out = subprocess.run(cmd, capture_output=True, text=True, env=env, cwd=HERE, timeout=1800)
    for line in out.stdout.splitlines():
        if line.startswith("RESULT "):
            res = json.loads(line[7:])
            r = res["rewards"]
            if swap:
                r = [r[1], r[0]]
            return {"seed": seed, "swap": swap, "a": r[0], "b": r[1]}
    return {"seed": seed, "swap": swap, "a": None, "b": None,
            "err": (out.stderr or out.stdout)[-400:]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--a", default="main.py")
    ap.add_argument("--b", default="starter")
    ap.add_argument("--seeds", default="1,2,3,4")
    ap.add_argument("--params-a", default="{}")
    ap.add_argument("--params-b", default="{}")
    ap.add_argument("--both-sides", action="store_true")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--label", default="")
    args = ap.parse_args()

    seeds = [int(s) for s in args.seeds.split(",")]
    tasks = [(args.a, args.b, s, args.params_a, args.params_b, False) for s in seeds]
    if args.both_sides:
        tasks += [(args.a, args.b, s, args.params_a, args.params_b, True) for s in seeds]

    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        results = list(ex.map(run_one, tasks))

    ok = [r for r in results if r["a"] is not None]
    for r in results:
        if r["a"] is None:
            print("FAILED seed", r["seed"], r.get("err"))
    if not ok:
        return
    a_scores = sorted(r["a"] for r in ok)
    b_scores = sorted(r["b"] for r in ok)
    wins = sum(1 for r in ok if r["a"] > r["b"])
    n = len(ok)
    print(f"{args.label or args.a} vs {args.b}: n={n} wins={wins} ({wins / n:.0%})")
    print(f"  A mean={sum(a_scores) / n:9.0f} median={a_scores[n // 2]:9.0f} "
          f"min={a_scores[0]:9.0f} max={a_scores[-1]:9.0f}")
    print(f"  B mean={sum(b_scores) / n:9.0f} median={b_scores[n // 2]:9.0f}")
    print("  per-seed A: " + " ".join(f"{r['seed']}{'R' if r['swap'] else ''}:{r['a']:.0f}" for r in ok))


if __name__ == "__main__":
    main()
