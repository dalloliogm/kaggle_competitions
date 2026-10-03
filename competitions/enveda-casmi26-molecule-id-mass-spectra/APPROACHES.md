# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD |

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
