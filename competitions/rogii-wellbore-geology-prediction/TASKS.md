# Tasks

## Resume Here Tomorrow (2026-07-24+)

We used all 5 of 2026-07-23's submission slots; Kaggle's scoring was extremely slow that day (6+ hours pending, no scores landed before we stopped). **First thing tomorrow: check all 5 submission scores** — `kaggle competitions submissions rogii-wellbore-geology-prediction --format json` (note: use `--format json` and compare `ref` as an `int`, not a string — see the polling bugs noted in the session; the table view wraps long descriptions onto a second line and breaks naive parsing).

The 5 pending submissions form a deliberate sweep — read the scores together, not in isolation:

| Ref | Candidate | What it isolates |
|---|---|---|
| 54927668 | Contact-override (main/aggressive) | Full pipeline incl. same-well geological contact reconstruction |
| 54929149 | Model-package-only | Pure separate pretrained model (TabICL/model-package), nothing else |
| 54935192 | No-override blend | Full PF+learned blend, override forced off |
| 54935198 | Pure learned-branch | LightGBM/CatBoost booster ensemble alone |
| 54935199 | Pure PF/ridge anchor | Signal-processing/PF side alone, no ML |

Decision tree once scores are in:
- If **54927668 (override) scores near its expected ~7.3** (or better): the geological shortcut generalizes well from visible prefix to hidden tail. Lean into it; Phase 2 differentiation should focus on improving the contact-reconstruction step itself (candidate reference formations, MD-interpolation quality), not on more upstream blending.
- If **54927668 scores much worse than ~7.3** (e.g. back near double digits): the override overfit to the visible prefix and didn't generalize. Compare against 54935192 (no-override) — if that one scores better, the safer path forward is the blend without the override, and the "public-aggressive" same-well shortcut should probably be avoided or used only as a hedge pick, not our primary.
- Compare 54929149 vs. 54935198 vs. 54935199 to see which single signal family (model-package, learned GBM, or PF/ridge anchor) is strongest in isolation — that tells us where to invest further modeling effort in Phase 2.
- Whichever pair looks best (one aggressive, one robust) becomes our current best pair to refine toward the Phase 3 final-submission picks.

## Current Goal

**Catch-up strategy (as of 2026-07-23, ~13 days left, deadline 2026-08-05 23:59:00).** We're at rank 3504/5504 (score 11.107, from 2026-05-10) while the public meta has moved to a "target-free geosteering" pipeline (PF/beam/DTW + GBM residual + contact override, see `LEARNINGS.md`) clustering at 6-9. GPU is confirmed *not* required for this approach, so the current GPU-quota gap is not a blocker — work happens on CPU.

### Phase 0 (CPU): reproduce the shared baseline — DONE, awaiting scores
- Adapted `rogii-lb7295-public-rebuild.ipynb` (simple, 3 datasets) and `working-note-target-free-tvt-geosteering.ipynb` (advanced, 7 datasets) — both produced byte-identical `submission.csv` since the contact override dominates for our 3 test wells (see `LEARNINGS.md`).
- Built 3 additional single-change forks to isolate each pipeline component: no-override, pure-learned-branch, pure-PF-anchor (see `notebooks/working-note-*-ablation.ipynb` and their sidecar `.kernel-metadata.json` files — reusable templates for future ablations).
- All 5 submitted 2026-07-23; see "Resume Here Tomorrow" above for what to do with the scores.

### Phase 1 (once GPU refreshes): evaluate the learned-branch NN
- Check via CV whether the torch-based "learned branch" component adds anything over the LightGBM/CatBoost residual models before spending GPU time on it.
- If useful, retrain/finetune it; otherwise skip and keep the CPU-only stack.

### Phase 2 (days ~3-10): differentiate beyond the shared fork cluster
- Hundreds of teams are forking the *same* notebook with one config value changed — matching them gets to bronze/top25% but won't distinguish us. Real differentiation options:
  - Ensemble our own `triple-signal-beam-search-dual-pf-lightgbm.ipynb` (already dual-PF + LGBM) and the highest-voted alternative lineage (`9-251-...-dwt-based.ipynb`, DWT-based GR alignment + LGBM/CatBoost/hill-climbing) as independent signals on top of the shared PF/contact pipeline.
  - Spend modeling effort on the LightGBM/CatBoost residual layer specifically (our strongest existing skill) rather than re-tuning PF configs like everyone else.
  - Tune conservatively via CV/visible-prefix holdout; don't burn the 5/day submission budget on blind LB probing.

### Phase 3 (final ~days): stability and final-submission picks
- Select 2 Final Submissions (rule allows up to 2): one "aggressive"/public-LB-optimized pick (e.g. same-well contact override enabled) and one "conservative"/robustness pick (override disabled, conservative visible-prefix profile) as a hedge — the notebooks already expose these as named profiles.
- Leave 1-2 days of buffer before the deadline for submission failures or last-minute issues.

## Next Experiments (smaller/parallel items)

- Confirm which notebook actually produced our 11.107 best-score submission (currently inferred from timing only — check kernel version history, not just `kernels status`).
- Investigate the anomalous 11404.716 submission (2026-05-10 19:30:03, 12s after the good one) — likely a broken run; identify root cause before reusing that notebook.
- Move `../playground-series-s6e5/notebooks/rogii-automated-public-ensemble-v2.ipynb` into this workspace's `notebooks/` — it's a ROGII notebook misfiled under the playground-series-s6e5 folder.
- Review `rogii-lgbm-aug-online-training.ipynb` for feature ideas and leakage risks (may already be superseded by the PF/geosteering approach — check before investing time).
- Review `wellbore-geology-tcn.ipynb` for sequence modeling setup, grouped CV, and runtime feasibility on Kaggle.

## Done

- Initialized workspace from `https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction`.
- Fetched Kaggle description, evaluation, rules, and file listing into `references/`.
- Copied initial ROGII notebooks from `origin/main` into `notebooks/`.
- Confirmed Kaggle API connection works (access-token auth) and competition is already joined (`userHasEntered: True`).
- Confirmed 3 existing submissions; best public LB so far is 11.107.
- Pulled and reviewed 5 top public notebooks; identified the current dominant "target-free geosteering" technique and confirmed GPU is not required for it (see `LEARNINGS.md`).
- Downloaded full public leaderboard (5504 teams), computed our real rank (3504) and medal-zone score cutoffs.
- Confirmed via competition rules that public code/dataset sharing (the shared `koolbox`/`artifacts`/PF-config notebooks) is explicitly compliant, not a gray area.
- Decided validation protocol: `GroupKFold(well_id)` plus the competition-specific visible-prefix holdout trick.

## Questions

- Which notebook is the current best public/private baseline of *ours*? (Tentatively `triple-signal-beam-search-dual-pf-lightgbm.ipynb`, not confirmed.)
- Are type-well files always available for each horizontal well in train and test?
- Does the "learned branch" NN in the shared pipeline actually beat pure LightGBM/CatBoost residuals, or is it legacy/optional? (Check via CV once Phase 0 is running.)
- Exactly how does Kaggle split public/private here — same 3 wells by row, or something else? (Inferred, not confirmed; see `COMPETITION.md`.)
