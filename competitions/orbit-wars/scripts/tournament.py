#!/usr/bin/env python3
"""Discriminating Orbit Wars tournament harness.

Binary win/loss saturates against weak opponents, so we also track survival
(elimination avoidance), elimination step, and final ship-share — the metrics
that actually separate candidates when the failure mode is being eliminated.

Config is a JSON file passed as argv[1]:
  {
    "candidates": {"name": "rel/path/to/main.py", ...},
    "opponents":  {"name": "rel/path/to/main.py", ...},
    "seeds": [911, 1012, 1113],
    "modes": [4],            # player counts to test
    "output": "submissions/tournament-XXX.json"
  }

For each (candidate, opponent, mode, seed, seat): candidate occupies `seat`,
all other seats are the opponent. Reports per (candidate,opponent,mode):
  games, wins, win_rate, eliminations, survival_rate,
  avg_elim_step (only over games where eliminated), avg_final_ship_share, errors.
"""

from __future__ import annotations

import json
import os
import sys
from collections import defaultdict
from pathlib import Path

os.environ.setdefault("LITELLM_LOCAL_MODEL_COST_MAP", "True")
# Keep torch single-ish so parallel tournament shards don't oversubscribe.
for v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ.setdefault(v, "2")

from kaggle_environments import make

ROOT = Path(__file__).resolve().parents[1]
SHIPS = 5  # planet field index for ship count
OWNER = 1


def _planets(step, seat):
    return step[seat]["observation"].get("planets", [])


def _candidate_metrics(env, seat, n_players):
    """Return dict of metrics.

    Distinguishes EARLY elimination (knocked to 0 planets while the game keeps
    going) from a normal end-of-game loss (only 0 at the final step). The
    survival metric we care about is avoiding EARLY elimination.
    """
    steps = env.steps
    n_steps = len(steps)
    last = n_steps - 1
    elim_step = None
    peak_planets = 0
    for t, step in enumerate(steps):
        mine = [p for p in _planets(step, seat) if int(p[OWNER]) == seat]
        peak_planets = max(peak_planets, len(mine))
        if len(mine) == 0 and t > 0 and peak_planets > 0 and elim_step is None:
            elim_step = t
    # Early elimination = lost all planets strictly before the final step.
    early_elim = elim_step is not None and elim_step < last
    # final ship share across planets (fleets ignored; planets dominate endgame)
    by_owner = defaultdict(int)
    for p in _planets(steps[last], seat):
        by_owner[int(p[OWNER])] += int(p[SHIPS])
    total = sum(v for o, v in by_owner.items() if o >= 0)
    mine_ships = by_owner.get(seat, 0)
    share = (mine_ships / total) if total > 0 else 0.0
    return {
        "early_elim": early_elim,
        "elim_step": elim_step,
        "n_steps": n_steps,
        "final_ships": mine_ships,
        "final_share": share,
        "survival_frac": round((elim_step if elim_step is not None else last) / last, 3),
    }


