# Learnings

Capture durable information learned while working on this competition. This is for insights that should guide future modeling and prevent repeated mistakes.

## Data

- TBD

## Target And Metric

- TBD

## Validation

- TBD

## Leakage And Rules

- TBD

## Features

- TBD

## Models

- TBD

## Ensembling And Submission Behavior

- TBD

## Leaderboard Notes

- TBD

- `train.parquet` has NO `spectrum_id`/`molecule_id` columns (only test does); the notebook uses the global row index as spectrum id.
- Kaggle mounts the competition at `/kaggle/input/competitions/<slug>/` (found via recursive glob). Notebook needs `kernelspec` metadata or papermill fails.
- Visible test.parquet is drawn from train (400 mols, 1213 spectra), so its predictions are leaky; hidden test replaces it on rerun.
- Kaggle CLI (`uvx kaggle`): pages via `kaggle competitions pages list --content -c <slug>`; `init_competition_workspace.py` needs fixing for this.

- Library-retrieval baseline: local class-1 holdout 0.917 but public LB 0.140, so the hidden test is dominated by molecules without public spectra (classes 2/3). Biggest gains need candidate retrieval (PubChem/COCONUT) + spectrum->structure models, not better cosine.
- Submit code competitions via `KaggleApi().competition_submit_code(file_name='submission.csv', kernel='owner/slug', kernel_version=N)`; scoring reruns the notebook (~10 min).

- Offline RDKit: Kaggle image has no rdkit; attach `metric/rdkit-2026-3-3-wheel` (official, has cp313) and pip install --no-index from /kaggle/input.
- Useful public datasets: `dmitriigluzdov/casmi26-pubchem-popularity-prior` (`pool_popularity.csv`: 710k structures w/ smiles, mass, pop, NP flags), `dmitriigluzdov/casmi26-natural-product-knowledge-table`, pubchem tier / pretrained FP models listed in TASKS.md.
- Library cosine must be thresholded (relu(cos-0.7)): raw cosine of weak matches penalises true structures that have no library spectra (class 2). This alone took LB 0.162 -> 0.191.
- FP model (MLP, 1 Da frag+neutral-loss bins, 8 epochs, ~1M spectra) trains in ~5 min on a T4; held-out-structure MRR@25 0.54 inside a small (~110 cand) pool.
- Kernel `kernel_sources` lets an inference notebook read another kernel's /kaggle/working outputs (fpmodel.pt) — no dataset upload needed.

- Adding the PubChem tier (4000 most popular per window) lowered LB 0.191 -> 0.175: the weak FP model (class-2 proxy MRR 0.15 once the answer must come from the tier) can't discriminate among thousands of extra isomers, so extra candidates just push true pool answers down. A better FP model (pretrained public ones / ensembles) and/or a learned ranker must come *before* widening the pool; consider tier candidates only as a lower-priority slot (e.g. fill ranks after top-N from the pool).
- Local validation is only trustworthy for class 2 when the answer is removed from the candidate pool (see v3); v2's 0.577 class-2 proxy was far too optimistic.

- Pretrained public FPNet (transformer, 10,226-bit multi-FP, mass-window ranking loss) is far better than my 2048-bit MLP: LB 0.191 -> 0.292 just by swapping the encoder (candidates/pool unchanged). Don't train from scratch; compose public assets.
- Public asset layout: `ahmedberatozer/casmi26-v3-models` (code/casmi/{fpnet,chem}.py + fpnet_0/1.pt), `casmi26-v2-pool` (pool_fp.npy packed rows aligned with pool_popularity.csv `pool_row`, fp_bits.npy), score = F @ z (F: unpacked candidate bits, z: mean logits). Public checkpoints saw nearly all train structures; use `dmitriigluzdov/casmi26-fold-safe-fpnet` (split.parquet 'hold') for honest local validation.
- With the strong FPNet, the validation blend ranks fp-only best; library cosine and popularity add nothing on the held-out mix (but README says NP answers like popularity — validate on np fold).

- NP-panel tuning does not transfer: popularity (0.25) + LOTUS/NPAtlas flag (0.5) raised the local NP-panel MRR 0.52->0.75 but lowered LB 0.292->0.255. Hidden test molecules are mostly *not* famous (low PubChem popularity); do not tune priors on the panel. Fingerprint score alone is the safest. Gains must come from better spectrum models/ensembles (and maybe unpopular-compound-aware candidate sets), not priors.
- Leaderboard context (2026-10-04, 2,440 teams): median public 0.328, top 0.471; many teams sit at 0.33-0.44 by composing the public FPNet/ICEBERG/DreaMS pipelines. v4 (0.292) is below median — public pipelines use ensembles of several FPNets + polarity-merged spectra + rankers + formula/fragment features.

- Averaging 4 public FPNet checkpoints + merged-polarity view gave no gain (LB 0.290 vs 0.292). The remaining gap to the 0.33-0.47 field is not encoder averaging: public top pipelines add a LightGBM ranker over many candidate features (analog/derivation/fragment-coverage/FragNet/ICEBERG/DreaMS) and/or different candidate generation (PubChem tier with popularity). Next real step is either reproducing/adapting that public pipeline (`dmitriigluzdov/casmi-26-from-spectra-to-structures`, needs v4b models, glacier, iceberg etc.) or building our own ranker on honest held-out data.
- Workflow note: user wants commits pushed directly to `main` (PR #3 had already merged the session branch).

- Running the attributed public pipeline (FPNet + LightGBM rankers + PubChem tier channel + ICEBERG/GLACIER + engine fusion) gives LB 0.367 vs our best own 0.292 (+0.075) -> rank ~771/2466. Each submission costs ~6-7 h of scoring rerun, so iterate offline (cached candidate scores) and submit sparingly.
- When forking public notebooks: datasets mount under /kaggle/input/datasets/<owner>/<name>/, so hard-coded /kaggle/input/<name> paths break (patch with recursive glob); attach the official rdkit wheel for cp313.

- Panel replay (README of the NP benchmark): popularity prior is worth +0.44 MRR on the panel's PubChem channel (0.51 -> 0.95) because panel answers are famous; the same dataset cautions it will overstate the benefit for rarely studied compounds. Our LB evidence (v5: -0.04) agrees. Treat panel numbers as a ceiling, not a tuning target.
