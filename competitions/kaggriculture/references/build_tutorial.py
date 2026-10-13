#!/usr/bin/env python3
"""Build the competition-specific Kaggriculture tutorial notebook."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "notebooks" / "kaggriculture-competition-tutorial.ipynb"


def markdown(source: str) -> dict:
    return {"cell_type": "markdown", "metadata": {}, "source": source.splitlines(keepends=True)}


def code(source: str) -> dict:
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": source.splitlines(keepends=True),
    }


cells = [
    markdown(
        """# Kaggriculture: build and validate your first farming agent

**Audience:** Python users starting the Kaggriculture simulation competition.

**Prerequisites:** basic Python functions and dictionaries. The synthetic sections use only the standard library. The optional arena section needs a Kaggle Environments release that matches the live competition.

**Learning goals:** by the end you can explain the agent interface, produce a legal deterministic action, understand why win rate matters more than coin margin, validate an artifact, and plan a leakage-safe local arena.
"""
    ),
    markdown(
        """## Outline

1. Understand the game and evaluation
2. Inspect crop economics without competition data
3. Validate the action schema
4. Build a minimal carrot-loop agent
5. Design a trustworthy arena
6. Run the optional official environment smoke test
7. Exercise and next steps
"""
    ),
    code(
        """from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import importlib.util
import math
import random
import statistics

SEED = 21
random.seed(SEED)
SEED
"""
    ),
    markdown(
        """## 1. What is being optimized?

Two agents independently manage farms for 720 turns (30 days × 24 turns). The player with more **banked coins** at the end wins; unsold items do not count.

Kaggle converts win/loss/tie episode results into a ladder skill rating and runs a final Bradley–Terry tournament. Coin margin is strategically useful, but it does not directly change the rating update. Compare agents with many full episodes, swap seats, and keep results grouped by seed. There is no private leaderboard in this simulation competition.
"""
    ),
    markdown(
        """## 2. A transparent economics check

The table below is a deliberately simple static-price calculation. It helps check intuition, but it is **not** a faithful profit forecast: travel, watering, hiring, market impact, town demand, fertilizer, decay, and end-of-season timing all matter.
"""
    ),
    code(
        """@dataclass(frozen=True)
class Crop:
    seed_cost: int
    base_price: int
    first_yield_day: int
    peak_day: int
    peak_units: int


CROPS = {
    "WHEAT": Crop(10, 25, 2, 4, 6),
    "CARROT": Crop(20, 35, 2, 3, 4),
    "TOMATO": Crop(50, 60, 8, 11, 4),
    "STRAWBERRY": Crop(100, 120, 10, 16, 4),
    "MELON": Crop(80, 250, 10, 10, 6),
}

economics = []
for name, crop in CROPS.items():
    gross = crop.base_price * crop.peak_units
    economics.append({
        "crop": name,
        "days_to_peak": crop.peak_day,
        "static_gross": gross,
        "static_net_before_actions": gross - crop.seed_cost,
    })

sorted(economics, key=lambda row: row["static_net_before_actions"], reverse=True)
"""
    ),
    markdown(
        """A common proxy mistake is to choose the crop with the largest static net value. Premium products can collapse to the $1 price floor when supply is high, and a long maturation time may leave no time to sell. A useful policy estimates value **at the expected sale turn**, including actions and inventory capacity.
"""
    ),
    markdown(
        """## 3. Agent and action schema

Kaggle imports a top-level `agent(obs)` function. Each turn it must return an action dictionary with a farmer action, one action per hired hand, and an ordered list of up to ten market orders. Invalid actions silently become no-ops, so a schema check catches many expensive bugs before submission.
"""
    ),
    code(
        """FARMER_OPS = {
    "NORTH", "SOUTH", "EAST", "WEST", "PASS", "PICKUP", "DROP", "PLACE",
    "PLANT", "WATER", "HARVEST", "FERTILIZE", "FEED", "COLLECT_FERTILIZER",
    "CARE", "BUILD_COOP", "BUILD_PASTURE", "DIG",
}
MARKET_OPS = {"BUY_SEED", "BUY_PRODUCT", "BUY_ANIMAL", "SELL", "HIRE", "BUY_LAND"}


