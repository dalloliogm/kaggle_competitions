# Tasks

## Current Goal

- Get a valid baseline `submission.csv` via a Kaggle notebook, then improve MRR@25.

## Next Experiments

- Spectral-library retrieval baseline (matchms cosine / modified cosine over train, aggregate across a molecule's spectra) — covers class 1.
- Candidate-set retrieval from PubChem/COCONUT by precursor mass/formula + learned spectrum->fingerprint/embedding (CSI:FingerID / MIST-style) re-ranking — covers class 2 (needs external DB attached as a Kaggle dataset, no internet).
- De novo generation (MSNovelist/DiffMS-style) for class 3.
- Domain adaptation using `enveda-np-examples` and timsTOF-only filtering.

## Done

- Reviewed the NP panel benchmark replay (`casmi26-natural-product-panel-benchmark`): the forked pipeline already uses its best merge rule (promote best PubChem proposal when S>6 and pop>=5; prior 0.25). The dataset itself warns the panel is a famous-compound proxy (249/250 in COCONUT, optimistic pool scenarios), and our own v5 showed panel-tuned popularity hurting LB. No further replay-based changes made. Decision (2026-10-05): stop experimenting; best submission = public-pipeline fork, LB 0.367. Further submissions cost ~7h of scoring each.

- **Fork of public pipeline** (`casmi26-public-pipeline-fork` v3, attributed copy of dmitriigluzdov's notebook; builds on ahmedberatozer v4g-v4m, Apache 2.0): **LB 0.367** (rank ~771/2466, median 0.328, top 0.471). Needed `metric/rdkit-2026-3-3-wheel` + glob for the asset path (datasets mount under /kaggle/input/datasets/...). Notebook run ~5 h on T4, scoring rerun ~6-7 h each submission.

- v6 (`casmi26-candidates-fpnet-ensemble-v6`): 4 FPNet checkpoints (v3 fpnet_0/1 + v4b fe_A/fe_B) averaged, polarity-merged + per-spectrum views, ce_n fix, fp-only blend. Fold0 val unchanged (0.863 vs 0.865); **LB 0.290 ~ v4 0.292** -> more FPNets of the same family add nothing. Best stays v4 (0.292).

- v5 (`casmi26-candidates-fpnet-v5-np`): blend re-tuned on NP panel (258 held-out NP structures) + general + class1 with narrow NP flag; chosen pop=0.25, nn=0.5, lib=0. Local NP panel MRR 0.518 -> 0.748, but **LB 0.255 < v4's 0.292**. The NP panel (famous compounds, median pop ~13) is NOT representative of the hidden test; the popularity prior hurts there. Keep v4 (fp-only) as best. Leaderboard (2026-10-04): v4 0.292 = rank 1404/2440, median 0.328, top 0.471.

- v4 (`casmi26-candidates-fpnet-v4`, GPU T4, ~10 min): replaced my MLP with the public pretrained FPNet transformer (`ahmedberatozer/casmi26-v3-models` fpnet_0+fpnet_1 for test; fold-safe `fpnet_fold0.pt` for honest validation), candidate fingerprints from `casmi26-v2-pool/pool_fp.npy`. Local mix 0.865 (c1 0.967 inflated / c2 0.821); **LB 0.292** (v2 0.191, v3 0.175, baseline 0.140). Best submission so far. Blend chose fp only (lib=0,pop=0,np=0) on val.

- v3 (`casmi26-candidates-pubchem-v3`): adds ±10 ppm window of the 105.9M PubChem tier (top 4000 by popularity) to the candidates. Honest local class-2 proxy (val structures removed from pool, tier-only) = 0.151, mix 0.368; **LB 0.175 < v2's 0.191** -> still best submission is v2. Runtime ~25 min.

- v2 pipeline (notebooks `casmi26-fp-model-train` [GPU, ~10 min] -> `casmi26-candidates-fp-v2` [CPU, ~12 min]): mass-window candidates from pool_popularity (710k) + NP table, spectrum->Morgan-FP MLP, lib cosine (thresholded), blend weights tuned on local mix. LB: 0.162 (first blend) -> **0.191** (lib threshold 0.7, kernel v2). Local mix 0.657 (class1 0.846 / class2-proxy 0.577) is optimistic: class-2 proxy candidates are always in the pool.

- Workspace initialised; official pages saved to `references/`.
- Built `notebooks/casmi26-library-retrieval-baseline.ipynb` (class-1 library retrieval, mass shortlist + binned cosine, local holdout validation). Ran on Kaggle (kernel `dalloliogm/casmi26-library-retrieval-baseline` v3, CPU, ~6 min total): local class-1 holdout MRR@25 = 0.917 (100 mols, top1 0.87). Submitted (ref 56796436): public LB MRR@25 = 0.140 (vs 0.917 local class-1 holdout -> most hidden molecules are class 2/3).

## Next (ideas, in priority order)

- (new) v4 tuned blend picked fp-only; re-tune with an NP-focused validation (README of fold-safe-fpnet: popularity/NP priors help natural products at weight ~0.15-0.25 but hurt others) using the 265 `np` fold structures in split.parquet.
- (new) Ensemble more FPNets (v4b `casmi26-v4b-models`, `prvsiyan/casmi26-fp-models-v4`, DreaMS-based `hengck23-dreams-enveda-casmi26`); merge spectra per polarity like the public pipeline (z = 0.5*(mean per-spectrum + merged)).
- (new) Library match: keep as a *rerank boost* only for strong cosine (threshold tuned), since FPNet already uses everything.
- Re-try PubChem-tier candidates only now that the FP model is strong (they need on-the-fly raw fingerprints: ~1.5 ms each).

- Bigger candidate pool: PubChem tier (105.9M structures, mass-sorted; datasets `ahmedberatozer/casmi26-pubchem-tier`, popularity arrays in `dmitriigluzdov/casmi26-pubchem-popularity-prior`). Real class-2 answers are mostly outside the 730k pool.
- Stronger FP model: public pretrained ones exist (`prvsiyan/casmi26-fp-models-v4`, `ahmedberatozer/casmi26-v4b-models`, `dmitriigluzdov/casmi26-fold-safe-fpnet`); also ensembles, collision-energy/polarity merging per molecule, bigger/longer training.
- Learned ranker (LightGBM) over lib/fp/pop/np features instead of hand-grid weights.
- Class 3: de novo / analog propagation (see public `prvsiyan` pipelines).

## Questions

- Accept competition rules on Kaggle (web UI) — required before data download / submission.
- Create the competition tutorial notebook (`notebooks/enveda-casmi26-molecule-id-mass-spectra-competition-tutorial.ipynb`) per workspace skill — not yet done.
- Which external DBs (PubChem subset, COCONUT) are available as Kaggle datasets for offline use?
