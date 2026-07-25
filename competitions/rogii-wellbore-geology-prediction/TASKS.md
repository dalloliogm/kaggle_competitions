# Tasks

## Current Goal

**Catch-up strategy, updated 2026-07-25 (~11 days left, deadline 2026-08-05 23:59:00).** Best-ever public score is **model-package-only at 7.097** (rank ~1317/5572, top 23.6%, 2026-07-23). Checked the competition forum and got two resolving answers to what looked like open mysteries — see `LEARNINGS.md` for full detail and forum thread IDs:

1. **The visible `test/` folder (3 wells) is placeholder data, replaced entirely at grading time with a real hidden set (~52 wells for public alone).** Confirmed directly by the host. This means our train/test overlap discovery, while real in the placeholder data, isn't exploitable for real scoring — **the capped-overlap-calibration ablation is a dead end**, and per-well diagnostics we ran against the visible 3 wells don't necessarily transfer to the real scored set.
2. **Score variance between identical resubmissions is confirmed, community-documented, unseeded PF-feature randomness** — not a bug in our code or a platform failure. Other competitors have reported the exact same symptom (identical notebook, 3 submissions, 3 different scores) with a clear community explanation. Our 7.097→20.067 swing is an extreme case of the same well-understood phenomenon.

### What this changes
- **Stop pursuing the overlap-exploitation angle** — deprioritize the capped-overlap-calibration result whenever it lands; it's not expected to be informative either way.
- **The "reliability crisis" is resolved conceptually** (we know the cause now) but the practical implication stands: any single score is one noisy sample. For Final Submission selection, prefer repeat-confirmed candidates or deliberately resubmit a strong candidate multiple times and bank whichever draw scores best — this is a legitimate, community-validated tactic (per the forum: *"one could get top 5 on the public LB just submitting the best public notebook like 10 times"*), not overfitting, since the random draw applies uniformly across all rows in one submission rather than being a public-only artifact.
- **The continuity-fade ablation is still worth trusting as a concept** (it's not leak-related, just a legitimate boundary-smoothing fix) — its result should still be read with the "one noisy sample due to PF randomness" caveat, same as anything else from this pipeline.

### Recently submitted, pending as of 2026-07-25
- Tie-breaker #3 for model-package-only (`54968605`) — expect a third, likely different, number; don't be surprised
- Continuity-fade ablation (`54968618`)
- Capped overlap calibration (`54968623`) — expect this to be a near-no-op given Finding 1 above

### Differentiate beyond the current sweep
- Ensemble a genuinely independent signal — our own `triple-signal-beam-search-dual-pf-lightgbm.ipynb` or the DWT-based lineage (`9-251-...-dwt-based.ipynb`) — on top of the current best, now that we understand the score noise isn't something ensembling alone will fix (the earlier ensemble regression to 11.736 is now better explained by PF randomness than by a bad ensemble idea).
- The pure-learned-branch ablation (7.856, worse than the blend/model-package) shows the PF/ridge anchor and model-package both add real value beyond raw GBM boosters.
- Given real reproducibility requires *repeated* submissions to average out noise, and we only get 5/day, budget for this explicitly rather than treating every slot as a new experiment.

### Final-submission picks
- Select 2 Final Submissions (rule allows up to 2). Given the confirmed randomness, prefer a strategy of **resubmitting our best-understood config several times near the deadline and picking the best-scoring draw(s)**, rather than picking based on whichever single historical score looks best.
- Leave 1-2 days of buffer before the deadline for submission failures or last-minute issues.

### Operational notes
- Kaggle's submission scoring can take 6+ hours to return a score (observed once) — don't assume PENDING for a few hours means something is broken.
- Use `kaggle competitions submissions ... --format json` and compare `ref` as an `int`, not a string, when scripting status checks — the table view wraps long descriptions onto a second line and breaks naive line-based parsing.
- `notebooks/working-note-*-ablation.ipynb` and their sidecar `.kernel-metadata.json` files are reusable templates for future single-change ablations of this pipeline.
- Resubmitting an already-pushed kernel version (no new push needed) is enough to get a fresh, independent grading-time execution — useful for reproducibility checks without waiting ~10-15 min for a rerun.
- **The Kaggle CLI can read the discussion forum**: `kaggle competitions topics list <slug> --format json` and `kaggle competitions topic-messages <slug> <topic_id> --format json -n -1`. WebFetch cannot render forum/writeup pages (client-side React, returns only the page title) — the CLI is the only way to actually read thread content. Worth checking periodically for new host announcements or community findings.

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
