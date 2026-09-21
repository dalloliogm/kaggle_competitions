#!/usr/bin/env python3
"""Compact analysis helpers for Orbit Wars replay JSONs.

Replay structure (kaggle_environments):
  data['steps'][t]            -> list of per-seat dicts (one per player)
  data['steps'][t][seat]      -> {'action', 'info', 'observation', 'reward', 'status'}
  observation['planets']      -> [[id, owner, x, y, angular_velocity, ships, prod], ...]
                                 owner: -1 neutral, else player seat index
  observation['fleets']       -> in-flight fleets (varies); each typically
                                 [id, owner, ...kinematics..., ships, ...]
  observation['player']       -> the seat this observation belongs to
  data['info']['Agents'/'TeamNames'] -> opponent identities
  data['rewards']             -> final reward per seat (1 win / -1 loss / 0)

Planet field indices:
  PID=0, OWNER=1, X=2, Y=3, AVEL=4, SHIPS=5, PROD=6

Usage:
  python replay_tools.py timeline <replay.json> <seat> [--every N]
  python replay_tools.py summary  <replay.json>
  python replay_tools.py actions  <replay.json> <seat> [--max-step N]
  python replay_tools.py fleets   <replay.json> <seat> [--every N]
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

PID, OWNER, X, Y, AVEL, SHIPS, PROD = range(7)


def load(path):
    with open(path) as f:
        return json.load(f)


def _planets(step, seat):
    return step[seat]["observation"].get("planets", [])


def _fleets(step, seat):
    return step[seat]["observation"].get("fleets", [])


def _owner_stats(planets):
    """Return {owner: {'planets': n, 'ships': s, 'prod': p}}."""
    out = {}
    for pl in planets:
        o = int(pl[OWNER])
        d = out.setdefault(o, {"planets": 0, "ships": 0, "prod": 0})
        d["planets"] += 1
        d["ships"] += int(pl[SHIPS])
        d["prod"] += int(pl[PROD])
    return out


def _fleet_ships_by_owner(fleets):
    """Sum ships in flight per owner. Fleet layout varies; ships is the last
    large int-ish field — we use a heuristic: owner is field 1, ships is the
    max integer value among remaining fields (robust to layout drift)."""
    out = {}
    for fl in fleets:
        if len(fl) < 3:
            continue
        owner = int(fl[1])
        # ships heuristic: largest plausible integer in the row after kinematics
        ints = [v for v in fl[2:] if isinstance(v, (int, float)) and float(v).is_integer()]
        ships = int(max(ints)) if ints else 0
        out[owner] = out.get(owner, 0) + ships
    return out


def cmd_summary(path):
    data = load(path)
    steps = data["steps"]
    n_players = len(steps[0])
    info = data.get("info", {})
    rewards = data.get("rewards", [])
    agents = info.get("Agents") or info.get("TeamNames") or []
    print(f"file: {Path(path).name}")
    print(f"players: {n_players}  steps: {len(steps)}  seed: {info.get('seed')}")
    print(f"agents: {agents}")
    print(f"final_rewards: {rewards}")
    # Per-seat trajectory of planet count + total ships (planets only)
    print("\nseat | result | peak_planets | elim_step | final_planets | final_ships")
    for seat in range(n_players):
        counts = []
        ships_series = []
        for step in steps:
            st = _owner_stats(_planets(step, seat))
            counts.append(st.get(seat, {}).get("planets", 0))
            ships_series.append(st.get(seat, {}).get("ships", 0))
        peak = max(counts)
        elim = next((i for i, c in enumerate(counts) if c == 0 and i > 0 and peak > 0), None)
        result = "?"
        if seat < len(rewards):
            r = rewards[seat]
            result = "WIN" if r == 1 else ("LOSS" if r == -1 else f"{r}")
        print(f"  {seat}  | {result:5} | {peak:4} | {str(elim):>5} | {counts[-1]:4} | {ships_series[-1]:6}")


def cmd_timeline(path, seat, every=10):
    data = load(path)
    steps = data["steps"]
    n_players = len(steps[0])
    print(f"# Timeline seat={seat} (every {every} steps)  file={Path(path).name}")
    print("step | " + " | ".join(f"P{p}(pl/shp/prd)" for p in range(n_players)) + " | neutral_pl")
    for t in range(0, len(steps), every):
        st = _owner_stats(_planets(steps[t], seat))
        cells = []
        for p in range(n_players):
            d = st.get(p, {})
            cells.append(f"{d.get('planets',0):2}/{d.get('ships',0):5}/{d.get('prod',0):3}")
        neutral = st.get(-1, {}).get("planets", 0)
        marker = "  <-- US" if False else ""
        print(f"{t:4} | " + " | ".join(cells) + f" | {neutral:2}")
    # always print last step
    t = len(steps) - 1
    st = _owner_stats(_planets(steps[t], seat))
    cells = []
    for p in range(n_players):
        d = st.get(p, {})
        cells.append(f"{d.get('planets',0):2}/{d.get('ships',0):5}/{d.get('prod',0):3}")
    print(f"{t:4} | " + " | ".join(cells) + f" | {st.get(-1, {}).get('planets',0):2}  [FINAL]")


def cmd_fleets(path, seat, every=10):
    data = load(path)
    steps = data["steps"]
    n_players = len(steps[0])
    print(f"# In-flight fleet ships per owner, seat={seat} (every {every})")
    print("step | " + " | ".join(f"P{p}_inflight" for p in range(n_players)))
    for t in range(0, len(steps), every):
        fb = _fleet_ships_by_owner(_fleets(steps[t], seat))
        cells = [f"{fb.get(p,0):6}" for p in range(n_players)]
        print(f"{t:4} | " + " | ".join(cells))


def cmd_actions(path, seat, max_step=None):
    """Show the moves this seat issued each step: [from, angle, ships]."""
    data = load(path)
    steps = data["steps"]
    limit = max_step if max_step is not None else len(steps)
    print(f"# Actions issued by seat={seat}  file={Path(path).name}")
    print("step | action (from_planet, angle, ships) | own_planets | own_ships")
    for t in range(min(limit, len(steps))):
        action = steps[t][seat].get("action")
        st = _owner_stats(_planets(steps[t], seat)).get(seat, {})
        print(f"{t:4} | {action} | {st.get('planets',0)} | {st.get('ships',0)}")


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 1
    cmd = argv[1]

    def opt(name, default):
        if name in argv:
            return int(argv[argv.index(name) + 1])
        return default

    if cmd == "summary":
        cmd_summary(argv[2])
    elif cmd == "timeline":
        cmd_timeline(argv[2], int(argv[3]), every=opt("--every", 10))
    elif cmd == "fleets":
        cmd_fleets(argv[2], int(argv[3]), every=opt("--every", 10))
    elif cmd == "actions":
        cmd_actions(argv[2], int(argv[3]), max_step=opt("--max-step", None) if "--max-step" in argv else None)
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
