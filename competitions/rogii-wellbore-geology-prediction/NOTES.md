# Notes

Quick facts and loose/not-yet-actioned ideas. For validated technical understanding see `LEARNINGS.md`; for the current plan see `TASKS.md`; for the experiment log see `APPROACHES.md`. This file is deliberately lighter-weight than those — don't duplicate them here, just point to them.

## Quick Facts

- Deadline: 2026-08-05 23:59:00. Category: Featured. Reward: $50,000 (top 4 only — see `COMPETITION.md` for why the cash prize isn't realistic from our current rank, medal is the real target).
- Metric: RMSE, row-weighted. Only 3 test wells, 14,151 hidden rows total — see `LEARNINGS.md` "Data" section for the full structural breakdown (prefix/tail split, train-only geology columns, etc.).
- As of 2026-07-28: **best public score 6.474 (GS1.30), reproducibility-confirmed** (second draw 6.562; both in a tight 6.4-6.6 band). Fresh LB (5822 teams): bronze ≤6.457 — our 6.474 draw is rank ~771 (top 13.2%), **0.017 outside bronze**. Strategy: resubmit the clean GS1.30 kernel (`rogii-frontier-lab-clean-gs1-30-no-q0522`) to bank draws and catch one ≤6.457. See `APPROACHES.md`.
- 2026-07-28: checked the "physics" notebook (`evgendvorkin/roggi-physics-lb-7-872-v48`) — it's the SAME `vp_balanced_modelpkg_005` pipeline we run (gs ×1.6 vs our ×1.3). Submitted as `55050805` and **scored 6.505 (did NOT crash — my Q0522-will-throw prediction was wrong, see `APPROACHES.md`)**. No better than our clean draws; nothing architecturally new. Prefer the clean kernel for Final Submissions (LB-probing concern in the Q0522 shift).
- (Historical) 2026-07-24: 7.097 (rank ~1317/5572), up from a stale 11.107 (rank ~3504) that predated a ~2.5 month public-meta shift.

## Not Yet Actioned / Loose Ideas

- **Tutorial notebook**: still owed (requested 2026-07-24, got sidetracked mid-build by the train/test overlap discovery — see `LEARNINGS.md`). Should walk through the actual modeling problem (GR-to-typewell alignment, PF/state-space tracking, formation-surface prior, learned residuals, model-package, guarded override) using real sample data, and include the overlap-discovery episode as a worked example of verifying an assumption empirically rather than trusting a public notebook's framing.
- Visualizing a train well's GR curve against its typewell's GR curve (the "stratigraphic barcode" matching idea) would make the core technique much more concrete than prose — good candidate for the tutorial notebook.
- Haven't yet dug into *why* the guarded contact override underperforms a plain direct lookup by exactly as little as it does (mean 0.004 ft apart per `APPROACHES.md`) — since both land close to the same real score (9.565-ish), understanding the override's specific formula might not be worth more time versus just treating "same-well override family" as a dead end (see Backlog in `APPROACHES.md`).
- Old model ideas from before the 2026-07-23 catch-up (starter NN, TCN, LightGBM-aug-online notebooks) are superseded — they scored 11-16 vs. the current 7.097 best. Not worth revisiting unless a specific feature idea from them is worth grafting onto the current best pipeline.

## Useful References

- Competition URL: https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction
- Fetched Kaggle metadata and leaderboard snapshots are under `references/`.
- Reusable ablation-notebook templates (single-change forks of the shared pipeline) are in `notebooks/working-note-*-ablation.ipynb` plus their sidecar `.kernel-metadata.json` files.