def validate_action(action: dict, hand_count: int = 0) -> list[str]:
    errors = []
    if set(action) != {"farmer", "hands", "market"}:
        errors.append("action must contain exactly farmer, hands, and market")
    farmer = action.get("farmer", [])
    hands = action.get("hands", [])
    market = action.get("market", [])
    if not isinstance(farmer, list) or not farmer or farmer[0] not in FARMER_OPS:
        errors.append("invalid farmer action")
    if not isinstance(hands, list) or len(hands) != hand_count:
        errors.append("hands must contain one action per hired hand")
    elif any(not move or move[0] not in FARMER_OPS for move in hands):
        errors.append("invalid hand action")
    if not isinstance(market, list) or len(market) > 10:
        errors.append("market must be a list of at most ten orders")
    elif any(not order or order[0] not in MARKET_OPS for order in market):
        errors.append("invalid market order")
    return errors


validate_action({"farmer": ["PASS"], "hands": [], "market": [["BUY_SEED", "CARROT", 1]]})
"""
    ),
    markdown(
        """## 4. Minimal deterministic baseline

This validity baseline stays on the starting tile next to the shed and cycles carrots: buy, plant, water, harvest, drop, and sell. It deliberately ignores most of the board. Its job is to validate the complete action and packaging path before a stronger planner is trusted.
"""
    ),
    code(
        """def carrot_loop_agent(obs):
    farms = obs.get("farms") or []
    player = int(obs.get("player", 0))
    private = obs.get("private") or {}
    if player >= len(farms):
        return {"farmer": ["PASS"], "hands": [], "market": []}

    farm = farms[player]
    x, y = farm["farmer"]
    tile = farm["tiles"][y][x]
    seeds = private.get("seeds") or {}
    shed = private.get("shed") or {}
    inventories = private.get("inventories") or []
    carried = inventories[0] if inventories else {}
    market = []

    if shed.get("CARROT", 0) > 0:
        market.append(["SELL", "CARROT", shed["CARROT"]])
    if tile is None and seeds.get("CARROT", 0) == 0 and farm.get("money", 0) >= 20:
        market.append(["BUY_SEED", "CARROT", 1])

    farmer = ["PASS"]
    if sum(carried.values()) > 0:
        farmer = ["DROP"]
    elif tile is None and seeds.get("CARROT", 0) > 0:
        farmer = ["PLANT", "CARROT"]
    elif isinstance(tile, dict) and tile.get("kind") == "WEED":
        farmer = ["DIG"]
    elif isinstance(tile, dict) and tile.get("kind") == "PLANT" and tile.get("crop") == "CARROT":
        age = obs.get("day", 0) - tile.get("planted_day", 0)
        if age >= 3 and tile.get("yield_units", 0) > 0:
            farmer = ["HARVEST"]
        elif not tile.get("watered_today", False):
            farmer = ["WATER"]

    return {
        "farmer": farmer,
        "hands": [["PASS"] for _ in farm.get("hands", [])],
        "market": market,
    }
"""
    ),
    code(
        """toy_observation = {
    "player": 0,
    "day": 0,
    "farms": [{
        "money": 3000,
        "farmer": [4, 4],
        "hands": [],
        "tiles": [[None] * 10 for _ in range(10)],
    }],
    "private": {"seeds": {}, "shed": {}, "inventories": [{}]},
}

toy_action = carrot_loop_agent(toy_observation)
assert validate_action(toy_action) == []
toy_action
"""
    ),
    markdown(
        """## 5. Validation that matches the ladder

