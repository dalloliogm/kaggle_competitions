# Notes

## Recap of the challenge so far (written 2026-10-31; ends 2026-12-14, entry/merger deadline 2026-12-07)

### Timeline of our work
- Oct 3: library-retrieval baseline LB 0.140 -> own FP-MLP + candidates 0.191 -> public FPNet swap 0.292 (v4). Priors tuned on the NP panel hurt (v5 0.255); more FPNets did not help (v6 0.290).
- Oct 4-6: forks of the public pipeline (FPNet + LightGBM rankers + PubChem tier + ICEBERG/GLACIER fusion) = **LB 0.363-0.379** (best 0.379, v30 fork with POP_MU 0.15). We declined the "visible-id pair" leak notebooks that claimed 0.41x.
- Oct 9-10: "prize path" (own FPNet trained only on train.parquet+COCONUT, no third-party weights): LB 0.261 -> 0.274 (train3). Prize-eligible but ~0.1 below the public frontier.
- Oct 10-31: no activity from us. Field moved from ~0.41 to **0.477 (public code) / 0.517 (leaderboard top)**.
- Oct 31: forked the current public 0.477 notebook (busyaprime m1) as `dalloliogm/casmi26-fork-m1-0477` and submitted it (ref 57838262, commit run ~35 min, scoring rerun pending; expect ~7 h).

### State of the field (2026-10-31)
- Leaderboard top 0.517 (Oleksandr Parfionov, Savko), then 0.504, 0.501, 0.495... ~4,300 teams. Gold line ~0.481 (rank 18 on 10-29). 231 teams sit at exactly 0.477, 175 at 0.472: **the public pipeline is saturated** - 122 of 133 public notebooks scoring >=0.46 attach the same `dmitriigluzdov/casmi26-attributed-v4g-reproduction-assets`.
- Lineage of the 0.477 notebook: Gluzdov "Data behind Spectra to Structures" 0.465 -> Saner Turhaner neural RRF (weight .25) 0.466 -> Roman Rozen leader-safe consensus (ranks 2-25 at .50) 0.468 -> alex chilton ranks 2-25 at .75 = 0.472 -> Roman Tamrazov fragment check (<=2-bond-cleavage MetFrag-lite, untrained) 0.472 -> busyaprime merge (fragment-check leader moves taken from the V2 order on top of the .75 order) **0.477**.
- Negative results documented there: Ahmed Berat Ozer's long-trained neural model -0.019; NX isomer reranker -0.058; provenance reranker +0.000; leader-rule knob sweeps +-0.004 (i.e. noise).
- Public LB is ~31% of the test (~125 molecules): one rank 2->1 move = 0.004. Differences <=0.005 between public notebooks are noise (thread 753525). Top-10 teams are not authors of any public notebook, so 0.50+ uses private ideas.

