# Tasks

## Current Goal

**Catch-up strategy, updated 2026-07-28 evening (~8 days left, deadline 2026-08-05 23:59:00).** Major pivot on 2026-07-27: `dalloliogm/rogii-public-score-frontier-lab-visuals` (GS1.30) scored 6.474, our best result by far (previous best ~7.1). Full writeup in `LEARNINGS.md` under "BREAKTHROUGH".

**2026-07-28 evening update — two important developments:**
- **Reproducibility is now confirmed**: 4 draws of the GS1.30 recipe (original + clean fork) scored 6.474, 6.562, 6.558, and one more pending (`55055548`) — a real, fairly tight band (~0.09 spread), genuinely stable (unlike the earlier flaky model-package-only config).
- **But the leaderboard tightened while we were confirming it.** A fresh pull (5857 teams, up from 5572) shows bronze now needs **≤6.453** (was ≤6.463) and silver **≤6.415** (was ≤6.427) — our best-ever draw (6.474) no longer clears bronze, and our rank slipped from top 12.4% to top 13.9%. **The "bank the best draw" strategy alone is no longer sufficient — we need genuine improvement, not just a lucky resubmission.** See `APPROACHES.md` 2026-07-28 leaderboard-tightening entry.
- Also spotted a different, independent public notebook ("ROGII Physics LB 7.872 v48!") scoring **6.505** (`55050805`) — same ballpark as GS1.30 but a different pipeline; worth pulling and considering as an ensemble partner.
- The PF-seed branch hedge (on top of neighbor-transfer v2) scored **13.011 — a bad regression** (real completed score, not an exception). Combined with neighbor-transfer v2 alone throwing an exception once already, that whole lineage looks unreliable/harmful and is deprioritized.

### Immediate priorities
1. ~~**Confirm 6.474 is reproducible**~~ — done: confirmed real and fairly stable (6.474/6.562/6.558, 4th draw pending). Stop spending slots purely on repro draws of the exact same recipe — the gap to bronze (≥0.02 ft on the best draw) is now bigger than the observed reproducibility noise, so more draws of the identical config are unlikely to clear it on their own.
2. ~~**Do not submit any version of `rogii-public-score-frontier-lab-visuals` that includes the "Q0522" cell**~~ — done: built `notebooks/rogii-frontier-lab-clean.ipynb` (Q0522 removed entirely), pushed as `dalloliogm/rogii-frontier-lab-clean-gs1-30-no-q0522` v1, confirmed scoring in the same band (6.558). This is now the safe reference point going forward — **use this notebook/kernel, not `rogii-public-score-frontier-lab-visuals`, for any further layering (neighbor-transfer, azimuth split, etc.)**. Still flag the Q0522 public-LB-probing concern to whoever is working on the other machine if still active.
3. **Find genuine improvement, not just draws, to close the ~0.02-0.1 ft gap to the new bronze line (≤6.453)**. Candidates, roughly in priority order:
   - Pull and inspect the independent "ROGII Physics LB 7.872 v48!" notebook (6.505) and test ensembling it with the GS1.30/clean-fork base.
   - Azimuth/drilling-direction-based model splitting — still untested by anyone.
   - Neighbor-transfer v2 layered on the GS1.30/clean base specifically (not the plain no-override baseline it was built against) — deprioritized below the other two given its own reliability track record, but still an open, unstacked combination worth one careful try.

### Reliability/randomness — understood, now just a practical constraint
- Score variance between identical resubmissions is confirmed, community-documented, unseeded PF-feature randomness (one competitor's unmodified notebook: 8.354/8.188/8.438 across 3 submissions) — not a bug in our code or a platform failure. Some configs are more stable than others in practice: continuity-fade reproduced almost exactly (7.111 → 7.112) on a repeat submission, unlike model-package-only (7.097 → 20.067 → exception).
- The visible `test/` folder (3 wells) is placeholder data, replaced entirely at grading time with a real hidden set (~52 wells for public alone) — confirmed by the host. This is why overlap/override-based approaches never worked, and why Q0522 (above) will fail. **Don't pursue hardcoded-to-visible-data approaches — confirmed dead end.**
- Practical implication for Final Submissions: prefer a strategy of **resubmitting our best-understood config several times near the deadline and banking the best-scoring draw(s)** — a legitimate, community-validated tactic (forum: *"one could get top 5 on the public LB just submitting the best public notebook like 10 times"*), not overfitting, since the random draw applies uniformly across all rows in one submission.

### Differentiate beyond the current best
- The PF-seed branch hedge is now a **known regression** (13.011) — don't layer it on anything further without first understanding why. Neighbor-transfer v2 alone (not combined with the hedge) is still an open, untested-on-GS1.30 combination.
- Pull and inspect "ROGII Physics LB 7.872 v48!" (scored 6.505 independently) as a possible ensemble partner for GS1.30/clean-fork — new lead as of 2026-07-28 evening, likely higher priority than the levers below given it's already confirmed to score in-band.
- Try azimuth-based model splitting, still untested.
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
