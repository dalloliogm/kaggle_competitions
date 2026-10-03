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
