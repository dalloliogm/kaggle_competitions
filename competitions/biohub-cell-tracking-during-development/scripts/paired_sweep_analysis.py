#!/usr/bin/env python3
"""Paired per-video comparison of sweep candidates, restricted to affected videos.

## Why this exists

On 2026-09-18 a candidate was called validated on a paired bootstrap over all 24
held-out stems: +0.00167 adjusted edge Jaccard, CI excluding zero. It then lost
on the leaderboard. The error was that only 9 of the 24 videos were affected by
the change at all; the other 15 were exact ties, and including them diluted the
bootstrap with structural zeros, tightening the interval without adding
information.

So every comparison here reports **both**:

* the weighted aggregate delta, which is what the competition metric computes
  and therefore what a leaderboard score reflects; and
* the paired statistics restricted to the videos the change actually moves,
  which is where the evidence actually lives.

A candidate whose aggregate looks good but which moves three videos is a
candidate with three data points, and the output says so.

Usage:  python3 scripts/paired_sweep_analysis.py <validator_results.csv> [baseline_config]
"""

from __future__ import annotations

import collections
import csv
import math
import random
import statistics
import sys
from pathlib import Path

BOOTSTRAP = 20000
SEED = 20260919


def load(path: Path):
    rows = list(csv.DictReader(open(path)))
    by = collections.defaultdict(dict)
    for r in rows:
        by[r["config"]][r["stem"]] = r
    return by


def compare(by, cand, ref):
    A, B = by[cand], by[ref]
    stems = sorted(set(A) & set(B))
    recs = []
    for s in stems:
        d = float(A[s]["adjusted_edge_jaccard"]) - float(B[s]["adjusted_edge_jaccard"])
        recs.append((s, d, float(B[s]["weight"]), float(B[s]["t_pred"]) / 100.0))
    wsum = sum(w for _, _, w, _ in recs)
    weighted = sum(d * w for _, d, w, _ in recs) / wsum

    affected = [r for r in recs if abs(r[1]) > 1e-12]
    n_aff = len(affected)
    if n_aff == 0:
        return dict(cand=cand, weighted=0.0, n_aff=0, wins=0, losses=0,
                    lo=0.0, hi=0.0, dens=None, mean=0.0)

    wins = sum(1 for r in affected if r[1] > 0)
    losses = n_aff - wins
    rng = random.Random(SEED)
    boots = []
    for _ in range(BOOTSTRAP):
        samp = [affected[rng.randrange(n_aff)] for _ in range(n_aff)]
        boots.append(sum(d * w for _, d, w, _ in samp) / sum(w for _, _, w, _ in samp))
    boots.sort()
    lo, hi = boots[int(0.025 * BOOTSTRAP)], boots[int(0.975 * BOOTSTRAP)]
    dens = (min(r[3] for r in affected), max(r[3] for r in affected))
    return dict(cand=cand, weighted=weighted, n_aff=n_aff, wins=wins, losses=losses,
                lo=lo, hi=hi, dens=dens,
                mean=statistics.mean(r[1] for r in affected))


def main() -> int:
    path = Path(sys.argv[1])
    ref = sys.argv[2] if len(sys.argv) > 2 else "tight55"
    by = load(path)
    if ref not in by:
        print(f"reference {ref!r} not in {sorted(by)}")
        return 1
    cands = [c for c in by if c != ref and not c.startswith("combo")]
    results = [compare(by, c, ref) for c in cands]
    results.sort(key=lambda r: -r["weighted"])

    print(f"paired against {ref!r}, {len(by[ref])} stems, adjusted edge Jaccard")
    print(f"{'candidate':<18}{'weighted':>10}{'n_aff':>7}{'W/L':>8}"
          f"{'95% CI on affected':>26}{'verdict':>10}  density range")
    print("-" * 104)
    for r in results:
        if r["n_aff"] == 0:
            print(f"{r['cand']:<18}{r['weighted']:>+10.5f}{0:>7}{'-':>8}{'(no effect)':>26}{'inert':>10}")
            continue
        sig = r["lo"] > 0 or r["hi"] < 0
        verdict = ("SUPPORTED" if r["lo"] > 0 else "NEGATIVE") if sig else "noise"
        ci = f"[{r['lo']:+.5f}, {r['hi']:+.5f}]"
        d = r["dens"]
        print(f"{r['cand']:<18}{r['weighted']:>+10.5f}{r['n_aff']:>7}"
              f"{str(r['wins']) + '/' + str(r['losses']):>8}{ci:>26}{verdict:>10}"
              f"  {d[0]:.0f}-{d[1]:.0f} cells/frame")
    print()
    print("weighted = what the competition metric aggregates (drives the leaderboard).")
    print("n_aff    = videos the change actually moves; the rest are exact ties.")
    print("CI is bootstrapped over the AFFECTED videos only - including ties")
    print("would shrink it without adding evidence, which is the 2026-09-18 error.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
