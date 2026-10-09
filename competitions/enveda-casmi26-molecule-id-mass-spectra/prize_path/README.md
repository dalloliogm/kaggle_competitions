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
