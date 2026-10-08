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
