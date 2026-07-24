# Notes

Quick facts and loose/not-yet-actioned ideas. For validated technical understanding see `LEARNINGS.md`; for the current plan see `TASKS.md`; for the experiment log see `APPROACHES.md`. This file is deliberately lighter-weight than those — don't duplicate them here, just point to them.

## Quick Facts

- Deadline: 2026-08-05 23:59:00. Category: Featured. Reward: $50,000 (top 4 only — see `COMPETITION.md` for why the cash prize isn't realistic from our current rank, medal is the real target).
- Metric: RMSE, row-weighted. Only 3 test wells, 14,151 hidden rows total — see `LEARNINGS.md` "Data" section for the full structural breakdown (prefix/tail split, train-only geology columns, etc.).
- As of 2026-07-24: current best public score 7.097 (rank ~1317/5572, top 23.6%), up from a stale 11.107 (rank ~3504) that predated a ~2.5 month public-meta shift. See `APPROACHES.md` for the full submission history.

## Not Yet Actioned / Loose Ideas

- **Tutorial notebook**: still owed (requested 2026-07-24, got sidetracked mid-build by the train/test overlap discovery — see `LEARNINGS.md`). Should walk through the actual modeling problem (GR-to-typewell alignment, PF/state-space tracking, formation-surface prior, learned residuals, model-package, guarded override) using real sample data, and include the overlap-discovery episode as a worked example of verifying an assumption empirically rather than trusting a public notebook's framing.
- Visualizing a train well's GR curve against its typewell's GR curve (the "stratigraphic barcode" matching idea) would make the core technique much more concrete than prose — good candidate for the tutorial notebook.
- Haven't yet dug into *why* the guarded contact override underperforms a plain direct lookup by exactly as little as it does (mean 0.004 ft apart per `APPROACHES.md`) — since both land close to the same real score (9.565-ish), understanding the override's specific formula might not be worth more time versus just treating "same-well override family" as a dead end (see Backlog in `APPROACHES.md`).
- Old model ideas from before the 2026-07-23 catch-up (starter NN, TCN, LightGBM-aug-online notebooks) are superseded — they scored 11-16 vs. the current 7.097 best. Not worth revisiting unless a specific feature idea from them is worth grafting onto the current best pipeline.

## Useful References

- Competition URL: https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction
- Fetched Kaggle metadata and leaderboard snapshots are under `references/`.
- Reusable ablation-notebook templates (single-change forks of the shared pipeline) are in `notebooks/working-note-*-ablation.ipynb` plus their sidecar `.kernel-metadata.json` files.
