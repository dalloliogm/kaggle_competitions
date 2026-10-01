#!/usr/bin/env python3
"""Mine a Kaggriculture replay corpus for what strong players actually do.

Implements step 3 of docs/kaggle-simulation-competition-playbook.md ("mine
strong-player behavior") against the public tabular corpora, e.g.
`kaggle datasets download vijaikm/kaggriculture-match-replay-corpus`.

Strength is taken from each team's mean final score in matches_meta.csv, so no
external rating table is needed. Market orders carry the economy decisions
(hiring curve, land timing, livestock mix, seed mix, sale volumes); farmer
actions in these corpora record only the main farmer, not the hired hands.

Usage: mine_replay_corpus.py <corpus-dir> [--min-score 80000] [--min-games 4]
"""

import argparse
import collections
import csv
import os
import statistics

PRODUCTS = ["WHEAT", "CARROT", "TOMATO", "STRAWBERRY", "MELON",
            "EGG", "MILK", "WOOL", "FERTILIZER"]
CROPS = ["WHEAT", "CARROT", "TOMATO", "STRAWBERRY", "MELON"]
ANIMALS = ["GOOSE", "COW", "SHEEP"]


def load_meta(path):
    """(episode, seat) -> (team, final score)."""
    out = {}
    with open(path) as fh:
        for r in csv.DictReader(fh):
            for seat in ("0", "1"):
                try:
                    score = float(r[f"player_{seat}_score"])
                except (ValueError, KeyError):
                    continue
                out[(r["episode_id"], seat)] = (r[f"player_{seat}_team"], score)
    return out


def rank_teams(meta, min_games):
    scores = collections.defaultdict(list)
    for team, score in meta.values():
        scores[team].append(score)
    return {t: (statistics.mean(v), len(v))
            for t, v in scores.items() if len(v) >= min_games}


def profile(corpus, meta, teams):
    """Per-game aggregates for every player in `teams`."""
    agg = collections.defaultdict(collections.Counter)
    with open(os.path.join(corpus, "market_orders.csv")) as fh:
        for r in csv.DictReader(fh):
            key = (r["episode_id"], r["player"])
            if key not in meta or meta[key][0] not in teams:
                continue
            day, op, item = int(r["day"]), r["order_type"], r["item"]
            try:
                qty = float(r["quantity"] or 1)
            except ValueError:
                qty = 1
            a = agg[key]
            if op == "HIRE":
                a["hires"] += 1
                a[f"hires_block{min(day // 6, 4)}"] += 1
            elif op == "BUY_LAND":
                a["land_quadrants"] += 1
                a["land_first_day"] = min(a["land_first_day"] or 99, day)
            elif op == "BUY_ANIMAL":
                a[f"animal_{item}"] += qty
            elif op == "BUY_SEED":
                a[f"seed_{item}"] += qty
            elif op == "SELL":
                a[f"sold_{item}"] += qty
            elif op == "BUY_PRODUCT":
                a[f"bought_{item}"] += qty
    return agg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("corpus")
    ap.add_argument("--min-score", type=float, default=80000)
    ap.add_argument("--min-games", type=int, default=4)
    args = ap.parse_args()

    meta = load_meta(os.path.join(args.corpus, "matches_meta.csv"))
    ranked = rank_teams(meta, args.min_games)
    strong = {t for t, (m, _) in ranked.items() if m >= args.min_score}
    if not strong:
        raise SystemExit("no teams clear --min-score; lower it or widen the corpus")
    agg = profile(args.corpus, meta, strong)

    def med(key):
        return statistics.median([a[key] for a in agg.values()]) if agg else 0

    print(f"{len(meta)} player-games in corpus, {len(ranked)} teams with "
          f">={args.min_games} games")
    print("strong cohort (mean score >= %.0f): %s" % (args.min_score, ", ".join(sorted(strong))))
    print(f"profiled {len(agg)} games\n")
    print("median per game:")
    print(f"  hires {med('hires'):.0f} total, by 6-day block "
          f"{[round(med(f'hires_block{i}')) for i in range(5)]}")
    print(f"  land {med('land_quadrants'):.0f} extra quadrants, first on day "
          f"{med('land_first_day'):.0f}")
    print("  livestock: " + "  ".join(f"{k} {med('animal_' + k):.0f}" for k in ANIMALS))
    print("  seeds:     " + "  ".join(f"{k} {med('seed_' + k):.0f}" for k in CROPS))
    print("  sold:      " + "  ".join(f"{k} {med('sold_' + k):.0f}" for k in PRODUCTS))
    print("  bought:    " + "  ".join(f"{k} {med('bought_' + k):.0f}"
                                      for k in ("WHEAT", "FERTILIZER")))


if __name__ == "__main__":
    main()
