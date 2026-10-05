# Plan to the final deadline (written 2026-10-05; deadline 2026-12-14 23:59 UTC)

## Where we are
- Best: public-pipeline fork, **LB 0.367** (~rank 771/2466; median 0.328, top 0.471). Our own pipelines topped out at 0.292.
- Public notebooks already report **LB ~0.413-0.416** (e.g. `gengsr/casmi26-fusion-glacier-mh-lb-0-413`, `lehau007/casmi26-sota-v28-golden-tailfill-0416`, `wangpenghua/casmi26-v29-fusion-pop-glmh`, `imranarif536/casmi26-v44-pairtail-locked-top1`).
- Constraints: 5 submissions/day, **2 final submissions** selectable, 9 h notebook limit, scoring reruns the whole notebook (~7 h for the fork, so ~1 usable LB check per ~7 h per pipeline), Kaggle GPU quota ~30 h/week, team merger/entry deadline 2026-12-07.
- Lessons so far: priors tuned on the famous-compound NP panel hurt LB; averaging more FPNets gave nothing; local validation that keeps the answer in the pool is optimistic; encoder + LightGBM ranker + PubChem channel is what moves the score.

## Phase 1 (Oct 5 - Oct 12): catch up to the public frontier cheaply
1. Fork the best public ~0.41 notebooks (attributed, same pattern as our fork: glob asset paths, attach `metric/rdkit-2026-3-3-wheel`). Submit 1-2 of them to confirm LB 0.41 reproduces under our account. Record exact versions/datasets.
2. Diff the 0.37 fork vs 0.41 ones: what changed (GLACIER/ICEBERG fusion, tail fill, popularity rules, pair promotion). Write it down in LEARNINGS.md. This tells us which components carry the gain.
3. Read the competition discussion threads (data/metric quirks, hidden-test composition, runtime tips).
Exit criterion: a reproduced >=0.41 submission in hand = new floor.

## Phase 2 (Oct 12 - Nov 2): honest offline evaluation so we stop paying 7 h per idea
1. Build a replay harness on identity-disjoint folds (`casmi26-identity-disjoint-validation-folds`) + the cached NP panel tables, scoring each stage separately: candidate coverage (is the answer in the list?), ordering (rank when present), end-to-end MRR@25.
2. Report per novelty scenario (library-reference / in-pool-no-reference / PubChem-only) and weight them by what LB implies (our 0.14 library-only score suggests few class-1 molecules). Never tune on the NP panel alone.
3. Add timing budget tracking so the final notebook stays under ~7.5 h including scoring variance.
Exit criterion: offline MRR differences predict LB direction on the 5-6 submissions we already have (0.14, 0.19, 0.29, 0.29, 0.37, plus the 0.41 fork).

## Phase 3 (Nov 2 - Nov 25): the improvements most likely to add real signal (ranked)
A. **Encoder**: fine-tune/train an FPNet on timsTOF-matched data with the fold-safe training loop (`dmitriigluzdov/casmi26-fold-safe-fpnet`, ~5 h on a big GPU; more on T4, so budget GPU quota). Options: upweight `enveda-180` + `enveda-np-examples`, collision-energy-aware augmentation, mass-window hard negatives from the PubChem tier. Success = better held-out-identity top-1 than public FPNet A (0.42 on NP panel, 0.68 on identities).
B. **Ranker**: retrain/extend the LightGBM ranker on honest held-out candidate tables (identity-disjoint), adding features the encoder gap suggests (fragment-coverage, formula agreement, ICEBERG/GLACIER predicted-spectrum similarity for isomers).
C. **Candidate coverage**: audit where answers are missing (class-3 / not in PubChem); try analog generation from near library neighbours (public pipelines have an analog generator) and check the gain offline first.
D. **Ensembling at the list level**: rank-fuse the 2-3 strongest *different* pipelines (not near-duplicates). Only if offline replay shows >0.005 gain.
Each candidate must beat the floor offline before consuming an LB slot.

## Phase 4 (Nov 25 - Dec 5): integrate and de-risk
- Merge winners into one notebook; dry-run end-to-end on visible test, check runtime <=7.5 h, memory, determinism, valid format (25 SMILES max, unique, no nulls).
- 2-3 LB checks max (one per ~7 h run), each logged with a hypothesis.
- Decide on team merger (deadline 12-07) if useful.

## Phase 5 (Dec 5 - Dec 14): freeze
- Select 2 Final Submissions on Kaggle (manual step): (1) the best LB, (2) a different-risk variant (the best pipeline not tuned to public LB, e.g. best offline-honest model). Public LB has ~1.5k test spectra; the private split can shuffle ranks.
- Last 48 h: no new code; verify the selected kernels still run (dataset versions pinned), reproduce results.
- If winning-range: prize requires MIT/OSI release of code+model (rules) — keep notebooks clean and attributed.

## Cadence / housekeeping
- Weekly: update TASKS.md/LEARNINGS.md, leaderboard snapshot (kaggle competitions leaderboard --download), commit to `main`.
- Never privately share code outside the team (rules); public sharing only on competition forum/notebooks.
- Attribution: forked notebooks keep a note + original licence (Apache 2.0 for the v4g-v4m lineage).
