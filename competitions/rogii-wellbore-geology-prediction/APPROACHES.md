# Approaches

Track modeling approaches, experiments, submissions, and outcomes here. Prefer short entries with enough detail that a future chat can understand what was tried and whether it is worth revisiting.

## Current Best

| Date | Approach | Local CV | Public LB | Private LB | Notebook/commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-05-10 | Triple-signal beam search + dual PF + LightGBM (likely) | TBD | 11.107 | TBD | `notebooks/triple-signal-beam-search-dual-pf-lightgbm.ipynb` | Best submitted score so far (submission `52524349`, 2026-05-10 19:29:51). Notebook attribution inferred from kernel run time (19:27:33) being closest to the submission timestamp — not yet confirmed via kernel version metadata. |

## Tried

| Date | Approach | Changes | Local CV | Public LB | Outcome | Follow-up |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-05-06 | NN starter (`nn-starter-cv-15-5.ipynb`) | Simple PyTorch baseline, CV ~15.5 | ~15.5 | 15.744 | Submission `52390182`; matches notebook's own CV-15.5 name | Superseded by later submissions |
| 2026-05-10 | Unidentified second submission same session | TBD | 11404.716 | Failed/anomalous | Submission `52524355`, 2026-05-10 19:30:03 — 12 seconds after the 11.107 submission, score is ~1000x worse, almost certainly a broken run (wrong units/column, or an unintended submission file) | Identify which notebook produced this and why it broke before reusing it |

## Backlog

| Idea | Rationale | Expected impact | Cost | Priority |
| --- | --- | --- | --- | --- |
| Adopt/adapt the shared "target-free geosteering" pipeline (PF/beam/DTW + GBM residual + contact override; see `LEARNINGS.md` and `notebooks/working-note-target-free-tvt-geosteering.ipynb`) | Public meta moved from ~11-15 (May) to 6-9 (July) via this technique; hundreds of forks confirm it reproduces reliably; GPU not required | Likely jump from rank 3504 to top-25%/bronze in one submission | Medium (adaptation, not invention — `koolbox`/artifacts datasets do the heavy lifting) | High |
| Ensemble our own dual-PF/LightGBM notebook + the DWT-based lineage on top of the shared pipeline | Most forkers only tweak one shared notebook's config; independent signals are the realistic path from bronze to silver/gold | Differentiation beyond the fork cluster | Medium-High | High |
| Validate via visible-prefix holdout instead of LB probing | Competition-specific per-well self-calibration signal already built into the public notebooks; submissions capped at 5/day | Avoid wasting submission budget | Low | High |
| Compare starter NN, TCN, and LightGBM under one grouped CV split | Current older notebooks likely use different assumptions and validation setups; may be superseded by the geosteering approach | Establish reliable baseline ranking | Medium | Low (deprioritized vs. adopting the current meta) |
| Audit online/test-known-zone training logic | The strongest-looking notebook uses test known zones for calibration-style samples | Avoid leakage or rule violations | Medium | Medium |
| Build an end-to-end Kaggle submission notebook | Existing notebooks may be exploratory or runtime-heavy | Make submissions reproducible | Medium | Medium |

## Abandoned

| Approach | Why dropped | Evidence | Revisit if |
| --- | --- | --- | --- |
| TBD | TBD | TBD | TBD |
