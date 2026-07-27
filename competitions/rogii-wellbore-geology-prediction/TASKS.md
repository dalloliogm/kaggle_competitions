# Tasks

## Current Goal

**Catch-up strategy, updated 2026-07-25 (~11 days left, deadline 2026-08-05 23:59:00).** The "target-free geosteering" pipeline family has plateaued for us around ~7.1 with real execution instability (model-package-only: 3 submissions, 3 different outcomes — 7.097, 20.067, an exception; continuity-fade and capped-overlap ablations both landed at/near the same 7.1 baseline or failed outright — see `APPROACHES.md`). Forum research (see `LEARNINGS.md`) explains why and points to three concrete, never-tried levers that top teams (LB 5.7-6.0) actually use.

### Top priority: three concrete new levers from forum research

1. ~~**Test the `bimodal_guarded` profile preset**~~ — **done, 2026-07-26: scored 7.850, no better than the 7.102 baseline.** Guard fired for 0 of our 3 visible wells locally; inconclusive whether that's also true of the real hidden set or just noise (7.102/7.111/7.856/7.850 are all within 0.75 of each other, inside the demonstrated noise band). Not worth repeating — the magnitude of effect this lever could plausibly produce is small relative to our noise floor.
2. **Neighbor-well curve transfer** for wells with a close spatial neighbor — **v2 submitted, pending (`55022483`, 2026-07-27).** V1 threw grading exceptions twice because its 3-placeholder-well implementation did not scale to the roughly 52-well hidden grading set. V2 uses a 5.31 MB sampled index, k=1 queries, on-demand curve loading, a 600-ft gate, and fail-safe unchanged-base fallbacks. Its embedded 52-well benchmark completed 15,600 queries with 0 failures in 4.051 s; the full v2 stage took 13.374 s. This should finally test model quality rather than execution scalability.
3. **PF-seed posterior branch hedge — kernel v1 complete and validated; ready for explicit submission approval.** The new `dalloliogm/rogii-pf-seed-branch-hedge` v1 records all 128 PF seed trajectories, performs a likelihood-weighted two-mode split, and applies the public-lineage guard (minor mass ≥0.25, separation 4-40 ft, 60% midpoint move, ±2 ft cap) after neighbor-transfer v2. The visible run qualified one well (`00e12e8b`: minor mass 0.279, separation 29.44 ft), moving all 4,301 suffix rows by +2 ft; the other two wells were unchanged. Final audit: 14,151 ordered unique IDs, all finite, SHA-256 `3297365b...`. No hardcoded well IDs or leaderboard-tuned Q0522/A31/DYNQ offsets are present. Not yet submitted because two 2026-07-27 submissions are already pending and spending another slot requires explicit approval.
4. **Azimuth/drilling-direction-based model splitting** — wells drilled in opposite directions traverse layers in reverse order; reported to drop score significantly on its own. Mechanically simple if azimuth is derivable from trajectory columns.

Full rationale, forum thread IDs, and quotes are in `LEARNINGS.md` under "Where top-team scores actually come from."

**Lesson from lever #1**: this pipeline family's noise floor (~0.5-1.5 ft between otherwise-identical runs) makes single-submission validation of small-effect changes unreliable. Prioritize levers with large reported effect sizes (#2, #3) over further marginal flag tweaks, since a small change is hard to distinguish from noise without spending many submissions on repeats we don't have budget for.

### Reliability/randomness — understood, now just a practical constraint
- Score variance between identical resubmissions is confirmed, community-documented, unseeded PF-feature randomness (one competitor's unmodified notebook: 8.354/8.188/8.438 across 3 submissions) — not a bug in our code or a platform failure.
- The visible `test/` folder (3 wells) is placeholder data, replaced entirely at grading time with a real hidden set (~52 wells for public alone) — confirmed by the host. This is why overlap/override-based approaches never worked; **don't pursue that angle further, confirmed dead end.**
- Practical implication for Final Submissions: prefer a strategy of **resubmitting our best-understood config several times near the deadline and banking the best-scoring draw(s)** — a legitimate, community-validated tactic (forum: *"one could get top 5 on the public LB just submitting the best public notebook like 10 times"*), not overfitting, since the random draw applies uniformly across all rows in one submission.

### Differentiate beyond the current sweep
- The three levers above are the priority. Beyond those: ensemble a genuinely independent signal (our own `triple-signal-beam-search-dual-pf-lightgbm.ipynb` or the DWT-based lineage) on top of whichever config wins.
- The pure-learned-branch ablation (7.856, worse than the blend/model-package) shows the PF/ridge anchor and model-package both add real value beyond raw GBM boosters — keep those components even while adding the new levers.
- Given real reproducibility requires *repeated* submissions to average out noise, and we only get 5/day, budget for this explicitly rather than treating every slot as a new experiment.

### Final-submission picks
- Select 2 Final Submissions (rule allows up to 2). Given the confirmed randomness, prefer a strategy of **resubmitting our best-understood config several times near the deadline and picking the best-scoring draw(s)**, rather than picking based on whichever single historical score looks best.
- Leave 1-2 days of buffer before the deadline for submission failures or last-minute issues.

### Operational notes
- Continuity-fade v1 was deliberately resubmitted on 2026-07-26 using an otherwise-unused daily slot: submission `55011588` scored **7.112**, effectively identical to its original 7.111. The downloaded output was revalidated before submission (`id,tvt`, 14,151 unique rows, all finite, sample ID order confirmed).
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
