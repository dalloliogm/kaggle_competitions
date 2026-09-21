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
    planets = _read(obs, "initial_planets", None) or _read(obs, "planets", [])
    owners = [int(planet[1]) for planet in planets if int(planet[1]) >= 0]
    return max(owners, default=1) + 1


def agent(obs):
    global _player_count
    step = int(_read(obs, "step", 0) or 0)
    if step == 0 or _player_count is None:
        _player_count = _infer_initial_player_count(obs)
    if _player_count >= 4:
        return producer_anchor_agent.agent(obs)
    return primary_agent.agent(obs)


__all__ = ["agent"]
