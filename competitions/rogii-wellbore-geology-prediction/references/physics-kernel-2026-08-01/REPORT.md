# ROGII Physics kernel: static lineage and reuse assessment

Date: 2026-08-01

Safety boundary: public source was downloaded and inspected statically. No third-party notebook code was executed, no kernel was pushed, and no submission was made.

## Identification

- Public kernel: [`evgendvorkin/rogii-physics-lb-7-872-v48`](https://www.kaggle.com/code/evgendvorkin/rogii-physics-lb-7-872-v48)
- User submission: `55050805`, created `2026-07-28T09:16:15.837Z`, description `Notebook ROGGI Physics LB 7.872 v48! | Version 1`, public score `6.505`.
- The title's `v48` is stale lineage text, not the submitted fork's upstream version number. Upstream v48 is script version/session `337187628`, created 2026-07-22, and scored `7.872`.
- The latest upstream source available before submission `55050805` was v65, script version/session `338370315`, created `2026-07-27T17:43:52.423Z`, and scored `6.400`; upstream v66 was not created until after the user submission. Therefore the user's Kaggle `Version 1` was most likely a fork of upstream v65. This is a timestamp/title inference because the authenticated competition submission ledger does not expose the source kernel ref.
- Upstream metadata currently records v59 as the kernel's best submission at `6.361`; later versions range widely, consistent with changes and/or grading variance rather than a stable independent 6.36 method.

Archived evidence:

- `v048__scriptVersionId-337187628/source.ipynb`: literal upstream v48.
- `v065__scriptVersionId-338370315/source.ipynb`: likely source lineage for submission `55050805`.
- `rogii-physics-lb-7-872-v48.ipynb` and `kernel-metadata.json`: current public source and attached-source metadata as of 2026-08-01.
- `v001__scriptVersionId-317028471/`: upstream v1, retained only to disambiguate it from the user's fork Version 1; it is an unrelated early baseline.

## What the relevant pipeline does

The likely v65 source is the same broad public-frontier pipeline as our clean GS1.30 notebook:

1. Builds typewell/formation-surface and trajectory features.
2. Runs ANCC/Z particle filters, beam search, NCC alignment, and a 128-seed likelihood-weighted PF tracker.
3. Runs LightGBM/CatBoost or loads attached model/precomputed artifacts when available.
4. Blends the learned prediction with SP45/PF candidates and smooths projected stratigraphic level `T + Z`.
5. Applies a same-well train/test contact reconstruction only when it passes a visible-prefix RMSE gate.
6. Runs visible-prefix pseudo-holdout selection among polynomial, surface/contact, and PF candidates.
7. Runs a PF seed-branch hedge, then an active Q0522 mutation that adds `0.522 ft` to all 4,301 rows of well `00e12e8b` after verifying an exact expected artifact/hash.
8. Audits `submission.csv` for exact columns, row count/order, uniqueness, and finite values.

Its attached metadata lists seven auxiliary datasets (Koolbox, model packages, v10 artifacts, Claude models, TabICL mirror, and Ravaghi artifacts). The source can load id-exact precomputed submissions or model artifacts from attached inputs. Those fallbacks are operationally convenient but make provenance and behavior dependent on the exact attached versions.

Runtime is dominated by PF work and scales approximately with wells x hidden rows x seeds x particles, plus three masked-prefix calibrations per well. The public/user reruns completed, but this remains hidden-scale sensitive and is not an attractive second full pipeline to add beside GS1.30.

## Independence test

It is **not genuinely independent from clean GS1.30**.

- Comparing likely-source v65 with `rogii-frontier-lab-clean.ipynb` found all 104 clean top-level functions in v65.
- 102 of those 104 functions have exactly identical normalized Python ASTs.
- The only changed shared functions are `lik_pf` and `_gold_alpha`, which are precisely the GS1.30 likelihood-scale/overlay adjustment area.
- v65 additionally contains the active Q0522 mutation and three small Q0522 audit helpers; the clean notebook removed that scoring mutation.

For historical context, literal upstream v48 was a smaller pure-physics precursor, but even it shares 29 named functions with clean GS1.30 and 22 are exact AST matches, including the PF/beam kernels and main tracking functions.

## Risk assessment

- **Q0522 / leaderboard tuning: high risk.** The active cell hard-codes one public well, 4,301 affected rows, expected hash/statistics, an earlier public score, and a `+0.522 ft` adjustment. Do not reuse it.
- **Same-well overlap/contact override: moderate-to-high robustness risk.** It uses public train truth only after a visible-prefix check, so it is not direct hidden-target access, but it exploits train/test well identity and MD overlap and may fail under a changed hidden rerun.
- **Precomputed artifact risk: moderate.** Id-order checks prevent schema mismatch, but attached CSV/model provenance controls what the learned branch actually is.
- **Placeholder/no-op risk: moderate.** Surface candidates silently disappear when `_FI`/`_DI` or artifacts are unavailable; broad exception fallbacks can leave only the PF anchor while the notebook still completes.
- **Runtime risk: moderate.** The nested PF and masked-prefix loops are expensive and scale with the hidden test set.

## Recommendation

Do **not** spend a slot on this notebook and do **not** ensemble it with clean GS1.30. The apparent `6.505` partner is effectively the same lineage, not a diverse model; blending would mostly average near-duplicates while reintroducing Q0522/overlap risk.

There is no clean layer here that our notebook lacks. The useful conclusion is negative but actionable: close this lead and prioritize a genuinely independent direction, such as direction/azimuth normalization or a separately validated model family. If we ever mine this lineage further, restrict it to ablations of the two true differences (`lik_pf` scaling and `_gold_alpha`) on the Q0522-free clean base, not wholesale copying or output blending.
