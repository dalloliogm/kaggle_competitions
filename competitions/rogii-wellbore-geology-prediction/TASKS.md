# Tasks

## Current Goal

**Catch-up strategy, updated 2026-07-25 (~11 days left, deadline 2026-08-05 23:59:00).** Best-ever public score is **model-package-only at 7.097** (rank ~1317/5572, top 23.6%, 2026-07-23), but as of 2026-07-25 this is under serious doubt — see "Reliability crisis" below, now the top priority.

### Reliability crisis (top priority right now)
Resubmitted the exact same byte-identical `submission_model_package_only.csv` file (verified via SHA-256 across two independent kernel runs) and it scored **20.067** instead of 7.097. Separately, resubmitting the no-override blend threw another exception. **This pipeline family is unreliable at Kaggle's actual grading time in a way that isn't visible from our own interactive kernel runs** — see `LEARNINGS.md` "Escalation" section for full details. A tie-breaker third submission (`54968605`) is in flight.

**Until this resolves, do not treat any single score from this pipeline (ours or a public notebook's) as a stable fact.** This changes the submission-budget calculus: spend slots on repeat-confirming whatever we're leaning toward for Final Submissions, not just chasing new variants.

### Recently submitted, pending as of 2026-07-25
- Tie-breaker #3 for model-package-only (`54968605`)
- Continuity-fade ablation (`54968618`) — legitimate boundary-smoothing fix, not leak-related, ported from a public notebook self-reporting LB 6.40
- Capped overlap calibration (`54968623`) — leak-adjacent (5.5% dose of the same signal our full override already showed hurts at 100%), also ported from that notebook

Both new ablations should be treated skeptically even if they score well, until repeated — see reliability crisis above.

### Once reliability is understood: differentiate beyond the current sweep
- If a config turns out genuinely stable, ensemble it with our own `triple-signal-beam-search-dual-pf-lightgbm.ipynb` or the DWT-based lineage (`9-251-...-dwt-based.ipynb`) as an independent signal.
- The pure-learned-branch ablation (7.856, worse than the blend/model-package) shows the PF/ridge anchor and model-package both add real value beyond raw GBM boosters — headroom exists there if we can trust the numbers.
- Tune conservatively via CV/visible-prefix holdout; don't burn the 5/day submission budget on blind LB probing.

### Final-submission picks (once reliability is sorted)
- Select 2 Final Submissions (rule allows up to 2). Given the demonstrated instability, prefer whichever candidate(s) show the *most consistent* repeated scores over whichever has the single best point-estimate — a lucky 7.097 that regresses to 20 on the actual scored run would be catastrophic for final placement.
- Leave 1-2 days of buffer before the deadline for submission failures or last-minute issues.

### Operational notes
- Kaggle's submission scoring can take 6+ hours to return a score (observed once) — don't assume PENDING for a few hours means something is broken.
- Use `kaggle competitions submissions ... --format json` and compare `ref` as an `int`, not a string, when scripting status checks — the table view wraps long descriptions onto a second line and breaks naive line-based parsing.
- `notebooks/working-note-*-ablation.ipynb` and their sidecar `.kernel-metadata.json` files are reusable templates for future single-change ablations of this pipeline.
- Resubmitting an already-pushed kernel version (no new push needed) is enough to get a fresh, independent grading-time execution — useful for reproducibility checks without waiting ~10-15 min for a rerun.

## Next Experiments (smaller/parallel items, low priority given the pivot above)

- Move `../playground-series-s6e5/notebooks/rogii-automated-public-ensemble-v2.ipynb` into this workspace's `notebooks/` — it's a ROGII notebook misfiled under the playground-series-s6e5 folder. Pure housekeeping, not urgent.
- Our pre-2026-07-23 notebooks (`rogii-lgbm-aug-online-training.ipynb`, `wellbore-geology-tcn.ipynb`, `nn-starter-cv-15-5.ipynb`) all predate the target-free-geosteering pivot and scored far worse (11-16 range) — not worth reviewing further unless a specific feature idea from them is worth grafting onto the current best.

## Done

- Initialized workspace from `https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction`.
- Fetched Kaggle description, evaluation, rules, and file listing into `references/`.
- Copied initial ROGII notebooks from `origin/main` into `notebooks/`.
- Confirmed Kaggle API connection works (access-token auth) and competition is already joined (`userHasEntered: True`).
- Pulled and reviewed 5 top public notebooks; identified the current dominant "target-free geosteering" technique and confirmed GPU is not required for it (see `LEARNINGS.md`).
- Downloaded full public leaderboard (2026-07-23: 5504 teams; 2026-07-24: 5572 teams), computed real rank and medal-zone score cutoffs both times.
- Confirmed via competition rules that public code/dataset sharing (the shared `koolbox`/`artifacts`/PF-config notebooks) is explicitly compliant, not a gray area.
- Decided validation protocol: `GroupKFold(well_id)` plus the competition-specific visible-prefix holdout trick.
- Ran and submitted a 5-point ablation sweep (contact-override, model-package-only, no-override blend, pure-learned-branch, pure-PF-anchor) — real scores landed 2026-07-24, moving us from rank 3504 (11.107) to ~1317 (7.097). Overturned the assumption that the contact-override profile would be our strongest pick.

## Questions

- Are type-well files always available for each horizontal well in train and test?
- Exactly how does Kaggle split public/private here — same 3 wells by row, or something else? (Inferred, not confirmed; see `COMPETITION.md`.)
- Why does the contact override generalize so much worse than its ~0.01 ft prefix RMSE would suggest? Not yet investigated — see Backlog in `APPROACHES.md`.
- ~~Which notebook produced our old 11.107 best-score submission?~~ No longer relevant — superseded by the 2026-07-23/24 sweep.
- ~~Does the "learned branch" NN beat pure LightGBM/CatBoost residuals?~~ Answered: pure-learned-branch alone scores 7.856, clearly worse than the full blend (7.102) or model-package-only (7.097) — the blend's other components (PF/ridge anchor, model-package) add real value.