def main():
    cfg = json.loads(Path(sys.argv[1]).read_text())
    candidates = {k: ROOT / v for k, v in cfg["candidates"].items()}
    opponents = {k: ROOT / v for k, v in cfg["opponents"].items()}
    seeds = cfg.get("seeds", [911, 1012, 1113])
    modes = cfg.get("modes", [4])
    output = ROOT / cfg["output"]

    # "mixed" mode: fill non-candidate seats from a rotating pool of all
    # opponents (mirrors a real ladder lobby of assorted bots) instead of 3
    # identical copies. Enable with cfg["mixed"] = true.
    mixed = cfg.get("mixed", False)
    opp_items = list(opponents.items())

    def opponent_paths_for(mode, cand_seat):
        """Return (label, list-of-paths) for the non-candidate seats."""
        if not mixed:
            return None  # handled per-opponent below
        seats = []
        oi = 0
        for s in range(mode):
            if s == cand_seat:
                seats.append(None)
            else:
                seats.append(opp_items[oi % len(opp_items)])
                oi += 1
        return seats

    games = []

    def run_game(cand_name, cand_path, opp_label, paths, mode, seed, seat):
        print(f"{cand_name} vs {opp_label} {mode}P seed={seed} seat={seat}", flush=True)
        env = make("orbit_wars", configuration={"seed": seed}, debug=False)
        env.run(paths)
        final = env.steps[-1]
        m = _candidate_metrics(env, seat, mode)
        games.append({
            "candidate": cand_name, "opponent": opp_label, "mode": mode,
            "seed": seed, "seat": seat,
            "reward": final[seat].reward, "status": final[seat].status,
            "early_elim": m["early_elim"], "elim_step": m["elim_step"],
            "n_steps": m["n_steps"], "survival_frac": m["survival_frac"],
            "final_ships": m["final_ships"], "final_share": round(m["final_share"], 4),
        })

    for cand_name, cand_path in candidates.items():
        for mode in modes:
            for seed in seeds:
                for seat in range(mode):
                    if mixed:
                        seats = opponent_paths_for(mode, seat)
                        paths = []
                        for s in range(mode):
                            paths.append(str(cand_path) if s == seat else str(seats[s][1]))
                        run_game(cand_name, cand_path, "MIXED", paths, mode, seed, seat)
                    else:
                        for opp_name, opp_path in opp_items:
                            paths = [str(opp_path)] * mode
                            paths[seat] = str(cand_path)
                            run_game(cand_name, cand_path, opp_name, paths, mode, seed, seat)

    summary = {}
    keyed = defaultdict(list)
    for g in games:
        keyed[(g["candidate"], g["opponent"], g["mode"])].append(g)
    for (cand, opp, mode), gs in keyed.items():
        n = len(gs)
        wins = sum(1 for g in gs if g["reward"] == 1)
        elims = sum(1 for g in gs if g["early_elim"])
        elim_steps = [g["elim_step"] for g in gs if g["early_elim"] and g["elim_step"]]
        errs = sum(1 for g in gs if g["status"] != "DONE")
        summary[f"{cand}|{mode}P|{opp}"] = {
            "games": n,
            "wins": wins,
            "win_rate": round(wins / n, 3),
            "early_eliminations": elims,
            "survival_rate": round(1 - elims / n, 3),
            "avg_survival_frac": round(sum(g["survival_frac"] for g in gs) / n, 3),
            "avg_elim_step": round(sum(elim_steps) / len(elim_steps), 1) if elim_steps else None,
            "avg_final_share": round(sum(g["final_share"] for g in gs) / n, 4),
            "errors": errs,
        }

    # Per-candidate aggregate across all opponents/modes
    agg = defaultdict(lambda: {"games": 0, "wins": 0, "elims": 0,
                               "share_sum": 0.0, "surv_sum": 0.0, "errors": 0})
    for g in games:
        a = agg[g["candidate"]]
        a["games"] += 1
        a["wins"] += g["reward"] == 1
        a["elims"] += g["early_elim"]
        a["share_sum"] += g["final_share"]
        a["surv_sum"] += g["survival_frac"]
        a["errors"] += g["status"] != "DONE"
    aggregate = {}
    for cand, a in agg.items():
        n = a["games"]
        aggregate[cand] = {
            "games": n,
            "win_rate": round(a["wins"] / n, 3),
            "survival_rate": round(1 - a["elims"] / n, 3),
            "avg_survival_frac": round(a["surv_sum"] / n, 3),
            "avg_final_share": round(a["share_sum"] / n, 4),
            "errors": a["errors"],
        }

    payload = {"config": cfg, "summary": summary, "aggregate": aggregate, "games": games}
    output.write_text(json.dumps(payload, indent=2) + "\n")
    print("\n=== AGGREGATE (across all opponents) ===")
    for cand, a in sorted(aggregate.items(), key=lambda kv: (-kv[1]["win_rate"], -kv[1]["avg_survival_frac"])):
        print(f"  {cand:32} win={a['win_rate']:.2f} survive={a['survival_rate']:.2f} "
              f"surv_frac={a['avg_survival_frac']:.2f} share={a['avg_final_share']:.3f} err={a['errors']}")
    print(f"\nWrote {output}")


if __name__ == "__main__":
    main()
