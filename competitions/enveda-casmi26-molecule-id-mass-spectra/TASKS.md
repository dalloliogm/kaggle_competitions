# Tasks

## Current Goal

- Get a valid baseline `submission.csv` via a Kaggle notebook, then improve MRR@25.

## Next Experiments

- Spectral-library retrieval baseline (matchms cosine / modified cosine over train, aggregate across a molecule's spectra) — covers class 1.
- Candidate-set retrieval from PubChem/COCONUT by precursor mass/formula + learned spectrum->fingerprint/embedding (CSI:FingerID / MIST-style) re-ranking — covers class 2 (needs external DB attached as a Kaggle dataset, no internet).
- De novo generation (MSNovelist/DiffMS-style) for class 3.
- Domain adaptation using `enveda-np-examples` and timsTOF-only filtering.

## Done

- v2 pipeline (notebooks `casmi26-fp-model-train` [GPU, ~10 min] -> `casmi26-candidates-fp-v2` [CPU, ~12 min]): mass-window candidates from pool_popularity (710k) + NP table, spectrum->Morgan-FP MLP, lib cosine (thresholded), blend weights tuned on local mix. LB: 0.162 (first blend) -> **0.191** (lib threshold 0.7, kernel v2). Local mix 0.657 (class1 0.846 / class2-proxy 0.577) is optimistic: class-2 proxy candidates are always in the pool.

- Workspace initialised; official pages saved to `references/`.
- Built `notebooks/casmi26-library-retrieval-baseline.ipynb` (class-1 library retrieval, mass shortlist + binned cosine, local holdout validation). Ran on Kaggle (kernel `dalloliogm/casmi26-library-retrieval-baseline` v3, CPU, ~6 min total): local class-1 holdout MRR@25 = 0.917 (100 mols, top1 0.87). Submitted (ref 56796436): public LB MRR@25 = 0.140 (vs 0.917 local class-1 holdout -> most hidden molecules are class 2/3).

## Next (ideas, in priority order)

- Bigger candidate pool: PubChem tier (105.9M structures, mass-sorted; datasets `ahmedberatozer/casmi26-pubchem-tier`, popularity arrays in `dmitriigluzdov/casmi26-pubchem-popularity-prior`). Real class-2 answers are mostly outside the 730k pool.
- Stronger FP model: public pretrained ones exist (`prvsiyan/casmi26-fp-models-v4`, `ahmedberatozer/casmi26-v4b-models`, `dmitriigluzdov/casmi26-fold-safe-fpnet`); also ensembles, collision-energy/polarity merging per molecule, bigger/longer training.
- Learned ranker (LightGBM) over lib/fp/pop/np features instead of hand-grid weights.
- Class 3: de novo / analog propagation (see public `prvsiyan` pipelines).

## Questions

- Accept competition rules on Kaggle (web UI) — required before data download / submission.
- Create the competition tutorial notebook (`notebooks/enveda-casmi26-molecule-id-mass-spectra-competition-tutorial.ipynb`) per workspace skill — not yet done.
- Which external DBs (PubChem subset, COCONUT) are available as Kaggle datasets for offline use?