Run each candidate in a fresh process. For every seed, play both seats against the same frozen opponent. Primary evidence is win/tie/loss across episodes; bank balance is diagnostic. Do not split adjacent replay steps across training and validation because that leaks nearly identical states.
"""
    ),
    code(
        """def summarize_outcomes(candidate_rewards, opponent_rewards):
    outcomes = [
        "win" if ours > theirs else "loss" if ours < theirs else "tie"
        for ours, theirs in zip(candidate_rewards, opponent_rewards)
    ]
    decisive = sum(result != "tie" for result in outcomes)
    wins = outcomes.count("win")
    return {
        "episodes": len(outcomes),
        "wins": wins,
        "ties": outcomes.count("tie"),
        "losses": outcomes.count("loss"),
        "decisive_win_rate": wins / decisive if decisive else math.nan,
        "mean_bank_difference": statistics.mean(
            ours - theirs for ours, theirs in zip(candidate_rewards, opponent_rewards)
        ),
    }


# Synthetic example only: replace with paired arena results.
summarize_outcomes([4100, 3200, 3700, 3900], [3800, 3300, 3700, 3500])
"""
    ),
    markdown(
        """## 6. Optional local environment smoke test

The current repository environment may not match Kaggle's live configuration. This cell inspects defaults and only runs a short game if Kaggle Environments is installed. A successful run proves interface compatibility, not competitive performance or evaluator identity.
"""
    ),
    code(
        """expected_defaults = {
    "episodeSteps": 720,
    "startingMoney": 3000,
    "townShopSellInterval": 4,
    "townCenterSellInterval": 24,
    "farmHandCostMult": 1,
}

try:
    from kaggle_environments import make

    probe = make("kaggriculture", debug=True)
    observed = {key: probe.configuration[key] for key in expected_defaults}
    mismatches = {
        key: {"expected": expected_defaults[key], "observed": observed[key]}
        for key in expected_defaults
        if observed[key] != expected_defaults[key]
    }
    print("Configuration mismatches:", mismatches or "none")

    short = make(
        "kaggriculture",
        configuration={**expected_defaults, "episodeSteps": 24, "seed": SEED},
        debug=True,
    )
    short.run([carrot_loop_agent, "starter"])
    print([(state.reward, state.status) for state in short.steps[-1]])
except (ImportError, FileNotFoundError, KeyError) as exc:
    print("Optional environment smoke test skipped:", type(exc).__name__, exc)
"""
    ),
    markdown(
        """## 7. Exercise

Improve the validity baseline without adding farm hands:

1. Move among four nearby unlocked tiles.
2. Track a daily priority queue: water urgent plants before planting new ones.
3. Stop planting when the crop cannot mature and be sold before turn 720.
4. Compare the new policy against the frozen baseline over paired seeds.

**Answer scaffold:** complete `choose_target` and `should_plant`, then plug them into a copy of `carrot_loop_agent`. Keep pathfinding and economic policy separate so each can be tested.
"""
    ),
    code(
        """def choose_target(position, candidate_tiles):
    # TODO: choose the nearest tile, with a deterministic tie-break.
    return min(
        candidate_tiles,
        key=lambda tile: (abs(position[0] - tile[0]) + abs(position[1] - tile[1]), tile[1], tile[0]),
    )


def should_plant(day, crop="CARROT", season_days=30, sale_buffer_days=1):
    maturity = CROPS[crop].peak_day
    return day + maturity + sale_buffer_days < season_days


assert choose_target((4, 4), [(3, 4), (4, 3)]) == (4, 3)
assert should_plant(20)
assert not should_plant(27)
"""
    ),
    markdown(
        """## Next steps and pitfalls

- Pin a local environment revision that matches Kaggle's live evaluator.
- Run full 720-turn, side-swapped seeded matches in separate processes.
- Inspect public high-rated replays before tuning a large heuristic.
- Preserve a frozen fallback agent and validate the exact archive before upload.
- Never submit merely because a short smoke test passes; Kaggle's self-play validation and live ladder behavior are separate stages.
"""
    ),
]

for index, cell in enumerate(cells):
    cell["id"] = f"kaggriculture-{index:02d}"

notebook = {
    "cells": cells,
    "metadata": {
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python", "version": "3.12"},
    },
    "nbformat": 4,
    "nbformat_minor": 5,
}

OUTPUT.write_text(json.dumps(notebook, indent=2) + "\n", encoding="utf-8")
print(OUTPUT)
