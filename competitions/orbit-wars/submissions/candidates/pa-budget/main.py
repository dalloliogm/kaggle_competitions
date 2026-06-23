"""Route each Orbit Wars game to the strongest observed player-count specialist."""

from __future__ import annotations

import primary_agent
import producer_anchor_agent


_player_count: int | None = None


def _read(obs, key, default=None):
    if isinstance(obs, dict):
        return obs.get(key, default)
    return getattr(obs, key, default)


def _infer_initial_player_count(obs) -> int:
    # Count distinct seat owners from the LIVE ``planets``/``fleets`` — at game
    # start each player owns one planet, so seats appear here. ``initial_planets``
    # is all-neutral in the real obs (owners only ever show up in ``planets``), so
    # keying off it mis-detects every 4P game as 2P and misroutes it. Seats are
    # 0-based and contiguous, so player count = max seat index + 1.
    owners = set()
    for row in (_read(obs, "planets", None) or _read(obs, "initial_planets", None) or []):
        try:
            o = int(row[1])
        except (IndexError, TypeError, ValueError):
            continue
        if o >= 0:
            owners.add(o)
    for row in (_read(obs, "fleets", None) or []):
        try:
            o = int(row[1])
        except (IndexError, TypeError, ValueError):
            continue
        if o >= 0:
            owners.add(o)
    return (max(owners) + 1) if owners else 2


def agent(obs):
    global _player_count
    step = int(_read(obs, "step", 0) or 0)
    if step == 0 or _player_count is None:
        _player_count = _infer_initial_player_count(obs)
    if _player_count >= 4:
        return producer_anchor_agent.agent(obs)
    return primary_agent.agent(obs)


__all__ = ["agent"]
