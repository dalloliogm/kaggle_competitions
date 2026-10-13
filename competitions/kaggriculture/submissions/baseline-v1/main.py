"""Kaggriculture validity baseline: a deterministic single-tile carrot loop.

This agent is intentionally simple. It exercises buying, planting, watering,
harvesting, dropping, and selling while staying on the starting shed-adjacent
tile. It is a packaging/runtime baseline, not a competitive strategy.
"""

from __future__ import annotations


PASS_ACTION = {"farmer": ["PASS"], "hands": [], "market": []}


def agent(obs):
    """Return one legal action dictionary from a Kaggriculture observation."""
    farms = obs.get("farms") or []
    player = int(obs.get("player", 0))
    private = obs.get("private") or {}
    if player < 0 or player >= len(farms):
        return PASS_ACTION

    farm = farms[player]
    farmer_position = farm.get("farmer") or [0, 0]
    x, y = int(farmer_position[0]), int(farmer_position[1])
    tiles = farm.get("tiles") or []
    if y < 0 or y >= len(tiles) or x < 0 or x >= len(tiles[y]):
        return PASS_ACTION

    tile = tiles[y][x]
    seeds = private.get("seeds") or {}
    shed = private.get("shed") or {}
    inventories = private.get("inventories") or []
    farmer_inventory = inventories[0] if inventories else {}
    money = float(farm.get("money", 0))
    market = []

    # Market orders execute after field actions. Sell everything already banked
    # in the shed and maintain one carrot seed for the next empty-tile cycle.
    carrots_in_shed = int(shed.get("CARROT", 0))
    if carrots_in_shed > 0:
        market.append(["SELL", "CARROT", carrots_in_shed])
    if tile is None and int(seeds.get("CARROT", 0)) == 0 and money >= 20:
        market.append(["BUY_SEED", "CARROT", 1])

    farmer = ["PASS"]
    if sum(int(value) for value in farmer_inventory.values()) > 0:
        # The starting tile is adjacent to the central shed.
        farmer = ["DROP"]
    elif tile is None and int(seeds.get("CARROT", 0)) > 0:
        farmer = ["PLANT", "CARROT"]
    elif isinstance(tile, dict) and tile.get("kind") == "WEED":
        farmer = ["DIG"]
    elif isinstance(tile, dict) and tile.get("kind") == "PLANT":
        if tile.get("crop") == "CARROT":
            age = int(obs.get("day", 0)) - int(tile.get("planted_day", 0))
            if age >= 3 and int(tile.get("yield_units", 0)) > 0:
                farmer = ["HARVEST"]
            elif not bool(tile.get("watered_today", False)):
                farmer = ["WATER"]

    return {
        "farmer": farmer,
        "hands": [["PASS"] for _ in farm.get("hands", [])],
        "market": market[:10],
    }
