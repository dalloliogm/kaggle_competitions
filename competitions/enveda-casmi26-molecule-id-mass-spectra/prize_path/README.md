# Prize path (permissively licensed, self-trained)

Goal: a leaderboard-competitive submission that is *eligible to win*: no third-party weights or derived tables with non-commercial licences.

Hosts' rules (forum, 2026-10): solutions built on non-commercial data/tools are ineligible to win; open-source models trained on `train.parquet` are fair game; DreaMS weights (CC BY 4.0) allowed; COCONUT is CC BY 4.0; PubChem is public-domain data.

| Asset | Source / licence | Used? |
|---|---|---|
| `train.parquet` | competition data | yes (training + library) |
| COCONUT structures | CC BY 4.0 (`aidensong123/casmi26-coconut-202609`, attribution file kept) | yes (candidate pool) |
| RDKit 2026.03.3 wheel | BSD (`metric/rdkit-2026-3-3-wheel`) | yes |
| Spectrum encoder + weights | **ours**, trained on train.parquet | yes |
| ahmedberatozer/* models, pools, ICEBERG/GLACIER | "Other / non-commercial" | **no** |
| PubChem popularity / tier | PubChem (public domain) derivatives by third parties | not yet; candidate for later (check licence) |

## Pieces
- `own_fpnet_train.py` — GPU script kernel `dalloliogm/casmi26-own-fpnet-train`: builds pool (train structures U COCONUT) with own multi-fingerprint, trains a transformer spectrum->fingerprint model with a +-10 ppm mass-window ranking loss, hold-out by md5(inchikey14)%100<3 (identity-disjoint). Outputs `pool.npz`, `spectra.npz`, `ownfp.pt` (resumable).
- `own-fpnet-infer.ipynb` — submission notebook (kernel sources: the training kernel): FPNet score + thresholded library cosine.

## Roadmap
1. First 6.5 h training run -> read held-out-identity MRR@25 in the log (benchmark: public FPNet A ~0.68 top-1 / 0.79 MRR on held-out identities within the 710k pool).
2. Continue training (resume from own output via `kernel_sources`) for more steps; add spectrum merging and collision-energy augmentation.
3. Add candidates beyond the pool (PubChem structures, public domain) and a popularity prior once licences are confirmed; own LightGBM ranker.
4. Compare to the public-pipeline fork (0.37 LB); keep the fork as non-prize fallback for the 2nd final submission.

## Run log
- **Run 1** (`casmi26-own-fpnet-train` v1, 2026-10-08, T4, 7.7 h): pool 729,387 structures (275,809 train + 453,581 COCONUT-only), 6,901 bits, 2.53 M spectra, 27 M-param model. **Only ~1,069 optimiser steps** because of two bugs: (a) `np.load(...npz)` returns a lazy NpzFile that re-reads the 2 GB array on every access (about 1.7 s/step), (b) the 30-min evaluation took >30 min so it re-triggered every step. Even so, held-out-identity MRR@25 inside the +-10 ppm pool window = **0.40** (1.5k structures; 0.369 on a different 1.5k subset at the end) - public FPNet A reaches ~0.79 after 83k steps, so there is a lot of headroom.
- **Run 2** (`casmi26-own-fpnet-train2`, fixed: arrays loaded once, eval every 30 min with 400 structures, cached pool/spectra/ckpt reused from run 1 via kernel_sources, LR cosine by elapsed time, 7.5 h budget): finished 2026-10-09: **100,753 steps in 7.5 h** (0.27 s/step). Held-out-identity MRR@25 (400 structures) plateaued at ~0.60 from step ~8k while train loss kept falling (rank loss 2.4 -> 0.4), i.e. memorising training structures; final 1,500-structure eval = **0.701**. Public FPNet A reference: 0.79 (with merged spectra, 83k steps, different held-out). Next levers: regularisation / stronger augmentation, spectrum merging, larger hold-out-aware early stopping, more diverse negatives.

## Results
- **LB 0.261** (ref 56981486): `casmi26-own-fpnet-infer` v1 = own FPNet (run 2 weights, step 100,753) + pool (train U COCONUT) + fingerprint score only (val chose lib bonus off). Local held-out-identity proxies: class-2-like MRR 0.803, class-1-like 0.977 (inflated). Comparable to our earlier public-weights version (0.292) and below the non-prize public-pipeline fork (0.37-0.371), but fully self-trained and licence-clean (no ahmedberatozer/* assets).
- Gap analysis to the fork: (1) no PubChem candidate channel (answers outside train U COCONUT are unreachable), (2) no popularity prior / NP flags, (3) no spectrum merging / ensembling, (4) model overfits (held-out plateau ~0.60 on the hardest 400 from step 8k), (5) no ICEBERG/GLACIER-style isomer re-scoring or LightGBM ranker.

## 2026-10-10: regularised retrain + PubChem channel
- **Train3** (`casmi26-own-fpnet-train3`, launched 2026-10-10 ~12:20 UTC, 7.5 h): fresh weights; spectrum merging (30% items merge 2-4 spectra of same structure+polarity), stronger augmentation (20% peak dropout, m/z jitter .003, multiplicative intensity noise), dropout .2, wd .05, EMA(.9995), best-EMA checkpoint (`ownfp_best.pt`), random 400-structure validation subset (numbers not comparable to runs 1-2, whose eval used the lowest-mass 400 structures).
- **PubChem own tier** (private Kaggle dataset `dalloliogm/casmi26-pubchem-own-tier`, MAKE PUBLIC before final submission - rules require external data to be equally accessible): rebuilt from NCBI Extras (CID-Mass/SMILES/SID/PMID, release 2026-09-27) with `pubchem/build_pubchem_tier.py` in ~10 min; 34,219,447 uncharged compounds, 100-1300 Da, >=3 substance records or >=1 PubMed link; 2.7 GB.
- **Inference v2** (`casmi26-own-fpnet-infer2`): pool window + top-2000 most-documented tier compounds per molecule (own fingerprints/InChIKeys computed on the fly), tier penalty delta and popularity weight tuned on held-out identities removed from library AND pool. Result with run-2 weights: if the answer is *only* in PubChem, MRR@25 is 0.13-0.15 (best at delta 0, pop .1) but that costs class-1-like accuracy (0.98 -> 0.70); the validator chose delta=1 (class-2-proxy 0.072, class-1-proxy 0.939). Submitted as ref 57043448.

## 2026-10-10 evening results
- **PubChem channel LB: 0.209 (ref 57043448) < pool-only 0.261.** The tier-only candidates hurt on the leaderboard even with a penalty. Reason: the validator objective over-weighted the 'answer only in PubChem' proxy (0.07-0.15 MRR) vs the case where the answer is in the pool; LB says most scored answers are reachable from the pool or the PubChem top-2000 are mostly wrong. infer2 v3 now tunes on three groups: A answer in pool (library removed) 0.6, B answer only in PubChem 0.1, class-1-like 0.3.
- **Train3 (regularised) finished**: 93,254 steps; EMA held-out-identity MRR@25 (random 400): 0.62 @6k, 0.71 @18.6k, best 0.715 @49.7k, then flat ~0.70-0.71; final random-1500 = **0.706** (EMA) / 0.707 (raw). Merging+augmentation reached the plateau ~3x faster than run 2 but the plateau is about the same -> bottleneck is data/capacity/negatives, not just regularisation. Best checkpoint `ownfp_best.pt` (step 49,699).

- **LB 0.274 (ref 57052812)**: train3 best-EMA checkpoint (step 49,699) + pool + PubChem tier at delta=4 (practically pool-only; tier barely contributes). Prize-eligible best so far: 0.261 -> **0.274**. Validation (3 groups): in-pool 0.781, PubChem-only 0.018, class-1-like 0.933.
- Lessons: (1) PubChem top-2000-by-popularity candidates never helped on LB (v3 0.175<0.292, own-tier 0.209<0.261); (2) regularisation/merging gave +0.013 LB; the held-out plateau (~0.71) suggests capacity/data limits; (3) remaining ideas: ensemble several own models (different seeds/architectures, cheap via the pool fingerprints), popularity prior from a permissive source applied *only inside the pool*, bigger/longer model with hard (same-formula) negatives, DreaMS embedding features (CC BY 4.0 weights allowed by hosts), LightGBM re-ranker on honest held-out lists.
