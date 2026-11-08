# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-10-31 | Fork of public m1 (busyaprime, 0.477): v4g pipeline + neural RRF .25/.75 + fragment check | n/a | 0.477 (ref 57838262, reproduced 2026-11-01) | - | dalloliogm/casmi26-fork-m1-0477 v1 | quick catch-up submission, unmodified |
| 2026-11-05 | m1 + rank-1 arbiter (LightGBM on ICEBERG/GLACIER/fragment/structure, swap leader with rank 2-6 if P>0.8) | grouped CV +0.025 (clean features, validation dump; optimistic) | 0.477 (ref 58019927; = baseline, no measurable effect) | - | dalloliogm/casmi26-m1-arbiter v1 | expect +0.005-0.015 vs 0.477 |
| 2026-11-07 | m1 + rank-1 arbiter, thr 0.7 (same model as thr 0.8 run) | grouped CV +0.036 (clean, lgbm, 0.7; ~27 swaps/300) | 0.473 (ref 58101521; -0.004 vs baseline) | - | dalloliogm/casmi26-m1-arbiter v2 | tests whether more swaps help; v1 (0.8) = 0.477 |
| 2026-11-08 | m1 + tail rescue (outside candidates compete by neural score for ranks 21-25; 40 outsiders/molecule), no arbiter | n/a (validation has ~100% recall) | pending | - | dalloliogm/casmi26-m1-tail-rescue v1 | ranks 1-20 identical to m1 |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-10-03 | Library cosine retrieval | class-1 only | 0.917 (class-1 holdout) | 0.140 | Hidden test mostly class 2/3 | superseded |
| 2026-10-03 | Own FP-MLP + pool candidates + thresholded lib | pool_popularity candidates | 0.657 (optimistic) | 0.191 | superseded | - |
| 2026-10-03 | + PubChem tier (4000/window) | wider candidates | 0.368 honest | 0.175 | weak encoder cannot rank extra isomers | needs strong encoder first |
| 2026-10-04 | Public FPNet (v4) | swap encoder | 0.865 | 0.292-0.297 | big jump | - |
| 2026-10-04 | NP-panel tuned blend (v5) | pop .25, nn .5 | 0.748 NP panel | 0.255 | panel not representative | never tune on panel |
| 2026-10-04 | FPNet x4 + merged views (v6) | ensemble | 0.863 | 0.290 | no gain | - |
| 2026-10-04..06 | Fork public pipeline (FPNet+LGBM+tier+ICEBERG/GLACIER) | none | - | 0.363-0.379 | +0.08 | best old floor (POP_MU .15 = 0.379) |
| 2026-10-09 | Prize path own FPNet (train.parquet+COCONUT) | 100k steps | 0.70 held-out | 0.261 | prize-eligible, weak | - |
| 2026-10-10 | Prize path + own PubChem tier channel | delta=1 | - | 0.209 | hurt | - |
| 2026-10-10 | Prize path train3 (merging+aug+EMA) + tier delta=4 | regularised | 0.706 | 0.274 | best prize-eligible | - |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| TBD | TBD | TBD | TBD |


## Library retrieval baseline (notebook: casmi26-library-retrieval-baseline)

- Neutral mass from adduct -> shortlist train structures by formula mass (max(0.01 Da, 15 ppm)); binned (0.02 Da) sqrt-intensity cosine; best match per structure per spectrum, mean across molecule's spectra; top 25 unique inchikey14.
- Only class 1. Status: untested on real data.
