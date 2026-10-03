# Tasks

## Current Goal

- Get a valid baseline `submission.csv` via a Kaggle notebook, then improve MRR@25.

## Next Experiments

- Spectral-library retrieval baseline (matchms cosine / modified cosine over train, aggregate across a molecule's spectra) — covers class 1.
- Candidate-set retrieval from PubChem/COCONUT by precursor mass/formula + learned spectrum->fingerprint/embedding (CSI:FingerID / MIST-style) re-ranking — covers class 2 (needs external DB attached as a Kaggle dataset, no internet).
- De novo generation (MSNovelist/DiffMS-style) for class 3.
- Domain adaptation using `enveda-np-examples` and timsTOF-only filtering.

## Done

- Workspace initialised; official pages saved to `references/`.
- Built `notebooks/casmi26-library-retrieval-baseline.ipynb` (class-1 library retrieval, mass shortlist + binned cosine, local holdout validation). Verified only on synthetic data; real-data run/timing and LB score still pending.

## Questions

- Accept competition rules on Kaggle (web UI) — required before data download / submission.
- Create the competition tutorial notebook (`notebooks/enveda-casmi26-molecule-id-mass-spectra-competition-tutorial.ipynb`) per workspace skill — not yet done.
- Which external DBs (PubChem subset, COCONUT) are available as Kaggle datasets for offline use?
