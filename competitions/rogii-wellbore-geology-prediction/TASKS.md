# Tasks

## Current Goal

**Catch-up strategy (as of 2026-07-23, ~13 days left, deadline 2026-08-05 23:59:00).** We're at rank 3504/5504 (score 11.107, from 2026-05-10) while the public meta has moved to a "target-free geosteering" pipeline (PF/beam/DTW + GBM residual + contact override, see `LEARNINGS.md`) clustering at 6-9. GPU is confirmed *not* required for this approach, so the current GPU-quota gap (refreshes in ~2 days) is not a blocker — work starts now on CPU.

### Phase 0 (CPU, now → GPU refresh): reproduce the shared baseline
- Adapt/fork one of the 5 pulled public notebooks in `notebooks/` (`working-note-target-free-tvt-geosteering.ipynb` or `top-pf-config-branch-conservative-visuals.ipynb` are the most complete) into a runnable submission on Kaggle.
- Install `koolbox` (e.g. `phongnguyn23021656/koolbox-offline`) and mount `ravaghi/wellbore-geology-prediction-artifacts` as datasets.
- Get one submission in to confirm we land in the expected ~6-9 public-score range. This alone should be a huge rank jump (top-25%/bronze territory) — see medal math in `COMPETITION.md`.
- Set up local validation using the visible-prefix holdout mechanism (hide suffixes of known `TVT_input`, score candidates on that) instead of blind public-LB probing, since submissions are capped at 5/day.

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
