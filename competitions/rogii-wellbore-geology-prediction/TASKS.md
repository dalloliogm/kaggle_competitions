# Tasks

## Current Goal

**Catch-up strategy, updated 2026-07-27 (~9 days left, deadline 2026-08-05 23:59:00).** Major pivot: while this session was mid-flight on the neighbor-transfer/bimodal-hedge levers below, work happened directly on Kaggle from another machine and found something much bigger — **`dalloliogm/rogii-public-score-frontier-lab-visuals` scored 6.474**, our best result of the entire session (previous best ~7.1). Rank ~718/5793 (top 12.4%), bronze ≤6.463 (0.011 away), silver ≤6.427. Full writeup in `LEARNINGS.md` under "BREAKTHROUGH". Reproducibility check in flight (`55038368`).

### Immediate priorities
1. **Confirm 6.474 is reproducible** — reproducibility resubmission pending (`55038368`, same kernel v1). Given this pipeline family's demonstrated PF-randomness, don't fully trust a single score until repeated.
2. **Do not submit any version of `rogii-public-score-frontier-lab-visuals` that includes the "Q0522" cell (cell 47 in the current root-committed file) without removing/gating it first** — it hardcodes an expected SHA/well-ID (`00e12e8b`, a placeholder-only well) with no fallback and will almost certainly throw an exception against real grading data. See `LEARNINGS.md` warning. Flag this to whoever is working on the other machine if still active.
3. **Understand exactly why 6.474 beats our own ablation results** — the active ingredient is GS1.30 (PF gamma-ray likelihood sigma × 1.3, one line, cell 31), on top of the pipeline's existing 128-seed PF ensemble + bimodal branch-hedge (`vp_balanced_modelpkg_005` profile) that we never had active together in our own tests. Worth checking whether GS1.30 alone (without whatever else this specific fork added) reproduces most of the gain, and whether it stacks with our own neighbor-transfer work.

### Three forum-derived levers — status update
1. ~~**Test the `bimodal_guarded` profile preset**~~ — done, 2026-07-26: scored 7.850, inconclusive (see `APPROACHES.md`). Superseded in priority by GS1.30, which appears to achieve a similar goal (don't overcommit to noisy GR matches) more fundamentally.
2. **Neighbor-well curve transfer** — done, but blocked on execution reliability, not the idea itself. V1 (773-well eager load) failed twice; v2 (done on the other machine: k=1 queries, on-demand loading, fail-safe wrapper) *still* failed once (`55022483`) despite excellent defensive engineering — strong evidence the failure is upstream in the shared base pipeline, not this logic. Worth retrying neighbor-transfer v2 layered on top of the GS1.30 base instead of the plain no-override baseline, now that GS1.30 is confirmed much stronger.
3. **PF-seed posterior branch hedge** (also done on the other machine, `dalloliogm/rogii-pf-seed-branch-hedge`) — a more principled, distribution-based version of bimodal-hedge than our flag-flip, built on neighbor-transfer v2. Submission pending (`55036598`).
4. **Azimuth/drilling-direction-based model splitting** — still untested by anyone. Worth trying on top of the GS1.30 base given how much stronger that starting point now is.

### Reliability/randomness — understood, now just a practical constraint
- Score variance between identical resubmissions is confirmed, community-documented, unseeded PF-feature randomness (one competitor's unmodified notebook: 8.354/8.188/8.438 across 3 submissions) — not a bug in our code or a platform failure. Some configs are more stable than others in practice: continuity-fade reproduced almost exactly (7.111 → 7.112) on a repeat submission, unlike model-package-only (7.097 → 20.067 → exception).
- The visible `test/` folder (3 wells) is placeholder data, replaced entirely at grading time with a real hidden set (~52 wells for public alone) — confirmed by the host. This is why overlap/override-based approaches never worked, and why Q0522 (above) will fail. **Don't pursue hardcoded-to-visible-data approaches — confirmed dead end.**
- Practical implication for Final Submissions: prefer a strategy of **resubmitting our best-understood config several times near the deadline and banking the best-scoring draw(s)** — a legitimate, community-validated tactic (forum: *"one could get top 5 on the public LB just submitting the best public notebook like 10 times"*), not overfitting, since the random draw applies uniformly across all rows in one submission.

### Differentiate beyond the current best
- Layer neighbor-transfer v2 and/or the PF-seed branch hedge on top of the GS1.30 base (not the plain no-override baseline) — these ideas were validated independently and haven't been tested in combination with GS1.30 yet.
- Try azimuth-based model splitting, still untested.
- Ensemble a genuinely independent signal (our own `triple-signal-beam-search-dual-pf-lightgbm.ipynb` or the DWT-based lineage) on top of whichever config wins, once we have a stable best.
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
