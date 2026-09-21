#!/usr/bin/env python3
"""Summarize downloaded Orbit Wars ladder replays."""

from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPLAYS = ROOT / "submissions" / "replays"
OUTPUT = ROOT / "submissions" / "ladder-analysis.json"
OUR_NAME = "Giovanni Marco Dall'Olio"


def total_ships(state: dict, player: int) -> int:
    obs = state["observation"]
    planet_ships = sum(p[5] for p in obs["planets"] if p[1] == player)
    fleet_ships = sum(f[6] for f in obs["fleets"] if f[1] == player)
    return int(planet_ships + fleet_ships)


def production(state: dict, player: int) -> int:
    return int(
        sum(p[6] for p in state["observation"]["planets"] if p[1] == player)
    )


def analyze(path: Path, role: str) -> dict:
    replay = json.loads(path.read_text())
    names = replay["info"]["TeamNames"]
    our_index = names.index(OUR_NAME)
    final = replay["steps"][-1]
    ours = final[our_index]
    opponent_indices = [index for index in range(len(final)) if index != our_index]
    final_totals = [total_ships(state, index) for index, state in enumerate(final)]
    final_production = [production(state, index) for index, state in enumerate(final)]
    return {
        "episode": replay["info"]["EpisodeId"],
        "role": role,
        "players": len(final),
        "seat": our_index,
        "seed": replay["info"]["seed"],
        "steps": len(replay["steps"]),
        "reward": ours["reward"],
        "status": ours["status"],
        "our_ships": final_totals[our_index],
        "best_opponent_ships": max(final_totals[index] for index in opponent_indices),
        "our_production": final_production[our_index],
        "best_opponent_production": max(
            final_production[index] for index in opponent_indices
        ),
        "our_planets": sum(
            1 for p in ours["observation"]["planets"] if p[1] == our_index
        ),
        "opponents": [names[index] for index in opponent_indices],
        "remaining_overage": ours["observation"].get("remainingOverageTime"),
    }


def aggregate(games: list[dict]) -> dict:
    result = {}
    for role in sorted({game["role"] for game in games}):
        role_games = [game for game in games if game["role"] == role]
        by_players = {}
        for players in (2, 4):
            subset = [game for game in role_games if game["players"] == players]
            if not subset:
                continue
            by_players[str(players)] = {
                "games": len(subset),
                "wins": sum(game["reward"] == 1 for game in subset),
                "losses": sum(game["reward"] != 1 for game in subset),
                "avg_ship_margin": sum(
                    game["our_ships"] - game["best_opponent_ships"] for game in subset
                )
                / len(subset),
                "avg_production_margin": sum(
                    game["our_production"] - game["best_opponent_production"]
                    for game in subset
                )
                / len(subset),
                "seats": dict(Counter(str(game["seat"]) for game in subset)),
            }
        result[role] = {
            "games": len(role_games),
            "wins": sum(game["reward"] == 1 for game in role_games),
            "losses": sum(game["reward"] != 1 for game in role_games),
            "by_players": by_players,
        }
    return result


def main() -> None:
    games = []
    for role in (
        "primary",
        "challenger",
        "producer-anchor",
        "i-m-stronger",
    ):
        for path in sorted((REPLAYS / f"{role}-public").glob("*.json")):
            games.append(analyze(path, role))
    payload = {"summary": aggregate(games), "games": games}
    OUTPUT.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload["summary"], indent=2))
    print("\nLosses:")
    for game in games:
        if game["reward"] != 1:
            print(
                game["role"],
                game["episode"],
                f"{game['players']}P",
                f"seat={game['seat']}",
                f"steps={game['steps']}",
                f"ships={game['our_ships']}:{game['best_opponent_ships']}",
                f"prod={game['our_production']}:{game['best_opponent_production']}",
                ",".join(game["opponents"]),
            )


if __name__ == "__main__":
    main()