### Hosts' rulings that matter (discussion threads)
- 750330 (10-17): non-commercial (CC-BY-NC) open data now allowed; NIST and proprietary data are not (derived weights included).
- 748882 / 752541 / 753662 (10-25..30): weights/intermediates need public original training/generation code to be prize-eligible; hosts "reserve the right" to remove non-reproducible submissions from the leaderboard; checks have historically covered prize (sometimes gold) zone only. Pre-built free, openly accessible datasets are OK if not built from proprietary data (David Healey, 10-30); open follow-ups on whether shared weight datasets (ahmedberatozer/*, prvsiyan/*) count.
- 745072: earlier answer - non-commercial inputs make a solution ineligible to win (superseded in part by 750330).
- 752846/753400/751300: Class 3 (novel structures) is unsolved by everyone; rule-based biotransformation of analogs recovers few.
- Final: 2 submissions selectable; private = ~69% of molecules, so keep one diverse pick.

### Where the signal is (hypotheses for the remaining 6 weeks)
1. The public pipeline's ceiling is ~0.477; gains of 0.04 (top teams) come from something not in public notebooks - likely a better spectrum->structure encoder (DreaMS / larger FPNet), Class-3 handling, or better candidate generation.
2. Our own prize-path FPNet (0.274 alone) is far weaker than the shared `sanpier/casmi-spectrum-model-v1` neural scorer; the gap is encoder quality/training data (they likely use the whole 2.5M spectra + COCONUT with longer training).
3. Fragment-coverage scoring (untrained) gave +0.005: cheap physics-style features still add signal.

## 2026-11-01 progress: feature/validation dump (step 0 of STRATEGY_2026-10-31.md)
- Premise check: the strategy agent assumed m1 has a built-in VALIDATION mode. It does NOT (our older v30 fork had one; m1/busyaprime/Spectral Parallax do not). A dump needs a small patch.
- Why patching is needed: the wrapper and the SHA-pinned frozen 0.465 pipeline read the real competition dir; frozen cell 28 asserts `comp in {/kaggle/input/<slug>, /kaggle/input/competitions/<slug>}`. `IS_RERUN` is also true whenever the test spectrum-id signature differs from the visible one, so a held-out test automatically runs every molecule (no SMOKE subset).
- Patch surface (small): frozen cell 4 (`locate_data_dir`: honour an env var first), cell 26 (`COMP = os.path.dirname(find('test.parquet'))` -> env var), cell 28 (relax the path assertion); update FROZEN_B64 and FROZEN_SHA256 (constants in wrapper cell 8; runner.py checks the hash); wrapper cell 2 COMP discovery. No other hard-coded paths found in frozen cells or helper modules.
- Held-out set design: build `/kaggle/working/valcomp/{train,test,sample_submission}` in a prep cell by streaming train.parquet with pyarrow (never load all 2.5M spectra): pick ~200 enveda-180 structures + ~100 enveda-np-examples structures, remove ALL train rows of those inchikey14 from train, write held-out spectra as test (new `molecule_id`/`spectrum_id`, label columns dropped to the 12 test columns), save labels to val_labels.csv. ~300 molecules to stay inside 9 h (v30 validation of 250 mols took ~2.1 h).
- Dump contents to save from /kaggle/working: frozen_candidate_evidence.parquet, outsider_evidence.parquet, neural_candidate_features.parquet, variants/*.csv, fragment-check report; add per-candidate score table + per-molecule MRR of each variant.
- Caveats: held-out structures are still in the candidate pool/pretrained weights (optimistic; prefer fold-safe assets where possible); S2 = drug-like enveda-180 (not natural products); validation has no class-1 molecules by construction.
- Status: design done, patched notebook NOT yet built or run. Submission 57838262 still PENDING at last check. Local kaggle CLI needs `uvx --with six` (missing dep in uv cache).

### 2026-11-01 update
- Submission 57838262 (unmodified fork of public m1) scored **public LB 0.477**: reproduces the public number, so the pipeline is deterministic enough. Ties ~466 teams at 0.477.
- Validation dump kernel `dalloliogm/casmi26-m1-validation-dump` v1 pushed 2026-11-01 ~16:50 UTC; still running at 18:14 UTC.

## 2026-11-01 validation dump RESULTS (kernel dalloliogm/casmi26-m1-validation-dump v1, ~4 h, COMPLETE)
Files: `validation_dump_2026-11-01/` (scores, labels, per-molecule RR, candidate/neural tables, answer files). Big raw outputs (query spectra, held-out test, valcomp) stay in the Kaggle kernel output.
Setup: 300 held-out molecules (200 S2 = enveda-180-only structures, 100 S1 = enveda-np-examples), all train rows of those structures purged, whole unchanged m1 pipeline run (`is_full_run: true`, 300 molecules).

| answer file | ALL | S2 | S1 |
|---|---|---|---|
| final submission.csv (m1 incl. fragment check merge) | 0.789 | 0.736 | 0.896 |
| CUSTOM (.25/.75 neural) | 0.795 | 0.737 | 0.911 |
| V0 (0.465 baseline, no neural) | 0.792 | 0.730 | 0.916 |
| V1 (neural .25) | 0.795 | 0.735 | 0.915 |
| V2 (.25/.50) = V3 | 0.801 | 0.745 | 0.915 |
| V4 (.25/1.0) | 0.789 | 0.732 | 0.903 |
| e004/e006 controls | 0.801 | 0.743 | 0.918 |

Rank distribution of the truth in the final list: rank 1 64.7% (S2 55.0%, S1 84.0%), ranks 2-6 33.3% (S2 43.5%), ranks 7-25 1.7%, miss 0.3%. hit@25 = 99.7%.

Interpretation:
- **Not representative of the hidden test in absolute terms**: MRR 0.79 vs LB 0.477 and hit@25 0.997. The held-out structures are still in the precomputed candidate pool (v2-pool / COCONUT / train-derived tiers) and in the pretrained FPNet/neural weights, so recall is ~100% and class 3 is entirely absent. Use only for *ordering among candidates present*; never as an LB predictor.
- Within that scope the headroom is the rank-1 decision: 33% of molecules have the truth at ranks 2-6 (S2: 43.5%). An oracle arbiter would move MRR from 0.79 toward ~0.95; a realistic one capturing a few % of these is the +0.005-0.015 hypothesis.
- All public knob variants differ by <=0.012 (V2 best) which is ~3-4 molecules at n=300; the fragment-check merge changed only 4 molecules, all for the worse here (-0.006 vs CUSTOM). Consistent with "knob differences are noise".
- Contamination caveat for training an arbiter on this dump: neural scores for held-out structures are inflated (weights saw them). Features from the frozen FPNet/neural scorer are therefore biased towards the truth; prefer fold-safe checkpoints (`dmitriigluzdov/casmi26-fold-safe-fpnet`) or restrict the arbiter to features not trained on the structure (fragment coverage, formula, GLACIER/ICEBERG, popularity/doc counts).
- Cost/housekeeping: the cleanup cell left `ice_site/`, `eng/`, etc. in the output (~1.3 GB); fine but slow to download (~15 min).
