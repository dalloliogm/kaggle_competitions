# Tasks

## Current Goal

**Catch-up strategy, updated 2026-07-24 (~12 days left, deadline 2026-08-05 23:59:00).** Yesterday's 5-point ablation sweep scored (see `APPROACHES.md`/`LEARNINGS.md` for full numbers) and **overturned the working assumption from Phase 0**: the contact-override profile we expected to be our strong pick actually scored *worst* (9.565) of the four that scored. Current best is **model-package-only at 7.097** (rank ~1317/5572, top 23.6%), effectively tied with the no-override blend (7.102). We've moved from rank 3504 to ~1317 in one day; bronze needs ≤6.538, about 0.56 away.

### Phase 0 (CPU): reproduce the shared baseline — DONE
- Confirmed GPU not required; confirmed the contact-override profile is real-world *worse* than not using it, not just neutral. Full sweep and scores in `APPROACHES.md`.

### Phase 1 (now): ensemble the two near-tied leaders
- Average `submission_model_package_only.csv` (7.097) and the no-override blend's `submission.csv` (7.102) — same id order in both, so this is a trivial merge. They come from different signal paths (separate pretrained model vs. PF+GBM blend) so there's a real chance of pulling independent error down.
- Resolve the pure-PF-anchor scoring anomaly (empty `publicScore` despite a verified-clean file) — resubmit or investigate further before relying on that data point.
- Decide whether to keep investigating *why* the override overfits (Backlog item) or deprioritize it — don't spend more than one focused session on this before moving on.

### Phase 2 (days ~3-10): push past top25% toward bronze/silver
- The ensemble in Phase 1 is the first concrete lever. Beyond that:
  - Ensemble our own `triple-signal-beam-search-dual-pf-lightgbm.ipynb` (dual-PF + LGBM) and the highest-voted alternative lineage (`9-251-...-dwt-based.ipynb`, DWT-based GR alignment + LGBM/CatBoost/hill-climbing) as independent signals on top of the current best.
  - Spend modeling effort on the LightGBM/CatBoost residual layer and/or the PF/ridge anchor specifically — the pure-learned-branch ablation (7.856) shows those two components add real value beyond raw GBM boosters, so there's headroom there, not just in override tuning.
  - Tune conservatively via CV/visible-prefix holdout; don't burn the 5/day submission budget on blind LB probing.

### Phase 3 (final ~days): stability and final-submission picks
- Select 2 Final Submissions (rule allows up to 2). Given the override finding, lean toward two *non-override* variants (e.g. the ensemble as primary, no-override blend or model-package-only alone as the hedge) rather than pairing an aggressive-override pick with a conservative one as originally planned.
- Leave 1-2 days of buffer before the deadline for submission failures or last-minute issues.

### Operational notes carried over from 2026-07-23
- Kaggle's submission scoring can take 6+ hours to return a score (observed once) — don't assume PENDING for a few hours means something is broken.
- Use `kaggle competitions submissions ... --format json` and compare `ref` as an `int`, not a string, when scripting status checks — the table view wraps long descriptions onto a second line and breaks naive line-based parsing.
- `notebooks/working-note-*-ablation.ipynb` and their sidecar `.kernel-metadata.json` files are reusable templates for future single-change ablations of this pipeline.

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
